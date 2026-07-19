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

# ── SceneryStack simulation structure (see Baton/CONVENTIONS.md) ────────────────
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

  if compgen -G "src/*Colors.ts" >/dev/null; then
    pass "<Prefix>Colors.ts at src/ root"
  else
    fail "no <Prefix>Colors.ts at src/ root"
  fi

  # Constants: default is a root <Prefix>Constants.ts; a documented nested layout is
  # allowed (CONVENTIONS.md §2), but constants must exist somewhere under src/.
  if compgen -G "src/*Constants.ts" >/dev/null; then
    pass "<Prefix>Constants.ts at src/ root"
  elif [ -n "$(find src -mindepth 2 -name '*Constants.ts' -print -quit)" ]; then
    if [ -f CLAUDE.md ] && grep -qE '^## Compliance carve-outs' CLAUDE.md && grep -qiE 'nested constants' CLAUDE.md; then
      pass "nested *Constants.ts layout documented in CLAUDE.md Compliance carve-outs"
    else
      warn "no root <Prefix>Constants.ts — nested constants found; document under CLAUDE.md ## Compliance carve-outs"
    fi
  else
    fail "no *Constants.ts anywhere under src/"
  fi

  # The scenerystack Claude Code plugin roll-out (config/claude-settings.json).
  if [ ! -f .claude/settings.json ]; then
    fail ".claude/settings.json is missing (run Baton/scripts/sync-claude-settings.sh)"
  elif ! grep -q 'scenerystack@openphysics' .claude/settings.json; then
    fail ".claude/settings.json does not enable the scenerystack@openphysics plugin"
  else
    pass ".claude/settings.json enables the scenerystack plugin"
  fi

  # Hardcoded colors in view code (heuristic — ProfileColorProperty entries belong in
  # <Prefix>Colors.ts). Transparent rgba(0,0,0,0) hit-areas and icon/brand palettes are
  # accepted; anything else should be themed or documented as a carve-out in CLAUDE.md.
  color_hits="$(grep -rEn '"#[0-9a-fA-F]{3,8}"|rgba?\(' src --include='*.ts' 2>/dev/null \
    | grep -vE 'Colors\.ts|Icon|brand\.ts|rgba\( *0, *0, *0, *0 *\)|rgba\(0,0,0,0\)' || true)"
  if [ -n "$color_hits" ]; then
    if [ -f CLAUDE.md ] && grep -qE '^## Compliance carve-outs' CLAUDE.md && grep -qiE 'hardcoded colors' CLAUDE.md; then
      pass "hardcoded color carve-outs documented in CLAUDE.md ($(echo "$color_hits" | wc -l | tr -d ' ') hit(s))"
    else
      warn "possible hardcoded colors outside <Prefix>Colors.ts (theme or document under CLAUDE.md ## Compliance carve-outs):"
      echo "$color_hits" | sed 's/^/  /'
    fi
  else
    pass "no hardcoded colors outside <Prefix>Colors.ts"
  fi

  # Screen summaries (ACCESSIBILITY.md layer 2): per-screen *ScreenSummaryContent.ts
  # files (template pattern), an inline createScreenSummaryContent() factory
  # (OscillationsAndChaos pattern), or a direct `new ScreenSummaryContent(...)`
  # — one of the three must exist.
  if [ -n "$(find src -name '*ScreenSummaryContent.ts' -print -quit)" ] \
    || grep -rqE 'createScreenSummaryContent|new ScreenSummaryContent\(' src --include='*.ts'; then
    pass "screen summary content present"
  else
    warn "no *ScreenSummaryContent.ts and no ScreenSummaryContent construction — a11y screen summaries appear unwired (ACCESSIBILITY.md)"
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
    if [ ! -f "$d" ]; then
      fail "$d is missing"
    else
      # Presence is required (fail above); content is expected to be filled, not a
      # stub. Heuristic: count substantive lines (non-blank, non-heading, no TODO/
      # placeholder marker). A real doc has several; a copied-template stub has ~none.
      body_lines=$(grep -vE '^\s*$|^\s*#|TODO|TBD|FIXME|placeholder|fill in|\.\.\.$' "$d" | wc -l)
      if [ "$body_lines" -lt 5 ]; then
        warn "$d looks like a stub (only $body_lines substantive lines) — fill in the physics/architecture"
      else
        pass "$d is filled ($body_lines content lines)"
      fi
    fi
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
