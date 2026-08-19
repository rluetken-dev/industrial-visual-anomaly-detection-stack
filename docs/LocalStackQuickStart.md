# Industrial Visual Anomaly Detection Stack - Local Stack Quick Start

## Purpose

This guide explains how to run the containerized Python inference service and ASP.NET Core backend locally and connect the native Windows desktop client.

The stack is intended for local portfolio demonstration and development. It does not download datasets or model artifacts automatically.

## What Runs Where

Docker Compose starts:

- the Python inference service;
- the ASP.NET Core backend.

The WPF desktop client runs natively on Windows outside Docker.

```text
WPF desktop client
    -> ASP.NET Core backend container
        -> Python inference container
            -> read-only model artifact
```

## Compatible Releases

The verified stack configuration targets:

| Component | Release |
| --- | --- |
| Python model and inference service | `v0.4.0` |
| ASP.NET Core backend | `v0.2.0` |
| WPF desktop client | `v0.2.0` |

These versions provide the verified anomaly-analysis and heatmap contract. Model release `v0.4.0` supports both the existing Capsule reference artifact and compatible artifacts trained from user-provided normal-image directories.

## Prerequisites

Install or prepare:

- Windows 11;
- WSL 2;
- Docker Desktop using Linux containers and the WSL 2 backend;
- Git;
- a compatible exported model artifact;
- optionally, the released WPF desktop client or its source repository.

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

## Prepare the Model Artifact

The model artifact is intentionally not stored in this repository or inside the container images.

Obtain or export a compatible artifact by following the model repository documentation:

```text
https://github.com/rluetken-dev/industrial-visual-anomaly-detection-model
```

Model release `v0.4.0` supports:

- the existing MVTec AD Capsule reference artifact;
- artifacts created from other MVTec AD categories;
- compatible artifacts trained from user-provided normal-image directories.

A complete artifact directory must contain at least `metadata.json` and `feature_memory.pt`. Generalized artifacts additionally contain `training_split.json`.

### Option 1 - Copy the Artifact into the Stack Repository

Copy the complete artifact directory below the ignored `runtime-artifacts` directory:

```text
industrial-visual-anomaly-detection-stack/
`-- runtime-artifacts/
    `-- mvtec-ad-capsule-320/
        |-- feature_memory.pt
        `-- metadata.json
```

The committed `.env.example` uses this Capsule location as its portable default:

```dotenv
MODEL_ARTIFACT_HOST_PATH=./runtime-artifacts/mvtec-ad-capsule-320
MODEL_ARTIFACT_CONTAINER_PATH=/runtime-artifacts/mvtec-ad-capsule-320
```

### Option 2 - Reference an Artifact Outside the Stack Repository

A local `.env` may point directly to an artifact exported by a neighboring model repository. For example:

```dotenv
MODEL_ARTIFACT_HOST_PATH=../industrial-visual-anomaly-detection-model/outputs/model-artifacts/mvtec-ad-bottle-generalized-320
MODEL_ARTIFACT_CONTAINER_PATH=/runtime-artifacts/mvtec-ad-bottle-generalized-320
```

Both paths must describe the same artifact:

- `MODEL_ARTIFACT_HOST_PATH` is resolved on the host relative to the stack repository;
- `MODEL_ARTIFACT_CONTAINER_PATH` is the location used inside the inference container.

The artifact is mounted read-only. Changing either artifact path requires recreating the inference container.

Artifact directories are ignored by Git. Do not force-add them.

MVTec datasets are not required merely to start the stack when a compatible exported artifact and a separate test image are already available.

## Create Local Configuration

Copy the committed environment template:

```powershell
Copy-Item .\.env.example .\.env
```

Open `.env` and review the documented values.

The initial configuration covers:

- backend host port;
- optional inference diagnostic port;
- model artifact location;
- inference memory chunk size;
- pinned backend source revision;
- pinned inference source revision.

Do not commit `.env`.

## Validate the Compose Configuration

Run:

```powershell
docker compose config
```

This resolves the environment values and validates the Compose structure without starting containers.

Stop here if Docker reports a missing variable, invalid mount, or invalid Compose configuration.

## Build the Images

```powershell
docker compose build
```

The initial build retrieves the pinned application source revisions and creates the inference and backend runtime images. It can take several minutes and requires internet access.

The model artifact is mounted at runtime and is not copied into either image.

## Start the Stack

```powershell
docker compose up --detach --no-build
```

Inspect service state:

```powershell
docker compose ps
```

The inference service may need additional startup time while loading the artifact. The backend becomes ready only after the inference service is usable.

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

Press `Ctrl+C` to stop following logs. This does not stop containers started with `-d`.

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

If the optional inference diagnostic port is published, verify it directly:

```powershell
curl.exe --max-time 10 -i http://localhost:8000/health/live
```

Backend readiness is the authoritative check for whether the complete server-side workflow is available.

## Verify an Analysis

Supply a local PNG or JPEG image. The image is not added to the repository.

```powershell
$imagePath = "C:\path\to\test-image.png"

