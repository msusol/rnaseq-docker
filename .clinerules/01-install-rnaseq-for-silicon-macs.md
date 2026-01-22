For nf-core/rnaseq on an M‑series Mac with Rancher Desktop, install Java and Nextflow without Homebrew, point Docker to Rancher’s engine, use the nf-core `docker,arm` profiles, and then launch the pipeline with your samplesheet and references. [reddit](https://www.reddit.com/r/bioinformatics/comments/11mhjzq/nfcore_rnaseq_pipeline_on_m1_chip/)

## 1. Install Java and Nextflow (no Homebrew)

- Install a Java 11+ JDK via MacPorts (for example an `openjdk` port) and ensure `java -version` reports that JDK in your PATH. [training.nextflow](https://training.nextflow.io/2.1/envsetup/02_local/)
- Download Nextflow via the official script:  
  - `curl -s https://get.nextflow.io | bash`  
  - `chmod +x nextflow` and move it into a directory on your PATH (for example `$HOME/.local/bin` or a MacPorts‑managed bin dir), then verify with `nextflow info`. [nextflow](https://www.nextflow.io/docs/stable/install.html)

## 2. Docker Desktop as the Docker engine

- Only use **Docker Desktop**, versus Rancher Desktop or Podman.

## 3. Apple Silicon image settings

- Optionally set `DOCKER_DEFAULT_PLATFORM=linux/amd64` if you run into missing arm64 images; this forces pulling `linux/amd64` images while still running on your M‑series Mac via emulation. [stackoverflow](https://stackoverflow.com/questions/67010057/how-to-run-docker-on-apple-silicon-m1)
- Prefer native arm64 images where nf-core provides them and only rely on amd64 emulation for tools without ARM builds to keep performance reasonable. [seqera](https://seqera.io/blog/building-containers-for-scientific-workflows/)

## 4. Configure nf-core/rnaseq profiles

- nf-core recommends running with container profiles such as `-profile docker` to pull the `nfcore/rnaseq` images from Docker Hub and manage all tools via containers. [nf-co](https://nf-co.re/rnaseq/latest/docs/usage/)
- On Apple Silicon, include the `arm` profile and run with `-profile docker,arm` so the pipeline uses ARM‑aware settings and ARM‑compatible images where available. [nf-co](https://nf-co.re/rnaseq/3.18.0/docs/usage)

## 5. Run nf-core/rnaseq

- Prepare your samplesheet (CSV), reference FASTA, and GTF, then run a command like:  
  `nextflow run nf-core/rnaseq --input samplesheet.csv --fasta genome.fa --gtf genes.gtf --outdir results -profile docker,arm`. [github](https://github.com/nf-core/rnaseq)
- Monitor the workflow; nf-core/rnaseq will handle alignment, quantification, and QC via containers through Rancher Desktop and write outputs under your `--outdir` directory. [nf-co](https://nf-co.re/rnaseq/3.22.2/)