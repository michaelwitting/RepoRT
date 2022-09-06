## ---------------------------
##
## Script name: compounds_classyfire.R
##
## Purpose of script: Add ClassyFire annotation, if available
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
## This script add ClassyFire compound class annotation to standardized data.
##
## -----------------------------------------------------------------------------

# ==============================================================================
# load required libraries
# ==============================================================================
library(tidyverse)
library(classyfireR)

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# folders from command arguments -----------------------------------------------
data_folders <- file.path('processed_data', commandArgs(trailingOnly=TRUE))


# load already classified inchikeys
start.time <- Sys.time()
classyfire_db <- new.env(hash=TRUE)
for (rt_data_file in list.files("processed_data", pattern="_rtdata_.*_success.txt$",
                                full.names=TRUE, recursive=TRUE)){
    rt_data <- read_tsv(rt_data_file, show_col_types = FALSE)
    for (i in 1:nrow(rt_data))
        classyfire_db[[rt_data[[i, "inchikey.std"]]]] <- c(rt_data[[i, "classyfire.kingdom"]],
                                                           rt_data[[i, "classyfire.superclass"]],
                                                           rt_data[[i, "classyfire.class"]],
                                                           rt_data[[i, "classyfire.subclass"]],
                                                           rt_data[[i, "classyfire.level5"]],
                                                           rt_data[[i, "classyfire.level6"]])
}
end.time <- Sys.time()
time.taken <- end.time - start.time
cat(paste("read in", length(classyfire_db), "already classified inchikeys in", round(time.taken, 2), "min\n"))


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

    # perform classification
    classyfire <- map_dfr(rt_data_canonical$inchikey.std, function(x) {

      if(!is.null(classyfire_db[[x]])){

        classification_result <- classyfire_db[[x]]
        kingdom <- classification_result[1]
        superclass<- classification_result[2]
        class <- classification_result[3]
        subclass <- classification_result[4]
        level5 <- classification_result[5]
        level6 <- classification_result[6]

      } else {

        Sys.sleep(10)

        # get classifiction from ClassyFire server
        classification_result <- get_classification(x)

        # check results and retrieve results
        if(is.null(classification_result)) {

          kingdom <- NA
          superclass <- NA
          class <- NA
          subclass <- NA
          level5 <- NA
          level6 <- NA

        } else {

          kingdom <- paste0(classification_result@classification$Classification[1],
                            " (", classification_result@classification$CHEMONT[1], ")")
          superclass <- paste0(classification_result@classification$Classification[2],
                               " (", classification_result@classification$CHEMONT[2], ")")
          class <- paste0(classification_result@classification$Classification[3],
                          " (", classification_result@classification$CHEMONT[3], ")")
          subclass <- paste0(classification_result@classification$Classification[4],
                             " (", classification_result@classification$CHEMONT[4], ")")
          level5 <- paste0(classification_result@classification$Classification[5],
                           " (", classification_result@classification$CHEMONT[5], ")")
          level6 <- paste0(classification_result@classification$Classification[6],
                           " (", classification_result@classification$CHEMONT[6], ")")

          classyfire_db[[x]] <- c(kingdom, superclass, class, subclass, level5, level6)

        }

      }

      # combine different results in columns
      bind_cols(classyfire.kingdom = kingdom,
                classyfire.superclass = superclass,
                classyfire.class = class,
                classyfire.subclass = subclass,
                classyfire.level5 = level5,
                classyfire.level6 = level6)

    })

    # combine tables
    rt_data_canonical <- bind_cols(rt_data_canonical %>% select(id,
                                                                name,
                                                                formula,
                                                                rt,
                                                                smiles.std,
                                                                inchi.std,
                                                                inchikey.std), classyfire)

    # write results
    write_tsv(rt_data_canonical,
              rt_data_file,
              na = "")

    # remove to avoid overlap
    rm(rt_data_canonical)
    rm(classyfire)


  }



  # isomeric smiles data -------------------------------------------------------
  # read isomeric smiles data
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

    # perform classification
    classyfire <- map_dfr(rt_data_isomeric$inchikey.std, function(x) {

      if(!is.null(classyfire_db[[x]])){

        classification_result <- classyfire_db[[x]]
        kingdom <- classification_result[1]
        superclass<- classification_result[2]
        class <- classification_result[3]
        subclass <- classification_result[4]
        level5 <- classification_result[5]
        level6 <- classification_result[6]

      } else {

        Sys.sleep(10)

        # get classifiction from ClassyFire server
        classification_result <- get_classification(x)

        # check results and retrieve results
        if(is.null(classification_result)) {

          kingdom <- NA
          superclass <- NA
          class <- NA
          subclass <- NA
          level5 <- NA
          level6 <- NA

        } else {

          kingdom <- paste0(classification_result@classification$Classification[1],
                            " (", classification_result@classification$CHEMONT[1], ")")
          superclass <- paste0(classification_result@classification$Classification[2],
                               " (", classification_result@classification$CHEMONT[2], ")")
          class <- paste0(classification_result@classification$Classification[3],
                          " (", classification_result@classification$CHEMONT[3], ")")
          subclass <- paste0(classification_result@classification$Classification[4],
                             " (", classification_result@classification$CHEMONT[4], ")")
          level5 <- paste0(classification_result@classification$Classification[5],
                           " (", classification_result@classification$CHEMONT[5], ")")
          level6 <- paste0(classification_result@classification$Classification[6],
                           " (", classification_result@classification$CHEMONT[6], ")")

          classyfire_db[[x]] <- c(kingdom, superclass, class, subclass, level5, level6)

        }

      }

      # combine different results in columns
      bind_cols(classyfire.kingdom = kingdom,
                classyfire.superclass = superclass,
                classyfire.class = class,
                classyfire.subclass = subclass,
                classyfire.level5 = level5,
                classyfire.level6 = level6)

    })

    # combine tables
    rt_data_isomeric <- bind_cols(rt_data_isomeric %>% select(id,
                                                              name,
                                                              formula,
                                                              rt,
                                                              smiles.std,
                                                              inchi.std,
                                                              inchikey.std), classyfire)

    # write results
    write_tsv(rt_data_isomeric,
              rt_data_file,
              na = "")

    # remove to avoid overlap
    rm(rt_data_isomeric)
    rm(classyfire)

  }



}
