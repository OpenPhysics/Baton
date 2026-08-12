# CodeQL across the fleet

Every simulation (and most tools) call the reusable workflow
[`shared-codeql.yml`](../.github/workflows/shared-codeql.yml) from their `ci.yml`:

```yaml
codeql:
  uses: OpenPhysics/Baton/.github/workflows/shared-codeql.yml@main
```

The shared job analyzes JavaScript/TypeScript with the
`security-extended` and `security-and-quality` query suites.

## Path exclusions

A small set of **local offline tooling** scripts is excluded via `paths-ignore` in
the shared workflow. These scripts fetch curated third-party assets (or public
datasets) and write them under the repo or a git-ignored `.cache/` directory so
developers can work offline. They are not part of the shipped simulation
runtime, and CodeQL’s `js/http-to-file-access` (and related) rules flag the
intentional download→disk flow as if it were a backdoor.

| Path pattern | Used for |
|---|---|
| `**/scripts/decompile-flash.ts` | NAAP lineage: download/extract FFDec to decompile Flash baselines |
| `**/scripts/data/**` | Dataset download caches (e.g. PlateTectonics `build-data`) |

Do **not** add runtime `src/` paths here. If a new offline tool trips the same
class of alert, document it in this table and extend the shared `paths-ignore`
list — prefer one org-wide exclude over per-repo dismissals.
