# load required libraries
library(BridgeDbR)

# load the current metabolomics BridgeDB
mapper <- loadDatabase("D:/bridgedb/2019-09-04/metabolites_20190829.bridge")

data_folder <- list.dirs("raw_data", recursive = FALSE)

for(single_folder in data_folder) {
  
  rt_file <- list.files(single_folder, pattern = "_rtdata.txt$", full.names = T)
  
  # read RT data
  rt_data <- read.table(rt_file, sep = "\t", header = TRUE)
}

# iterate through all compounds in table
for(i in 1:nrow(`Compound-SBtab.tsv_table`)) {

  # neutral metabolites
  # get inchikey
  inchikey <- `Compound-SBtab.tsv_table`$`!Notes:InChIKey_neutral`[i]
  
  if(!is.na(inchikey)) {
    
    # perform mapping
    ids <- wormJam_mapper(inchikey, mapper)
    
    print(ids)
    
    # add ids to compound table
    # ChEBI are the primary IDs for WormJam and manually curated
    #`Compound-SBtab.tsv_table`$`!Notes:ChEBI_neutral`[i] <- ids[["ChEBI"]]
    `Compound-SBtab.tsv_table`$`!Notes:KEGG_neutral`[i] <- ids[["KEGG"]]
    `Compound-SBtab.tsv_table`$`!Notes:MetaCyc_neutral`[i] <- ids[["MetaCyc"]]
    `Compound-SBtab.tsv_table`$`!Notes:HMDB_neutral`[i] <- ids[["HMDB"]]
    `Compound-SBtab.tsv_table`$`!Notes:LipidMaps_neutral`[i] <- ids[["LipidMaps"]]
    `Compound-SBtab.tsv_table`$`!Notes:SwissLipids_neutral`[i] <- ids[["SwissLipids"]]
    `Compound-SBtab.tsv_table`$`!Notes:Wikidata_neutral`[i] <- ids[["Wikidata"]]
    `Compound-SBtab.tsv_table`$`!Notes:Pubchem_neutral`[i] <- ids[["PubChem"]]
    `Compound-SBtab.tsv_table`$`!Notes:Metabolights_neutral`[i] <- ids[["Metabolights"]]
    `Compound-SBtab.tsv_table`$`!Notes:Chemspider_neutral`[i] <- ids[["Chemspider"]]
  }
}

# save changes to the files
write_sbtab(model_folder)


# function to map WormJam InChI key to external DB id ==========================
wormJam_mapper <- function(inchikey, mapper) {
  
  # get all codes required in WormJam
  wormjam_codes <- .get_wormjam_codes()
  
  # generate empty list for ids
  ids <- list()
  
  for(wormjam_code in names(.get_wormjam_codes())) {
    
    wormjam_mapping <- BridgeDbR::map(mapper,
                                      inchikey,
                                      source = getSystemCode("InChIKey"),
                                      target = wormjam_codes[[wormjam_code]])
    
    if(length(wormjam_mapping) > 0) {
      
      # isolate based on regex
      if(wormjam_code == "ChEBI") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^CHEBI:\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "KEGG") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^C\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "MetaCyc") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^CPD-\\d{5}$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "HMDB") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^HMDB\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "LipidMaps") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^LM(FA|GL|GP|SP|ST|PR|SL|PK)[0-9]{4}([0-9a-zA-Z]{4,6})?$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "SwissLipids") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^SLM:\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "Wikidata") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^Q\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "PubChem") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "Metabolights") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^MTBLC\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } else if(wormjam_code == "Chemspider") {
        
        ids_list <- unlist(stringr::str_extract_all(wormjam_mapping,
                                                    "^\\d+$"))
        
        ids[[wormjam_code]] <- paste0(ids_list, collapse = ";")
        
      } 
      
      
      
      
    } else {
      
      ids[[wormjam_code]] <- NA
      
    }
  }
  
  return(ids)
  
}

# helper function for BridgDbR codes in WormJam ================================
.get_wormjam_codes <- function() {
  wormjam_codes <- list(
    "ChEBI" = BridgeDbR::getSystemCode("ChEBI"),
    "KEGG" = BridgeDbR::getSystemCode("KEGG Compound"),
    "MetaCyc" = BridgeDbR::getSystemCode("MetaCyc"),
    "HMDB" = BridgeDbR::getSystemCode("HMDB"),
    "LipidMaps" = BridgeDbR::getSystemCode("LIPID MAPS"),
    "SwissLipids" = BridgeDbR::getSystemCode("SwissLipids"),
    "Wikidata" = BridgeDbR::getSystemCode("Wikidata"),
    "PubChem" = BridgeDbR::getSystemCode("PubChem-compound"),
    "Metabolights" = BridgeDbR::getSystemCode("MetaboLights Compounds"),
    "Chemspider" = BridgeDbR::getSystemCode("Chemspider")
  )
  
  return(wormjam_codes)
}  