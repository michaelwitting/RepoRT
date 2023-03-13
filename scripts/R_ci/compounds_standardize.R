## ---------------------------
##
## Script name: compounds_standardize.R
##
## Purpose of script: Standardization of structures according to PubChem
##
## Author: Dr. Michael Witting
##
## Date Created: 2020-06-19
##
## Copyright (c) Michael Witting, 2020
## Email: michael.witting@helmholtz-muenchen.de
##
## -----------------------------------------------------------------------------
##
## Notes:
##
## This script performs a PubChem API based standardization of SMILES. Data is
## splitted into substances having isomeric or canonical SMILES.
##
## -----------------------------------------------------------------------------

# ==============================================================================
# load required libraries
# ==============================================================================
library(tidyverse)
library(rcdk)
library(rinchi)
source("scripts/R_ci/helper_functions.R")

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# folders from command arguments -----------------------------------------------
data_folders <- file.path('raw_data', commandArgs(trailingOnly=TRUE))

# read data  and perform standardization ----------------------------------------
for(data_folder in data_folders) {

  cat(paste(Sys.time(), "processing", data_folder, "\n"))

  # ============================================================================
  # read and standardize compound data
  # ============================================================================
  rt_data_file <- list.files(data_folder,
                             pattern = "_rtdata.txt$",
                             full.names = TRUE)

  if (length(rt_data_file) == 0){
    warning("no rtdata file exists for ", data_folder, ", skipping")
    next
  }

  ## get SMILES for entries where only database IDs are specified
  system(paste("python3 scripts/Python/ids_to_smiles.py", rt_data_file))

  rt_data <- read_tsv(rt_data_file,
                      col_types = cols(id = col_character(),
                                       name = col_character(),
                                       formula = col_character(),
                                       rt = col_double(),
                                       pubchem.cid = col_character(),
                                       pubchem.smiles.isomeric = col_character(),
                                       pubchem.smiles.canonical = col_character(),
                                       pubchem.inchi = col_character(),
                                       pubchem.inchikey = col_character(),
                                       id.chebi = col_character(),
                                       id.hmdb = col_character(),
                                       id.lipidmaps = col_character(),
                                       id.kegg = col_character()))

  # get canonical SMILES for entries with only isomeric ones
  sp <- get.smiles.parser()
  rt_data <- rt_data %>% mutate(pubchem.smiles.canonical=mapply(
    function (canonical, isomeric) ifelse(is.na(canonical), ifelse(
      !is.na(isomeric),
      # convert isomeric to canonical SMILES
      get.smiles(parse.smiles(isomeric)[[1]], smiles.flavors('Generic')), NA),
      # keep canonical
      canonical),
    canonical=rt_data$pubchem.smiles.canonical, isomeric=rt_data$pubchem.smiles.isomeric, USE.NAMES=F))

  # get formula for entries without one
  rt_data <- rt_data %>% mutate(formula=mapply(
    function (formula, smiles) ifelse(is.na(formula), ifelse(
      !is.na(smiles),
      # get formula from SMILES
      attr(get.mol2formula(parse.smiles(smiles)[[1]]), "string"), NA),
      # keep formula
      formula),
    formula=rt_data$formula, smiles=rt_data$pubchem.smiles.canonical, USE.NAMES=F))


  # try to use standardized SMILES from cache
  rt_data <- rt_data %>% add_column(
    "pubchem.smiles.canonical.std"=sapply(rt_data$pubchem.smiles.canonical,
                                          function (s) query_cache("smiles", s), USE.NAMES=F),
    "pubchem.smiles.isomeric.std"=sapply(rt_data$pubchem.smiles.isomeric,
                                         function (s) query_cache("smiles", s), USE.NAMES=F)) %>%
    ## make sure those columns are of type "character"
    mutate(across(pubchem.smiles.canonical.std, as.character)) %>%
    mutate(across(pubchem.smiles.isomeric.std, as.character))

  # ============================================================================
  # standardize canonical smiles
  # ============================================================================

  cat("Canonical standardized SMILES retrieved from cache:",
      nrow(rt_data %>% filter(!is.na(pubchem.smiles.canonical.std) & !is.na(pubchem.smiles.canonical))), "\n")
  cat("Canonical standardized SMILES to compute:",
      nrow(rt_data %>% filter(is.na(pubchem.smiles.canonical.std) & !is.na(pubchem.smiles.canonical))), "\n")

  rt_data %>%
    filter(is.na(pubchem.smiles.canonical.std)) %>%
    select(id, pubchem.smiles.canonical) %>%
    write_tsv("temp.txt", col_names = FALSE, na = "")

  # perform standardization ----------------------------------------------------
  #shell("java -jar scripts/Java/structure-standardization.jar temp.txt")
  system("python3 scripts/Python/standardize.py temp.txt")

  # read standarized smiles ----------------------------------------------------
  smiles_canonical_std <- read_tsv("temp.txt_standardized", col_names = FALSE, show_col_types = FALSE)
  smiles_canonical_failed <- read_tsv("temp.txt_failed", col_names = FALSE, show_col_types = FALSE)

  # check if it contains data and rename column names --------------------------
  if(nrow(smiles_canonical_std) > 0) {

    ## cached standardized SMILES plus newly computed ones
    smiles_canonical_std <- rt_data %>% select(id, pubchem.smiles.canonical.std) %>%
      rows_update(smiles_canonical_std %>% rename(id = X1, pubchem.smiles.canonical.std = X2),
                  by = "id") %>%
      filter(!is.na(pubchem.smiles.canonical.std)) %>%
      rename(smiles.std = pubchem.smiles.canonical.std)


  } else {

    smiles_canonical_std <- rt_data %>% select(id, pubchem.smiles.canonical.std) %>%
      filter(!is.na(pubchem.smiles.canonical.std)) %>%
      rename(smiles.std = pubchem.smiles.canonical.std)

  }

  if(nrow(smiles_canonical_failed) > 0) {

    smiles_canonical_failed <- smiles_canonical_failed %>%
      rename(id = X1,
             smiles.std = X2,
             status = X3)

  } else {

    smiles_canonical_failed <- tibble(id = character(0),
                                      smiles.std = character(0),
                                      status = character(0))

  }


  # calculate InChI and InChIKey -----------------------------------------------
  smiles_canonical_std <- smiles_canonical_std %>%
    mutate(inchi.std = sapply(smiles.std, get.inchi),
           inchikey.std = sapply(smiles.std, get.inchi.key))

  smiles_canonical_failed <- smiles_canonical_failed %>%
    mutate(inchi.std = NA,
           inchikey.std = NA)

  # combine tables and write results to clipboard ------------------------------
  rt_data_canonical_success <- right_join(rt_data %>% select(id,
                                              name,
                                              formula,
                                              rt),
                                          smiles_canonical_std)

  rt_data_canonical_failed <- right_join(rt_data %>% select(id,
                                                 name,
                                                 formula,
                                                 rt),
                                         smiles_canonical_failed)

  # remove temp files ----------------------------------------------------------
  for (temp_file in c("temp.txt", "temp.txt_standardized", "temp.txt_failed"))
    if (file.exists(temp_file)) file.remove(temp_file)

  # ============================================================================
  # standardize isomeric smiles
  # ============================================================================

  cat("Isomeric standardized SMILES retrieved from cache:",
      nrow(rt_data %>% filter(!is.na(pubchem.smiles.isomeric.std) & !is.na(pubchem.smiles.isomeric))), "\n")
  cat("Isomeric standardized SMILES to compute:",
      nrow(rt_data %>% filter(is.na(pubchem.smiles.isomeric.std) & !is.na(pubchem.smiles.isomeric))), "\n")

  rt_data %>%
    filter(is.na(pubchem.smiles.isomeric.std)) %>%
    select(id, pubchem.smiles.isomeric) %>%
    write_tsv("tempiso.txt", col_names = FALSE, na = "")

  # perform standardization ----------------------------------------------------
  system("python3 scripts/Python/standardize.py tempiso.txt")

  # read standarized smiles ----------------------------------------------------
  smiles_isomeric_std <- read_tsv("tempiso.txt_standardized", col_names = FALSE, show_col_types = FALSE)
  smiles_isomeric_failed <- read_tsv("tempiso.txt_failed", col_names = FALSE, show_col_types = FALSE)

  # check if it contains data and rename column names --------------------------
  if(nrow(smiles_isomeric_std) > 0) {

    ## cached standardized SMILES plus newly computed ones
    smiles_isomeric_std <- rt_data %>% select(id, pubchem.smiles.isomeric.std) %>%
      rows_update(smiles_isomeric_std %>% rename(id = X1, pubchem.smiles.isomeric.std = X2),
                  by = "id") %>%
      filter(!is.na(pubchem.smiles.isomeric.std)) %>%
      rename(smiles.std = pubchem.smiles.isomeric.std)

  } else {

    smiles_isomeric_std <- rt_data %>% select(id, pubchem.smiles.isomeric.std) %>%
      filter(!is.na(pubchem.smiles.isomeric.std)) %>%
      rename(smiles.std = pubchem.smiles.isomeric.std)

  }

  if(nrow(smiles_isomeric_failed) > 0) {

    smiles_isomeric_failed <- smiles_isomeric_failed %>%
      rename(id = X1,
             smiles.std = X2,
             status = X3)

  } else {

    smiles_isomeric_failed <- tibble(id = character(0),
                                      smiles.std = character(0),
                                      status = character(0))

  }


  # calculate InChI and InChIKey -----------------------------------------------
  smiles_isomeric_std <- smiles_isomeric_std %>%
    mutate(inchi.std = sapply(smiles.std, get.inchi),
           inchikey.std = sapply(smiles.std, get.inchi.key))

  smiles_isomeric_failed <- smiles_isomeric_failed %>%
    mutate(inchi.std = NA,
           inchikey.std = NA)

  # combine tables and write results to clipboard ------------------------------
  rt_data_isomeric_success <- right_join(rt_data %>% select(id,
                                                             name,
                                                             formula,
                                                             rt),
                                          smiles_isomeric_std)

  rt_data_isomeric_failed <- right_join(rt_data %>% select(id,
                                                            name,
                                                            formula,
                                                            rt),
                                         smiles_isomeric_failed)

  # remove temp files ----------------------------------------------------------
  for (temp_file in c("tempiso.txt", "tempiso.txt_standardized", "tempiso.txt_failed"))
    if (file.exists(temp_file)) file.remove(temp_file)

  # ============================================================================
  # read and standardize meta data
  # ============================================================================
  meta_data_file <- list.files(data_folder,
                               pattern = "_metadata.txt$",
                               full.names = TRUE)

  meta_data <- read_tsv(meta_data_file, show_col_types = FALSE)

  # ============================================================================
  # write results
  # ============================================================================
  # create new path ------------------------------------------------------------
  result_folder <- paste0("processed_data/", basename(data_folder))

  if(!dir.exists(result_folder)) {
    dir.create(result_folder)
  }

  for (output in list(
    list(rt_data_canonical_success, paste0(result_folder, "/", basename(data_folder), "_rtdata_canonical_success.txt")),
    list(rt_data_canonical_failed, paste0(result_folder, "/", basename(data_folder), "_rtdata_canonical_failed.txt")),
    list(rt_data_isomeric_success, paste0(result_folder, "/", basename(data_folder), "_rtdata_isomeric_success.txt")),
    list(rt_data_isomeric_failed, paste0(result_folder, "/", basename(data_folder), "_rtdata_isomeric_failed.txt")),
    list(meta_data, paste0(result_folder, "/", basename(data_folder), "_metadata.txt"))
    )) {
      data <- output[[1]]
      out_file <- output[[2]]
      if(nrow(data) > 0) {
        write_tsv(data, out_file, na = "")
      } else {
        # file shouldn't exist -> remove
        if (file.exists(out_file)) file.remove(out_file)
      }
    }

}
