#!/usr/bin/env python3
"""Back-propagate PSI-MS column-model MS:IDs into the repo-rt catalog.

The return leg of the cross-repo loop. psi-ms-CV is the sole authority for ID
assignment; this script only MIRRORS the assigned ids into the "psi_ms_id" column of
resources/column_database/column_database.tsv, by an exact (company, Column name) join
against the mapping psi-ms-CV publishes at .github/repo-rt/psi-ms-column-ids.tsv. The
keys are normalised the same way the generator normalises its keys, so the join is a
dumb exact-string lookup -- no leaf-label or collision logic is duplicated.

It is deliberately conservative, because repo-rt is *upstream* of id assignment:
  * a row whose (company, Column name) is in the mapping is set to that id -- filling a
    blank cell or updating a changed one (e.g. after a rename minted a new id);
  * a row NOT in the mapping is LEFT AS-IS -- a brand-new repo-rt model that psi-ms-CV
    has not minted yet stays blank until a later cycle, and an existing id is never
    erased just because the (possibly older) mapping does not list it;
  * an empty mapping aborts (the download almost certainly failed) rather than touching
    the catalog.

Only the psi_ms_id field is edited (the column is appended if absent); quoting and
spacing on every other field survive byte-for-byte, and re-running with an unchanged
mapping is a no-op.

In repo-rt CI the mapping is fetched by raw URL:
    curl -fsSL -o psi-ms-column-ids.tsv \\
      https://raw.githubusercontent.com/HUPO-PSI/psi-ms-CV/master/.github/repo-rt/psi-ms-column-ids.tsv

Usage:
    python add_psi_ms_id.py --mapping psi-ms-column-ids.tsv \\
        --catalog resources/column_database/column_database.tsv [--report report.md]
"""
import argparse
import sys

ID_COL = "psi_ms_id"


def norm(text):
    """Normalise a join key the way the generator does -- clean(s.strip()): strip, then
    drop C0 control chars -- so the catalog keys match the mapping's cleaned
    (company, Column name) even if a cell carries an interior control char."""
    return "".join(ch for ch in text.strip() if ch >= " ")


def read_mapping(path):
    """{(company, Column name): psi_ms_id} from the published mapping TSV."""
    mapping = {}
    for line in open(path, encoding="utf-8").read().split("\n"):
        if not line or line.startswith("company\t"):
            continue
        company, name, ms_id = line.split("\t")
        mapping[(norm(company), norm(name))] = ms_id.strip()
    return mapping


def back_propagate(catalog_path, mapping):
    """Fill/refresh the psi_ms_id column of catalog_path in place from `mapping`.

    Returns a report dict {filled, changed, blank_new, preserved}. Raises ValueError on
    an empty mapping or a header missing the company / Column name columns."""
    if not mapping:
        raise ValueError("mapping is empty; the download almost certainly failed -- aborting")

    # Read raw bytes so line endings survive exactly; a strict UTF-8 decode is a sanity check.
    lines = open(catalog_path, "rb").read().decode("utf-8").split("\n")
    header = lines[0].split("\t")
    if "company" not in header or "Column name" not in header:
        raise ValueError(f"{catalog_path} header lacks 'company'/'Column name': {header[:5]}...")
    company_i, name_i = header.index("company"), header.index("Column name")
    has_id = ID_COL in header
    id_i = header.index(ID_COL) if has_id else None
    need = max(company_i, name_i, id_i) if has_id else max(company_i, name_i)

    rep = {"filled": 0, "changed": 0, "blank_new": 0, "preserved": 0}
    for k, line in enumerate(lines):
        if line == "":
            continue
        fields = line.split("\t")
        if k == 0:
            if not has_id:
                fields.append(ID_COL)
                lines[k] = "\t".join(fields)
            continue
        if len(fields) <= need:
            if not has_id:  # appending the column: keep every row's width consistent
                fields.append("")
                lines[k] = "\t".join(fields)
            continue
        existing = fields[id_i].strip() if has_id else ""
        key = (norm(fields[company_i]), norm(fields[name_i]))
        if not all(key):
            new = existing  # blank company/name: not a model, leave as-is
        elif key in mapping:
            new = mapping[key]
            if existing == "":
                rep["filled"] += 1
            elif existing != new:
                rep["changed"] += 1
        elif existing:
            new = existing  # not in this mapping: keep the id we already have
            rep["preserved"] += 1
        else:
            new = ""  # new repo-rt model, no id yet -> stays blank, fills a later cycle
            rep["blank_new"] += 1
        if has_id:
            fields[id_i] = new
        else:
            fields.append(new)
        lines[k] = "\t".join(fields)

    open(catalog_path, "w", encoding="utf-8", newline="").write("\n".join(lines))
    return rep


def report_markdown(rep, catalog_path):
    return "\n".join([
        f"- catalog: `{catalog_path}`",
        f"- psi_ms_id filled (was blank): **{rep['filled']}**",
        f"- psi_ms_id changed (e.g. rename): **{rep['changed']}**",
        f"- still blank (new models awaiting a PSI-MS id): **{rep['blank_new']}**",
        f"- existing id preserved (not in this mapping): **{rep['preserved']}**",
    ]) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--mapping", default="psi-ms-column-ids.tsv",
                    help="the psi-ms-CV mapping TSV (company / Column name / psi_ms_id)")
    ap.add_argument("--catalog", default="resources/column_database/column_database.tsv",
                    help="the repo-rt column_database.tsv to fill in place")
    ap.add_argument("--report", help="write a Markdown summary to this path (for the PR body)")
    args = ap.parse_args()

    rep = back_propagate(args.catalog, read_mapping(args.mapping))
    print(f"wrote {args.catalog}")
    print(f"filled={rep['filled']} changed={rep['changed']} "
          f"blank_new={rep['blank_new']} preserved={rep['preserved']}")
    if rep["filled"] + rep["changed"] == 0 and rep["preserved"] + rep["blank_new"] > 0:
        print("WARNING: nothing matched the mapping -- check key normalisation / the "
              "downloaded mapping is current", file=sys.stderr)
    if args.report:
        open(args.report, "w", encoding="utf-8").write(report_markdown(rep, args.catalog))
        print(f"wrote {args.report}")


if __name__ == "__main__":
    main()
