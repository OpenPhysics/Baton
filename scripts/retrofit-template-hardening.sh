#!/usr/bin/env bash
# Thin wrapper: run retrofit-template-hardening.mjs against the current directory.
# Used by fleet-exec (cwd = temp clone) or locally from a sim root.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_DIR/retrofit-template-hardening.mjs" "$@"
