r"""Set metadata fields of datasets in raw_data (both TSV and YAML), changing nothing else.

Usage: python3 scripts/Python/set_metadata.py 0262 0263 column.id=2.1 [field=value ...]

Afterwards, run the "Preprocessing of specified datasets" workflow with only metadata
standardization enabled, which regenerates processed_data (incl. column.t0):
  gh workflow run preprocess_manual.yaml --ref <branch> -f datasets="0262 0263" -f do_standardize=false \
     -f do_classyfire=false -f do_descriptors=false -f do_fingerprints=false -f do_validation=false
"""
import sys
import yaml

def set_tsv(tsv_file, changes):
    with open(tsv_file, newline='') as f:
        text = f.read()
    nl = '\r\n' if '\r\n' in text else '\n'
    header, row, *rest = text.split(nl)
    header, row = header.split('\t'), row.split('\t')
    for field, value in changes.items():
        if field not in header:
            sys.exit(f'{tsv_file}: unknown field {field}')
        print(f'{tsv_file}: {field}: {row[header.index(field)]!r} -> {value!r}')
        row[header.index(field)] = value
    with open(tsv_file, 'w', newline='') as f:
        f.write(nl.join(['\t'.join(header), '\t'.join(row), *rest]))

def get(data, path):
    for p in path:
        data = data.get(p) if isinstance(data, dict) else None
    return data

def set_yaml(yaml_file, changes):
    with open(yaml_file) as f:
        original = f.read()
    data, changed = yaml.safe_load(original), False
    for field, value in changes.items():
        try:  # same types as written by convert_metadata.py (numbers, strings, None for missing values)
            value = yaml.safe_load(value) if value not in ('', 'NA') else None
        except yaml.YAMLError:  # e.g. "%"
            pass
        parts = field.split('.')
        if parts[0] == 'column':  # column.<key>
            path = ['column', '.'.join(parts[1:])]
        elif parts[0] == 'eluent':  # eluent.<A>.<chemical>[.unit], chemical is either "x: value" or "x: {value: .., unit: ..}"
            chemical = '.'.join(parts[2:]).removesuffix('.unit')
            node = get(data, ['eluent', parts[1], chemical])
            if field.endswith('.unit') or isinstance(node, dict):
                path = ['eluent', parts[1], chemical, 'unit' if field.endswith('.unit') else 'value']
            else:
                path = ['eluent', parts[1], chemical]
        else:  # e.g. gradient.* fields are only stored in the TSV
            continue
        old = get(data, path)
        if old == value or (old is None and value in (None, 0)):  # unchanged (e.g. 40 == 40.0; YAML omits 0 eluents)
            continue
        print(f'{yaml_file}: {field}: {old!r} -> {value!r}')
        parent = data
        for p in path[:-1]:
            if not isinstance(parent.get(p), dict):  # create, or "x: value" -> {value: ..}
                parent[p] = {} if parent.get(p) is None else {'value': parent[p]}
            parent = parent[p]
        parent[path[-1]] = value
        changed = True
    if changed:
        out = yaml.safe_dump(data, default_flow_style=False, sort_keys=False, allow_unicode=True)
        if f"id: '{data.get('id')}'\n" in original:  # keep quoted dataset ID as is
            out = out.replace(f"id: {data.get('id')}\n", f"id: '{data.get('id')}'\n", 1)
        with open(yaml_file, 'w') as f:
            f.write(out)

if __name__ == '__main__':
    datasets = [a for a in sys.argv[1:] if '=' not in a]
    changes = dict(a.split('=', 1) for a in sys.argv[1:] if '=' in a)
    if not datasets or not changes:
        sys.exit(__doc__)
    for dataset in datasets:
        set_tsv(f'raw_data/{dataset}/{dataset}_metadata.tsv', changes)
        set_yaml(f'raw_data/{dataset}/{dataset}_metadata.yaml', changes)
