#!/bin/bash

# Replace w/ path to strain-id script
dir=$(pwd)

# ================================================================================
# Required files
# --------------
#
# 1. bed: a bed file with one line per variant (for SNPs start pos = end pos)
# 2. pos: the first two columns from bed separated by a space instead of a tab
# 3. bam: an alignment file for NucSeq data
# ================================================================================

bed=${dir}/strain-D2-SNPs.bed
pos=${dir}/pos.txt
snps=${dir}/strain-D2-SNPs.txt
bam=""

# ================================================================================
# Required programs
# --------------
#
# If these programs re not already included your PATH, include the full path 
#
# ================================================================================

samtools=samtools
Rscript=Rscript

# ================================================================================
# Variables
# --------------
# 
# in/out options
# --------------
#  1. id: sample identifier
#  2. o: output prefix
#  3. keep: change to "true" to keep pileup output (file may be large)
#  4. varMatch: output the vars and whether or not they match the given strain
#  5. strain: strain to match (required with varMatch)
#
# analysis options
# --------------
#  1. dp.cutoff: a depth cutoff for considering a variant reliable
#  2. alt.per: an alt-allele percentage cutoff for considering a var reliable
#  3. f1: vars are from current data (FALSE) or a parent strain (TRUE)
#
# compute options
# --------------
#  1. threads: number of threads to use for analysis
#
# ================================================================================

# in/out options

id=""
o=${id}-strain
keep=""
varMatch=""
strain=""

# analysis options

dp_cut=30
af_cut=0.05
f1="TRUE"

# compute options

threads=1





