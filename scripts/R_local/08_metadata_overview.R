# ==============================================================================
# This script gives an overview on the metadata associated with the studies.
# Information is fetched from the studies.txt as well as from each meta data file
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

# # filter potential data folders found in negative list
# if(!length(negative_list) == 1 && !is.na(negative_list)) {
#   data_folders <- data_folders[which(!str_detect(data_folders, paste0(negative_list, collapse = "|")))]
# }

# read data --------------------------------------------------------------------
studies_data <- read_tsv("processed_data/studies.tsv")
meta_data <- tibble()

for(data_folder in data_folders) {
  
  meta_data_file <- list.files(data_folder,
                               pattern = "_metadata.txt$",
                               full.names = TRUE)
  
  meta_data_clipboard <- read_tsv(meta_data_file)
  
  meta_data <- bind_rows(meta_data,
                         meta_data_clipboard)
  
  
}

# combine with study list
full_meta_data <- full_join(studies_data,
                            meta_data,
                            by = "id")

# ==============================================================================
# Overview on separation methods
# ==============================================================================
# count method type ------------------------------------------------------------
full_meta_data %>%
  count(method.type) %>%
  mutate(n = n/sum(n) * 100) %>% 
  ggplot(aes(x = "", y = n, fill = method.type)) +
  geom_bar(stat = "identity") +
  coord_polar("y", start=0) +
  theme_bw()

# count column -----------------------------------------------------------------
column_count <- full_meta_data %>% 
  count(column.name)

# count column USP code --------------------------------------------------------
full_meta_data %>% 
  count(column.usp.code)

# column length ----------------------------------------------------------------
full_meta_data %>% 
  count(column.length)
