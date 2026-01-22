#!/usr/bin/env bash
set -euo pipefail

# 1) Bioconductor setup (aligns Bioc with R 4.5)
Rscript -e "if (!requireNamespace('BiocManager', quietly = TRUE))
              install.packages('BiocManager', repos='https://cloud.r-project.org');
            BiocManager::install(ask = FALSE)"

# 2) CRAN + GitHub packages
Rscript -e "install.packages(c(
  'kableExtra',
  'remotes',
  'ggnewscale',
  'tidyverse',
  'rvcheck'
), repos = 'https://cloud.r-project.org', dependencies = TRUE);
remotes::install_github('YuLab-SMU/ggtree')"

# 3) Bioconductor packages (including the ones you previously had as tar.gz)
Rscript -e "BiocManager::install(c(
  'Gviz',
  'VariantAnnotation',
  'GenomicFeatures',
  'rtracklayer',
  'Biostrings',
  'ggtree',
  'DESeq2',
  'tximport',
  'tximeta',
  'msa',
  'seqinr',
  'fgsea',
  'GOSemSim',
  'qvalue',
  'reshape2',
  'downloader',
  'enrichplot',
  'plotly',
  'org.Hs.eg.db',
  'AnnotationDbi',
  'GO.db',
  'DO.db',
  'DOSE',
  'clusterProfiler'
), ask = FALSE)"

# No curl or .tar.gz handling is needed anymore; those are all handled via CRAN/Bioconductor.