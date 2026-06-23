# Fleet git commands

Run everyday git operations across **every OpenPhysics repo checked out locally** — the sibling
clones that live beside `Baton` in the workspace (`pull all`, `push all`, `status all`, …).

These operate on your **local working trees**. Two related tools cover different jobs:

| You want to… | Use |
|---|---|
| Update / clone every catalog repo into the workspace | [`scripts/clone-fleet.sh --update`](../scripts/clone-fleet.sh) |
| Make the *same change* everywhere and open one PR per repo | [`scripts/fleet-exec.sh`](../scripts/fleet-exec.sh) (see [`fleet-auth.md`](fleet-auth.md)) |
| Run an ad-hoc git command across your local checkouts | the one-liners below |

All commands assume you're in the `Baton` directory (the scripts resolve the workspace from there):

```bash
cd ~/OpenPhysics/Baton
```

---

## The building block

[`parse-repos.sh paths --require-local`](../scripts/parse-repos.sh) prints the on-disk path of
every catalog repo that actually exists in your workspace:

```bash
scripts/parse-repos.sh paths --require-local
```

Add catalog filters to narrow the set (same filters as the rest of the tooling):

```bash
scripts/parse-repos.sh paths --require-local --simulation        # simulations only
scripts/parse-repos.sh paths --require-local --type tool         # tools only
scripts/parse-repos.sh paths --require-local --no-simulation     # everything that isn't a sim
```

> Without a filter the list includes `Baton` and `.github` too. Add `--simulation` (or pipe through
> `grep -v` ) if you want to skip them.

Pipe those paths into a loop and use `git -C "$p"` to act on each repo without `cd`-ing around:

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  printf '\n\033[1m== %s ==\033[0m\n' "$(basename "$p")"
  git -C "$p" <any git subcommand>
done
```

Every recipe below is that loop with a different `git` command.

---

## Common operations

**Status of all repos** (short form, only repos with changes shown clearly):

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  printf '\n== %s ==\n' "$(basename "$p")"; git -C "$p" status -s
done
```

**Branch + dirty-count overview** — quick "where is everything" snapshot:

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  printf '%-24s %-28s %s dirty\n' "$(basename "$p")" \
    "$(git -C "$p" rev-parse --abbrev-ref HEAD)" \
    "$(git -C "$p" status --porcelain | wc -l)"
done
```

**Pull all** — prefer `clone-fleet.sh --update`: it fast-forwards every existing repo *and* clones
any catalog repo you're missing, in one pass:

```bash
scripts/clone-fleet.sh --update
```

Or, to pull only what's already on disk (no new clones):

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  printf '\n== %s ==\n' "$(basename "$p")"; git -C "$p" pull --ff-only
done
```

**Fetch all** (update remotes without touching working trees):

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  printf '\n== %s ==\n' "$(basename "$p")"; git -C "$p" fetch --all --prune
done
```

**Push all** — pushes the current branch of each repo. There is no built-in helper; pushing writes
to remotes, so review with a status/branch overview first. `git push` is a no-op for repos with
nothing to push:

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  printf '\n== %s ==\n' "$(basename "$p")"; git -C "$p" push
done
```

For a brand-new local branch, set the upstream the first time: `git -C "$p" push -u origin HEAD`.

**Create the same branch everywhere:**

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  git -C "$p" checkout -b chore/my-change
done
```

**Run anything else** — substitute any git subcommand, e.g. show the last commit per repo:

```bash
scripts/parse-repos.sh paths --require-local | while read -r p; do
  printf '%-24s %s\n' "$(basename "$p")" "$(git -C "$p" log -1 --format='%h %s')"
done
```

---

## Optional: a reusable shell function

Drop this into your `~/.bashrc` (or `~/.zshrc`) for a `fleet` command that runs any git subcommand
across every local repo:

```bash
# Run a git command across every OpenPhysics repo checked out locally.
#   fleet status -s
#   fleet pull --ff-only
#   fleet push
#   fleet log -1 --oneline
fleet() {
  local baton="$HOME/OpenPhysics/Baton"
  "$baton/scripts/parse-repos.sh" paths --require-local | while read -r p; do
    printf '\n\033[1m== %s ==\033[0m\n' "$(basename "$p")"
    git -C "$p" "$@"
  done
}
```

To target a subset, filter inside the function call instead — e.g. simulations only:

```bash
fleet-sims() {
  local baton="$HOME/OpenPhysics/Baton"
  "$baton/scripts/parse-repos.sh" paths --require-local --simulation | while read -r p; do
    printf '\n\033[1m== %s ==\033[0m\n' "$(basename "$p")"
    git -C "$p" "$@"
  done
}
```

---

## Notes

- **Read-only first.** `status`, `fetch`, and `log` change nothing — run them freely. `pull`,
  `push`, and `checkout` change state; eyeball a status overview before a bulk `push`.
- **`pull --ff-only`** refuses to create merge commits, so a repo with diverged local work fails
  loudly instead of silently merging. Resolve those repos by hand.
- **Loops don't stop on error.** If one repo fails (e.g. a non-fast-forward pull), the loop keeps
  going to the next; scan the output for failures rather than relying on an exit code.
- **Workspace location.** Scripts assume `Baton` sits beside the member repos. If your checkout
  differs, set `OPENPHYSICS_WORKSPACE` or pass `--catalog /path/to/repos.json`.
- For non-git fan-out (lint, build, dependency bumps) that should land as PRs, use
  [`fleet-exec.sh`](../scripts/fleet-exec.sh) instead — it works on fresh clones, not your local
  trees.
