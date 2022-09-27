RNA Strain-Match
================

RNA Strain-Match uses known coding SNPs from strains to match bulk, single-cell, or nuclear RNA sequencing data to its appropriate strain.

It was originally developed to match data from B6 x BXD F1 mice to SNPs identified in the paternal BXD strain (Ashbrook 2021), but can be applied broadly to match RNA data to an appropriate strain.

Required Tools
--------------

| Tool | Version[^*] |
| ---- | ---------- |
| (Samtools)[https://www.htslib.org/] | 1.13 |
| (Rscript)[https://www.r-project.org/] | 4.0.4 |

[^*] This is the version we used; other versions may work as well



References
----------
1. D. G. Ashbrook, D. Arends, P. Prins, M. K. Mulligan, S. Roy, E. G. Williams, C. M. Lutz, A. Valenzuela, C. J. Bohl, J. F. Ingles, M. S. McCarty, A. G. Centeno, R. Hager, J. Auwerx, L. Lu, R. W. Williams "A platform for experimental precision medicine: The extended BXD mouse family" Cell Syst 2021, 12:3, 235-247
