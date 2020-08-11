## ---------------------------
##
## Script name: compounds_descriptors.R
##
## Purpose of script: Calculate descriptors for molecules using rcdk
##
## Author: Dr. Michael Witting
##
## Date Created: 2020-08-10
##
## Copyright (c) Michael Witting, 2020
## Email: michael.witting@helmholtz-muenchen.de
##
## -----------------------------------------------------------------------------
##
## Notes:
##
## This script calculates molecular descriptors using rcdk and writes them to an
## extra file.
##
## -----------------------------------------------------------------------------

# ==============================================================================
# load required libraries
# ==============================================================================
library(tidyverse)
library(rcdk)

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# get list of all folders ------------------------------------------------------
data_folders <- list.dirs("processed_data", full.names = TRUE, recursive = FALSE)


# iterate through folder and add data to full_rt_data_canonical ----------------
for(data_folder in data_folders) {
  
  # canconical smiles data -----------------------------------------------------
  # read canonical smiles data
  rt_data_file <- list.files(data_folder,
                             pattern = "_rtdata_canonical_success.txt$",
                             full.names = TRUE)
  
  rt_data_canonical <- read_tsv(rt_data_file,
                                col_types = cols(id = col_character(),
                                                 name = col_character(),
                                                 formula = col_character(),
                                                 rt = col_double(),
                                                 smiles.std = col_character(),
                                                 inchi.std = col_character(),
                                                 inchikey.std = col_character()))
  
  # perform classification
  rcdk_descriptors <- map_dfr(rt_data_canonical$smiles.std, function(x) {
    
    # parse smiles into molecules
    mol <- parse.smiles(x)

    # get all descriptor categories and unique descriptor names
    desc_categories <-get.desc.categories()
    desc_names <- c()

    for(desc_category in desc_categories) {
      
      desc_names <-c(desc_names, get.desc.names(type = desc_category))
      
    }
    
    desc_names <- unique(desc_names)
    
    # predict descriptors
    desc <- eval.desc(mol, desc_names, verbose = FALSE)
    row.names(desc) <- NULL

    desc
    
  })
  
  # combine tables
  rt_data_canonical <- bind_cols(rt_data_canonical %>% select(id), rcdk_descriptors)
  
  # write results
  write_tsv(rt_data_canonical,
            gsub("_rtdata_canonical_success.txt", "_descriptors_canonical_success.txt", rt_data_file),
            na = "")
  
  # canconical smiles data -----------------------------------------------------
  # read canonical smiles data
  rt_data_file <- list.files(data_folder,
                             pattern = "_rtdata_isomeric_success.txt$",
                             full.names = TRUE)
  
  rt_data_isomeric <- read_tsv(rt_data_file,
                                col_types = cols(id = col_character(),
                                                 name = col_character(),
                                                 formula = col_character(),
                                                 rt = col_double(),
                                                 smiles.std = col_character(),
                                                 inchi.std = col_character(),
                                                 inchikey.std = col_character()))
  
  # perform classification
  rcdk_descriptors <- map_dfr(rt_data_isomeric$smiles.std, function(x) {
    
    # parse smiles into molecules
    mol <- parse.smiles(x)
    
    # get all descriptor categories and unique descriptor names
    desc_categories <-get.desc.categories()
    desc_names <- c()
    
    for(desc_category in desc_categories) {
      
      desc_names <-c(desc_names, get.desc.names(type = desc_category))
      
    }
    
    desc_names <- unique(desc_names)
    
    # predict descriptors
    desc <- eval.desc(mol, desc_names, verbose = FALSE)
    row.names(desc) <- NULL
    
    desc
    
  })
  
  # combine tables
  rt_data_isomeric <- bind_cols(rt_data_isomeric %>% select(id), rcdk_descriptors)
  
  # write results
  write_tsv(rt_data_isomeric,
            gsub("_rtdata_isomeric_success.txt", "_descriptors_isomeric_success.txt", rt_data_file),
            na = "")
  
}

