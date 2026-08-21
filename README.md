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

The complete workflow consists of three independently maintained application projects:

- [Industrial Visual Anomaly Detection Model](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-model) - Python model development, artifact export, registry-based inference, and heatmap generation;
- [Industrial Visual Anomaly Detection Backend](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-backend) - ASP.NET Core API, validation, model-catalog forwarding, health checks, and inference integration;
- [Industrial Visual Anomaly Detection Desktop](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-desktop) - native WPF analysis client with dynamic model selection and an interactive heatmap overlay.

This repository adds the orchestration layer without duplicating application source code.

## Architecture

```text
Native Windows WPF client
    -> ASP.NET Core backend container
        -> Python inference container
            -> read-only model registry
                -> multiple read-only model artifacts
```

Docker Compose provides:

- reproducible image builds from configurable Git references;
- separate source references and local image tags;
- an internal service network;
- health-based startup dependencies;
- portable environment configuration;
- one read-only mount containing the registry and its model artifacts;
- a single server-side startup and shutdown workflow.

The WPF application is intentionally not containerized because it is a native Windows desktop application.

## Integration Baseline

The current multi-model integration is verified against these development references:

| Component | Source reference | Local image tag |
| --- | --- | --- |
| Python model and inference service | `main` | `multi-model-support` |
| ASP.NET Core backend | `feat/multi-model-support` | `multi-model-support` |

These development references are temporary. Replace them with fixed release versions after the coordinated model, backend, desktop, and stack releases.

The verified integration supports:

- a runtime model catalog;
- an explicit optional `modelId` per analysis request;
- a configured default model when `modelId` is omitted;
- Base64-encoded PNG heatmaps;
- simultaneous hosting of Capsule, Bottle, VisA Candle, and VisA Cashew artifacts.

## Prerequisites

- Windows 11;
- WSL 2;
- Docker Desktop using Linux containers;
- Git;
- a compatible model registry and its referenced model artifacts;
- optionally, the native WPF desktop client.

A Docker Hub account is not required for local use.

## Model Registry and Artifacts

Model registries, model artifacts, datasets, and test images are not included in Git or in the container images.

