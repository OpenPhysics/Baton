---
name: scenerystack-enumeration
description: Use when a model or view needs a fixed set of named choices — a mode, a state, a tool selection — backed by a Property and bound to radio buttons or a combo box. Covers the EnumerationValue class pattern, EnumerationProperty, and why to prefer it over string unions or numeric constants.
---

# SceneryStack Enumeration

When state is "one of a fixed set" (mode = wave | particle, tool = ruler | timer | none), model it with the **`EnumerationValue` class pattern** from `scenerystack/phet-core` and an **`EnumerationProperty`** from `scenerystack/axon` — not a string union or a bag of numeric constants. The enum carries real instances, so a `Property` of it works cleanly with radio buttons, combo boxes, and `Multilink`.

## The pattern

A class extends `EnumerationValue`, declares its members as `static readonly` instances, and exposes a `static enumeration`:

```typescript
import { Enumeration, EnumerationValue } from "scenerystack/phet-core";

export class SourceMode extends EnumerationValue {
  public static readonly CONTINUOUS = new SourceMode();
  public static readonly PULSE = new SourceMode();
  public static readonly SINGLE = new SourceMode();

  // MUST be last — registers the members above for name/value lookup
  public static readonly enumeration = new Enumeration(SourceMode);
}
```

The `enumeration` field must be the **last** static — it reflects over the already-defined members.

## Backing it with a Property

```typescript
import { EnumerationProperty } from "scenerystack/axon";

this.sourceModeProperty = new EnumerationProperty(SourceMode.CONTINUOUS);

// react to it
this.sourceModeProperty.link((mode) => {
  if (mode === SourceMode.PULSE) { /* … */ }
});
```

Iterate members via `SourceMode.enumeration.values`, and switch on identity (`=== SourceMode.PULSE`).

## Binding to controls

`EnumerationProperty` drops straight into radio/combo controls (see scenerystack-ui-controls):

```typescript
new AquaRadioButtonGroup(model.sourceModeProperty, [
  { value: SourceMode.CONTINUOUS, createNode: () => new Text(continuousStringProperty) },
  { value: SourceMode.PULSE,      createNode: () => new Text(pulseStringProperty) },
  { value: SourceMode.SINGLE,     createNode: () => new Text(singleStringProperty) },
]);
```

## Rules

- Use the `EnumerationValue` class pattern for any fixed, named choice set in model/view state.
- The `static enumeration = new Enumeration(ThisClass)` line goes **last**, after every member.
- Back the choice with `EnumerationProperty`; reset it in the model's `reset()` like any other Property (see scenerystack-model).
- Compare by identity (`mode === SourceMode.PULSE`) — members are singletons.
- Provide the user-visible label per member at the control via localized `*StringProperty`s (see scenerystack-strings), not on the enum.
- This is the modern API — use `Enumeration`/`EnumerationValue` from `phet-core`, not the deprecated `EnumerationDeprecated`.

## Common mistakes

- A `string` union (`"wave" | "particle"`) or magic numbers instead of an enum → no singletons, weaker typing, awkward with `EnumerationProperty` and radio groups.
- Declaring `static enumeration` before the members → it can't see them; it must be last.
- Forgetting to reset the `EnumerationProperty` in `reset()` → mode survives Reset All.
- Comparing with deep equality instead of `===` — members are unique instances; identity is correct and cheapest.
- Reaching for `EnumerationDeprecated` (the old map-based API) in new code.

Related skills: scenerystack-model, scenerystack-ui-controls, scenerystack-strings.
