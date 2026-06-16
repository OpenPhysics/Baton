---
name: scenerystack-keyboard-help-dialog
description: Use when documenting a sim's keyboard controls in the Keyboard Shortcuts dialog (? icon). Covers KeyboardHelpSection, KeyboardHelpSectionRow.fromHotkeyData, TwoColumnKeyboardHelpContent, the BasicActions/SliderControls prebuilt sections, and wiring via createKeyboardHelpNode.
---

# SceneryStack Keyboard Help Dialog

Every keyboard-navigable sim ships a Keyboard Shortcuts dialog (opened with the `?` icon). You build its content from `KeyboardHelpSection`s and hand the whole node to the screen via `createKeyboardHelpNode`. The golden rule: **the help dialog is generated from the same `HotkeyData` that drives the actual listeners**, so documentation can't drift from behavior.

## Rows from HotkeyData

Define shortcuts once as `HotkeyData` (see scenerystack-accessibility), then build each help row with `KeyboardHelpSectionRow.fromHotkeyData` — the key icons come straight from the binding:

```typescript
import { KeyboardHelpSection, KeyboardHelpSectionRow } from "scenerystack/scenery-phet";
import MazeGameHotkeyData from "./MazeGameHotkeyData.js";

export default class MazeGameKeyboardHelpSection extends KeyboardHelpSection {
  public constructor(strings: KeyboardHelpStrings) {
    const moveRow = KeyboardHelpSectionRow.fromHotkeyData(MazeGameHotkeyData.MOVE_PARTICLE, {
      labelStringProperty: strings.controlParticleStringProperty,        // visible label
      pdomLabelStringProperty: strings.controlParticleDescriptionStringProperty, // screen-reader label
    });
    const stopRow = KeyboardHelpSectionRow.fromHotkeyData(MazeGameHotkeyData.STOP_MOTION, {
      labelStringProperty: strings.stopMotionStringProperty,
      pdomLabelStringProperty: strings.stopMotionDescriptionStringProperty,
    });

    // section title + its rows
    super(strings.particleStringProperty, [moveRow, stopRow]);
  }
}
```

## Assembling the dialog content

Lay sections out in two columns with `TwoColumnKeyboardHelpContent`. Reuse the prebuilt sections for common controls — `BasicActionsKeyboardHelpSection` (Tab/Esc/space) and `SliderControlsKeyboardHelpSection` (arrows/page-up-down) — alongside your sim-specific sections:

```typescript
import { TwoColumnKeyboardHelpContent, BasicActionsKeyboardHelpSection } from "scenerystack/scenery-phet";

class MazeGameKeyboardHelpContent extends TwoColumnKeyboardHelpContent {
  public constructor() {
    const moveSection = new MazeGameKeyboardHelpSection(strings);
    const basicActions = new BasicActionsKeyboardHelpSection();
    super(
      [moveSection],     // left column
      [basicActions],    // right column
    );
  }
}
```

## Wiring it to the screen

Pass a factory to the screen's `createKeyboardHelpNode` option (in the `Screen` subclass or in `main.ts`). The framework calls it to populate the dialog:

```typescript
new MazeGameScreen({
  createKeyboardHelpNode: () => new MazeGameKeyboardHelpContent(),
  // ...
});
```

## Rules

- Build rows with `KeyboardHelpSectionRow.fromHotkeyData(hotkeyData, ...)` so icons match the real bindings — never hand-type key names that could fall out of sync.
- All labels are `StringProperty`s from `StringManager` (see scenerystack-strings); supply a `pdomLabelStringProperty` so screen-reader users get a spoken description.
- Group with `TwoColumnKeyboardHelpContent`; include `BasicActionsKeyboardHelpSection` for the universal Tab/Esc shortcuts, and `SliderControlsKeyboardHelpSection` when the sim has sliders.
- One `createKeyboardHelpNode` per screen; multi-screen sims can return different content per screen.
- If you add or change a `HotkeyData` binding, the help dialog updates for free — keep both deriving from the same source.

## Common mistakes

- Typing literal key icons/labels instead of `fromHotkeyData` → the dialog lies once a binding changes.
- Hardcoded English in a row label → use a localized `StringProperty`.
- Documenting a shortcut in the dialog that no listener implements (or vice versa) → both must come from one `HotkeyData`.

Related skills: scenerystack-accessibility, scenerystack-strings, scenerystack-drag-listener.
