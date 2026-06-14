# OpenPhysics org scripts

Utilities for reading [`structure/repos.json`](../structure/repos.json) and operating on
OpenPhysics repositories. These scripts are intended for local use and for AI agents working in
the monorepo checkout.

## Prerequisites

- [`jq`](https://jqlang.org/)
- [`gh`](https://cli.github.com/) for GitHub sync commands
- Node.js + `npm install` (in the repo root) for the screenshot scripts — installs Playwright

## Quick reference

| Script | Purpose |
|---|---|
| [`parse-repos.sh`](parse-repos.sh) | Core parser/CLI for `repos.json` |
| [`list-repos.sh`](list-repos.sh) | Human-friendly listing wrapper |
| [`sync-github-metadata.sh`](sync-github-metadata.sh) | Push description + website to GitHub |
| [`lib/repos.sh`](lib/repos.sh) | Bash helper functions for other scripts |
| [`check-repo-compliance.sh`](check-repo-compliance.sh) | README/CI compliance checks |
| [`sync-dependabot.sh`](sync-dependabot.sh) | Copy Dependabot configs to sim repos |
| [`generate-pages-index.sh`](generate-pages-index.sh) | Build `docs/index.html` simulation landing page |
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

## sync-github-metadata.sh

Updates GitHub **Description** and **Website** from `repos.json`:

```bash
scripts/sync-github-metadata.sh --dry-run
scripts/sync-github-metadata.sh
scripts/sync-github-metadata.sh --repo TemplateSingleSim
```

Note: GitHub does not expose API toggles for **Deployments** / **Packages** in the About sidebar.

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
