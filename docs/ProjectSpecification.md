# Industrial Visual Anomaly Detection Stack - Project Specification

## Document Purpose

This document defines the stable scope, goals, constraints, and acceptance criteria for the local stack orchestration repository.

Implementation progress belongs in `DevelopmentStatus.md`. Container and dependency boundaries belong in `ArchitectureOverview.md`. Operational setup belongs in `LocalStackQuickStart.md`.

## Project Objective

The project provides a reproducible Docker Compose environment for running the server-side components of the Industrial Visual Anomaly Detection system.

It allows a user to start the Python inference service and ASP.NET Core backend together without manually preparing separate local source checkouts for those services. Multiple compatible model artifacts can be made available through one external registry and selected per analysis request.

The Windows WPF desktop application remains a native host application and connects to the containerized backend.

## System Context

```text
Native WPF desktop application
        |
        | HTTP on the local development host
        v
ASP.NET Core backend container
        |
        | Internal Docker network
        v
Python inference container
        |
        | Read-only mounted volume
        v
Local model registry and exported artifacts
```

## Functional Scope

The stack shall provide:

- one Docker Compose definition;
- one inference-service container;
- one backend container;
- explicit source revisions for reproducible image builds;
- independently configurable local image tags;
- an internal Docker network between backend and inference service;
- a read-only volume mount containing a model registry and its artifact directories;
- simultaneous startup loading of multiple enabled model artifacts;
- discovery of available models through the backend;
- model selection per analysis request;
- a configured default model for compatible clients that omit a model identifier;
- backend and inference health checks;
- configurable ports and runtime paths through environment variables;
- an `.env.example` without secrets or machine-specific values;
- documented build, start, stop, inspection, and cleanup commands;
- a verification script for container health and an optional model-specific analysis request;
- instructions for connecting the native WPF desktop application.

## Repository Ownership

This repository owns:

- Dockerfiles used to build the inference and backend source revisions;
- Docker Compose orchestration;
- local stack configuration examples;
- startup and verification scripts;
- stack-level documentation;
- stack-level CI validation.

It does not own:

- model development, training, evaluation, or artifact export;
- the model-registry content;
- Python service implementation;
- ASP.NET Core backend implementation;
- WPF desktop implementation;
- datasets or model artifacts;
- production cloud deployment.

Changes to application behavior remain in the corresponding application repository.

## Source Version Strategy

Released stack defaults shall use explicit immutable repository tags rather than unpinned branches.

Source revisions shall be configurable as Docker build arguments. Local image tags shall be configured separately so that the source reference and resulting image name have distinct responsibilities.

Development branches may be used temporarily for local integration before compatible component releases exist. Such temporary references shall be documented as integration values and replaced with immutable tags before publishing a stable stack release.

The orchestration repository shall not copy application source code into its own Git history.

## Model Registry and Artifact Boundary

The inference container requires a model registry and the exported artifacts referenced by its enabled entries.

The registry shall identify at least:

- its schema version;
- one default model identifier;
- the available model entries;
- each model identifier and display name;
- each model's artifact directory;
- whether an entry is enabled.

The registry and artifacts:

- shall remain outside stack Git history;
- shall not be embedded in the container image;
- shall be mounted into the inference container through one read-only artifact root;
- shall be created or assembled by following the model repository instructions;
- shall remain subject to the license conditions of their datasets and model dependencies.

The inference service shall validate the registry and enabled artifacts during startup. Missing, invalid, duplicated, or incompatible entries shall cause a clear startup or health failure rather than a silent fallback.

The registry shall be the authoritative source for available and default models. The stack, backend, and desktop shall not require separate hard-coded model lists.

The orchestration layer shall remain category-neutral and shall not hard-code model identity, category, input size, threshold, decision, or heatmap values.

## Multi-Model Behavior

- Multiple enabled artifacts shall be loadable by one inference-service instance.
- Each enabled model shall have a stable unique identifier.
- One enabled model shall be designated as the default.
- The inference service shall expose its validated catalog to the backend.
- The backend shall expose an application-facing model catalog.
- An analysis request may include a model identifier.
- The selected model identifier shall flow from the client through the backend to inference.
- The response shall identify the model that produced the result.
- An unknown, disabled, or invalid model identifier shall produce a clear failure.
- Switching between already loaded models shall not require modifying `.env` or recreating containers.

Dynamic registry reload, lazy model loading, and model unloading after service startup are outside the current required scope.

## Dataset Boundary

This repository shall not distribute MVTec AD, VisA, or other third-party dataset images.

Users who reproduce artifact export shall obtain datasets from their official sources and comply with their licenses. Runtime use of already exported local artifacts does not require mounting complete datasets into the containers.

## Desktop Boundary

The WPF desktop application shall not run inside Docker.

The stack documentation shall explain how to:

