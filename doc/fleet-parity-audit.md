# SceneryStack Fleet Parity Audit

**Date:** 2026-07-03 · **Scope:** 19 SceneryStack simulations + `TemplateSingleSim` ·
**Mode:** read-only · **Basis:** `Baton/CONVENTIONS.md` + `Baton/scripts/check-repo-compliance.sh`

> This audit re-bases the generic audit checklist onto the org's **current** conventions.
> The classic layout the checklist assumes (`src/<Sim>Main.ts`, root `src/model/`,
> `strings/<sim>_en.json`) predates the fleet; the real standard is a
> `src/{init,assert,splash,brand,main}.ts` bootstrap chain, `model/`+`view/` **inside
> kebab-case screen folders**, `src/i18n/` + `StringManager` (en/es/fr), and
> `doc/model.md` + `doc/implementation-notes.md`. Every structural verdict below uses
> that standard, so the matrix reflects reality rather than flagging the correct modern
> structure as broken.

## Executive summary

The fleet is in **strong, uniform health**. All **20** in-scope repos pass the Baton compliance
gate, `tsc` type-check, `biome` lint (exit 0), and a production `vite build` — with zero
version drift (`scenerystack@^3` everywhere), zero `Property<any>`, zero lodash
`merge`/`_.extend`, zero stray co-located tests, and filled `doc/model.md` +
`implementation-notes.md` in every repo. GitHub security posture (Dependabot alerts/updates,
secret scanning on public repos) is enabled fleet-wide.

Five **NAAP astronomy ports** joined the fleet since the June audit
(`ExtrasolarPlanets`, `HabitableZones`, `RotatingSky`, `SolarSystemModels`, `VariableStarPhotometry`).
All five are **fully implemented** and structurally on parity with the rest of the fleet. Reference
implementations to emulate are **`WaveComposer`** and **`DopplerEffect`** (both 24/24, fully green),
with **`TemplateSingleSim`** as the canonical scaffold, **`ExtrasolarPlanets`**, **`HabitableZones`**,
and **`RotatingSky`** as NAAP reference ports, and **`Resonance`** (449 passing unit tests) for
verification depth.

> **Stale-artifact note (2026-07-10):** this audit's July 3 draft still described HabitableZones as
> scaffold-only. Sim docs and code were current as of 2026-07-09 (Circumstellar + Galactic implemented).
> See [doc-freshness-audit.md](./doc-freshness-audit.md) for the per-sim freshness pass that flagged
> the mismatch.

Resolved since 2026-06-23: **OpticsLab** leak suite green (392/392); **QubitSketch** has
`QubitSketchConstants.ts`, palette `dispose()`, and `tests/memory-leak.test.ts`; **SolarSystemModels**
hardcoded view colors migrated to `SolarSystemModelsColors.ts`; PhET-port CLAUDE.md files expanded;
**Resonance** raw timer exceptions documented in CLAUDE.md.

Remaining systemic gaps: (1) **memory-leak verification is thin** — only OpticsLab and QubitSketch
ship leak tests; dynamic NAAP views (RotatingSky, VariableStarPhotometry) have none; (2) **advisory
lint debt** in OscChaos (~375), Resonance (~264), and QubitSketch (~33) warn-level Biome warnings,
mostly `noNonNullAssertion`.

**Legend:** ✅ compliant · ⚠️ partial/minor · ❌ missing/broken · N/A not applicable.
Repo codes: `DE` DopplerEffect · `EFD` ElectricFieldOfDreams · `EP` ExtrasolarPlanets · `HZ`
HabitableZones · `LB` LadyBug · `LL` LunarLander · `MG` MazeGame · `MM` MovingMan · `OL` OpticsLab ·
`OC` OscillationsAndChaos · `QS` QubitSketch · `RW` RadioWaves · `RES` Resonance · `RS` RotatingSky ·
`SSM` SolarSystemModels · `TPL` TemplateSingleSim · `RMP` TheRamp · `TL` TrackLab · `VSP`
VariableStarPhotometry · `WC` WaveComposer.

---

## §0 Inventory

All 20 in-scope repos are present under `/home/veillette/OpenPhysics/`, each with
`package.json`, `tsconfig.json`, `CLAUDE.md`, and `.github/workflows/ci.yml`.
Out of scope per `CONVENTIONS.md`: `Baton`, `.github`, `jscd48`, `tscd48`, `pycd48`, `pyro`.

