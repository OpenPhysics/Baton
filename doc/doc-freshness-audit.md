# Per-Sim Documentation Freshness Audit

**Date:** 2026-07-10 · **Scope:** 20 `isSimulation: true` repos from
[`structure/repos.json`](../structure/repos.json) · **Mode:** identification only
(no doc rewrites) · **Docs in scope:** `README.md`, `CLAUDE.md`, `CREDITS.md` (if
present), and all of `doc/*.md`.

> Compliance (`check-repo-compliance.sh`) and the
> [fleet-parity audit](./fleet-parity-audit.md) already confirm that
> `doc/model.md` / `doc/implementation-notes.md` exist and are non-stubs. This
> pass asks whether that content still **matches the code**.
>
> **Update pass (2026-07-10):** Findings in §4 were applied to the listed sim
> docs, `Baton/structure/repos.json` (OpticsLab screens), and the HabitableZones
> claim in [fleet-parity-audit.md](./fleet-parity-audit.md). This report remains
> the identification record; treat §2 dated claims as historical unless
> re-audited.

## Method

1. **Triage** — inventory markdown; compare last commit touching in-scope docs vs
   `src/` (ignoring TypeScript / Dependabot-only bumps); keyword scan for
   scaffold / placeholder / TODO status claims; screen-count sanity vs catalog.
2. **Spot verification** — for candidates, pin specific claims to contradicting
   code paths. Verdicts: **current** · **dated** · **uncertain**.
3. **Calibration** — HabitableZones, RotatingSky, VariableStarPhotometry (primary
   docs), LunarLander, ElectricFieldOfDreams, RadioWaves, MazeGame, TrackLab, and
   OscillationsAndChaos were spot-checked as mostly current.

**Out of scope for this report:** Almanach, Baton skills/CONVENTIONS, root-level
planning files such as `plan.md` / `PORTING_PLAN.md` (not in the locked doc set),
and updating any sim docs.

**Note on [fleet-parity-audit.md](./fleet-parity-audit.md):** that document still
describes HabitableZones as scaffold-only. HabitableZones **sim docs and code**
are current as of 2026-07-09; the parity audit itself is the stale artifact.

---

## Executive summary

Of **20** catalog simulations:

| Bucket | Count | Sims |
|---|---|---|
| **Suspect (dated claims verified)** | **10** | LightPropagation, OpticsLab, Resonance, MovingMan, LadyBug, TheRamp, QubitSketch, DopplerEffect, WaveComposer, SolarSystemModels |
| **Mostly current** | **10** | HabitableZones, ExtrasolarPlanets, RotatingSky, VariableStarPhotometry, OscillationsAndChaos, LunarLander, ElectricFieldOfDreams, RadioWaves, MazeGame, TrackLab |

Highest educational risk (wrong physics / product status in user-facing or
educator docs):

1. **LightPropagation** — README + CLAUDE still claim all screens are scaffolds with no physics.
2. **Resonance** — `doc/model.md` spring presets and defaults disagree with `ResonancePresets` / constructor.
3. **MovingMan** — `doc/model.md` / `implementation-notes.md` misdescribe Intro charts and wall collisions.
4. **OpticsLab** — README under-documents four screens; several `doc/*` plans/audits superseded; `implementation-notes.md` uses renamed filenames.
5. **LadyBug** — README + `implementation-notes.md` describe a rotatable platform / platform-rotation UI that the port does not implement.

Update pass completed 2026-07-10 (see note under Method).

**Legend:** ✅ current · ⚠️ dated (verified) · ❓ uncertain · — not present

---

## §1 Fleet triage table

`Doc last` / `Src last` = last commit date touching in-scope markdown vs `src/`.
`Substantive after` = commits to `src/` after last doc touch, excluding TypeScript /
dependency bumps. High counts alone do **not** imply stale docs (many are
`optionize` / bugfix commits that leave narrative docs valid).

