import sys
import os.path
from collections import OrderedDict
import pandas as pd
import numpy as np
import yaml

def primitive(x):
    return x.item() if hasattr(x, 'item') else x

def to_hierarchical(metadata):
    result = OrderedDict()
    for k, v in metadata.items():
        if k in ['id']:
            # just take as is
            result[k] = primitive(v)
        elif k.startswith('column.'):
            # "column" fields -> one level
            k_sin = k.replace('column.', '')
            result.setdefault('column', {})[k_sin] = primitive(v)
        elif k.startswith('eluent.'):
            # "eluent" fields -> two/three levels
            part = k.split('.')[1]
            k_sin = k.replace(f'eluent.{part}.', '')
            chemical_dict = result.setdefault('eluent', {}).setdefault(part, {}).setdefault(k_sin.replace('.unit', ''), {})
            if k.endswith('.unit'):
                chemical_dict['unit'] = primitive(v)
            else:
                chemical_dict['value'] = primitive(v)
        else:
            # skip
            print('skipping field', k)
    # simplify eluent fields with not unit specified
    result_simplified = {}
    for k, v in result.items():
        if k == 'eluent':
            for part in v:
                for chemical in v[part]:
                    if list(v[part][chemical]) == ['value']:
                        v[part][chemical] = v[part][chemical]['value']
        result_simplified[k] = v
    # TODO: don't store eluent values if they only have a unit but no value
    return result

def traverse(whole_key, x, result):
    if not isinstance(x, dict):
        result[whole_key.replace('.value', '')] = x
    else:
        for k, v in x.items():
            traverse(f'{whole_key}.{k}'.lstrip('.'), v, result)

def to_full_table(metadata):
    result = {}
    traverse('', metadata, result)
    base = pd.read_csv('example/0259_metadata.tsv', sep='\t',
                       dtype={'id': str})
    # clear everything
    for c in base.columns.tolist():
        if any([c.startswith(x) for x in ['eluent.', 'gradient.']]) and not any(
                [c.endswith(x) for x in ['.unit', '.pH']]):
            base.at[0, c] = 0
        else:
            base.at[0, c] = None
    for k, v in result.items():
        base.at[0, k] = v
    return base.set_index('id')

def read_tsv(tsv_file):
    df_in = pd.read_csv(tsv_file, sep='\t', dtype={'id': str})
    assert len(df_in) == 1, 'metadata tsv files can only have one row!'
    for c in df_in.columns.tolist():
        if (c.startswith('eluent') or c.startswith('gradient')) and df_in.loc[0, c] == 0:
            df_in.at[0, c] = None
    return df_in.dropna(axis=1).loc[0]

def read_yaml(yaml_file, gradient_file):
    with open(yaml_file) as f:
        yaml_in = yaml.load(f, yaml.loader.SafeLoader)
    result = to_full_table(yaml_in)
    if os.path.exists(gradient_file):
        # add gradient data
        gradient = pd.read_csv(gradient_file, sep='\t').sort_values('t [min]')
        for part in [c.split()[0] for c in gradient.columns.tolist() if len(c.split()[0]) == 1
                     and (ord(c[0]) >= ord('A') and ord(c[0]) <= ord('Z'))]: # future proof ;)
            result[f'gradient.start.{part}'] = gradient.iloc[0][f'{part} [%]']
            result[f'gradient.end.{part}'] = gradient.iloc[-1][f'{part} [%]']
    return result

if __name__ == '__main__':
    # either convert from tsv to YAML or YAML to tsv
    for dataset in sys.argv[1:]:
        for mode_ in ['raw', 'processed']:
            tsv_file = f'{mode_}_data/{dataset}/{dataset}_metadata.tsv'
            yaml_file = f'{mode_}_data/{dataset}/{dataset}_metadata.yaml'
            if (os.path.exists(tsv_file) and not os.path.exists(yaml_file)):
                # tsv -> YAML
                df_series = read_tsv(tsv_file)
                result = to_hierarchical(OrderedDict(df_series))
                with open(yaml_file, 'w') as out:
                    yaml.safe_dump(dict(result), out, default_flow_style=False, sort_keys=False, allow_unicode=True)
            elif (os.path.exists(yaml_file) and not os.path.exists(tsv_file)):
                # YAML -> tsv
                result = read_yaml(yaml_file, tsv_file.replace('metadata', 'gradient'))
                result.to_csv(tsv_file, sep='\t')
            elif (os.path.exists(yaml_file) and os.path.exists(tsv_file)):
                # just make sure they are equal
                with open(yaml_file) as f:
                    yaml_res = yaml.load(f, yaml.loader.SafeLoader)
                tsv_res = to_hierarchical(dict(read_tsv(tsv_file)))
                if not yaml_res == tsv_res:
                    raise Exception('metadata files contain conflicting information!')
