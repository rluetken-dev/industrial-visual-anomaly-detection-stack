# Industrial Visual Anomaly Detection Stack - Development Status

## Purpose

This document records verified implementation progress and the immediate next steps for the local Docker Compose stack.

It is intentionally concise. Stable scope belongs in `ProjectSpecification.md`, technical structure in `ArchitectureOverview.md`, and operating instructions in `LocalStackQuickStart.md`.

## Current Phase

**Phase 1 - Public stack baseline complete**

The Python inference service and ASP.NET Core backend can be built, started, connected, verified, and stopped through Docker Compose. The native WPF desktop client has also been verified against the containerized backend.

The repository has been published publicly, validated through GitHub Actions, verified from a clean clone, and released as `v0.1.0`.

The initial public stack baseline is complete. Future work can focus on artifact distribution, test fixtures, additional model categories, and deployment options without changing the verified `v0.1.0` baseline.

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

## Compatible Application Releases

The verified stack baseline uses:

| Component | Release |
| --- | --- |
| Python model and inference service | `v0.3.0` |
| ASP.NET Core backend | `v0.2.0` |
| WPF desktop client | `v0.2.0` |

These versions provide the verified anomaly-analysis and heatmap contract used by the complete local workflow.

## Implemented

### Repository Foundation

- separate stack repository created;
- Git repository initialized with the `main` branch;
- repository directory structure created;
- `.gitignore` created for local configuration, artifacts, outputs, logs, editor files, and Compose overrides;
- `.dockerignore` created to keep Git data, documentation, local configuration, generated output, and runtime artifacts out of image build contexts;
- `runtime-artifacts/.gitkeep` added while runtime artifact contents remain ignored;
- `.gitattributes` created with explicit text and binary handling;
- `.editorconfig` created with baseline formatting rules;
- `.env.example` created with portable local defaults;
- local `.env` created and verified as ignored;
- initial documentation set completed;
- commit message guidelines completed;
- initial commit `e4967c2` created with message `chore: initialize stack repository`;
- GitHub repository created and published publicly;
- public repository access verified without authentication;
- README and documentation links verified in the public repository;
- `origin` configured and `main` pushed successfully;
- local and remote `main` branches verified as synchronized;
- working tree verified as clean after publication;
- initial stack release `v0.1.0` published;
- release badge added to the README and verified.

### Inference Container

- multi-stage Python 3.12 Dockerfile created;
- model repository source pinned to release `v0.3.0`;
- declared Python dependencies installed in an isolated virtual environment;
- application package installed from the pinned source revision;
- ResNet18 pretrained weights downloaded during the image build;
- pretrained-weight cache copied into the runtime image;
- runtime no longer requires internet access to start;
- CPU runtime dependency `libgomp1` installed;
- service runs as an unprivileged user;
- Uvicorn bound to container port `8000`;
- container liveness health check configured;
- inference image built successfully;
- offline container startup verified with Docker networking disabled;
- model artifact mounted and loaded successfully;
- model artifact mount verified as read-only;
- inference health verified.

### Backend Container

- multi-stage .NET 10 Dockerfile created;
- backend repository source pinned to release `v0.2.0`;
- API project restored and published in Release configuration;
- final runtime image uses ASP.NET Core rather than the SDK image;
- service runs as the unprivileged .NET `app` user;
- backend bound to container port `8080`;
- liveness health check configured;
- backend image built successfully;
- backend image size and runtime user inspected;
- backend liveness verified.

### Docker Compose

- Compose definition created for `inference` and `backend` services;
- shared bridge network configured;
- backend-to-inference communication configured through Compose DNS at `http://inference:8000`;
- backend dependency configured to wait for healthy inference;
- backend and inference host ports configured through `.env`;
- model artifact path configured through `.env`;
- model artifact mounted only into inference and as read-only;
- local-only image pull policy configured to avoid Docker Hub lookup;
- Compose configuration resolved and validated successfully;
- both images built successfully through `docker compose build`;
- Compose image assignments inspected successfully;
- complete stack startup verified;
- clean stack shutdown and recreation verified;
- both containers verified as healthy after recreation;
- backend readiness verified through the internal inference dependency.

