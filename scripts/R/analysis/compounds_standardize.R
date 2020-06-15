# ==============================================================================
# This script gives an overview on the substances measured in the studies.
# Information is fetched from the RT data file.
# ==============================================================================

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
#data_folders_raw <- list.dirs("raw_data", full.names = TRUE, recursive = FALSE)
#data_folders_processed <- list.dirs("processed_data", full.names = TRUE, recursive = FALSE)

# select only folders not exisisting in processed_data -------------------------
#data_folders <- data_folders_raw[!basename(data_folders_raw) %in% basename(data_folders_processed)]
data_folders <- list.dirs("raw_data", full.names = TRUE, recursive = FALSE)

# read data  and peform standardization ----------------------------------------
for(data_folder in data_folders) {
  
  # ============================================================================
  # read and standardize compound data 
  # ============================================================================
  rt_data_file <- list.files(data_folder,
                             pattern = "_rtdata.txt$",
                             full.names = TRUE)
  
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
  
  # ============================================================================
  # standardize canonical smiles
  # ============================================================================
  
  rt_data %>% 
    select(id, pubchem.smiles.canonical) %>% 
    write_tsv("temp.txt", col_names = FALSE)
  
  # perform standardization ----------------------------------------------------
  shell("java -jar scripts/Java/structure-standardization.jar temp.txt")
  
  # read standarized smiles ----------------------------------------------------
  smiles_canonical_std <- read_tsv("temp.txt_standardized", col_names = FALSE) 
  smiles_canonical_failed <- read_tsv("temp.txt_failed", col_names = FALSE)
  
  # check if it contains data and rename column names --------------------------
  if(nrow(smiles_canonical_std) > 0) {
    
    smiles_canonical_std <- smiles_canonical_std %>%  rename(id = X1,
                                         pubchem.smiles.canonical = X2)
    
  } else {
    
    smiles_canonical_std <- tibble(id = character(0),
                         pubchem.smiles.canonical = character(0))
    
  }

  if(nrow(smiles_canonical_failed) > 0) {
    
    smiles_canonical_failed <- smiles_canonical_failed %>% rename(id = X1,
                                              pubchem.smiles.canonical = X2,
                                              status = X3)
    
  } else {
    
    smiles_canonical_failed <- tibble(id = character(0),
                            pubchem.smiles.canonical = character(0),
                            status = character(0))
    
  }
   
  
  # calculate InChI and InChIKey -----------------------------------------------
  smiles_canonical_std <- smiles_canonical_std %>% 
    mutate(InChI.std = sapply(pubchem.smiles.canonical, get.inchi),
           InChIKey.std = sapply(pubchem.smiles.canonical, get.inchi.key))
  
  smiles_canonical_failed <- smiles_canonical_failed %>% 
    mutate(InChI.std = NA,
           InChIKey.std = NA)
  
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
  shell("java -jar scripts/Java/structure-standardization.jar temp.txt")
  
  # read standarized smiles ----------------------------------------------------
  smiles_isomeric_std <- read_tsv("temp.txt_standardized", col_names = FALSE) 
  smiles_isomeric_failed <- read_tsv("temp.txt_failed", col_names = FALSE)
  
  # check if it contains data and rename column names --------------------------
  if(nrow(smiles_isomeric_std) > 0) {
    
    smiles_isomeric_std <- smiles_isomeric_std %>%  rename(id = X1,
                                                             pubchem.smiles.isomeric = X2)
    
  } else {
    
    smiles_isomeric_std <- tibble(id = character(0),
                                   pubchem.smiles.isomeric = character(0))
    
  }
  
  if(nrow(smiles_isomeric_failed) > 0) {
    
    smiles_isomeric_failed <- smiles_isomeric_failed %>% rename(id = X1,
                                                                  pubchem.smiles.isomeric = X2,
                                                                  status = X3)
    
  } else {
    
    smiles_isomericl_failed <- tibble(id = character(0),
                                      pubchem.smiles.isomeric = character(0),
                                      status = character(0))
    
  }
  
  
  # calculate InChI and InChIKey -----------------------------------------------
  smiles_isomeric_std <- smiles_isomeric_std %>% 
    mutate(InChI.std = sapply(pubchem.smiles.isomeric, get.inchi),
           InChIKey.std = sapply(pubchem.smiles.isomeric, get.inchi.key))
  
  smiles_canonical_failed <- smiles_isomeric_failed %>% 
    mutate(InChI.std = NA,
           InChIKey.std = NA)
  
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
  
  write_tsv(rt_data_canonical_success,
            paste0(result_folder, "/", basename(data_folder), "_rtdata_canonical_success.txt"),
            na = "")
  
  write_tsv(rt_data_canonical_failed,
            paste0(result_folder, "/", basename(data_folder), "_rtdata_canonical_failed.txt"),
            na = "")
  
  write_tsv(rt_data_isomeric_success,
            paste0(result_folder, "/", basename(data_folder), "_rtdata_isomeric_success.txt"),
            na = "")
  
  write_tsv(rt_data_isomeric_failed,
            paste0(result_folder, "/", basename(data_folder), "_rtdata_isomeric_failed.txt"),
            na = "")
  
  write_tsv(meta_data,
            paste0(result_folder, "/", basename(data_folder), "_metadata.txt"),
            na = "")
  
  # write simple report file ---------------------------------------------------
  # .cat <- function(x) {
  #   cat(x, file = paste0(result_folder, "/", basename(data_folder), "_report.txt"), append = TRUE)
  # }
  # 
  # .cat(paste0("Report for data set ", basename(data_folder)))
  # .cat(paste0(nrow(rt_data_success), " of ", nrow(rt_data), " compounds were standardized."))
  # .cat(paste0(nrow(rt_data_failed), " of ", nrow(rt_data), " compounds failed."))
  
}
