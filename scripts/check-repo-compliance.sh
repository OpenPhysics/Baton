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
