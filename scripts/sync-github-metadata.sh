#!/usr/bin/env bash
# Sync GitHub repository description and homepage from structure/repos.json.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/repos.sh
source "$SCRIPT_DIR/lib/repos.sh"

ORG="${OPENPHYSICS_ORG:-OpenPhysics}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: sync-github-metadata.sh [options]

Update GitHub repo description and website URL using structure/repos.json.

Options:
  --dry-run          Print planned changes without calling gh
  --simulation       Only simulation repositories
  --repo NAME        Sync a single repository
  -h, --help         Show this help

Requires: gh auth login with repo scope, jq installed.
EOF
}

REPO_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --simulation)
      FILTER_SIMULATION="true"
      shift
      ;;
    --repo)
      REPO_NAME="${2:?Missing value for --repo}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required" >&2
  exit 1
fi

repos_require_jq

if [[ -n "$REPO_NAME" ]]; then
  FILTER_NAME="$REPO_NAME"
fi

repos_json="$(repos_list_json)"
FILTER_NAME=""

count=0
while IFS= read -r repo; do
  name="$(jq -r '.name' <<<"$repo")"
  description="$(jq -r '.description // ""' <<<"$repo")"
  homepage="$(jq -r '.githubHomepage // ""' <<<"$repo")"

  echo "$name: homepage=${homepage:-"(none)"}"
  if [[ -n "$description" ]]; then
    if [[ ${#description} -le 80 ]]; then
      echo "  description: $description"
    else
      echo "  description: ${description:0:77}..."
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  dry-run: gh repo edit $ORG/$name ..."
    count=$((count + 1))
    continue
  fi

  cmd=(gh repo edit "$ORG/$name")
  if [[ -n "$description" ]]; then
    cmd+=(--description "$description")
  fi
  if [[ -n "$homepage" ]]; then
    cmd+=(--homepage "$homepage")
  fi

  if ! "${cmd[@]}"; then
    exit 1
  fi
  count=$((count + 1))
done < <(jq -c '.[]' <<<"$repos_json")

echo "Synced $count repositories."
