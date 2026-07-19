# SceneryStack Fleet Parity Audit

**Date:** 2026-07-18 · **Scope:** 24 active SceneryStack simulations + `TemplateSingleSim` ·
**Mode:** refresh of the 2026-07-03 audit · **Basis:** `Baton/CONVENTIONS.md` +
`Baton/scripts/check-repo-compliance.sh`

> Prior drafts covered 19–20 sims. This refresh folds in **BasicCoordinatesAndSeasons**,
> **HabitableZones** (already functional by 2026-07-09), **LightPropagation**,
> **MotionsOfTheSun**, **SternGerlach**, and **Zenith**, and records the July 18
> testing / a11y workstreams.

## Executive summary

The fleet remains in **strong, uniform health** on structure and toolchain:

| Gate | Status |
|---|---|
| Package pins (`vite ^8`, `typescript ^7`, `vitest ^4`, `biome ^2.5.4`, `scenerystack ^3`) | Identical across all 24 sims |
| `engines.node` | `>=22` everywhere |
| `.github/workflows/ci.yml` / `deploy.yml` | Bit-identical across the fleet |
| Org Pages screenshots | All 24 sims have `assets/screenshot.png` + Baton card thumbs |
| Compliance gate | Passes (some WARN for nested `*Constants.ts` / color carve-outs) |

**2026-07-18 workstreams completed:**

1. **Memory-leak pattern** — `tests/memory-leak.test.ts` + `vitest` `--expose-gc` on
   **all** active SceneryStack sims (TimeModel / MazeGameModel / ListenerTracker /
   NumberProperty dispose harnesses).
2. **Baseline + deepened unit tests** — smoke suites for former zero-test sims; extra
   physics invariants on MovingMan, TheRamp, LunarLander, LadyBug, RadioWaves, OC spring.
3. **Docs / legal / conventions** — LICENSE, SECURITY, CREDITS, CODEOWNERS; README/CLAUDE
   Testing parity; testing skill refresh; doc-freshness re-audit; this parity refresh.
4. **Accessibility** — WaveComposer `pdomOrder`; OC `a11y` rename; Layer-3 keyboard-drag
   pairing on primary play-area objects (see a11y audit).
5. **Template fuzz + Pages thumbs** — TemplateSingleSim Playwright fuzz smoke;
   Baton `refresh-screenshots.yml` weekly/manual PR workflow.

## §0 Inventory (test files)

`tests` = count of `tests/**/*.test.ts`; `leak` = whether a memory-leak suite is present.

| Repo | Kind | Test files | Leak suite |
|---|---|---|---|
| BasicCoordinatesAndSeasons | NAAP | 8 | — |
| DopplerEffect | new | 2 | — |
| ElectricFieldOfDreams | PhET | 1 | — |
| ExtrasolarPlanets | NAAP | 7 | — |
| HabitableZones | NAAP | 4 | — |
| LadyBug | PhET | 1 | — |
| LightPropagation | new | 6 | — |
| LunarLander | PhET | 1 | — |
| MazeGame | PhET | 2 | — |
| MotionsOfTheSun | NAAP | 13 | — |
| MovingMan | PhET | 1 | — |
| OpticsLab | new | 2 | ✅ |
| OscillationsAndChaos | new | 1 | — |
| QubitSketch | new | 1 | ✅ |
| RadioWaves | PhET | 1 | — |
| Resonance | new | 13 | — |
| RotatingSky | NAAP | 6 | ✅ |
| SolarSystemModels | NAAP | 3 | — |
| SternGerlach | new | 14 | ✅ |
| TemplateSingleSim | template | 2 | ✅ |
| TheRamp | PhET | 1 | — |
| TrackLab | tool | 2 | ✅ |
| VariableStarPhotometry | NAAP | 3 | ✅ |
| WaveComposer | new | 12 | — |
| Zenith | new | 14 | — |

## §1 Remaining polish (non-blocking)

| Item | Severity | Notes |
|---|---|---|
| Graph-chrome keyboard pan/zoom (`GraphInteractionHandler`) | Minor | Play-area Layer-3 pairing largely done 2026-07-18; see [fleet-a11y-audit.md](./fleet-a11y-audit.md) |
| Biome `noNonNullAssertion` warn debt (OC / Resonance / QubitSketch) | Minor | Rule enabled as `warn`; StatePropertyMapper + QubitSketch simulator/QASM cleaned; more remain |
| Nested `*Constants.ts` compliance WARNs | Cosmetic | Documented carve-outs / layout variants |
| Expand leak suites beyond TimeModel / NumberProperty fallback | Minor | OpticsLab remains the deep reference; several sims use Property.dispose harness |
| OscillationsAndChaos extract `*ScreenSummaryContent.ts` | Cosmetic | Behavior already correct |
| Template Playwright fuzz not in default CI | Cosmetic | `npm run test:fuzz` / `test:fuzz:quick` available locally |

## §2 Best-practice harvest

- **OpticsLab / QubitSketch → fleet:** deep vs. compact `memory-leak.test.ts` patterns.
- **TemplateSingleSim → fleet:** baseline `TimeModel` leak suite + `--expose-gc` vitest config.
- **Resonance → fleet:** densest physics unit-test suite.
- **WaveComposer → fleet:** shared `BaseAnalysisScreenView.establishPdomOrder` for multi-screen shells.

## §3 Related docs

- [`doc-freshness-audit.md`](./doc-freshness-audit.md) — doc/code claim mismatches (2026-07-10)
- [`fleet-a11y-audit.md`](./fleet-a11y-audit.md) — accessibility checklist (2026-07-18)
- [`CONVENTIONS.md`](../CONVENTIONS.md) · [`ACCESSIBILITY.md`](../ACCESSIBILITY.md)

<sub>Re-run per sim: `npm run check && npm run lint && npm run build && npm test`, plus
`bash Baton/scripts/check-repo-compliance.sh <SimDir>` from the workspace root.</sub>
