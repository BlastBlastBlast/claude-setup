#!/usr/bin/env bash
# claude-setup installer: symlinks canonical config into place + brew bundle.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Oldest Claude Code this config is designed for. Older harnesses silently
# ignore unknown config: subagent spawn-depth cap needs >= 2.1.219, per-session
# caps 2.1.212, path-scoped rules ~2.1.198, PreToolUse exit-2 blocking 2.1.214.
# The check warns rather than fails - Claude Code self-updates, so drift is
# usually transient.
MIN_CLAUDE_CODE_VERSION="2.1.219"

check_claude_version() {
  if ! command -v claude >/dev/null 2>&1; then
    echo "warning: 'claude' not found on PATH - install via https://claude.ai/install.sh; this config expects >= ${MIN_CLAUDE_CODE_VERSION}" >&2
    return 0
  fi
  local ver
  ver="$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  if [ -z "$ver" ]; then
    echo "warning: could not parse 'claude --version' output; this config expects >= ${MIN_CLAUDE_CODE_VERSION}" >&2
    return 0
  fi
  if [ "$(printf '%s\n%s\n' "$MIN_CLAUDE_CODE_VERSION" "$ver" | sort -V | head -1)" != "$MIN_CLAUDE_CODE_VERSION" ]; then
    echo "warning: Claude Code ${ver} < ${MIN_CLAUDE_CODE_VERSION}; version-gated config (subagent caps, .claude/rules) will be silently ignored. Update Claude Code." >&2
  fi
  return 0
}

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
  link_file "$REPO_DIR/claude/rules"         "$HOME/.claude/rules"
  link_file "$REPO_DIR/cmux/cmux.json"     "${XDG_CONFIG_HOME:-$HOME/.config}/cmux/cmux.json"
  link_file "$REPO_DIR/bin/wt"             "$HOME/.local/bin/wt"
  link_file "$REPO_DIR/bin/promote-skill"  "$HOME/.local/bin/promote-skill"
  link_file "$REPO_DIR/bin/claude-guard-destructive" "$HOME/.local/bin/claude-guard-destructive"
  link_file "$REPO_DIR/shell/zshrc"                 "$HOME/.zshrc"
  link_file "$REPO_DIR/shell/sheldon/plugins.toml"  "${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
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
  check_claude_version
  links
  _set_hooks_path
  run_brew
  echo "claude-setup installed. (Pre-existing files, if any, saved as *.bak.*)"
}

# Run main only when executed, not when sourced (so tests can load functions).
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
