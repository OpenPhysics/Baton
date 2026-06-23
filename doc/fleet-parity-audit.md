# SceneryStack Fleet Parity Audit

**Date:** 2026-06-23 · **Scope:** 14 SceneryStack simulations + `TemplateSingleSim` ·
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

The fleet is in **strong, uniform health**. All 15 in-scope repos pass the Baton compliance
gate, `tsc` type-check, `biome` lint (exit 0), and a production `vite build` — with zero
version drift (`scenerystack@^3` everywhere), zero `Property<any>`, zero lodash
`merge`/`_.extend`, zero stray co-located tests, and filled `doc/model.md` +
`implementation-notes.md` in every repo. GitHub security posture (Dependabot alerts/updates,
secret scanning) is enabled fleet-wide. The reference implementations to emulate are
**`WaveComposer`** and **`DopplerEffect`** (both 24/24, fully green, well-documented), with
**`TemplateSingleSim`** as the canonical scaffold and **`Resonance`** (449 passing unit tests)
and **`OscillationsAndChaos`** (granular, well-factored constants modules) worth harvesting
from. The three systemic gaps are: (1) **memory-leak verification is thin** — only 5 sims ship
tests and **OpticsLab's own leak-regression suite is currently red** (detector views not
collected after dispose), the fleet's single Major functional bug; (2) **advisory lint debt**
is uneven — five sims carry warn-level Biome warnings (OscChaos 375, Resonance 264, QubitSketch
46, TrackLab 4, MazeGame 2), predominantly `noNonNullAssertion`; (3) **QubitSketch is the
weakest sim** — dynamic drag-drop nodes with no `dispose()` and no leak test, no `*Constants.ts`
file, and the most warnings per LOC. None of these block builds or the compliance gate.

**Legend:** ✅ compliant · ⚠️ partial/minor · ❌ missing/broken · N/A not applicable.
Repo codes: `DE` DopplerEffect · `EFD` ElectricFieldOfDreams · `LB` LadyBug · `LL` LunarLander ·
`MG` MazeGame · `MM` MovingMan · `OL` OpticsLab · `OC` OscillationsAndChaos · `QS` QubitSketch ·
`RW` RadioWaves · `RES` Resonance · `TPL` TemplateSingleSim · `RMP` TheRamp · `TL` TrackLab ·
`WC` WaveComposer.

---

## §0 Inventory

All 15 in-scope repos are present under `/home/veillette/OpenPhysics/`, each with
`package.json`, `tsconfig.json`, `node_modules`, `CLAUDE.md`, and `.github/workflows/ci.yml`.
Out of scope per `CONVENTIONS.md`: `Baton`, `.github`, `jscd48`, `tscd48`, `pycd48`, `pyro`.

| Repo | Kind | Screens | Tests | scenerystack |
|---|---|---|---|---|
| DopplerEffect | new sim | 1 | — | ^3.0.0 |
| ElectricFieldOfDreams | PhET port | 1 | — | ^3.0.0 |
| LadyBug | PhET port | 1 | — | ^3.0.0 |
| LunarLander | PhET port | 1 | — | ^3.0.0 |
| MazeGame | PhET port | 1 | ✅ 8 | ^3.0.0 |
| MovingMan | PhET port | 2 | — | ^3.0.0 |
| OpticsLab | new sim | 1 | ❌ 6 fail / 386 pass | ^3.0.0 |
| OscillationsAndChaos | new sim | 4 | — | ^3.0.0 |
| QubitSketch | new sim | 1 | — | ^3.0.0 |
| RadioWaves | PhET port | 1 | — | ^3.0.0 |
| Resonance | new sim | 4 | ✅ 449 | ^3.0.0 |
| TemplateSingleSim | template | — | ✅ 5 | ^3.0.0 |
| TheRamp | PhET port | 2 | — | ^3.0.0 |
| TrackLab | new sim (tool) | — | — | ^3.0.0 |
| WaveComposer | new sim | 3 | ✅ 44 | ^3.0.0 |

---

## §1 Per-repo snapshots

