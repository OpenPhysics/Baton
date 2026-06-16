# OpenPhysics Codebase Convention

This document defines the **single, shared codebase structure** every OpenPhysics
SceneryStack simulation must follow, so that any contributor (or AI assistant) can move
between sims and find everything in the same place. It is the structural companion to
[ACCESSIBILITY.md](ACCESSIBILITY.md) (which governs the a11y pattern) and to the shared
coding guidance in [.github/CLAUDE.md](https://github.com/OpenPhysics/.github/blob/main/CLAUDE.md).

The canonical reference implementation lives in **`TemplateSingleSim`**. When in doubt,
copy from the template. New sims are forked from it via `npm run rename`, so they start
conformant by default.

> **Scope:** the 14 SceneryStack TypeScript sims (DopplerEffect, ElectricFieldOfDreams,
> LadyBug, LunarLander, MazeGame, MovingMan, OpticsLab, OscillationsAndChaos, QubitSketch,
> RadioWaves, Resonance, TheRamp, TrackLab, WaveComposer) and the template. The hardware web
> UI `tscd48` and the Python apps (`pyro`, `pycd48`) are out of scope. Orchestration (`Baton`)
> and community-health (`.github`) repos follow their own conventions.

## 1. Bootstrap chain

`src/main.ts` must have `import "./brand.js"` as its **very first import**. Never reorder.
See [.github/CLAUDE.md §"Bootstrap import chain"](https://github.com/OpenPhysics/.github/blob/main/CLAUDE.md)
for the full explanation. Every sim has all five bootstrap files:

```
src/init.ts  src/assert.ts  src/splash.ts  src/brand.ts  src/main.ts
```

## 2. Source layout & naming

```
src/
  init.ts assert.ts splash.ts brand.ts main.ts
  <Prefix>Colors.ts          ProfileColorProperty entries (never hardcode color in views)
  <Prefix>Constants.ts       named layout/physics constants
  <Prefix>Namespace.ts       new Namespace("<kebab-id>")  ← MUST be at src/ root
  i18n/                      see §4
  preferences/               see §3
  <screen-name>/             kebab-case; one folder per screen
    <Screen>Screen.ts
    model/                   state, step(dt), reset() — must NOT import from view/
    view/                    Scenery nodes, layout, input
  common/                    shared code for multi-screen sims only
```

- `<Prefix>` is the sim's class prefix (e.g. `DopplerEffect`, `LunarLander`). `<kebab-id>`
  is its kebab-case id (e.g. `doppler-effect`).
- `<Prefix>Namespace.ts` lives at **`src/` root** — not in `common/`.
- Screen folders are **kebab-case** (`single-oscillator/`, `more-features/`). Single-screen
  sims still use a screen folder (e.g. `doppler-effect/`).
- There is **no top-level `src/model/` or `src/view/`** — `model/`/`view/` live inside a
  screen folder (or `common/`).
- Sim-specific extra root files are allowed when justified (e.g. `<Prefix>Icons.ts`,
  `<Prefix>Strings.ts`); note them in the sim's `CLAUDE.md`.

## 3. Preferences

```
src/preferences/
  <Prefix>PreferencesModel.ts
  <Prefix>PreferencesNode.ts        the preferences-dialog UI
  <prefix>QueryParameters.ts        camelCase, lowercase first letter
```

The query-parameters file is **lowercase-first camelCase** (`dopplerEffectQueryParameters.ts`),
matching its exported object. **Multi-tab pattern:** a sim with more than one preferences-dialog
tab may split the UI into `<Prefix><Tab>PreferencesNode.ts` files instead of a single
`<Prefix>PreferencesNode.ts` — e.g. OscillationsAndChaos uses
`OscillationsAndChaosSimulationPreferencesNode.ts` + `OscillationsAndChaosAudioPreferencesNode.ts`.
At least one `*PreferencesNode.ts` must exist.

## 4. Internationalization

```
src/i18n/
  StringManager.ts          singleton accessor + compile-time locale-parity checks
  strings_en.json  strings_es.json  strings_fr.json
```

All three locales ship in every sim; a missing key in any locale is a **build error**
(enforced by `satisfies` parity checks in `StringManager.ts`). Never hardcode display text in
views. Accessibility strings live under an `a11y` group — see [ACCESSIBILITY.md](ACCESSIBILITY.md).

## 5. Tests (optional, but standardized when present)

Unit tests are **optional** — most sims rely on `npm run check`/`build` + manual testing, and
only the more algorithm-heavy sims (OpticsLab, Resonance, WaveComposer, MazeGame) ship them.
When a sim does have tests, they follow the template exactly:

```
tests/
  setup.ts                  vitest setup (assertion helpers, globals)
  **/*.test.ts              unit tests (mirror the source tree under tests/)
  **/*.spec.ts              Playwright specs, if any (e.g. tests/fuzz/)
vitest.config.ts            root; include: ["tests/**/*.test.ts"]; setupFiles: ["./tests/setup.ts"]
```

- Tests live **only** under root `tests/`. Do **not** co-locate `*.test.ts` next to source and
  do **not** use `__tests__/` directories.
- The setup file is `tests/setup.ts` (not a root `vitest.setup.ts`).
- The vitest `environment` may vary by sim's needs (`happy-dom` is the template default;
  `jsdom` or `node` are acceptable where justified) — document the choice in the sim's `CLAUDE.md`.

## 6. Documentation

```
doc/model.md                physics, math, behavior (filled, not a stub)
doc/implementation-notes.md  architecture, design decisions (filled)
README.md                   six-section outline (Baton enforces order)
CLAUDE.md                   sim-specific AI/contributor context only
```

`README.md` uses the fixed outline `## Features / Quick Start / Scripts / Tech Stack /
License / Contributing` (enforced by Baton's compliance check). Do **not** add a per-repo
`CONTRIBUTING.md` or `LICENSE` — org defaults apply. `CREDITS.md` is optional.

## 7. Configuration baseline

| File | Standard |
|---|---|
| `biome.json` | `2.5.0` schema; 2-space indent, 120-char width, double quotes, semicolons |
| `tsconfig.json` / `tsconfig.scripts.json` | shared template versions (TS6, `erasableSyntaxOnly`, `verbatimModuleSyntax`) |
| `package.json` | `scenerystack ^3`, `vite ^8`, `typescript ^6`, `@biomejs/biome ^2.5`; standard `scripts` block |
| `.githooks/{pre-commit,pre-push}` | present; activated via `prepare` script on `npm install` |
| `.github/workflows/ci.yml` | calls `OpenPhysics/Baton` reusable CI + shared security workflows |
| `.github/dependabot.yml` | present |

**Documented-as-allowed variations** (not violations — note each in the sim's `CLAUDE.md`):
sim-specific `vite.config.ts` plugins (e.g. TrackLab's OpenCV/video serving), `biome.json` /
`.gitignore` additions for vendored binaries or local references, extra `package.json` scripts
(`release` / `serve` / `watch` / domain checks), an extra `tsconfig.test.json`, and the a11y
traversal choice (`pdomOrder` wrapper-Node *or* `pdomPlayAreaNode`/`pdomControlAreaNode`, per
[ACCESSIBILITY.md §3](ACCESSIBILITY.md)).

## Per-sim checklist (PR sign-off gate)

Most of these are checked automatically by Baton's compliance gate (see Verification); the
rest are a quick manual scan.

- [ ] Bootstrap: `src/{init,assert,splash,brand,main}.ts` exist; `main.ts`'s first import is `./brand.js`. *(auto)*
- [ ] `<Prefix>Namespace.ts` is at `src/` root, not in `common/`. *(auto)*
- [ ] `<Prefix>Colors.ts` and `<Prefix>Constants.ts` exist; no hardcoded colors/magic pixels in views. *(partly manual)*
- [ ] Screen folders are kebab-case with `model/` + `view/`; no top-level `src/model/` or `src/view/`. *(auto warn)*
- [ ] `src/preferences/` has `<Prefix>PreferencesModel.ts`, `<prefix>QueryParameters.ts`, and ≥1 `*PreferencesNode.ts`. *(auto)*
- [ ] `src/i18n/` has `StringManager.ts` + `strings_{en,es,fr}.json`; `npm run check` is green. *(auto)*
- [ ] Any tests live only under root `tests/` with `tests/setup.ts`; no co-located / `__tests__/`. *(auto)*
- [ ] `doc/model.md` + `doc/implementation-notes.md` exist and are filled. *(auto presence; manual content)*
- [ ] `README.md` follows the six-section outline; no local `CONTRIBUTING.md` / `LICENSE`. *(auto)*
- [ ] `biome.json` is on the `2.5.0` schema; `npm run lint` is green. *(auto)*
- [ ] Any deliberate deviation is documented in the sim's `CLAUDE.md`. *(manual)*

## Verification

- **Automated gate:** `bash ../Baton/scripts/check-repo-compliance.sh <SimDir>` — run from the
  superproject root, this enforces the structural and config rules above (it also runs in CI via
  `Baton/.github/workflows/shared-compliance-check.yml`). It must print `Compliance check passed`.
- **Per sim:** `npm run lint && npm run check && npm run build`, plus `npm test` where tests exist.
- **New sims:** `npm run rename` from a `TemplateSingleSim` copy produces a sim that passes the
  gate unchanged — that is the regression guarantee.
