# Industrial Visual Anomaly Detection Stack - Local Stack Quick Start

## Purpose

This guide explains how to run the containerized Python inference service and ASP.NET Core backend locally with a registry-controlled set of model artifacts and connect the native Windows desktop client.

The stack is intended for local portfolio demonstration and development. It does not download datasets, registries, or model artifacts automatically.

## What Runs Where

Docker Compose starts:

- the Python inference service;
- the ASP.NET Core backend.

The WPF desktop client runs natively on Windows outside Docker.

```text
WPF desktop client
    -> ASP.NET Core backend container
        -> Python inference container
            -> read-only model registry
                -> multiple read-only model artifacts
```

## Integration Baseline

The current multi-model integration is verified against these temporary development references:

| Component | Source reference | Local image tag |
| --- | --- | --- |
| Python model and inference service | `main` | `multi-model-support` |
| ASP.NET Core backend | `feat/multi-model-support` | `multi-model-support` |

Replace these development references with fixed version tags after the coordinated releases.

The verified integration supports:

- runtime model-catalog discovery;
- a configured default model;
- optional explicit `modelId` selection per analysis;
- simultaneous hosting of Capsule, Bottle, VisA Candle, and VisA Cashew artifacts;
- Base64-encoded PNG heatmaps through the complete service chain.

## Prerequisites

Install or prepare:

- Windows 11;
- WSL 2;
- Docker Desktop using Linux containers and the WSL 2 backend;
- Git;
- a compatible model registry and all referenced model artifacts;
- optionally, the native WPF desktop client or its source repository.

A Docker Hub account is not required for the initial local workflow.

## Verify Docker

Open a new PowerShell window after installing Docker Desktop.

Run:

```powershell
docker --version
docker compose version
docker info --format "{{.ServerVersion}}"
```

All three commands must succeed before continuing.

If `docker` is not recognized immediately after installation, close and reopen PowerShell so the updated user `PATH` is loaded.

## Clone the Stack Repository

```powershell
git clone https://github.com/rluetken-dev/industrial-visual-anomaly-detection-stack.git
cd .\industrial-visual-anomaly-detection-stack
```

## Prepare the Model Registry and Artifacts

The model registry and model artifacts are intentionally not stored in this repository or inside the container images.

Obtain or export compatible artifacts by following the model repository documentation:

```text
https://github.com/rluetken-dev/industrial-visual-anomaly-detection-model
```

A complete artifact directory contains at least:

- `metadata.json`;
- `feature_memory.pt`.

Generalized artifacts additionally contain `training_split.json`.

The registry file contains:

- a schema version;
- the default model identifier;
- each model identifier and display name;
- an artifact directory relative to the registry;
- an enabled flag.

### Option 1 - Copy Registry and Artifacts into the Stack Repository

Copy `models.json` and every referenced artifact directory below the ignored `runtime-artifacts` directory:

```text
industrial-visual-anomaly-detection-stack/
`-- runtime-artifacts/
    |-- models.json
    |-- mvtec-ad-capsule-320/
    |   |-- feature_memory.pt
    |   `-- metadata.json
    |-- mvtec-ad-bottle-generalized-320/
    |   |-- feature_memory.pt
    |   |-- metadata.json
    |   `-- training_split.json
    |-- visa-candle-generalized-q95-320/
    |   |-- feature_memory.pt
    |   |-- metadata.json
    |   `-- training_split.json
    `-- visa-cashew-generalized-q95-320/
        |-- feature_memory.pt
        |-- metadata.json
        `-- training_split.json
```

The committed `.env.example` uses this portable configuration:

```dotenv
MODEL_ARTIFACTS_HOST_PATH=./runtime-artifacts
MODEL_ARTIFACTS_CONTAINER_PATH=/runtime-artifacts
MODEL_REGISTRY_CONTAINER_PATH=/runtime-artifacts/models.json
```

### Option 2 - Reference Model Repository Outputs

A local `.env` may point directly to the artifact output directory of a neighboring model repository:

```dotenv
MODEL_ARTIFACTS_HOST_PATH=../industrial-visual-anomaly-detection-model/outputs/model-artifacts
MODEL_ARTIFACTS_CONTAINER_PATH=/runtime-artifacts
MODEL_REGISTRY_CONTAINER_PATH=/runtime-artifacts/models.json
```

The variables have these responsibilities:

- `MODEL_ARTIFACTS_HOST_PATH` is resolved by Docker Compose on the host;
- `MODEL_ARTIFACTS_CONTAINER_PATH` is the read-only parent directory inside the inference container;
- `MODEL_REGISTRY_CONTAINER_PATH` identifies `models.json` inside that mounted directory.

