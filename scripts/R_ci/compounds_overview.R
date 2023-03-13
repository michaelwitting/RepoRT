## -----------------------------------------------------------------------------
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
library(gridExtra)
library(grid)
library(viridis)
library(treemapify)

# ==============================================================================
# read the data and create tibble for data analysis
# ==============================================================================
# folders from command arguments -----------------------------------------------
data_folders <- file.path('processed_data', commandArgs(trailingOnly=TRUE))

# iterate through folder and add data to full_rt_data_canonical ----------------
for(data_folder in data_folders) {

  cat(paste(Sys.time(), "processing", data_folder, "\n"))

  gradient_file <- paste0(data_folder, "/", basename(data_folder), "_gradient.txt")
  metadata_file <- paste0(data_folder, "/", basename(data_folder), "_metadata.txt")

  if(file.exists(gradient_file) && file.exists(metadata_file)) {

    # ============================================================================
    # meta data
    # ============================================================================
    meta_data <- read_tsv(metadata_file, show_col_types = FALSE)

    # ============================================================================
    # gradient
    # ============================================================================
    gradient_table <- read_tsv(gradient_file, show_col_types = FALSE) %>%
      filter(!is.na(`t [min]`))

    if(nrow(gradient_table) > 0) {

      maxrtime <- max(gradient_table$`t [min]`)

      gradient_plot <- gradient_table %>%
        select(-`flow rate [ml/min]`) %>%
        pivot_longer(cols = c(-`t [min]`)) %>%
        rename("eluent" = "name") %>%
        ggplot(aes(x = `t [min]`, y = value, group = eluent, colour = eluent)) +
        geom_line() +
        theme_bw() +
        theme(legend.position = "bottom",
              axis.text.y = element_text(angle = 90, hjust = 0.5)) +
        scale_x_continuous(limits = c(0,maxrtime))

      flow_plot <- gradient_table %>%
        ggplot(aes(x = `t [min]`, y = `flow rate [ml/min]`)) +
        geom_line() +
        theme_bw()+
        theme(legend.position = "bottom",
              axis.text.y = element_text(angle = 90, hjust = 0.5)) +
        scale_x_continuous(limits = c(0,maxrtime))

    } else {

      maxrtime <- 0
      gradient_plot <- ggplot() + theme_void()
      flow_plot <- ggplot() + theme_void()

    }

    # ============================================================================
    # canonical SMILES
    # ============================================================================
    # setup plotting device to pdf
    report_file <- paste0(data_folder, "/", basename(data_folder), "_report_canonical.pdf")

    if(file.exists(report_file)) warning(paste(data_folder, "report already exists:", report_file, "overwriting"))

    pdf(file = report_file, onefile = TRUE, paper = "a4")

    # read canonical smiles data
    rt_data_file <- list.files(data_folder,
                               pattern = "_rtdata_canonical_success.txt$",
                               full.names = TRUE)

    rt_data_clipboard <- read_tsv(rt_data_file,
                                  col_types = cols(id = col_character(),
                                                   name = col_character(),
                                                   formula = col_character(),
                                                   rt = col_double(),
                                                   smiles.std = col_character(),
                                                   inchi.std = col_character(),
                                                   inchikey.std = col_character(),
                                                   classyfire.kingdom = col_character(),
                                                   classyfire.superclass = col_character(),
                                                   classyfire.class = col_character(),
                                                   classyfire.subclass = col_character(),
                                                   classyfire.level5 = col_character(),
                                                   classyfire.level6 = col_character()),
                                  na = c("NA (NA)", ""))

    # add to full overview table
    # full_rt_data_canonical <- bind_rows(full_rt_data_canonical,
    #                                     rt_data_clipboard)

    if(nrow(rt_data_clipboard) > 0) {
      # create overview on RT range
      histo <- rt_data_clipboard %>% ggplot(aes(x = rt)) +
        geom_histogram(binwidth = 0.5, colour = "black", fill = viridis(1)) +
        xlab("RT (min)") +
        ylab("Count") +
        theme_bw() +
        theme(legend.position = "bottom",
              axis.text.y = element_text(angle = 90, hjust = 0.5)) +
        scale_x_continuous(limits = c(0,maxrtime)) +
        geom_vline(xintercept = meta_data$column.t0 * 1, colour = "red", linetype = "dashed") +
        geom_vline(xintercept = meta_data$column.t0 * 2, colour = "orange", linetype = "dashed") +
        geom_vline(xintercept = meta_data$column.t0 * 3, colour = "green", linetype = "dashed")

      p1 <- grid.arrange(flow_plot, gradient_plot, histo, heights = c(0.33, 0.33, 0.33))

      # create overview on compound classes
      p2_data <- rt_data_clipboard %>% count(classyfire.kingdom)
      p2_1 <- p2_data %>% ggplot(aes(area = n, fill = classyfire.kingdom)) +
        geom_treemap(fill = viridis(n = nrow(p2_data))) +
        theme_bw() +
        theme(legend.position = "none")
      p2_2 <- p2_data %>% tableGrob()
      p2 <- grid.arrange(p2_1, p2_2, heights = c(0.33, 0.66))

      p2 %>% grid.draw()

      p3_data <- rt_data_clipboard %>% count(classyfire.superclass)
      p3_1 <- p3_data %>% ggplot(aes(area = n, fill = classyfire.kingdom)) +
        geom_treemap(fill = viridis(n = nrow(p3_data))) +
        theme_bw() +
        theme(legend.position = "none")
      p3_2 <- p3_data %>% tableGrob()
      p3 <- grid.arrange(p3_1, p3_2, heights = c(0.33, 0.66))

      p3 %>% grid.draw()

      p4_data <- rt_data_clipboard %>% count(classyfire.class)
      p4_1 <- p4_data %>% ggplot(aes(area = n, fill = classyfire.kingdom)) +
        geom_treemap(fill = viridis(n = nrow(p4_data))) +
        theme_bw() +
        theme(legend.position = "none")
      p4_2 <- p4_data %>% tableGrob()
      p4 <- grid.arrange(p4_1, p4_2, heights = c(0.33, 0.66))

      p4 %>% grid.draw()

      # switch off device
      dev.off()
    }


    # ============================================================================
    # isomeric SMILES
    # ============================================================================
    # setup plotting device to pdf
    report_file <- paste0(data_folder, "/", basename(data_folder), "_report_isomeric.pdf")

    if(file.exists(report_file)) warning(paste(data_folder, "report already exists:", report_file, "overwriting"))

    pdf(file = report_file, onefile = TRUE, paper = "a4")

    # read isomeric smiles data
    rt_data_file <- list.files(data_folder,
                               pattern = "_rtdata_isomeric_success.txt$",
                               full.names = TRUE)

    rt_data_clipboard <- read_tsv(rt_data_file,
                                  col_types = cols(id = col_character(),
                                                   name = col_character(),
                                                   formula = col_character(),
                                                   rt = col_double(),
                                                   smiles.std = col_character(),
                                                   inchi.std = col_character(),
                                                   inchikey.std = col_character(),
                                                   classyfire.kingdom = col_character(),
                                                   classyfire.superclass = col_character(),
                                                   classyfire.class = col_character(),
                                                   classyfire.subclass = col_character(),
                                                   classyfire.level5 = col_character(),
                                                   classyfire.level6 = col_character()),
                                  na = c("NA (NA)", ""))

    # add to full overview table
    # full_rt_data_isomeric <- bind_rows(full_rt_data_isomeric,
    #                                    rt_data_clipboard)

    if(nrow(rt_data_clipboard) > 0) {
      # create overview on RT range
      histo <- rt_data_clipboard %>% ggplot(aes(x = rt)) +
        geom_histogram(binwidth = 0.5, colour = "black", fill = viridis(1)) +
        xlab("RT (min)") +
        ylab("Count") +
        theme_bw()+
        theme(legend.position = "bottom",
              axis.text.y = element_text(angle = 90, hjust = 0.5)) +
        scale_x_continuous(limits = c(0,maxrtime)) +
        geom_vline(xintercept = meta_data$column.t0 * 1, colour = "red", linetype = "dashed") +
        geom_vline(xintercept = meta_data$column.t0 * 2, colour = "orange", linetype = "dashed") +
        geom_vline(xintercept = meta_data$column.t0 * 3, colour = "green", linetype = "dashed")

      p1 <- grid.arrange(flow_plot, gradient_plot, histo, heights = c(0.33, 0.33, 0.33))

      # create overview on compound classes
      p2_data <- rt_data_clipboard %>% count(classyfire.kingdom)
      p2_1 <- p2_data %>% ggplot(aes(area = n, fill = classyfire.kingdom)) +
        geom_treemap(fill = viridis(n = nrow(p2_data))) +
        theme_bw() +
        theme(legend.position = "none")
      p2_2 <- p2_data %>% tableGrob()
      p2 <- grid.arrange(p2_1, p2_2, heights = c(0.33, 0.66))

      p2 %>% grid.draw()

      p3_data <- rt_data_clipboard %>% count(classyfire.superclass)
      p3_1 <- p3_data %>% ggplot(aes(area = n, fill = classyfire.kingdom)) +
        geom_treemap(fill = viridis(n = nrow(p3_data))) +
        theme_bw() +
        theme(legend.position = "none")
      p3_2 <- p3_data %>% tableGrob()
      p3 <- grid.arrange(p3_1, p3_2, heights = c(0.33, 0.66))

      p3 %>% grid.draw()

      p4_data <- rt_data_clipboard %>% count(classyfire.class)
      p4_1 <- p4_data %>% ggplot(aes(area = n, fill = classyfire.kingdom)) +
        geom_treemap(fill = viridis(n = nrow(p4_data))) +
        theme_bw() +
        theme(legend.position = "none")
      p4_2 <- p4_data %>% tableGrob()
      p4 <- grid.arrange(p4_1, p4_2, heights = c(0.33, 0.66))

      p4 %>% grid.draw()

      # switch off device
      dev.off()
    }

  } else {
    warning(paste(data_folder, "does not have both gradient and metadata files, skipping"))
  }
}