curl.exe `
    --max-time 60 `
    -X POST `
    http://localhost:8080/api/v1/analyses `
    -F "image=@$imagePath;type=image/png"
```

The response should contain:

- model identifier and category;
- anomaly score;
- threshold;
- `normal` or `anomalous` decision;
- processing time;
- trace identifier;
- PNG heatmap metadata and Base64 data.

The stack does not provide MVTec test images because dataset redistribution and licensing must remain explicit.

## Run the Verification Script

Verify service health:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1
```

Verify the complete analysis workflow with a local image:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1 `
    -ImagePath "C:\path\to\test-image.png"
```

The script validates backend and inference health and, when an image is supplied, the analysis result and decoded PNG heatmap.

## Run the Desktop Client

Clone or obtain the compatible desktop release separately:

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

The environment variable is removed after the desktop application is closed.

Start the WPF client natively on Windows. The status indicators should report a healthy backend and ready inference service.

Select a PNG or JPEG image and run the analysis. The client should display the decision, score, threshold, metadata, and interactive heatmap overlay.

## Stop the Stack

Return to the stack repository and stop its containers:

```powershell
Set-Location C:\path\to\industrial-visual-anomaly-detection-stack

docker compose down
```

This stops and removes the Compose containers and network. It does not delete the host model artifact or the locally built container images.

## Rebuild After a Version Change

After changing a pinned source revision or Dockerfile:

```powershell
docker compose build --no-cache
docker compose up -d
```

Use the verified default tags again if a newer combination has not yet been confirmed compatible.

## Common Problems

### Docker Command Not Found

Open a new PowerShell window after Docker Desktop installation. Confirm that Docker Desktop reports `Engine running`.

### Docker Engine Is Unavailable

Start Docker Desktop and wait until the engine is running, then retry:

```powershell
docker info
```

### Artifact Path Does Not Exist

Confirm that the complete exported directory exists below `runtime-artifacts` and that `.env` refers to the correct relative path.

### Inference Container Is Unhealthy

Inspect:

```powershell
docker compose logs inference
```

Typical causes include:

- missing artifact files;
- incompatible artifact metadata;
- insufficient available memory;
- invalid artifact mount configuration.

### Backend Is Live but Not Ready

Inspect both services:

```powershell
docker compose ps
docker compose logs backend
docker compose logs inference
```

This usually means that the backend process is running but cannot reach a healthy inference service.

### Desktop Cannot Reach the Backend

Confirm that:

- backend readiness succeeds from the Windows host;
- the desktop base address uses the published host port;
- the desktop does not use the internal Compose hostname `inference`;
- local firewall or proxy settings are not blocking the connection.

### Port Is Already in Use

Change the relevant host port in `.env`, validate the resolved configuration, and restart the stack:

```powershell
docker compose config
docker compose down
docker compose up -d
```

## Local Data Rules

Do not commit:

- `.env`;
- model artifacts;
- MVTec datasets;
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

- the runtime supports one configured model artifact at a time;
- changing the selected artifact requires recreating the inference container;
- simultaneous multi-model hosting and runtime category selection are not implemented;
- artifacts are prepared manually;
- the WPF client is not started by Compose;
- no GPU-specific runtime is provided;
- the stack is intended for local use rather than production deployment.

## Related Documentation

- `ProjectSpecification.md` - scope and acceptance criteria;
- `ArchitectureOverview.md` - component, network, build, and artifact architecture;
- `DevelopmentStatus.md` - verified progress and immediate next steps.

## Last Updated

2026-08-19
