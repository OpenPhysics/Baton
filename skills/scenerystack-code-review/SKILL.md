---
name: scenerystack-code-review
description: Use to run a pre-release Code Review (CRC) on an OpenPhysics SceneryStack sim built from the single-sim template — build/run/fuzz checks, memory-leak audit, performance, usability, i18n, repo-structure conformance, coding conventions, math libraries, maintainability, and accessibility. Trigger when asked to "code review", "do a CRC", "pre-release review", or audit a sim against project standards.
---

# SceneryStack Code Review (CRC)

A Code Review is the pre-release audit of an OpenPhysics sim against project standards. Our sims are
single-sim **Vite + TypeScript + Biome** projects forked from `TemplateSingleSim` (`npm run rename`), so
this checklist is tailored to that layout (`src/`, `doc/`, `public/`, `biome.json`) — **not** the classic
PhET `js/`/grunt layout. Related skills: scenerystack-accessibility, scenerystack-i18n,
scenerystack-color-profiles, scenerystack-constants, scenerystack-query-parameters,
scenerystack-preferences.

## How to run a review

1. Create a GitHub issue titled **"Code Review"** labeled `dev:code-review`, assigned to the reviewer.
2. Paste the **Checklist** section below into it (drop this skill's heading/intro).
3. Fill in or delete **Specific Instructions**; replace each `{{ISSUE}}` with a real issue link.
4. Delete or ~~strike through~~ items and whole sections that don't apply (e.g. the sim has no sounds).
5. A checked box means **"reviewed"**, not "no problem here". File problems as side issues that
   reference the review, or as `// REVIEW` comments in the code.

When running this as an automated pass, work top-down: stop at the first **Build & Run** failure and
report it, since later items assume a building sim.

---

## Checklist

### Specific Instructions

*Known failing items, files to skip, incomplete code, shared/common code that also needs review, etc.
Delete if none.*

### Companion Issues

These standard issues should exist and be complete. If any are missing, pause the review.

- [ ] `doc/model.md` — {{ISSUE}}. Describes the model for educators; reviewed by the sim designer.
- [ ] `doc/implementation-notes.md` — {{ISSUE}}. Useful overview for future maintainers.
- [ ] Memory-test results — {{ISSUE}}.
- [ ] Performance testing and sign-off — {{ISSUE}}.
- [ ] Pointer-area review — {{ISSUE}}.
- [ ] If accessibility is included: description review and sign-off — {{ISSUE}}.
- [ ] Credits — {{ISSUE}} (usually finished after release-candidate testing).

### Build & Run

*If any item here fails, pause the review.*

- [ ] `npm run check` passes (`tsc --noEmit` for app and scripts) with no type errors.
- [ ] `npm run lint` (Biome) reports no errors.
- [ ] `npm test` (Vitest) passes.
- [ ] `npm run build` (`tsc && vite build`) completes without warnings/errors and emits `dist/`.
- [ ] The `dist/` bundle size is reasonable versus comparable sims.
- [ ] The sim starts in both dev (`npm start`) and built (`npm run preview`) modes.
- [ ] No assertion failures with `?ea`.
- [ ] Passes a scenery fuzz test: `?fuzz&ea`.
- [ ] Behaves correctly under shuffled listener order: `?ea&listenerOrder=random` and
  `?ea&listenerOrder=random&fuzz`.
- [ ] No deprecation warnings with `?deprecationWarnings`; no deprecated APIs in new code.

### Memory Leaks

- [ ] `tests/memory-leak.test.ts` exists and passes under `npm test` (WeakRef +
  `execArgv: ["--expose-gc"]` in `vitest.config.ts` — see scenerystack-testing / CONVENTIONS §5).
- [ ] A Chrome DevTools heap comparison shows no leak. Build with mangling disabled for readable names
  (e.g. `vite build --minify false`). Compare against the responsible dev's results: {{ISSUE}}.
- [ ] Every SceneryStack component that registers internal observers/listeners is `dispose()`d where
  needed. Disposal may be unnecessary for a node that lives in a `ScreenView` never removed from the
  scene graph — document that reasoning when relying on it.
- [ ] Registrations are paired with cleanup unless documented otherwise:
  - `Property.link` / `lazyLink` ↔ `unlink`.
  - `Multilink.multilink` ↔ `unmultilink`; `new Multilink(...)` ↔ `.dispose()`.
  - `new DerivedProperty(...)` ↔ `.dispose()`.
  - `Emitter.addListener` ↔ `removeListener` (including `ObservableArray` element emitters).
  - `Node.addInputListener` ↔ `removeInputListener`.
- [ ] Every class needing teardown has a `dispose()`. Acceptable patterns: a private
  `this.dispose{{ClassName}}()` callback invoked from `dispose()`; `Disposable` / `disposeEmitter`; or
  direct `super.dispose()` + `child.dispose()`.
- [ ] Classes that intentionally don't clean up set `isDisposable: false` or call
  `Disposable.assertNotDisposable()`, so a stray `dispose()` can't silently leak.

### Performance

- [ ] Play through the sim; note any obvious issues (animation slowing with object count, GC hitches).
- [ ] If WebGL is used, there is a Canvas/SVG fallback that performs acceptably (`?webgl=false`).

### Usability

- [ ] Continuous controls (sliders especially) feel responsive.
- [ ] Pointer areas are optimized for touch (`?showPointerAreas`).
- [ ] Pointer areas don't overlap inappropriately (`?showPointerAreas`). Overlap may be fine given
  z-ordering and whether objects move.

### Internationalization

See scenerystack-i18n and scenerystack-strings. Strings live in `src/i18n/strings_en.json` and are
accessed through `src/i18n/StringManager.ts`.

- [ ] Dynamic layout survives runtime locale switching: `?stringTest=dynamic`, then left/right arrows.
- [ ] All user-visible strings are externalized; layout handles short strings (`?stringTest=X` shows
  only `X`s).
- [ ] Layout handles long strings (`?stringTest=double` and `?stringTest=long`).
- [ ] Negative numbers render correctly in RTL (`?stringTest=rtl`); use `StringUtils.toFixedLTR` /
  `toFixedNumberLTR` where needed.
- [ ] No external redirect on `?stringTest=xss` (a crash/failed start is acceptable; a redirect is not).
- [ ] No string concatenation for user-visible text — use `StringUtils.fillIn` with a pattern.
- [ ] Named placeholders (`"{{value}} {{units}}"`), not numbered (`"{0} {1}"`).
- [ ] String keys in `strings_en.json` follow project key conventions; keys are hard to change after
  publication.
- [ ] If previously released, no original string keys changed without deliberate discussion.

### Repository Structure

Compare against `TemplateSingleSim`. Source lives in `src/`, not `js/`; tooling is Biome + Vite.

- [ ] Repo name matches the sim title (e.g. "The Ramp" → `TheRamp` per OpenPhysics naming).
- [ ] Top-level layout matches the template (resource dirs may be absent if unused):

  ```
  my-sim/
    doc/            model.md, implementation-notes.md, images/
    public/         favicon.ico, icons/  (and any static assets)
    scripts/        generate-icons.ts, rename-sim.ts, …
    src/            (see below)
    tests/
    .githooks/
    biome.json
    index.html
    package.json
    tsconfig.json
    tsconfig.scripts.json
    vite.config.ts
    vitest.config.ts
    README.md
    CLAUDE.md
    CREDITS.md                  PhET / NAAP / original attribution (fleet standard)
    SECURITY.md                 points at org security policy
    .github/CODEOWNERS
  ```

- [ ] No local `LICENSE` or `CONTRIBUTING.md` — org defaults from `OpenPhysics/.github` apply
  (compliance fails if a root `LICENSE` is present).
- [ ] `README.md` follows the six-section outline only: Features / Quick Start / Scripts /
  Tech Stack / License / Contributing (no extra top-level `##` sections).
- [ ] `src/` follows the template layout — one folder per screen (even single-screen), shared code in
  `src/common/`, model/view split, preferences and i18n in their own folders:

  ```
  src/
    main.ts                         entry point
    SimColors.ts                    ProfileColorProperty instances
    SimNamespace.ts
    common/                         model/, view/ shared across screens
    i18n/
      StringManager.ts
      strings_en.json   strings_fr.json   strings_es.json   …
    preferences/
      simQueryParameters.ts         QueryStringMachine schema
      SimPreferencesModel.ts        Property instances seeded by the schema
      SimPreferencesNode.ts         preferences UI
    sim-screen/                     (renamed per screen)
      SimScreen.ts
      model/SimModel.ts
      view/SimScreenView.ts
      view/SimScreenSummaryContent.ts
      view/SimKeyboardHelpContent.ts
  ```

- [ ] After `npm run rename`, the `Sim` prefix has been replaced consistently — no stray `Sim*`
  filenames, class names, or namespace strings remain.
- [ ] Filenames use a single consistent prefix matching the sim (full name or an all-uppercase
  abbreviation unique across repos, e.g. `TheRampConstants.ts` or `TRConstants.ts` — never mixed
  forms like `TheRampConstants` and `TRColors` in one repo).
- [ ] Static assets live under `public/`; icons are generated from `public/icons/icon.svg` via
  `npm run icons` (not hand-edited PNGs that drift from the source SVG).
- [ ] Sim-specific query parameters are declared once in `src/preferences/{prefix}QueryParameters.ts`
  (see scenerystack-query-parameters), with public-facing ones marked `public: true`.
- [ ] Colors live in `SimColors.ts` using `ProfileColorProperty` for theme-able values (see
  scenerystack-color-profiles).
- [ ] Sim-specific preferences are `Property` instances in `SimPreferencesModel.ts`, initialized from
  the query-parameter schema (see scenerystack-preferences).
- [ ] Primary constants live in `src/{Prefix}Constants.ts`; any nested topical constants files
  are documented in `CLAUDE.md` (see scenerystack-constants).
- [ ] `package.json` has no unused dependencies.
- [ ] `package.json`, `tsconfig*.json`, `vite.config.ts`, `vitest.config.ts`, and `biome.json` contain
  no dev-only relaxations that should be removed before release (disabled lint rules, loosened
  `strict`/type checks, debug flags).
- [ ] `.gitignore` covers `dist/`, `node_modules/`, and other generated output.
- [ ] No stale branches that should be deleted.

### Coding Conventions

- [ ] Code generally follows SceneryStack/PhET conventions and the repo's CLAUDE.md guidance. Confirm
  it meets project standards — no need to check every item exhaustively.
- [ ] `npm run fix` (Biome) introduces no changes, i.e. formatting and import ordering are already
  clean.

### Math Libraries

- [ ] Format numbers with `toFixed` / `toFixedNumber` from `scenerystack/dot` (or
  `Utils.toFixed` / `Utils.toFixedNumber`), never JavaScript's native `Number.toFixed`
  (cross-browser rounding inconsistencies). See scenerystack-numerics.

### Organization, Readability & Maintainability

- [ ] Code organization makes sense; model/view contain the expected types; code names match UI names.
- [ ] Appropriate design patterns are used; favor composition over inheritance where it fits; the type
  hierarchy is sensible.
- [ ] No unnecessary coupling — pass only what's needed. Narrow constructor APIs with separate params
  or TypeScript `Pick<>`:

  ```ts
  class MyNode {
    public constructor(
      tickMarksVisibleProperty: Property<boolean>,
      model: Pick<MyModel, "changeWaterLevel">, // only the slice we need
      providedOptions?: MyNodeOptions
    ) {}
  }
  ```

- [ ] No unnecessary decoupling — pass an object instead of all its fields when that reads clearer.
- [ ] Source files are reasonably sized; flag large multi-responsibility files. Find them with:

  ```sh
  cd src && wc -l $(find . -name "*.ts") | sort -n
  ```

- [ ] No significant duplicated blocks; anything reusable is lifted into `src/common/` or shared code.
- [ ] No leftover `TODO` / `FIXME` / `REVIEW` comments — resolve them or promote to GitHub issues.
- [ ] No undocumented magic numbers; extract them as named, documented constants.
- [ ] Constants shared across files are centralized in `src/{Prefix}Constants.ts` (plus any
  documented nested extras); the sim doesn't silently break when plausible constant values change.
- [ ] `PhetColorScheme` is used for standardized colors rather than re-inventing them; note any colors
  worth contributing upstream.
- [ ] Dependent Properties are `DerivedProperty`, not hand-synced plain `Property`s.
- [ ] All time-stepping runs through the sim's `step(dt)` chain — no `window.setTimeout` /
  `setInterval` for model time.

### Accessibility

*Omit if the sim has no accessibility instrumentation; skip subsections that don't apply.* See
scenerystack-accessibility and the repo's `SimScreenSummaryContent.ts` / `SimKeyboardHelpContent.ts`.

**General**

- [ ] A11y uses maintainable SceneryStack patterns (PDOM naming, accessible responses, screen summary).

**Alternative Input**

- [ ] Passes the keyboard fuzz test: `?fuzzBoard&ea`.
- [ ] Traversal order is set via `ScreenView.pdomPlayAreaNode.pdomOrder` and
  `pdomControlAreaNode.pdomOrder`.
- [ ] `KeyboardListener` keys are defined with `HotkeyData`, shared between the listener and the
  keyboard-help dialog so each binding lives in one place.
- [ ] No sim shortcuts collide with global SceneryStack shortcuts.

**Interactive Description**

- [ ] axe DevTools reports no accessibility violations.
- [ ] Resetting the sim also resets the PDOM.
- [ ] Accessibility strings avoid ASCII-only transforms like `toUpperCase()` (they will be translated).
- [ ] Accessibility strings have no leading space before a terminal period (some screen readers read
  ` .` as "dot").

---

*PhET-iO is not used in OpenPhysics template sims; if a sim adds it, review against the upstream PhET-iO
instrumentation guide separately.*
