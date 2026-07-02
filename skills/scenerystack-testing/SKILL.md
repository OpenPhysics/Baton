---
name: scenerystack-testing
description: Use when adding or changing unit tests for a simulation — writing vitest specs for model/physics code, setting up the test harness, or adding fuzz/Playwright specs. Covers the standardized tests/ layout, vitest config, what is worth testing, and the build/fuzz check that substitutes for tests where none exist.
---

# SceneryStack Testing

Unit tests are **optional** across the fleet — most sims rely on `npm run check` + `npm run build` + manual/fuzz testing, and only the algorithm-heavy sims (OpticsLab, Resonance, WaveComposer, MazeGame, QubitSketch, ExtrasolarPlanets, RotatingSky, SolarSystemModels) ship unit tests. When a sim *does* test, it follows the template layout exactly (CONVENTIONS §5) so the structure is identical everywhere. Test the **model** (pure logic, physics, math) — not Scenery rendering.

## The standardized layout

```
tests/
  setup.ts                 vitest setup (assertion helpers, globals)
  **/*.test.ts             unit tests, mirroring the source tree under tests/
  **/*.spec.ts             Playwright specs, if any (e.g. tests/fuzz/)
vitest.config.ts           include: ["tests/**/*.test.ts"]; setupFiles: ["./tests/setup.ts"]
```

Tests live **only** under root `tests/` — never co-located next to source, never in `__tests__/` (the compliance gate fails on those). Mirror the source path: a test for `src/optics-lab/model/Lens.ts` is `tests/optics-lab/model/Lens.test.ts`.

## A model unit test

Test physics/algorithm code directly — construct the model object, step or call it, assert on Property values:

```typescript
import { describe, it, expect } from "vitest";
import { Range, Vector2 } from "scenerystack/dot";
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

## What to test

- **Physics / math:** closed-form results, conservation laws, edge cases (zero, boundary of a `Range`, sign flips).
- **`reset()` completeness:** a quick test that after mutating state, `reset()` restores initial values catches the classic "forgot to reset a Property" bug.
- **Derived quantities:** that a `DerivedProperty` recomputes correctly when dependencies change.
- **Not** Scenery layout/rendering — that's covered by build + fuzz, not unit tests.

## Fuzz / build as the baseline

Where there are no unit tests, the safety net is `npm run build` plus **fuzz testing** (random-input stress via the `?fuzz` query parameter / a Playwright `tests/fuzz/*.spec.ts`), which surfaces crashes and the memory leaks from un-disposed listeners (see scenerystack-disposal). The pre-release Code Review uses this — see scenerystack-code-review.

## Rules

- Put tests only under root `tests/`, mirroring the source tree; setup file is `tests/setup.ts` (CONVENTIONS §5).
- Test the model, not the view. Model code is pure and import-cheap; rendering is not.
- Import sim source through the `src/…/*.js` path (matching the sim's `verbatimModuleSyntax` extension convention).
- Always include a `reset()` test for any model with state — it's the cheapest catch for Reset-All bugs.
- The vitest `environment` (`happy-dom` default, `jsdom`/`node` where justified) is documented in the sim's `CLAUDE.md`; don't change it casually.
- Run `npm test` (where a test script exists) plus `npm run check && npm run build` before pushing; CI runs tests automatically when a `test` script is present.

## Common mistakes

- Co-locating `*.test.ts` beside source or using `__tests__/` → fails the compliance gate.
- Testing rendered pixels/layout in a unit test instead of model logic → brittle and slow; leave that to fuzz/build.
- Adding a `vitest.setup.ts` at root instead of `tests/setup.ts`.
- Asserting on floating-point physics with `toBe`/`toEqual` instead of `toBeCloseTo`.
- Skipping the `reset()` test — the single highest-value model test.

Related skills: scenerystack-model, scenerystack-code-review, scenerystack-disposal, scenerystack-numerics.