Automated results: `compliance` = `check-repo-compliance.sh`; `check` = `tsc --noEmit`
(both tsconfigs); `lint` = `biome check .`; `build` = `tsc && vite build`; `test` = `npm test`.
**All 15 are green on compliance / check / lint(exit) / build.** Only deltas are noted.

<details><summary>DopplerEffect — 24/24, fully green</summary>

Compliance PASS · check/lint/build green · no tests. Namespace at root, `DopplerEffectColors.ts`,
`DopplerEffectConstants.ts` (in screen `model/`). `stepTimer.setTimeout` used (correct axon
pattern, not a raw timer). 0 Biome warnings. CLAUDE.md 35 lines / 6 sections.
</details>

<details><summary>ElectricFieldOfDreams — 23.5/24</summary>

All green; 0 Biome warnings. ⚠️ CLAUDE.md thin (29 lines / 5 sections) — verify it documents
model props and deviations. Colors + Constants present.
</details>

<details><summary>LadyBug — 23.5/24</summary>

All green; 0 Biome warnings. ⚠️ CLAUDE.md thin (29 lines / 5 sections).
</details>

<details><summary>LunarLander — 24/24, fully green</summary>

All green; 0 Biome warnings. CLAUDE.md 35 lines / 6 sections. Colors + Constants present.
</details>

<details><summary>MazeGame — 23.5/24</summary>

All green; tests ✅ 8/8. Uses `optionize` extensively (15 sites). ⚠️ 2 Biome warnings
(`useExplicitType`, warn-level). `MazeGameLayoutConstants.ts` present. ScreenView extends
`ScreenView` (layoutBounds inherited; positions via layout containers — fine). 30 links / 58
dispose — well balanced. `stepTimer.setTimeout` (correct).
</details>

<details><summary>MovingMan — 23.5/24</summary>

All green; 0 Biome warnings. ⚠️ CLAUDE.md thin (31 lines / 5 sections). Colors + Constants present.
</details>

<details><summary>OpticsLab — 23.5/24, but carries the fleet's only Major bug</summary>

Compliance/check/lint/build green; structurally excellent (71 `.register` calls, 11 `dispose()`,
20 `disposeEmitter`, `OpticsLabConstants.ts`, 386 passing tests). ❌ **`npm test` fails: 6 of 392
tests red, all in `tests/memory-leak.test.ts` — the `detector` view is not garbage-collected
after `dispose()`** (a retained `keyboardDragListener` on `curvatureDragListener`, and 3 leaked
`detector` objects on the bulk create/dispose cycle). 0 Biome warnings. `window.setTimeout(…, 0)`
in `SceneSVGExporter.ts:284` is a one-shot blob-URL revoke (benign). CLAUDE.md 60 lines / 8 sections.
</details>

<details><summary>OscillationsAndChaos — 23.5/24</summary>

All green (4 screens, 48 `.register`). ⚠️ **375 warn-level Biome warnings** (sampled:
`noNonNullAssertion`). Exceptionally well-factored constants — 10 granular modules
(`UILayoutConstants`, `FontSizeConstants`, `VectorScaleConstants`, …). Raw hex in
`*ScreenIcon.ts` files (icon carve-out). 122 links / 3 dispose, but nodes are screen-lifetime.
CLAUDE.md 45 lines.
</details>

<details><summary>QubitSketch — 21.5/24, weakest sim</summary>

Compliance/check/lint/build green. ❌ **No `*Constants.ts` file** — magic numbers inlined
(`MARGIN=20`, `BUTTON_SIZE=28`, `READOUT_WIDTH=80` in `CircuitScreenView.ts:31,208-211`).
⚠️ **Dynamic nodes without disposal**: `GatePalettePanel` adds/removes preview & tooltip nodes
at runtime (`dragLayer`/`overlayLayer` `addChild`/`removeChild`) but the sim has **0 `dispose()`
overrides / 0 `disposeEmitter`** and ships no leak test. ⚠️ 46 Biome warnings (18
`noNonNullAssertion` + 2 `noExcessiveCognitiveComplexity`). CLAUDE.md 53 lines / 9 sections (good).
</details>

<details><summary>RadioWaves — 23.5/24</summary>

