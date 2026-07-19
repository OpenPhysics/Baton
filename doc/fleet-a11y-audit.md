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

**Layer 3 keyboard drag (2026-07-18 follow-up):** play-area objects gained
`KeyboardDragListener` (or `RichDragListener`) in LadyBug, RadioWaves,
ElectricFieldOfDreams, OscillationsAndChaos (spring/pendulum masses), TheRamp
(surface + FBD), DopplerEffect (`DragHandlerManager`), SolarSystemModels
(Configurations planets), QubitSketch (Bloch camera), and OpticsLab (protractor).
Many NAAP map/camera sims already paired `DragListener` with `KeyboardListener`.
Remaining gaps are mostly **graph chrome** (pan/zoom/resize handlers in
OscillationsAndChaos / Resonance `GraphInteractionHandler`) and a few secondary
UI hit-targets (seek bars, timeline strips, palette drag previews).

## Checklist matrix (2026-07-18)

| Sim | `a11y` strings | Screen summary | Keyboard help | `screenSummaryContent` | Explicit `pdomOrder` / PDOM areas | Keyboard drag gap |
|---|---|---|---|---|---|---|
| TemplateSingleSim | ✅ | ✅ | ✅ | ✅ | ✅ wrapper | — |
| BasicCoordinatesAndSeasons | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ DragListener-only sites |
| DopplerEffect | ✅ | ✅ | ✅ | ✅ | ✅ | — (KeyboardDragListener in DragHandlerManager) |
| ElectricFieldOfDreams | ✅ | ✅ | ✅ | ✅ | ✅ | — (KeyboardDragListener on particles) |
| ExtrasolarPlanets | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| HabitableZones | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| LadyBug | ✅ | ✅ | ✅ | ✅ | ✅ | — (KeyboardDragListener on bug) |
| LightPropagation | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| LunarLander | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| MazeGame | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| MotionsOfTheSun | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| MovingMan | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| OpticsLab | ✅ | ✅ shared | ✅ shared | ✅ | ✅ | — (RichDragListener fleet-wide; ToolsPanel protractor) |
| OscillationsAndChaos | ✅ (`a11y`) | ✅ inline | ✅ shared | ✅ `setScreenSummaryContent` | ✅ `pdomPlayAreaNode` | — masses/bob; ⚠️ graph chrome |
| QubitSketch | ✅ | ✅ | ✅ | ✅ | ✅ | — (KeyboardDragListener on Bloch camera) |
| RadioWaves | ✅ | ✅ | ✅ | ✅ | ✅ | — (KeyboardDragListener on electron) |
| Resonance | ✅ | ✅ shared | ✅ shared | ✅ | ✅ | ⚠️ |
| RotatingSky | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| SolarSystemModels | ✅ | ✅ | ✅ | ✅ | ✅ | — (Configurations planet KeyboardDragListener; other screens TBD) |
| SternGerlach | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| TheRamp | ✅ | ✅ shared | ✅ shared | ✅ | ✅ | — (surface + FBD; BlockNode already had KeyboardListener) |
| TrackLab | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| VariableStarPhotometry | ✅ | ✅ | ✅ shared | ✅ | ✅ | ⚠️ |
| WaveComposer | ✅ | ✅ shared | ✅ shared | ✅ | ✅ **fixed** | — |
| Zenith | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

## Ranked remaining work

1. **Graph-chrome keyboard pan/zoom** — `GraphInteractionHandler` in OscillationsAndChaos /
   Resonance (and similar timeline/seek UI) still uses pointer-only `DragListener`s for
   chart pan/resize. Prefer keyboard affordances or `RichDragListener` where continuous.
2. **OscillationsAndChaos structural polish** — Extract inline `createScreenSummaryContent()`
   bodies into per-screen `*ScreenSummaryContent.ts` files (behavior already correct).
3. **Secondary UI hit-targets** — Palette drag previews, analyzer delta bars, zodiac/timeline
   strips: add keyboard paths where they are primary interactions, not decorative chrome.

## Verification

- Locale parity: `StringManager` `satisfies` checks (build fails on missing keys).
- Manual: Tab order matches `pdomOrder`, `?` keyboard-help dialog lists real interactions,
  screen summary reads first in the PDOM.
