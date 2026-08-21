# Industrial Visual Anomaly Detection Stack - Development Status

## Purpose

This document records verified implementation progress and the immediate next steps for the local Docker Compose stack.

It is intentionally concise. Stable scope belongs in `ProjectSpecification.md`, technical structure in `ArchitectureOverview.md`, and operating instructions in `LocalStackQuickStart.md`.

## Current Phase

**Phase 3 - Multi-model integration verified locally**

The Python inference service and ASP.NET Core backend can be built, started, connected, verified, and stopped through Docker Compose. The native WPF desktop client has also been verified against the containerized backend.

The stack now mounts a read-only model registry and multiple artifact directories into one inference container. The backend exposes the available catalog, and callers can select a model for each analysis request without recreating the container.

The complete containerized workflow has been verified with Capsule and Cashew requests. The catalog exposed through the backend contained Capsule, Bottle, Candle, and Cashew. Native desktop verification additionally covered all four models.

The multi-model integration currently uses development revisions rather than new published component releases:

| Component | Current integration source | Local image tag |
| --- | --- | --- |
| Python model and inference service | `main` | `multi-model-support` |
| ASP.NET Core backend | `feat/multi-model-support` | `multi-model-support` |

These temporary references must be replaced with immutable release tags after compatible releases are published.

The stack repository was previously published publicly, validated through GitHub Actions, verified from a clean clone, and released as `v0.1.0`. The current multi-model changes are not yet included in a new stack release.

## Verified Environment

- operating system: Windows 11 Pro;
- Windows build: `26200`;
- WSL version: `2.7.10.0`;
- WSL default distribution: Ubuntu using WSL 2;
- Docker Desktop installed with the WSL 2 backend;
- Docker Desktop engine is running;
- Docker CLI: `29.6.1`;
- Docker Compose: `v5.3.0`;
- Docker Engine: `29.6.1`;
- Git: `2.55.0.windows.3`.

## Published Compatibility Baseline

The previously released single-model baseline used:

| Component | Release |
| --- | --- |
| Python model and inference service | `v0.4.0` |
| ASP.NET Core backend | `v0.2.0` |
| WPF desktop client | `v0.2.0` |

Those releases provide the earlier single-model anomaly-analysis and heatmap workflow. They do not represent the complete multi-model integration described in the current working tree.

## Implemented

### Repository Foundation

- separate stack repository created and published publicly;
- repository structure, ignore rules, attributes, and formatting rules established;
- portable `.env.example` and ignored local `.env` workflow established;
- stack documentation set established;
- GitHub Actions workflow implemented and previously verified;
- initial stack release `v0.1.0` published;
- runtime artifacts and machine-specific paths remain outside Git.

### Inference Container

- multi-stage Python 3.12 Dockerfile created;
- model source revision configurable through `INFERENCE_SOURCE_REF`;
- local image tag configurable independently through `INFERENCE_IMAGE_TAG`;
- declared Python dependencies installed in an isolated virtual environment;
- ResNet18 pretrained weights downloaded during image build and copied into the runtime image;
- runtime starts without internet access;
- CPU runtime dependency `libgomp1` installed;
- service runs as an unprivileged user;
- Uvicorn bound to container port `8000`;
- container health check configured;
- inference image built successfully from the registry-capable model source;
- model registry and artifact root mounted read-only;
- registry loaded successfully at startup;
- all enabled artifacts loaded successfully;
- inference container became healthy with four registered models.

### Backend Container

- multi-stage .NET 10 Dockerfile created;
- backend source revision configurable through `BACKEND_SOURCE_REF`;
- local image tag configurable independently through `BACKEND_IMAGE_TAG`;
- API project restored and published in Release configuration;
- final runtime image uses ASP.NET Core rather than the SDK image;
- service runs as the unprivileged .NET `app` user;
- backend bound to container port `8080`;
- liveness health check configured;
- multi-model backend image built successfully;
- backend model-catalog path configured explicitly as `/api/v1/models`;
- backend liveness and readiness verified.

### Docker Compose

- Compose definition configured for `inference` and `backend` services;
- shared bridge network configured;
- backend-to-inference communication configured through Compose DNS at `http://inference:8000`;
- backend dependency configured to wait for healthy inference;
- backend and inference host ports configured through `.env`;
- source revisions and image tags configured independently;
- model artifact root and registry container path configured through `.env`;
- artifact root mounted only into inference and as read-only;
- local-only image pull policy configured to avoid registry lookup;
- resolved Compose configuration validated successfully;
- both multi-model images built successfully through Docker Compose;
- inference container became healthy and backend started successfully;
- backend readiness verified through the internal inference dependency.

### Model Catalog

- registry-based startup verified with `models.json`;
- public backend catalog verified through `GET /api/v1/models`;
- configured default model verified as `mvtec-ad-capsule-320`;
- the following four catalog entries verified through the containerized backend:

