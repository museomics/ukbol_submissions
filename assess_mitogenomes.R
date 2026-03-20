##############################################################################
## ASSESSING MITOGENOME ASSEMBLIES FROM SKIM2MITO                        ##
## Author: Maria Kamouyiaros @NHMUK                                         ##
## Date: 2026-03-20                                                         ##
##############################################################################

library(dplyr)

assess_mitogenomes <- function(directory){

  files  <- list.files(path = directory, pattern = 'summary_contigs_mqc.txt', recursive = T)
  tables <- lapply(files, read.table, header = TRUE, sep = "\t")
  combined.df <- do.call(rbind , tables)

  # Remove NAs
  summary <- combined.df[complete.cases(combined.df),]

  # Filter by main criteria: must be Insecta & must be >= 5000bp & must have min. 5 genes
  summary_filtered <- summary[summary$Length >= 5000 & summary$Class == "Insecta" & summary$N..genes >=5,]

  # Remove any contigs with duplicated genes
  torm <- grep("_", summary_filtered$Genes.list)
  summary_filtered <- summary_filtered[-torm, ]
  
  # Add in information about whether mtDNA is partial (linear) or complete (circular)
  summary_filtered$level <- "linear"
  summary_filtered$level[grep("circular", summary_filtered$Contig)] <- "circular"

  # Count number of contigs per assembly
  df <- summary_filtered %>%
    group_by(ID) %>%
    mutate(N.contigs = n_distinct(Contig)) %>%
    ungroup()

  multi_contigs <- df[df$N.contigs>1, c("ID", "Contig")]
  multi_contigs <- multi_contigs %>%
    group_by(ID) %>%
    summarise(Contigs = paste(Contig, collapse = ","), .groups = "drop")

  linear <- df[df$N.contigs == 1 & df$level == "linear", c("ID", "Contig")] 
  circular <- df[df$N.contigs == 1 & df$level == "circular", c("ID", "Contig")]



  n.multi <- length(unique(multi_contigs$ID))
  n.circular <- length(unique(circular$ID))
  n.linear <- length(unique(linear$ID))

  summary_assemblies <- data.frame(category = c("complete mitochondrial genome", "partial mitochondrial genome", "mitochondrial genome assembly"), 
                                 submission_type = c("chromosome-level", "chromosome-level", "contig-level"),
                                 n_submissoins = c(n.circular, n.linear, n.multi))

  write.csv(multi_contigs, "multi_contig_assemblies.csv", row.names = F)
  write.csv(linear, "linear_assemblies.csv", row.names = F)
  write.csv(circular, "circular_assemblies.csv", row.names = F)
  write.csv(summary_assemblies, "summary_assemblies.csv", row.names = F)



  #### Create contig subset lists for multi_contig assemblies:
  i <- 1
  for(i in 1:nrow(multi_contigs)){
    name <- multi_contigs$ID[i] 
    contigs <- matrix(strsplit(multi_contigs$Contigs[i], ",")[[1]])
    outfile <- paste0(name, ".txt")
  
  write.table(contigs, outfile, sep="\t", col.names = F, row.names = F, quote = FALSE)
  }
}
