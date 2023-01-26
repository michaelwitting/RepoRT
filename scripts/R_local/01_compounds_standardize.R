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

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# get list of all folders ------------------------------------------------------
data_folders <- list.dirs("raw_data", full.names = TRUE, recursive = FALSE)

# filter potential data folders found in negative list
if(!length(negative_list) == 1 && !is.na(negative_list)) {
  data_folders <- data_folders[which(!str_detect(data_folders, paste0(negative_list, collapse = "|")))]
}

# read data  and perform standardization ----------------------------------------
for(data_folder in data_folders) {

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


  # ============================================================================
  # standardize canonical smiles
  # ============================================================================
  rt_data %>%
    select(id, pubchem.smiles.canonical) %>%
    write_tsv("temp.txt", col_names = FALSE)

  # perform standardization ----------------------------------------------------
  #shell("java -jar scripts/Java/structure-standardization.jar temp.txt")
  system("python3 scripts/Python/standardize.py temp.txt")

  # read standarized smiles ----------------------------------------------------
  smiles_canonical_std <- read_tsv("temp.txt_standardized", col_names = FALSE)
  smiles_canonical_failed <- read_tsv("temp.txt_failed", col_names = FALSE)

  # check if it contains data and rename column names --------------------------
  if(nrow(smiles_canonical_std) > 0) {

    smiles_canonical_std <- smiles_canonical_std %>%
      rename(id = X1,
             smiles.std = X2)

  } else {

    smiles_canonical_std <- tibble(id = character(0),
                                   smiles.std = character(0))

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
  file.remove("temp.txt")
  file.remove("temp.txt_standardized")
  file.remove("temp.txt_failed")

  # ============================================================================
  # standardize isomeric smiles
  # ============================================================================
  rt_data %>%
    select(id, pubchem.smiles.isomeric) %>%
    write_tsv("temp.txt", col_names = FALSE)

  # perform standardization ----------------------------------------------------
  #shell("java -jar scripts/Java/structure-standardization.jar temp.txt")
  system("python3 scripts/Python/standardize.py temp.txt")

  # read standarized smiles ----------------------------------------------------
  smiles_isomeric_std <- read_tsv("temp.txt_standardized", col_names = FALSE)
  smiles_isomeric_failed <- read_tsv("temp.txt_failed", col_names = FALSE)

  # check if it contains data and rename column names --------------------------
  if(nrow(smiles_isomeric_std) > 0) {

    smiles_isomeric_std <- smiles_isomeric_std %>%
      rename(id = X1,
             smiles.std = X2)

  } else {

    smiles_isomeric_std <- tibble(id = character(0),
                                  smiles.std = character(0))

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

  smiles_canonical_failed <- smiles_isomeric_failed %>%
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
  file.remove("temp.txt")
  file.remove("temp.txt_standardized")
  file.remove("temp.txt_failed")

  # ============================================================================
  # read and standardize meta data
  # ============================================================================
  meta_data_file <- list.files(data_folder,
                               pattern = "_metadata.txt$",
                               full.names = TRUE)

  meta_data <- read_tsv(meta_data_file)

  # ============================================================================
  # write results
  # ============================================================================
  # create new path ------------------------------------------------------------
  result_folder <- paste0("processed_data/", basename(data_folder))

  if(!dir.exists(result_folder)) {
    dir.create(result_folder)
  }

  if(nrow(rt_data_canonical_success) > 0) {

    write_tsv(rt_data_canonical_success,
              paste0(result_folder,
                     "/",
                     basename(data_folder),
                     "_rtdata_canonical_success.txt"),
              na = "")

  }

  if(nrow(rt_data_canonical_failed) > 0) {

    write_tsv(rt_data_canonical_failed,
              paste0(result_folder,
                     "/",
                     basename(data_folder),
                     "_rtdata_canonical_failed.txt"),
              na = "")

  }

  if(nrow(rt_data_isomeric_success) > 0) {

    write_tsv(rt_data_isomeric_success,
              paste0(result_folder,
                     "/",
                     basename(data_folder),
                     "_rtdata_isomeric_success.txt"),
              na = "")

  }

  if(nrow(rt_data_isomeric_failed) > 0) {

    write_tsv(rt_data_isomeric_failed,
              paste0(result_folder,
                     "/",
                     basename(data_folder),
                     "_rtdata_isomeric_failed.txt"),
              na = "")

  }

  if(nrow(meta_data) > 0) {

    write_tsv(meta_data,
              paste0(result_folder,
                     "/",
                     basename(data_folder),
                     "_metadata.txt"),
              na = "")

  }
}
