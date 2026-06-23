# OpenPhysics org scripts

Utilities for reading [`structure/repos.json`](../structure/repos.json) and operating on
OpenPhysics repositories. These scripts are intended for local use and for AI agents working in
the monorepo checkout.

## Prerequisites

- [`jq`](https://jqlang.org/)
- [`gh`](https://cli.github.com/) for GitHub sync commands
- Node.js + `npm install` (in the repo root) for the screenshot and thumbnail scripts — installs Playwright and sharp

## Quick reference

| Script | Purpose |
|---|---|
| [`parse-repos.sh`](parse-repos.sh) | Core parser/CLI for `repos.json` |
| [`list-repos.sh`](list-repos.sh) | Human-friendly listing wrapper |
| [`clone-fleet.sh`](clone-fleet.sh) | Clone/update every catalog repo into the workspace as a sibling |
| [`fleet-exec.sh`](fleet-exec.sh) | Run a command across many repos and open one PR each |
| [`../doc/fleet-git.md`](../doc/fleet-git.md) | Cheat sheet: everyday git across local checkouts (`pull`/`push`/`status` all) |
| [`sync-github-metadata.sh`](sync-github-metadata.sh) | Push description + website to GitHub |
| [`sync-claude-settings.sh`](sync-claude-settings.sh) | Roll the `scenerystack` Claude Code plugin out to sim repos' `.claude/settings.json` |
| [`lib/repos.sh`](lib/repos.sh) | Bash helper functions for other scripts |
| [`check-repo-compliance.sh`](check-repo-compliance.sh) | README/CI compliance checks |
| [`check-skills.sh`](check-skills.sh) | Validate the `skills/` collection and its README index (Baton self-check) |
| [`check-node-version.sh`](check-node-version.sh) | Assert the fleet Node version agrees across workflows (Baton self-check) |
| [`sync-dependabot.sh`](sync-dependabot.sh) | Copy Dependabot configs to sim repos |
| [`generate-pages-index.sh`](generate-pages-index.sh) | Build `docs/index.html` simulation landing page |
| [`make-thumbnails.mjs`](make-thumbnails.mjs) | Downscale `screenshots/*.png` to `docs/assets/*.webp` with sharp |
| [`generate-screenshots.sh`](generate-screenshots.sh) | Capture each sim's screen to `<sim>/assets/screenshot.png` |
| [`screenshot.mjs`](screenshot.mjs) | Playwright driver behind `generate-screenshots.sh` |

## parse-repos.sh

Primary entry point for agents. Reads `structure/repos.json` and adds computed fields:

- `githubHomepage` — normalized Pages URL (`https://openphysics.github.io/{name}`)
- `localPath` — sibling directory in the workspace checkout
- `localExists` — whether that directory is present locally

```bash
# All repository names
scripts/parse-repos.sh names

# Simulation repos only
scripts/parse-repos.sh names --simulation

# Full JSON with computed fields
scripts/parse-repos.sh list --format json --simulation

# One repo
scripts/parse-repos.sh get DopplerEffect

# Local checkout paths for sims that exist on disk
scripts/parse-repos.sh paths --simulation --require-local

# Run a command per repo (env: REPO_NAME, REPO_HOMEPAGE, REPO_PATH, ...)
scripts/parse-repos.sh for-each --simulation -- \
  echo "$REPO_NAME -> $REPO_HOMEPAGE"

# Catalog summary
scripts/parse-repos.sh summary
```

Filters:

- `--type simulation|template|config|hardware-interface|tool`
- `--status active|template`
- `--simulation` / `--no-simulation`

## clone-fleet.sh

Populate the workspace from the catalog: clone every selected repo as a sibling directory
beside `Baton`. `repos.json` is the single source of truth — there are no submodules, so a
repo appears here the moment it is added to the catalog. Re-runnable and safe: repos already
on disk are skipped unless `--update` is given (which `git pull --ff-only`s them).

The thin [`OpenPhysics` superproject](https://github.com/OpenPhysics/OpenPhysics)'s
`bootstrap.sh` clones `Baton` and then calls this; run it directly once you already have
`Baton`.

```bash
# Clone whatever is missing into the workspace
scripts/clone-fleet.sh

# Only the simulations, and fast-forward any already present
scripts/clone-fleet.sh --simulation --update

# Preview the plan, change nothing (HTTPS instead of SSH)
scripts/clone-fleet.sh --dry-run --https
```

Reuses the same catalog filters as `parse-repos.sh` (`--simulation`, `--type`, `--status`,
`--only NAME`, `--skip NAME`). Clones over SSH by default; `--https` for token/anonymous use.

## fleet-exec.sh

Fan a change out across the org: clone each selected repo, run a command in it, and
— with `--apply` — push a branch and open one PR per repo. **Dry-run by default** (prints
a diffstat per repo and opens nothing). Reuses the same catalog filters as `parse-repos.sh`.

```bash
# Preview bumping a dependency across every simulation (no PRs):
scripts/fleet-exec.sh --simulation -- npm pkg set dependencies.scenerystack=^3.1.0

# Apply a Biome autofix across all sims and open one PR each:
scripts/fleet-exec.sh --simulation --apply --install \
  --branch chore/biome-fix --title "chore: biome autofix" -- npm run fix
```

Key options: `--apply` (push + open PRs), `--install` (`npm install` before the command,
needed for lint/build codemods), `--branch`, `--title`, `--label`, `--skip NAME`, `--keep`.

Pushing and opening PRs needs a token with **write access to the target repos** — your local
`gh auth`, or an org PAT / GitHub App token as `GH_TOKEN`. The default `GITHUB_TOKEN` only
reaches the repo running a workflow, so the [`fleet-exec.yml`](../.github/workflows/fleet-exec.yml)
dispatch wrapper reads a `FLEET_PAT` secret for `apply=true`.

## sync-github-metadata.sh

Updates GitHub **Description** and **Website** from `repos.json`:

```bash
scripts/sync-github-metadata.sh --dry-run
scripts/sync-github-metadata.sh
scripts/sync-github-metadata.sh --repo TemplateSingleSim
```

Note: GitHub does not expose API toggles for **Deployments** / **Packages** in the About sidebar.

## sync-claude-settings.sh

Roll the [`scenerystack` Claude Code plugin](../.claude-plugin/marketplace.json) out to the
SceneryStack repos by **merging** the canonical keys from
[`config/claude-settings.json`](../config/claude-settings.json) into each repo's
`.claude/settings.json`. It only adds/updates `extraKnownMarketplaces.openphysics` and
`enabledPlugins["scenerystack@openphysics"]` — existing keys in a repo's settings are preserved.
Targets every catalog repo whose framework is `SceneryStack`. Writes files only; commit/push (or
fan out as PRs via `fleet-exec.sh`) is left to you.

```bash
scripts/sync-claude-settings.sh --dry-run     # show what would change, write nothing
scripts/sync-claude-settings.sh               # merge into each sibling repo
scripts/sync-claude-settings.sh DopplerEffect # limit to named repo(s)
```

## Self-check scripts

Run by [`baton-selfcheck.yml`](../.github/workflows/baton-selfcheck.yml) on every PR that touches
`skills/`, `.claude-plugin/`, or `scripts/`, and runnable locally:

```bash
scripts/check-skills.sh         # every skills/<name>/SKILL.md is well-formed and indexed in skills/README.md
scripts/check-node-version.sh   # ci.yml / deploy.yml / fleet-health.yml all declare the same Node version
```

## generate-screenshots.sh

Captures a screenshot of every SceneryStack simulation into `<sim>/assets/screenshot.png`.
It serves each sim's built `dist/` and renders the requested screen with the sim's **own**
`ScreenshotGenerator` (the same code path as the in-app camera button), so the result is a
clean PNG at the sim's nominal layout — not a raw viewport grab. Multi-screen sims are forced
onto a single screen with `?screens=N`, so the capture is that screen's play area rather than
the home-screen selector.

```bash
# One-time setup: install Playwright (declared in this repo's package.json)
npm install
# If Chromium is not already cached: npx playwright install chromium

# Capture every sim's first screen (reuses dist/ if already built)
npm run screenshots
# or directly:
scripts/generate-screenshots.sh

# Force a rebuild first, capture a specific screen, or limit to some sims
scripts/generate-screenshots.sh --build
scripts/generate-screenshots.sh --screen 2 Resonance OscillationsAndChaos
```

Options: `--build` (force `npm run build`), `--screen N` (default 1),
`--width`/`--height` (default 1154×753, matching existing assets). Trailing positional
arguments limit the run to the named sims.

`screenshot.mjs` is the underlying Playwright driver and can be run on a single dist directory:

```bash
node scripts/screenshot.mjs --dist ../DopplerEffect/dist --out /tmp/shot.png --screen 1
```

It discovers a usable Chromium automatically (Playwright's bundled build, the newest cached
build, or a system Chromium); override with `PLAYWRIGHT_CHROMIUM_EXECUTABLE`.

## Bash helpers

Source from other scripts:

```bash
source "$(dirname "$0")/lib/repos.sh"
repos_simulation_names | while read -r sim; do
  echo "$sim"
done
```

Or call the CLI directly:

```bash
scripts/parse-repos.sh names --simulation
```

## Workspace layout

Scripts assume the orchestration `Baton` repo lives beside member repos:

```
OpenPhysics/
  Baton/            ← this repo
  DopplerEffect/
  TemplateSingleSim/
  ...
```

If your checkout differs, set `OPENPHYSICS_WORKSPACE` or pass `--catalog /path/to/repos.json`.
