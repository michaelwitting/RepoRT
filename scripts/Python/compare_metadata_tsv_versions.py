"""tool showing metadata TSV differences between two versions.
Usage: python compare_metadata_tsv_versions.py processed_data/0259/0259_metadata.tsv /path/to/old/RepoRT/version /path/to/new/RepoRT/version
"""

import pandas as pd
import sys
import os.path

rel_path = sys.argv[1]
root_old, root_new = sys.argv[2:]

df_old = pd.read_csv(os.path.join(root_old, rel_path), sep='\t', dtype={'id': str})
df_new = pd.read_csv(os.path.join(root_new, rel_path), sep='\t', dtype={'id': str})
metadata_old = dict(df_old.iloc[0])
metadata_new = dict(df_new.iloc[0])

for k in set(metadata_old) | set(metadata_new):
    if (k not in metadata_old):
        print(f'+  column {k}; is now {metadata_new[k]}')
    elif (k not in metadata_new):
        print(f'-  column {k}; was {metadata_old[k]}')
    else:
        v_old = metadata_old[k]
        v_new = metadata_new[k]
        if ((pd.isna(v_old) and pd.isna(v_new))                  # both NaN
            or all(pd.isna(v) or v == 0 for v in [v_old, v_new]) # both NaN or 0
            or (v_old == v_new)):                                # simply equal
            pass
        else:
            print(f'+- value {k}; {v_old} -> {v_new}')
