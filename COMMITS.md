# Commit Message Guidelines

This project follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.

## Format

```text
<type>(optional scope): <short summary>

(optional body)

(optional footer)
```

## Types

- `feat` - add a capability or observable stack behavior;
- `fix` - correct invalid orchestration or runtime behavior;
- `docs` - change documentation only;
- `test` - add or update automated verification;
- `refactor` - restructure files without changing intended behavior;
- `perf` - improve measured build or runtime performance;
- `style` - change formatting or whitespace only;
- `chore` - change tooling, configuration, dependencies, or repository support files;
- `revert` - revert an earlier commit.

## Recommended Scopes

- `compose` - Compose services, networks, mounts, dependencies, and health checks;
- `backend` - backend container build and runtime configuration;
- `inference` - Python inference container build and runtime configuration;
- `artifacts` - model artifact paths, mounts, validation, and integrity handling;
- `config` - environment templates and shared configuration;
- `network` - service discovery, published ports, and network boundaries;
- `health` - container health checks and readiness behavior;
- `scripts` - local startup, shutdown, and verification scripts;
- `ci` - automated workflows and repository checks;
- `security` - container hardening and dependency remediation;
- `deps` - base-image, action, or tooling updates;
- `readme` - repository README;
- `docs` - documentation spanning multiple documents;
- `architecture` - architecture documentation;
- `quickstart` - local stack operating instructions;
- `spec` - project specification;
- `status` - development-status documentation.

Scopes are optional. Use the most specific useful scope and keep each commit focused on one logical change.

## Examples

```text
feat(inference): add Python service container image
```

```text
feat(backend): add multi-stage API container image
```

```text
feat(compose): orchestrate backend and inference services
```

```text
feat(artifacts): mount model artifact as read-only
```

```text
feat(health): add service health dependencies
```

```text
fix(network): use Compose DNS for inference requests
```

```text
test(scripts): verify analysis response contains a heatmap
```

```text
chore(ci): validate Compose configuration and image builds
```

```text
docs(quickstart): document local artifact setup
```

```text
chore(deps): update ASP.NET Core runtime image
```

## Guidelines

- Use lowercase for type and scope.
- Write the summary in imperative mood, such as `add`, not `added`.
- Do not end the summary with a period.
- Keep the summary concise, ideally no longer than 72 characters.
- Keep each commit focused on one logical change.
- Use the body for motivation, compatibility details, trade-offs, or migration steps.
- Pin application source revisions and explain intentional upgrades.
- Do not include secrets, credentials, private hosts, or personal machine paths.
- Do not commit `.env`, datasets, model artifacts, test images, heatmaps, logs, or generated output.
- Do not describe a container, Compose service, or verification workflow as implemented before it has run successfully.
- Do not claim compatibility, startup improvements, security improvements, or performance gains without verification.
- Separate behavioral changes from bulk formatting where practical.

## Breaking Changes

Mark a breaking change when users must change environment variables, artifact layout, published ports, Compose commands, or another documented public workflow.

```text
feat(config)!: rename artifact path variable
```

Alternatively, use a footer:

```text
feat(compose): change backend host port

BREAKING CHANGE: local clients must use the new published backend port.
```

Internal changes before a public stack contract exists are not automatically breaking changes.

## Documentation Commits

Use `docs` when only documentation changes:

```text
docs(architecture): document container network boundaries
```

Use `chore` when documentation is only one part of broader repository initialization:

```text
chore: initialize stack repository
```

## Verification Commits

Use `test` when adding checks that verify stack behavior:

```text
test(health): verify backend readiness through Compose
```

Use `scripts` for the scope when the primary change is a reusable local verification script:

```text
test(scripts): add local stack verification workflow
```

## Dependency and Image Commits

Use `chore(deps)` for base-image, GitHub Action, or supporting-tool updates that do not directly add product behavior.

```text
chore(deps): update Python runtime image
```

If an image or dependency change affects application compatibility, artifact loading, HTTP contracts, or runtime output, validate the complete affected workflow and explain the result in the commit body.

## Source Revision Updates

Changes to pinned application releases must identify the affected component and preserve reproducibility.

```text
chore(inference): update model service to v0.4.0
```

The commit body should record:

- the previous and new release;
- the reason for the update;
- the compatibility checks performed;
- any required configuration or artifact migration.

Do not use floating branches such as `main` as release defaults.

## Artifact Handling Commits

Never commit the artifact itself.

Artifact-related commits may change:

- ignored placeholder structure;
- environment variable definitions;
- read-only mounts;
- validation scripts;
- documentation.

Example:

```text
feat(artifacts): validate capsule artifact before startup
```

## Initial Repository Commit

Use:

```text
chore: initialize stack repository
```

Create the initial commit after:

- repository hygiene files are present;
- initial documentation is present;
- `.env.example` contains no secret or personal path;
- Dockerfiles and `compose.yml` pass static validation;
- both images build successfully;
- the stack starts with the verified capsule artifact;
- inference health and backend readiness succeed;
- one complete analysis including heatmap data is verified;
- generated output, datasets, test images, and artifacts remain untracked.