# # ==============================================================================
# # reformat and add
# # ==============================================================================
# full_rt_data_canonical <- full_rt_data_canonical %>%
#   separate(col = id,
#            into = c("study_id", "metabolite_id"),
#            sep = "_", remove = FALSE)
#
# full_rt_data_isomeric <- full_rt_data_isomeric %>%
#   separate(col = id,
#            into = c("study_id", "metabolite_id"),
#            sep = "_", remove = FALSE)
#
# # ==============================================================================
# # determine sizes of data sets
# # ==============================================================================
# sizes_canonical <- full_rt_data_canonical %>%
#   group_by(study_id) %>%
#   rowwise() %>%
#   count(study_id)
#
# sizes_canonical %>%
#   ggplot(aes(x = n)) +
#   geom_histogram(binwidth = 50)
#
# sizes_isomeric <- full_rt_data_isomeric %>%
#   group_by(study_id) %>%
#   rowwise() %>%
#   count(study_id)
#
# sizes_isomeric %>%
#   ggplot(aes(x = n)) +
#   geom_histogram(binwidth = 50)
#
# # ==============================================================================
# # Overview on separation methods
# # ==============================================================================
# # count occurrence of metabolites ----------------------------------------------
# metabolite_count_canonical <- full_rt_data_canonical %>%
#   count(inchikey.std)
#
# metabolite_count_canonical %>%
#   ggplot(aes(x = inchikey.std, y = n)) +
#   geom_bar(stat = "identity") +
#   theme_bw() +
#   theme(legend.position = "none")
