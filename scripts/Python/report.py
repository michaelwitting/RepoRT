import pandas as pd
import sys
import os.path
from os import listdir

def check_processed_file(f, fields):
    if (not os.path.exists(f)):
        return None
    df = pd.read_csv(f, sep='\t', index_col=0)
    if (fields is None):
        # check if there is at least one field in each row != NA
        return (~pd.isna(df)).any(axis=1).sum()
    else:
        return (~pd.isna(df[fields]).all(axis=1)).sum()

def validation_file_len(f):
    if os.path.exists(f):
        return len(list(open(f).readlines())) - 1 # minus header
    return 0

def validation_stats(dataset, mode_):
    if (mode_ == 'qspr'):
        return validation_file_len(f'processed_data/{dataset}/{dataset}_validation_qspr_outliers.txt')
    elif (mode_ == 'same_condition'):
        return validation_file_len(f'processed_data/{dataset}/{dataset}_validation_same_condition.txt')
    elif (mode_ == 'systematic'):
        return (validation_file_len(f'processed_data/{dataset}/{dataset}_validation_systematic_column_temperature.txt')
                + validation_file_len(f'processed_data/{dataset}/{dataset}_validation_systematic_column_flowrate.txt'))
    else:
        raise NotImplementedError(mode_)

def print_stats(stats_raw, stats_processed, stats_val, exist):
    print(pd.DataFrame.from_records([{'mode': mode,
                                      'raw SMILES': stats_raw[f'{mode} SMILES'],
                                      'standardized SMILES': stats_processed[f'{mode} SMILES'],
                                      'Classyfire classifications': stats_processed[f'{mode} ClassyFire classifications'],
                                      'descriptors': stats_processed[f'{mode} descriptors']}
                                     for mode in ['canonical', 'isomeric']]).set_index('mode').to_markdown())
    # general stats on entries
    print('')
    print(pd.DataFrame.from_records([{'entries without rt': stats_raw['entries without rt'],
                                      'entries without SMILES': stats_raw['entries without SMILES'],
                                      #TODO: duplicate entries
                                      #TODO: validation with *pairs*
                                      'entries flagged by QSPR-based validation': stats_val['qspr-flagged'],
                                      'entry-pairs flagged by retention order-based validation (datasets with identical setups)': stats_val['same_condition-flagged'],
                                      'entry-pairs flagged by retention order-based validation (systematic measurements)': stats_val['systematic-flagged']
                                      }]).transpose().rename(columns={0: 'nr'}).to_markdown())
    # whether all files exist
    print('\n### Files successfully generated\n')
    for info in ['RTdata canonical',
                 'RTdata isomeric',
                 'descriptors canonical',
                 'descriptors isomeric',
                 'metadata file',
                 'gradient file',
                 'report canonical',
                 'report isomeric']:
        if info in exist:
            print(':heavy_check_mark: ' + info)
        else:
            print(':x: ' + info)


def check_dataset(dataset):
    stats_raw = {}
    stats_processed = {}
    stats_val = {}
    raw_rtdata = pd.read_csv(f'raw_data/{dataset}/{dataset}_rtdata.txt', sep='\t')
    stats_raw['canonical SMILES'] = len(raw_rtdata.dropna(subset=['pubchem.smiles.canonical']))
    stats_raw['isomeric SMILES'] = len(raw_rtdata.dropna(subset=['pubchem.smiles.isomeric']))
    stats_raw['entries without rt'] = len(raw_rtdata.loc[pd.isna(raw_rtdata.rt)])
    stats_raw['entries without SMILES'] = len(raw_rtdata.loc[pd.isna(raw_rtdata['pubchem.smiles.canonical'])
                                                             & pd.isna(raw_rtdata['pubchem.smiles.isomeric'])])
    # TODO: stats['duplicate entries']
    exist = []
    # check rtdata, descriptors files for valid computations
    for desc, f in [('RTdata canonical', f'processed_data/{dataset}/{dataset}_rtdata_canonical_success.txt'),
                    ('RTdata isomeric', f'processed_data/{dataset}/{dataset}_rtdata_isomeric_success.txt'),
                    ('descriptors canonical', f'processed_data/{dataset}/{dataset}_descriptors_canonical_success.txt'),
                    ('descriptors isomeric', f'processed_data/{dataset}/{dataset}_descriptors_isomeric_success.txt')]:
        if desc.lower().split()[0] == 'rtdata':
            res_smiles = check_processed_file(f, ['smiles.std'])
            res_classyfire = check_processed_file(f, ['classyfire.kingdom'])
            if res_smiles is None or res_classyfire is None:
                stats_processed[f'{desc.split()[1]} SMILES'] = 0
                stats_processed[f'{desc.split()[1]} ClassyFire classifications'] = 0
            else:
                exist.append(desc)
                stats_processed[f'{desc.split()[1]} SMILES'] = res_smiles
                stats_processed[f'{desc.split()[1]} ClassyFire classifications'] = res_classyfire
        elif desc.lower().split()[0] == 'descriptors':
            res = check_processed_file(f, None)
            if res is None:
                stats_processed[f'{desc.split()[1]} descriptors'] = 0
            else:
                exist.append(desc)
                stats_processed[f'{desc.split()[1]} descriptors'] = res
    # check whether all processed files exist
    for desc, f in [('metadata file', f'processed_data/{dataset}/{dataset}_metadata.txt'),
                    ('gradient file', f'processed_data/{dataset}/{dataset}_metadata.txt'),
                    ('report canonical', f'processed_data/{dataset}/{dataset}_report_canonical.pdf'),
                    ('report isomeric', f'processed_data/{dataset}/{dataset}_report_isomeric.pdf')]:
        if (os.path.exists(f)):
            exist.append(desc)
    # validation
    stats_val['qspr-flagged'] = validation_stats(dataset, 'qspr')
    stats_val['same_condition-flagged'] = validation_stats(dataset, 'same_condition')
    stats_val['systematic-flagged'] = validation_stats(dataset, 'systematic')
    # print everything
    print_stats(stats_raw=stats_raw, stats_processed=stats_processed, stats_val=stats_val, exist=exist)
    # reasons for failed classifications
    for f in [f'processed_data/{dataset}/{dataset}_rtdata_canonical_failed.txt', f'processed_data/{dataset}/{dataset}_rtdata_isomeric_failed.txt']:
        if (os.path.exists(f)):
            print(f'\n### Failed {f.split("/")[-1].split("_")[-2]} classifications: reasons\n')
            print(pd.read_csv(f, sep='\t')['status'].value_counts().to_markdown())

if __name__ == '__main__':
    print('# Preprocessing Report\n')
    for dataset in sys.argv[1:]:
        print(f'\n## {dataset}\n')
        try:
            check_dataset(dataset)
        except:
            print('error while checking, outputting names of generated files instead\n', end='- ')
            dir_ = f'processed_data/{dataset}/'
            if (os.path.exists(dir_)):
                print('\n- '.join(listdir(dir_)))
