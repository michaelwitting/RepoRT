import os.path
from os import getcwd
from glob import glob
import pandas as pd
import numpy as np
import subprocess
import re
import yaml
import json

def series_subset_to_string(series, subset):
    # preprocess for unit
    fields = []
    for c in subset:
        if c.endswith('.unit'):
            continue
        v = series[c]
        if pd.isna(series[c]):
            continue
        if isinstance(v, float) or isinstance(v, int):
            if v == 0:
                continue
        if ((unit := c + '.unit') in subset and not pd.isna(series[unit])):
            fields.append(f'{c}:{v}{series[unit]}')
        else:
            fields.append(f'{c}:{v}')
    return ', '.join(fields)

# yaml can't handle numpy numbers properly
def numpy_representer(dumper, data):
    serialized = data.item()
    return dumper.represent_data(serialized)

# json can't handle numpy numbers properly
class NumpyJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.generic):
            return obj.item()
        return super().default(obj)

class Stats():
    def __init__(self, dir_=None, verbose=True):
        self.verbose = verbose
        self.dir_ = dir_ or getcwd()
        current_commit_hash = subprocess.run(
                ['git', 'rev-parse',  '--short', 'HEAD'], cwd=self.dir_, capture_output=True
            ).stdout.decode().strip()
        current_commit_date = subprocess.run(
                'git --no-pager log -1 --format="%ai"'.split(), cwd=self.dir_, capture_output=True
            ).stdout.decode().strip()
        self.version_info = f'RepoRT version {current_commit_hash} with last commit from {current_commit_date}'
        if (self.verbose):
            print(self.version_info)
        dataset_info = pd.read_csv(os.path.join(self.dir_, 'raw_data/studies.tsv'), sep='\t')
        mdfs = [pd.read_csv(mfile, sep='\t', dtype={'id': str}) for mfile in glob(
            os.path.join(self.dir_, 'processed_data/*/*_metadata.tsv'))]
        dataset_metadata = pd.concat(mdfs)
        dataset_info.id = [str(i).rjust(4, '0') for i in dataset_info.id.tolist()] # keep string formatting of IDs
        dataset_metadata.id = [str(i).rjust(4, '0') for i in dataset_metadata.id.tolist()]
        dataset_iall = pd.merge(dataset_info, dataset_metadata, on='id', validate='one_to_one', how='right')
        dataset_iall.index = dataset_iall.id
        eluent_columns = [c for c in dataset_iall.columns if c.startswith('eluent.')
                          and not (c.endswith('.unit') or c.endswith('.pH'))] # TODO: has to be changed once "unit" works properly
        dataset_iall['eluent'] = [series_subset_to_string(r, eluent_columns) for i, r in dataset_iall.iterrows()]
        dataset_iall['mobilephase'] = [series_subset_to_string(r, eluent_columns)
                                       for i, r in dataset_iall.iterrows()]
        self.dss = dataset_iall
        # TODO: need this?
        self.dss_rp = self.dss.loc[self.dss['method.type'] == 'RP']
        self.dss_hilic = self.dss.loc[self.dss['method.type'] == 'HILIC']
        self.dss_other = self.dss.loc[self.dss['method.type'] == 'Other']
        self.cs_df = pd.concat([pd.read_csv(f, delimiter='\t') for f in
                           glob(os.path.join(self.dir_, 'processed_data/*/*rtdata_canonical_success.tsv'))],
                          axis=0, ignore_index=True)
        # no duplicate IDs
        assert len(list(self.cs_df.id)) == len(set(self.cs_df.id))
        self.cs_df['dataset_id'] = self.cs_df.id.str.split('_', expand=True)[0]
        self.cs_df['internal_id'] = self.cs_df.id.str.split('_', expand=True)[1]
        self.cs_df['smiles_type'] = 'canonical'
        self.cs_df['smiles.std_canonical'] = self.cs_df['smiles.std']
        self.cs_df.set_index('id', inplace=True)
        # iso
        cs_df_iso = pd.concat([pd.read_csv(f, delimiter='\t') for f in
                               glob(os.path.join(self.dir_, 'processed_data/*/*rtdata_isomeric_success.tsv'))],
                              axis=0, ignore_index=True)
        assert len(list(cs_df_iso.id)) == len(set(cs_df_iso.id))
        cs_df_iso['dataset_id'] = cs_df_iso.id.str.split('_', expand=True)[0]
        cs_df_iso['internal_id'] = cs_df_iso.id.str.split('_', expand=True)[1]
        cs_df_iso['smiles_type'] = 'isomeric'
        cs_df_iso.set_index('id', inplace=True)
        self.cs_df.update(cs_df_iso)
        self.counts = self.cs_df.dropna(subset=['rt']).groupby('dataset_id').count()['inchikey.std']
        #hsm/tanaka
        self.hsm_db = pd.read_csv(os.path.join(self.dir_, 'resources/hsm_database/hsm_database.tsv'), sep='\t')
        self.tanaka_db = pd.read_csv(os.path.join(self.dir_, 'resources/tanaka_database/tanaka_database.tsv'), sep='\t')
        self.records = {'RepoRT version': self.version_info}

    def make_dataset_stats(self):
        # general
        datasets_records = self.records['datasets'] = {}
        datasets_records['nr_datasets'] = len(self.dss)
        datasets_records['nr_datasets_by_separation_mode'] = dict(self.dss['method.type'].value_counts())
        # setups
        # TODO:
        # columns
        datasets_records['nr_columns'] = self.dss['column.name'].nunique()
        datasets_records['nr_columns_by_separation_mode'] = dict(self.dss.groupby('method.type')[
            'column.name'].nunique())
        datasets_records['most_common_columns'] = list(dict(self.dss.groupby('column.name').id.nunique(
        ).sort_values(ascending=False).iloc[:5]).items())
        res = datasets_records['most_common_columns_by_separation_mode'] = {}
        for mode_ in self.dss['method.type'].dropna().unique():
            res[mode_] = list(dict(self.dss.loc[self.dss['method.type'] == mode_].groupby('column.name').id.nunique(
            ).sort_values(ascending=False).iloc[:5]).items())
        # mobile phase
        datasets_records['nr_mobile_phase_compositions'] = self.dss.mobilephase.nunique()
        datasets_records['nr_mobile_phase_compositions_by_separation_mode'] = dict(
            self.dss.groupby('method.type').mobilephase.nunique())
        # HSM/Tanaka availability (NOTE: only RP!!)
        cols_with_hsm = [c for c in self.dss_rp['column.name'].unique() if c in self.hsm_db.name_normalized.unique()]
        nr_sets_with_hsm = (self.dss_rp['column.name'].isin(cols_with_hsm)).sum()
        hsm_records = datasets_records['HSM'] = {}
        hsm_records['nr_columns_with_hsm'] = len(cols_with_hsm)
        hsm_records['nr_datasets_with_hsm'] = nr_sets_with_hsm
        hsm_records['ratio_rp_datasets_with_hsm'] = nr_sets_with_hsm / len(self.dss_rp)
        tanaka_records = datasets_records['Tanaka'] = {}
        cols_with_tanaka = [c for c in self.dss_rp['column.name'].unique() if c in
                            self.tanaka_db.name_normalized.unique()]
        tanaka_db_configs = {tuple([x[0], float(re.sub(r' *spp', '', x[1]))])
                             for x in self.tanaka_db[['name_normalized', 'particle size [µm]']].dropna().values}
        sets_with_tanaka_exact = [i for i, r in self.dss_rp.iterrows() if tuple(
            r[['column.name', 'column.particle.size']]) in tanaka_db_configs]
        nr_sets_with_tanaka_rough = (self.dss_rp['column.name'].isin(cols_with_tanaka)).sum()
        tanaka_records['nr_columns_with_tanaka'] = len(cols_with_tanaka)
        tanaka_records['nr_datasets_with_tanaka_exact'] = len(sets_with_tanaka_exact)
        tanaka_records['ratio_rp_datasets_with_tanaka_exact'] = len(sets_with_tanaka_exact) / len(self.dss_rp)
        tanaka_records['nr_datasets_with_tanaka_rough'] = nr_sets_with_tanaka_rough
        tanaka_records['ratio_rp_datasets_with_tanaka_rough'] = nr_sets_with_tanaka_rough / len(self.dss_rp)
        datasets_records['nr_datasets_with_hsm_and_tanaka_rough'] = (
            self.dss_rp['column.name'].isin(cols_with_hsm)
            & self.dss_rp['column.name'].isin(cols_with_tanaka)).sum()
        datasets_records['ratio_rp_datasets_with_hsm_and_tanaka_rough'] = (
            self.dss_rp['column.name'].isin(cols_with_hsm)
            & self.dss_rp['column.name'].isin(cols_with_tanaka)).sum() / len(self.dss_rp)

    def make_compound_stats(self):
        compounds_stats = self.records['compounds'] = {}
        compounds_stats['nr_compounds'] = self.cs_df['smiles.std'].nunique()
        compounds_stats['nr_compounds_per_dataset'] = dict(self.counts.describe()[
            ['mean', '50%', 'min', 'max']].rename({'50%': 'median'}))
        compounds_stats['nr_datasets_less_than_10_compounds'] = (self.counts < 10).sum()
        compounds_stats['nr_datasets_more_than_1000_compounds'] = (self.counts > 1000).sum()

    def make_entry_stats(self):
        entries_stats = self.records['entries'] = {}
        entries_stats['nr_entries'] = len(self.cs_df.dropna(subset=['smiles.std', 'rt']))

    def make_all_stats(self):
        self.make_dataset_stats()
        self.make_compound_stats()
        self.make_entry_stats()

    def make_stats_yaml(self, out_file='stats/stats.yaml'):
        self.make_all_stats()
        yaml.add_multi_representer(np.generic, numpy_representer, Dumper=yaml.SafeDumper)
        with open(out_file, 'w') as out:
            yaml.safe_dump(self.records, out, default_flow_style=False, sort_keys=False,
                           allow_unicode=True, default_style='')
        if (self.verbose):
            print('statistics written to', out_file)

    def make_stats_json(self, out_file='stats/stats.json'):
        self.make_all_stats()
        with open(out_file, 'w') as out:
            json.dump(self.records, out, cls=NumpyJSONEncoder, indent=2)
        if (self.verbose):
            print('statistics written to', out_file)

if __name__ == '__main__':
    stats = Stats()
    stats.make_stats_yaml()
    # stats.make_stats_json()
