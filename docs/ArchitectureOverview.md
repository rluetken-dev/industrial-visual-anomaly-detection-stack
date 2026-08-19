# Industrial Visual Anomaly Detection Stack - Architecture Overview

## Purpose

This document describes the technical architecture of the local container stack for the Industrial Visual Anomaly Detection system.

Stable scope and requirements belong in `ProjectSpecification.md`. Operational setup instructions belong in `LocalStackQuickStart.md`, and verified implementation progress belongs in `DevelopmentStatus.md`.

## Architectural Objective

The stack provides a reproducible local runtime for the server-side components of the system:

- the ASP.NET Core backend;
- the Python inference service;
- an externally supplied model artifact.

Docker Compose coordinates these components. The Windows WPF desktop client remains a native host application and communicates with the published backend endpoint.

## System Context

```text
+---------------------------+
| Windows host              |
|                           |
|  WPF desktop application  |
+-------------+-------------+
              |
              | HTTP
              v
+-------------+-------------+
| Docker Compose stack      |
|                           |
|  +---------------------+  |
|  | ASP.NET Core        |  |
|  | backend             |  |
|  +----------+----------+  |
|             | HTTP        |
|             v             |
|  +----------+----------+  |
|  | Python inference    |  |
|  | service             |  |
|  +----------+----------+  |
|             | read-only   |
|             v             |
|  +---------------------+  |
|  | Model artifact      |  |
|  | bind mount          |  |
|  +---------------------+  |
+---------------------------+
```

## Repository Responsibility

The stack repository owns:

- Dockerfiles for the backend and inference service;
- the Docker Compose definition;
- runtime configuration examples;
- local verification scripts;
- stack-specific documentation;
- stack-level CI checks.

It does not own:

- model training or evaluation logic;
- inference API behavior;
- backend application behavior;
- WPF desktop application behavior;
- datasets or model artifacts.

Those responsibilities remain in their respective repositories.

## Component Architecture

### WPF Desktop Application

The desktop application runs directly on Windows and is not part of the Compose deployment.

Responsibilities:

- select and preview an image;
- call the backend analysis endpoint;
- display health and readiness state;
- display anomaly results and the heatmap overlay.

The application communicates only with the ASP.NET Core backend. It does not call the Python service directly and does not read the model artifact.

Initial compatible release:

```text
industrial-visual-anomaly-detection-desktop v0.2.0
```

### ASP.NET Core Backend Container

The backend is the public server-side boundary of the stack.

Responsibilities:

- expose liveness and readiness endpoints;
- accept and validate image uploads;
- call the inference service;
- map inference results into the public analysis contract;
- return anomaly scores, decisions, metadata, trace identifiers, and heatmap data;
- map failures into stable Problem Details responses.

The backend container does not load the model artifact directly.

Initial compatible release:

```text
industrial-visual-anomaly-detection-backend v0.2.0
```

### Python Inference Container

The inference service owns model runtime execution.

Responsibilities:

- load the configured model artifact during startup;
- expose service health endpoints;
- accept image prediction requests from the backend;
- run preprocessing and anomaly inference;
- return the score, threshold, decision metadata, and encoded heatmap.

The inference service is reachable by the backend through the internal Compose network. Its port may be published to the host for diagnostics during local development, but the desktop application must not depend on that port.

Initial compatible release:

```text
industrial-visual-anomaly-detection-model v0.4.0
```

### Model Artifact

The model artifact is supplied outside Git and outside the container image.

It is mounted into the inference container as a read-only bind mount. The mount prevents runtime code from modifying the host artifact and keeps large generated files out of repository history and image layers.

The committed configuration uses the verified Capsule artifact as its portable default:

```text
mvtec-ad-capsule-320
```

The artifact path is configured by the operator. A compatible artifact may instead originate from another category or from the generalized normal-image-directory training workflow introduced in model release `v0.4.0`.

The stack has been verified with both the Capsule reference artifact and `mvtec-ad-bottle-generalized-320`. Model identity, category, threshold, decision, and heatmap data flow through the existing service contracts without category-specific stack configuration.

