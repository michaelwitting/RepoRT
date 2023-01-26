## -----------------------------------------------------------------------------
##
## Script name: compounds_overview.R
##
## Purpose of script: Analyze RT data
##
## Author: Dr. Michael Witting
##
## Date Created: 2020-06-15
##
## Copyright (c) Michael Witting, 2020
## Email: michael.witting@helmholtz-muenchen.de
##
## -----------------------------------------------------------------------------
##
## Notes:
##
## This script gives an overview on the substances measured in the studies.
## Information is fetched from the RT data file.
##
## -----------------------------------------------------------------------------
#negative_list <- NA
negative_list <- c("0186", "0205", "0206", "0207", "0208", "0209", "0210",
                   "0211", "0212", "0213", "0214", "0215", "0216", "0217",
                   "0218")

# ==============================================================================
# execute all scripts on compounds
# ==============================================================================
source("01_compounds_standardize.R")
source("02_compounds_classyfire.R")
source("03_compounds_descriptors.R")
source("04_compounds_fingerprints.R")

# ==============================================================================
# execute all scripts on metadata
# ==============================================================================
source("05_metadata_standardize.R")

# ==============================================================================
# get overview on files
# ==============================================================================
source("06_files_complete.R")

# ==============================================================================
# generate overviews
# ==============================================================================
source("07_compounds_overview.R")
source("08_metadata_overview.R")
