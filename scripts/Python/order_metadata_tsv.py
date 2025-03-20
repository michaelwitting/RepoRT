"""tool bringing metadata TSV columns in the same order as the example dataset 0259
Usage: python order_metadata_tsv.py processed_data/0437/0437_metadata.tsv
"""

import pandas as pd
import sys

f_in = sys.argv[1]
df = pd.read_csv(f_in, sep='\t', dtype={'id': str})
example_df = pd.read_csv('processed_data/0259/0259_metadata.tsv', sep='\t', dtype={'id': str})
assert set(example_df.columns) == set(df.columns), f'different columns: {set(example_df.columns) ^ set(df.columns)}'
df[example_df.columns].to_csv(f_in, sep='\t', index=False)
