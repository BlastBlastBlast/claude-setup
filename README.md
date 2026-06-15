# claude-setup

Global Claude Code + cmux configuration and automation. Canonical source of truth for
`~/.claude/`, `~/.config/cmux/`, and personal `bin/` tools; provisions tooling via Homebrew.

## Install (fresh machine)

```bash
git clone <repo-url> ~/dev/claude-setup
cd ~/dev/claude-setup
./install.sh
```

`install.sh` is idempotent: it symlinks config into place (backing up any pre-existing
real files to `*.bak.*`) and runs `brew bundle`. Re-run it any time after pulling changes.

## Claude Code

Claude Code is installed via its native self-updating installer (not Homebrew):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

It self-updates; do not also install the `claude-code` Homebrew cask (they conflict).

## Status line + context monitor (optional)

The status line and context-usage monitor are provided by the open-source
[`stigsb/claude-context-monitor`](https://github.com/stigsb/claude-context-monitor) (Go).
They are optional — if not installed, Claude Code simply runs without them. `settings.json`
references them at `$HOME/.local/bin/`. To enable:

```bash
go install github.com/stigsb/claude-context-monitor/...@latest
# put the built binaries where settings.json expects them:
ln -sf "$(go env GOPATH)/bin/claude-statusline"      "$HOME/.local/bin/claude-statusline"
ln -sf "$(go env GOPATH)/bin/claude-context-monitor" "$HOME/.local/bin/claude-context-monitor"
```

## Secrets

Never commit secrets. This repo ignores `.env*`, `*.pem`, `*.key` and runs a `gitleaks`
pre-commit hook (`core.hooksPath hooks`). For secrets the config must reference, use a
1Password (`op://…`) or `sops` reference, never a plaintext value.

## Layout

| Path | Symlinked to | Purpose |
|------|--------------|---------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | universal Claude Code principles |
| `claude/skills/` | `~/.claude/skills/` | global skills |
| `cmux/cmux.json` | `~/.config/cmux/cmux.json` | cmux workspace layouts |
| `bin/wt` | `~/.local/bin/wt` | worktree + cmux session lifecycle |
| `bin/promote-skill` | `~/.local/bin/promote-skill` | move skills between repo/global scope |

## Parallel sessions (`wt`)

`wt` manages a git worktree + cmux workspace per parallel task:

```bash
wt new feature/foo   # worktree at .worktrees/feature-foo on branch feature/foo + a cmux Claude session
wt new               # same, but auto-named (wt/scratch-<timestamp>-<pid>) when you haven't picked a name yet
wt ls                # list worktrees
wt rm feature/foo    # remove the worktree and delete the branch
```

Outside cmux, `wt new` prints the `cd … && claude` command instead of opening a workspace.

### `wt here` — isolate the current tab

`wt here [name]` creates an isolated worktree (off `main`, falling back to HEAD) but drops the
**current** cmux tab into it instead of spawning a new one. It prints only the worktree path to
stdout so you can `cd` into it; omit `[name]` to get an auto-named scratch branch you can rename
later with `git branch -m <name>`:

```bash
cd "$(wt here)"        # auto-named scratch branch, decide later
cd "$(wt here docs)"   # branch named 'docs'
```

Worktrees are always on a real branch (never detached), so work is never garbage-collected.

To skip the `cd "$(…)"` dance, source the optional shell integration so `wt here` cds your shell
automatically:

```bash
source /path/to/claude-setup/shell/wt.sh   # in ~/.zshrc or ~/.bashrc
wt here docs           # now cds the current shell into the worktree directly
```

`cmux-skills` (installed via `npx skills add manaflow-ai/cmux-skills`) lets Claude Code drive
cmux directly (open workspaces, post notifications).

📖 **Full usage guide:** [`docs/parallel-sessions.md`](docs/parallel-sessions.md) — mental model,
command reference, the typical sequence, cross-repo use, and the rule of thumb.

## Design

A layered global setup: universal principles in `claude/CLAUDE.md`; per-language conventions
as on-demand skills (`lang-python`, `lang-js`) authored via the `research-to-skill` meta-skill
from authoritative sources; permissions/hooks in `claude/settings.json`; and the `wt`
git-worktree + cmux workflow for isolating parallel Claude Code sessions. `promote-skill` moves
skills between repo-local and global scope.

## Tests

```bash
bats tests/
```
