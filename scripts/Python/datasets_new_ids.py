import sys
import re
from os import remove, rename, mkdir
from os.path import exists
from glob import glob

# quotation characters as variables so regex doesn not look (even more) ugly
sq = "'"
dq = '"'

def get_new_ids(old_ids):
    # determine last/highest ID
    highest = sorted([int(l.split('\t')[0]) for i, l in enumerate(open('raw_data/studies.tsv'))
                      if i > 0 and l.strip() != '' and l.split('\t')[0] not in old_ids])[-1]
    return [str(highest + i + 1).rjust(4, '0') for i in range(len(old_ids))]

def delete_old_ids_in_overview(old_ids):
    for f in ['raw_data/studies.tsv', 'processed_data/studies.tsv']:
        lines = list(open(f).readlines())
        with open(f, 'w') as out:
            for line in lines:
                if any(re.match(rf'^{old_id}\s', line) for old_id in old_ids):
                    pass
                else:
                    out.write(line)

def adapt_file(f, old_id, new_id, ignore_contents=False):
    # ID to change is either at the beginning of a line (tsv) or its own key-value line (yaml)
    new_path = re.sub(f'^(.*)(raw|processed)_data/{old_id}/{old_id}_(.*)$',
                      rf'\1\2_data/{new_id}/{new_id}_\3', f)
    if ignore_contents:
        # just move the file and be done (for example the PDF files)
        rename(f, new_path)
        return
    with open(f) as in_handle, open(new_path, 'w') as out_handle:
        for line in in_handle:
            if f.endswith('.tsv') and re.match(rf'^{old_id}[_\s]', line):
                line = re.sub(rf'^{old_id}([_\s])', rf'{new_id}\1', line)
            elif f.endswith('.yaml') and line.strip().startswith('id') and line.strip().strip(f'{sq}{dq}').endswith(f'{old_id}'):
                line = re.sub(rf'(\s)[{sq}{dq}]?{old_id}[{sq}{dq}]?$', rf'\1{sq}{new_id}{sq}', line)
            out_handle.write(line)

if __name__ == '__main__':
    old_ids = sys.argv[1:]      # TODO: do something with the order?
    # get new IDs
    new_ids = get_new_ids(old_ids)
    for old_id, new_id in zip(old_ids, new_ids):
        # create new folders
        mkdir(f'raw_data/{new_id}')
        mkdir(f'processed_data/{new_id}')
        # change contents of info, metadata, rtdata and computed data files
        for f in glob(f'*_data/{old_id}/{old_id}_*'):
            adapt_file(f, old_id, new_id, ignore_contents=f.endswith('.pdf'))
            if exists(f):     # might already have been deleted (e.g., PDF files)
                remove(f)
    # remove old IDs from studies (overview) files
    delete_old_ids_in_overview(old_ids)
    print(' '.join(new_ids))
