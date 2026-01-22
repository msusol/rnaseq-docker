FROM ghcr.io/nextflow-io/training:latest
#Apple Silicon–tuned image (ARM): e.g. elbamos/rstudio-m1 for M-series Macs.
# https://github.com/elbamos/rstudio-m1 5 years ago
#FROM elbamos/rstudio-m1:latest
#https://github.com/rstudio/rstudio/wiki/M1-Mac-Dev-Machine-Setup
FROM rocker/rstudio:latest

USER root

# Install Java, Nextflow, and Docker
RUN apt-get update && apt-get install -y openjdk-17-jre-headless curl gpg \
    && curl -fsSL https://get.nextflow.io | bash \
    && mv nextflow /usr/local/bin/ && chmod +x /usr/local/bin/nextflow \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y docker-ce-cli

# Install R
# TODO: Once nextflow pipeline runs
#RUN apt-get install -y libharfbuzz-dev libfribidi-dev wget && \
#    chmod -R 777 /usr/local/lib/R/site-library

# Create training directory and set ownership
RUN mkdir -p /home/rstudio/training && \
    chown -R rstudio:rstudio /home/rstudio

USER rstudio

WORKDIR /home/rstudio

#COPY container/install_r_pkgs.sh install_r_pkgs.sh
#RUN /bin/bash install_r_pkgs.sh

# Copy the differential expression analysis script
COPY --chown=rstudio:rstudio container/de_rstudio.R /home/rstudio/de_rstudio.R

# Copy Nextflow training files to /home/rstudio/training
COPY --chown=rstudio:rstudio training/data/           /home/rstudio/training/data/
COPY --chown=rstudio:rstudio training/nextflow.config /home/rstudio/training/nextflow.config
