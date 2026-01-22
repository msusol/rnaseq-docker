# Apple Silicon Support Implementation Plan

## Objective
Modify rnaseq-docker/container to build and run natively on Apple Silicon Macs (M3 Pro/M4 Max - ARM64 architecture) with full nf-core/rnaseq pipeline compatibility.

## Current State Analysis
- `.clinerules/01-install-rnaseq-for-silicon-macs.md` provides guidance for running nf-core/rnaseq on Apple Silicon
- `build_command.sh` currently builds for `linux/amd64` platform only
- `docker-compose.yml` already configured for ARM64 (`platform: linux/arm64`, `image: rnaseq-docker-rstudio:arm64`)
- `Dockerfile` uses `rocker/rstudio:latest` which supports ARM64
- README.md has extensive documentation but missing Apple Silicon setup basics

## Required Changes

### 1. Docker Build Configuration Updates
**File:** `rnaseq-docker/container/build_command.sh`
- [x] Change `--platform linux/amd64` to `--platform linux/arm64`
- [x] Update image tags from `:amd64` to `:arm64` (keep `:latest` pointing to ARM64)
- [x] Update description label from "AMD64 RStudio Server" to "ARM64 RStudio Server"

### 2. Documentation Updates
**File:** `rnaseq-docker/README.md`
- [x] Add "Apple Silicon Setup" section with basics from `01-install-rnaseq-for-silicon-macs.md`
- [x] Include Java/Nextflow installation instructions (no Homebrew)
- [x] Add Rancher Desktop configuration steps
- [x] Document ARM profile usage for pipelines
- [x] Add test workflow command: `nextflow run nf-core/rnaseq -r 3.12.0 -profile docker,arm,test --outdir results_test -resume`
- [x] Update all pipeline commands to use `arm` profile for Apple Silicon

### 3. Verification Steps
- [x] Confirm `docker-compose.yml` specifies `platform: linux/arm64` ✓ (Already done)
- [x] Verify Dockerfile components are ARM64 compatible ✓ (rocker/rstudio supports ARM64)
- [x] Test ARM64 image build with `docker buildx build --platform linux/arm64` ✓ (Build successful)
- [x] Test container startup and RStudio access on Apple Silicon Mac ✓ (Container running on port 8787)
- [ ] Run test pipeline with ARM profile to verify nf-core/rnaseq compatibility

## Expected Outcomes
- ✅ Native ARM64 container builds successfully
- ✅ RStudio Server runs on Apple Silicon without emulation
- nf-core/rnaseq pipeline executes with `docker,arm` profiles
- All bioinformatics R packages function correctly on ARM64
- Improved performance compared to x86_64 emulation

## Risk Assessment
- **Low risk**: rocker/rstudio and nf-core containers have ARM64 support
- **Low risk**: R packages should be cross-platform compatible
- **Medium risk**: Rancher Desktop may need specific configuration for ARM64

## Implementation Order
1. ✅ Update `build_command.sh` (highest priority - enables ARM64 builds)
2. ✅ Update `README.md` (documentation for users)
3. ✅ Test build and functionality (validation)

## Success Criteria
- [x] `docker-compose up -d` starts ARM64 container successfully ✓
- [x] RStudio accessible at `http://localhost:8787` on Apple Silicon Mac ✓
- [ ] Test pipeline runs: `nextflow run nf-core/rnaseq -r 3.12.0 -profile docker,arm,test --outdir results_test -resume`
- [x] No segmentation faults or architecture compatibility errors ✓

## Timeline
- Implementation: ~30 minutes
- Testing: ~15 minutes (build time) + ~10 minutes (pipeline test)
- Total: ~55 minutes

## Dependencies
- Docker Desktop or Rancher Desktop with ARM64 support
- Apple Silicon Mac (M3 Pro/M4 Max)
- Internet connection for container pulls and package installs
