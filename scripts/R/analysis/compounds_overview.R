# ==============================================================================
# This script gives an overview on the substances measured in the studies.
# Information is fetched from the RT data file.
# ==============================================================================

# ==============================================================================
# load required libraries
# ==============================================================================
library(tidyverse)

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# get list of all folders ------------------------------------------------------
data_folders <- list.dirs("processed_data", full.names = TRUE, recursive = FALSE)

# read data --------------------------------------------------------------------
full_rt_data <- tibble()

# iterate through folder and add data to full_rt_data --------------------------
for(data_folder in data_folders) {
  
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
  
  full_rt_data <- bind_rows(full_rt_data,
                       rt_data_clipboard)
  
  
}

# ==============================================================================
# Overview on separation methods
# ==============================================================================
# count occurrence of metabolites ----------------------------------------------
metabolite_count <- full_rt_data %>% 
  count(InChIKey.std)

metabolite_count %>%
  ggplot(aes(x = InChIKey.std, y = n)) +
  geom_bar(stat = "identity") +
  theme_bw() +
  theme(legend.position = "none")

