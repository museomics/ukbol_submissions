
##############################################################################
## SUBMIT READS                                                             ##
## Author: Maria Kamouyiaros @NHMUK                                         ##
## Date: 2026-03-16                                                         ##
##############################################################################

library(dplyr)

# Import files
batch_file <- read.csv("sequencing_filepaths.csv", header = T, na.strings=c("")) 
samples <- read.csv("ena-registered-samples.csv", header = T)

# Define sequencing & library metadata:
sequencing_platform <- "ELEMENT"
sequencing_instrument <- "Element AVITI"
library_source <- "GENOMIC"
library_selection <- "RANDOM"
library_strategy <-  "WGS"

# Define Project Accession
study_accession <- "PRJEBXXXXX"

## Combine spreadsheets to patch file paths to sample accessions by sample_alias
df <- batch_file %>%
  left_join(samples, by = c("sample_alias" = "alias"))

df <- df[!is.na(df$id),]
df$experiment_name <- paste0("UKBOL_Accelerated_", df$sample_alias)

submission <- data.frame(study_accession =  study_accession,
                         sample_accession = df$id, 
                         experiment_name = df$experiment_name,
                         sequencing_platform = sequencing_platform, 
                         sequencing_instrument = sequencing_instrument, 
                         library_name = df$library_name, 
                         library_source = library_source, 
                         library_selection = library_selection, 
                         library_strategy = library_strategy, 
                         library_description	= df$library_description, 
                         "uploaded file 1" = df$uploaded.file.1, 
                         "uploaded file 2" = df$uploaded.file.2) 

write.table(submission, "sequence_submission.tsv", row.names=FALSE, sep = "\t", quote = F) 
