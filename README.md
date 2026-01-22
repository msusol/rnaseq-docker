# RNA-seq Tutorial with Docker Compose

This tutorial demonstrates running nf-core/rnaseq pipeline and downstream analysis with RStudio Server using Docker Compose.

## Apple Silicon Setup (M3/M4 Macs)

For Apple Silicon Macs (M3 Pro/M4 Max), follow these setup steps before using the container:

### 1. Install Java and Nextflow (no Homebrew)

- Install a Java 11+ JDK via MacPorts (for example an `openjdk` port) and ensure `java -version` reports that JDK in your PATH.
- Download Nextflow via the official script:
  ```bash
  curl -s https://get.nextflow.io | bash
  chmod +x nextflow && mv nextflow /usr/local/bin/
  ```
- Verify with `nextflow info`.

### 2. Configure Rancher Desktop as the Docker engine

- In Rancher Desktop settings, enable the **dockerd/moby** backend (or containerd with a Docker‑compatible socket).
- Confirm `docker ps` works in your terminal.
- Export the Rancher Docker socket: `export DOCKER_HOST=unix://$HOME/.rd/docker.sock`

### 3. Apple Silicon image settings

- Optionally set `DOCKER_DEFAULT_PLATFORM=linux/amd64` if you run into missing arm64 images (forces pulling amd64 images while still running on ARM64 via emulation).
- Prefer native arm64 images where available for better performance.

### 4. Configure nf-core/rnaseq profiles

- Use `-profile docker,arm` for ARM-aware settings and ARM-compatible images where available.
- Example test command:
  ```bash
  nextflow run nf-core/rnaseq -r 3.12.0 -profile docker,arm,test --outdir results_test -resume
  ```

## Setup

### Option 1: Pre-built ARM64 Image (Recommended)

1. **Start RStudio Server:**
   ```bash
   cd rnaseq-docker
   docker-compose up -d
   ```

2. **Access RStudio:**
   - Open `http://localhost:8787`
   - Username: `rstudio`
   - Password: `yourpassword` (change in docker-compose.yml)

### Option 2: Manual Build (Advanced)

If you prefer to build the image manually:

```bash
cd rnaseq-docker/container
docker buildx build --platform linux/arm64/v8 --tag rnaseq-docker-rstudio:arm64 .
cd ..
docker-compose up -d
```

## Workflow

### 1. Run nf-core/rnaseq Pipeline

Choose one of the following three pipeline options based on your system resources and testing needs:

#### Option 1: Quick Training/Test Run (Recommended for Learning)
Uses nf-core's built-in test data with no local FASTQ files needed. Outputs to `results_test`.

```bash
cd rnaseq-docker/training
nextflow run nf-core/rnaseq -r 3.12.0 -profile docker,test --outdir results_test -resume
```

**Alternative: Run from research/ directory:**
```bash
cd rnaseq-docker/research
nextflow run nf-core/rnaseq -r 3.12.0 -profile docker,test --outdir results_test_from_research -resume
```

#### Option 2: Use Chromosome 21 Subset (Recommended for Testing with Local Data)
Modify the command to use a smaller genome subset that fits within 18 GB RAM systems.

**Prerequisites:** Download chromosome 21 reference files to `data/refs/` directory.

**Download Commands:**
```bash
# Create refs directory
mkdir -p rnaseq-docker/research/data/refs
cd rnaseq-docker/research/data/refs

# 1. Download chromosome 21 FASTA (note: files are .fasta, not compressed)
aws s3 cp s3://ngi-igenomes/igenomes/Homo_sapiens/GATK/GRCh38/Sequence/Chromosomes/chr21.fasta ./ --no-sign-request
mv chr21.fasta Homo_sapiens_assembly38_chr21.fa

# 2. Create FASTA index using Docker (samtools not required locally)
docker run --rm -v $(pwd):/data -w /data biocontainers/samtools:v1.9-4-deb_cv1 \
  samtools faidx Homo_sapiens_assembly38_chr21.fa

# 3. Download GENCODE GTF file (chr21 subset)
# Since GATK bundle doesn't include annotations, download from GENCODE:
curl -L -o gencode.v29.annotation.gtf.gz \
  "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.annotation.gtf.gz"
gunzip gencode.v29.annotation.gtf.gz
# Extract only chr21 features
grep '^chr21' gencode.v29.annotation.gtf > gencode_v29_chr21.gff

# 4. Create minimal transcript FASTA for chr21 (simplified approach)
# Note: GENCODE transcript headers don't contain chromosome info, so we'll create a minimal transcript file
# For testing purposes, you can either:
# Option A: Use a placeholder (pipeline may still work with just FASTA + GTF)
echo ">ENST00000456328.2 chr21_placeholder_transcript" > gencode_v29_transcripts_chr21.fa
echo "ATCGATCGATCGATCGATCG" >> gencode_v29_transcripts_chr21.fa

# Option B: Skip transcript FASTA for now (remove transcript_fasta from config if needed)
# The pipeline may work with just the GTF file for basic testing

# Alternative: If you have the full GRCh38 igenomes downloaded, extract chr21 from there
# cd /path/to/your/GRCh38/Sequence/WholeGenomeFasta
# docker run --rm -v $(pwd):/data -w /data biocontainers/samtools:v1.9-4-deb_cv1 \
#   samtools faidx genome.fa chr21 > Homo_sapiens_assembly38_chr21.fa
# cd /path/to/your/GRCh38/Annotation
# grep '^chr21' gencode.v29.annotation.gtf > gencode_v29_chr21.gff
```

