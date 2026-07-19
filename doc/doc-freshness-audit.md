# Per-Sim Documentation Freshness Audit

**Date:** 2026-07-18 · **Scope:** 24 `isSimulation: true` SceneryStack repos +
`TemplateSingleSim` from [`structure/repos.json`](../structure/repos.json) ·
**Mode:** triage refresh (identification + fleet doc hygiene) ·
**Docs in scope:** `README.md`, `CLAUDE.md`, `CREDITS.md`, `LICENSE`, `SECURITY.md`,
and `doc/*.md` when present.

> Prior pass: 2026-07-10 (20 sims). This refresh folds in **SternGerlach**,
> **Zenith**, **MotionsOfTheSun**, **BasicCoordinatesAndSeasons**, and checks
> that July 18 fleet-wide doc/legal files landed everywhere.

## Method

1. **Inventory** — every active sim has `README.md`, `CLAUDE.md`, `CREDITS.md`,
   `LICENSE` (AGPL), `SECURITY.md`, and `.github/CODEOWNERS`.
2. **Triage flags** — scaffold/status keywords, screen-count vs catalog, Tech Stack
   claiming TypeScript ^5, Scripts table missing `npm test`, CLAUDE missing Testing.
3. **Spot verification** — only when a flag suggests a dated physics/product claim.

## Executive summary

| Bucket | Count | Notes |
|---|---|---|
| **Legal / meta docs present** | **25/25** | LICENSE, SECURITY, CREDITS, CODEOWNERS added 2026-07-18 |
| **README Scripts include `npm test`** | **25/25** | Fan-out from Template |
| **CLAUDE Testing section** | **25/25** | Fan-out from Template |
| **Suspect product/physics claims** | **re-spot as needed** | July 10 update pass covered the prior top offenders; new sims below |

### New / recently added sims (spot check)

| Sim | README / CLAUDE | Notes |
|---|---|---|
| SternGerlach | ✅ | Six-section README; dense unit-test suite; WIP source may outpace `doc/` — re-check before release |
| Zenith | ✅ | Features/scripts current; large test suite |
| MotionsOfTheSun | ✅ | NAAP-style docs present; keyboard map interactions already paired |
| BasicCoordinatesAndSeasons | ✅ | Multi-screen; DragListener sites largely have KeyboardListener pairs |

### Residual from 2026-07-10

The July 10 update pass rewrote dated claims in LightPropagation, OpticsLab,
Resonance, MovingMan, LadyBug, TheRamp, QubitSketch, DopplerEffect, WaveComposer,
and SolarSystemModels. Treat those as **current unless `src/` drifts again**.

## Fleet hygiene completed this pass

- Root `LICENSE` (AGPL-3.0) + `SECURITY.md` + `.github/CODEOWNERS` on every sim
- `CREDITS.md` for PhET / NAAP / original sims (WaveComposer keeps its audio credits)
- README Scripts + CLAUDE Testing sections aligned with Vitest + memory-leak suite
- `Baton/skills/scenerystack-testing/SKILL.md` updated (tests are fleet-standard, not optional)

## Related

- [`fleet-parity-audit.md`](./fleet-parity-audit.md)
- [`fleet-a11y-audit.md`](./fleet-a11y-audit.md)
- [`CONVENTIONS.md`](../CONVENTIONS.md)

<sub>Re-triage when a sim’s `src/` commit date substantially outruns its last
doc-touching commit, excluding Dependabot-only bumps.</sub>
