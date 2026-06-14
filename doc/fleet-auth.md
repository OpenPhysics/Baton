# Fleet authentication

Cross-repo **writes** — pushing branches and opening PRs in other OpenPhysics repos from
[`fleet-exec.yml`](../.github/workflows/fleet-exec.yml) / [`scripts/fleet-exec.sh`](../scripts/fleet-exec.sh)
with `--apply` — need a token with write access to **those** repos.

The workflow's default `GITHUB_TOKEN` is scoped to Baton only, so it can clone public repos
(enough for dry-runs and the read-only [`fleet-health.yml`](../.github/workflows/fleet-health.yml)
and compliance audits) but **cannot** push to or open PRs in the sim repos. For that, supply a
broader token.

```
fleet-exec --apply  ─uses→  GH_TOKEN  ─prefers→  secrets.FLEET_PAT  ─else→  github.token (Baton-only, read)
```

You have two options. A **fine-grained PAT** is the quickest; a **GitHub App** is the more robust
choice for ongoing org-wide automation (short-lived tokens, not tied to a person).

---

## Option A — Fine-grained personal access token (quickest)

1. Create the token at **GitHub → Settings → Developer settings → Fine-grained tokens → Generate new token**
   (<https://github.com/settings/personal-access-tokens>).
2. Set:
   - **Resource owner**: `OpenPhysics` (not your personal account).
   - **Repository access**: *All repositories*, or *Only select repositories* and pick the sim
     repos listed in [`structure/repos.json`](../structure/repos.json).
   - **Repository permissions**:
     - **Contents** → **Read and write** (clone + push branches)
     - **Pull requests** → **Read and write** (open PRs)
     - **Metadata** → Read-only (selected automatically)
     - **Workflows** → **Read and write** *only* if a fleet change will edit files under
       `.github/workflows/` in the target repos (GitHub rejects workflow edits otherwise).
   - **Expiration**: pick a finite window (e.g. 90 days) and set a rotation reminder.
3. Add it as a Baton repository secret named **`FLEET_PAT`**:

   ```bash
   gh secret set FLEET_PAT --repo OpenPhysics/Baton
   # paste the token when prompted
   ```

   Or via the UI: **Baton → Settings → Secrets and variables → Actions → New repository secret**,
   name `FLEET_PAT`.

That's it — `fleet-exec.yml` already reads `secrets.FLEET_PAT`. Org PAT policies must allow
fine-grained tokens (**Org → Settings → Personal access tokens**); an org admin may need to
approve the token before it works.

---

## Option B — GitHub App (recommended for ongoing automation)

A GitHub App mints a short-lived installation token per run, isn't tied to anyone's account, and
scopes cleanly to the installed repos.

1. **Create the app**: **Org → Settings → Developer settings → GitHub Apps → New GitHub App**.
   - **Permissions**: Contents → Read and write; Pull requests → Read and write
     (+ Workflows → Read and write only if editing workflow files).
   - No webhook needed.
2. **Install** the app on the OpenPhysics repos you want to target.
3. Generate a **private key** and store two secrets on Baton:

   ```bash
   gh secret set FLEET_APP_ID      --repo OpenPhysics/Baton   # the app's numeric ID
   gh secret set FLEET_APP_PRIVATE_KEY --repo OpenPhysics/Baton < path/to/app-private-key.pem
   ```
4. Mint a token in the workflow and hand it to `fleet-exec` as `GH_TOKEN`. Add this step before
   "Run fleet-exec" in [`fleet-exec.yml`](../.github/workflows/fleet-exec.yml):

   ```yaml
   - name: Mint installation token
     id: app-token
     uses: actions/create-github-app-token@v2
     with:
       app-id: ${{ secrets.FLEET_APP_ID }}
       private-key: ${{ secrets.FLEET_APP_PRIVATE_KEY }}
       owner: OpenPhysics
   ```

   then change the `GH_TOKEN` line to:

   ```yaml
   GH_TOKEN: ${{ steps.app-token.outputs.token || secrets.FLEET_PAT || github.token }}
   ```

---

## Verifying

1. **Dry-run first** (no token needed beyond the default — public clones only):
   run the **Fleet Exec** workflow with `apply` unchecked, or locally:

   ```bash
   scripts/fleet-exec.sh --simulation -- npm pkg set dependencies.scenerystack=^3.1.0
   ```

   Confirm the printed diffstats look right.
2. **Apply to one repo** as a smoke test, scoping with `--skip` or a tight filter, e.g. limit the
   catalog to a single repo with `--catalog`, then re-run with `apply` enabled. Verify one PR opens.
3. Scale up once a single-repo PR looks correct.

## Safety notes

- Prefer **fine-grained** tokens / **App** installs over classic PATs — grant only Contents and
  Pull requests, never admin.
- `fleet-exec` is **dry-run by default**; `--apply` (or `apply=true`) is the only thing that writes.
- Add a `--label` so fleet PRs are easy to find, triage, and bulk-close if needed.
- Rotate the PAT on its expiry; App tokens expire automatically each run.