### End-to-End Verification

- inference liveness verified from the Windows host;
- backend liveness verified from the Windows host;
- backend readiness verified from the Windows host;
- complete image analysis verified through the containerized backend;
- capsule model identifier and category verified;
- anomaly score, threshold, and decision verified;
- trace identifier verified;
- Base64-encoded PNG heatmap verified with dimensions `320 x 320`;
- native WPF desktop client verified against backend host port `8080`;
- desktop health state, analysis response, and interactive heatmap overlay verified;
- reusable PowerShell verification script created;
- verification script syntax validated;
- health-only script execution verified;
- full script execution with a local test image verified;
- temporary verification response cleanup implemented in the verification script;
- repository cloned successfully into a separate clean-check directory;
- `.env.example` copied successfully in the clean clone;
- clean-clone Compose configuration validated;
- model artifact copied into the clean clone with matching SHA-256 hashes;
- copied artifact files verified as ignored by Git;
- stack started successfully from the clean clone without rebuilding images;
- clean-clone inference liveness and backend liveness and readiness verified;
- complete anomaly analysis and PNG heatmap verified from the clean clone.

### CI

- GitHub Actions workflow implemented;
- Compose configuration validation included;
- PowerShell syntax validation included;
- inference image build included;
- backend image build included;
- initial GitHub Actions execution completed successfully;
- CI intentionally excludes prediction execution because model artifacts and MVTec images are not committed;
- CI badge rendering verified in the public README.

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

Local `.env`, model artifact contents, test images, and generated verification output remain untracked.

## Not Yet Implemented or Verified

- automated artifact acquisition;
- distributable test image fixture;
- multiple model artifacts;
- dynamic model or category selection;
- GPU-specific images;
- hosted deployment;
- production authentication and TLS termination;
- container registry publication;
- Kubernetes orchestration.

## Current Decisions

- The repository orchestrates existing released components instead of duplicating their source code.
- The Python inference service and ASP.NET Core backend run as Linux containers.
- The WPF desktop client remains a native Windows application.
- Docker Compose coordinates the server-side services.
- Application source revisions are pinned to published tags by default.
- The verified source tags are model `v0.3.0` and backend `v0.2.0`.
- The desktop compatibility baseline is `v0.2.0`.
- ResNet18 pretrained weights are included in the inference image for offline startup.
- The exported model artifact remains outside Git and container images.
- The artifact is mounted read-only into the inference container.
- The backend reaches the inference service through Compose service DNS.
- The desktop communicates only with the backend host endpoint.
- MVTec datasets and test images are not redistributed by this repository.
- Full prediction verification remains local until a distributable fixture strategy exists.

## Immediate Next Steps

1. commit and push the final release-status update;
2. remove the temporary clean-clone directory;
3. evaluate a legally distributable artifact and test-image strategy as a later milestone;
4. consider additional model categories without changing the verified `v0.1.0` baseline.

## Verification Commands

Validate the resolved Compose configuration:

```powershell
docker compose config
```

Build both images:

```powershell
docker compose build
```

Start the stack:

```powershell
docker compose up --detach --no-build
```

Inspect service state and image assignments:

```powershell
docker compose ps
docker compose images
```

Run health-only verification:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1
```

Run complete verification with a local image:

```powershell
powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File .\scripts\verify-local-stack.ps1 `
    -ImagePath "C:\path\to\test-image.png"
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

Container creation alone is not sufficient verification. Health, dependency communication, artifact loading, and the relevant HTTP behavior must be checked explicitly.

## Documentation Update Rule

Update this document after a verified milestone or meaningful group of changes. Do not update it for every small internal edit.

## Last Updated

2026-08-18
