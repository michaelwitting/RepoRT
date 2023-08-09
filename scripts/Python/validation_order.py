from glob import glob
from typing import Set
import pandas as pd
from argparse import ArgumentParser
from itertools import combinations
import os.path

MIN_REQUIRED_PARAMS = ['column.name', 'column.flowrate', 'column.temperature']

def delete_file(f):
    if os.path.exists(f):
        os.remove(f)

def reasonable_flip(order):
    first_change = [(i, ch) for i, ch in enumerate(order) if ch != order[0]]
    if (len(first_change) == 0):
        return True
    change_back = [(i, ch) for i, ch in enumerate(order) if i > first_change[0][0]
                   and ch != first_change[0][1]]
    return len(change_back) == 0

class Detector():
    def __init__(self, repo_root='.', void_factor=2, epsilon=0.5):
        self.repo_root = repo_root
        self.void_factor = void_factor
        self.epsilon = epsilon
        self.metadata = pd.concat([pd.read_csv(f, sep='\t', dtype={'id': str}, index_col=0)
                                   for f in glob(self.repo_root + '/processed_data/*/*_metadata.tsv')])
        self.metadata.index = [str(i).rjust(4, '0') for i in self.metadata.index.tolist()]
        self.rtdata = self.get_rtdata()

    def get_rtdata(self, iso=True):
        cs_df = pd.concat([pd.read_csv(f, delimiter='\t') for f in
                           glob(self.repo_root + '/processed_data/*/*rtdata_canonical_success.tsv')],
                          axis=0, ignore_index=True)
        # no duplicate IDs
        assert len(list(cs_df.id)) == len(set(cs_df.id))
        cs_df['dataset_id'] = cs_df.id.str.split('_', expand=True)[0]
        cs_df['internal_id'] = cs_df.id.str.split('_', expand=True)[1]
        cs_df.set_index('id', inplace=True, drop=False)
        if iso:
            cs_df_iso = pd.concat([pd.read_csv(f, delimiter='\t') for f in
                                   glob(self.repo_root + '/processed_data/*/*rtdata_isomeric_success.tsv')],
                                  axis=0, ignore_index=True)
            assert len(list(cs_df_iso.id)) == len(set(cs_df_iso.id))
            cs_df_iso['dataset_id'] = cs_df_iso.id.str.split('_', expand=True)[0]
            cs_df_iso['internal_id'] = cs_df_iso.id.str.split('_', expand=True)[1]
            cs_df_iso.set_index('id', inplace=True, drop=False)
            cs_df.update(cs_df_iso)
        return cs_df

    def get_dataset_clusters(self, dataset_query=None):
        clusters = []
        # join metadata with dataset names, drop unusable datasets
        metadata = self.metadata.dropna(subset=MIN_REQUIRED_PARAMS).join(
            pd.read_csv(self.repo_root + '/processed_data/studies.tsv', sep='\t',
                        dtype={'id': str}, index_col=0)[['name', 'authors']], how='left')
        group_columns = [col for col in metadata.columns.tolist() if col not in ['name']]
        # get clusters
        for spec, group in metadata.groupby(group_columns, dropna=False):
            if len(group) > 1:
                spec_verbose =  [(c, v) for c, v in zip(group_columns, spec) if not pd.isna(v) and v != 0]
                clusters.append((spec_verbose, group.index.tolist()))
        if dataset_query is None or len(dataset_query) == 0:
            return clusters
        return [c for c in clusters if any(ci in dataset_query for ci in c[1])]

    def get_series_clusters(self, criterion, dataset_query=None):
        clusters = self.get_dataset_clusters() # no query to also get previously uploaded clusters
        condition_series = {}
        for spec, c in clusters:
            condition_value = [v for k, v in spec if k == criterion]
            if len(condition_value) > 1:
                raise Exception('failure when generating cluster specs')
            if len(condition_value) == 0 or pd.isna(condition_value[0]):
                continue
            condition_value = condition_value[0]
            spec_sine_condition = tuple([s for s in spec if s[0] != criterion])
            condition_series.setdefault(spec_sine_condition, []).append((condition_value, c))
        condition_series = {k: v for k, v in condition_series.items() if len(v) > 1}
        if dataset_query is None or len(dataset_query) == 0:
            return condition_series
        return {k: v for k, v  in condition_series.items() if any(ci in dataset_query for vi in v for ci in vi[1])}


    def get_cluster_comparable_pairs(self, cluster, rt_epsilon=1/12):
        ignore_compounds = set() # for example smiles with duplicate entries
        ignore_compounds.update(self.rtdata.loc[self.rtdata.dataset_id.isin(cluster) & self.rtdata.duplicated(subset=['dataset_id', 'smiles.std'], keep=False)].sort_values(['dataset_id', 'smiles.std']).index.tolist())
        ignore_pairs : Set[frozenset] = set()
        pairs : Set[tuple] = set()
        for ds in cluster:
            void = self.metadata.loc[ds, 'column.t0']  * self.void_factor
            # remove duplicates
            df = self.rtdata.loc[self.rtdata.dataset_id == ds].dropna(subset=['rt'])
            dups_rt_diff = df.loc[df.duplicated(subset=['smiles.std'], keep=False)].groupby('smiles.std').rt.agg(
                ['max', 'min']).diff(axis=1)['min'].abs()
            ignore_compounds.update(dups_rt_diff.loc[dups_rt_diff > rt_epsilon].index.tolist())
            # get all possible pairs
            a, b = map(list, zip(*combinations(df.index, 2)))
            for _, (id1, smiles1, rt1, id2, smiles2, rt2) in pd.concat(
                    [df.loc[a, ['smiles.std', 'rt']].reset_index(), df.loc[b, ['smiles.std', 'rt']].reset_index()],
                    keys=['a', 'b'], axis=1).iterrows():
                (rt_smaller, smiles_smaller), (rt_greater, smiles_greater) = sorted(zip([rt1, rt2], [smiles1, smiles2]))
                if ((rt1 < void and rt2 < void) or (smiles1 in ignore_compounds or smiles2 in ignore_compounds)
                    or (frozenset([smiles1, smiles2]) in ignore_pairs)):
                    continue
                if ((rt_greater - rt_smaller < self.epsilon)
                    or (tuple([smiles_greater, smiles_smaller]) in pairs) # conflicting within same condition
                    ):
                    ignore_pairs.add(frozenset([smiles1, smiles2]))
                    if (tuple([smiles_greater, smiles_smaller]) in pairs):
                        pairs.remove(tuple([smiles_greater, smiles_smaller]))
                    continue
                pairs.add(tuple([smiles_smaller, smiles_greater]))
        return pairs

    def get_pairs_order_changes(self, pairs_conds):
        all_pairs = {frozenset(pair) for pairs in pairs_conds.values() for pair in pairs}
        records = []
        for pair in all_pairs:
            try:
                c1, c2 = pair
            except Exception as e:
                print(pair)
                continue
            if (not all((c1, c2) in pairs or (c2, c1) in pairs
                for pairs in pairs_conds.values())):
                continue
            for value, pairs in pairs_conds.items():
                order = '<' if (c1, c2) in pairs else ('>' if (c2, c1) in pairs else '?')
                records.append({'smiles1': c1, 'smiles2': c2, 'order': order, 'condition_value': value})
        df = pd.DataFrame.from_records(records)
        df['order_str'] = [f'{r.condition_value:.1f}: {r.order}' for i, r in df.iterrows()]
        grouped = df.groupby(['smiles1', 'smiles2'])
        results = grouped.agg({'order_str': ', '.join, 'order': ''.join})
        # NOTE: visualization comes here
        return results.loc[lambda df: [not reasonable_flip(r.order) for i, r in df.iterrows()]]


    def get_cluster_conflicts(self, cluster):
        records = []
        pairs = {}
        for ds in cluster:
            pairs[ds] = self.get_cluster_comparable_pairs([ds])
        all_pairs = set.union(*[set(map(frozenset, v)) for v in pairs.values()])
        # get unique string-based "order" for pairs to find conflicts
        pairs_ordered = {ds: {frozenset([c1, c2]): 1 if c1 < c2 else 2 for c1, c2 in pairs[ds]}
                         for ds in pairs}
        for pair in all_pairs:
            try:
                c1, c2 = pair
            except Exception as e:
                print(pair)
                continue
            orders = {pairs_ordered[ds][pair] for ds in pairs_ordered
                      if pair in pairs_ordered[ds]}
            if len(orders) > 1:
                record = {'smiles1': c1, 'smiles2': c2}
                for ds in pairs:
                    order = '<' if (c1, c2) in pairs[ds] else ('>' if (c2, c1) in pairs[ds] else '?')
                    record[ds] = order
                records.append(record)
        return pd.DataFrame.from_records(records)

    def get_all_series_unreasonable_flips(self, criterion, dataset_query):
        # get corresponding cluster
        print(f'INFO: looking for dataset clusters of systematic measurements ({criterion}) with query', dataset_query)
        clusters = self.get_series_clusters(criterion, dataset_query)
        if len(clusters) == 0:
            print('INFO: no clusters found')
            return
        for spec, series in clusters.items():
            print('INFO: looking for unlikely double order inversions for cluster',
                  ', '.join(f'{k}={v}' for k, v in spec), '; datasets:', ' '.join([x for value, cluster in series for x in cluster]))
            # get all comparable pairs
            pairs_conds = {value: self.get_cluster_comparable_pairs(cluster) for value, cluster in series}
            # now get unreasonable flips
            results = self.get_pairs_order_changes(pairs_conds)
            if (results is None or len(results) == 0):
                print('INFO: no double order inversions found')
            else:
                print(results.to_string())
            # export
            for ds in dataset_query:
                if ds in [x for value, cluster in series for x in cluster]:
                    out_file = self.repo_root + f'/processed_data/{ds}/{ds}_validation_systematic_{criterion.replace(".", "_")}.tsv'
                    if (results is None or len(results) == 0):
                        delete_file(out_file)
                    else:
                        results.to_csv(out_file, sep='\t')


    def get_all_cluster_conflicts(self, dataset_query):
        print('INFO: looking for datasets measured under identical conditions with query', dataset_query)
        clusters = self.get_dataset_clusters(dataset_query)
        if len(clusters) == 0:
            print('INFO: no clusters found')
            return
        for spec, c in clusters:
            print('INFO: looking for order conflicts in cluster',
                  ', '.join(f'{k}={v}' for k, v in spec), '; datasets:', ' '.join(c))
            results = self.get_cluster_conflicts(c)
            if (results is None or len(results) == 0):
                print('INFO: no conflicts found')
            else:
                print(results.to_string())
            # export
            for ds in dataset_query:
                if ds in c:
                    out_file = self.repo_root + f'/processed_data/{ds}/{ds}_validation_same_condition.tsv'
                    if (results is None or len(results) == 0):
                        delete_file(out_file)
                    else:
                        results.to_csv(out_file, sep='\t', index=False)


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('datasets', nargs='+')
    parser.add_argument('--mode', choices=['systematic', 'same_condition'])
    parser.add_argument('--epsilon', type=float, default=0.5, help='retention time difference threshold (min)')
    parser.add_argument('--void_factor', type=int, default=2, help='multiplicator of "column.t0" value for void time threshold')
    args = parser.parse_args()
    d = Detector(void_factor=args.void_factor, epsilon=args.epsilon)
    if (args.mode == 'systematic'):
        d.get_all_series_unreasonable_flips(criterion='column.temperature', dataset_query=args.datasets)
        d.get_all_series_unreasonable_flips(criterion='column.flowrate', dataset_query=args.datasets)
    elif (args.mode == 'same_condition'):
        d.get_all_cluster_conflicts(dataset_query=args.datasets)
