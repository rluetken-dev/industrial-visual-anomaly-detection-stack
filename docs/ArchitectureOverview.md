# Industrial Visual Anomaly Detection Stack - Architecture Overview

## Purpose

This document describes the technical architecture of the local container stack for the Industrial Visual Anomaly Detection system.

Stable scope and requirements belong in `ProjectSpecification.md`. Operational setup instructions belong in `LocalStackQuickStart.md`, and verified implementation progress belongs in `DevelopmentStatus.md`.

## Architectural Objective

The stack provides a reproducible local runtime for the server-side components of the system:

- the ASP.NET Core backend;
- the Python inference service;
- an externally supplied registry of model artifacts.

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
|  | Model registry and  |  |
|  | artifact directories|  |
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
- datasets, the model registry, or model artifacts.

Those responsibilities remain in their respective repositories or local runtime storage.

## Component Architecture

### WPF Desktop Application

The desktop application runs directly on Windows and is not part of the Compose deployment.

Responsibilities:

- retrieve the available model catalog from the backend;
- select an inference model;
- select and preview an image;
- call the backend analysis endpoint with the selected model identifier;
- display health and readiness state;
- display anomaly results and the heatmap overlay.

The application communicates only with the ASP.NET Core backend. It does not call the Python service directly and does not read the model registry or artifacts.

The multi-model desktop implementation is currently consumed from its development branch until a compatible release is published.

### ASP.NET Core Backend Container

The backend is the public server-side boundary of the stack.

Responsibilities:

- expose liveness and readiness endpoints;
- expose the inference model catalog through `GET /api/v1/models`;
- accept and validate image uploads and optional model identifiers;
- call the inference service;
- map inference results into the public analysis contract;
- return anomaly scores, decisions, metadata, trace identifiers, and heatmap data;
- map failures into stable Problem Details responses.

The backend container does not load the model registry or artifacts directly. The multi-model backend implementation is currently built from `feat/multi-model-support` until a compatible release is published.

### Python Inference Container

The inference service owns model discovery and runtime execution.

Responsibilities:

- load and validate the configured model registry during startup;
- load the enabled model artifacts referenced by that registry;
- identify the configured default model;
- expose service health and model-catalog endpoints;
- accept image prediction requests with an optional model identifier;
- run preprocessing and anomaly inference with the selected model;
- return model metadata, score, threshold, decision, and encoded heatmap.

The inference service is reachable by the backend through the internal Compose network. Its port may be published to the host for diagnostics during local development, but the desktop application must not depend on that port.

The registry-capable inference implementation is currently built from `main` until a compatible release is published.

### Model Registry and Artifacts

The model registry and artifacts are supplied outside the stack repository and outside the container image.

The registry is a JSON document that identifies:

- the registry schema version;
- the default model identifier;
- the available models;
- each model's display name;
- each model's artifact directory;
- whether each entry is enabled.

The artifact root is mounted into the inference container as a read-only bind mount. It contains `models.json` and the artifact directory referenced by every enabled registry entry.

The verified local registry currently contains:

```text
mvtec-ad-capsule-320
mvtec-ad-bottle-generalized-320
visa-candle-generalized-q95-320
visa-cashew-generalized-q95-320
```

`mvtec-ad-capsule-320` is the configured default. The client may select another enabled model for each analysis request without recreating the inference container.

## Build Architecture

Each container image is built from a configurable source revision of its owning repository. Source revisions and local image tags are configured separately:

| Component | Current source revision | Current local image tag |
| --- | --- | --- |
| Python inference service | `main` | `multi-model-support` |
| ASP.NET Core backend | `feat/multi-model-support` | `multi-model-support` |

These branch references are temporary integration values. They must be replaced with immutable release tags after compatible multi-model releases are published.

The source code is retrieved during the image build. It is not copied into the stack repository.

Separating source revisions from image tags provides:

- explicit control over the code being built;
- predictable local image names;
- reviewable compatibility updates;
- separation between orchestration and application source.

Published release tags should be used for stable defaults. Floating branches are appropriate only during an explicitly documented integration phase.