| Sim | Kind | Doc last | Src last | Substantive after | Triage flags | Overall |
|---|---|---|---|---|---|---|
| DopplerEffect | new | 2026-06-15 | 2026-06-23 | 8 | git drift | ⚠️ |
| ElectricFieldOfDreams | phet | 2026-06-23 | 2026-06-23 | 1 | — | ✅ |
| ExtrasolarPlanets | naap | 2026-07-09 | 2026-07-09 | 1 | prefs “scaffold” (accurate) | ✅ |
| HabitableZones | naap | 2026-07-09 | 2026-07-09 | 1 | — | ✅ |
| LadyBug | phet | 2026-06-23 | 2026-06-23 | 1 | platform wording | ⚠️ |
| LightPropagation | new | 2026-07-06 | 2026-07-06 | 1 | status-kw scaffold | ⚠️ |
| LunarLander | phet | 2026-06-15 | 2026-06-23 | 1 | — | ✅ |
| MazeGame | phet | 2026-07-02 | 2026-06-15 | 0 | — | ✅ |
| MovingMan | phet | 2026-06-23 | 2026-06-23 | 1 | model/impl mismatch | ⚠️ |
| OpticsLab | new | 2026-06-15 | 2026-06-23 | 4 | git drift; catalog screens=1 | ⚠️ |
| OscillationsAndChaos | new | 2026-07-02 | 2026-07-02 | 1 | — | ✅ |
| QubitSketch | new | 2026-06-15 | 2026-06-23 | 5 | dispose/constants lag | ⚠️ |
| RadioWaves | phet | 2026-07-02 | 2026-06-23 | 0 | — | ✅ |
| Resonance | new | 2026-06-23 | 2026-06-23 | 1 | model presets; solvers | ⚠️ |
| RotatingSky | naap | 2026-07-09 | 2026-07-09 | 2 | — | ✅ |
| SolarSystemModels | naap | 2026-07-09 | 2026-07-09 | 4 | impl-notes prefs | ⚠️ |
| TheRamp | phet | 2026-07-02 | 2026-07-02 | 1 | README “scaffold” | ⚠️ |
| TrackLab | new | 2026-07-02 | 2026-06-23 | 0 | catalog `screens: null` OK | ✅ |
| VariableStarPhotometry | naap | 2026-07-09 | 2026-07-09 | 1 | — | ✅ |
| WaveComposer | new | 2026-06-15 | 2026-06-23 | 4 | prefs rename | ⚠️ |

---

## §2 Suspect detail (dated locations)

### LightPropagation — high priority

Physics is implemented (`WaveSceneModel`, four screens in `src/main.ts`, Lab
presets, vitest). Status claims in README/CLAUDE are false.

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `README.md` | ⚠️ | L15: “Each screen is currently a scaffold (placeholder label + Reset All) — physics is not yet implemented.” → e.g. `src/intro/model/IntroModel.ts` composes `WaveSceneModel`; `IntroScreenView` builds real controls. Scripts table incomplete vs `package.json` (`test`, `build:single`, …). Tech stack still says TypeScript ^6; package has `^7.0.2`. |
| `CLAUDE.md` | ⚠️ | L8–9: “All four screens are currently scaffolding … no physics yet.” → same code evidence. Key-file map otherwise matches. |
| `doc/model.md` | ✅ | Matches EMANIM-style equations / Lab presets. |
| `doc/implementation-notes.md` | ✅ | Shared `WaveSceneModel` + screen layout matches `src/`. |

### Resonance — high priority (educator physics)

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `doc/model.md` | ⚠️ | **Spring Presets** (§ “Light and Bouncy” etc.): e.g. doc Light and Bouncy = 0.1 kg / 100 N/m / 0.5 damping; code `ResonancePresets` = 0.5 / 50 / 0.1 (`src/common/model/ResonanceModel.ts` ~1183+). Constructor defaults: doc mass 0.25 kg / damping 0.5 elsewhere vs code `massProperty = 2.53`, `dampingProperty = 1.0` (~191–193). |
| `doc/implementation-notes.md` | ⚠️ | Available Solvers table lists **AdaptiveEulerSolver** and **ModifiedMidpointSolver**; `SolverType.ts` only has RK4, Adaptive RK45, Analytical. |
| `doc/architecture-review.md` | ⚠️ | Dated 2026-02-10. Stale: “443 lines inline preferences” — preferences extracted to `ResonancePreferencesNode`; `main.ts` is much smaller. Empty-subclass notes partly still true. Treat as historical review. |
| `README.md` / `CLAUDE.md` | ✅ | Four-screen map and exceptions align. |

