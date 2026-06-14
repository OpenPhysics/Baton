# OpenPhysics `Baton`

Orchestration repository for the [OpenPhysics](https://github.com/OpenPhysics) organization. Baton owns
the **operational** side of the org: the reusable CI/CD workflows every simulation calls, the cross-repo
automation scripts, the Dependabot templates, the machine-readable repository catalog, and the GitHub
Pages simulation landing page.

> Community-health defaults (license, contributing, code of conduct, security policy, issue/PR templates,
> org profile) live in [OpenPhysics/.github](https://github.com/OpenPhysics/.github) — GitHub requires those
> in the special `.github` repo so they are inherited org-wide.

## Contents

| Path | Purpose |
|---|---|
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | Reusable CI workflow (audit, lint, type-check, build) |
| [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) | Reusable GitHub Pages deploy workflow |
| [`.github/workflows/shared-codeql.yml`](.github/workflows/shared-codeql.yml) | Reusable CodeQL analysis |
| [`.github/workflows/shared-dependency-review.yml`](.github/workflows/shared-dependency-review.yml) | Reusable dependency review |
| [`.github/workflows/shared-compliance-check.yml`](.github/workflows/shared-compliance-check.yml) | README and repo-structure compliance audit |
| [`.github/workflows/pages.yml`](.github/workflows/pages.yml) | Build and deploy the org simulation index to GitHub Pages |
| [`.github/workflows/optimize-assets.yml`](.github/workflows/optimize-assets.yml) | Regenerate WebP card thumbnails from screenshots and commit them back |
| [`.github/workflows/fleet-exec.yml`](.github/workflows/fleet-exec.yml) | Fan a command across many repos and open one PR each (manual dispatch) |
| [`.github/workflows/fleet-health.yml`](.github/workflows/fleet-health.yml) | Weekly lint / type-check / build of every simulation, reported as a table |
| [`.github/workflows/sync-dependabot.yml`](.github/workflows/sync-dependabot.yml) | Validate the Dependabot templates |
| [`scripts/`](scripts/) | Repo catalog tools, compliance checks, Dependabot/metadata sync, screenshots |
| [`config/`](config/) | Canonical Dependabot templates synced to member repos |
| [`structure/repos.json`](structure/repos.json) | Machine-readable catalog of org repositories |
| [`docs/`](docs/) | Generated landing page ([openphysics.github.io/Baton](https://openphysics.github.io/Baton/)) |

## Shared CI

Each simulation's `.github/workflows/ci.yml` calls the reusable workflows from this repo:

```yaml
jobs:
  ci:
    uses: OpenPhysics/Baton/.github/workflows/ci.yml@main
  dependency-review:
    if: github.event_name == 'pull_request'
    uses: OpenPhysics/Baton/.github/workflows/shared-dependency-review.yml@main
  codeql:
    uses: OpenPhysics/Baton/.github/workflows/shared-codeql.yml@main
```

Optional compliance checking:

```yaml
  compliance:
    uses: OpenPhysics/Baton/.github/workflows/shared-compliance-check.yml@main
    with:
      repo-name: ${{ github.event.repository.name }}
```

Pages deploy (sims that publish to GitHub Pages):

```yaml
jobs:
  deploy:
    uses: OpenPhysics/Baton/.github/workflows/deploy.yml@main
    permissions:
      contents: read
      pages: write
      id-token: write
```

## Compliance workflow

[`shared-compliance-check.yml`](.github/workflows/shared-compliance-check.yml) runs weekly (Mondays 06:00 UTC)
and on manual dispatch. It reads [`structure/repos.json`](structure/repos.json), clones each simulation repo,
and checks:

- **FAIL** if `CONTRIBUTING.md` or `LICENSE` exists at repo root (use the org defaults from `OpenPhysics/.github`)
- **FAIL** if `README.md` is missing `## Features`, `## Quick Start`, `## Scripts`, `## Tech Stack`, `## License`, or `## Contributing`
- **FAIL** if `README.md` sections are out of order or include extra top-level sections (only the six standard sections allowed)
- **FAIL** if `.github/workflows/ci.yml` does not call this repo's shared reusable CI workflow

Simulation READMEs use a fixed six-section outline (in order): **Features → Quick Start → Scripts → Tech Stack → License → Contributing**.

Run locally against a checkout:

```bash
scripts/check-repo-compliance.sh /path/to/sim-repo
```

## Repository catalog

[`structure/repos.json`](structure/repos.json) lists all OpenPhysics repositories with metadata (simulation
type, framework, deployed URL, physics topics, etc.). The compliance workflow, Pages landing page, and the
catalog scripts consume this file. See [`scripts/README.md`](scripts/README.md) for the tooling:

```bash
scripts/parse-repos.sh names --simulation
scripts/list-repos.sh --json
scripts/sync-github-metadata.sh --dry-run
```

Scripts assume the `Baton` repo lives beside member repos in a shared workspace; set
`OPENPHYSICS_WORKSPACE` or pass `--catalog /path/to/repos.json` if your checkout differs.

## Fleet operations

Cross-repo automation, all driven from the catalog:

- **Batch changes** — [`scripts/fleet-exec.sh`](scripts/fleet-exec.sh) clones each selected
  repo, runs a command, and (with `--apply`) opens one PR per repo. Dry-run by default. The
  [`fleet-exec.yml`](.github/workflows/fleet-exec.yml) workflow exposes it as a manual dispatch
  (e.g. bump a shared dependency, run `npm run fix`, apply a codemod). Opening PRs in other
  repos needs a `FLEET_PAT` secret with write access — the default `GITHUB_TOKEN` is scoped to
  Baton only.
- **Health report** — [`fleet-health.yml`](.github/workflows/fleet-health.yml) runs weekly,
  cloning every active simulation and running lint, type-check, and build, then publishing a
  pass/fail table to the job summary. Read-only; surfaces sims broken by a shared-workflow or
  dependency change.
- **Compliance audit** — [`shared-compliance-check.yml`](.github/workflows/shared-compliance-check.yml)
  audits README structure and CI wiring across the org (see above).