## Container Images

### Inference Image

The inference image uses a Python runtime compatible with the selected model source revision.

The image build:

1. retrieves the configured model repository revision;
2. creates an isolated Python virtual environment;
3. installs declared Python dependencies and the project package;
4. downloads the required pretrained ResNet18 backbone weights into a dedicated build cache;
5. copies the virtual environment and backbone cache into the runtime stage;
6. installs only the required native runtime library;
7. runs the FastAPI service through Uvicorn as a non-root user.

Bundling the pretrained backbone weights during the image build allows the inference container to start without internet access. The registry and model artifacts are not copied into the image.

### Backend Image

The backend uses a multi-stage .NET build.

The image build:

1. retrieves the configured backend repository revision;
2. restores dependencies;
3. publishes the ASP.NET Core project in Release configuration;
4. copies the published output into the smaller ASP.NET Core runtime image;
5. starts the API assembly.

Build tools and source history are not required in the final runtime stage.

## Compose Services

The Compose project contains two services:

```text
backend
inference
```

The backend depends on a healthy inference service. Compose health checks prevent dependency ordering from being treated as service readiness.

Container names are not required for service discovery. Compose service names provide stable internal DNS names.

## Network Architecture

Compose creates a dedicated application network.

The backend reaches the inference service through:

```text
http://inference:8000
```

The backend must not use `localhost` for this connection because `localhost` inside the backend container refers to the backend container itself.

The host-facing boundaries are:

| Boundary | Purpose |
| --- | --- |
| Backend port | Desktop access and local API diagnostics |
| Inference port | Optional local diagnostics only |

Only ports required for the local workflow should be published.

## Configuration Architecture

Configuration is separated into committed examples and local operator values.

### Committed Files

- `compose.yml` defines services, networks, mounts, health checks, and configuration wiring;
- `.env.example` documents supported environment variables without secrets or personal paths;
- Dockerfiles define reproducible component builds.

### Local Files

- `.env` contains machine-specific values and is ignored by Git;
- the configured artifact root contains the model registry and artifact directories;
- optional Compose override files remain local unless a stable shared use case is established.

Expected configuration areas include:

- backend and inference source revisions;
- backend and inference image tags;
- backend host port;
- optional inference host port;
- model-artifact host and container paths;
- model-registry container path;
- inference memory chunk size;
- backend inference-request timeout.

The backend-to-inference address is defined by the Compose topology as `http://inference:8000`; it is not a host-specific operator value.

No secret, credential, private host, dataset path, or personal machine path belongs in committed defaults.

## Registry and Artifact Mounting

The artifact root is mounted into the inference container with read-only access.

Conceptually:

```text
configured host artifact root
    -> configured container artifact root:ro
       +-- models.json
       +-- mvtec-ad-capsule-320/
       +-- mvtec-ad-bottle-generalized-320/
       +-- visa-candle-generalized-q95-320/
       +-- visa-cashew-generalized-q95-320/
```

The inference configuration points to the registry path inside the container, never to the Windows host path. Registry entries resolve their artifact directories relative to the mounted artifact root.

The stack validates registry and artifact availability through inference startup and health behavior. A missing registry, invalid entry, or incompatible artifact must result in an observable failed or unhealthy service rather than silent fallback behavior.

## Health and Readiness

### Inference Health

The inference health check verifies that the service has completed startup and its HTTP health endpoint responds successfully. Successful startup implies that the configured registry and enabled artifacts were accepted.

### Backend Liveness

Backend liveness confirms that the ASP.NET Core process is running.

### Backend Readiness

Backend readiness confirms that the backend can reach a usable inference service.

The expected dependency sequence is:

```text
registry and artifacts available
    -> inference loads the catalog and becomes healthy
    -> backend starts and becomes ready
    -> desktop retrieves the catalog
    -> model-specific analysis is available
```

Health-check timings must allow for initial loading of all enabled models without hiding persistent startup failures.

## Catalog Flow

The model-catalog flow is:

1. the inference service reads `models.json` and loads the enabled artifacts during startup;
2. the inference service exposes its validated catalog;
3. the backend retrieves and maps that catalog through its inference client;
4. the backend exposes the public catalog through `GET /api/v1/models`;
5. the desktop retrieves the public catalog and selects its default model;
6. the user may choose another available model.

The inference registry remains the authoritative source for model availability. The stack, backend, and desktop do not maintain separate hard-coded model lists.

## Request Flow

The image-analysis flow is:

1. the user selects a model and image in the native WPF client;
2. the client submits multipart form data containing the image and selected `modelId` to the backend;
3. the backend validates the upload and model identifier;
4. the backend forwards both values to `http://inference:8000`;
5. the inference service resolves the requested model from its loaded catalog;
6. the inference service preprocesses the image and runs the selected model;
7. the inference service creates and encodes the heatmap;
8. the backend validates and maps the inference response;
9. the desktop displays the decision, metrics, model metadata, and heatmap overlay.

If no model identifier is supplied by a compatible client, the inference service uses the registry default where supported by the application contracts.

Correlation and trace information is propagated where supported so failures can be followed across the desktop, backend, and inference boundaries.

## Failure Behavior

The architecture must expose clear failures for:

- a missing or invalid model registry;
- missing or invalid model artifacts;
- an unknown or disabled model identifier;
- inference startup failure;
- backend startup failure;
- inference health-check failure;
- backend readiness failure;
- invalid image uploads;
- inference timeouts;
- incompatible component contracts.

The stack must not substitute fake predictions, silently omit enabled models, or silently start without the configured registry and artifacts.

## Security Boundaries

The stack is intended for local portfolio demonstration and development.

Security rules:

- the registry and model artifacts are mounted read-only;
- datasets and uploaded images are not committed;
- secrets are not stored in Compose files or images;
- only necessary ports are published;
- containers run with the least practical privileges;
- application logs must not contain image contents or secrets;
- base images and source revisions are explicit and reviewable.

Production authentication, TLS termination, secret management, and network isolation are outside the current scope.

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
- retrieve the public model catalog;
- submit a known local image and model identifier when explicitly supplied;
- verify that the returned model identifier matches the requested identifier;
- validate score, decision, metadata, and heatmap response shape;
- stop the stack without leaving containers running.

The verified runtime workflow has exercised multiple registry entries, including Capsule and Cashew, through the containerized backend and inference services.

Automated verification must not require redistribution of dataset images or model artifacts in Git.

## CI Boundary

Stack CI can validate repository structure, Compose syntax, and container builds that do not require private or large runtime artifacts.

Full catalog and prediction verification requires a registry, artifacts, and a test image and therefore remains a documented local workflow unless legally distributable fixtures and artifacts are introduced later.

## Deployment Boundary

The architecture supports local Docker Desktop execution on Windows with Linux containers and WSL 2.

The following remain deferred:

- hosted deployment;
- container registry publication;
- automatic model-registry or artifact download;
- dynamic registry modification without recreating the inference container;
- lazy loading or unloading of models after startup;
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
| Configure source revisions and image tags separately | Keep build inputs explicit while allowing predictable local image naming |
| Use published tags for stable defaults | Provide reproducible and reviewable builds |
| Mount the registry and artifacts externally | Keep large generated files out of Git and container images |
| Mount runtime artifacts read-only | Protect verified runtime inputs from mutation |
| Make the inference registry authoritative | Avoid duplicated, hard-coded model lists in other components |
| Route desktop traffic through the backend | Preserve validation, error mapping, and public API ownership |
| Use internal service DNS | Avoid host-specific addresses between containers |
| Use health-based dependencies | Distinguish process order from actual readiness |
| Select models per request | Support multiple loaded models without recreating containers |
| Keep stack integration category-neutral | Allow artifacts to provide their own model identity, category, threshold, decision, and heatmap data |

## Documentation Update Rule

Update this document when component boundaries, service topology, networking, registry or artifact handling, build strategy, or deployment assumptions change. Do not update it for internal implementation details that do not affect the architecture.

## Last Updated

2026-08-21