All green; 0 Biome warnings. ⚠️ CLAUDE.md thin (30 lines / 5 sections). Raw hex in
`BackgroundSceneNode.ts:118-119` canvas `addColorStop` gradient (minor — canvas fill).
</details>

<details><summary>Resonance — 23/24</summary>

All green; tests ✅ **449/449** (the fleet's largest suite, incl. fuzz). ⚠️ **264 warn-level
Biome warnings** (`noNonNullAssertion`, `useExplicitType`, `noExportedImports`). ⚠️ Raw
`requestAnimationFrame` in `chladni-patterns/model/ResonanceCurveCalculator.ts:156,161`
(progressive chunked computation) and `setTimeout` in `ResonanceSonification.ts:199` — justify
in CLAUDE.md or route through `stepTimer`. `ResonanceConstants.ts` present. CLAUDE.md 62 lines.
</details>

<details><summary>TemplateSingleSim — 24/24, canonical scaffold</summary>

All green; tests ✅ 5/5; 0 Biome warnings. Richest CLAUDE.md (114 lines / 14 sections).
`new Text("Sim Template")` is the intended placeholder.
</details>

<details><summary>TheRamp — 24/24, fully green</summary>

All green; 0 Biome warnings; richest tooling (`physics-check`, `verify` scripts).
`RampConstants.ts` present. Raw hex hits are inside `src/assets/images/crate.svg` (asset, not
code). CLAUDE.md 46 lines.
</details>

<details><summary>TrackLab — 23/24 (documented outlier)</summary>

All green (no `build:single`, no tests — documented OpenCV/video/worker exceptions). 14 `dispose()`,
82 links / 119 dispose (well balanced). ⚠️ 4 Biome warnings (`noNonNullAssertion`). ⚠️ Raw
`setInterval`/`setTimeout`/`requestAnimationFrame` in `WebcamPanel.ts`, `AutoTrackerNode.ts`,
`webcam.ts` — **acceptable & documented** (real-time frame capture needs them). CLAUDE.md 49 lines / 9 sections.
</details>

<details><summary>WaveComposer — 24/24, reference sim</summary>

All green; tests ✅ 44/44; 0 Biome warnings. 3 screens, `WaveComposerConstants.ts` +
`preferences/AnalysisConstants.ts`. CLAUDE.md 42 lines / 5 sections.
</details>

---

## §2 Parity matrix

| Convention | DE | EFD | LB | LL | MG | MM | OL | OC | QS | RW | RES | TPL | RMP | TL | WC |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| package.json baseline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| scenerystack ^3 pinned | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| TSC clean | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Biome clean (0 warn) | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ⚠️ | ✅ | ✅ | ⚠️ | ✅ |
| Build passes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bootstrap chain | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Screen-folder layout | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Namespace at src root | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Options (no lodash merge) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Typed Axon properties | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Node dispose pattern | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| layoutBounds in ScreenView | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| i18n (StringManager en/es/fr) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| No hardcoded UI strings | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Constants file | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Colors file (ProfileColor) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Link/unlink balance | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| No raw timers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ⚠️ | ✅ |
| doc/model.md filled | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| doc/implementation-notes.md | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CI workflow (Baton + sec) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CLAUDE.md present & complete | ✅ | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ✅ |
| README six-section outline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tests under tests/ only | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Notes on judgement calls:
- **Node dispose / Link-unlink:** the crude link-vs-unlink ratio is *not* used as a flag —
  single-screen sims legitimately hold screen-lifetime links that need no `unlink`. Cells are
  ⚠️ only where there is concrete dynamic-node churn without disposal (QS) or a failing leak test (OL).
- **Biome clean:** every repo passes `biome check .` (exit 0). ⚠️ marks repos carrying *warn-level*
  advisory warnings; it is not a lint failure.
- **No raw timers:** `stepTimer.setTimeout` is the correct axon pattern (not flagged). TL's raw
  timers are ⚠️ but **documented & acceptable** (video/webcam frame capture). RES's model-side
  `requestAnimationFrame` is the one undocumented case.
- **layoutBounds:** all sims extend joist `ScreenView` (layoutBounds defined by default); MG drives
  layout via containers rather than referencing the literal — functionally compliant.

---

## §3 Ranked action items

### Major

#### OpticsLab — Node dispose pattern (failing leak suite)
**Severity:** Major
**Finding:** `npm test` fails 6/392; all in `tests/memory-leak.test.ts` — the `detector` view is
retained after `dispose()` (a `keyboardDragListener` on `curvatureDragListener` survives, and the
bulk create/dispose cycle leaks 3 `detector` objects).
**Fix:** Audit detector disposal in `src/common/view/detectors/` — ensure `rebuildEmitter`
listeners and all Property links/drag listeners are removed in `dispose()`; re-run `npm test` to green.
**Reference:** `tests/memory-leak.test.ts:487,512`; scenerystack-disposal skill.

#### QubitSketch — Node dispose pattern (dynamic nodes, no disposal, no leak test)
**Severity:** Major
**Finding:** `GatePalettePanel` creates/removes preview and tooltip nodes at runtime
(`dragLayer`/`overlayLayer` `addChild`/`removeChild`), but the sim has no `dispose()` overrides or
`disposeEmitter` and ships no memory-leak test — leaks would go undetected.
**Fix:** Add `dispose()`/`disposeEmitter` teardown to runtime-created nodes; add a
`tests/memory-leak.test.ts` modeled on OpticsLab's.
**Reference:** `src/circuit-screen/view/GatePalettePanel.ts:106,173,188`; scenerystack-disposal skill.

### Minor

#### QubitSketch — Constants file missing
**Severity:** Minor
**Finding:** No `*Constants.ts` module; layout magic numbers inlined (`MARGIN=20`, `BUTTON_SIZE=28`,
`READOUT_WIDTH=80`, `READOUT_HEIGHT=28`).
**Fix:** Add `src/QubitSketchConstants.ts` and hoist the magic values.
**Reference:** `src/circuit-screen/view/CircuitScreenView.ts:31,208-211`; scenerystack-constants skill.

#### ElectricFieldOfDreams / LadyBug / MovingMan / RadioWaves — thin CLAUDE.md
**Severity:** Minor
**Finding:** CLAUDE.md is 29–31 lines and may not capture model properties, gotchas, or documented
deviations (EFD 29, LB 29, RW 30, MM 31).
**Fix:** Expand to cover key model Properties, solver/behavior notes, and any allowed deviation,
per the template's CLAUDE.md.
**Reference:** `TemplateSingleSim/CLAUDE.md` (114 lines); `CONVENTIONS.md` §6.

#### OscillationsAndChaos / Resonance / QubitSketch — Biome warning debt
**Severity:** Minor
**Finding:** Warn-level Biome warnings, mostly `noNonNullAssertion`: OC 375, RES 264, QS 46
(+2 `noExcessiveCognitiveComplexity`). Lint still passes (exit 0).
**Fix:** Replace unjustified `!` with proper narrowing/assertions; split the over-complex functions.
**Reference:** scenerystack-coding-conventions skill (non-null assertions).

#### Resonance — raw rAF/setTimeout in model & sonification
**Severity:** Minor
**Finding:** `requestAnimationFrame` drives progressive computation in a model file, and a raw
`setTimeout` schedules sonification — both bypass the sim step / `stepTimer`.
**Fix:** Route through `stepTimer`, or document the deliberate chunked-computation pattern in CLAUDE.md.
**Reference:** `src/chladni-patterns/model/ResonanceCurveCalculator.ts:156,161`,
`src/chladni-patterns/view/ResonanceSonification.ts:199`; scenerystack-numerics skill.

#### MazeGame / TrackLab — minor Biome warnings
**Severity:** Minor
**Finding:** MG 2 (`useExplicitType`), TL 4 (`noNonNullAssertion`). TL's raw timers are documented
and acceptable.
**Fix:** Add explicit return types (MG); narrow the four `!` sites (TL). Optional.
**Reference:** scenerystack-coding-conventions skill.

#### OscillationsAndChaos / RadioWaves — raw hex in icons/canvas
**Severity:** Minor
**Finding:** Hardcoded hex in `*ScreenIcon.ts` (OC pendulum icons) and a canvas gradient
(`RadioWaves/.../BackgroundSceneNode.ts:118-119`).
**Fix:** Optional — move to a Colors/Constants entry. Screen-icon palettes are a common carve-out.
**Reference:** scenerystack-color-profiles skill.

*(No Blocking items: nothing fails the build or the compliance gate.)*

---

## §4 Scenerystack version drift

**None.** All 15 repos pin `scenerystack@^3.0.0` (a semver caret range, not a git SHA), and TS
strictness is uniform (`strict` + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`).
Fleet standard = `scenerystack@^3`. No action required.

---

## §5 Best-practice harvest

- **TemplateSingleSim → fleet:** the 114-line / 14-section CLAUDE.md is the gold standard for
  sim-specific contributor docs — the thin ports should mirror its structure.
- **Resonance → fleet:** a 449-test suite (unit + fuzz) is the strongest verification in the fleet;
  its memory-leak/fuzz harness is the template QubitSketch and others should copy.
- **OscillationsAndChaos → fleet:** constants split into 10 small intent-named modules
  (`FontSizeConstants`, `VectorScaleConstants`, `UILayoutConstants`, …) — a cleaner pattern than a
  single monolithic `*Constants.ts` for large sims.
- **OpticsLab → fleet:** disciplined disposal infrastructure (20 `disposeEmitter`, 11 `dispose()`)
  **plus a dedicated `memory-leak.test.ts`** that actually catches regressions — the model every
  dynamic sim should adopt (and which OpticsLab itself must now get back to green).
- **TheRamp → fleet:** domain `physics-check` / `verify` scripts that validate the model beyond
  generic check/lint/build.
- **MazeGame → fleet:** consistent `optionize`-based options with balanced dispose (30 links / 58
  teardown) — a good worked example of the `optionize` style from `CONVENTIONS.md` §8.

---

## §6 Summary scorecard

Score = 1 point per matrix row (✅ 1 · ⚠️ 0.5 · ❌ 0), out of 24.

| Rank | Repo | Score / 24 | Blocking | Major | Minor |
|---|---|---|---|---|---|
| 1 | DopplerEffect | 24.0 | 0 | 0 | 0 |
| 1 | LunarLander | 24.0 | 0 | 0 | 0 |
| 1 | TemplateSingleSim | 24.0 | 0 | 0 | 0 |
| 1 | TheRamp | 24.0 | 0 | 0 | 0 |
| 1 | WaveComposer | 24.0 | 0 | 0 | 0 |
| 6 | ElectricFieldOfDreams | 23.5 | 0 | 0 | 1 |
| 6 | LadyBug | 23.5 | 0 | 0 | 1 |
| 6 | MazeGame | 23.5 | 0 | 0 | 1 |
| 6 | MovingMan | 23.5 | 0 | 0 | 1 |
| 6 | OscillationsAndChaos | 23.5 | 0 | 0 | 1 |
| 6 | RadioWaves | 23.5 | 0 | 0 | 1 |
| 6 | OpticsLab | 23.5 | 0 | **1** | 0 |
| 13 | Resonance | 23.0 | 0 | 0 | 2 |
| 13 | TrackLab | 23.0 | 0 | 0 | 1* |
| 15 | QubitSketch | 21.5 | 0 | **1** | 2 |

\* TrackLab's raw-timer ⚠️ is documented/acceptable; its only actionable item is 4 Biome warnings.

> **Caveat on ranks:** the per-row score rewards structural conformance, so OpticsLab sits at
> 23.5 despite carrying the fleet's only Major functional bug (red leak tests). Read the
> Blocking/Major/Minor columns alongside the score: **OpticsLab (fix the leak suite) and QubitSketch
> (add disposal + a Constants file + a leak test) are the two repos that actually need work**, even
> though their numeric scores are mid-pack. Everything else is polish-level.

---

<sub>Generated read-only from local working copies on 2026-06-23. Re-run the underlying checks with
`npm run check && npm run lint && npm run build && npm test` per repo, and
`bash Baton/scripts/check-repo-compliance.sh <SimDir>` for the structural gate.</sub>
