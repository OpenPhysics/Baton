---
name: scenerystack-testing
description: Use when adding or changing unit tests for a simulation — writing vitest specs for model/physics code, setting up the test harness, or adding fuzz/Playwright specs. Covers the standardized tests/ layout, vitest config, memory-leak suites, what is worth testing, and optional Playwright fuzz.
---

# SceneryStack Testing

Every OpenPhysics SceneryStack sim ships Vitest unit tests under root `tests/` and a
`test` script in `package.json`. CI runs `npm test` when that script is present. Prefer
testing the **model** (pure logic, physics, math) — not Scenery rendering.

Algorithm-heavy sims (OpticsLab, Resonance, WaveComposer, MazeGame, SternGerlach, Zenith,
ExtrasolarPlanets, MotionsOfTheSun, …) carry denser suites; PhET ports often start with a
smoke + reset suite and grow physics invariants over time. TemplateSingleSim is the layout
reference (CONVENTIONS §5).

## The standardized layout

```
tests/
  setup.ts                 vitest setup (Canvas/Audio mocks, init({ name }))
  memory-leak.test.ts      WeakRef + --expose-gc dispose regression (fleet pattern)
  **/*.test.ts             unit tests, mirroring the source tree under tests/
  **/*.spec.ts             Playwright specs, if any (e.g. tests/fuzz/)
vitest.config.ts           include: ["tests/**/*.test.ts"]; setupFiles: ["./tests/setup.ts"];
                           execArgv: ["--expose-gc"] when a memory-leak suite is present
```

Tests live **only** under root `tests/` — never co-located next to source, never in
`__tests__/` (the compliance gate fails on those). Mirror the source path: a test for
`src/optics-lab/model/Lens.ts` is `tests/optics-lab/model/Lens.test.ts`.

## A model unit test

Test physics/algorithm code directly — construct the model object, step or call it, assert
on Property values:

```typescript
import { describe, it, expect } from "vitest";
import { Vector2 } from "scenerystack/dot";
import { LensModel } from "../../../src/optics-lab/model/LensModel.js";

describe("LensModel", () => {
  it("forms a real image beyond the focal point (thin-lens equation)", () => {
    const lens = new LensModel({ focalLength: 1 });
    lens.objectPositionProperty.value = new Vector2(-3, 0);

    // 1/f = 1/do + 1/di  ⇒  di = 1.5 for f=1, do=3
    expect(lens.imageDistanceProperty.value).toBeCloseTo(1.5, 6);
    expect(lens.imageTypeProperty.value).toBe("real");
  });

  it("resets every Property", () => {
    const lens = new LensModel({ focalLength: 1 });
    lens.objectPositionProperty.value = new Vector2(-5, 2);
    lens.reset();
    expect(lens.objectPositionProperty.value).toEqual(lens.objectPositionProperty.initialValue);
  });
});
```

## Memory-leak suite

Ship `tests/memory-leak.test.ts` modeled on TemplateSingleSim / QubitSketch:

- Require `execArgv: ["--expose-gc"]` in `vitest.config.ts`.
- Allocate inside a **function** boundary, call `dispose()`, hold a `WeakRef`, then
  `forceGC` until the ref is cleared.
- Prefer disposing a real model (`TimeModel`, screen model, or a known disposable helper
  like Resonance `ListenerTracker`). When the sim has no disposable model yet, dispose a
  `NumberProperty` to keep the harness green and document the gap.
- Dynamic sims that add/remove nodes at runtime should expand the suite like OpticsLab.

## What to test

- **Physics / math:** closed-form results, conservation laws, edge cases (zero, `Range`
  boundaries, sign flips).
- **`reset()` completeness:** after mutating state, `reset()` restores initial values.
- **Derived quantities:** `DerivedProperty` recomputes when dependencies change.
- **Not** Scenery layout/rendering — covered by build + optional fuzz.

## Optional Playwright fuzz

TemplateSingleSim and Resonance ship `tests/fuzz/fuzz.spec.ts` + `playwright.config.ts`
with `npm run test:fuzz` / `test:fuzz:quick`. Fuzz uses joist's `?fuzz` query parameter and
fails on console/`pageerror`. Use it for pre-release / CRC stress; it is not required in
the default CI path.

## Rules

- Put tests only under root `tests/`, mirroring the source tree; setup file is
  `tests/setup.ts` (CONVENTIONS §5).
- Test the model, not the view.
- Import sim source through the `src/…/*.js` path (`verbatimModuleSyntax`).
- Always include a `reset()` test for any model with state.
- Document the vitest `environment` in the sim's `CLAUDE.md`; don't change it casually.
- Run `npm test` plus `npm run check && npm run build` before pushing.

## Common mistakes

- Co-locating `*.test.ts` beside source or using `__tests__/` → fails the compliance gate.
- Testing rendered pixels/layout in a unit test instead of model logic.
- Adding a `vitest.setup.ts` at root instead of `tests/setup.ts`.
- Asserting floating-point physics with `toBe`/`toEqual` instead of `toBeCloseTo`.
- Skipping the `reset()` test — the single highest-value model test.
- Memory-leak helpers that allocate in a block scope (not a function) — V8 won't collect.

Related skills: scenerystack-model, scenerystack-code-review, scenerystack-disposal,
scenerystack-numerics.
