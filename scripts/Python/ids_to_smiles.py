from zeep import Client
import urllib.request
import json
import sys
import pandas as pd
import os
import pubchempy as pcp

def is_isomeric(smiles):
    return any(c in smiles for c in ['\\', '/', '@'])

def is_na(x):
    if isinstance(x, str):
        return x == ''
    else:
        return pd.isna(x)

def get_formula(smiles):
    return pcp.get_compounds(smiles, 'smiles')[0].molecular_formula

def inchi_to_smiles(inchi):
    compound = pcp.get_compounds(inchi, 'inchi')[0]


def get_pubchem_smiles(id_):
    id_ = int(id_)              # might be float
    # instead of isomeric also canonical is possible
    return (urllib.request.urlopen(f'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/{id_}/property/IsomericSMILES/TXT')
            ).read().decode().strip()

def get_chebi_smiles(id_):
    client = Client('https://www.ebi.ac.uk/webservices/chebi/2.0/webservice?wsdl')
    return client.service.getCompleteEntity(id_)['smiles']

def get_hmdb_smiles(id_):
    return (urllib.request.urlopen(f'https://hmdb.ca/structures/metabolites/{id_}/download.smiles')
            ).read().decode()

def get_kegg_smiles(id_):
    kegg_id, cid = (urllib.request.urlopen(f'https://rest.kegg.jp/conv/pubchem/{id_}')
                    ).read().decode().strip().split('\t')
    return get_pubchem_smiles(cid)

def get_lipidmaps_smiles(id_):
    return json.load((urllib.request.urlopen(f'https://www.lipidmaps.org/rest/compound/lm_id/{id_}/smiles/')))['smiles']

# with priorities
IDS = {'pubchem.cid': (get_pubchem_smiles, 0),
       'id.chebi': (get_chebi_smiles, 2),
       'id.hmdb': (get_hmdb_smiles, 2),
       'id.lipidmaps': (get_lipidmaps_smiles, 2),
       'id.kegg': (get_kegg_smiles, 1)}

def get_smiles(id_, id_type):
    if (id_type not in IDS):
        raise Exception('unknown ID type', id_type)
    return IDS[id_type][0](id_)

if __name__ == '__main__':
    in_file = sys.argv[1]
    changed = False
    df = pd.read_csv(in_file, sep='\t', index_col='id', converters={'pubchem.cid': str})
    # add missing columns
    example_df = pd.read_csv('example/0259_rtdata.tsv', sep='\t', index_col=0)
    for c in example_df.columns.tolist():
        if c not in df.columns.tolist():
            df[c] = None
            changed = True
    for i, r in df.iterrows():
        if not (is_na(df.loc[i, 'pubchem.smiles.canonical']) or is_na(df.loc[i, 'pubchem.smiles.isomeric'])):
            # TODO: for large datasets, find a way to remember where there is no further information to retrieve
            continue
        for id_type, _ in sorted(IDS.items(), key=lambda x: x[1][1]):
            if id_type not in df.columns.tolist():
                continue
            id_ = df.loc[i, id_type]
            if not is_na(id_):
                try:
                    smiles = get_smiles(id_, id_type)
                    if is_isomeric(smiles) and is_na(df.loc[i, 'pubchem.smiles.isomeric']):
                        # update isomeric SMILES only if not set already
                        df.at[i, 'pubchem.smiles.isomeric'] = smiles
                        print(f'retrieved isomeric SMILES for {i} via {id_type} with ID {id_}')
                        changed = True
                        continue
                    elif not is_isomeric(smiles) and is_na(df.loc[i, 'pubchem.smiles.canonical']):
                        # update canonical SMILES only if not set already
                        df.at[i, 'pubchem.smiles.canonical'] = smiles
                        print(f'retrieved canonical SMILES for {i} via {id_type} with ID {id_}')
                        changed = True
                        continue
                    else:
                        print(f'[{id_type}: {id_}] not updating SMILES; already specified:',
                              dict(~pd.isna(df.loc[i, ['pubchem.smiles.isomeric', 'pubchem.smiles.canonical']])),
                              'retrieved SMILES are', 'isomeric' if is_isomeric(smiles) else 'canonical')
                except Exception as e:
                    print(i, e)
    if (changed):
        os.rename(in_file, in_file + '.old')
        # TODO: restore example file column order
        df.to_csv(in_file, sep='\t')
