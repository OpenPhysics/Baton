#!/usr/bin/env bash
# List OpenPhysics repositories from structure/repos.json.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: list-repos.sh [options]

Options:
  --simulation       Only simulation repositories
  --no-simulation    Only non-simulation repositories
  --type TYPE        Filter by repos.json type field
  --status STATUS    Filter by status field
  --json             Output JSON
  --names            Output names only (one per line)
  --paths            Output local workspace paths
  --require-local    With --paths, only existing directories
  --summary          Print catalog summary
  -h, --help         Show this help

Examples:
  list-repos.sh --simulation --names
  list-repos.sh --json
  list-repos.sh --paths --simulation --require-local
EOF
}

ARGS=()
FORMAT="text"
COMMAND="list"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulation|--no-simulation)
      ARGS+=("$1")
      shift
      ;;
    --type|--status)
      ARGS+=("$1" "${2:?Missing value for $1}")
      shift 2
      ;;
    --json)
      FORMAT="json"
      shift
      ;;
    --names)
      FORMAT="names"
      shift
      ;;
    --paths)
      COMMAND="paths"
      shift
      ;;
    --require-local)
      ARGS+=("--require-local")
      shift
      ;;
    --summary)
      COMMAND="summary"
      shift
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

if [[ "$COMMAND" == "summary" ]]; then
  exec "$SCRIPT_DIR/parse-repos.sh" summary "${ARGS[@]}"
fi

if [[ "$COMMAND" == "paths" ]]; then
  exec "$SCRIPT_DIR/parse-repos.sh" paths "${ARGS[@]}"
fi

exec "$SCRIPT_DIR/parse-repos.sh" list --format "$FORMAT" "${ARGS[@]}"
