---
name: scenerystack-screen-view
description: Use when wiring a simulation's entry point — creating the Sim, defining a Screen, building a ScreenView, setting screen icons and background, or connecting a screen's model to its view. Covers the joist Sim/Screen/ScreenView trio, the model factory pattern, and the per-frame step hand-off.
---

# SceneryStack Screen & Sim Setup

`scenerystack/joist` defines the three-layer entry point every sim shares: a **`Sim`** owns one or more **`Screen`**s; each `Screen` is a factory pairing a model with a `ScreenView`. This is the view-side counterpart to scenerystack-model — the model holds physics, the `ScreenView` is the root `Node` of everything the user sees.

## The launch chain

`src/main.ts` (after the bootstrap imports — see CONVENTIONS §1) constructs the screens and the `Sim`, then launches:

```typescript
import { Sim, simLauncher } from "scenerystack/joist";
import { DopplerEffectScreen } from "./doppler-effect/DopplerEffectScreen.js";

simLauncher.launch(() => {
  const sim = new Sim(titleStringProperty, [ new DopplerEffectScreen() ], {
    credits: { leadDesign: "…" },
  });
  sim.start();
});
```

## A Screen is a model + view factory

`Screen`'s constructor takes a **model factory**, a **view factory** (given the model), and options (icon, background, name). The factories defer construction until the framework is ready.

```typescript
import { Screen, type ScreenOptions } from "scenerystack/joist";
import { optionize, type EmptySelfOptions } from "scenerystack/phet-core";

type DopplerEffectScreenOptions = ScreenOptions;

export class DopplerEffectScreen extends Screen<DopplerEffectModel, DopplerEffectScreenView> {
  public constructor(providedOptions?: DopplerEffectScreenOptions) {
    const options = optionize<DopplerEffectScreenOptions, EmptySelfOptions, ScreenOptions>()(
      {
        name: StringManager.getInstance().screenNameStringProperty,
        backgroundColorProperty: DopplerEffectColors.backgroundProperty,
        // homeScreenIcon: new ScreenIcon( … ),  // see below
      },
      providedOptions,
    );

    super(
      () => new DopplerEffectModel(),                  // model factory
      (model) => new DopplerEffectScreenView(model),   // view factory
      options,
    );
  }
}
```

A single-screen sim still has exactly one `Screen` (the home-screen selector is skipped automatically).

## The ScreenView

`ScreenView` is the root node. Build the scene graph in its constructor, position against `layoutBounds` (see scenerystack-layout), and forward the frame loop to the model in `step(dt)`:

```typescript
import { ScreenView, type ScreenViewOptions } from "scenerystack/joist";

export class DopplerEffectScreenView extends ScreenView {
  public constructor(private readonly model: DopplerEffectModel, providedOptions?: ScreenViewOptions) {
    super(providedOptions);

    // … add child nodes, controls, ResetAllButton (see scenerystack-ui-controls) …
  }

  // called every animation frame; advance the model here (not in the model itself)
  public override step(dt: number): void {
    if (this.model.isPlayingProperty.value) {
      this.model.step(dt);
    }
  }

  public reset(): void { /* reset view-only state; model.reset() is called by ResetAllButton */ }
}
```

## Screen icons

Multi-screen sims need a `homeScreenIcon` (and usually a `navigationBarIcon`). Build one from a `Node` wrapped in `ScreenIcon` from `scenerystack/joist`:

```typescript
import { ScreenIcon } from "scenerystack/joist";
const icon = new ScreenIcon(iconNode, { maxIconWidthProportion: 1, maxIconHeightProportion: 1 });
```

## Rules

- The `Screen` constructor takes **factories** (`() => model`, `(model) => view`), not pre-built instances — let joist call them.
- The `ScreenView` owns the per-frame `step(dt)` and decides whether to advance the model (gate on `isPlayingProperty`); the model's own `step` does the physics (see scenerystack-model).
- Set `backgroundColorProperty` from `*Colors.ts` so projector mode works (see scenerystack-color-profiles).
- Use `optionize` with `ScreenOptions`/`ScreenViewOptions` as the parent type (see scenerystack-optionize).
- Keep `main.ts`'s bootstrap import order intact — `./brand.js` first (CONVENTIONS §1).
- One screen folder per `Screen`, kebab-case, with `model/` and `view/` inside it (CONVENTIONS §2).

## Common mistakes

- Passing `new Model()` / `new View()` instances to `Screen` instead of factory functions.
- Calling `model.step(dt)` unconditionally in the ScreenView, ignoring play/pause.
- Hardcoding the background color instead of a `ProfileColorProperty`.
- Putting physics in `ScreenView.step` — it belongs in the model; the view only forwards `dt`.
- Reordering `main.ts` imports so `brand.js` is no longer first → breaks the bootstrap chain.

Related skills: scenerystack-model, scenerystack-layout, scenerystack-ui-controls, scenerystack-color-profiles, scenerystack-optionize.
