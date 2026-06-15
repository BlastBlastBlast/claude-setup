# claude-setup Brewfile — install/update everything with: brew bundle
# Source of truth for tooling; brew-first policy (no manual downloads).

# ── Claude Code + AI workflow ───────────────────────────────────────────────────
# Claude Code itself is installed via its native self-updating installer (see README),
# NOT Homebrew — managing it via brew fights the auto-updater.
cask "cmux"                         # cmux — native macOS terminal for AI agents (cmux.com)

# ── Core dev toolchain ──────────────────────────────────────────────────────────
brew "git"
brew "git-lfs"                      # large binary/asset storage (see design spec)
brew "gh"                           # GitHub CLI
brew "uv"                           # Python package manager
brew "go"                           # for `go install` of the optional statusline/context-monitor

# ── Quality / safety ────────────────────────────────────────────────────────────
brew "gitleaks"                     # secret scanning (pre-commit guard)

# ── Test tooling ─────────────────────────────────────────────────────────────────
brew "bats-core"                    # shell test runner used by this repo