- run the desktop application natively on Windows;
- configure its backend address for the containerized HTTP endpoint;
- verify backend liveness and inference readiness before analysis;
- retrieve the available model catalog through the backend;
- select a model and submit an analysis request.

Containerization of WPF, Windows containers, and graphical container forwarding are outside scope.

## Configuration Requirements

Configuration shall use environment variables and an optional local `.env` file.

The committed `.env.example` shall contain safe defaults and documentation-friendly placeholders only.

Configuration shall cover at least:

- backend and inference source revisions;
- backend and inference local image tags;
- backend host port;
- inference diagnostic host port;
- model-artifact host and container paths;
- model-registry container path;
- inference memory chunk size;
- backend inference-request timeout.

Required values shall fail clearly when absent or invalid. Host-specific absolute paths shall remain in the ignored local `.env`, not in committed defaults.

## Networking Requirements

- Backend-to-inference communication shall use the Docker service name rather than `localhost`.
- Only ports required for local verification or desktop access shall be published to the host.
- The inference service may be published for diagnostics, but backend communication shall remain on the internal network.
- The local container stack may use HTTP; production TLS termination is outside scope.
- The desktop shall communicate with the public backend boundary rather than calling inference directly.

## Security and Privacy Requirements

- Containers shall not contain credentials or private hostnames.
- The model registry and artifacts shall be mounted read-only.
- Dataset images, uploaded images, response payloads, and generated heatmaps shall not be committed.
- Container logs shall not expose image bytes, Base64 heatmap payloads, or secrets.
- Images should run as non-root users where practical.
- Runtime images shall be smaller than build images through multi-stage builds where practical.
- Published base images shall use explicit supported runtime families.

## Reproducibility Requirements

- Stable application source references shall use immutable tags.
- Temporary integration references shall be explicitly documented and shall not be presented as stable releases.
- Docker Compose configuration shall be valid without undocumented local edits.
- A new user shall be able to copy `.env.example` to `.env` and identify every required local value.
- Build and startup commands shall be documented from the repository root.
- Health checks shall provide deterministic readiness signals.
- The stack shall be verifiable without installing Python or the .NET SDK on the host.
- Required pretrained backbone weights shall be included during the image build so that inference startup does not require internet access.
- The local model registry and artifact layout shall be documented sufficiently for an operator to assemble them without modifying Compose files.

Docker Desktop, Docker Compose, native desktop prerequisites, and compatible external model artifacts remain required.

## Quality Requirements

- `docker compose config --quiet` shall succeed.
- Dockerfiles shall build successfully from the documented commands.
- The inference container shall become healthy after validating and loading the configured registry.
- The backend shall report readiness only when inference is available.
- The backend model-catalog endpoint shall return the configured default and enabled models.
- A model-specific analysis shall return the requested model identifier.
- Normal and anomalous image requests shall be verifiable when the user supplies licensed local test images.
- Returned analysis data shall include decision metadata and a valid heatmap.
- Stack scripts shall fail with actionable messages.
- The verification script shall support health-only and model-specific analysis modes.
- CI shall validate repository formatting and Docker Compose configuration without requiring model artifacts.

## Multi-Model Acceptance Criteria

The multi-model orchestration milestone is complete when:

- both Dockerfiles build compatible registry-capable application revisions;
- Docker Compose starts backend and inference services;
- the registry and all enabled artifacts are mounted read-only;
- inference validates the registry and reaches a healthy state;
- backend liveness and readiness return successful responses;
- the backend catalog returns the configured models and default identifier;
- at least two distinct model identifiers are selected successfully without recreating containers;
- each analysis response identifies the requested model;
- real analysis requests return scores, thresholds, decisions, metadata, and valid heatmaps;
- the native desktop retrieves the catalog and performs model-specific analyses through the containerized backend;
- setup and troubleshooting documentation describe the registry-based workflow;
- automated configuration validation succeeds;
- no dataset, registry, artifact, secret, or runtime output is tracked by Git.

## Release Acceptance Criteria

A stable multi-model stack release additionally requires:

- compatible immutable releases of the model, backend, and desktop components;
- stack defaults updated from temporary integration branches to those release tags;
- complete local verification repeated with the released component revisions;
- GitHub Actions verification of the committed stack configuration;
- documentation and compatibility references aligned with the released versions.

## Deferred Scope

The following capabilities remain deferred:

- dynamic registry reload without recreating the inference container;
- lazy model loading or unloading after startup;
- automatic artifact download or publication;
- dataset download automation;
- distributable dataset-based test fixtures;
- container registries and prebuilt public images;
- WPF containerization;
- Kubernetes;
- production ingress, TLS, authentication, and secret management;
- GPU-specific container support;
- cloud deployment.

## Documentation Update Rule

Documentation shall be updated after verified stack milestones or compatibility changes. Routine formatting changes do not require a full documentation revision.

## Last Updated

2026-08-21
