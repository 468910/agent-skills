#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGETS=(
  "$HOME/.agent-skills"
  "$HOME/.codex"
  "$HOME/.opencode"
  "$HOME/.agy"
)

install() {
  local count=0
  for target in "${TARGETS[@]}"; do
    if [ -d "$target" ]; then
      # Remove existing symlinks from previous installs
      if [ -L "$target/AGENTS.md" ]; then
        rm "$target/AGENTS.md"
      fi
      if [ -L "$target/install.sh" ]; then
        rm "$target/install.sh"
      fi
      if [ -d "$target/skills" ] && [ -L "$target/skills" ]; then
        rm -rf "$target/skills"
      fi
    else
      mkdir -p "$target"
    fi

    ln -sf "$SCRIPT_DIR/AGENTS.md" "$target/AGENTS.md"
    ln -sf "$SCRIPT_DIR/install.sh" "$target/install.sh"
    ln -sf "$SCRIPT_DIR/skills" "$target/skills"
    count=$((count + 1))
    echo "Installed into $target/"
  done

  echo ""
  echo "Done. Installed agent-skills into $count target(s):"
  for target in "${TARGETS[@]}"; do
    echo "  - $target/"
  done
}

install
