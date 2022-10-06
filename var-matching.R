#==============================================================
# GET INPUT DATA
#==============================================================

# Read in args
# args[1]: pileup raw output file
# args[2]: output basename
# args[3]: strain genotype info 
# args[4]: expected strain
# args[5]: depth cutoff to consider a var reliable
# args[6]: % alt allele required to consider a var reliable
# args[7]: is this F1 data or not

args = commandArgs(trailingOnly=TRUE)

# Read in base pileup
all.nuc <- read.delim(stringsAsFactors=F, file=args[1])

# Get rid of lines w/ indels
all.nuc <- all.nuc[-grep("[+-]",all.nuc$base_pileup),]

# Label vars
all.nuc$VAR <- paste(sep = "_",all.nuc$X.CHROM,all.nuc$POS)

# Read in strain genotype info
snps <- read.delim(stringsAsFactors=F, file=args[3])

# Get the assigned strain
strain <- args[4]

dp.cutoff=as.integer(args[5])
alt.percent=as.numeric(args[6])
f1=as.logical(args[7])

#==============================================================
# Get Variants w/ match/mismatch
#==============================================================

# Identify useful alleles

all.nuc$base_pileup <- as.character(sapply(1:nrow(all.nuc), function(x) gsub(ignore.case=T, all.nuc$REF[x], "B", all.nuc$base_pileup[x])))
all.nuc$base_pileup <- as.character(sapply(1:nrow(all.nuc), function(x) gsub(ignore.case=T, all.nuc$ALT[x], "D", all.nuc$base_pileup[x])))
all.nuc$base_pileup <- gsub(perl=T, "[^BD]","", all.nuc$base_pileup)

all.nuc$dp <- as.integer(sapply(all.nuc$base_pileup, function(x) nchar(x)))

all.nuc$ALT.percent <- as.numeric(sapply(all.nuc$base_pileup, function(x) nchar(gsub(perl=T, "[^D]", "", x))/nchar(x)))


# Identify informative vars 

# Using a cutoff of 0.05 for ALT.percent allows for some contamination

vars=c()
vars[all.nuc$VAR[all.nuc$dp > dp.cutoff & all.nuc$ALT.percent >= alt.percent]] <- "D"
vars[all.nuc$VAR[all.nuc$dp > dp.cutoff & all.nuc$ALT.percent == 0]] <- "B"


var.match <- data.frame(stringsAsFactors=F, "VAR"=names(vars), "CALL"=vars)
var.match$PILEUP <- as.character(sapply(var.match$VAR, function(x) all.nuc$base_pileup[all.nuc$VAR == x]))
var.match$DP <- as.character(sapply(var.match$VAR, function(x) all.nuc$dp[all.nuc$VAR == x]))
var.match$ALT.PERCENT <- as.character(sapply(var.match$VAR, function(x) all.nuc$ALT.percent[all.nuc$VAR == x]))

# Get the genotype for the assigned strain
var.match$ASSIGNED.STRAIN <- as.character(sapply(var.match$VAR, function(x) snps[snps$VAR == x,strain]))

# Check for matches
var.match$match <- T
var.match$match[var.match$CALL == "D" & var.match$ASSIGNED.STRAIN == "0/0"] <- F

if(f1){
  var.match$match[var.match$CALL == "B" & var.match$ASSIGNED.STRAIN == "1/1"] <- F
}else{
  var.match$match[var.match$CALL == "B" & var.match$ASSIGNED.STRAIN %in% c("1/1","0/1")] <- F
}

write.table(var.match, file=paste(sep="-",args[2], "var-matches.txt"), quote = F, sep = "\t", col.names = T, row.names = F)



