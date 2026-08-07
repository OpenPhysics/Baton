#!/usr/bin/env bash
# Check or apply the canonical GitHub repository settings baseline.
# Source of truth: config/github-repo-baseline.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/repos.sh
source "$SCRIPT_DIR/lib/repos.sh"

ORG="${OPENPHYSICS_ORG:-OpenPhysics}"
BASELINE_PATH="$(cd "$SCRIPT_DIR/.." && pwd)/config/github-repo-baseline.json"
MODE="check"
DRY_RUN=0
REPO_NAME=""
# Default: simulations + template (matches baseline.appliesTo.primary)
FILTER_SIMULATION=""
INCLUDE_TEMPLATE=1
ALL_CATALOG=0

usage() {
  cat <<'EOF'
Usage: sync-github-settings.sh [options]

Check or apply GitHub repository settings from config/github-repo-baseline.json
(wiki/projects off, Dependabot alerts + security updates, secret scanning +
push protection, private vulnerability reporting, Pages build_type=workflow).

By default operates on catalog simulations plus SceneryStackTemplate.

Modes:
  --check            Report drift; exit 1 if any (default)
  --apply            Enable missing baseline settings via the GitHub API
  --dry-run          With --apply, print actions without calling mutating APIs

Scope:
  --simulation       Simulations only (skip template)
  --all              Every catalog repo (public + private)
  --repo NAME        A single repository

Requires: gh auth login (repo scope), jq, python3.

Examples:
  scripts/sync-github-settings.sh --check
  scripts/sync-github-settings.sh --apply --repo CrystalLattice
  scripts/sync-github-settings.sh --apply --all
  scripts/sync-github-settings.sh --apply --dry-run --simulation
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      MODE="check"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --simulation)
      FILTER_SIMULATION="true"
      INCLUDE_TEMPLATE=0
      shift
      ;;
    --all)
      ALL_CATALOG=1
      INCLUDE_TEMPLATE=0
      shift
      ;;
    --repo)
      REPO_NAME="${2:?Missing value for --repo}"
      INCLUDE_TEMPLATE=0
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
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi
if [[ ! -f "$BASELINE_PATH" ]]; then
  echo "Baseline not found: $BASELINE_PATH" >&2
  exit 1
fi

repos_require_jq

if ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated; run: gh auth login" >&2
  exit 1
fi

if [[ -n "$REPO_NAME" ]]; then
  FILTER_NAME="$REPO_NAME"
fi
if [[ "$ALL_CATALOG" -eq 0 && -z "$REPO_NAME" && -z "${FILTER_SIMULATION:-}" ]]; then
  # Default primary scope: simulations (template added below)
  FILTER_SIMULATION="true"
fi

repos_json="$(repos_list_json)"
FILTER_NAME=""
FILTER_SIMULATION=""

names="$(jq -r '.[].name' <<<"$repos_json")"
if [[ "$INCLUDE_TEMPLATE" -eq 1 ]]; then
  if ! grep -qx 'SceneryStackTemplate' <<<"$names"; then
    names="${names}"$'\n'"SceneryStackTemplate"
  fi
fi

# Deduplicate while preserving order
names="$(printf '%s\n' "$names" | awk 'NF && !seen[$0]++')"

export ORG BASELINE_PATH MODE DRY_RUN
export NAMES_FILE
NAMES_FILE="$(mktemp)"
printf '%s\n' "$names" >"$NAMES_FILE"
trap 'rm -f "$NAMES_FILE"' EXIT

python3 <<'PY'
import json, os, subprocess, sys

ORG = os.environ["ORG"]
BASELINE = json.load(open(os.environ["BASELINE_PATH"]))
MODE = os.environ["MODE"]
DRY_RUN = os.environ.get("DRY_RUN", "0") == "1"
names = [n.strip() for n in open(os.environ["NAMES_FILE"]) if n.strip()]

repo_want = BASELINE["repository"]
sec_want = BASELINE["security"]
pages_want = (BASELINE.get("pages") or {}).get("build_type")

REPO_KEYS = [
    "has_issues", "has_wiki", "has_projects", "has_downloads",
    "allow_auto_merge", "allow_update_branch", "delete_branch_on_merge",
    "web_commit_signoff_required", "default_branch",
    "allow_squash_merge", "allow_merge_commit", "allow_rebase_merge",
    "squash_merge_commit_title", "squash_merge_commit_message",
    "merge_commit_title", "merge_commit_message",
]

SEC_STATUS_KEYS = [
    "dependabot_security_updates",
    "secret_scanning",
    "secret_scanning_push_protection",
    "secret_scanning_non_provider_patterns",
    "secret_scanning_validity_checks",
]