Registry artifact paths are resolved relative to `models.json`. The whole directory is mounted read-only. Changing registry contents or artifact files requires recreating the inference container because enabled models are loaded during startup.

Registry and artifact directories are ignored by Git. Do not force-add them.

MVTec and VisA datasets are not required merely to start the stack when compatible exported artifacts and separate test images are already available.

## Create Local Configuration

Copy the committed environment template:

```powershell
Copy-Item .\.env.example .\.env
```

Open `.env` and review the documented values.

The configuration covers:

- backend and inference host ports;
- model registry and artifact locations;
- inference memory chunk size and request timeout;
- backend and inference Git source references;
- local Docker image tags, which are separate from source references.

The separation allows a source branch such as `feat/multi-model-support` to use a Docker-compatible image tag without `/`.

Do not commit `.env`.

## Validate the Compose Configuration

Run:

```powershell
docker compose config --quiet
```

No output and exit code `0` indicate a valid configuration.

Stop here if Docker reports a missing variable, invalid mount, or invalid Compose configuration.

## Build the Images

```powershell
docker compose build
```

The initial build retrieves the configured application source references and creates the inference and backend runtime images. It can take several minutes and requires internet access.

The registry and model artifacts are mounted at runtime and are not copied into either image.

## Start the Stack

```powershell
docker compose up --detach --no-build
```

Inspect service state:

```powershell
docker compose ps
```

The inference service loads all enabled model artifacts during startup. Startup duration and memory consumption increase with the number and size of enabled artifacts. The backend starts only after the inference service reports healthy.

## Inspect Startup Logs

Show logs from both services:

```powershell
docker compose logs
```

Follow logs continuously when diagnosing startup:

```powershell
docker compose logs --follow
```

Show one service only:

```powershell
docker compose logs inference
docker compose logs backend
```

Press `Ctrl+C` to stop following logs. This does not stop containers started with `--detach`.

## Verify Service Health

The exact host ports come from `.env`.

Verify backend liveness:

```powershell
curl.exe --max-time 10 -i http://localhost:8080/health/live
```

Verify backend readiness:

```powershell
curl.exe --max-time 30 -i http://localhost:8080/health/ready
```

Expected readiness result:

```json
{"status":"ready"}
```

If the inference diagnostic port is published, verify it directly:

```powershell
curl.exe --max-time 10 -i http://localhost:8000/health/live
```

Backend readiness is the authoritative check for whether the complete server-side workflow is available.

## Verify the Model Catalog

Query the public backend endpoint:

```powershell
Invoke-RestMethod `
    -Uri http://localhost:8080/api/v1/models `
    -Method Get |
    ConvertTo-Json -Depth 5
```

The response contains:

- `defaultModelId`;
- the ordered enabled model list;
- display name and category for each model;
- input size;
- default-model marker.

The verified four-model registry returns:

- `mvtec-ad-capsule-320`;
- `mvtec-ad-bottle-generalized-320`;
- `visa-candle-generalized-q95-320`;
- `visa-cashew-generalized-q95-320`.

## Verify an Analysis

Supply a local PNG or JPEG image and a model identifier from the catalog. The image is not added to the repository.

Windows PowerShell 5.1 does not support `Invoke-RestMethod -Form`, so use `curl.exe`:

```powershell
$imagePath = "C:\path\to\test-image.png"

curl.exe `
    --max-time 60 `
    --silent `
    --show-error `
    --fail-with-body `
    --request POST `
    --form "image=@$imagePath;type=image/png" `
    --form "modelId=mvtec-ad-capsule-320" `
    http://localhost:8080/api/v1/analyses
```

Omit the `modelId` form field to use the registry default model.

The response contains:

- selected model identifier and category;
- anomaly score;
- threshold;
- `normal` or `anomalous` decision;
- processing time;
- trace identifier;
- PNG heatmap metadata and Base64 data.

The stack does not provide MVTec or VisA test images because dataset redistribution and licensing must remain explicit.

## Run the Verification Script

Verify service health:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1
```

Verify the complete analysis workflow and selected model:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1 `
    -ImagePath "C:\path\to\test-image.png" `
    -ModelId "mvtec-ad-capsule-320"
```

The temporary `-ExecutionPolicy Bypass` applies only to this PowerShell process and does not change the system-wide policy.

The script validates:

- inference liveness;
- backend liveness and readiness;
- successful analysis response;
- requested model identifier;
- category and supported decision;
- PNG heatmap metadata;
- valid, non-empty Base64 heatmap data.

## Run the Desktop Client

Clone or obtain the compatible desktop client separately:

```text
https://github.com/rluetken-dev/industrial-visual-anomaly-detection-desktop
```

Configure its backend base address to the published stack endpoint:

```text
http://localhost:8080
```

Open a separate PowerShell window, switch to the desktop repository, and start the client with a temporary configuration override:

```powershell
Set-Location C:\path\to\industrial-visual-anomaly-detection-desktop

