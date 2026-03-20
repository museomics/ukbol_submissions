#########################################################################
## PREP SPREADSHEET FOR ENA SUBMISSION                                 ##
## Author: Maria Kamouyiaros @NHMUK                                    ##
## Date: 2026-03-16                                                    ##
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
