---
name: scenerystack-ui-controls
description: Use when adding standard UI controls to a simulation — sliders, number spinners, checkboxes, radio buttons, combo boxes, push buttons, the Reset All button, or playback controls. Covers the sun and scenery-phet component libraries, the Property-backed value pattern, and wiring controls to model state.
---

# SceneryStack UI Controls

Sims build their controls from two ready-made component libraries — **`scenerystack/sun`** (generic widgets) and **`scenerystack/scenery-phet`** (sim-flavoured widgets) — rather than hand-rolling interactive nodes. Every control is **value-backed by a `Property`**: you hand it a model Property and the control reads/writes it. Don't poll or push values imperatively.

## Where each control lives

| Control | Module | Use for |
|---|---|---|
| `Slider` / `HSlider` / `VSlider` | `sun` | a continuous `NumberProperty` over a `Range` |
| `NumberControl` | `scenery-phet` | a slider **plus** title, tweaker arrows, and a numeric readout — the usual choice for a labelled quantity |
| `Checkbox` | `sun` | a `BooleanProperty` toggle with a label node |
| `AquaRadioButtonGroup` / `RectangularRadioButtonGroup` | `sun` | pick one value of an enumeration |
| `ComboBox` | `sun` | pick one value from a longer list (dropdown) |
| `ABSwitch` / `ToggleSwitch` | `sun` | a two-state switch |
| `RectangularPushButton` / `TextPushButton` | `sun` | fire an action |
| `ResetAllButton` | `scenery-phet` | reset the whole sim |
| `TimeControlNode` / `PlayPauseButton` / `StepForwardButton` | `scenery-phet` | playback |
| `NumberDisplay` | `scenery-phet` | read-only numeric readout |

## NumberControl — the workhorse

For a labelled numeric quantity, `NumberControl` beats a bare slider: it bundles the title, slider, tweaker buttons, and a formatted readout, all driven by one `NumberProperty`.

```typescript
import { NumberControl } from "scenerystack/scenery-phet";

const frequencyControl = new NumberControl(
  StringManager.getInstance().frequencyStringProperty,  // localized title (see scenerystack-strings)
  model.frequencyProperty,                              // NumberProperty
  model.frequencyProperty.range,                        // the Property's Range
  {
    delta: 0.1,                                         // tweaker step
    numberDisplayOptions: { decimalPlaces: 1, valuePattern: hzPatternStringProperty },
    sliderOptions: { majorTicks: [ { value: 0, label: new Text("0") } ] },
  },
);
```

## Checkbox, radio, combo — pick-a-value

```typescript
import { Checkbox, AquaRadioButtonGroup, ComboBox } from "scenerystack/sun";

const showGrid = new Checkbox(model.gridVisibleProperty, new Text(gridStringProperty), { boxWidth: 18 });

// one value of an enumeration (see scenerystack-enumeration)
const modeButtons = new AquaRadioButtonGroup(model.modeProperty, [
  { value: Mode.WAVE, createNode: () => new Text(waveStringProperty) },
  { value: Mode.PARTICLE, createNode: () => new Text(particleStringProperty) },
]);

// ComboBox needs a listbox parent (usually the ScreenView) so the popup isn't clipped
const unitsCombo = new ComboBox(model.unitsProperty, items, this /* listParent */);
```

## Reset All and playback

```typescript
import { ResetAllButton, TimeControlNode } from "scenerystack/scenery-phet";

const resetAll = new ResetAllButton({
  listener: () => { this.interruptSubtreeInput(); model.reset(); this.reset(); },
  right: this.layoutBounds.maxX - MARGIN,
  bottom: this.layoutBounds.maxY - MARGIN,
});

const timeControl = new TimeControlNode(model.isPlayingProperty, {
  playPauseStepButtonOptions: { stepForwardButtonOptions: { listener: () => model.step(STEP_DT) } },
});
```

## Rules

- Bind every control to a model `Property`; the control is the view of that state, not a second copy. After `model.reset()` the controls follow automatically.
- `ResetAllButton`'s listener should `interruptSubtreeInput()` first, then reset the model **and** any view-only state.
- Pass localized `*StringProperty`s for all labels — never literal strings (see scenerystack-strings).
- Style via `optionize` defaults and `*Constants`/`*Colors`, not inline literals (see scenerystack-optionize, scenerystack-color-profiles).
- `ComboBox` and other popups need a `listParent` Node high in the tree (commonly the `ScreenView`) so the open list isn't clipped by a panel.
- Lay controls out with `VBox`/`HBox`/`Panel` (see scenerystack-layout); don't hand-place each one.
- These controls are keyboard-accessible out of the box — keep that by giving groups `accessibleName`/help text (see scenerystack-accessibility) and documenting them in the keyboard-help dialog.

## Common mistakes

- Re-implementing a slider/checkbox with raw `Rectangle` + `DragListener` instead of using `sun` — loses accessibility, theming, and tweakers.
- Reaching for a bare `HSlider` when the quantity needs a title and readout — `NumberControl` already bundles them.
- Forgetting the `ComboBox` list parent → the dropdown is clipped inside a panel.
- A `ResetAllButton` that resets the model but leaves view-only Properties (e.g. a "show ruler" toggle) stale.

Related skills: scenerystack-layout, scenerystack-optionize, scenerystack-strings, scenerystack-enumeration, scenerystack-accessibility.
