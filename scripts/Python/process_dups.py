import pandas as pd
import sys
from glob import glob

POT_DUP_COLUMNS = ['smiles_key', 'rt']

def update_comment(old_comment, new_info):
    if old_comment is None or old_comment.strip() == '':
        return new_info
    elif new_info in old_comment.split('; '):
        # already there, nothing to update
        return old_comment
    else:
        return new_info + '; ' + old_comment

def remove_duplicates(df):
    len_orig = len(df)
    all_dups = df.loc[df.duplicated(keep=False)]
    df.drop_duplicates(inplace=True)
    # comment on the remaining duplicates (which are not duplicates anymore)
    for id_ in all_dups.index.tolist():
        if id_ in df.index.tolist():
            df.at[id_, 'comment'] = update_comment(df.at[id_, 'comment'], 'removed another duplicate entry')
    return len_orig - len(df)

def flag_pot_duplicates(df):
    pot_dups = df.duplicated(subset=POT_DUP_COLUMNS, keep=False)
    for entry in df.loc[pot_dups].index.tolist():
        df.at[entry, 'comment'] = update_comment(df.at[entry, 'comment'], 'potential duplicate')
    return pot_dups.sum()

def flag_doublets(df):
    doublets = df.duplicated(subset=['smiles_key'], keep=False)
    for entry in df.loc[doublets].index.tolist():
        df.at[entry, 'comment'] = update_comment(df.at[entry, 'comment'], 'doublet')
    return doublets.sum()

def delete_entries(ds, entries):
    entries = set(entries)      # faster
    for f in glob(f'processed_data/{ds}/{ds}_*.tsv'):
        lines = open(f).readlines()
        len_orig = len(lines)
        written = 0
        with open(f, 'w') as out:
            for line in lines:
                if line.split('\t')[0].strip() in entries:
                    continue
                out.write(line)
                written += 1
        print(f'deleted {len_orig - written} lines in {f}')


if __name__ == '__main__':
    for ds in sys.argv[1:]:
        f = f'raw_data/{ds}/{ds}_rtdata.tsv'
        df = pd.read_csv(f, sep='\t', index_col=0, converters={'pubchem.cid': str, 'comment': str})
        print('dataset', ds)
        if 'comment' not in df.columns.tolist():
            df['comment'] = ''
        original_entries = df.index.tolist()
        # first remove definite duplicates (whole row equal)
        removed = remove_duplicates(df)
        # helper SMILES column with most specific SMILES structure per compound
        df['smiles_key'] = [r['pubchem.smiles.isomeric'] if not pd.isna(r['pubchem.smiles.isomeric'])
                            else r['pubchem.smiles.canonical'] for i, r in df.iterrows()]
        # flag remaining potential duplicates
        flagged_dups = flag_pot_duplicates(df)
        # flag all doublets
        flagged_doublets = flag_doublets(df)
        # cleanup flag/comment field
        df.comment = [c.rstrip('; ') for c in df.comment]
        del df['smiles_key']
        print(pd.Series({'removed duplicates': removed,
                         'flagged_duplicates': flagged_dups,
                         'flagged doublets': flagged_doublets}).to_string())
        print(df.comment.value_counts().to_string())
        df.to_csv(f, sep='\t')
        # if already processed, remove duplicate entries also in "processed" files
        delete_entries(ds, set(original_entries) - set(df.index.tolist()))
