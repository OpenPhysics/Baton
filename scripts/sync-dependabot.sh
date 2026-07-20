#!/usr/bin/env bash
# Sync canonical Dependabot configs from Baton/config/ to OpenPhysics repositories.
#
# Targets are read from structure/repos.json (not a hardcoded list):
#   - Baton itself          → config/dependabot-actions.yml
#   - npm member repos      → config/dependabot-npm.yml
#       • framework == "SceneryStack" (all sims + TemplateSingleSim)
#       • jscd48, tscd48, pyro, Almanach (other npm packages in the org)
#   - pycd48                  → config/dependabot-pip.yml
#
# Writes sibling checkouts under OPENPHYSICS_WORKSPACE; skips repos that are not
# present locally (clone with clone-fleet.sh first). Commit/push is left to you
# or to fleet-exec.sh.
#
#   scripts/sync-dependabot.sh --dry-run     # show targets only
#   scripts/sync-dependabot.sh               # copy templates
#   scripts/sync-dependabot.sh DopplerEffect # limit to named repo(s)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/config"
CATALOG="${OPENPHYSICS_CATALOG:-$REPO_ROOT/structure/repos.json}"
WORKSPACE="${OPENPHYSICS_WORKSPACE:-$(cd "$REPO_ROOT/.." && pwd)}"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
[ -f "$CATALOG" ] || { echo "missing catalog: $CATALOG" >&2; exit 1; }

DRY_RUN=0
FILTER=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *) FILTER+=("$arg") ;;
  esac
done

wants() {
  [ "${#FILTER[@]}" -eq 0 ] && return 0
  local name="$1"
  for f in "${FILTER[@]}"; do [ "$f" = "$name" ] && return 0; done
  return 1
}

sync_file() {
  local template="$1"
  local target="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "WOULD sync $template → $target"
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  cp "$template" "$target"
  echo "Synced $target"
}

# npm repos: SceneryStack fleet + other org npm packages (see header comment).
mapfile -t NPM_REPOS < <(
  jq -r '
    .repos[]
    | select(
        .name != "Baton" and .name != ".github" and
        (
          .framework == "SceneryStack" or
          .name == "jscd48" or .name == "tscd48" or .name == "pyro" or .name == "Almanach"
        )
      )
    | .name
  ' "$CATALOG" | sort
)

# Python pip repo(s) from the catalog.
mapfile -t PIP_REPOS < <(jq -r '.repos[] | select(.name == "pycd48") | .name' "$CATALOG")

echo "Syncing Dependabot configs from $CONFIG_DIR"
echo "Catalog: $CATALOG"
echo "Workspace: $WORKSPACE"
[ "$DRY_RUN" -eq 1 ] && echo "(dry-run — no files written)"

sync_file "$CONFIG_DIR/dependabot-actions.yml" "$REPO_ROOT/.github/dependabot.yml"

npm_synced=0
npm_skipped=0
for repo in "${NPM_REPOS[@]}"; do
  wants "$repo" || continue
  dir="$WORKSPACE/$repo"
  if [ ! -d "$dir" ]; then
    echo "SKIP $repo (not checked out at $dir)"
    npm_skipped=$((npm_skipped + 1))
    continue
  fi
  sync_file "$CONFIG_DIR/dependabot-npm.yml" "$dir/.github/dependabot.yml"
  npm_synced=$((npm_synced + 1))
done

pip_synced=0
pip_skipped=0
for repo in "${PIP_REPOS[@]}"; do
  wants "$repo" || continue
  dir="$WORKSPACE/$repo"
  if [ ! -d "$dir" ]; then
    echo "SKIP $repo (not checked out at $dir)"
    pip_skipped=$((pip_skipped + 1))
    continue
  fi
  sync_file "$CONFIG_DIR/dependabot-pip.yml" "$dir/.github/dependabot.yml"
  pip_synced=$((pip_synced + 1))
done

echo "Dependabot sync complete: npm $npm_synced synced ($npm_skipped skipped), pip $pip_synced synced ($pip_skipped skipped)."
