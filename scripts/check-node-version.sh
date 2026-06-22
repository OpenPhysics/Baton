#!/usr/bin/env bash
# Assert the fleet's default Node version is in sync across the workflows that
# declare it. README.md ("Node version") says these "must stay in sync" — this
# turns that prose warning into an enforced check.
#
#   scripts/check-node-version.sh
#
# Exits non-zero (and prints what disagrees) if the versions diverge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WF="$ROOT/.github/workflows"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }

# Each entry: "label|file|extractor" where extractor is a grep -oP that yields the version.
# ci.yml / deploy.yml declare it as the `node-version` input default; fleet-health.yml
# sets it on the setup-node step.
declare -A VERSIONS

extract() {
  local file="$1" pattern="$2"
  [ -f "$file" ] || { fail "missing workflow: ${file#$ROOT/}"; return 1; }
  grep -oP "$pattern" "$file" | head -n1
}

# Quotes may be single or double across the workflows, so match either.
# ci.yml / deploy.yml declare it as the `node-version` input `default:`.
VERSIONS[ci.yml]="$(extract "$WF/ci.yml" $'default:\\s*["\']\\K[0-9]+(?=["\'])' || true)"
VERSIONS[deploy.yml]="$(extract "$WF/deploy.yml" $'default:\\s*["\']\\K[0-9]+(?=["\'])' || true)"
# fleet-health.yml: node-version: '24'  on the setup-node step.
VERSIONS[fleet-health.yml]="$(extract "$WF/fleet-health.yml" $'node-version:\\s*["\']\\K[0-9]+(?=["\'])' || true)"

echo "Declared Node versions:"
for f in ci.yml deploy.yml fleet-health.yml; do
  v="${VERSIONS[$f]:-}"
  echo "  $f: ${v:-<not found>}"
  [ -n "$v" ] || fail "$f: could not extract a Node version"
done

# All present versions must be identical.
uniq_versions="$(printf '%s\n' "${VERSIONS[@]}" | grep -v '^$' | sort -u | tr '\n' ' ' | sed 's/ $//')"
if [ "$FAIL" -eq 0 ] && [ "$(printf '%s' "$uniq_versions" | wc -w)" -ne 1 ]; then
  fail "Node versions diverge across workflows: $uniq_versions — bump all three together (see README 'Node version')"
fi

if [ "$FAIL" -ne 0 ]; then
  echo "Node-version check failed."
  exit 1
fi

echo "OK: all workflows agree on Node $uniq_versions"
echo "Node-version check passed."
