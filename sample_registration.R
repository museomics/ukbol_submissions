#########################################################################
## PREP SPREADSHEET FOR ENA SUBMISSION                                 ##
#########################################################################
library(dplyr)
library(plyr)

# load the metadata spreadsheet & tax ID sheets
df <- read.csv("ENA_master_sheet_checklist-ERC000053_1.csv", header = T)
ena_reg <- read.table("UKBOL_taxid_request_form_ENA.tsv", sep = "\t", header = T) # registered tax IDs 
ena_taxids <- read.csv("samples_with_ena_taxids.csv", header = T) # minted tax IDs


# remove trailing white spaces
df[] <- lapply(df, function(x) if (is.character(x)) trimws(x) else x)

# for each scientific_name count number of words, if == 1, paste0(x, " sp.")
i <- 1

for(i in 1:nrow(df)){
  words <- strsplit(df$scientific_name[i], "\\s+")[[1]]
  word_count <- length(words)
  if(word_count== 1){ 
    df$scientific_name[i] <- paste(df$scientific_name[i], "sp.", df$sample_alias[i], sep = " ")
  }else{
    next
  }
}


# patch with taxid minting output
ena_taxids2 <- ena_taxids[, 2:3]
ena_taxids2 <- unique(ena_taxids2)

df_filled <- df %>%
  left_join(ena_taxids2, by = c("scientific_name"= "scientificName"))

df_filled[is.na(df_filled$TaxID), "TaxID"] <- df_filled[is.na(df_filled$TaxID), "ena_taxid"]

# check conflicts to make sure patching worked 
check <- df_filled[-which(df_filled$TaxID == df_filled$ena_taxid),]

# patch with registered taxids received from ENA and check for conflicts in proposed versus registered name
ena_reg$proposed_name <- gsub("  ", " ", ena_reg$proposed_name)
ena_reg[which(!(ena_reg$proposed_name == ena_reg$current.name)),]
missing <- which(!(ena_taxids$ena_taxid %in% df_filled$ena_taxid))
ena_taxids[missing,]

df_filled2 <- df_filled %>%
  left_join(ena_reg, by = c("scientific_name" = "proposed_name"))

  ## check for conflicts with new registered taxIDs
  check <- df_filled2[is.na(df_filled2$TaxID), ] 

# Checkpoint - write out any missing tax IDs to a separate file and save samples for registration
write.csv(df_filled2[which(is.na(df_filled2$TaxID)), ], "missing_taxIDs.csv", row.names = F)
write.csv(df_filled2[which(!is.na(df_filled2$TaxID)),], "samples_for_registration.csv", row.names = F)
