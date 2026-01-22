# Nextflow Training Configuration

This directory contains Nextflow configuration and training data for RNA-seq analysis.

## Configuration Overview

### Apple Silicon M3 Pro Optimization

**Hardware Specs:**
- **CPU:** M3 Pro chip with 12 cores (6 performance + 6 efficiency)
- **Memory:** 16GB recommended for RNA-seq workflows

**Nextflow Settings (`nextflow.config`):**
```groovy
params {
    max_cpus      = 10    // Optimized for M3 Pro (10/12 cores)
    max_memory    = '16GB' // Matches system RAM
    max_time      = '2.h'  // Reasonable timeout for pipelines
}
```

**Why max_cpus = 10:**
- **Performance cores:** 6 fast cores utilized for compute-intensive tasks
- **Efficiency cores:** 4 additional cores for parallel processing
- **System reserve:** 2 cores left for macOS and UI responsiveness
- **Balance:** Maximum performance without system lag or overheating

**Alternative Settings:**
- `max_cpus = 8` - Conservative (leaves 4 cores free, good for multitasking)
- `max_cpus = 12` - Aggressive (uses all cores, may cause UI lag)
- `max_cpus = 6` - Minimal (uses only performance cores)

### Docker Network Configuration

```groovy
docker {
  enabled = true
  runOptions = '--network rnaseq'  // Connects to RStudio container network
}
```

This ensures Nextflow pipeline containers can communicate with the RStudio server for integrated analysis workflows.

## Usage

### Running Pipelines

```bash
# From container (recommended)
docker-compose exec rstudio bash
cd /training
nextflow run nf-core/rnaseq -profile docker --input data/samplesheet.csv

# From host
nextflow run nf-core/rnaseq \
  -c training/nextflow.config \
  -profile docker \
  --input training/data/samplesheet.csv
```

### Data Structure

```
training/
├── nextflow.config    # Optimized configuration
├── data/             # Training datasets
│   └── samplesheet.csv
└── README.md         # This file
```

## Performance Tips

- **Monitor system:** Use Activity Monitor to ensure adequate system resources
- **Memory limits:** 16GB is suitable for most RNA-seq analyses
- **CPU scaling:** Adjust `max_cpus` down if system becomes unresponsive
- **Parallel processing:** M3 Pro efficiency cores help with multi-threaded bioinformatics tools

## Troubleshooting

**System unresponsive:**
- Reduce `max_cpus` to 6-8
- Close unnecessary applications
- Ensure proper cooling/ventilation

**Memory issues:**
- Monitor with `docker stats`
- Consider `max_memory = '8GB'` for memory-constrained workflows
- Use `--skip_*` flags in nf-core/rnaseq to reduce memory usage
