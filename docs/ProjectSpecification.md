# Industrial Visual Anomaly Detection Stack - Project Specification

## Document Purpose

This document defines the stable scope, goals, constraints, and acceptance criteria for the local stack orchestration repository.

Implementation progress belongs in `DevelopmentStatus.md`. Container and dependency boundaries belong in `ArchitectureOverview.md`. Operational setup belongs in `LocalStackQuickStart.md`.

## Project Objective

The project provides a reproducible Docker Compose environment for running the server-side components of the Industrial Visual Anomaly Detection system.

It allows a user to start the published Python inference service and ASP.NET Core backend together without manually preparing separate local source checkouts for those services.

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
Locally exported model artifact
```

## Functional Scope

The initial stack shall provide:

- one Docker Compose definition;
- one inference-service container;
- one backend container;
- pinned source versions for reproducible image builds;
- an internal Docker network between backend and inference service;
- a read-only model-artifact volume mount;
- backend and inference health checks;
- configurable ports and artifact paths through environment variables;
- an `.env.example` without secrets or machine-specific values;
- documented build, start, stop, inspection, and cleanup commands;
- a verification script for container health and one analysis request;
- instructions for connecting the native WPF desktop application.

## Repository Ownership

This repository owns:

- Dockerfiles used to build the published inference and backend source versions;
- Docker Compose orchestration;
- local stack configuration examples;
- startup and verification scripts;
- stack-level documentation;
- stack-level CI validation.

It does not own:

- model development, training, evaluation, or artifact export;
- Python service implementation;
- ASP.NET Core backend implementation;
- WPF desktop implementation;
- datasets or model artifacts;
- production cloud deployment.

Changes to application behavior remain in the corresponding application repository.

## Source Version Strategy

Container builds shall use explicit published repository tags rather than an unpinned default branch.

The verified compatible versions are:

- model and inference service: `v0.4.0`;
- backend: `v0.2.0`;
- desktop client: `v0.2.0`.

Source versions shall be configurable as Docker build arguments while retaining verified defaults.

The orchestration repository shall not copy application source code into its own Git history.

## Model Artifact Boundary

The inference container requires an exported model artifact containing metadata and feature memory.

The artifact:

- shall remain outside Git history;
- shall not be embedded in the container image;
- shall be mounted into the container as a read-only volume;
- shall be created by following the model repository instructions;
- shall remain subject to the dataset and model dependency license conditions from which it was produced.

The committed default artifact location targets `mvtec-ad-capsule-320`. The stack shall accept one compatible artifact at a time through configurable host and container paths.

Compatibility has been verified with both the Capsule reference artifact and `mvtec-ad-bottle-generalized-320`. The orchestration layer shall remain category-neutral and shall not hard-code model identity, category, threshold, decision, or heatmap values.

## Dataset Boundary

This repository shall not distribute MVTec AD images or other third-party datasets.

Users who want to reproduce artifact export shall download the dataset from its official source and comply with its license. Runtime use of an already exported local artifact does not require mounting the complete dataset into the containers.

## Desktop Boundary

The WPF desktop application shall not run inside Docker.

The stack documentation shall explain how to:

- run the desktop application natively on Windows;
- configure its backend address for the containerized HTTP endpoint;
- verify backend liveness and inference readiness before analysis.

Containerization of WPF, Windows containers, and graphical container forwarding are outside scope.

## Configuration Requirements

Configuration shall use environment variables and an optional local `.env` file.

The committed `.env.example` shall contain safe defaults and documentation-friendly placeholders only.

Configuration shall cover at least:

- backend host port;
- inference diagnostic host port;
- local model-artifact host and container paths;
- model and backend source tags;
- inference memory chunk size;
- backend inference-request timeout.

Required values shall fail clearly when absent or invalid.

## Networking Requirements

- Backend-to-inference communication shall use the Docker service name rather than `localhost`.
- Only ports required for local verification or desktop access shall be published to the host.
- The inference service may be published for diagnostics but backend communication shall remain on the internal network.
- The initial local container stack may use HTTP; production TLS termination is outside scope.

## Security and Privacy Requirements

- Containers shall not contain credentials or private hostnames.
- Model artifacts shall be mounted read-only.
- Dataset images, uploaded images, response payloads, and generated heatmaps shall not be committed.
- Container logs shall not expose image bytes, Base64 heatmap payloads, or secrets.
- Images should run as non-root users where practical.
- Runtime images shall be smaller than build images through multi-stage builds where practical.
- Published base images shall use explicit supported runtime families.

## Reproducibility Requirements

- Application source references shall use explicit tags.
- Docker Compose configuration shall be valid without undocumented local edits.
- A new user shall be able to copy `.env.example` to `.env` and identify every required local value.
- Build and startup commands shall be documented from the repository root.
- Health checks shall provide a deterministic readiness signal.
- The stack shall be verifiable without installing Python or the .NET SDK on the host.
- Required pretrained backbone weights shall be included during the image build so that inference startup does not require internet access.

Docker Desktop, Docker Compose, the native desktop prerequisites, and the external model artifact remain required.

## Quality Requirements

- `docker compose config` shall succeed.
- Dockerfiles shall build successfully from the documented commands.
- Both containers shall reach healthy or ready states.
- The backend shall report readiness only when inference is available.
- One normal and one anomalous image request shall be verifiable when the user supplies licensed local test images.
- Stack scripts shall fail with actionable messages.
- CI shall validate repository formatting and Docker Compose configuration without requiring a model artifact.

## Initial Acceptance Criteria

The initial orchestration milestone is complete when:

- both Dockerfiles build pinned compatible application releases;
- Docker Compose starts backend and inference services;
- the local artifact is mounted read-only;
- inference liveness returns a successful response;
- backend liveness and readiness return successful responses;
- a real analysis request returns decision metadata and a heatmap;
- the native desktop connects to the containerized backend;
- normal and anomalous analyses are verified through the complete stack;
- setup and troubleshooting documentation are complete;
- automated configuration validation succeeds;
- no dataset, artifact, secret, or runtime output is tracked by Git.

## Deferred Scope

The following capabilities remain deferred:

- multiple simultaneously loaded model artifacts;
- runtime model or category selection without recreating the inference container;
- artifact download or publication;
- dataset download automation;
- container registries and prebuilt public images;
- WPF containerization;
- Kubernetes;
- production ingress, TLS, authentication, and secret management;
- GPU-specific container support;
- cloud deployment.

## Documentation Update Rule

Documentation shall be updated after verified stack milestones or compatibility changes. Routine formatting changes do not require a full documentation revision.

## Last Updated

2026-08-19