### MovingMan

Two screens registered in `src/main.ts` (Introduction, Charts) under shared
`src/moving-man/` — architecture is fine; physics/UI narrative drifts.

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `doc/model.md` | ⚠️ | Overview: Intro “shows live motion with **rolling chart windows**” → Intro view has play area + controls, not charts (`IntroScreenView`). Charts live on Charts screen. |
| `doc/implementation-notes.md` | ⚠️ | “Chart data uses fixed rolling windows on the **Intro** screen” (same UI mismatch). “Wall collisions **reverse velocity**” → `MovingMan.ts` sets `velocityProperty.value = 0` on wall collide (~331–333); `model.md` correctly says stop-at-boundary. |
| `README.md` / `CLAUDE.md` | ✅ | Two-screen features and wall-zero behavior described accurately. |

### OpticsLab

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `README.md` | ⚠️ | Features omit four screens (Intro, Lab, Presets, Diffraction), gratings, detectors, undo — see `src/main.ts` ~103–131. |
| `doc/implementation-notes.md` | ⚠️ | Still refers to **`SimScreenView.ts` / `SimModel.ts`** and **`vite.config.js`**; code uses `RayTracingCommonView` / `RayTracingCommonModel` and `vite.config.ts`. |
| `doc/model-features-vs-view.md` | ⚠️ | Superseded snapshot (2026-04): claims no undo / unused `CommandHistory`, max depth not wired, detector totals not shown — contradicted by current `RayTracingCommonView` / `DetectorChartPanel`. |
| `doc/phet-io-tandem-plan.md` | ⚠️ | Plan paths use old `SimModel` / `SimScreenView` names; treat as historical. |
| `doc/adversarial-security-review.md` | ⚠️ | Audit dated 2026-04-07; several P0/P1 items fixed since (serialization validation, `sincSquared`, etc.). Do not treat as current threat model. |
| `doc/model.md` | ✅ | Core optics physics still matches. |
| `CLAUDE.md` | ✅ / minor | Four-screen shared-view story is largely right. |
| *Catalog* | ⚠️ | `repos.json` `"screens": ["Optics Lab"]` understates four screens (metadata, not sim markdown). |

### LadyBug

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `README.md` | ⚠️ | “ladybug on a **rotating platform**” / “kinematics on a **rotatable platform**” → no platform node or platform-rotation control in `src/lady-bug/view/` (remote pad is position/velocity/acceleration, not platform spin). Also claims English + French only; `strings_es.json` exists. |
| `doc/implementation-notes.md` | ⚠️ | Architecture text and view list (“Platform”, “platform rotation” on `RemoteControlPanel`) do not match the implemented remote-control pad. Circular/elliptical **motion presets** exist; a rotatable platform does not. |
| `doc/model.md` | ✅ | Pure 2-D kinematics description is accurate (no platform claim). |
| `CLAUDE.md` | ❓ | Spot-check did not find a hard false status claim; refresh if README/impl-notes are rewritten. |

### TheRamp

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `README.md` | ⚠️ | Features: “Two-screen SceneryStack **scaffold** …” → sim is a filled PhET port (`doc/implementation-notes.md`, `CLAUDE.md`, physics/verify scripts). Screen names are fine; “scaffold” is wrong. Features also under-describe physics/charts. |
| Other in-scope docs | ✅ | No other verified false claims. |

### QubitSketch

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `doc/implementation-notes.md` | ⚠️ | Closing note: “no dispose functions have been used” → `GatePalettePanel.dispose()` + `tests/memory-leak.test.ts` exist. Constants location partially outdated vs `QubitSketchConstants.ts`. |
| `CLAUDE.md` | ⚠️ (minor) | Missing `QubitSketchConstants.ts` and leak-test / dispose pattern (added after last doc touch). |
| `README.md` / `doc/model.md` | ✅ | Circuit-screen features and quantum model match. |

