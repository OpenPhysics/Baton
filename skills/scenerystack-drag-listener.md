---
name: scenerystack-drag-listener
description: Use whenever a node must be draggable by mouse, touch, or keyboard. Covers DragListener, KeyboardDragListener, RichDragListener, the positionProperty+transform pattern, drag bounds, and pairing pointer drag with keyboard drag for accessibility.
---

# SceneryStack Drag Listeners

Dragging is added by attaching an input listener to a node with `node.addInputListener(listener)`. Three listeners cover the cases:

| Listener | Input | Use when |
|---|---|---|
| `DragListener` | mouse + touch | pointer dragging |
| `KeyboardDragListener` | arrow keys / WASD | keyboard accessibility for the same object |
| `RichDragListener` | **both** mouse/touch **and** keyboard | the normal choice — one listener, accessible by default |

All three import from `scenerystack/scenery`. Prefer **`RichDragListener`** for new draggable objects so the object is keyboard-accessible without extra wiring.

## The idiomatic pattern: `positionProperty` + `transform`

Let the listener own the model↔view conversion. Give it the model `positionProperty`, the `ModelViewTransform2`, and optional `dragBoundsProperty` (in model coordinates). The listener writes model coordinates straight back into the property; your node updates because it already links to that property.

```typescript
import { DragListener, KeyboardDragListener, RichDragListener } from "scenerystack/scenery";

// node follows the model
model.positionProperty.link((position) => {
  this.translation = modelViewTransform.modelToViewPosition(position);
});

const dragListener = new DragListener({
  targetNode: this,
  positionProperty: model.positionProperty,   // updated in MODEL coords
  transform: modelViewTransform,
  dragBoundsProperty: model.dragBoundsProperty,
});
this.addInputListener(dragListener);

// keyboard equivalent — same property + transform
const keyboardDragListener = new KeyboardDragListener({
  positionProperty: model.positionProperty,
  transform: modelViewTransform,
  dragBoundsProperty: model.dragBoundsProperty,
  dragSpeed: 100,        // px/s
  shiftDragSpeed: 50,    // px/s with Shift held (fine control)
});
this.addInputListener(keyboardDragListener);
```

`RichDragListener` combines the two and also exposes model-space deltas in its `drag` callback:

```typescript
const drag = new RichDragListener({
  transform: modelViewTransform,
  start: () => { /* grab */ },
  drag: (_event, listener) => {
    const { x: dx, y: dy } = listener.modelDelta; // already in model units
    setPoint(getPoint().x + dx, getPoint().y + dy);
  },
  end: () => { /* commit / record history */ },
});
handle.addInputListener(drag);
```

## When you can't use `positionProperty` (custom mapping)

Some objects don't move 1:1 with the pointer (e.g. a velocity vector set from the drag direction). Use the raw callbacks and convert manually through the transform:

```typescript
new DragListener({
  targetNode,
  dragBoundsProperty: new Property(dragBounds),
  allowTouchSnag: true,
  start: (event) => {
    const viewPos = modelViewTransform.modelToViewPosition(positionProperty.value);
    this.dragOffset = viewPos.minus(event.pointer.point); // pointer → object offset
  },
  drag: (event) => {
    const viewPoint = event.pointer.point.plus(this.dragOffset);
    positionProperty.value = modelViewTransform.viewToModelPosition(viewPoint);
  },
});
```

## Rules

- Convert coordinates **only** through the screen's `ModelViewTransform2` (see scenerystack-model-view-transform). Never hand-roll `* scale`.
- Every pointer-draggable object that matters for interaction should also be keyboard-draggable — use `RichDragListener`, or pair `DragListener` + `KeyboardDragListener` on the same `positionProperty`.
- `dragBoundsProperty` is in **model** coordinates when you pass a `transform`. Keep it on the model so physics and view agree.
- Set `allowTouchSnag: true` for touch objects so a finger that starts slightly off still grabs.
- A focusable draggable node needs `tagName`/`accessibleName` so screen readers announce it — see scenerystack-accessibility.
- Dispose listeners you create dynamically: keep the reference, call `removeInputListener(listener)` and `listener.dispose()` in the node's `dispose()`.

## Common mistakes

- Writing **view** pixels into a model `positionProperty` (forgot the `transform`) → object jumps and bounds break.
- Mouse-only `DragListener` with no keyboard path → fails accessibility; reach for `RichDragListener`.
- Recreating the offset math when `positionProperty` + `transform` would have done it for free.

Related skills: scenerystack-model-view-transform, scenerystack-model.
