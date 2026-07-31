#!/usr/bin/env bash
# Validate structure/repos.json against structure/repos.schema.json and a few
# fleet invariants the JSON Schema cannot express alone (unique names, etc.).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG="${OPENPHYSICS_CATALOG:-$ROOT/structure/repos.json}"
SCHEMA="${OPENPHYSICS_CATALOG_SCHEMA:-$ROOT/structure/repos.schema.json}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

if [[ ! -f "$CATALOG" ]]; then
  echo "catalog not found: $CATALOG" >&2
  exit 1
fi
if [[ ! -f "$SCHEMA" ]]; then
  echo "schema not found: $SCHEMA" >&2
  exit 1
fi

echo "Validating $CATALOG"

jq empty "$CATALOG"
jq empty "$SCHEMA"

# Prefer check-jsonschema when available (CI / local); fall back to structural asserts.
if command -v check-jsonschema >/dev/null 2>&1; then
  check-jsonschema --schemafile "$SCHEMA" "$CATALOG"
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import jsonschema' 2>/dev/null; then
  python3 - "$CATALOG" "$SCHEMA" <<'PY'
import json, sys
from jsonschema import Draft202012Validator

catalog_path, schema_path = sys.argv[1], sys.argv[2]
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)
with open(catalog_path, encoding="utf-8") as f:
    instance = json.load(f)
Draft202012Validator(schema).validate(instance)
print("jsonschema: ok")
PY
else
  echo "warning: neither check-jsonschema nor python3-jsonschema installed; running structural checks only" >&2
fi

# Fleet invariants (also covered by schema when a validator runs).
errors=0
assert_jq() {
  local label="$1"
  local expr="$2"
  local result
  result="$(jq -r "$expr" "$CATALOG")"
  if [[ "$result" != "true" && "$result" != "0" ]]; then
    echo "FAIL: $label ($result)" >&2
    errors=$((errors + 1))
  else
    echo "pass: $label"
  fi
}

assert_jq "unique repo names" '
  (.repos | length) as $n
  | (.repos | map(.name) | unique | length) == $n
'

assert_jq "isSimulation matches type" '
  all(.repos[]; .isSimulation == (.type == "simulation"))
'

assert_jq "simulations have lineage + non-empty screens" '
  all(.repos[] | select(.isSimulation);
    (.lineage == "original" or .lineage == "phet" or .lineage == "naap")
    and (.screens | type == "array" and length > 0)
  )
'

assert_jq "ports have matching upstream.org" '
  all(.repos[] | select(.lineage == "phet" or .lineage == "naap");
    (.upstream != null) and (.upstream.org == .lineage)
  )
'

assert_jq "non-ports have null upstream" '
  all(.repos[] | select(.lineage != "phet" and .lineage != "naap");
    .upstream == null
  )
'

assert_jq "deployedUrl host is lowercase openphysics when set" '
  all(.repos[] | select(.deployedUrl != null);
    (.deployedUrl | startswith("https://openphysics.github.io/"))
  )
'

assert_jq "status values are known" '
  all(.repos[];
    .status == "active" or .status == "template" or .status == "draft"
    or .status == "wip" or .status == "archived"
  )
'

if [[ "$errors" -ne 0 ]]; then
  echo "$errors catalog invariant(s) failed" >&2
  exit 1
fi

echo "Catalog OK ($(jq '.repos | length' "$CATALOG") repos, schemaVersion=$(jq -r .schemaVersion "$CATALOG"))"