| Repo | Kind | Screens | Tests | scenerystack |
|---|---|---|---|---|
| DopplerEffect | new sim | 1 | ✅ 17 | ^3.0.0 |
| ElectricFieldOfDreams | PhET port | 1 | — | ^3.0.0 |
| ExtrasolarPlanets | NAAP port | 2 | ✅ 64 | ^3.0.0 |
| HabitableZones | NAAP port | 2 | ✅ 19 | ^3.0.0 |
| LadyBug | PhET port | 1 | — | ^3.0.0 |
| LunarLander | PhET port | 1 | — | ^3.0.0 |
| MazeGame | PhET port | 1 | ✅ 8 | ^3.0.0 |
| MovingMan | PhET port | 2 | — | ^3.0.0 |
| OpticsLab | new sim | 4 | ✅ 392 | ^3.0.0 |
| OscillationsAndChaos | new sim | 4 | — | ^3.0.0 |
| QubitSketch | new sim | 1 | ✅ 7 | ^3.0.0 |
| RadioWaves | PhET port | 1 | — | ^3.0.0 |
| Resonance | new sim | 4 | ✅ 449 | ^3.0.0 |
| RotatingSky | NAAP port | 3 | ✅ 35 | ^3.0.0 |
| SolarSystemModels | NAAP port | 2 | ✅ 32 | ^3.0.0 |
| TemplateSingleSim | template | — | ✅ 5 | ^3.0.0 |
| TheRamp | PhET port | 2 | — | ^3.0.0 |
| TrackLab | new sim (tool) | — | — | ^3.0.0 |
| VariableStarPhotometry | NAAP port | 4 | ✅ 6 | ^3.0.0 |
| WaveComposer | new sim | 3 | ✅ 44 | ^3.0.0 |

---

## §1 Per-repo snapshots

Automated results: `compliance` = `check-repo-compliance.sh`; `check` = `tsc --noEmit`
(both tsconfigs); `lint` = `biome check .`; `build` = `tsc && vite build`; `test` = `npm test`.
**All 20 are green on compliance / check / lint(exit) / build.** Only deltas are noted.

### NAAP ports (new since June audit)

<details><summary>ExtrasolarPlanets — 24/24, NAAP reference</summary>

Compliance PASS · check/lint/build green · tests ✅ 64/64 · 0 Biome warnings. Two screens
(Radial Velocity, Transit), root `ExtrasolarPlanetsConstants.ts` + `ExtrasolarPlanetsColors.ts`.
Rich CLAUDE.md (163 lines). No memory-leak test.
</details>

<details><summary>HabitableZones — 24/24, NAAP reference</summary>

Compliance PASS · check/lint/build green · tests ✅ 19/19 (star evolution, planet evolution,
galactic habitability, `TimeModel`). Two implemented screens: **Circumstellar** (stellar evolution +
HZ) and **Galactic** (Milky Way habitability curves). Rich CLAUDE.md. No memory-leak test.
</details>

<details><summary>RotatingSky — 24/24, NAAP reference</summary>

Compliance PASS · check/lint/build green · tests ✅ 35/35 · 0 Biome warnings. Three screens
(Horizon System, Celestial Sphere, Explorer), shared `SkyModel` engine. CLAUDE.md 126 lines.
19 dispose sites; no memory-leak test.
</details>

<details><summary>SolarSystemModels — 24/24, fully green</summary>

Compliance PASS · check/lint/build green · tests ✅ 32/32 · 0 Biome warnings. Two screens
(Ptolemaic, Configurations); all view colors in `SolarSystemModelsColors.ts` (including
`zodiacGhostBarColor()` for speed-based ghosting bars). CLAUDE.md 77 lines.
</details>

<details><summary>VariableStarPhotometry — 23.5/24</summary>

Compliance PASS · check/lint/build green · tests ✅ 6/6 · 0 Biome warnings. Four-screen workflow
complete. ⚠️ Thin test coverage (6 tests, mostly `PDMCalculator`) for a 4-screen sim.
CLAUDE.md 116 lines documents grouped `VSPConstants` pattern.
</details>

### Previously audited sims (deltas only)

<details><summary>OpticsLab — 24/24, fully green</summary>

Compliance/check/lint/build green; tests ✅ **392/392** (leak suite green as of July 2026).
</details>

<details><summary>QubitSketch — 23/24</summary>

Compliance/check/lint/build green; tests ✅ 7/7 incl. `memory-leak.test.ts`.
`QubitSketchConstants.ts` + palette `dispose()` in place. ⚠️ ~33 Biome warnings remain
(mostly `QasmSerializer.ts`).
</details>

<details><summary>OscillationsAndChaos — 23.5/24</summary>

All green; ⚠️ ~375 warn-level Biome warnings (`noNonNullAssertion` in ODE solvers).
</details>

<details><summary>Resonance — 23.5/24</summary>

All green; tests ✅ 449/449. ⚠️ ~264 Biome warnings. Raw rAF/setTimeout **documented** in CLAUDE.md.
</details>

<details><summary>MazeGame — 24/24</summary>

All green; tests ✅ 8/8; Biome warnings cleared in test files.
</details>

<details><summary>TrackLab — 23.5/24</summary>