**Run Pipeline (Option A - HISAT2 alignment, skip subsampling to avoid Salmon issues):**
```bash
cd rnaseq-docker/research
nextflow run nf-core/rnaseq -r 3.12.0 \
  --input data/reads/rnaseq_samplesheet.csv \
  --outdir results_hisat2 \
  --genome GRCh38chr21 \
  --aligner hisat2 \
  --skip_biotype_qc \
  --skip_stringtie \
  --skip_bigwig \
  --skip_umi_extract \
  --skip_trimming \
  --skip_fastqc \
  --skip_markduplicates \
  --skip_dupradar \
  --skip_rseqc \
  --skip_qualimap \
  --min_mapped_reads 1 \
  -profile docker,arm
```

**Run Pipeline (Option B - Fix Salmon subsampling with real chr21 transcripts):**

Since Ensembl download failed, use the GENCODE transcripts you already downloaded and extract chr21 transcripts:

```bash
# Navigate to refs directory
cd rnaseq-docker/research/data/refs

# Remove the placeholder file
rm gencode_v29_transcripts_chr21.fa

# Try manual extraction first to debug
head -10 gencode.v29.transcripts.fa

# Check if chr21 transcripts exist in the file
grep -c 'chr21' gencode.v29.transcripts.fa

# Manual extraction using awk
awk '
BEGIN { in_chr21 = 0 }
/^>/ {
    in_chr21 = (index($0, "chr21") > 0)
    if (in_chr21) print $0
    next
}
in_chr21 { print }
' gencode.v29.transcripts.fa > gencode_v29_transcripts_chr21.fa

# Verify the extraction worked
head -5 gencode_v29_transcripts_chr21.fa
wc -l gencode_v29_transcripts_chr21.fa
ls -lh gencode_v29_transcripts_chr21.fa

# If still empty, try a simpler approach with a few known chr21 transcripts
echo ">ENST00000389680.6 chr21_ENST00000389680.6" > gencode_v29_transcripts_chr21.fa
echo "ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG" >> gencode_v29_transcripts_chr21.fa
echo ">ENST00000389681.6 chr21_ENST00000389681.6" >> gencode_v29_transcripts_chr21.fa
echo "GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA" >> gencode_v29_transcripts_chr21.fa
```

**Alternative: If manual extraction fails, create a minimal working file:**
```bash
# Create a minimal but valid FASTA file for testing
cat > gencode_v29_transcripts_chr21.fa << 'EOF'
>ENST00000389680.6 chr21_test_transcript_1
ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA
>ENST00000389681.6 chr21_test_transcript_2
TTTTAAAAAGGGGCCCCTTTTAAAAAGGGGCCCCTTTTAAAAAGGGGCCCCTTTTAAAAA
GGGGCCCCTTTTAAAAAGGGGCCCCTTTTAAAAAGGGGCCCCTTTTAAAAAGGGGCCCC
EOF
```

**Then run the full pipeline with STAR+Salmon:**
```bash
cd rnaseq-docker/research
nextflow run nf-core/rnaseq -r 3.12.0 \
  --input data/reads/rnaseq_samplesheet.csv \
  --outdir results_star_salmon \
  --genome GRCh38chr21 \
  --aligner star_salmon \
  --pseudo_aligner salmon \
  --skip_biotype_qc \
  --skip_stringtie \
  --skip_bigwig \
  --skip_umi_extract \
  --skip_trimming \
  --skip_fastqc \
  --skip_markduplicates \
  --skip_dupradar \
  --skip_rseqc \
  --skip_qualimap \
  -profile docker
```

**Alternative: If Ensembl download fails, try GENCODE:**
```bash
# Alternative download from GENCODE (if Ensembl is unavailable)
cd rnaseq-docker/research/data/refs
curl -L -o gencode.v29.transcripts.fa.gz \
  "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.transcripts.fa.gz"
gunzip gencode.v29.transcripts.fa.gz

# Extract chr21 transcripts using seqtk
docker run --rm -v $(pwd):/data -w /data biocontainers/seqtk:v1.3-1-deb_cv1 \
  bash -c "grep -E '^>ENST.*chr21' gencode.v29.transcripts.fa | sed 's/>//' > chr21_ids.txt && seqtk subseq gencode.v29.transcripts.fa chr21_ids.txt > gencode_v29_transcripts_chr21.fa"
```

