# ENA SUBMISSIONS SOP FOR UKBOL ACCELERATED

[![DOI](https://zenodo.org/badge/1186149562.svg)](https://doi.org/10.5281/zenodo.19132437)


<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/UKBOL%20dragonfly.png" width="200" height="200"
    alt="UKBOL Accelerated logo">
</p>

**Date:** 2026-03-19

**Author:** Maria Kamouyiaros@NHMUK

## Background
The following steps were used to prepare all files needed for submission of genomic skim data generated in UKBOL_Accelerated to the [European Nucleotide Archive (ENA)](https://www.ebi.ac.uk/ena/browser/home).
Each is desgined based on instructions and requirements set by ENA as under their [ENA metadata model](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/metadata.html). 

<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_metadata_model.png" width="600" height="500"
    alt="ENA metadata model flowchart">
  <figcaption>Image taken from ENA's general guide. </figcaption>
</p


#

## Requirements

**1. A valid ENA Webin login**
An account can be registered [here](https://www.ebi.ac.uk/ena/submit/webin/login)

**2. A registered study and study accession number**
This can be found on the webin login page: 
<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_study_registration.png" width="600" height="500"
    alt="Webin register study">
</p
With a guide on how to register available [here](https://ena-docs.readthedocs.io/en/latest/submit/study.html).

**3. Spreadsheet of sample metadata**
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

**4. An install of R (v >4.3.0)**
- Packages: dplyr and plyr

**5. An install of ENA bulk webin-cli**
This is available for install with associated information [here](https://github.com/enasequence/ena-bulk-webincli/tree/master)

## Sample Registration 

To register all samples - the metadata spreadsheet for all samples has to go through a series of clean-ups and checks: 
- Patch spreadsheet with existing tax IDs
- Patch spreadsheet with any registered tax IDs
- Check for trailing whitespaces and tabs
- Check for valid date and coordinate formatting
- Check for valid country names
- Check for valid species names (if registering new) - Manual assessment and correction of any discrepancies in nomenclature 
- Check for valid tax IDs (if registering new) - In UKBOL Accelerated, tax IDs were searched with [taxid-minting](https://github.com/museomics/taxid-minting-process) and 476 new tax IDs were registered.

These are all done in R with the following R script: [sample_registration.R](https://github.com/museomics/ukbol_submissions/blob/main/sample_registration.R)

### This script is made up of 2 main steps:

  - Step one: prepares metadata spreadsheet for ENA submission requirements by patching the spreadsheet with existing and registered tax IDs and checks for any missing (outputs `missing_taxIDs.csv`)
  - Step two: final checks and formatting for ENA submission. **Outputs:** **(1)** either a list of countries that are incorrectly spelled in the terminal or `character(0)` if all countries are named correctly, **(2)** a final csv of all of the final information (`sample_registration.csv`), **(3)** a TSV for submission online containing samples with lat/lon (`sample_registration.tsv`), and **(4)** a TSV for submission containing only samples without lat/lon (`sample_registration_nolatlon.tsv`).  

**NOTE:** You will notice that at the end samples with no lat/lon metadata are parsed into a separate submission TSV file. This is because ENA treats lat/lon as mandatory fields if the header is present and therefore won't accept missing terms. 

Once the TSVs have been generated you will need to add the following line above the header row: 
```
Checklist	ERC000053:1.6	Tree of Life Checklist
```
And this below the header row 
```
#units										DD	DD						
```
**OR** the following if lat/lon not included: 
```
#units															
```
The TSV files are then ready for submission via the ENA Webin.

<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_sample_registration.png" width="400" height="300"
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


**To generate that TSV:**

1. CSV: ENA registered sample metadata - this can be downloaded directly from the ENA webin site (must contain at minimum sample accession (`sample_accession`) and unique sample name - in this case we use `sample_alias`) 

<p align="center">
  <img src="https://github.com/museomics/ukbol_submissions/blob/main/img/ENA_sample_download.png" width="400" height="300"
    alt="ENA Webin Sample metadata download">
</p

2. CSV: Sequence filepaths - this must have a minimum of 3 columns, unique sample name (`sample_alias`), forward read filepath (`uploaded.file.1`) and reverse read filepath (`uploaded.file.2`)

To generate the TSV run the R code [submit_reads.R](https://github.com/museomics/ukbol_submissions/blob/main/submit_reads.R)- where you change defined variables according to needs.

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