def gh_api(method, path, body=None, check=False):
    cmd = ["gh", "api", "-X", method, path]
    if body is not None:
        cmd += ["--input", "-"]
        p = subprocess.run(cmd, input=json.dumps(body), capture_output=True, text=True)
    else:
        p = subprocess.run(cmd, capture_output=True, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(p.stderr.strip() or p.stdout.strip() or f"gh api failed: {path}")
    return p.returncode, (p.stdout or "").strip(), (p.stderr or "").strip()


def st(sec, key):
    return (sec.get(key) or {}).get("status", "?")


drift_count = 0
ok_count = 0

for name in names:
    code, out, err = gh_api("GET", f"repos/{ORG}/{name}")
    if code != 0:
        print(f"{name}: ERROR fetch ({err[:100] or out[:100]})")
        drift_count += 1
        continue

    data = json.loads(out)
    private = bool(data.get("private"))
    sec = data.get("security_and_analysis") or {}
    homepage = data.get("homepage") or ""
    wants_pages = bool(data.get("has_pages")) or "github.io" in homepage
    issues = []

    for k in REPO_KEYS:
        if k not in repo_want:
            continue
        actual = data.get(k)
        expected = repo_want[k]
        if actual != expected:
            issues.append(f"{k}={actual!r} (want {expected!r})")

    # Vulnerability alerts: GET returns 204 when enabled, 404 when disabled
    vuln_code, _, _ = gh_api("GET", f"repos/{ORG}/{name}/vulnerability-alerts")
    vuln_on = vuln_code == 0
    if sec_want.get("vulnerability_alerts") and not vuln_on:
        issues.append("vulnerability_alerts=off")

    if not private:
        for k in SEC_STATUS_KEYS:
            if k not in sec_want:
                continue
            actual = st(sec, k)
            expected = sec_want[k]
            if actual != expected:
                issues.append(f"{k}={actual} (want {expected})")

        if sec_want.get("private_vulnerability_reporting"):
            pvr_code, pvr_out, _ = gh_api("GET", f"repos/{ORG}/{name}/private-vulnerability-reporting")
            pvr_on = False
            if pvr_code == 0:
                try:
                    pvr_on = bool(json.loads(pvr_out).get("enabled"))
                except Exception:
                    pvr_on = False
            if not pvr_on:
                issues.append("private_vulnerability_reporting=off")

        # Pages: only require workflow when the repo already has Pages or a homepage Pages URL
        if wants_pages and pages_want:
            p_code, p_out, _ = gh_api("GET", f"repos/{ORG}/{name}/pages")
            if p_code != 0:
                issues.append("pages=missing (want build_type=workflow)")
            else:
                build = json.loads(p_out).get("build_type")
                if build != pages_want:
                    issues.append(f"pages.build_type={build!r} (want {pages_want!r})")
    else:
        # Private: secret scanning / PVR often unavailable without Advanced Security.
        dep = st(sec, "dependabot_security_updates")
        if dep not in ("enabled", "?"):
            issues.append(f"dependabot_security_updates={dep} (want enabled)")

    if not issues:
        print(f"{name}: ok")
        ok_count += 1
        continue

    drift_count += 1
    print(f"{name}: DRIFT")
    for item in issues:
        print(f"  - {item}")

    if MODE != "apply":
        continue

    if DRY_RUN:
        print("  dry-run: would apply baseline")
        continue

    # Apply repository feature flags + security_and_analysis (public)
    patch = {k: repo_want[k] for k in REPO_KEYS if k in repo_want}
    if not private:
        patch["security_and_analysis"] = {
            "dependabot_security_updates": {"status": sec_want["dependabot_security_updates"]},
            "secret_scanning": {"status": sec_want["secret_scanning"]},
            "secret_scanning_push_protection": {"status": sec_want["secret_scanning_push_protection"]},
        }
    code, out, err = gh_api("PATCH", f"repos/{ORG}/{name}", patch)
    print(f"  patch: {'ok' if code == 0 else 'FAIL: ' + (err or out)[:120]}")

    if sec_want.get("vulnerability_alerts"):
        code, _, err = gh_api("PUT", f"repos/{ORG}/{name}/vulnerability-alerts")
        print(f"  vulnerability-alerts: {'ok' if code == 0 else 'FAIL: ' + err[:80]}")

    code, _, err = gh_api("PUT", f"repos/{ORG}/{name}/automated-security-fixes")
    print(f"  automated-security-fixes: {'ok' if code == 0 else 'FAIL: ' + err[:80]}")

    if not private and sec_want.get("private_vulnerability_reporting"):
        code, _, err = gh_api("PUT", f"repos/{ORG}/{name}/private-vulnerability-reporting")
        print(f"  private-vulnerability-reporting: {'ok' if code == 0 else 'FAIL: ' + err[:80]}")

    if not private and wants_pages and pages_want:
        p_code, _, _ = gh_api("GET", f"repos/{ORG}/{name}/pages")
        if p_code != 0:
            code, _, err = gh_api("POST", f"repos/{ORG}/{name}/pages", {"build_type": pages_want})
            print(f"  pages create: {'ok' if code == 0 else 'FAIL: ' + err[:80]}")
        else:
            code, _, err = gh_api("PUT", f"repos/{ORG}/{name}/pages", {"build_type": pages_want})
            print(f"  pages update: {'ok' if code == 0 else 'FAIL: ' + err[:80]}")

print()
print(f"ok={ok_count} drift={drift_count} total={len(names)} mode={MODE}")
if MODE == "check" and drift_count:
    sys.exit(1)
if MODE == "apply" and drift_count and not DRY_RUN:
    # Re-check quickly would be expensive; exit 0 if we attempted apply.
    # Callers can re-run --check.
    pass
PY
