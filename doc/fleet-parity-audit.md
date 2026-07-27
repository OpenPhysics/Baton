# SceneryStack Fleet Parity Audit

**Date:** 2026-07-27 · **Scope:** 27 active SceneryStack simulations + `TemplateSingleSim` ·
**Mode:** refresh of the 2026-07-19 audit · **Basis:** `Baton/CONVENTIONS.md` +
`Baton/scripts/check-repo-compliance.sh` · **Catalog:** `structure/repos.json`
(13 original · 7 PhET · 7 NAAP)

> Prior drafts covered 19–24 sims. The 2026-07-19 pass folded in
> **BasicCoordinatesAndSeasons**, **HabitableZones**, **LightPropagation**, **MotionsOfTheSun**,
> **SternGerlach**, and **Zenith**. This refresh adds **Oscilloscope**, **Precession**, and
> **ACPhasor**, re-runs the compliance gate, and updates the test / leak inventory.

## Executive summary

The fleet remains in **strong, uniform health** on structure and toolchain:

| Gate | Status |
|---|---|
| Package pins (`vite ^8.1.5`, `typescript ^7.0.2`, `vitest ^4.1.10`, `@biomejs/biome ^2.5.5`, `scenerystack ^3.0.0`) | Identical across all 27 sims + template |
| `engines.node` | `>=22.0.0` everywhere |
| `.github/workflows/ci.yml` / `deploy.yml` | Bit-identical to `TemplateSingleSim` across the fleet |
| Org Pages screenshots | All 27 sims have `assets/screenshot.png` + Baton card thumbs (`screenshots/*.png` + `docs/assets/*.webp`) |
| Memory-leak suite (`tests/memory-leak.test.ts` + `--expose-gc`) | Present on all 27 sims + template |
| Legal / meta docs | `SECURITY.md`, `CREDITS.md`, `.github/CODEOWNERS` on every sim + template |
| Compliance gate (structure / README / a11y scaffolding / GitHub security) | Passes on all 27 sims + template (documented color WARN carve-outs only) |

**2026-07-27 follow-ups (done this pass):**

1. **Oscilloscope**, **Precession**, **ACPhasor** — enabled Dependabot security updates + secret
   scanning on GitHub (vulnerability alerts were already on).
2. **Precession** — moved gyroscope scene fills into `RigidBodyPrecessionColors`
   (`sceneGroundColorProperty`, `sceneInsetCardColorProperty`).
3. **ACPhasor** — catalog + Pages assets already on `main`; finished hand-edited tallies
   (CONVENTIONS / ACCESSIBILITY / org profile / OpenPhysics README) and documented IEC resistor
   band-color carve-out in `CLAUDE.md`.

**Resolved since 2026-07-19 (spot-check):**

- OscillationsAndChaos `*ScreenSummaryContent.ts` extraction — done (per-screen classes).
- Native `Number.toFixed` — none found under `src/` on the prior 26-sim set + template.
- Package pin drift — biome advanced to `^2.5.5` fleet-wide (was `^2.5.4` in the prior note).

## §0 Inventory (test files)

`tests` = count of `tests/**/*.test.ts`; `leak` = whether `tests/memory-leak.test.ts` is present.

| Repo | Kind | Test files | Leak suite |
|---|---|---|---|
| ACPhasor | new | 7 | ✅ |
| BasicCoordinatesAndSeasons | NAAP | 9 | ✅ |
| DopplerEffect | new | 3 | ✅ |
| ElectricFieldOfDreams | PhET | 3 | ✅ |
| ExtrasolarPlanets | NAAP | 9 | ✅ |
| HabitableZones | NAAP | 5 | ✅ |
| LadyBug | PhET | 2 | ✅ |
| LightPropagation | new | 8 | ✅ |
| LunarLander | PhET | 2 | ✅ |
| MazeGame | PhET | 3 | ✅ |
| MotionsOfTheSun | NAAP | 14 | ✅ |
| MovingMan | PhET | 2 | ✅ |
| OpticsLab | new | 4 | ✅ |
| OscillationsAndChaos | new | 2 | ✅ |
| Oscilloscope | new | 15 | ✅ |
| Precession | new | 6 | ✅ |
| QubitSketch | new | 7 | ✅ |
| RadioWaves | PhET | 2 | ✅ |
| Resonance | new | 14 | ✅ |
| RotatingSky | NAAP | 6 | ✅ |
| SolarSystemModels | NAAP | 4 | ✅ |
| SternGerlach | new | 14 | ✅ |
| TemplateSingleSim | template | 2 | ✅ |
| TheRamp | PhET | 2 | ✅ |
| TrackLab | new | 8 | ✅ |
| VariableStarPhotometry | NAAP | 3 | ✅ |
| WaveComposer | new | 13 | ✅ |
| Zenith | new | 21 | ✅ |