```text
mvtec-ad-capsule-320
mvtec-ad-bottle-generalized-320
visa-candle-generalized-q95-320
visa-cashew-generalized-q95-320
```

- model identifiers, display names, categories, input sizes, and default state returned correctly;
- model selection no longer requires changing `.env` or recreating the inference container.

### End-to-End Verification

- inference liveness verified from the Windows host;
- backend liveness verified from the Windows host;
- backend readiness verified from the Windows host;
- complete image analysis verified through the containerized backend;
- explicit Capsule model selection verified;
- explicit Cashew model selection verified;
- returned model identifiers matched the requested identifiers;
- anomaly score, threshold, and decision verified;
- trace identifier verified;
- Base64-encoded PNG heatmaps verified with dimensions `320 x 320`;
- reusable PowerShell verification script extended with optional `ModelId`;
- conditional multipart `modelId` transmission implemented;
- verification script checks that the response model matches the requested model;
- health-only verification remains supported;
- full script executions for Capsule and Cashew succeeded;
- temporary verification response cleanup remains implemented;
- native WPF desktop catalog loading and model selection verified separately with Capsule, Bottle, Candle, and Cashew.

### CI

- GitHub Actions workflow implemented;
- Compose configuration validation included;
- PowerShell syntax validation included;
- inference image build included;
- backend image build included;
- previous single-model workflow completed successfully;
- CI intentionally excludes prediction execution because model artifacts and dataset images are not committed;
- current multi-model changes have not yet been committed and verified through GitHub Actions.

## Current Repository Shape

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

Local `.env`, model registry and artifacts, test images, and generated verification output remain untracked.

## Not Yet Implemented or Verified

- immutable multi-model release tags for the model and backend repositories;
- a released desktop version containing multi-model selection;
- a new stack release containing the multi-model configuration;
- GitHub Actions verification of the current stack changes;
- automated registry and artifact acquisition;
- checksum verification for downloaded runtime artifacts;
- distributable test-image and artifact fixtures;
- dynamic registry reload without recreating the inference container;
- lazy model loading or unloading after startup;
- GPU-specific images;
- hosted deployment;
- production authentication and TLS termination;
- container registry publication;
- Kubernetes orchestration.

## Current Decisions

- The repository orchestrates existing component source revisions instead of duplicating source code.
- The Python inference service and ASP.NET Core backend run as Linux containers.
- The WPF desktop client remains a native Windows application.
- Docker Compose coordinates the server-side services.
- Stable stack defaults should use published immutable tags.
- Development branches may be used temporarily during an explicitly documented integration phase.
- Source revisions and local image tags are configured separately.
- ResNet18 pretrained weights are included in the inference image for offline startup.
- The model registry and exported artifacts remain outside Git and container images.
- The artifact root is mounted read-only into the inference container.
- The local `.env` selects the artifact root, not an individual model artifact.
- The inference registry is authoritative for available and default models.
- Models are selected per analysis request without recreating the container.
- The stack remains category-neutral and obtains model identity, category, threshold, decision, and heatmap data through service contracts.
- The backend reaches the inference service through Compose service DNS.
- The desktop communicates only with the backend host endpoint.
- Dataset images are not redistributed by this repository.
- Full prediction verification remains local until a distributable fixture strategy exists.

## Immediate Next Steps

1. complete and review the stack documentation update;
2. run final Compose, whitespace, and repository-status checks;
3. commit and push the stack multi-model integration;
4. verify the pushed changes through GitHub Actions;
5. publish compatible model, backend, and desktop releases in the appropriate order;
6. replace temporary branch references with immutable release tags;
7. repeat local stack verification using those release tags;
8. publish a new stack release only after the released-component workflow is verified.

## Verification Commands

Validate the resolved Compose configuration:

```powershell
docker compose config --quiet
```

Build both images:

```powershell
docker compose build
```

Start the stack:

```powershell
docker compose up --detach
```

Inspect service state and image assignments:

```powershell
docker compose ps
docker compose images
```

Retrieve the model catalog:

```powershell
Invoke-RestMethod `
    -Uri http://127.0.0.1:8080/api/v1/models `
    -Method Get |
    ConvertTo-Json -Depth 5
```

Run health-only verification:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1
```

Run model-specific verification with a local image:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1 `
    -ImagePath "C:\path\to\test-image.png" `
    -ModelId "mvtec-ad-capsule-320"
```

Stop the stack:

```powershell
docker compose down
```

Check repository whitespace and status:

```powershell
git diff --check
git status --short --untracked-files=all
```

## Verification Rule

Only mark a stack capability as implemented after its configuration has been executed successfully in the documented environment.

Container creation alone is not sufficient verification. Health, dependency communication, registry and artifact loading, catalog behavior, model selection, and the relevant HTTP response must be checked explicitly.

## Documentation Update Rule

Update this document after a verified milestone or meaningful group of changes. Do not update it for every small internal edit.

## Last Updated

2026-08-21
