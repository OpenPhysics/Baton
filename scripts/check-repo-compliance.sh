#!/usr/bin/env bash
# Compliance checks for OpenPhysics SceneryStack simulation repositories.
set -euo pipefail

REPO_DIR="${1:?Repository directory required}"
cd "$REPO_DIR"

echo "Checking compliance in: $(pwd)"
FAIL=0
WARN=0

fail() {
  echo "FAIL: $1"
  FAIL=1
}

warn() {
  echo "WARN: $1"
  WARN=1
}

pass() {
  echo "OK: $1"
}

if [ -f CONTRIBUTING.md ]; then
  fail "CONTRIBUTING.md must not exist at repo root (use org default from OpenPhysics/.github)"
else
  pass "no local CONTRIBUTING.md"
fi

if [ -f LICENSE ]; then
  fail "LICENSE must not exist at repo root (use org default from OpenPhysics/.github)"
else
  pass "no local LICENSE"
fi

REQUIRED_SECTIONS=(
  "Features"
  "Quick Start"
  "Scripts"
  "Tech Stack"
  "License"
  "Contributing"
)

if [ ! -f README.md ]; then
  fail "README.md is missing"
else
  mapfile -t HEADINGS < <(grep -E '^## ' README.md | sed 's/^## //')
  for heading in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^## ${heading}" README.md; then
      fail "README.md missing '## ${heading}' section"
    else
      pass "README has ## ${heading}"
    fi
  done

  expected_index=0
  for heading in "${HEADINGS[@]}"; do
    if [ "$expected_index" -ge "${#REQUIRED_SECTIONS[@]}" ]; then
      fail "README.md has unexpected section '## ${heading}' (only standard sections allowed)"
      continue
    fi
    if [ "$heading" != "${REQUIRED_SECTIONS[$expected_index]}" ]; then
      if [ "$expected_index" -eq 0 ] && [ "$heading" = "Screens" ]; then
        fail "README.md must use '## Features' instead of '## Screens'"
      else
        fail "README.md section order wrong: expected '## ${REQUIRED_SECTIONS[$expected_index]}', found '## ${heading}'"
      fi
    else
      ((expected_index++)) || true
    fi
  done

  if [ "$expected_index" -ne "${#REQUIRED_SECTIONS[@]}" ]; then
    fail "README.md is missing one or more required sections after '## Features'"
  else
    pass "README section order matches standard outline"
  fi
fi

if [ ! -f .github/workflows/ci.yml ]; then
  fail ".github/workflows/ci.yml is missing"
elif ! grep -q "OpenPhysics/Baton/.github/workflows/ci.yml@main" .github/workflows/ci.yml; then
  fail "ci.yml must call OpenPhysics/Baton reusable workflow"
else
  pass "ci.yml uses shared reusable workflow"
fi

if ! grep -q "OpenPhysics/Baton/.github/workflows/shared-dependency-review.yml@main" .github/workflows/ci.yml; then
  fail "ci.yml must call shared dependency-review workflow"
elif ! grep -q "OpenPhysics/Baton/.github/workflows/shared-codeql.yml@main" .github/workflows/ci.yml; then
  fail "ci.yml must call shared CodeQL workflow"
else
  pass "ci.yml uses shared security workflows"
fi

if [ -f package.json ]; then
  if [ ! -f .github/dependabot.yml ]; then
    fail ".github/dependabot.yml is missing for npm repository"
  else
    pass "dependabot.yml present"
  fi
