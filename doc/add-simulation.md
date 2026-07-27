# Adding a simulation to the fleet

Checklist for bringing a new SceneryStack sim into OpenPhysics end-to-end: GitHub repo,
[`structure/repos.json`](../structure/repos.json) catalog entry, screenshots, and the org
landing page at [openphysics.github.io/Baton](https://openphysics.github.io/Baton/).

> **Two different lists.** The org **landing page** in Baton (`docs/index.html`) is
> **generated** from `repos.json` plus committed screenshots — no hand-edited card
> Markdown. Separately, the **workspace bootstrapper** repo
> [`OpenPhysics/README.md`](https://github.com/OpenPhysics/OpenPhysics/blob/main/README.md)
> has a **hand-edited** sim list in its `## Layout` table; that file is *not* generated
> from the catalog and must be updated by hand when you add a sim (see §7).

---

## 1. Create the simulation repository

1. Copy [`TemplateSingleSim`](https://github.com/OpenPhysics/TemplateSingleSim) (or clone it
   beside `Baton` and work from that checkout).
2. Run the template rename so package name, namespaces, and strings match the new sim:

   ```bash
   cd TemplateSingleSim   # or your copy
   npm install
   npm run rename         # follow the prompts for id / title / package name
   ```

3. Create the empty GitHub repo under the `OpenPhysics` org (same **PascalCase** name you
   will use in the catalog, e.g. `MyNewSim`), push `main`, and confirm:
   - `.github/workflows/ci.yml` calls `OpenPhysics/Baton/.../ci.yml@main`
   - `.github/workflows/deploy.yml` (or equivalent) calls Baton's reusable Pages deploy
   - README follows the six-section outline (enforced by compliance — see
     [`CONVENTIONS.md`](../CONVENTIONS.md))
4. In the GitHub repo settings, enable **Pages → Source: GitHub Actions**, then merge a
   green `main` build so `https://openphysics.github.io/<SimName>/` goes live.

---

## 2. Add the catalog entry

Edit [`structure/repos.json`](../structure/repos.json). Insert a new object in `repos`
(keep the list alphabetized by `name` when practical). Active SceneryStack sims look like:

```json
{
  "name": "MyNewSim",
  "type": "simulation",
  "isSimulation": true,
  "isPhETPort": false,
  "isNAAPPort": false,
  "isNewSimulation": true,
  "language": ["TypeScript"],
  "framework": "SceneryStack",
  "description": "One or two sentences for GitHub and the landing-page card.",
  "deployedUrl": "https://OpenPhysics.github.io/MyNewSim",
  "physicsTopics": ["topic-a", "topic-b"],
  "screens": ["Screen One"],
  "status": "active"
}
```

| Field | Notes |
|---|---|
| `name` | Must match the GitHub repo name (and the sibling folder name in the workspace). |
| `isPhETPort` / `isNAAPPort` / `isNewSimulation` | Exactly one of the three landing-page buckets should be the “home” for the card: set `isPhETPort` or `isNAAPPort` for ports; otherwise set `isNewSimulation: true`. The page generator groups by PhET / NAAP / everything else. |
| `description` | Shown on the card and synced to the GitHub repo description. |
| `deployedUrl` | Canonical Pages URL (trailing slash optional; the generator normalizes). |
| `physicsTopics` | Up to three tags are shown on the card. |
| `screens` | Human-readable screen titles (documentation / compliance; not required for the card image). |
| `status` | `"active"` to appear on the landing page and in fleet health. Use `"template"` / other values only for non-shipped entries (e.g. `TemplateSingleSim`). |

Validate locally:

```bash
jq empty structure/repos.json
scripts/parse-repos.sh names --simulation | grep MyNewSim
```

---

## 3. Pull the repo into the workspace

From the OpenPhysics workspace root (sibling of `Baton`):

```bash
./bootstrap.sh --update
# or: Baton/scripts/clone-fleet.sh --update
```

Confirm `../MyNewSim` (or `$OPENPHYSICS_WORKSPACE/MyNewSim`) exists beside `Baton`.

---

## 4. Screenshot → thumbnail → landing page

Asset pipeline (all paths relative to the `Baton` repo):

| Stage | Path | Role |
|---|---|---|
| Sim-owned capture | `<Sim>/assets/screenshot.png` | Ground truth in the **sim** repo (optional to commit there; many sims do). |
| Baton full-size | `screenshots/<Sim>.png` | Ground truth **in Baton** for the org page. |
| Card thumbnail | `docs/assets/<Sim>.webp` | Lightweight image served by the landing page. |
| Page | `docs/index.html` | Generated HTML (cards come from `repos.json` + thumbnails). |

### Option A — Local (best when the sim is checked out)

From `Baton/` after `npm install` (and `npx playwright install chromium` once):

```bash
# 1. Capture into the sibling sim (builds dist/ if needed)
scripts/generate-screenshots.sh --build MyNewSim

# 2. Copy sibling shot → screenshots/, build WebP under docs/assets/
npm run thumbnails -- MyNewSim
# same as: node scripts/make-thumbnails.mjs MyNewSim

# 3. Regenerate the HTML index from repos.json
npm run pages
# same as: scripts/generate-pages-index.sh
```

`make-thumbnails.mjs` copies `../MyNewSim/assets/screenshot.png` → `screenshots/MyNewSim.png`
when the sibling file exists, then writes `docs/assets/MyNewSim.webp`. Open
`docs/index.html` in a browser to sanity-check the new card (placeholder monogram means the
WebP is still missing).

Commit in **Baton** at least:

- `structure/repos.json`
- `screenshots/MyNewSim.png`
- `docs/assets/MyNewSim.webp`
- `docs/index.html` (if your change regenerates it — keep it in sync with the catalog)

### Option B — After Pages is live (CI)

Once `https://openphysics.github.io/MyNewSim/` deploys, run the
[`refresh-screenshots.yml`](../.github/workflows/refresh-screenshots.yml) workflow
(workflow_dispatch; optional `repos: MyNewSim` input). It captures live Pages, regenerates
WebPs + `docs/index.html`, and opens a PR. Useful for refresh; for a brand-new sim, Option A
is usually faster so the catalog PR can include the card image in one shot.

Pushing `screenshots/**` to `main` also triggers
[`optimize-assets.yml`](../.github/workflows/optimize-assets.yml) to refresh WebPs.

---

## 5. Sync GitHub metadata and fleet config

```bash
# Description + Website on the GitHub repo page
scripts/sync-github-metadata.sh --repo MyNewSim

# Dependabot + Claude settings (operate on every matching local checkout;
# after clone-fleet, your new sim is included automatically)
scripts/sync-dependabot.sh
scripts/sync-claude-settings.sh
```

Open a PR in the **sim** repo for any files those sync scripts change (or commit
directly on a setup branch before the sim’s first release).

---

## 6. Compliance and health

```bash
scripts/check-repo-compliance.sh ../MyNewSim
```

Must print `Compliance check passed`. After merge, the next
[`fleet-health.yml`](../.github/workflows/fleet-health.yml) / compliance matrix run will pick
the sim up automatically from the catalog (no workflow edit required).

---

## 7. Update the workspace README (hand-edited)

The [`OpenPhysics`](https://github.com/OpenPhysics/OpenPhysics) superproject README is **not**
generated. Its `## Layout` table lists every repo type in prose — simulations appear as a
comma-separated row of backtick names:

```markdown
| `BasicCoordinatesAndSeasons`, `DopplerEffect`, … , `Zenith` | simulation | SceneryStack TypeScript simulations. |
```

When you add a sim:

1. Open `OpenPhysics/README.md` on `main`.
2. Append `` `MyNewSim` `` to that simulation row (keep **alphabetical** order with the
   other names).
3. Open a PR in **OpenPhysics** (separate from the Baton catalog PR).

`bootstrap.sh` / `clone-fleet.sh` read `repos.json`, not this README — the table is for
humans cloning the workspace, not for tooling. If you skip this step the sim still clones and
appears on the Baton landing page, but the workspace README will be stale.

---

## 8. Manual counts and prose tallies

Some places still carry a **hand-maintained number** or sim list. Others are **computed from
`repos.json`** when a script or workflow runs — do not edit those by hand.

### Get current counts from the catalog

Run from `Baton/`:

```bash
# Active SceneryStack sims (excludes TemplateSingleSim, cd48, etc.)
jq '[.repos[] | select(.isSimulation==true and .status=="active")] | length' structure/repos.json

# Landing-page buckets (must match isPhETPort / isNAAPPort flags on each row)
jq '[.repos[] | select(.isSimulation==true and .status=="active" and .isPhETPort==false and .isNAAPPort==false)] | length' structure/repos.json   # “New / original”
jq '[.repos[] | select(.isSimulation==true and .status=="active" and .isPhETPort==true)] | length' structure/repos.json                          # PhET ports
jq '[.repos[] | select(.isSimulation==true and .status=="active" and .isNAAPPort==true)] | length' structure/repos.json                           # NAAP ports
```

*(As of 2026-07-27 the fleet has **26** active sims: **12** original, **7** PhET, **7** NAAP.)*

### Auto-generated — no manual count edit

| Location | What updates |
|---|---|
| [`docs/index.html`](../docs/index.html) footer | `"N live simulations"` — from [`generate-pages-index.sh`](../scripts/generate-pages-index.sh) (`total_count`) |
| Same file, section headings | Per-bucket counts (`new_count`, `phet_count`, `naap_count`) — same script |
| [`fleet-health.yml`](../.github/workflows/fleet-health.yml) matrix | One job per catalog sim — driven by `repos.json` |
| [`shared-compliance-check.yml`](../.github/workflows/shared-compliance-check.yml) matrix | Same |

Regenerate the landing page after catalog changes: `npm run pages` (see §4).

### Hand-edited when you add a sim

| Location | Repo | What to update |
|---|---|---|
| [`OpenPhysics/README.md`](https://github.com/OpenPhysics/OpenPhysics/blob/main/README.md) `## Layout` | OpenPhysics | Comma-separated sim names (§7) — **no total count** in that file |
| [`.github/profile/README.md`](https://github.com/OpenPhysics/.github/blob/main/profile/README.md) | `.github` | Top stats row `` **N** simulations ``; add a table row under **NAAP**, **PhET**, or **Other simulations** (match `isNAAPPort` / `isPhETPort` / original) |
| [`CONVENTIONS.md`](../CONVENTIONS.md) scope blockquote | Baton | `` As of YYYY-MM-DD that is N sims … `` — bump **N**, date, and example names if you use them |
| [`ACCESSIBILITY.md`](../ACCESSIBILITY.md) scope blockquote | Baton | Same pattern as CONVENTIONS |

The org **profile README** is what visitors see on github.com/OpenPhysics — it is separate from
the Baton landing page and from the workspace bootstrapper README. All three can drift
independently.

### Audit snapshots — update on the next audit pass, not every sim

These are dated fleet reports; treat counts inside them as historical unless you are refreshing
the audit:

| File | Typical stale content |
|---|---|
| [`doc/fleet-parity-audit.md`](fleet-parity-audit.md) | Scope line and table rows saying “all 24 sims” |
| [`doc/fleet-a11y-audit.md`](fleet-a11y-audit.md) | Scope line “24 active … sims” |
| [`doc/doc-freshness-audit.md`](doc-freshness-audit.md) | Scope “24 … repos”, `25/25` ratio rows, “Prior pass: … (20 sims)” |

When you add a sim you do **not** have to rewrite these immediately; do bump
CONVENTIONS/ACCESSIBILITY scope lines and the org profile if you want public tallies to stay
accurate.

---

## Minimal PR checklist

**Sim repo**

- [ ] Created from `TemplateSingleSim` via `npm run rename`
- [ ] CI + Pages deploy wired; first deploy succeeded
- [ ] `scripts/check-repo-compliance.sh` passes

**Baton**

- [ ] Row added to `structure/repos.json` (`status: "active"`, correct port/new flags)
- [ ] `screenshots/<Sim>.png` committed
- [ ] `docs/assets/<Sim>.webp` committed (or produced by optimize-assets / refresh-screenshots)
- [ ] `docs/index.html` regenerated (`npm run pages`) and committed if it changed
- [ ] `scripts/sync-github-metadata.sh --repo <Sim>` applied

**OpenPhysics** (hand-edited — separate PR)

- [ ] `` `MyNewSim` `` added to the simulation row in `OpenPhysics/README.md` `## Layout`

**`.github` org profile** (hand-edited — separate PR)

- [ ] `` **N** simulations `` count updated in `.github/profile/README.md`
- [ ] Table row added under the correct section (NAAP / PhET / Other)

**Baton prose** (optional but recommended when the public count matters)

- [ ] Scope blockquote in `CONVENTIONS.md` and `ACCESSIBILITY.md` (`N sims`, date)

**Verify**

- [ ] Card appears under the right section on a local `docs/index.html` preview
- [ ] After Baton `main` deploy, card appears on https://openphysics.github.io/Baton/
- [ ] Card links to https://openphysics.github.io/\<Sim\>/
