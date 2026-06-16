# SceneryStack skills

Focused, single-topic reference docs for building OpenPhysics SceneryStack simulations. Each
file is a self-contained skill — frontmatter (`name` + `description`) describing **when** it
applies, followed by the patterns, code, and common mistakes for that topic. An AI assistant
loads the one that matches the task at hand; a human can read them as topic guides.

These complement, not replace, the broader docs:

- [`.github/CLAUDE.md`](https://github.com/OpenPhysics/.github/blob/main/CLAUDE.md) — the org-wide AI guide (tech stack, bootstrap chain, commands). Start there.
- [`../CONVENTIONS.md`](../CONVENTIONS.md) — the structural convention (file layout, naming, the `preferences/` trio, tests).
- [`../ACCESSIBILITY.md`](../ACCESSIBILITY.md) — the shared accessibility pattern.

The skills go one level deeper than `CLAUDE.md`: API specifics, idioms, and pitfalls for a
single subsystem.

## Index

### Coding & review

| Skill | Use when |
|---|---|
| [`scenerystack-coding-conventions`](scenerystack-coding-conventions.md) | Writing/reviewing TypeScript — naming, constructor signatures, optionize, access modifiers, type inference, assertions, read-vs-write Property APIs. |
| [`scenerystack-code-review`](scenerystack-code-review.md) | Running a pre-release Code Review (CRC) on a sim — build/fuzz, memory leaks, performance, i18n, structure conformance, accessibility. |

### Model & math

| Skill | Use when |
|---|---|
| [`scenerystack-model`](scenerystack-model.md) | Creating/changing a model — state, physics, the `step(dt)`/`reset()` loop, reactive Properties, the `TModel` contract, model/view separation. |
| [`scenerystack-model-view-transform`](scenerystack-model-view-transform.md) | Converting between model and view coordinates or scaling physical quantities to pixels — `ModelViewTransform2`. |
| [`scenerystack-constants`](scenerystack-constants.md) | A number, size, or physical parameter appears in code — define it in `*Constants.ts` instead of inlining a magic value. |

### View & layout

| Skill | Use when |
|---|---|
| [`scenerystack-layout`](scenerystack-layout.md) | Positioning nodes — `layoutBounds`, `VBox`/`HBox`/`GridBox`, `AlignBox`/`AlignGroup`, struts, `Panel`. |
| [`scenerystack-color-profiles`](scenerystack-color-profiles.md) | Adding/theming colors — `ProfileColorProperty`, the per-sim `*Colors.ts`, projector mode. |
| [`scenerystack-drag-listener`](scenerystack-drag-listener.md) | Making a node draggable by mouse, touch, or keyboard — `DragListener`, `KeyboardDragListener`, `RichDragListener`, drag bounds. |
| [`scenerystack-optionize`](scenerystack-optionize.md) | A constructor takes configurable options — `optionize<>()`, `SelfOptions`/`Options`, `EmptySelfOptions`, `combineOptions`. |

### Text & localization

| Skill | Use when |
|---|---|
| [`scenerystack-strings`](scenerystack-strings.md) | A view needs display text, or you add/rename user-visible text — `StringManager`, `strings_*.json`, consuming `*StringProperty`. |
| [`scenerystack-i18n`](scenerystack-i18n.md) | Adding a locale, keeping locale files in sync, interpolating with `PatternStringProperty`, or enabling the runtime language picker. |

### Configuration & accessibility

| Skill | Use when |
|---|---|
| [`scenerystack-preferences`](scenerystack-preferences.md) | Configuring the Preferences dialog — projector mode, dynamic locale, sound, interactive highlights, custom controls. |
| [`scenerystack-query-parameters`](scenerystack-query-parameters.md) | Adding a URL-configurable startup option or debug flag — a typed `QueryStringMachine` schema. |
| [`scenerystack-keyboard-help-dialog`](scenerystack-keyboard-help-dialog.md) | Documenting keyboard controls in the `?` dialog — `KeyboardHelpSection`, `TwoColumnKeyboardHelpContent`, `createKeyboardHelpNode`. |
| [`scenerystack-accessibility`](scenerystack-accessibility.md) | Making a sim usable with a keyboard and screen reader — `accessibleName`, help text, dynamic announcements, keyboard listeners, interactive highlights. |
