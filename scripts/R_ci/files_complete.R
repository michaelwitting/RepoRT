# ==============================================================================
# This script checks if all required files are present in the raw data folders
# ==============================================================================

# ==============================================================================
# load required libraries
# ==============================================================================
library(tidyverse)

# ==============================================================================
# read the data and create tibble for data analysis, raw data
# ==============================================================================
# get list of all raw data folders from command arguments ----------------------
data_folders <- file.path('raw_data', commandArgs(trailingOnly=TRUE))

# read check if all files are present ------------------------------------------
file_complete_raw <- tibble()

for(data_folder in data_folders) {

  cat(paste(Sys.time(), "processing raw_data", data_folder, "\n"))

  study_id <- basename(data_folder)

  # meta data files
  gradient_file <- file.exists(paste0(data_folder, "/", study_id, "_gradient.tsv"))
  metadata_file <- file.exists(paste0(data_folder, "/", study_id, "_metadata.tsv"))

  # RT data files
  rtdata_file <- file.exists(paste0(data_folder, "/", study_id, "_rtdata.tsv"))

  file_complete_raw <- bind_rows(file_complete_raw,
                                 tibble(id = study_id,
                                        gradient_file = gradient_file,
                                        metadata_file = metadata_file,
                                        rtdata_file = rtdata_file))


}

# check if everything is in place
file_complete_raw <- file_complete_raw %>%
  rowwise() %>%
  mutate(complete = all(across(ends_with("file"))))

# ==============================================================================
# read the data and create tibble for data analysis, processed data
# ==============================================================================
# get list of all processed data folders from command arguments ----------------
data_folders <- file.path('processed_data', commandArgs(trailingOnly=TRUE))

# read check if all files are present ------------------------------------------
file_complete_processed <- tibble()

for(data_folder in data_folders) {

  cat(paste(Sys.time(), "processing processed_data", data_folder, "\n"))

  study_id <- basename(data_folder)

  # meta data files
  gradient_file <- file.exists(paste0(data_folder, "/", study_id, "_gradient.tsv"))
  metadata_file <- file.exists(paste0(data_folder, "/", study_id, "_metadata.tsv"))

  # RT data files
  rtdata_canonical_success_file <- file.exists(paste0(data_folder, "/", study_id, "_rtdata_canonical_success.tsv"))
  rtdata_canonical_failed_file <- file.exists(paste0(data_folder, "/", study_id, "_rtdata_canonical_failed.tsv"))
  rtdata_isomeric_success_file <- file.exists(paste0(data_folder, "/", study_id, "_rtdata_isomeric_success.tsv"))
  rtdata_isomeric_failed_file <- file.exists(paste0(data_folder, "/", study_id, "_rtdata_isomeric_failed.tsv"))

  # descriptor files
  desc_canonical_file <- file.exists(paste0(data_folder, "/", study_id, "_descriptors_canonical_success.tsv"))
  desc_isomeric_file <- file.exists(paste0(data_folder, "/", study_id, "_descriptors_isomeric_success.tsv"))


  file_complete_processed <- bind_rows(file_complete_processed,
                                       tibble(id = study_id,
                                              gradient_file = gradient_file,
                                              metadata_file = metadata_file,
                                              rtdata_canonical_success_file = rtdata_canonical_success_file,
                                              rtdata_canonical_failed_file = rtdata_canonical_failed_file,
                                              rtdata_isomeric_success_file = rtdata_isomeric_success_file,
                                              rtdata_isomeric_failed_file = rtdata_isomeric_failed_file,
                                              desc_canonical_file = desc_canonical_file,
                                              desc_isomeric_file = desc_isomeric_file))


}

# check if everything is in place
file_complete_processed <- file_complete_processed %>%
  rowwise() %>%
  mutate(complete = all(across(ends_with("file"))))