Only one artifact is mounted into an inference container at a time. Changing the selected artifact requires updating the local configuration and recreating the inference container.

## Build Architecture

Each container image is built from a pinned source revision of its owning repository.

The stack uses configurable build arguments with verified release tags as defaults:

| Component | Default source revision |
| --- | --- |
| Python inference service | `v0.4.0` |
| ASP.NET Core backend | `v0.2.0` |

The source code is retrieved during the image build. It is not copied into the stack repository.

This approach provides:

- reproducible default builds;
- explicit compatibility between components;
- reviewable version upgrades;
- separation between orchestration and application source.

Floating branches such as `main` are not used as release defaults.

## Container Images

### Inference Image

The inference image uses a Python runtime compatible with the pinned model release.

The image build:

1. retrieves the pinned model repository revision;
2. creates an isolated Python virtual environment;
3. installs declared Python dependencies and the project package;
4. downloads the required pretrained ResNet18 backbone weights into a dedicated build cache;
5. copies the virtual environment and backbone cache into the runtime stage;
6. installs only the required native runtime library;
7. runs the FastAPI service through Uvicorn as a non-root user.

Bundling the pretrained backbone weights during the image build allows the inference container to start without internet access.

The model artifact is not copied into the image.

### Backend Image

The backend uses a multi-stage .NET build.

The image build:

1. retrieves the pinned backend repository revision;
2. restores dependencies;
3. publishes the ASP.NET Core project in Release configuration;
4. copies the published output into the smaller ASP.NET Core runtime image;
5. starts the API assembly.

Build tools and source history are not required in the final runtime stage.

## Compose Services

The initial Compose project contains two services:

```text
backend
inference
```

The backend depends on a healthy inference service. Compose health checks prevent dependency ordering from being treated as service readiness.

Container names are not required for service discovery. Compose service names provide stable internal DNS names.

## Network Architecture

Compose creates a dedicated application network.

The backend reaches the inference service through an internal address such as:

```text
http://inference:8000
```

The backend must not use `localhost` for this connection because `localhost` inside the backend container refers to the backend container itself.

The initial host-facing boundaries are:

| Boundary | Purpose |
| --- | --- |
| Backend port | Desktop access and local API diagnostics |
| Inference port | Optional local diagnostics only |

Only ports required for the local workflow should be published.

## Configuration Architecture

Configuration is separated into committed defaults and local operator values.

### Committed Files

- `compose.yml` defines services, networks, mounts, health checks, and defaults;
- `.env.example` documents supported environment variables without secrets;
- Dockerfiles define reproducible component builds.

### Local Files

- `.env` contains machine-specific values and is ignored by Git;
- `runtime-artifacts/` contains or points to local model artifacts and ignores artifact content;
- optional Compose override files remain local unless a stable shared use case is established.

Expected configuration areas include:

- backend host port;
- optional inference host port;
- model artifact host path;
- model artifact container path;
- inference memory chunk size;
- pinned backend source revision;
- pinned inference source revision;
- backend inference-request timeout.

The backend-to-inference address is defined by the Compose topology as `http://inference:8000`; it is not a host-specific operator value.

No secret, credential, private host, dataset path, or personal machine path belongs in committed defaults.

## Artifact Mounting

The artifact directory is mounted into the inference container with read-only access.

Conceptually:

```text
configured host artifact directory
    -> configured container artifact directory:ro
```

The committed default resolves both sides to `mvtec-ad-capsule-320`. A local `.env` may select another compatible directory, including an artifact outside the stack repository.

The inference configuration points to the container path, never to the Windows host path.

The stack validates artifact availability through service startup and health behavior. A missing or incompatible artifact must result in an observable unhealthy or failed service rather than silent fallback behavior.

## Health and Readiness

### Inference Health

The inference health check verifies that its HTTP health endpoint responds successfully.

### Backend Liveness

Backend liveness confirms that the ASP.NET Core process is running.

### Backend Readiness

