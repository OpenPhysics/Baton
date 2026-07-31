#!/usr/bin/env bash
# Create a new OpenPhysics simulation from SceneryStackTemplate.
#
# Uses the GitHub template repository (Use this template) when creating a remote,
# then runs npm rename + scaffold-screens so single- or multi-screen sims share
# one entrypoint. Optional --onboard finishes fleet landing-page assets and the
# workspace README; --pr opens follow-up PRs in Baton / OpenPhysics.
#
# Examples:
#   scripts/create-sim.sh --repo Friction --name "Friction"
#   scripts/create-sim.sh --repo Friction --name "Friction" --screens Intro,Lab --shared-model
#   scripts/create-sim.sh --repo Friction --name "Friction" --onboard --pr
#   scripts/create-sim.sh --repo Friction --name "Friction" --local-only --onboard
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/repos.sh
source "$SCRIPT_DIR/lib/repos.sh"

ORG="${OPENPHYSICS_ORG:-OpenPhysics}"
TEMPLATE_REPO="${TEMPLATE_REPO:-OpenPhysics/SceneryStackTemplate}"
WORKSPACE="$(repos_workspace_root)"
BATON_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO=""
SIM_ID=""
SIM_NAME=""
SCREENS=""
TARGET_PATH=""
LOCAL_ONLY=0
NO_PUSH=0
CATALOG=0
ONBOARD=0
OPEN_PR=0
SHARED_MODEL=0
DESCRIPTION=""

usage() {
  cat <<'EOF'
Usage: create-sim.sh --repo <PascalCase> --name "<Display Name>" [options]

Bootstrap a new SceneryStack simulation from SceneryStackTemplate.

Required:
  --repo NAME          GitHub / folder name (PascalCase), e.g. Friction
  --name "TITLE"       Display title, e.g. "Friction" or "Wave Interference"

Options:
  --id <kebab>         Package id (default: kebab-case of --repo)
  --screens LIST       Comma-separated screen titles, or kebab:Title pairs.
                       Default: one screen named after --name.
  --shared-model       Scaffold src/common/model/SharedModel.ts; each screen composes it
  --path DIR           Checkout path (default: $OPENPHYSICS_WORKSPACE/<repo>)
  --description TEXT   GitHub + catalog description
  --local-only         Copy local SceneryStackTemplate; do not create a GitHub repo
  --no-push            Do not git push the sim (default: no auto-push unless --pr)
  --catalog            Insert a repos.json entry in Baton (no commit)
  --onboard            Full fleet onboarding: catalog + screenshot + WebP + Pages
                       index + OpenPhysics README Layout row (implies --catalog)
  --pr                 After --onboard, commit/push and open PRs in Baton and
                       OpenPhysics (and push the sim bootstrap if not --local-only)
  -h, --help           Show this help

Requires: gh (unless --local-only), jq, npm, Node 24+.
  --onboard also needs Baton npm deps + Playwright Chromium for screenshots.
EOF
}

pascal_to_kebab() {
  # Friction → friction; WaveInterference → wave-interference
  sed -E 's/([a-z0-9])([A-Z])/\1-\2/g; s/([A-Z]+)([A-Z][a-z])/\1-\2/g' <<<"$1" | tr '[:upper:]' '[:lower:]'
}

insert_catalog_entry() {
  local catalog_path="$1"
  local entry="$2"
  if jq -e --arg name "$REPO" '.repos[] | select(.name == $name)' "$catalog_path" >/dev/null; then
    echo "  catalog: $REPO already present — leaving row unchanged"
    return 0
  fi
  local tmp
  tmp="$(mktemp)"
  jq --argjson entry "$entry" \
    '.repos = ((.repos + [$entry]) | sort_by(.name | ascii_downcase))' \
    "$catalog_path" >"$tmp"
  mv "$tmp" "$catalog_path"
  echo "  catalog: inserted $REPO into structure/repos.json"
}

update_workspace_readme() {
  local readme="$WORKSPACE/README.md"
  if [[ ! -f "$readme" ]]; then
    echo "warning: OpenPhysics README not found at $readme — skip Layout update" >&2
    return 0
  fi
  python3 - "$readme" "$REPO" <<'PY'
import re, sys
path, repo = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
# Simulation row: | `A`, `B`, ... | simulation | ...
pat = re.compile(
    r"(^\| )(`[^`]+`(?:, `[^`]+`)*)( \| simulation \|)",
    re.MULTILINE,
)
m = pat.search(text)
if not m:
    sys.stderr.write("warning: could not find simulation Layout row in README\n")
    sys.exit(0)
names = re.findall(r"`([^`]+)`", m.group(2))
if repo in names:
    print(f"  readme: {repo} already listed")
    sys.exit(0)
names.append(repo)
names.sort(key=str.lower)
new_list = ", ".join(f"`{n}`" for n in names)
text = text[: m.start(2)] + new_list + text[m.end(2) :]
open(path, "w", encoding="utf-8").write(text)
print(f"  readme: inserted `{repo}` into OpenPhysics README Layout (alphabetical)")
PY
}

