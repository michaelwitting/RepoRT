## ---------------------------
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

# ==============================================================================
# load required libraries
# ==============================================================================
library(tidyverse)

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# get list of all folders ------------------------------------------------------
data_folders <- list.dirs("processed_data", full.names = TRUE, recursive = FALSE)

# create empty tibble to store data --------------------------------------------
full_rt_data_canonical <- tibble()
full_rt_data_isomeric <- tibble()

# iterate through folder and add data to full_rt_data_canonical ----------------
for(data_folder in data_folders) {
  
  
  # read canonical smiles data
  rt_data_file <- list.files(data_folder,
                               pattern = "_rtdata_canonical_success.txt$",
                               full.names = TRUE)
  
  rt_data_clipboard <- read_tsv(rt_data_file,
                                col_types = cols(id = col_character(),
                                                 name = col_character(),
                                                 formula = col_character(),
                                                 rt = col_double(),
                                                 pubchem.smiles.isomeric = col_character(),
                                                 InChI.std = col_character(),
                                                 InChIKey.std = col_character()))
  
  full_rt_data_canonical <- bind_rows(full_rt_data_canonical,
                                      rt_data_clipboard)
  
  # read isomeric smiles data
  rt_data_file <- list.files(data_folder,
                             pattern = "_rtdata_isomeric_success.txt$",
                             full.names = TRUE)
  
  rt_data_clipboard <- read_tsv(rt_data_file,
                                col_types = cols(id = col_character(),
                                                 name = col_character(),
                                                 formula = col_character(),
                                                 rt = col_double(),
                                                 pubchem.smiles.isomeric = col_character(),
                                                 InChI.std = col_character(),
                                                 InChIKey.std = col_character()))
  
  full_rt_data_isomeric <- bind_rows(full_rt_data_isomeric,
                                     rt_data_clipboard)
  
  
  
  
}

# ==============================================================================
# reformat and add
# ==============================================================================
full_rt_data_canonical <- full_rt_data_canonical %>%
  separate(col = id,
           into = c("study_id", "metabolite_id"),
           sep = "_", remove = FALSE)

full_rt_data_isomeric <- full_rt_data_isomeric %>% 
  separate(col = id,
           into = c("study_id", "metabolite_id"),
           sep = "_", remove = FALSE)

# ==============================================================================
# determine sizes of data sets
# ==============================================================================
sizes_canonical <- full_rt_data_canonical %>%
  group_by(study_id) %>%
  rowwise() %>%
  count(study_id)

sizes_canonical %>% 
  ggplot(aes(x = n)) + 
  geom_histogram(binwidth = 50)

sizes_isomeric <- full_rt_data_isomeric %>%
  group_by(study_id) %>%
  rowwise() %>%
  count(study_id)

sizes_isomeric %>% 
  ggplot(aes(x = n)) + 
  geom_histogram(binwidth = 50)

# ==============================================================================
# Overview on separation methods
# ==============================================================================
# count occurrence of metabolites ----------------------------------------------
metabolite_count_canonical <- full_rt_data_canonical %>% 
  count(InChIKey.std)

metabolite_metabolite_count_canonical %>%
  ggplot(aes(x = InChIKey.std, y = n)) +
  geom_bar(stat = "identity") +
  theme_bw() +
  theme(legend.position = "none")

