# execute all scripts on compounds
source("compounds_standardize.R")
source("compounds_classyfire.R")
source("compounds_descriptors.R")

# execute all scripts on metadata
source("metadata_standardize.R")

# generate overviews
source("compounds_overview.R")
source("metadata_overview.R")