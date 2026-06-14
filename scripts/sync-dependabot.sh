#!/usr/bin/env bash
# Sync canonical Dependabot configs from Baton/config/ to OpenPhysics repositories.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/config"
WORKSPACE_ROOT="$(cd "$REPO_ROOT/.." && pwd)"

NPM_REPOS=(
  DopplerEffect ElectricFieldOfDreams LadyBug LunarLander MazeGame MovingMan
  OpticsLab OscillationsAndChaos QubitSketch RadioWaves Resonance
  TemplateSingleSim TrackLab WaveComposer pyro jscd48 tscd48
)

sync_file() {
  local template="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  cp "$template" "$target"
  echo "Synced $target"
}

echo "Syncing Dependabot configs from $CONFIG_DIR"

sync_file "$CONFIG_DIR/dependabot-actions.yml" "$REPO_ROOT/.github/dependabot.yml"

for repo in "${NPM_REPOS[@]}"; do
  sync_file "$CONFIG_DIR/dependabot-npm.yml" "$WORKSPACE_ROOT/$repo/.github/dependabot.yml"
done

sync_file "$CONFIG_DIR/dependabot-pip.yml" "$WORKSPACE_ROOT/pycd48/.github/dependabot.yml"

echo "Dependabot sync complete."
