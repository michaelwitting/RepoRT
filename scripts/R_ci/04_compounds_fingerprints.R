## ---------------------------
##
## Script name: compounds_fingerprints.R
##
## Purpose of script: Calculate fingerprints for molecules using rcdk
##
## ---------------------------


# ==============================================================================
# load required libraries
# ==============================================================================
library(tidyverse)
library(rcdk)
## get smiles parser
sp <- get.smiles.parser()

## NOTE: caching should not be required

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# folders from command arguments -----------------------------------------------
data_folders <- file.path('processed_data', commandArgs(trailingOnly=TRUE))


# iterate through folder and add data to full_rt_data_canonical ----------------
for(data_folder in data_folders) {

  # canconical smiles data -----------------------------------------------------
  # read canonical smiles data
  rt_data_file <- list.files(data_folder,
                             pattern = "_rtdata_canonical_success.txt$",
                             full.names = TRUE)


  if(length(rt_data_file) == 1) {

    rt_data_canonical <- read_tsv(rt_data_file,
                                  col_types = cols(id = col_character(),
                                                   name = col_character(),
                                                   formula = col_character(),
                                                   rt = col_double(),
                                                   smiles.std = col_character(),
                                                   inchi.std = col_character(),
                                                   inchikey.std = col_character()))



    # perform computation
    fingerprints_ecfp6 <- sapply(rt_data_canonical$smiles.std, function(s) ifelse(is.na(s), NA, paste(attr(
      get.fingerprint(parse.smiles(s)[[1]], type="circular", circular.type="ECFP6"), "bits"), collapse=",")), USE.NAMES=F)
    fingerprints_maccs <- sapply(rt_data_canonical$smiles.std, function(s) ifelse(is.na(s), NA, paste(attr(
      get.fingerprint(parse.smiles(s)[[1]], type="maccs"), "bits"), collapse=",")), USE.NAMES=F)
    fingerprints_pubchem <- sapply(rt_data_canonical$smiles.std, function(s) ifelse(is.na(s), NA, paste(attr(
      get.fingerprint(parse.smiles(s)[[1]], type="pubchem"), "bits"), collapse=",")), USE.NAMES=F)

    # write results
    write_tsv(rt_data_canonical %>% select(id) %>% add_column(bits.on=fingerprints_ecfp6),
              gsub("_rtdata_canonical_success.txt", "_fingerprints_ecfp6_canonical_success.txt", rt_data_file),
              na = "")
    write_tsv(rt_data_canonical %>% select(id) %>% add_column(bits.on=fingerprints_maccs),
              gsub("_rtdata_canonical_success.txt", "_fingerprints_maccs_canonical_success.txt", rt_data_file),
              na = "")
    write_tsv(rt_data_canonical %>% select(id) %>% add_column(bits.on=fingerprints_pubchem),
              gsub("_rtdata_canonical_success.txt", "_fingerprints_pubchem_canonical_success.txt", rt_data_file),
              na = "")

    # remove to avoid overlap
    rm(rt_data_canonical)
    rm(fingerprints_ecfp6)
    rm(fingerprints_maccs)
    rm(fingerprints_pubchem)

  }


  # canconical smiles data -----------------------------------------------------
  # read canonical smiles data
  rt_data_file <- list.files(data_folder,
                             pattern = "_rtdata_isomeric_success.txt$",
                             full.names = TRUE)

  if(length(rt_data_file) == 1) {

    rt_data_isomeric <- read_tsv(rt_data_file,
                                 col_types = cols(id = col_character(),
                                                  name = col_character(),
                                                  formula = col_character(),
                                                  rt = col_double(),
                                                  smiles.std = col_character(),
                                                  inchi.std = col_character(),
                                                  inchikey.std = col_character()))

    # perform computation
    fingerprints_ecfp6 <- sapply(rt_data_isomeric$smiles.std, function(s) ifelse(is.na(s), NA, paste(attr(
      get.fingerprint(parse.smiles(s)[[1]], type="circular", circular.type="ECFP6"), "bits"), collapse=",")), USE.NAMES=F)
    fingerprints_maccs <- sapply(rt_data_isomeric$smiles.std, function(s) ifelse(is.na(s), NA, paste(attr(
      get.fingerprint(parse.smiles(s)[[1]], type="maccs"), "bits"), collapse=",")), USE.NAMES=F)
    fingerprints_pubchem <- sapply(rt_data_isomeric$smiles.std, function(s) ifelse(is.na(s), NA, paste(attr(
      get.fingerprint(parse.smiles(s)[[1]], type="pubchem"), "bits"), collapse=",")), USE.NAMES=F)

    # write results
    write_tsv(rt_data_isomeric %>% select(id) %>% add_column(bits.on=fingerprints_ecfp6),
              gsub("_rtdata_isomeric_success.txt", "_fingerprints_ecfp6_isomeric_success.txt", rt_data_file),
              na = "")
    write_tsv(rt_data_isomeric %>% select(id) %>% add_column(bits.on=fingerprints_maccs),
              gsub("_rtdata_isomeric_success.txt", "_fingerprints_maccs_isomeric_success.txt", rt_data_file),
              na = "")
    write_tsv(rt_data_isomeric %>% select(id) %>% add_column(bits.on=fingerprints_pubchem),
              gsub("_rtdata_isomeric_success.txt", "_fingerprints_pubchem_isomeric_success.txt", rt_data_file),
              na = "")

    # remove to avoid overlap
    rm(rt_data_isomeric)
    rm(fingerprints_ecfp6)
    rm(fingerprints_maccs)
    rm(fingerprints_pubchem)

  }
}

#print(computation_cache_hit_counter)
