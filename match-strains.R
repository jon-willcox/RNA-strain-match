#==============================================================
# GET INPUT DATA & VARS
#==============================================================

# Read in args
# args[1]: pileup raw output file
# args[2]: output basename
# args[3]: strain genotype info 
# args[4]: depth cutoff to consider a var reliable
# args[5]: % alt allele required to consider a var reliable
# args[6]: is this F1 data or not

args = commandArgs(trailingOnly=TRUE)

# Read in base pileup
all.nuc <- read.delim(stringsAsFactors=F, file=args[1])

# Get rid of lines w/ indels
all.nuc <- all.nuc[-grep("[+-]",all.nuc$base_pileup),]

# Label vars
all.nuc$VAR <- paste(sep = "_",all.nuc$X.CHROM,all.nuc$POS)

# Read in strain genotype info
snps <- read.delim(stringsAsFactors=F, file=args[3])

dp.cutoff=as.integer(args[4])
alt.percent=as.numeric(args[5])
f1=as.logical(args[6])

#==============================================================
# Get Matching Strains
#==============================================================

# Identify useful alleles

all.nuc$base_pileup <- as.character(sapply(1:nrow(all.nuc), function(x) gsub(ignore.case=T, all.nuc$REF[x], "B", all.nuc$base_pileup[x])))
all.nuc$base_pileup <- as.character(sapply(1:nrow(all.nuc), function(x) gsub(ignore.case=T, all.nuc$ALT[x], "D", all.nuc$base_pileup[x])))
all.nuc$base_pileup <- gsub(perl=T, "[^BD]","", all.nuc$base_pileup)

all.nuc$dp <- as.integer(sapply(all.nuc$base_pileup, function(x) nchar(x)))

all.nuc$ALT.percent <- as.numeric(sapply(all.nuc$base_pileup, function(x) nchar(gsub(perl=T, "[^D]", "", x))/nchar(x)))


# Identify informative vars
# Each position is assigned a "B" (entirely WT) and a "D" (alt allele present at > alt.percent)

# Using a cutoff of alt.percent allows for some contamination

vars=c()
vars[all.nuc$VAR[all.nuc$dp > dp.cutoff & all.nuc$ALT.percent >= alt.percent]] <- "D"
vars[all.nuc$VAR[all.nuc$dp > dp.cutoff & all.nuc$ALT.percent == 0]] <- "B"


# calculate percent match for each strain w/ available data

strain <- data.frame(stringsAsFactors=F, "strain"=colnames(snps)[7:(ncol(snps)-1)])

strain$ALT <- as.integer(sapply(strain$strain, function(x) length(which(snps[snps$VAR %in% names(vars[vars == "D"]),x] %in% c("1/1","0/1")))))
strain$ALT.mismatch <- as.integer(sapply(strain$strain, function(x) length(which(snps[snps$VAR %in% names(vars[vars == "D"]),x] %in% c("0/0")))))


# If sample is from f1, B can be from REF/REF or REF/ALT. If not, B should mostly only be from REF/REF
if (f1){
  strain$REF <- as.integer(sapply(strain$strain, function(x) length(which(snps[snps$VAR %in% names(vars[vars == "B"]),x] %in% c("0/0","0/1")))))
  strain$REF.mismatch <- as.integer(sapply(strain$strain, function(x) length(which(snps[snps$VAR %in% names(vars[vars == "B"]),x] %in% c("1/1")))))
}else{
  strain$REF <- as.integer(sapply(strain$strain, function(x) length(which(snps[snps$VAR %in% names(vars[vars == "B"]),x] %in% c("0/0")))))
  strain$REF.mismatch <- as.integer(sapply(strain$strain, function(x) length(which(snps[snps$VAR %in% names(vars[vars == "B"]),x] %in% c("1/1","0/1")))))
}

strain$total <- as.integer(sapply(strain$strain, function(x) length(which(snps[snps$VAR %in% names(vars),x] %in% c("0/0","1/1","0/1")))))
strain$match <- as.numeric(sapply(1:nrow(strain), function(x) (strain$ALT[x]+strain$REF[x])/strain$total[x]))


strain <- strain[order(decreasing=T, strain$match),]

# Write output file
write.table(strain, file=paste(sep="-",args[2], "strains.txt"), quote = F, sep = "\t", col.names = T, row.names = F)