ensure_baton_npm() {
  if [[ ! -d "$BATON_ROOT/node_modules" ]]; then
    echo "npm install (Baton)..."
    (cd "$BATON_ROOT" && npm install)
  fi
}

run_onboard_assets() {
  echo ""
  echo "Onboarding assets (screenshot → WebP → Pages)..."
  ensure_baton_npm
  if ! (cd "$BATON_ROOT" && npx playwright install chromium >/dev/null 2>&1); then
    echo "warning: playwright chromium install failed; screenshot may fail" >&2
  fi
  "$SCRIPT_DIR/generate-screenshots.sh" --build "$REPO"
  (cd "$BATON_ROOT" && npm run thumbnails -- "$REPO")
  (cd "$BATON_ROOT" && npm run pages)
  echo "  assets: screenshot + WebP + docs/index.html ready"
}

open_onboard_prs() {
  local branch="add/${REPO}"
  local baton_pr=""
  local op_pr=""

  # ── Sim repo ──────────────────────────────────────────────────────────────
  if [[ "$LOCAL_ONLY" -eq 0 ]]; then
    echo ""
    echo "Committing sim bootstrap..."
    (
      cd "$TARGET_PATH"
      git add -A
      if git diff --cached --quiet; then
        echo "  sim: nothing to commit"
      else
        git commit -m "$(cat <<EOF
chore: bootstrap from SceneryStackTemplate

Rename, scaffold screens, and capture the landing-page screenshot.
EOF
)"
      fi
      if [[ "$NO_PUSH" -eq 0 ]]; then
        git push -u origin HEAD
      fi
    )
  fi

  # ── Baton PR ──────────────────────────────────────────────────────────────
  echo ""
  echo "Opening Baton onboarding PR..."
  (
    cd "$BATON_ROOT"
    git fetch origin main >/dev/null 2>&1 || true
    git checkout -B "$branch" origin/main 2>/dev/null || git checkout -B "$branch"
    git add structure/repos.json "screenshots/${REPO}.png" "docs/assets/${REPO}.webp" docs/index.html 2>/dev/null || true
    # Also stage if screenshots path differs
    git add structure/repos.json screenshots docs 2>/dev/null || true
    if git diff --cached --quiet; then
      echo "  baton: nothing to commit (already on branch?)"
    else
      git commit -m "$(cat <<EOF
chore: onboard ${REPO} to the fleet catalog

Add catalog row, screenshot, WebP card, and regenerate the Pages index.
EOF
)"
    fi
    if [[ "$NO_PUSH" -eq 0 ]]; then
      git push -u origin "$branch"
      baton_pr="$(gh pr create --repo "$ORG/Baton" --base main --head "$branch" \
        --title "chore: onboard ${REPO}" \
        --body "$(cat <<EOF
## Summary
- Add \`${REPO}\` to \`structure/repos.json\`
- Landing-page screenshot + WebP thumbnail
- Regenerate \`docs/index.html\`

## Test plan
- [ ] Card appears under New/original on local \`docs/index.html\`
- [ ] Card links to https://openphysics.github.io/${REPO}/
- [ ] \`scripts/parse-repos.sh names --simulation | grep ${REPO}\`

EOF
)" 2>/dev/null || true)"
      if [[ -n "$baton_pr" ]]; then
        echo "  baton PR: $baton_pr"
      else
        echo "  baton: branch pushed ($branch); create/update the PR manually if needed"
      fi
    fi
  )

  # ── OpenPhysics PR ────────────────────────────────────────────────────────
  if [[ -d "$WORKSPACE/.git" ]]; then
    echo ""
    echo "Opening OpenPhysics README PR..."
    (
      cd "$WORKSPACE"
      git fetch origin main >/dev/null 2>&1 || true
      op_branch="docs/add-${REPO}"
      git checkout -B "$op_branch" origin/main 2>/dev/null || git checkout -B "$op_branch"
      git add README.md
      if git diff --cached --quiet; then
        echo "  openphysics: nothing to commit"
      else
        git commit -m "$(cat <<EOF
docs: add ${REPO} to the Layout simulation list

EOF
)"
      fi
      if [[ "$NO_PUSH" -eq 0 ]]; then
        git push -u origin "$op_branch"
        op_pr="$(gh pr create --repo "$ORG/OpenPhysics" --base main --head "$op_branch" \
          --title "docs: add ${REPO} to Layout" \
          --body "$(cat <<EOF
## Summary
- Add \`${REPO}\` to the simulation row in \`README.md\` \`## Layout\` (alphabetical)

## Test plan
- [ ] Name appears in the Layout table in alphabetical order

EOF
)" 2>/dev/null || true)"
        if [[ -n "$op_pr" ]]; then
          echo "  openphysics PR: $op_pr"
        else
          echo "  openphysics: branch pushed ($op_branch); create/update the PR manually if needed"
        fi
      fi
    )
  else
    echo "warning: OpenPhysics superproject is not a git checkout — skip README PR" >&2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:?Missing value for --repo}"
      shift 2
      ;;
    --id)
      SIM_ID="${2:?Missing value for --id}"
      shift 2
      ;;
    --name)
      SIM_NAME="${2:?Missing value for --name}"
      shift 2
      ;;
    --screens)
      SCREENS="${2:?Missing value for --screens}"
      shift 2
      ;;
    --path)
      TARGET_PATH="${2:?Missing value for --path}"
      shift 2
      ;;
    --description)
      DESCRIPTION="${2:?Missing value for --description}"
      shift 2
      ;;
    --local-only)
      LOCAL_ONLY=1
      shift
      ;;
    --no-push)
      NO_PUSH=1
      shift
      ;;
    --catalog)
      CATALOG=1
      shift
      ;;
    --onboard)
      ONBOARD=1
      CATALOG=1
      shift
      ;;
    --pr)
      OPEN_PR=1
      shift
      ;;
    --shared-model)
      SHARED_MODEL=1
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

if [[ -z "$REPO" || -z "$SIM_NAME" ]]; then
  echo "error: --repo and --name are required" >&2
  usage >&2
  exit 2
fi

if [[ "$OPEN_PR" -eq 1 && "$ONBOARD" -eq 0 ]]; then
  echo "error: --pr requires --onboard" >&2
  exit 2
fi

if [[ -z "$SIM_ID" ]]; then
  SIM_ID="$(pascal_to_kebab "$REPO")"
fi

if [[ -z "$TARGET_PATH" ]]; then
  TARGET_PATH="$WORKSPACE/$REPO"
fi

if [[ -e "$TARGET_PATH" ]]; then
  echo "error: path already exists: $TARGET_PATH" >&2
  exit 1
fi

if [[ -z "$DESCRIPTION" ]]; then
  DESCRIPTION="A SceneryStack simulation: ${SIM_NAME}."
fi

if [[ "$LOCAL_ONLY" -eq 0 ]] && ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI is required (or pass --local-only)" >&2
  exit 1
fi

repos_require_jq

SCREEN_ARGS=()
if [[ -n "$SCREENS" ]]; then
  SCREEN_ARGS=(--screens "$SCREENS")
fi
if [[ "$SHARED_MODEL" -eq 1 ]]; then
  SCREEN_ARGS+=(--shared-model)
fi

# Human-readable screen list for catalog
catalog_screens_json='[]'
if [[ -n "$SCREENS" ]]; then
  catalog_screens_json="$(
    python3 - "$SCREENS" <<'PY'
import json, sys
raw = sys.argv[1]
parts, cur, q = [], "", False
for ch in raw:
    if ch == '"':
        q = not q
        continue
    if ch == "," and not q:
        if cur.strip():
            parts.append(cur.strip().split(":", 1)[-1].strip())
        cur = ""
        continue
    cur += ch
if cur.strip():
    parts.append(cur.strip().split(":", 1)[-1].strip())
print(json.dumps(parts))
PY
  )"
else
  catalog_screens_json="$(jq -cn --arg n "$SIM_NAME" '[$n]')"
fi

echo "Creating simulation $REPO"
echo "  id:       $SIM_ID"
echo "  name:     $SIM_NAME"
echo "  path:     $TARGET_PATH"
echo "  screens:  ${SCREENS:-"(default: $SIM_NAME)"}"
echo "  shared:   $([[ "$SHARED_MODEL" -eq 1 ]] && echo yes || echo no)"
echo "  onboard:  $([[ "$ONBOARD" -eq 1 ]] && echo yes || echo no)"
echo "  template: $TEMPLATE_REPO"
echo ""

PARENT="$(dirname "$TARGET_PATH")"
mkdir -p "$PARENT"

if [[ "$LOCAL_ONLY" -eq 1 ]]; then
  SRC_TEMPLATE="$WORKSPACE/SceneryStackTemplate"
  if [[ ! -d "$SRC_TEMPLATE" ]]; then
    echo "error: local template not found at $SRC_TEMPLATE" >&2
    echo "  clone it first, or omit --local-only to use gh --template" >&2
    exit 1
  fi
  echo "Copying local template → $TARGET_PATH"
  rsync -a \
    --exclude node_modules \
    --exclude dist \
    --exclude .git \
    --exclude .cache \
    --exclude .vite \
    "$SRC_TEMPLATE/" "$TARGET_PATH/"
  git -C "$TARGET_PATH" init -b main
  git -C "$TARGET_PATH" add -A
  git -C "$TARGET_PATH" commit -m "chore: copy SceneryStackTemplate" >/dev/null
else
  echo "Creating GitHub repo from template..."
  (
    cd "$PARENT"
    gh repo create "$ORG/$REPO" \
      --public \
      --template "$TEMPLATE_REPO" \
      --description "$DESCRIPTION" \
      --homepage "https://openphysics.github.io/${REPO}" \
      --clone
  )
  if [[ "$(basename "$TARGET_PATH")" != "$REPO" ]]; then
    mv "$PARENT/$REPO" "$TARGET_PATH"
  fi
fi

cd "$TARGET_PATH"

echo ""
echo "npm install..."
npm install

echo ""
echo "npm run rename..."
npm run rename -- --id "$SIM_ID" --name "$SIM_NAME"

echo ""
echo "npm run scaffold-screens..."
npm run scaffold-screens -- "${SCREEN_ARGS[@]}"

# Keep package.json repository URL aligned with the new repo.
if [[ -f package.json ]]; then
  tmp="$(mktemp)"
  jq --arg url "https://github.com/${ORG}/${REPO}.git" \
    --arg desc "$DESCRIPTION" \
    '.repository.url = $url | .description = $desc' \
    package.json >"$tmp"
  mv "$tmp" package.json
fi

echo ""
echo "npm run fix..."
npm run fix

echo ""
echo "npm run check..."
npm run check

CATALOG_PATH="$(repos_catalog_path)"
entry="$(jq -n \
  --arg name "$REPO" \
  --arg display "$SIM_NAME" \
  --arg desc "$DESCRIPTION" \
  --arg url "https://openphysics.github.io/${REPO}" \
  --argjson screens "$catalog_screens_json" \
  '{
    name: $name,
    displayName: $display,
    type: "simulation",
    isSimulation: true,
    lineage: "original",
    upstream: null,
    language: ["TypeScript"],
    framework: "SceneryStack",
    description: $desc,
    deployedUrl: $url,
    physicsTopics: [],
    screens: $screens,
    status: "active"
  }')"

if [[ "$CATALOG" -eq 1 ]]; then
  echo ""
  echo "Catalog..."
  insert_catalog_entry "$CATALOG_PATH" "$entry"
fi

if [[ "$ONBOARD" -eq 1 ]]; then
  run_onboard_assets
  echo ""
  echo "Workspace README..."
  update_workspace_readme
fi

if [[ "$OPEN_PR" -eq 1 ]]; then
  open_onboard_prs
fi

echo ""
echo "Bootstrap complete: $TARGET_PATH"
echo ""
if [[ "$ONBOARD" -eq 1 ]]; then
  echo "Onboarded:"
  echo "  - Baton structure/repos.json"
  echo "  - ${REPO}/assets/screenshot.png"
  echo "  - Baton screenshots/${REPO}.png + docs/assets/${REPO}.webp"
  echo "  - Baton docs/index.html"
  echo "  - OpenPhysics README Layout row"
  if [[ "$OPEN_PR" -eq 1 ]]; then
    echo "  - follow-up PRs opened (see above)"
  else
    echo "  Review and commit; pass --pr next time to open Baton + OpenPhysics PRs."
  fi
else
  echo "Next steps (see Baton/doc/add-simulation.md):"
  echo "  1. Review: cd $TARGET_PATH && git status && git diff --stat"
  echo "  2. Commit bootstrap changes and push (unless --local-only / --no-push)."
  if [[ "$CATALOG" -eq 0 ]]; then
    echo "  3. Re-run with --onboard (or --catalog) to finish fleet landing-page assets."
  else
    echo "  3. Re-run with --onboard to capture screenshot/WebP/Pages + README."
  fi
fi
