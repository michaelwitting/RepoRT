import pandas as pd
from glob import glob

if __name__ == '__main__':
    for mode_ in ['raw', 'processed']:
        studies = pd.read_csv(f'{mode_}_data/studies.tsv', sep='\t', dtype={'id': 'str', 'pmid': 'str'}
                              ).rename({'doi': 'url'}, axis=1).set_index('id')
        dfs = []
        for f in glob(f'{mode_}_data/*/*_info.tsv'):
            dfs.append(pd.read_csv(f, sep='\t', dtype={'id': 'str', 'pmid': 'str'}))
        studies_new = pd.concat(dfs, ignore_index=True).sort_values('id').set_index('id')
        studies.update(studies_new)
        new_entries = studies_new.loc[studies_new.index.difference(studies.index)]
        pd.concat([studies, new_entries]).to_csv(f'{mode_}_data/studies.tsv', sep='\t')
