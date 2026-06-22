---
name: scenerystack-custom-drawing
description: Use when rendering custom graphics that the standard nodes don't cover — drawing a curve, a filled region, an arrow, a dynamic path, or choosing a renderer for performance. Covers Path + kite Shape, the primitive scenery nodes, scenery-phet drawing helpers, and canvas/WebGL renderer hints.
---

# SceneryStack Custom Drawing

Most visuals are built from ready-made nodes (`Rectangle`, `Circle`, `Line`, `Text`, `Image` in `scenerystack/scenery`; `ArrowNode` and friends in `scenerystack/scenery-phet`). When you need an arbitrary outline or filled region — a wave trace, a field line, a swept area — draw a **`Path`** whose geometry is a **kite `Shape`**. Geometry comes from `scenerystack/kite`; the node from `scenerystack/scenery`.

## Path + Shape

```typescript
import { Path } from "scenerystack/scenery";
import { Shape } from "scenerystack/kite";

const shape = new Shape()
  .moveTo(0, 0)
  .lineTo(50, -20)
  .quadraticCurveTo(80, -40, 120, 0)
  .close();

const curve = new Path(shape, {
  stroke: WaveColors.traceProperty,   // ProfileColorProperty, not a literal (see scenerystack-color-profiles)
  lineWidth: 2,
  fill: null,
});
```

## Redrawing a dynamic curve

For a trace that changes each frame, rebuild the `Shape` and assign it — don't mutate points in place. Build view-space points through the `ModelViewTransform2` (see scenerystack-model-view-transform):

```typescript
model.samplesProperty.link((samples) => {
  const shape = new Shape();
  samples.forEach((sample, i) => {
    const v = modelViewTransform.modelToViewPosition(sample);
    i === 0 ? shape.moveTo(v.x, v.y) : shape.lineTo(v.x, v.y);
  });
  this.curve.shape = shape;          // reassign; scenery re-renders the Path
});
```

Reassigning `shape` each frame is fine for typical sample counts. If profiling shows it's hot, give the `Path` a `canvas`/`webgl` renderer hint (below) before reaching for anything exotic.

## Ready-made drawing helpers

Prefer these over re-deriving the geometry:

- `ArrowNode` (`scenery-phet`) — vectors/forces, with configurable head/tail.
- `Line` (`scenery`) — a single straight segment.
- `DashedLineNode`, `BracketNode`, `LaserPointerNode`, `MeasuringTapeNode`, `RulerNode` (`scenery-phet`) — common physics overlays.

## Renderer hints & performance

Scenery picks SVG by default. For many frequently-changing nodes or large fills, hint a different renderer on the node (or a container) via options:

```typescript
new Path(shape, { renderer: "canvas" });   // or "webgl" for many sprite-like nodes
```

Apply hints **only after profiling** — premature renderer switches often hurt. Batch dynamic graphics under one parent and hint the parent rather than each child.

## Rules

- Geometry is a kite `Shape`; the node is a scenery `Path`. Don't draw to a raw `<canvas>` outside scenery.
- Convert model points to view space through the screen's `ModelViewTransform2` — never multiply by a scale by hand (see scenerystack-model-view-transform).
- Color/stroke from `*Colors.ts` `ProfileColorProperty`s so projector mode and theming work (see scenerystack-color-profiles).
- Rebuild and reassign `path.shape` for dynamic curves; keep `lineWidth`/sample counts in `*Constants.ts`.
- Reach for an existing `scenery-phet` node (`ArrowNode`, `RulerNode`, …) before hand-drawing the same thing.
- Treat `renderer: "canvas"/"webgl"` as a profiling-driven optimization, not a default.

## Common mistakes

- Drawing to a bare HTML canvas/`CanvasRenderingContext2D` instead of a scenery `Path` → escapes the scene graph, layout, and accessibility.
- Hardcoding stroke/fill colors instead of `ProfileColorProperty`.
- Hand-rolling an arrow with `Line`s when `ArrowNode` exists.
- Mutating a `Shape`'s internal points expecting a redraw — assign a new `shape` instead.
- Switching to WebGL "for speed" without profiling → often slower for a handful of paths.

Related skills: scenerystack-model-view-transform, scenerystack-color-profiles, scenerystack-constants, scenerystack-layout.
