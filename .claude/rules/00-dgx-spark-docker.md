# Native NVIDIA DGX Spark Docker Infrastructure Requirement

To ensure compatibility and performance on our native NVIDIA DGX Spark infrastructure, all containerized environments
must utilize native Docker.

```bash
$ docker --version
Docker version 29.1.3, build f52814d
$ docker info | grep -i runtime
 Runtimes: io.containerd.runc.v2 nvidia runc
 Default Runtime: runc
```

- **Strictly prohibit the use of `snap` for Docker installation.**
- Always rely on official NVIDIA Docker runtime configurations.
- Ensure all pipelines and development environments are tested against the DGX native Docker architecture.

docker run --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi

Ref: [NVIDIA Container Runtime for Docker](https://docs.nvidia.com/dgx/dgx-spark/nvidia-container-runtime-for-docker.html)
