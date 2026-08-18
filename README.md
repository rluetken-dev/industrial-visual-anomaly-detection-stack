# Industrial Visual Anomaly Detection Stack

[![CI](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-stack/actions/workflows/ci.yml/badge.svg)](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-stack/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/rluetken-dev/industrial-visual-anomaly-detection-stack)](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-stack/releases/latest)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Backend](https://img.shields.io/badge/backend-ASP.NET%20Core-512BD4)](https://dotnet.microsoft.com/apps/aspnet)
[![Inference](https://img.shields.io/badge/inference-Python-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/platform-Windows%20%2B%20WSL%202-0078D4)](https://learn.microsoft.com/windows/wsl/)

Docker Compose orchestration for the server-side components of the Industrial Visual Anomaly Detection system.

The stack runs the Python inference service and ASP.NET Core backend together while the WPF desktop client remains a native Windows application.

## Overview

The complete workflow consists of three independently released projects:

- [Industrial Visual Anomaly Detection Model](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-model) - Python model development, artifact export, inference, and heatmap generation;
- [Industrial Visual Anomaly Detection Backend](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-backend) - ASP.NET Core API, validation, health checks, and inference integration;
- [Industrial Visual Anomaly Detection Desktop](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-desktop) - native WPF analysis client with an interactive heatmap overlay.

This repository adds the missing orchestration layer without duplicating application source code.

## Architecture

```text
Native Windows WPF client
    -> ASP.NET Core backend container
        -> Python inference container
            -> read-only model artifact
```

Docker Compose provides:

- reproducible image builds from pinned releases;
- an internal service network;
- health-based startup dependencies;
- portable environment configuration;
- a read-only model artifact mount;
- a single server-side startup and shutdown workflow.

The WPF application is intentionally not containerized because it is a native Windows desktop application.

## Compatible Baseline

| Component | Release |
| --- | --- |
| Python model and inference service | `v0.3.0` |
| ASP.NET Core backend | `v0.2.0` |
| WPF desktop client | `v0.2.0` |

The baseline supports capsule anomaly classification and an encoded PNG heatmap returned through the complete service chain.

## Prerequisites

- Windows 11;
- WSL 2;
- Docker Desktop using Linux containers;
- Git;
- a compatible exported model artifact;
- optionally, the native WPF desktop client.

A Docker Hub account is not required for local use.

## Model Artifact

The model artifact is not included in Git or in the container images.

Prepare the verified artifact according to the [model repository documentation](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-model) and place it under:

```text
runtime-artifacts/mvtec-ad-capsule-320/
```

The directory is mounted read-only into the inference container.

MVTec datasets and test images are not redistributed by this repository.

## Quick Start

After cloning the repository and preparing the artifact:

```powershell
Copy-Item .\.env.example .\.env
docker compose config
docker compose build
docker compose up --detach --no-build
docker compose ps
```

Verify backend readiness:

```powershell
curl.exe --max-time 30 -i http://localhost:8080/health/ready
```

Expected response:

```json
{"status":"ready"}
```

For artifact preparation, configuration, analysis verification, desktop setup, and troubleshooting, see [Local Stack Quick Start](docs/LocalStackQuickStart.md).

## Run an Analysis

```powershell
$imagePath = "C:\path\to\test-image.png"

curl.exe `
    --max-time 60 `
    -X POST `
    http://localhost:8080/api/v1/analyses `
    -F "image=@$imagePath;type=image/png"
```

The response includes:

- model identifier and category;
- anomaly score and threshold;
- normal or anomalous decision;
- processing time and trace identifier;
- Base64-encoded PNG anomaly heatmap.

## Use the Desktop Client

Run the [WPF desktop client](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-desktop) natively on Windows and configure its backend address as:

```text
http://localhost:8080
```

The desktop client displays backend and inference status, the selected image, analysis metadata, and an adjustable heatmap overlay.

## Stop the Stack

```powershell
docker compose down
```

This removes the Compose containers and network without deleting the host model artifact.

## Repository Structure

```text
industrial-visual-anomaly-detection-stack/
|-- .github/
|   `-- workflows/
|       `-- ci.yml
|-- docker/
|   |-- backend/
|   |   `-- Dockerfile
|   `-- inference/
|       `-- Dockerfile
|-- docs/
|   |-- ArchitectureOverview.md
|   |-- DevelopmentStatus.md
|   |-- LocalStackQuickStart.md
|   `-- ProjectSpecification.md
|-- runtime-artifacts/
|   `-- .gitkeep
|-- scripts/
|   `-- verify-local-stack.ps1
|-- .dockerignore
|-- .editorconfig
|-- .env.example
|-- .gitattributes
|-- .gitignore
|-- COMMITS.md
|-- compose.yml
`-- README.md
```

Application source code remains in the three owning repositories and is not copied into this repository.

## Verification

Validate configuration:

```powershell
docker compose config
```

Build images:

```powershell
docker compose build
```

Inspect services and logs:

```powershell
docker compose ps
docker compose logs
```

Check repository whitespace and status:

```powershell
git diff --check
git status --short --untracked-files=all
```

Verify the running stack:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1
```

Verify the complete analysis workflow:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1 `
    -ImagePath "C:\path\to\test-image.png"
```

## Documentation

- [Project Specification](docs/ProjectSpecification.md)
- [Architecture Overview](docs/ArchitectureOverview.md)
- [Development Status](docs/DevelopmentStatus.md)
- [Local Stack Quick Start](docs/LocalStackQuickStart.md)
- [Commit Message Guidelines](COMMITS.md)

## Current Scope

The initial stack targets:

- local Docker Desktop execution;
- one configured capsule model artifact;
- CPU inference;
- a native Windows desktop client;
- development and portfolio demonstration.

Automatic artifact downloads, multiple runtime models, GPU images, hosted deployment, authentication, TLS termination, and Kubernetes remain outside the initial scope.

## License and Data

This repository does not redistribute MVTec datasets, model artifacts, uploaded images, or generated heatmaps.

Review the licenses and usage conditions of all upstream datasets, base images, packages, and application repositories before redistribution or commercial use.