Prepare compatible artifacts according to the [model repository documentation](https://github.com/rluetken-dev/industrial-visual-anomaly-detection-model). Place the registry and all referenced artifact directories below one host directory:

```text
runtime-artifacts/
|-- models.json
|-- mvtec-ad-capsule-320/
|-- mvtec-ad-bottle-generalized-320/
|-- visa-candle-generalized-q95-320/
`-- visa-cashew-generalized-q95-320/
```

Example `models.json`:

```json
{
  "schemaVersion": 1,
  "defaultModelId": "mvtec-ad-capsule-320",
  "models": [
    {
      "id": "mvtec-ad-capsule-320",
      "displayName": "MVTec AD - Capsule",
      "artifactDirectory": "mvtec-ad-capsule-320",
      "enabled": true
    },
    {
      "id": "mvtec-ad-bottle-generalized-320",
      "displayName": "MVTec AD - Bottle",
      "artifactDirectory": "mvtec-ad-bottle-generalized-320",
      "enabled": true
    },
    {
      "id": "visa-candle-generalized-q95-320",
      "displayName": "VisA - Candle",
      "artifactDirectory": "visa-candle-generalized-q95-320",
      "enabled": true
    },
    {
      "id": "visa-cashew-generalized-q95-320",
      "displayName": "VisA - Cashew",
      "artifactDirectory": "visa-cashew-generalized-q95-320",
      "enabled": true
    }
  ]
}
```

The committed `.env.example` uses this portable host directory:

```dotenv
MODEL_ARTIFACTS_HOST_PATH=./runtime-artifacts
MODEL_ARTIFACTS_CONTAINER_PATH=/runtime-artifacts
MODEL_REGISTRY_CONTAINER_PATH=/runtime-artifacts/models.json
```

A local ignored `.env` may instead reference the output directory of a neighboring model repository:

```dotenv
MODEL_ARTIFACTS_HOST_PATH=../industrial-visual-anomaly-detection-model/outputs/model-artifacts
MODEL_ARTIFACTS_CONTAINER_PATH=/runtime-artifacts
MODEL_REGISTRY_CONTAINER_PATH=/runtime-artifacts/models.json
```

The entire host directory is mounted read-only. Registry artifact paths are resolved relative to `models.json`. Changing the registry or its artifacts requires recreating the inference container so all enabled models are loaded during startup.

Loading additional models increases inference-container startup time and memory usage. Each current feature-memory artifact is approximately 410 MiB before runtime overhead.

MVTec and VisA datasets are not redistributed by this repository.

## Quick Start

After cloning the repository and preparing the registry and artifacts:

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

Verify the public model catalog:

```powershell
Invoke-RestMethod `
    -Uri http://localhost:8080/api/v1/models `
    -Method Get |
    ConvertTo-Json -Depth 5
```

For artifact preparation, configuration, analysis verification, desktop setup, and troubleshooting, see [Local Stack Quick Start](docs/LocalStackQuickStart.md).

## Run an Analysis

Select one model identifier from `GET /api/v1/models` and send it as an optional multipart field:

```powershell
$imagePath = "C:\path\to\test-image.png"

curl.exe `
    --max-time 60 `
    --fail-with-body `
    --request POST `
    --form "image=@$imagePath;type=image/png" `
    --form "modelId=mvtec-ad-capsule-320" `
    http://localhost:8080/api/v1/analyses
```

When `modelId` is omitted, the inference service uses the registry default model.

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

The desktop client:

- loads the model catalog dynamically from the backend;
- preselects the configured default model;
- allows the user to select any enabled model;
- sends the selected model identifier with the image;
- displays backend and inference status, analysis metadata, and an adjustable heatmap overlay.

## Stop the Stack

```powershell
docker compose down
```

This removes the Compose containers and network without deleting the host registry or model artifacts.

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
docker compose config --quiet
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

Verify health and readiness without an analysis image:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1
```

Verify the complete analysis workflow and requested model selection:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1 `
    -ImagePath "C:\path\to\test-image.png" `
    -ModelId "mvtec-ad-capsule-320"
```

The script fails if the backend returns a different model identifier, an unsupported decision, invalid heatmap metadata, invalid Base64 heatmap data, or an unsuccessful HTTP response.

The registry catalog and complete analysis workflow have been verified through Docker Compose with explicit Capsule and VisA Cashew model selections. Bottle and VisA Candle were additionally verified through the same runtime registry during native integration testing.

## Documentation

- [Project Specification](docs/ProjectSpecification.md)
- [Architecture Overview](docs/ArchitectureOverview.md)
- [Development Status](docs/DevelopmentStatus.md)
- [Local Stack Quick Start](docs/LocalStackQuickStart.md)
- [Commit Message Guidelines](COMMITS.md)

## Current Scope

The current stack targets:

- local Docker Desktop execution;
- a registry-controlled set of simultaneously loaded model artifacts;
- dynamic model-catalog discovery through the backend;
- optional explicit model selection per analysis;
- a configured default model when no model identifier is supplied;
- category-neutral backend and inference integration;
- CPU inference;
- a native Windows desktop client;
- development and portfolio demonstration.

The registry and all enabled artifacts are selected through the local `.env` file and mounted read-only. Free-form artifact upload from the desktop is intentionally outside the MVP.

Automatic artifact downloads, GPU images, hosted deployment, authentication, TLS termination, container registry publication, and Kubernetes remain outside the current scope.

## License and Data

This repository does not redistribute MVTec or VisA datasets, model registries, model artifacts, uploaded images, or generated heatmaps.

Review the licenses and usage conditions of all upstream datasets, base images, packages, and application repositories before redistribution or commercial use.