$env:Backend__BaseAddress = "http://127.0.0.1:8080"

dotnet run `
    --project .\src\IndustrialVisualAnomalyDetection.Desktop\IndustrialVisualAnomalyDetection.Desktop.csproj `
    --configuration Release

Remove-Item Env:\Backend__BaseAddress
```

The environment variable is removed after the desktop application closes.

The desktop client should:

- report a healthy backend and ready inference service;
- load the enabled model catalog;
- preselect the registry default model;
- allow model selection through the combobox;
- send the selected model identifier with each analysis;
- display decision, score, threshold, model metadata, and interactive heatmap overlay.

## Stop the Stack

Return to the stack repository and stop its containers:

```powershell
Set-Location C:\path\to\industrial-visual-anomaly-detection-stack

docker compose down
```

This stops and removes the Compose containers and network. It does not delete the host registry, model artifacts, or locally built container images.

## Rebuild After a Source or Registry Change

After changing a source reference or Dockerfile:

```powershell
docker compose build
docker compose up --detach
```

After changing only registry contents or artifacts:

```powershell
docker compose up --detach --force-recreate inference
docker compose up --detach backend
```

Use fixed release tags after the coordinated releases have been verified.

## Common Problems

### Docker Command Not Found

Open a new PowerShell window after Docker Desktop installation. Confirm that Docker Desktop reports `Engine running`.

### Docker Engine Is Unavailable

Start Docker Desktop and wait until the engine is running, then retry:

```powershell
docker info
```

### Registry or Artifact Path Does Not Exist

Confirm that:

- `MODEL_ARTIFACTS_HOST_PATH` points to the parent directory containing `models.json`;
- `MODEL_REGISTRY_CONTAINER_PATH` points to the registry inside the mounted container directory;
- every enabled `artifactDirectory` exists relative to `models.json`;
- every artifact contains `metadata.json` and `feature_memory.pt`.

### Inference Service Requires `IVAD_MODEL_ARTIFACT`

The configured inference source is too old and does not support registry mode. Use a source reference containing the configurable model-registry implementation, rebuild the inference image, and recreate the container.

### Inference Container Is Unhealthy

Inspect:

```powershell
docker compose logs inference
```

Typical causes include:

- missing registry or artifact files;
- invalid registry JSON;
- a duplicate or missing model identifier;
- an invalid default-model reference;
- incompatible artifact metadata;
- insufficient available memory;
- invalid read-only mount configuration.

### Backend Is Live but Not Ready

Inspect both services:

```powershell
docker compose ps
docker compose logs backend
docker compose logs inference
```

This usually means that the backend process is running but cannot reach a healthy inference service.

### Model Catalog Returns Service Unavailable

Check the backend and inference logs and query the inference catalog directly:

```powershell
Invoke-RestMethod `
    -Uri http://localhost:8000/api/v1/models `
    -Method Get |
    ConvertTo-Json -Depth 5
```

### Desktop Cannot Reach the Backend

Confirm that:

- backend readiness succeeds from the Windows host;
- the desktop base address uses the published host port;
- the desktop does not use the internal Compose hostname `inference`;
- local firewall or proxy settings are not blocking the connection.

### Port Is Already in Use

Stop native model or backend processes that use the same ports, or change the relevant host port in `.env`. Then validate and restart:

```powershell
docker compose config --quiet
docker compose down
docker compose up --detach
```

## Local Data Rules

Do not commit:

- `.env`;
- model registries and artifacts;
- MVTec or VisA datasets;
- uploaded or test images;
- generated heatmaps;
- logs;
- generated verification output.

Before committing stack changes, run:

```powershell
git status --short --untracked-files=all
git diff --check
```

## Current Limitations

- registries and artifacts are prepared manually;
- changing registry contents requires recreating the inference container;
- every enabled model is loaded during startup and consumes memory;
- the WPF client is not started by Compose;
- free-form artifact upload from the desktop is outside the MVP;
- no GPU-specific runtime is provided;
- the stack is intended for local use rather than production deployment.

## Related Documentation

- `ProjectSpecification.md` - scope and acceptance criteria;
- `ArchitectureOverview.md` - component, network, build, registry, and artifact architecture;
- `DevelopmentStatus.md` - verified progress and immediate next steps.

## Last Updated

2026-08-21
