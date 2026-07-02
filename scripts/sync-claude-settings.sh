#!/usr/bin/env bash
# Roll the scenerystack Claude Code plugin out to the SceneryStack repos by merging
# the canonical keys from config/claude-settings.json into each repo's
# .claude/settings.json. Mirrors sync-dependabot.sh, but MERGES (never clobbers):
# existing keys in a repo's settings are preserved; only extraKnownMarketplaces.openphysics
# and enabledPlugins["scenerystack@openphysics"] are added/updated.
#
# Targets every repo whose catalog framework is "SceneryStack" (all the sims in
# structure/repos.json + the template — i.e. the CONVENTIONS.md scope). Operates on sibling checkouts in the workspace, like the
# other fleet scripts; it writes files only — committing/pushing (or opening PRs) is left to
# you or to fleet-exec.sh.
#
#   scripts/sync-claude-settings.sh --dry-run     # show what would change, write nothing
#   scripts/sync-claude-settings.sh               # merge into each sibling repo
#   scripts/sync-claude-settings.sh DopplerEffect # limit to named repo(s)
#
# To fan it out as one PR per repo instead, run the per-repo form under fleet-exec.sh
# (see scripts/README.md).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$REPO_ROOT/config/claude-settings.json"
CATALOG="${OPENPHYSICS_CATALOG:-$REPO_ROOT/structure/repos.json}"
WORKSPACE="${OPENPHYSICS_WORKSPACE:-$(cd "$REPO_ROOT/.." && pwd)}"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
[ -f "$SOURCE" ] || { echo "missing $SOURCE" >&2; exit 1; }

DRY_RUN=0
FILTER=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *) FILTER+=("$arg") ;;
  esac
done

# SceneryStack repos = the CONVENTIONS scope (sims + template).
mapfile -t REPOS < <(jq -r '.repos[] | select(.framework == "SceneryStack") | .name' "$CATALOG")

wants() {
  [ "${#FILTER[@]}" -eq 0 ] && return 0
  local name="$1"
  for f in "${FILTER[@]}"; do [ "$f" = "$name" ] && return 0; done
  return 1
}

changed=0
missing=0
for repo in "${REPOS[@]}"; do
  wants "$repo" || continue
  dir="$WORKSPACE/$repo"
  if [ ! -d "$dir/.git" ]; then
    echo "SKIP $repo (not checked out at $dir)"
    missing=$((missing + 1))
    continue
  fi

  target="$dir/.claude/settings.json"
  # Deep-merge SOURCE into TARGET (TARGET wins only for keys SOURCE doesn't set);
  # for our two keys SOURCE provides the canonical value. Reports whether it changed.
  result="$(SOURCE="$SOURCE" TARGET="$target" DRY_RUN="$DRY_RUN" python3 - "$repo" <<'PY'
import json, os, sys
repo = sys.argv[1]
src = json.load(open(os.environ["SOURCE"]))
target = os.environ["TARGET"]
try:
    with open(target) as f:
        cur = json.load(f)
except FileNotFoundError:
    cur = {}

def deep_merge(dst, add):
    for k, v in add.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            deep_merge(dst[k], v)
        else:
            dst[k] = v
    return dst

before = json.dumps(cur, sort_keys=True)
merged = deep_merge(json.loads(json.dumps(cur)), src)
after = json.dumps(merged, sort_keys=True)

if before == after:
    print("OK   %s (already up to date)" % repo)
    sys.exit(0)

if os.environ.get("DRY_RUN") == "1":
    print("WOULD UPDATE %s" % repo)
    sys.exit(10)

os.makedirs(os.path.dirname(target), exist_ok=True)
with open(target, "w") as f:
    json.dump(merged, f, indent=2)
    f.write("\n")
print("UPDATED %s" % repo)
sys.exit(10)
PY
)" && rc=0 || rc=$?
  echo "$result"
  [ "$rc" -eq 10 ] && changed=$((changed + 1))
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run: $changed repo(s) would change, $missing not checked out. Re-run without --dry-run to apply."
else
  echo "Done: $changed repo(s) updated, $missing not checked out."
  echo "Review, then commit/push per repo (or use fleet-exec.sh to open PRs)."
fi
