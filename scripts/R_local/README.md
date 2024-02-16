# Run preprocessing locally

Using the scripts in this folder is deprecated, instead use the docker container with the scripts in the `R_ci` directory, as described below.

1. Download the preprocessing docker container:
```shell
docker pull ghcr.io/michaelwitting/repo_rt_preprocessing:latest
```
2. Run scripts from within the RepoRT main directory:
```shell
docker run -v $(pwd)/scripts:/scripts -v $(pwd)/example:/example -v $(pwd)/resources:/resources \
           -v $(pwd)/raw_data:/raw_data -v $(pwd)/processed_data:/processed_data \
           ghcr.io/michaelwitting/repo_rt_preprocessing:latest Rscript scripts/R_ci/compounds_standardize.R <dataset ID(s)>
```
  - the `-v`-settings allow the docker container to access your RepoRT files/scripts
  - on windows, replace `$(pwd)` with `%cd%` (when using `cmd`) or `${PWD}` (when using PowerShell)
  - `<dataset ID(s)>` are the dataset IDs, separated by space you want to preprocess, e.g.: `'0001' '0280' '0003'`
  - substitute `Rscript scripts/R_ci/compounds_standardize.R` with the script you want to run, the usual order is:
    1. `Rscript scripts/R_ci/compounds_standardize.R`
    2. `Rscript scripts/R_ci/compounds_classyfire.R`
    3. `Rscript scripts/R_ci/compounds_descriptors.R`
    4. `Rscript scripts/R_ci/compounds_fingerprints.R`
    5. `Rscript scripts/R_ci/metadata_standardize.R`
    6. `Rscript scripts/R_ci/compounds_overview.R`
    7. `Rscript scripts/R_ci/files_complete.R`
    8. `python3 scripts/Python/datasets_overview.py` (without <dataset ID(s)>)
    9. `python3 scripts/Python/validation_qspr.py`
    10. `python3 scripts/Python/validation_order.py --mode same_condition`
    11. `python3 scripts/Python/validation_order.py --mode systematic`