elif [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
  if [ ! -f .github/dependabot.yml ]; then
    fail ".github/dependabot.yml is missing for python repository"
  else
    pass "dependabot.yml present"
  fi
fi

# ── SceneryStack simulation structure (see OpenPhysics/CONVENTIONS.md) ──────────
# Only applies to sim repos (npm package with a src/main.ts bootstrap entry).
if [ -f package.json ] && [ -f src/main.ts ]; then
  for f in init assert splash brand main; do
    [ -f "src/$f.ts" ] || fail "src/$f.ts is missing (bootstrap chain)"
  done

  first_import="$(grep -m1 -E '^import ' src/main.ts || true)"
  if printf '%s' "$first_import" | grep -q '"\./brand'; then
    pass "main.ts imports ./brand first"
  else
    fail "src/main.ts's first import must be \"./brand.js\""
  fi

  root_ns="$(find src -maxdepth 1 -name '*Namespace.ts')"
  nested_ns="$(find src -mindepth 2 -name '*Namespace.ts')"
  if [ -z "$root_ns" ]; then
    fail "no <Prefix>Namespace.ts at src/ root"
  elif [ -n "$nested_ns" ]; then
    fail "<Prefix>Namespace.ts must be at src/ root, found nested: $(echo "$nested_ns" | tr '\n' ' ')"
  else
    pass "<Prefix>Namespace.ts at src/ root"
  fi

  if [ ! -d src/preferences ]; then
    fail "src/preferences/ is missing"
  else
    pref_ok=1
    compgen -G "src/preferences/*PreferencesModel.ts" >/dev/null || { fail "src/preferences/<Prefix>PreferencesModel.ts is missing"; pref_ok=0; }
    compgen -G "src/preferences/*PreferencesNode.ts"  >/dev/null || { fail "src/preferences/ needs at least one *PreferencesNode.ts"; pref_ok=0; }
    compgen -G "src/preferences/*QueryParameters.ts"  >/dev/null || { fail "src/preferences/<prefix>QueryParameters.ts is missing"; pref_ok=0; }
    [ "$pref_ok" -eq 1 ] && pass "src/preferences/ has Model, Node, and QueryParameters"
  fi

  if [ ! -f src/i18n/StringManager.ts ]; then
    fail "src/i18n/StringManager.ts is missing"
  else
    loc_miss=""
    for loc in en es fr; do
      [ -f "src/i18n/strings_$loc.json" ] || loc_miss="$loc_miss strings_$loc.json"
    done
    if [ -n "$loc_miss" ]; then
      fail "src/i18n/ missing locale file(s):$loc_miss"
    else
      pass "src/i18n/ has StringManager + en/es/fr locales"
    fi
  fi

  stray_tests="$(find src \( -name '*.test.ts' -o -name '*.spec.ts' \) 2>/dev/null)"
  stray_testdirs="$(find src -type d -name '__tests__' 2>/dev/null)"
  if [ -n "$stray_tests" ] || [ -n "$stray_testdirs" ]; then
    fail "tests must live under tests/, not in src/ ($(echo "$stray_tests $stray_testdirs" | tr '\n' ' '))"
  else
    pass "no tests co-located under src/"
  fi

  for d in doc/model.md doc/implementation-notes.md; do
    [ -f "$d" ] || fail "$d is missing"
  done

  if [ -f biome.json ]; then
    if grep -q 'biomejs.dev/schemas/2\.5' biome.json; then
      pass "biome.json on 2.5 schema"
    else
      fail "biome.json must reference the 2.5.x schema"
    fi
  fi

  for d in src/model src/view; do
    [ -d "$d" ] && warn "$d exists at src/ root — model/ and view/ belong inside a screen folder"
  done
fi

REPO_NAME=""
if [ -n "${GITHUB_REPOSITORY:-}" ]; then
  REPO_NAME="${GITHUB_REPOSITORY##*/}"
fi
if [ -z "$REPO_NAME" ]; then
  REPO_NAME="$(basename "$REPO_DIR")"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  VULN_ALERTS=$(gh api graphql -f query='query($o:String!,$n:String!){ repository(owner:$o,name:$n){ hasVulnerabilityAlertsEnabled isPrivate } }' -f o=OpenPhysics -f n="$REPO_NAME" --jq '.data.repository.hasVulnerabilityAlertsEnabled' 2>/dev/null || echo "")
  if [ "$VULN_ALERTS" = "true" ]; then
    pass "Dependabot vulnerability alerts enabled"
  elif [ -n "$VULN_ALERTS" ]; then
    fail "Dependabot vulnerability alerts are not enabled on GitHub"
  else
    warn "Could not verify GitHub vulnerability alerts (gh query failed)"
  fi

  SEC_JSON=$(gh api "repos/OpenPhysics/$REPO_NAME" --jq '.security_and_analysis // {}' 2>/dev/null || echo "{}")
  IS_PRIVATE=$(gh api "repos/OpenPhysics/$REPO_NAME" --jq '.private' 2>/dev/null || echo "false")
  if [ -n "$SEC_JSON" ] && [ "$SEC_JSON" != "{}" ] && [ "$SEC_JSON" != "null" ]; then
    DEP_UPDATES=$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("dependabot_security_updates",{}).get("status","unknown"))' <<<"$SEC_JSON")
    if [ "$DEP_UPDATES" = "enabled" ]; then
      pass "Dependabot security updates enabled"
    else
      fail "Dependabot security updates are not enabled on GitHub"
    fi

    if [ "$IS_PRIVATE" != "true" ]; then
      SECRET_SCAN=$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("secret_scanning",{}).get("status","unknown"))' <<<"$SEC_JSON")
      if [ "$SECRET_SCAN" = "enabled" ]; then
        pass "secret scanning enabled"
      else
        fail "Secret scanning is not enabled on GitHub"
      fi
    else
      pass "private repo: secret scanning check skipped"
    fi
  elif [ "$IS_PRIVATE" = "true" ]; then
    pass "private repo: dependabot security updates assumed enabled when vulnerability alerts are on"
  else
    warn "Could not read security_and_analysis settings from GitHub"
  fi
else
  warn "gh not available; skipping live GitHub security setting checks"
fi

if [ "$FAIL" -ne 0 ]; then
  echo "Compliance check failed."
  exit 1
fi

if [ "$WARN" -ne 0 ]; then
  echo "Compliance check passed with warnings."
else
  echo "Compliance check passed."
fi
