---
name: scenerystack-color-profiles
description: Use when adding, changing, or theming colors in a SceneryStack sim. Covers ProfileColorProperty, the per-sim *Colors.ts file, and projector mode. Trigger whenever a view needs a fill/stroke/color, or someone hardcodes a hex/rgb value.
---

# SceneryStack Color Profiles

Every color a view draws comes from a `ProfileColorProperty` defined in the sim's single `*Colors.ts` file. **Never hardcode `#hex`, `rgb(...)`, or a bare `Color` in a view or node.** Profile colors give you free light/dark theming, projector mode, and runtime-editable colors in the color editor.

## The `*Colors.ts` file

One file per sim (e.g. `DopplerEffectColors.ts`, `SimColors.ts`), exporting a single frozen object of `ProfileColorProperty` instances keyed off the sim namespace.

```typescript
import { Color, ProfileColorProperty } from "scenerystack/scenery";
import dopplerEffect from "./DopplerEffectNamespace";

const BLACK = new Color(0, 0, 0);
const WHITE = new Color(255, 255, 255);

const DopplerEffectColors = {
  backgroundColorProperty: new ProfileColorProperty(dopplerEffect, "backgroundColor", {
    default: BLACK,
    projector: WHITE,
  }),
  sourceColorProperty: new ProfileColorProperty(dopplerEffect, "sourceColor", {
    default: new Color(100, 255, 100),
    projector: new Color(0, 200, 0),
  }),
} as const;

export default DopplerEffectColors;
```

- First arg is the sim **namespace** (`new Namespace("dopplerEffect")`, exported from `*Namespace.ts`).
- Second arg is a **unique string key** — this is the name shown in the color editor and used by phet-io. Keep it stable.
- The third arg is a map of named profiles. `default` is required; `projector` enables Projector Mode (high-contrast, light background for classroom projectors).

## Consuming a profile color in a view

Pass the `Property` directly — Scenery nodes accept a `TReadOnlyProperty<Color>` anywhere they accept a color, and re-render automatically when the profile changes.

```typescript
const dot = new Circle(8, { fill: DopplerEffectColors.sourceColorProperty });
const label = new Text(titleStringProperty, { fill: DopplerEffectColors.textColorProperty });
this.setScreenBackgroundColor?.(DopplerEffectColors.backgroundColorProperty); // or screenView background
```

If you need to derive one color from another (e.g. a translucent version), use `DerivedProperty`:

```typescript
const glowProperty = new DerivedProperty(
  [DopplerEffectColors.sourceColorProperty],
  (c) => c.withAlpha(0.3),
);
```

## Turning on Projector Mode

Projector colors only take effect if the sim opts in, in `src/main.ts`:

```typescript
preferencesModel: new PreferencesModel({
  visualOptions: { supportsProjectorMode: true },
}),
```

This adds a **Preferences → Visual → Projector Mode** toggle. Always define a sensible `projector:` value for every color when the sim supports it.

## Rules

- Define **all** colors in `*Colors.ts`. A view that needs a new color adds a key there, it does not invent one inline.
- Name keys after **role**, not appearance (`selectionColorProperty`, not `orangeColorProperty`).
- Reuse shared local `Color` constants (`BLACK`, `WHITE`) inside the file; don't repeat literals.
- Color literals are fine **inside `*Colors.ts`**, nowhere else.

## Common mistakes

- `fill: "red"` or `fill: new Color(...)` in a view → move it to `*Colors.ts`.
- Reading `.value` to get a static `Color` and passing that — you lose reactivity. Pass the `Property` itself.
- Forgetting a `projector:` value when `supportsProjectorMode` is on (projector mode silently falls back to `default`).

Related skills: scenerystack-preferences (projector toggle).