Notable test-suite growth since 2026-07-19: ElectricFieldOfDreams 2→3, ExtrasolarPlanets 8→9,
LightPropagation 7→8, OpticsLab 2→4, QubitSketch 1→7, TrackLab 2→8, Zenith 15→21; plus new
rows for Oscilloscope (15), Precession (6), and ACPhasor (7).

## §1 Remaining polish (non-blocking)

| Item | Severity | Notes |
|---|---|---|
| Deferred a11y chrome (palette previews, video/axis resize, analyzer bars) | Cosmetic | Documented out-of-scope in ACCESSIBILITY.md + a11y audit |
| Template Playwright fuzz not in default CI | Cosmetic | `npm run test:fuzz` / `test:fuzz:quick` available locally |
| Live `currentDetailsContent` on a few shared summaries | Minor | Spot-check DerivedProperty usage |
| `fleet-a11y-audit.md` / `doc-freshness-audit.md` still dated 2026-07-18 | Docs | Re-run on next a11y / freshness pass (matrix missing newest sims) |

**Resolved earlier (kept for history):**

- **2026-07-18:** memory-leak pattern fleet-wide; SECURITY / CREDITS / CODEOWNERS; README/CLAUDE
  Testing parity; WaveComposer `pdomOrder`; OC `a11y` rename; Layer-3 keyboard-drag pairing.
- **2026-07-19:** SternGerlach README compliance; `SternGerlachDialog` rename; `toFixed` on
  SternGerlach + MotionsOfTheSun; four NAAP tsconfigs; CONVENTIONS scope + §5.
- **2026-07-27:** OC screen-summary extract; no remaining native `Number.toFixed` under `src/`;
  GitHub security settings on Oscilloscope / Precession / ACPhasor; Precession scene colors;
  ACPhasor hand-edited tallies + resistor carve-out.

## §2 Best-practice harvest

- **OpticsLab / QubitSketch → fleet:** deep vs. compact `memory-leak.test.ts` patterns.
- **TemplateSingleSim → fleet:** baseline `TimeModel` leak suite + `--expose-gc` vitest config.
- **Resonance / Oscilloscope / Zenith → fleet:** densest unit-test suites (14 / 15 / 21 files).
- **WaveComposer → fleet:** shared `BaseAnalysisScreenView.establishPdomOrder` for multi-screen shells.
- **Oscilloscope → fleet:** documented transparent hit-fill carve-out pattern in `CLAUDE.md`.
- **ACPhasor → fleet:** documented IEC-standard color-code carve-out (not themeable UI).

## §3 Related docs

- [`doc-freshness-audit.md`](./doc-freshness-audit.md) — doc/code claim mismatches (still dated 2026-07-18)
- [`fleet-a11y-audit.md`](./fleet-a11y-audit.md) — accessibility checklist (still dated 2026-07-18)
- [`add-simulation.md`](./add-simulation.md) — onboarding + hand-edited count locations
- [`CONVENTIONS.md`](../CONVENTIONS.md) · [`ACCESSIBILITY.md`](../ACCESSIBILITY.md)

<sub>Re-run per sim: `npm run check && npm run lint && npm run build && npm test`, plus
`bash Baton/scripts/check-repo-compliance.sh <SimDir>` from the workspace root.</sub>
