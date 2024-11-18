import sys
import os.path
from collections import OrderedDict
import pandas as pd
import yaml

def primitive(x):
    return x.item() if hasattr(x, 'item') else x

def change_to_primitive_types(d):
    return {k: primitive(v) for k, v in d.items()}

def isna(x):
    res = pd.isna(x)
    if isinstance(res, bool):
        return res
    return res.all()

def to_hierarchical(d):
    result = OrderedDict()
    for k, v in d.items():
        if '.' in k:
            parts = k.split('.')
            d = result
            for part in parts[:-1]:
                if part not in d:
                    d[part] = {}
                d = d[part]
            d[parts[-1]] = v
        else:
            result[k] = v
    return dict(result)

def make_liststrings_to_list(d_flattened):
    result = {}
    for k, v in d_flattened.items():
        if k in ['authors', 'flags']:
            if pd.isna(v):
                v = None
            else:
                v = v.strip().split(', ')
        result[k] = v
    return result

def fill_in_missing(d_flattened):
    base = pd.read_csv('example/0259_info.tsv', sep='\t',
                       dtype={'id': str})
    return {k: None for k, v in dict(base.iloc[0]).items() if k != 'id'} | d_flattened

def read_tsv(tsv_file):
    df_in = pd.read_csv(tsv_file, sep='\t', dtype={'id': str})
    assert len(df_in) == 1, 'info tsv files can only have one row!'
    return dict(df_in.iloc[0])

def read_yaml(yaml_file):
    with open(yaml_file) as f:
        yaml_in = yaml.load(f, yaml.loader.SafeLoader)
    for k, v in yaml_in.items():
        if isinstance(v, list):
            yaml_in[k] = ', '.join(v)
    return yaml_in


if __name__ == '__main__':
    # either convert from tsv to YAML or YAML to tsv
    for dataset in sys.argv[1:]:
        for mode_ in ['raw', 'processed']:
            print(f'{dataset=}, {mode_=}')
            tsv_file = f'{mode_}_data/{dataset}/{dataset}_info.tsv'
            yaml_file = f'{mode_}_data/{dataset}/{dataset}_info.yaml'
            if (os.path.exists(tsv_file) and not os.path.exists(yaml_file)):
                # tsv -> YAML
                result = read_tsv(tsv_file)
                result = make_liststrings_to_list(result)
                result = change_to_primitive_types(result)
                result = to_hierarchical({k: v for k, v in result.items()
                                          if not isna(v)})
                with open(yaml_file, 'w') as out:
                    yaml.safe_dump(result, out, default_flow_style=False, sort_keys=False, allow_unicode=True)
            elif (os.path.exists(yaml_file) and not os.path.exists(tsv_file)):
                # YAML -> tsv
                result = read_yaml(yaml_file)
                result = fill_in_missing(result)
                pd.json_normalize(result, sep='.').set_index('id').to_csv(tsv_file, sep='\t')
            elif (os.path.exists(yaml_file) and os.path.exists(tsv_file)):
                # just make sure they are equal
                result_yaml = read_yaml(yaml_file)
                result_yaml_flat = pd.json_normalize(result_yaml, sep='.').to_dict(orient='records')[0]
                result_tsv = read_tsv(tsv_file)
                try:
                    same_content = all([(isna(result_tsv[k]) and k not in result_yaml_flat)
                                        or (isna(result_tsv[k]) and isna(result_yaml_flat[k]))
                                        or (result_tsv[k] == result_yaml_flat[k])
                                        for k in set(result_yaml_flat) | set(result_tsv)])
                except KeyError:
                    same_content = False
                if not same_content:
                    print(f'WARNING: {dataset} info files contain conflicting information!', yaml_file, tsv_file, result_yaml_flat, result_tsv)
