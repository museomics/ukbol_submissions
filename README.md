# ENA SUBMISSIONS SOP AND WORKING CODE FOR UKBOL ACCELERATED

<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/UKBOL%20dragonfly.png" width="200" height="200"
    alt="UKBOL Accelerated logo">
</p>

**Date:** 2026-03-19

**Author:** Maria Kamouyiaros

## Background
The following steps were used to prepare all files needed for submission of genomic skim data generated in UKBOL_Accelerated to the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home).
Each is desgined based on instructions and requirements set by ENA as under their ENA metadata model. 

<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_metadata_model.png" width="600" height="500"
    alt="ENA metadata model flowchart">
</p
  
###### Image taken from ENA's general guide. For more detailed information on their metadata model see [here](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/metadata.html).

## Requirements

### 1. A valid ENA Webin login
  An account can be registered [here](https://www.ebi.ac.uk/ena/submit/webin/login)

### 2. A registered study and study accession number

This can be found on the webin login page: 
![Webin register study](https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_study_registration.png)

With a guide on how to register available [here](https://ena-docs.readthedocs.io/en/latest/submit/study.html).

### 3. Spreadsheet of sample metadata 

- Format: CSV UTF-8
- Must contain values for (at minimum) all mandatory fields listed in the [Tree of Life Checklist (ERC000053)](https://www.ebi.ac.uk/ena/browser/view/ERC000053)

| Tree of Life value| Description|
|---|---|
| tax_id | A valid taxonomic ID - In UKBOL this is in 2 separate spreadsheets where taxIDs were searched externally (see `Sample Registration` below) and 476 new IDs were registered|
| scientific_name| Valid taxonomic name to min. species level (if genus information only then in the format of "Genus sp.". Note: unidentified species of genera have unique tax IDs that are different from the genus tax ID)| 
|sample_alias|A unique alias for each sample - for UKBOL this had the format of UKXXX-XX|
|sample_title|Voucher and alias information - for UKBOL this had the format of: NHM voucher: NHMUKXXXXXXXX; Sample ID: UKXXX-XXX|
|sample_description|Recorded taxonomic name associated with specimen|
|organism part|The part of the organism used to extract DNA (e.g., whole/ 1 leg/ 2 legs)|
|lifestage| Lifestage of organism|
|project name| The registered study ID |
|collected_by| Recorded sample collectors name|
|collection date| Recorded sample collection date in the format YEAR-MONTH-DAY|
|geographic location (latitude)| Recorded latitude in decimal degrees (max. 8 dp)|
|geographic location (longitude)|Recorded longitude in decimal degrees (max. 8 dp)|
|geographic location (region and locality)| Recorded sampling locality| 
|geographic location (country and/or sea)| Recorded sampling country|
|habitat| Recorded habitat information (in most cases not recorded)|
|sex| Recorded sex of organism (in most cases not recorded)|
|collecting institution| Collecting institution name (Natural History Museum, London)|
|specimen_voucher| Museum specimen voucher number|

[Where data is missing record "missing: third party data" unless specified otherwise under INSDC Missing Value Reporting Terms](https://ena-docs.readthedocs.io/en/latest/submit/samples/missing-values.html)

### 4. An install of R (v >4.3.0)
- Packages: dplyr and plyr

### 5. An install of ENA bulk webin-cli
This is available for install with associated information [here](https://github.com/enasequence/ena-bulk-webincli/tree/master)

## Sample Registration 

To register all samples - the metadata spreadsheet for all samples has to go through a series of clean-ups and checks: 
- Check for trailing whitespaces and tabs
- Check for valid date and coordinate formatting
- Check for valid country names
- Check for valid species names (if registering new) - Manual assessment and correction of any discrepancies in nomenclature 
- Check for valid tax IDs (if registering new) - In UKBOL Accelerated, tax IDs were searched with [taxid-minting](https://github.com/museomics/taxid-minting-process) and 476 new tax IDs were registered.

 These are all done in R with the following code: 
 
```
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
```

If needed the above can be re-run for any number of sample batches and registrations depending on missing tax IDs and tax ID registration batches. 

```
#########################################################################
##### METADATA PREP FOR SAMPLE REGISTRATION - CHECKS AND FORMATTING
#########################################################################

df <- read.csv("samples_for_registration.csv", header = T)

df[] <- lapply(df, function(x) gsub("missing: not collected: third party data", "missing: third party data", x))

## Check lat/lon:
df$Latitude <- gsub("missing: third party data", NA, df$geographic.location..latitude.)
df$Longitude <- gsub("missing: third party data", NA, df$geographic.location..longitude)
df$Latitude <- as.numeric(df$Latitude)
df$Longitude <- as.numeric(df$Longitude)

df$Latitude[!is.na(df$Latitude)] <- round(df$Latitude[!is.na(df$Latitude)], 8)
df$Longitude[!is.na(df$Longitude)] <- round(df$Longitude[!is.na(df$Longitude)], 8)

## Flag incorrect countries based on list from ENA
allowed.countries <- c("Afghanistan","Albania","Algeria","American Samoa","Andorra","Angola","Anguilla","Antarctica","Antigua and Barbuda","Arctic Ocean","Argentina","Armenia","Aruba","Ashmore and Cartier Islands","Atlantic Ocean","Australia","Austria","Azerbaijan","Bahamas","Bahrain","Baker Island","Baltic Sea","Bangladesh","Barbados","Bassas da India","Belarus","Belgium","Belize","Benin","Bermuda","Bhutan","Bolivia","Borneo","Bosnia and Herzegovina","Botswana","Bouvet Island","Brazil","British Virgin Islands","Brunei","Bulgaria","Burkina Faso","Burundi","Cambodia","Cameroon","Canada","Cape Verde","Cayman Islands","Central African Republic","Chad","Chile","China","Christmas Island","Clipperton Island","Cocos Islands","Colombia","Comoros","Cook Islands","Coral Sea Islands","Costa Rica","Cote d'Ivoire","Croatia","Cuba","Curacao","Cyprus","Czechia","Czech Republic","Democratic Republic of the Congo","Denmark","Djibouti","Dominica","Dominican Republic","Ecuador","Egypt","El Salvador","Equatorial Guinea","Eritrea","Estonia","Eswatini","Ethiopia","Europa Island","Falkland Islands (Islas Malvinas)","Faroe Islands","Fiji","Finland","France","French Guiana","French Polynesia","French Southern and Antarctic Lands","Gabon","Gambia","Gaza Strip","Georgia","Germany","Ghana","Gibraltar","Glorioso Islands","Greece","Greenland","Grenada","Guadeloupe","Guam","Guatemala","Guernsey","Guinea","Guinea-Bissau","Guyana","Haiti","Heard Island and McDonald Islands","Honduras","Hong Kong","Howland Island","Hungary","Iceland","India","Indian Ocean","Indonesia","Iran","Iraq","Ireland","Isle of Man","Israel","Italy","Jamaica","Jan Mayen","Japan","Jarvis Island","Jersey","Johnston Atoll","Jordan","Juan de Nova Island","Kazakhstan","Kenya","Kerguelen Archipelago","Kingman Reef","Kiribati","Kosovo","Kuwait","Kyrgyzstan","Laos","Latvia","Lebanon","Lesotho","Liberia","Libya","Liechtenstein","Line Islands","Lithuania","Luxembourg","Macau","Madagascar","Malawi","Malaysia","Maldives","Mali","Malta","Marshall Islands","Martinique","Mauritania","Mauritius","Mayotte","Mediterranean Sea","Mexico","Micronesia, Federated States of","Midway Islands","Moldova","Monaco","Mongolia","Montenegro","Montserrat","Morocco","Mozambique","Myanmar","Namibia","Nauru","Navassa Island","Nepal","Netherlands","New Caledonia","New Zealand","Nicaragua","Niger","Nigeria","Niue","Norfolk Island","North Korea","North Macedonia","North Sea","Northern Mariana Islands","Norway","Oman","Pacific Ocean","Pakistan","Palau","Palmyra Atoll","Panama","Papua New Guinea","Paracel Islands","Paraguay","Peru","Philippines","Pitcairn Islands","Poland","Portugal","Puerto Rico","Qatar","Republic of the Congo","Reunion","Romania","Ross Sea","Russia","Rwanda","Saint Barthelemy","Saint Helena","Saint Kitts and Nevis","Saint Lucia","Saint Pierre and Miquelon","Saint Vincent and the Grenadines","Samoa","San Marino","Saint Martin","Sao Tome and Principe","Saudi Arabia","Senegal","Serbia","Seychelles","Sierra Leone","Singapore","Sint Maarten","Slovakia","Slovenia","Solomon Islands","Somalia","South Africa","South Georgia and the South Sandwich Islands","South Korea","South Sudan","Southern Ocean","Spain","Spratly Islands","Sri Lanka","State of Palestine","Sudan","Suriname","Svalbard","Sweden","Switzerland","Syria","Taiwan","Tajikistan","Tanzania","Tasman Sea","Thailand","Timor-Leste","Togo","Tokelau","Tonga","Trinidad and Tobago","Tromelin Island","Tunisia","Turkey","Turkmenistan","Turks and Caicos Islands","Tuvalu","USA","Uganda","Ukraine","United Arab Emirates","United Kingdom","Uruguay","Uzbekistan","Vanuatu","Venezuela","Viet Nam","Wake Island","Virgin Islands","Wallis and Futuna","West Bank","Western Sahara","Yemen","Zambia","Zimbabwe","missing","missing: control sample","missing: data agreement established pre-2023","missing: endangered species","missing: human-identifiable","missing: lab stock","missing: sample group","missing: synthetic construct","missing: third party data","not applicable","not collected","not provided","restricted access")
df$geographic.location..country.and.or.sea.[which(!(df$geographic.location..country.and.or.sea. %in% allowed.countries))]
  ## this should give character(0)

## Generate final dataframe
df.reg <- data.frame(tax_id = df$TaxID, scientific_name = df$scientific_name, sample_alias = df$sample_alias, 
                     sample_title = df$sample_title, sample_description = df$sample_description, "organism part" = df$organism.part, 
                     lifestage = df$lifestage, "project name" = df$project.name, collected_by = df$collected_by , "collection date" = df$collection.date,
                     "geographic.location..latitude." = df$Latitude, "geographic.location..longitude." = df$Longitude, 
                     "geographic.location..region.and.locality." = df$geographic.location..region.and.locality., "habitat" = df$habitat,                                
                     "sex"= df$sex, "geographic.location..country.and.or.sea." = df$geographic.location..country.and.or.sea.,
                     "collecting.institution" = df$collecting.institution, "specimen_voucher" = df$specimen_voucher
)

# remove any rogue tabs and replace with whitespace
df.reg[] <- lapply(df.reg, function(col) {
  if (is.character(col)) gsub("\t", " ", col) else col
})

df.latlong <- df.reg[!is.na(df.reg$geographic.location..latitude.),]

df.nolatlong <- df.reg[is.na(df.reg$geographic.location..latitude.),]
to.rm <- c("geographic.location..longitude.", "geographic.location..latitude.")
df.nolatlong <- df.nolatlong[,  !(names(df.nolatlong) %in% to.rm)]

write.table(df.latlong, "sample_registration.tsv", sep="\t", row.names = F)
write.table(df.nolatlong, "sample_registration_nolatlon.tsv", sep = "\t", row.names = F)
write.csv(df.reg, "sample_registration_2026-03-18.csv", row.names= F)
```

**NOTE:** You will notice that at the end samples with no lat/lon metadata are parsed into a separate submission TSV file. This is because ENA treats lat/lon as mandatory fields if the header is present and therefore won't accept missing terms. 

Once the TSVs have been generated you will need to add the following line above the header row: 
> Checklist	ERC000053:1.6	Tree of Life Checklist

And this below the header row 
> #units										DD	DD						

OR the following if lat/lon not included: 
> #units															

The TSV files are then ready for submission via the ENA Webin:

<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_sample_registration.png" width="600" height="500"
    alt="ENA Webin sample registration">
</p


## Sequencing read submission 

This information is needed in a single TSV file that can be used to generate a [manifest file](https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html). 

|Value| Description |
|---|---|
|study_accession| project accession number|
|sample_accession| Unique sample accession number from ENA - available under Samples > Samples Report | 
|experiment_name| A unique experiment name|
|sequencing_platform| Sequencing platform used. [See ENA permitted values](https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#platform)|
|sequencing_instrument|Sequencing instrument used. [See ENA permitted values](https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#instrument)| 
|library_name|Identifier for library and sequencing run, e.g., Batch01|
|library_source| Source molecule, e.g., `GENOMIC` [See ENA permitted values](https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#source)| 
|library_selection|Library selection, e.g. `RANDOM` [See ENA permitted values](https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#selection), 
|library_strategy|Sequencing strategy, e.g., whole genome sequencing (`WGS`). [See ENA permitted values](https://ena-docs.readthedocs.io/en/latest/submit/reads/webin-cli.html#strategy), 
|library_description| Unique descriptor for library| 
|"uploaded file 1"|Gzipped forward filepath - `uploaded.file.1`|
|"uploaded file 2"|Gzipped reverse filepath - `uploaded.file.2`| 


### To generate that TSV:

1. CSV: ENA registered sample metadata - this can be downloaded directly from the ENA webin site (must contain at minimum sample accession (`sample_accession`) and unique sample name - in this case we use `sample_alias`) 

![ENA Webin Sample metadata download](https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_sample_download.png)

2. CSV: Sequence filepaths - this must have a minimum of 3 columns, unique sample name (`sample_alias`), forward read filepath (`uploaded.file.1`) and reverse read filepath (`uploaded.file.2`)

To generate the TSV run the following R code - change defined variables according to needs: 

```

##############################################################################
## SUBMIT READS                                                             ##
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
```

Once this TSV is generated, it can be **validated** and then **submitted** to ENA via the [ena bulk webincli tool](https://github.com/enasequence/ena-bulk-webincli/tree/master).
This tool takes the TSV and generates individual manifests before submitting the manifests and sequence data to ENA. 

To validate the TSV and generate the manifests the command would look like the following: 
```

python /path/to/ena-bulk-webincli/bulk_webincli.py -u Webin-XXXXX -p XXXXXX -g reads -s sequence_submission_.tsv -m validate -d UKBOL_accelerated --webinCliPath /path/to/ena-bulk-webincli/webin-cli-9.0.1.jar
```

**NOTE** You will have to specify the filepath to bulk_webincli.py based on where your install is. You will also have to specify your webin login details (`-u` and `-p` for username and password). The argument `-d` specifies the parent directory of your files to be uploaded
To submit the manifests run change `-m validate` to `-m submit`: 

```
python /path/to/ena-bulk-webincli/bulk_webincli.py -u Webin-XXXXX -p XXXXXX -g reads -s sequence_submission_.tsv -m submit -d UKBOL_accelerated --webinCliPath /path/to/ena-bulk-webincli/webin-cli-9.0.1.jar

```

## Mitogenome assembly submissions

- Mitogenome success assessed by contiguity, length and circularity of final scaffold (considered complete if circularised by getOrganelle v XXXX; partial = single, non-circularised scaffold of minimum length of 5kbp)
- Multi-contig mitogenome assemblies were then assessed for taxonomic assignment, protein-coding gene duplications and gene content (contig assembly considered on where minimum of 5 genes found on each contig, and each contig is taxonomically placed in the correct order to prevent upload of non-target/contaminant mitogenome assemblies).
- Complete and partial mitogenomes are uploaded as [assemblies](https://ena-docs.readthedocs.io/en/latest/submit/assembly/genome.html)
- Multi-contig assemblies are uploaded as [targeted sequences](https://ena-docs.readthedocs.io/en/latest/submit/sequence.html
- Annotations in all cases were connected to sequence data and stored in ENA compatible [FLATFILE format] (https://ena-docs.readthedocs.io/en/latest/submit/fileprep/flat-file-example.html) 
