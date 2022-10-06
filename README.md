RNA Strain-Match
================

RNA Strain-Match uses known coding SNPs from strains to match bulk, single-cell, or nuclear RNA sequencing data to its appropriate strain. Calculations are perfomed using the presence or absence of alternate alleles in RNA data and do not consider homozygosity vs. heterozygosity.

This script was originally developed in the Kaczorowski Lab at The Jackson Laboratory to match data from B6 x BXD F1 mice to SNPs identified in the paternal BXD strain (Ashbrook 2022), but can be applied broadly to match RNA data to an appropriate strain.

Required Tools
--------------

| Tool | Version<sup>*</sup> |
| ---- | ---------- |
| [Samtools](https://www.htslib.org/) | 1.13 |
| [Rscript](https://www.r-project.org/) | 4.0.4 |

\* This is the version we used; other versions may work as well

Configuration File
------------------

The configuration file specifies several parameters that can be modified by the user. 

The file "config.sh" can be used a template configuration file

**Parameters**
| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| dir  | path | $(pwd) | The path to this script on your local device |
| bed  | file (including path) | ${dir}/strain-D2-SNPs.bed | A [bed](http://genome.ucsc.edu/FAQ/FAQformat#format1) file with the location of each SNP (start=end) |
| pos | file (including path) | ${dir}/pos.txt | The first two columns of "bed" separated by a space instead of a tab |
| snps | file (including path) | ${dir}/strain-D2-SNPs.txt | A matrix of genotype calls - see "SNP File" below for more details |
| samtools | program | samtools | Command to call samtools (if samtools is in your PATH variable, leave this as "samtools") |
| Rscript | program | Rscript | Command to call samtools (if Rscript is in your PATH variable, leave this as "Rscript") |
| id | string | "" | Your sample ID |
| o | string | ${id}-strain | Your output prefix |
| keep | logical | "" | Change to "true" to keep the per-SNP pileup data (file may be large) |
| varMatch | logical | "" | Change to "true" to output a file with variant-level sample/strain information (requires strain) |
| strain | string | "" | The strain to compare to for the varMatch option (must be present in SNP File) | 
| dp_cut | integer | 30 | A read-depth cutoff for considering a SNP useful |
| af_cut | float | 0.05 | An alt allele-fraction cutoff to consider the alt allele real |
| f1 | string | "TRUE" | Data belongs to a strain in the SNP file (FALSE) or the F1-progeny of a strain in the SNP file (TRUE) |
| threads | integer | 1 | The number of threads for computation |

SNP File
--------

The SNP file ("snps" in the configuration file) is a tab-delimited file specifying the genotypes at each SNP for each strain, where 

* "0/0" = REF/REF
* "0/1" = REF/ALT
* "1/1" = ALT/ALT
 
The columns are: the first six columns in a [vcf](http://genome.ucsc.edu/goldenPath/help/vcf.html) file, followed by a column for each strain and a column with the variant ID. 

The first few lines should look something like:

```
X.CHROM	POS	ID	REF	ALT	QUAL	STRAIN_1	STRAIN_2	...	STRAIN_N	VAR
chr1	3206491	.	G	C	72546.4	0/0	0/0	...	1/1	chr1_3206491
chr1	3213844	.	G	A	68282.1	0/1	1/1	...	0/0	chr1_3213844
chr1	3214941	.	A	T	94336	1/1	0/0	...	0/0	chr1_3214941
...
```

The "VAR" column should match the format "X.CHROM_POS".

### Variant Filters

**Required:**
* SNPs only
* Only one ALT allele

**Suggested:**
* Standard Variant-Call Quality Filters
* Limit to coding regions

### Building a SNPs File

> **Note**
> For BXD mouse strains you can use the attached file, *strain-D2-SNPs.txt*, along with *strain-D2-SNPs.bed* and *pos.txt*! This file was generated from data located on the European Nucleotide Archive (Project: [PRJEB45429](https://www.ebi.ac.uk/ena/browser/view/PRJEB45429?show=reads)).

For other strains, a SNP File can be generated from a vcf file with strain genotypes using [bcftools](https://samtools.github.io/bcftools/bcftools.html) and the following commands:

```
bcftools view your-strains.vcf.gz -i 'TYPE="snp"' |  grep -v ^## > strain-SNPs.txt

# Remove positions with multiple alt alleles
grep -v "," strain-SNPs.txt > tmp; mv -f tmp strain-SNPs.txt
```

followed by formatting in R:

```
snps <- read.delim(file="strain-SNPs.txt", stringsAsFactors=F)

for(i in 10:ncol(snps)){snps[,i] <- gsub("\\:.*","",snps[,i])}

snps$FORMAT <- NULL
snps$FILTER <- NULL
snps$INFO <- NULL

snps$VAR <- paste(sep = "_",snps$X.CHROM,snps$POS)

write.table(snps, "strain-SNPs.txt", sep="\t", quote=F, col.names=T, row.names=F)
```
The bed and pos files can then be generated with:

```
awk 'BEGIN{OFS="\t"}{FS="\t"}{print $1,$2,$2}' strain-SNPs.txt | tail -n +2 > strain-SNPs.bed

cut -f1-2 strain-SNPs.bed | sed "s/\t/ /g" | sed "s/chr//g" > pos.txt
```

Execution
---------

Once the configuration file is set up, the script can be run as:

`rna-strain-match -c config.sh`

> **Note**
> Using threads=4, a NucSeq bam file (~40G) took approximately 1.5h to run using 1e5 SNPs.

To display script info, enter:

`rna-strain-match -h` 

To perform a dry run (non-zero exit for missing input, but no calculations performed), enter:

`rna-strain-match -d -c config.sh`

Output
------

All output can be found in a directory named with the output prefix specified in the configuration file. <br />

The main output is a file ending in "-strains.txt" with columns:

| Column Name | Description |
| ----------- | ----------- |
| strain | each strain in the SNP file |
| ALT | the number of ALT allele matches |
| ALT.mismatch | the number of SNPs that are ALT in the RNA data, but REF in the SNP file |
| REF | the number of REF allele matches |
| REF.mismatch | the number of SNPs that are REF in the RNA data, but ALT in the SNP file |
| total | the total number of useable SNPs for the strain |
| match | the percentage of SNPs that match |

If "keep=true" in the configuration file, a file, "all-nuc.txt," that includes the base pileup at each SNP will be kept in the output directory.

> **Note**
> If you set "keep=true" then you can redo the calculations with different cutoffs by editing the cutoffs in the config.sh file and running the following:

```
source config.sh
$Rscript ${dir}/match-strains.R ${o}/all-nuc.txt ${o}/${id} $snps $dp_cut $af_cut $f1
```

If "varMatch=true" in the configuration file and a strain is provided, a file ending in "-var-matches.txt" that includes variant-level matches between the sample and the strain with columns:

| Column Name | Description |
| ----------- | ----------- |
| VAR | variant ID |
| CALL | the genotype call for the sample ("REF" means no ALT allele was present; "ALT" means ALT allele was present above af_cut) |
| PILEUP | all alleles present at this site ("B"="REF", "D"="ALT") | 
| DP | the depth at this site |
| AF | the alt allele fraction at this site | 
| ASSIGNED.STRAIN | the genotype for the assigned strain (0/0, 0/1, 1/1) |
| MATCH | TRUE if the sample matches the strain, FALSE if it does not |



Troubleshooting
---------------

* Make sure the chromosomes in the bed and pos files match those in the alignment (BAM) file (e.g. chr1, chr2, chr3 etc. vs. 1, 2, 3, etc.)
* **Contamination**: If the percent match is lower than expected, it could be due to contamination. Increasing "af_cut" raises the ALT allele-fraction cutoff to consider the ALT allele present, and therefore reduces noise from contamination. For downstream analysis, you may want to consider using a tool like [Soup-X](https://github.com/constantAmateur/SoupX) to remove cell-free mRNA. (Young 2018)

References
----------
1. D. G. Ashbrook, T. Sasani, M. Maksimov, M. H. Gunturkun, N. Ma, F. Villani, Y. Ren, D. Rothschild, H. Chen, L. Lu, V. Colonna, B. Dumont, K. Harris, M. Gymrek, J. K. Pritchard, A. A. Palmer, R. W. Williams "Private and sub-family specific mutations of founder haplotypes in the BXD family reveal phenotypic consequences relevant to health and disease" *bioRxiv* **2022**; doi: https://doi.org/10.1101/2022.04.21.489063
2. M. D. Young, S. Behjati "SoupX removes ambient RNA contamination from droplet based single cell RNA sequencing data" *bioRxiv* **2018**; doi: https://doi.org/10.1101/303727
