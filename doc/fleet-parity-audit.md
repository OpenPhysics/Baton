# SceneryStack Fleet Parity Audit

**Date:** 2026-07-19 · **Scope:** 24 active SceneryStack simulations + `TemplateSingleSim` ·
**Mode:** refresh of the 2026-07-18 audit · **Basis:** `Baton/CONVENTIONS.md` +
`Baton/scripts/check-repo-compliance.sh`

> Prior drafts covered 19–20 sims. The 2026-07-18 refresh folded in **BasicCoordinatesAndSeasons**,
> **HabitableZones**, **LightPropagation**, **MotionsOfTheSun**, **SternGerlach**, and **Zenith**.
> This pass corrects the leak-suite inventory and records the 2026-07-19 alignment fixes.

## Executive summary

The fleet remains in **strong, uniform health** on structure and toolchain:

| Gate | Status |
|---|---|
| Package pins (`vite ^8`, `typescript ^7`, `vitest ^4`, `biome ^2.5.4`, `scenerystack ^3`) | Identical across all 24 sims |
| `engines.node` | `>=22` everywhere |
| `.github/workflows/ci.yml` / `deploy.yml` | Bit-identical across the fleet |
| Org Pages screenshots | All 24 sims have `assets/screenshot.png` + Baton card thumbs |
| Memory-leak suite (`tests/memory-leak.test.ts` + `--expose-gc`) | Present on all 24 sims + template |
| Compliance gate | Passes (nested `*Constants.ts` / color carve-outs documented in CLAUDE.md) |

**2026-07-19 alignment fixes:**

1. **SternGerlach** — README six-section outline (dropped extra `## Documentation`); renamed
   `SimDialog` → `SternGerlachDialog`; `Number.toFixed` → `toFixed` from `scenerystack/dot`.
2. **MotionsOfTheSun** — `toFixed` for degree readouts.
3. **tsconfig** — `noImplicitOverride` / `allowUnreachableCode` / `allowUnusedLabels` restored on
   BasicCoordinatesAndSeasons, HabitableZones, LightPropagation, MotionsOfTheSun.
4. **CONVENTIONS.md** — scope points at the catalog (24 sims); §5 tests are fleet-standard (not
   optional), with a documented `setup.ts` carve-out for jsdom/node pure-math suites.

**2026-07-18 workstreams completed:**

1. **Memory-leak pattern** — `tests/memory-leak.test.ts` + `vitest` `--expose-gc` on
   **all** active SceneryStack sims (TimeModel / MazeGameModel / ListenerTracker /
   NumberProperty dispose harnesses).
2. **Baseline + deepened unit tests** — smoke suites for former zero-test sims; extra
   physics invariants on MovingMan, TheRamp, LunarLander, LadyBug, RadioWaves, OC spring.
3. **Docs / legal / conventions** — SECURITY, CREDITS, CODEOWNERS (no local LICENSE — org default); README/CLAUDE
   Testing parity; testing skill refresh; doc-freshness re-audit; this parity refresh.
4. **Accessibility** — WaveComposer `pdomOrder`; OC `a11y` rename; Layer-3 keyboard-drag
   pairing on primary play-area objects (see a11y audit).
5. **Template fuzz + Pages thumbs** — TemplateSingleSim Playwright fuzz smoke;
   Baton `refresh-screenshots.yml` weekly/manual PR workflow.

## §0 Inventory (test files)

`tests` = count of `tests/**/*.test.ts`; `leak` = whether `tests/memory-leak.test.ts` is present.

| Repo | Kind | Test files | Leak suite |
|---|---|---|---|
| BasicCoordinatesAndSeasons | NAAP | 9 | ✅ |
| DopplerEffect | new | 3 | ✅ |
| ElectricFieldOfDreams | PhET | 2 | ✅ |
| ExtrasolarPlanets | NAAP | 8 | ✅ |
| HabitableZones | NAAP | 5 | ✅ |
| LadyBug | PhET | 2 | ✅ |
| LightPropagation | new | 7 | ✅ |
| LunarLander | PhET | 2 | ✅ |
| MazeGame | PhET | 3 | ✅ |
| MotionsOfTheSun | NAAP | 14 | ✅ |
| MovingMan | PhET | 2 | ✅ |
| OpticsLab | new | 2 | ✅ |
| OscillationsAndChaos | new | 2 | ✅ |
| QubitSketch | new | 1 | ✅ |
| RadioWaves | PhET | 2 | ✅ |
| Resonance | new | 14 | ✅ |
| RotatingSky | NAAP | 6 | ✅ |
| SolarSystemModels | NAAP | 4 | ✅ |
| SternGerlach | new | 14 | ✅ |
| TemplateSingleSim | template | 2 | ✅ |
| TheRamp | PhET | 2 | ✅ |
| TrackLab | tool | 2 | ✅ |
| VariableStarPhotometry | NAAP | 3 | ✅ |
| WaveComposer | new | 13 | ✅ |
| Zenith | new | 15 | ✅ |

## §1 Remaining polish (non-blocking)

| Item | Severity | Notes |
|---|---|---|
| Deferred a11y chrome (palette previews, video/axis resize, analyzer bars) | Cosmetic | Documented out-of-scope in ACCESSIBILITY.md + a11y audit |
| OscillationsAndChaos extract `*ScreenSummaryContent.ts` | Cosmetic | Behavior already correct |
| Template Playwright fuzz not in default CI | Cosmetic | `npm run test:fuzz` / `test:fuzz:quick` available locally |
| Live `currentDetailsContent` on a few shared summaries | Minor | Spot-check DerivedProperty usage |
| Native `Number.toFixed` elsewhere (e.g. Zenith readouts) | Minor | Prefer `toFixed` from `scenerystack/dot` when touching those files |

**Resolved 2026-07-18 (follow-up):** root `LICENSE` removed (org default); graph pan +
secondary keyboard drag; deepened model-layer leak suites; nested-constants / color
carve-outs documented in per-sim `CLAUDE.md`.

**Resolved 2026-07-19:** SternGerlach README compliance; `SternGerlachDialog` rename;
`toFixed` on SternGerlach + MotionsOfTheSun; four NAAP tsconfigs; CONVENTIONS scope + §5.

## §2 Best-practice harvest

- **OpticsLab / QubitSketch → fleet:** deep vs. compact `memory-leak.test.ts` patterns.
- **TemplateSingleSim → fleet:** baseline `TimeModel` leak suite + `--expose-gc` vitest config.
- **Resonance → fleet:** densest physics unit-test suite.
- **WaveComposer → fleet:** shared `BaseAnalysisScreenView.establishPdomOrder` for multi-screen shells.

## §3 Related docs

- [`doc-freshness-audit.md`](./doc-freshness-audit.md) — doc/code claim mismatches (2026-07-18)
- [`fleet-a11y-audit.md`](./fleet-a11y-audit.md) — accessibility checklist (2026-07-18)
- [`CONVENTIONS.md`](../CONVENTIONS.md) · [`ACCESSIBILITY.md`](../ACCESSIBILITY.md)

<sub>Re-run per sim: `npm run check && npm run lint && npm run build && npm test`, plus
`bash Baton/scripts/check-repo-compliance.sh <SimDir>` from the workspace root.</sub>