#### Option 3: Full GRCh38 Genome Execution (Requires 72GB+ RAM)
For systems with sufficient memory (Gitpod's core plan with 128GB RAM recommended - 64GB RAM won't work). Uses the complete GRCh38 igenomes you downloaded.

```bash
cd rnaseq-docker/research
nextflow run nf-core/rnaseq -r 3.12.0 \
  --input data/reads/rnaseq_samplesheet.csv \
  --outdir results_star_salmon \
  --genome GRCh38 \
  --aligner star_salmon \
  --pseudo_aligner salmon \
  --skip_biotype_qc \
  --skip_stringtie \
  --skip_bigwig \
  --skip_umi_extract \
  --skip_trimming \
  --skip_fastqc \
  --skip_markduplicates \
  --skip_dupradar \
  --skip_rseqc \
  --skip_qualimap \
  -profile docker
```

### 2. Perform Differential Expression Analysis in RStudio

1. In RStudio, navigate to `/workspace/gitpod/training/DE_analysis/`
2. **Quick Start**: Use the pre-loaded script at `/workspace/de_rstudio.R` which contains the complete DESeq2 analysis workflow
3. Alternatively, follow the tutorial steps from `rnaseq/docs/usage/differential_expression_analysis/de_rstudio.md`
4. The results will be in `/workspace/gitpod/training/results_star_salmon/`

**The de_rstudio.R script includes:**
- Complete DESeq2 differential expression analysis
- Quality control plots (PCA, clustering heatmap)
- Statistical analysis and gene filtering
- Multiple visualization plots (MA plot, volcano plot, heatmap)
- Gene Ontology enrichment analysis
- Automated result saving to CSV and PNG files

## Directory Structure

```
rnaseq-docker/
├── container/                 # Docker container build files
│   ├── Dockerfile            # RStudio container definition
│   ├── build_command.sh      # Build script
│   ├── install_r_pkgs.sh     # R package installation
│   └── .dockerignore         # Docker ignore file
├── DE_analysis/              # RStudio working directory
│   ├── de_rstudio.R          # DESeq2 analysis script
│   └── de_results/           # Differential expression results
├── research/                 # Research data and outputs
│   ├── data/
│   │   ├── reads/            # FASTQ files and samplesheet
│   │   └── refs/             # Reference genome files (for GRCh38chr21)
│   ├── nextflow.config       # Nextflow configuration for research runs
│   ├── salmon-arm.config     # ARM64-specific config
│   ├── results_star_salmon/  # Pipeline outputs (STAR+Salmon)
│   │   └── pipeline_info/    # Execution reports and logs
│   └── work/                 # Nextflow intermediate files
├── training/                 # Training/test data and outputs
│   ├── data/
│   │   ├── reads/            # Training samplesheet
│   │   └── refs/             # Reference genome files
│   ├── results_test/         # Test pipeline outputs
│   │   ├── bbsplit/          # BBMap contamination filtering
│   │   ├── fastqc/           # FastQC quality reports
│   │   ├── multiqc/          # MultiQC summary reports
│   │   ├── pipeline_info/    # Execution reports and logs
│   │   ├── salmon/           # Salmon quantification
│   │   ├── star_salmon/      # STAR+Salmon alignment results
│   │   └── trimgalore/       # TrimGalore trimming reports
│   └── work/                 # Nextflow intermediate files
├── docker-compose.yml        # Docker Compose configuration
└── README.md                 # This file
```

## Configuration

### Nextflow Config (`nextflow.config`)

Following the tutorial recommendations, we've configured appropriate resource limits and Docker networking for ARM64 systems:

```groovy
docker {
  enabled = true
  runOptions = '--network rnaseq'
}

params {
    max_cpus      = 4
    max_memory    = '8GB'
    max_time      = '2.h'
}
```

**Network Configuration**: Nextflow containers automatically connect to the `rnaseq` Docker network (defined in `docker-compose.yml`). This enables communication between pipeline containers and RStudio.

## Notes

- RStudio Server runs on the `rnaseq` Docker network
- Data persists in the mounted volumes
- Use the Gitpod paths (`/workspace/gitpod/training/...`) within RStudio


## R Package Installation

The container uses `install_r_pkgs.sh` to install all required R packages using standard CRAN and Bioconductor repositories (no manual tar.gz downloads needed). The script installs:

- **CRAN packages**: tidyverse, kableExtra, remotes, ggnewscale, rvcheck
- **GitHub packages**: ggtree
- **Bioconductor packages**: DESeq2, tximport, clusterProfiler, and 15+ other bioinformatics packages

This approach is more reliable and maintainable than downloading and installing from tar.gz files.
