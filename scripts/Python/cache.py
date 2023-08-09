"""Creates queriable cache from already standardized SMILES, computed descriptors, classyfire classes.
{'cached_files': {'processed_data/0340/0340_rtdata_isomeric_success.tsv': '5fc536d7f6b5948586e4f9fe361b4b4c', ...},
 'classyfire': {'UFIVEPVSAGBUSI-UHFFFAOYSA-N': (..., 'Amino acids and derivatives (CHEMONTID:0000347)', 'Alpha amino acids and derivatives (CHEMONTID:0000060)'),
                'C1C(NC(=O)NC1=O)C(=O)O': (..., 'Amino acids and derivatives (CHEMONTID:0000347)', 'Alpha amino acids and derivatives (CHEMONTID:0000060)')},
 'descriptors': {'C1[C@H](NC(=O)NC1=O)C(=O)O': {'logp': 2.1, ...},
                 'C1C(NC(=O)NC1=O)C(=O)O': {'logp': 2.1, ...}},
 'smiles': {'C1[C@H](NC(=O)NC1=O)C(=O)O': 'C1[C@H](NC(=O)NC1=O)C(=O)O',
            'C1C(NC(=O)NC1=O)C(=O)O': 'C1C(NC(=O)NC1=O)C(=O)O'}
}
"""

import json
import os.path
from glob import glob
from hashlib import md5
import os

def get_file_hashes(specific_file=None):
    return {f: md5(open(f, 'rb').read()).hexdigest()
            for f in (glob('processed_data/*/*_success.tsv')
                      if specific_file is None else [specific_file])
            if '_fingerprints_' not in f}

def is_isomeric(smiles):
    return any(c in smiles for c in ['\\', '/', '@'])

# NOTE: NAs are cached, too! (for now)
def cache_data(files):
    cache = {'cached_files': {}, 'classyfire': {}, 'descriptors': {}, 'smiles': {}}
    for f in files:
        try:
            processed_data = [line.strip('\n').split('\t') for line in open(f)]
            if ('_descriptors_' in f):
                # get canonical/isomeric SMILES mapping
                rtdata_lines = [line.split('\t') for line in open(f.replace('_descriptors_', '_rtdata_'))]
                id_index, smiles_index = map(rtdata_lines[0].index, ['id', 'smiles.std'])
                mapping = {line[id_index]: line[smiles_index] for line in rtdata_lines[1:]}
                # cache descriptors
                id_index = processed_data[0].index('id')
                descriptors_by_index = {i: field.strip() for i, field in enumerate(processed_data[0])
                                        if i != id_index}
                for line in processed_data[1:]:
                    if (len(line) != len(processed_data[0])):
                        print(f'ERROR in {f}: current line has a different number of fields as header ({len(line)}/{len(processed_data[0])})')
                        continue
                    smiles = mapping[line[id_index]]
                    for i, value in enumerate(line):
                        value = value.strip() # the last field might have '\n'
                        if (i == id_index):
                            continue
                        #if (value != 'NA' and value != ''):
                        cache['descriptors'].setdefault(smiles, {})[descriptors_by_index[i]] = value
                        # cache['descriptors'].setdefault(smiles, {}).setdefault(descriptors_by_index[i], []).append(value)
            elif ('_rtdata_' in f):
                ds = os.path.basename(os.path.dirname(f))
                raw_file = f'raw_data/{ds}/{ds}_rtdata.tsv'
                # get raw ID<->SMILES mapping
                raw_rtdata = [line.strip('\n').split('\t') for line in open(raw_file)]
                id_index, smiles_index = map(raw_rtdata[0].index, [
                    'id', 'pubchem.smiles.isomeric' if '_isomeric_' in f else 'pubchem.smiles.canonical'])
                try:
                    raw_mapping = {line[id_index]: line[smiles_index] for line in raw_rtdata[1:]}
                except Exception as e:
                    print([len(line) for line in raw_rtdata[1:]], id_index, smiles_index)
                    raise e
                id_index, smiles_index, inchikey_index = map(processed_data[0].index,
                                                             ['id', 'smiles.std', 'inchikey.std'])
                classyfire_fields = {c.strip(): i for i, c in enumerate(processed_data[0])
                                     if c.split('.')[0] == 'classyfire'}
                for line in processed_data[1:]:
                    if (len(line) != len(processed_data[0])):
                        print(f'ERROR in {f}: current line has a different number of fields as header ({len(line)}/{len(processed_data[0])})')
                        continue
                    raw_smiles = raw_mapping[line[id_index]]
                    processed_smiles = line[smiles_index]
                    if is_isomeric(raw_smiles) ^ is_isomeric(processed_smiles):
                        print('SMILES: isomeric information might be lost, not caching:', f, raw_smiles, processed_smiles)
                    else:
                        # cache standardized SMILES
                        cache['smiles'][raw_smiles] = processed_smiles
                    # cache classyfire
                    try:
                        inchikey = line[inchikey_index]
                        for c in classyfire_fields:
                            value = line[classyfire_fields[c]].strip()
                            # if (value != 'NA' and value != ''):
                            cache['classyfire'].setdefault(inchikey, {})[c] = value
                    except Exception as e:
                        print(f'WARNING: classyfire data from {f} will not be cached', e)
            elif ('_fingerprints_' in f):
                # not worth caching
                continue
            else:
                 print(f'WARNING: data from {f} will not be cached')
                 continue
            cache['cached_files'][f] = get_file_hashes(f)[f]
        except Exception as e:
            print(f'WARNING: data from {f} will not be cached', e)
    return cache

if __name__ == '__main__':
    cache = {'cached_files': {}, 'classyfire': {}, 'descriptors': {}, 'smiles': {}}
    # check if cache exists
    cache_file = '_computation_cache.json'
    if str(os.environ.get('PREPROCESSING_NOCACHE', 0)) == "1":
        print('emptying cache')
        with open(cache_file, 'w') as out:
            json.dump(cache, out)
        exit(0)
    try:
        #os.path.exists(cache_file) -> excepted
        cache = json.load(open(cache_file, 'r'))
    except Exception as e:
        print(e)
    # has something changed?
    new_file_hashes = get_file_hashes()
    if (set(cache['cached_files']) != set(new_file_hashes)
        or any(new_file_hashes[f] == cache['cached_files'][f]
               for f in new_file_hashes)):
        # get modified files
        changed = [f for f in new_file_hashes if f not in cache['cached_files']
                   or new_file_hashes[f] != cache['cached_files'][f]]
        new_cache = cache_data(changed)
        for key in new_cache:
            cache[key].update(new_cache[key])
        # dump
        with open(cache_file, 'w') as out:
            json.dump(cache, out)
