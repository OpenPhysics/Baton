#!/usr/bin/env bash
# generate-screenshots.sh — capture a screenshot of every OpenPhysics simulation.
#
# For each SceneryStack simulation listed in structure/repos.json this:
#   1. builds the sim if it has no dist/ (or --build is given),
#   2. serves the dist/ and renders the requested screen with the sim's own
#      ScreenshotGenerator (see screenshot.mjs),
#   3. writes the PNG to <sim>/assets/screenshot.png.
#
# By default screen 1 is captured (for multi-screen sims this is the first
# screen's play area, not the home-screen selector).
#
# Requires: node + the playwright dependency from this repo's package.json
# (`npm install` in the repo root once), jq, and a built sim or its npm deps.
#
# Usage:
#   scripts/generate-screenshots.sh [options] [SIM ...]
#
# Options:
#   --build         Force `npm run build` even if dist/ already exists.
#   --screen N      Screen index to capture (default: 1).
#   --width N       Viewport width (default: 1154).
#   --height N      Viewport height (default: 753).
#   -h, --help      Show this help.
#
# Positional SIM args limit the run to the named sims; omit to do all of them.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repo root is one level up from scripts/.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Workspace is the directory holding the org repo and the sibling sim repos.
WORKSPACE="${OPENPHYSICS_WORKSPACE:-$(cd "$REPO_ROOT/.." && pwd)}"
CATALOG="${OPENPHYSICS_CATALOG:-$REPO_ROOT/structure/repos.json}"

FORCE_BUILD=0
SCREEN=1
WIDTH=1154
HEIGHT=753
ONLY=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) FORCE_BUILD=1; shift ;;
    --screen) SCREEN="${2:?}"; shift 2 ;;
    --width) WIDTH="${2:?}"; shift 2 ;;
    --height) HEIGHT="${2:?}"; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *) ONLY+=("$1"); shift ;;
  esac
done

# Resolve the simulation list. Prefer the canonical parser; fall back to jq, then
# python3, so this still works on a WSL checkout where the .sh helpers carry CRLF
# endings or where jq is not installed.
sims="$("$SCRIPT_DIR/parse-repos.sh" names --simulation 2>/dev/null || true)"
if [[ -z "$sims" ]] && command -v jq >/dev/null 2>&1; then
  sims="$(jq -r '.repos[] | select(.isSimulation==true and .framework=="SceneryStack") | .name' "$CATALOG")"
fi
if [[ -z "$sims" ]] && command -v python3 >/dev/null 2>&1; then
  sims="$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
for r in d["repos"]:
    if r.get("isSimulation") and r.get("framework")=="SceneryStack": print(r["name"])' "$CATALOG")"
fi
if [[ -z "$sims" ]]; then
  echo "error: could not enumerate sims (need parse-repos.sh, jq, or python3)" >&2
  exit 1
fi

if [[ ${#ONLY[@]} -gt 0 ]]; then
  sims="$(printf '%s\n' "${ONLY[@]}")"
fi

ok=(); skipped=(); failed=()

for sim in $sims; do
  dir="$WORKSPACE/$sim"
  if [[ ! -d "$dir" ]]; then
    echo "skip  $sim (not checked out at $dir)"; skipped+=("$sim"); continue
  fi

  if [[ ! -f "$dir/dist/index.html" || $FORCE_BUILD -eq 1 ]]; then
    echo "build $sim ..."
    if [[ ! -d "$dir/node_modules" ]]; then
      ( cd "$dir" && npm ci )
    fi
    ( cd "$dir" && npm run build )
  fi

  mkdir -p "$dir/assets"
  echo "shoot $sim ..."
  if node "$SCRIPT_DIR/screenshot.mjs" \
      --dist "$dir/dist" \
      --out "$dir/assets/screenshot.png" \
      --screen "$SCREEN" --width "$WIDTH" --height "$HEIGHT"; then
    ok+=("$sim")
  else
    failed+=("$sim")
  fi
done

echo
echo "── summary ──────────────────────────────────────────"
echo "captured: ${#ok[@]}   skipped: ${#skipped[@]}   failed: ${#failed[@]}"
[[ ${#ok[@]}      -gt 0 ]] && echo "  ok:      ${ok[*]}"
[[ ${#skipped[@]} -gt 0 ]] && echo "  skipped: ${skipped[*]}"
[[ ${#failed[@]}  -gt 0 ]] && echo "  failed:  ${failed[*]}"
[[ ${#failed[@]} -eq 0 ]]
