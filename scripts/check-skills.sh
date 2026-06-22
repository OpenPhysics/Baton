#!/usr/bin/env bash
# Validate the SceneryStack skills collection (Baton/skills/).
#
# Each skill is a folder containing a SKILL.md (the standard Claude Code layout, also
# what the scenerystack plugin ships — see .claude-plugin/). This enforces that every
# skill is well-formed and that the README index stays in sync with the folders on
# disk — the kind of drift that rots silently as the collection grows.
#
#   scripts/check-skills.sh
#
# Exit non-zero on any failure so CI can gate on it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../skills" && pwd)"
README="$SKILLS_DIR/README.md"

FAIL=0
fail() { echo "FAIL: $1"; FAIL=1; }
pass() { echo "OK: $1"; }

[ -f "$README" ] || { echo "FAIL: skills/README.md is missing"; exit 1; }

# Collect skill folders (every directory holding a SKILL.md).
mapfile -t SKILL_DIRS < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

skill_count=0
for name in "${SKILL_DIRS[@]}"; do
  path="$SKILLS_DIR/$name/SKILL.md"
  if [ ! -f "$path" ]; then
    fail "$name/: folder has no SKILL.md"
    continue
  fi
  skill_count=$((skill_count + 1))

  # 1. Frontmatter block must open on line 1 and close.
  if [ "$(head -n1 "$path")" != "---" ]; then
    fail "$name: SKILL.md must start with a '---' frontmatter block on line 1"
    continue
  fi
  frontmatter="$(awk 'NR>1 && /^---[[:space:]]*$/{exit} NR>1{print}' "$path")"

  # 2. name: present and matches the folder name.
  fm_name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -n1)"
  if [ -z "$fm_name" ]; then
    fail "$name: frontmatter is missing a 'name:' field"
  elif [ "$fm_name" != "$name" ]; then
    fail "$name: frontmatter name '$fm_name' must match folder name '$name'"
  fi

  # 3. description: present, phrased as a trigger ("Use when/whenever/to …"),
  #    and substantial enough to actually disambiguate when the skill applies.
  fm_desc="$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -n1)"
  if [ -z "$fm_desc" ]; then
    fail "$name: frontmatter is missing a 'description:' field"
  else
    case "$fm_desc" in
      "Use "*) : ;;
      *) fail "$name: description should be a trigger starting with 'Use …'. Found: '${fm_desc:0:40}…'" ;;
    esac
    [ "${#fm_desc}" -ge 40 ] || fail "$name: description is too short to be a useful trigger (<40 chars)"
  fi

  # 4. Listed in the README index.
  if ! grep -q "\`$name\`" "$README"; then
    fail "$name: skill is not referenced in skills/README.md index"
  fi
done

# 5. Reverse direction: every scenerystack-* skill referenced in the README must exist.
mapfile -t REFERENCED < <(grep -oE 'scenerystack-[a-z0-9-]+' "$README" | sort -u)
for ref in "${REFERENCED[@]}"; do
  [ -f "$SKILLS_DIR/$ref/SKILL.md" ] || fail "README references '$ref' but skills/$ref/SKILL.md does not exist"
done

if [ "$FAIL" -ne 0 ]; then
  echo "Skills check failed."
  exit 1
fi

pass "validated $skill_count skill folder(s); README index in sync"
echo "Skills check passed."
