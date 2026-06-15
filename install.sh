#!/usr/bin/env bash
# claude-setup installer: symlinks canonical config into place + brew bundle.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlink src -> dest. Idempotent: if dest is already the correct symlink, do
# nothing. If dest is any other existing file/dir/symlink, back it up first.
# Callers pass absolute paths for src (e.g. "$REPO_DIR/...") so the link resolves
# from anywhere.
link_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "${dest}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  ln -s "$src" "$dest"
}

# Create every symlink. Destinations derive from $HOME so tests can override it.
links() {
  link_file "$REPO_DIR/claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
  link_file "$REPO_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  link_file "$REPO_DIR/claude/skills"        "$HOME/.claude/skills"
  link_file "$REPO_DIR/cmux/cmux.json"     "${XDG_CONFIG_HOME:-$HOME/.config}/cmux/cmux.json"
  link_file "$REPO_DIR/bin/wt"             "$HOME/.local/bin/wt"
  link_file "$REPO_DIR/bin/promote-skill"  "$HOME/.local/bin/promote-skill"
}

# Point this repo's git hooks at the tracked hooks/ dir (secret-scan pre-commit).
_set_hooks_path() {
  git -C "$REPO_DIR" config core.hooksPath hooks 2>/dev/null || true
}

# Provision tools via Homebrew. Skipped (with a warning) if brew is absent.
run_brew() {
  if command -v brew >/dev/null 2>&1; then
    brew bundle --file="$REPO_DIR/Brewfile"
  else
    echo "Homebrew not found; skipping 'brew bundle'. Install from https://brew.sh" >&2
  fi
}

main() {
  set -euo pipefail
  links
  _set_hooks_path
  run_brew
  echo "claude-setup installed. (Pre-existing files, if any, saved as *.bak.*)"
}

# Run main only when executed, not when sourced (so tests can load functions).
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