Backend readiness confirms that the backend can reach a usable inference service.

The expected dependency sequence is:

```text
artifact available
    -> inference starts and becomes healthy
    -> backend starts and becomes ready
    -> desktop analysis is available
```

Health-check timings must allow for initial model loading without hiding persistent startup failures.

## Request Flow

The image-analysis flow is:

1. the user selects an image in the native WPF client;
2. the client submits multipart form data to the backend;
3. the backend validates the upload;
4. the backend forwards the image to `http://inference:8000`;
5. the inference service preprocesses the image and runs the loaded model;
6. the inference service creates and encodes the heatmap;
7. the backend validates and maps the inference response;
8. the desktop displays the decision, metrics, metadata, and heatmap overlay.

Correlation and trace information is propagated where supported so failures can be followed across the desktop, backend, and inference boundaries.

## Failure Behavior

The architecture must expose clear failures for:

- missing model artifacts;
- invalid artifact contents;
- inference startup failure;
- backend startup failure;
- inference health-check failure;
- backend readiness failure;
- invalid image uploads;
- inference timeouts;
- incompatible component contracts.

The stack must not substitute fake predictions or silently start without the configured model.

## Security Boundaries

The initial stack is intended for local portfolio demonstration and development.

Security rules:

- model artifacts are mounted read-only;
- datasets and uploaded images are not committed;
- secrets are not stored in Compose files or images;
- only necessary ports are published;
- containers run with the least practical privileges;
- application logs must not contain image contents or secrets;
- base images and source revisions are explicit and reviewable.

Production authentication, TLS termination, secret management, and network isolation are outside the initial scope.

## Verification Architecture

Stack verification is performed at multiple levels.

### Static Verification

- validate the Compose configuration;
- lint or parse PowerShell scripts;
- check repository whitespace and ignored files;
- verify that required configuration examples exist.

### Image Verification

- build both container images;
- confirm that runtime images start with the expected entry points;
- inspect image build failures independently from runtime failures.

### Runtime Verification

- start the complete Compose project;
- wait for inference health;
- verify backend liveness and readiness;
- submit a known local image when explicitly supplied;
- validate score, decision, metadata, and heatmap response shape;
- stop the stack without leaving containers running.

Automated verification must not require redistribution of MVTec images or model artifacts in Git.

## CI Boundary

Stack CI can validate repository structure, Compose syntax, and container builds that do not require private or large runtime artifacts.

Full prediction verification requires an artifact and test image and therefore remains a documented local workflow unless a legally distributable fixture and artifact strategy is introduced later.

## Deployment Boundary

The initial architecture supports local Docker Desktop execution on Windows with Linux containers and WSL 2.

The following remain deferred:

- hosted deployment;
- container registry publication;
- automatic model artifact download;
- multiple simultaneous model artifacts;
- runtime model or category selection without recreating the inference container;
- GPU-specific images;
- Kubernetes orchestration;
- production TLS and authentication;
- containerized WPF execution.

## Architectural Decision Summary

| Decision | Rationale |
| --- | --- |
| Use a separate stack repository | Preserve independent application repositories and releases |
| Use Docker Compose | Coordinate the two server-side services with a small local setup |
| Keep WPF native | WPF is Windows-specific and does not benefit from Linux containerization |
| Pin source releases | Provide reproducible and reviewable builds |
| Mount artifacts externally | Keep large generated files out of Git and container images |
| Mount artifacts read-only | Protect verified runtime inputs from mutation |
| Route desktop traffic through the backend | Preserve validation, error mapping, and public API ownership |
| Use internal service DNS | Avoid host-specific addresses between containers |
| Use health-based dependencies | Distinguish process order from actual readiness |
| Keep stack integration category-neutral | Allow compatible artifacts to provide their own model identity, category, threshold, decision, and heatmap data |

## Documentation Update Rule

Update this document when component boundaries, service topology, networking, artifact handling, build strategy, or deployment assumptions change. Do not update it for internal implementation details that do not affect the architecture.

## Last Updated

2026-08-19
