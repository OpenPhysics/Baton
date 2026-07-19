# Fleet Accessibility Audit

**Date:** 2026-07-18 · **Scope:** 24 active SceneryStack sims + `TemplateSingleSim` ·
**Basis:** [`ACCESSIBILITY.md`](../ACCESSIBILITY.md) three required layers

## Executive summary

Structural Layer 1–2 coverage is strong fleet-wide: every sim has localized `a11y` (or
equivalent) strings with en/es/fr key parity, a `*ScreenSummaryContent` (or shared base),
and `*KeyboardHelpContent`. After this pass:

| Fix applied | Status |
|---|---|
| WaveComposer missing `pdomOrder` | **Fixed** — `BaseAnalysisScreenView.establishPdomOrder` on all 3 screens |
| OscillationsAndChaos nonstandard `accessibility` string group | **Fixed** — renamed to `a11y` + `getA11yStrings()` |
| ACCESSIBILITY.md scope list stale (18 sims) | **Fixed** — points at catalog + this audit |
| Play-area + secondary keyboard drag | **Fixed** — see matrix; graph pan keyboard added for OC/Resonance/TrackLab |

**Layer 3:** Primary play-area drags and high-traffic secondary controls (seek bars, field
pads, timeline, PE zero line, chart pan) now have `KeyboardDragListener` /
`RichDragListener` / `KeyboardListener` paths. Remaining pointer-only sites are
**documented out-of-scope chrome** (palette drag previews, axis-resize handles, video
scrubbers, analyzer delta bars, zodiac strip) — see ACCESSIBILITY.md.

## Checklist matrix (2026-07-18)

| Sim | `a11y` strings | Screen summary | Keyboard help | `screenSummaryContent` | Explicit `pdomOrder` / PDOM areas | Keyboard drag |
|---|---|---|---|---|---|---|
| TemplateSingleSim | ✅ | ✅ | ✅ | ✅ | ✅ wrapper | — |
| BasicCoordinatesAndSeasons | ✅ | ✅ | ✅ | ✅ | ✅ | — (`KeyboardListener` on map/globe sites) |
| DopplerEffect | ✅ | ✅ | ✅ | ✅ | ✅ | — (source/observer + mic `RichDragListener`) |
| ElectricFieldOfDreams | ✅ | ✅ | ✅ | ✅ | ✅ | — (particles + external-field pad) |
| ExtrasolarPlanets | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| HabitableZones | ✅ | ✅ | ✅ | ✅ | ✅ | — (`KeyboardListener` / paired sites) |
| LadyBug | ✅ | ✅ | ✅ | ✅ | ✅ | — (bug + seek bar + remote pad) |
| LightPropagation | ✅ | ✅ | ✅ | ✅ | ✅ | — (paired sites) |
| LunarLander | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| MazeGame | ✅ | ✅ | ✅ | ✅ | ✅ | — (control panel / keyboard modes) |
| MotionsOfTheSun | ✅ | ✅ | ✅ | ✅ | ✅ | — (`KeyboardListener` on map/sun sites) |
| MovingMan | ✅ | ✅ | ✅ | ✅ | ✅ | — (sprite Drag+KeyboardDrag) |
| OpticsLab | ✅ | ✅ shared | ✅ shared | ✅ | ✅ | — (RichDragListener + protractor) |
| OscillationsAndChaos | ✅ (`a11y`) | ✅ inline | ✅ shared | ✅ `setScreenSummaryContent` | ✅ `pdomPlayAreaNode` | — (masses/bob + graph pan) |
| QubitSketch | ✅ | ✅ | ✅ | ✅ | ✅ | — (Bloch camera); palette preview chrome deferred |
| RadioWaves | ✅ | ✅ | ✅ | ✅ | ✅ | — (transmitter electron) |
| Resonance | ✅ | ✅ shared | ✅ shared | ✅ | ✅ | — (oscillator sites + graph pan) |
| RotatingSky | ✅ | ✅ | ✅ | ✅ | ✅ | — (`KeyboardListener` on map/sky) |
| SolarSystemModels | ✅ | ✅ | ✅ | ✅ | ✅ | — (Configurations planets + timeline) |
| SternGerlach | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| TheRamp | ✅ | ✅ shared | ✅ shared | ✅ | ✅ | — (block, surface, FBD, PE line, time cursor) |
| TrackLab | ✅ | ✅ | ✅ | ✅ | ✅ | — (chart pan); video/axis chrome deferred |
| VariableStarPhotometry | ✅ | ✅ | ✅ shared | ✅ | ✅ | — (aperture/registration); analyzer bars deferred |
| WaveComposer | ✅ | ✅ shared | ✅ shared | ✅ | ✅ | — |
| Zenith | ✅ | ✅ | ✅ | ✅ | ✅ | — (observer / planetarium paired) |

## Ranked remaining work

1. **Deferred chrome** — Gate-palette drag previews (QubitSketch), analyzer delta-bar
   hit-targets (VSP), zodiac strip / Ptolemaic extras (SSM), TrackLab video/axis resize:
   out of Layer-3 scope unless they become primary keyboard workflows.
2. **OscillationsAndChaos structural polish** — Extract inline `createScreenSummaryContent()`
   bodies into per-screen `*ScreenSummaryContent.ts` files (behavior already correct).
3. **Live `currentDetailsContent`** — Prefer `DerivedProperty` over static strings on every
   multi-state screen summary (spot-check remaining shared summary bases).

## Verification

- Locale parity: `StringManager` `satisfies` checks (build fails on missing keys).
- Manual: Tab order matches `pdomOrder`, `?` keyboard-help dialog lists real interactions,
  screen summary reads first in the PDOM.