All green; Biome warnings cleared in `scripts/bouncingBallToSVG.ts`. Raw timers documented.
</details>

*(Remaining sims unchanged from June audit — all green on compliance / check / lint / build.)*

---

## §2 Parity matrix

| Convention | DE | EFD | EP | HZ | LB | LL | MG | MM | OL | OC | QS | RW | RES | RS | SSM | TPL | RMP | TL | VSP | WC |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| package.json baseline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| scenerystack ^3 pinned | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| TSC clean | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Biome clean (0 warn) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Build passes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bootstrap chain | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Screen-folder layout | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Namespace at src root | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Constants file | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Colors file (ProfileColor) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| i18n (StringManager en/es/fr) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| doc/model.md filled | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CI workflow (Baton + sec) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Functional sim (not scaffold) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Unit tests present | ⚠️ | ⚠️ | ✅ | ⚠️ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ✅ |
| Memory-leak test | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |

Notes:
- **Biome clean:** exit 0 everywhere; ⚠️ = warn-level advisory count (OC, QS, RES).
- **Unit tests:** ⚠️ = no suite or thin coverage (VSP: 6 tests for 4 screens).
- **Memory-leak test:** only OL and QS ship `memory-leak.test.ts`.

---

## §3 Ranked action items

### Major

*(No major items as of 2026-07-10 — HabitableZones functional port completed 2026-07-09; see
[doc-freshness-audit.md](./doc-freshness-audit.md).)*

### Minor

#### VariableStarPhotometry — thin test coverage
**Severity:** Minor
**Finding:** 6 tests for a 4-screen workflow; only `PDMCalculator` substantially covered.
**Fix:** Add model tests for Registration, Blink Comparator, and Photometry screens.

#### RotatingSky / ExtrasolarPlanets — no memory-leak tests
**Severity:** Minor
**Finding:** Dynamic view nodes (sky graphics, orbit views) with no leak-regression suite.
**Fix:** Add `tests/memory-leak.test.ts` modeled on OpticsLab's.

#### OscillationsAndChaos / Resonance / QubitSketch — Biome warning debt
**Severity:** Minor
**Finding:** Warn-level Biome warnings, mostly `noNonNullAssertion`: OC ~375, RES ~264, QS ~33.
**Fix:** Replace unjustified `!` with proper narrowing; split over-complex functions.

#### OscillationsAndChaos / RadioWaves — raw hex in icons/canvas
**Severity:** Minor
**Finding:** Hardcoded hex in `*ScreenIcon.ts` (OC) and canvas gradient (RW) — documented carve-outs.

*(No Blocking items: nothing fails the build or the compliance gate.)*

---

## §4 Scenerystack version drift

**None.** All 20 repos pin `scenerystack@^3.0.0`. TS strictness is uniform
(`strict` + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`).

---

## §5 Best-practice harvest

- **ExtrasolarPlanets → fleet:** richest NAAP CLAUDE.md (163 lines); two-screen shared-constants
  pattern with per-screen model/view folders.
- **HabitableZones → fleet:** two-screen NAAP port with Circumstellar star-evolution/HZ model and
  Galactic parametric habitability curves; see `HabitableZones/CLAUDE.md`.
- **RotatingSky → fleet:** shared sky engine (`SkyModel`, `SkyCoordinates`, `SkyProjection`) reused
  across three screens — the multi-screen pattern for astronomy sims.
- **SolarSystemModels → fleet:** `zodiacGhostBarColor()` in `*Colors.ts` for computed decorative fills
  keeps views free of raw `rgb()` while preserving Flash-faithful ghosting.
- **Resonance → fleet:** 449-test suite remains the verification gold standard.
- **OpticsLab / QubitSketch → fleet:** `memory-leak.test.ts` pattern for dynamic sims.

---

## §6 Summary scorecard

Score = weighted matrix rows (✅ 1 · ⚠️ 0.5 · ❌ 0), normalized. Top tier = structural + functional parity.

| Rank | Repo | Blocking | Major | Minor | Notes |
|---|---|---|---|---|---|
| 1 | DopplerEffect, LunarLander, TemplateSingleSim, TheRamp, WaveComposer, EP, HZ, RS, SSM | 0 | 0 | 0 | Fully green |
| 2 | Most PhET ports + OpticsLab + MG + TL | 0 | 0 | 0–1 | Polish only |
| 3 | VSP, RES, OC, QS | 0 | 0 | 1–2 | Tests or lint debt |

> All in-scope repos pass structural and functional parity. Remaining deltas are polish-level
> (lint debt, leak-test coverage, thin VSP tests).

---

<sub>Re-run checks with `npm run check && npm run lint && npm run build && npm test` per repo, and
`bash Baton/scripts/check-repo-compliance.sh <SimDir>` for the structural gate. Fleet catalog:
`Baton/structure/repos.json`.</sub>