### DopplerEffect

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `doc/implementation-notes.md` | ⚠️ | Names **TrailManager**; code has **`TrailPath`** in `MoveableObjectView.ts`. |
| `README.md` | ❓ | Features OK; locale line may omit Spanish (`strings_es.json` present). |
| `CLAUDE.md` / `doc/model.md` | ✅ | Formula and keyboard presets match. |

### WaveComposer

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `doc/implementation-notes.md` | ⚠️ (minor) | Still names **`AnalysisPreferencesModel`**; code uses **`WaveComposerPreferencesModel`**. |
| `README.md` / `CLAUDE.md` / `doc/model.md` / `CREDITS.md` | ✅ | Three screens, DSP story, and asset inventory match (including cello synthesized fallback). |

### SolarSystemModels

| File | Verdict | Dated claim → evidence |
|---|---|---|
| `doc/implementation-notes.md` | ⚠️ | Tree claims `SolarSystemModelsPreferencesModel` holds “sim-specific pref state”; model is empty after Jul 9 feat. Also omits zodiac ghosting bars / localized event-name keys added in that feat. |
| `README.md` / `CLAUDE.md` / `doc/model.md` | ✅ | Updated with recent feat; physics narrative OK. |

---

## §3 Mostly current (brief)

| Sim | Notes |
|---|---|
| HabitableZones | Primary docs describe implemented Circumstellar + Galactic; “scaffold” only for empty preferences model (accurate). |
| ExtrasolarPlanets | README / `doc/model.md` / impl-notes match RV + Transit; prefs scaffold wording accurate. |
| RotatingSky | Three-screen docs match `main.ts`. |
| VariableStarPhotometry | README Features match four implemented screens. |
| OscillationsAndChaos | Four screens + solvers + voicing align. |
| LunarLander, ElectricFieldOfDreams, RadioWaves, MazeGame | README Features / `doc/model.md` roughly match; no clear false status claims. |
| TrackLab | Docs correctly describe single-screen video tool; catalog `screens: null` is metadata convention, not a doc bug. |

---

## §4 Suggested follow-up order (update pass — done 2026-07-10)

1. ~~**LightPropagation** — fix README + CLAUDE status; sync Scripts / TypeScript version.~~
2. ~~**Resonance** — reconcile `doc/model.md` presets/defaults with `ResonancePresets`; fix solver table; mark or refresh `architecture-review.md`.~~
3. ~~**MovingMan** — fix Intro charts + wall-collision wording in `doc/model.md` and `implementation-notes.md`.~~
4. ~~**OpticsLab** — expand README Features; rename pass in `implementation-notes.md`; banner superseded extras (`model-features-vs-view`, security review, tandem plan) or archive.~~
5. ~~**LadyBug** — remove / correct rotatable-platform claims in README + `implementation-notes.md`; fix locale list.~~
6. ~~**TheRamp** — drop “scaffold” from README Features; optionally expand feature bullets.~~
7. ~~**QubitSketch** — dispose / constants / leak-test notes in impl-notes + CLAUDE.~~
8. ~~**DopplerEffect**, **WaveComposer**, **SolarSystemModels** — small rename / prefs / TrailPath / prefs-tree fixes.~~
9. ~~**Baton** — refresh HabitableZones scaffold claim in `fleet-parity-audit.md` (or supersede with a pointer to this report).~~
10. ~~**Optional catalog** — OpticsLab `screens` in `repos.json` should list four screens.~~

---

## §5 Explicit non-actions

- Identification pass did not edit sim markdown; the 2026-07-10 update pass did (see §4).
- No compliance CI or scripts were changed.
- Root `plan.md` / `PORTING_PLAN.md` files (ExtrasolarPlanets, VariableStarPhotometry, LightPropagation, etc.) were **not** audited under the locked scope; several still contain scaffold language and should be handled separately if desired.
- OpticsLab superseded docs (`model-features-vs-view`, etc.) were bannered, not fully rewritten — body text may still name old files.
