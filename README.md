# claude-setup

Global Claude Code + cmux configuration and automation. The canonical source of truth for
`~/.claude/`, `~/.config/cmux/`, and personal `bin/` tools — symlinked into place and
provisioned via Homebrew, so a fresh machine matches this repo with one command.

## Install (fresh machine)

```bash
git clone <repo-url> ~/dev/claude-setup
cd ~/dev/claude-setup
./install.sh
```

`install.sh` is idempotent: it symlinks config into place (backing up any pre-existing real
files to `*.bak.*`), sets `core.hooksPath` to `hooks/`, and runs `brew bundle`. Re-run it any
time after pulling changes.

## What's in here

Everything below `claude/` is **user-level**, so once symlinked it applies in **every** repo
you open with Claude Code (each repo can still layer its own `CLAUDE.md`/`AGENTS.md` on top).

| Path | Symlinked / wired to | Purpose |
|------|----------------------|---------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Universal working principles — research/verify/reuse, complexity & typing discipline, git workflow, commits, tests, security. |
| `claude/settings.json` | `~/.claude/settings.json` | Model, status line, permissions (allow read-only/safe `git`+`gh`; **deny** reading `.env`/keys/`~/.ssh`), and the `PostToolUse` context-monitor hook. |
| `claude/skills/` | `~/.claude/skills/` | Global skills — see [Skills](#skills). |
| `cmux/cmux.json` | `~/.config/cmux/cmux.json` | cmux config + the **"Claude session"** workspace layout (claude pane + shell pane). |
| `bin/wt` | `~/.local/bin/wt` | git worktree + cmux session lifecycle — see [Parallel sessions](#parallel-sessions-wt--cmux). |
| `bin/promote-skill` | `~/.local/bin/promote-skill` | Move a skill between a repo's `.claude/skills/` and global scope. |
| `shell/wt.sh` | sourced from `~/.zshrc` (optional) | Makes `wt here` `cd` your shell into the worktree automatically. |
| `hooks/pre-commit` | `core.hooksPath=hooks` | `gitleaks` secret scan before every commit (this repo only). |

## Skills

**Language conventions** — auto-invoke when you write or review that language, biasing
generation toward expert-grade, idiomatic code. Each is sourced from authoritative references
(official docs / style guides / language maintainers), follows one 5-section template (Core
idioms · Reuse & helpers · Architecture · Anti-patterns · Sources), and cites every convention:

`lang-python` · `lang-js` · `lang-typescript` · `lang-go` · `lang-rust` · `lang-java` · `lang-kotlin`

**Meta / lifecycle:**

- **`research-to-skill`** — author a new conventions skill the right way: authoritative-source
  research first, the standard template, a required `Sources` block. Wraps superpowers
  `writing-skills`.
- **`bin/promote-skill`** — graduate a repo-local skill to global (`up`) or seed a repo-local
  one from a global skill (`down`); `--dry-run`/`--force`, validates the target first.

## Parallel sessions (`wt` + cmux)

`wt` pairs a **git worktree** (an isolated second checkout on its own branch) with a **cmux
workspace** (a vertical tab) so you can run many Claude Code sessions side by side without
collisions. Worktrees live at `<repo>/.worktrees/<branch>`, branched off `main`.

```bash
wt new [name]          # new worktree + a NEW cmux tab running claude, labeled <repo>/<branch>
wt here [name]         # turn the CURRENT tab into an isolated worktree:  cd "$(wt here [name])"
wt ls                  # list worktrees
wt rm <branch>         # remove the worktree and delete the branch (close the tab yourself)
```

- Omit `[name]` to get an auto-named scratch branch (`wt/scratch-<ts>-<pid>`) you can rename
  later with `git branch -m <name>`. Worktrees are always on a real branch (never detached),
  so work is never garbage-collected.
- The new tab is named **`<repo>/<branch>`** (e.g. `trusthere/feature-login`) so you can see at
  a glance which repo + worktree each session belongs to.
- Outside cmux, `wt new` prints a `cd … && claude` hint instead of opening a tab.
- Source the optional `shell/wt.sh` in your shell rc to drop the `cd "$(…)"` wrapper for
  `wt here`.

📖 **Full usage guide:** [`docs/parallel-sessions.md`](docs/parallel-sessions.md) — the cmux
vertical-tab/horizontal-surface model, keybindings, close/re-start, and cross-repo use.
`cmux-skills` (`npx skills add manaflow-ai/cmux-skills`) additionally lets Claude itself drive
cmux (open workspaces, post notifications).

## Claude Code

Claude Code is installed via its native self-updating installer (not Homebrew):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

It self-updates; do not also install the `claude-code` Homebrew cask (they conflict).

## Status line + context monitor (optional)

The status line and context-usage monitor come from the open-source
[`stigsb/claude-context-monitor`](https://github.com/stigsb/claude-context-monitor) (Go). They
are optional — without them Claude Code simply runs plain. `settings.json` references them at
`$HOME/.local/bin/`. To enable:

```bash
go install github.com/stigsb/claude-context-monitor/...@latest
ln -sf "$(go env GOPATH)/bin/claude-statusline"      "$HOME/.local/bin/claude-statusline"
ln -sf "$(go env GOPATH)/bin/claude-context-monitor" "$HOME/.local/bin/claude-context-monitor"
```

## Secrets

Never commit secrets. This repo ignores `.env*`, `*.pem`, `*.key` and runs a `gitleaks`
pre-commit hook (`core.hooksPath hooks`). For values the config must reference, use a
1Password (`op://…`) or `sops` reference — never a plaintext value. The global `settings.json`
also **denies Claude from reading** `.env*`, key files, and `~/.ssh/**` in any repo.

## Design

A layered global setup: universal principles in `claude/CLAUDE.md`; per-language conventions as
on-demand, expert-sourced skills authored via the `research-to-skill` meta-skill;
permissions/hooks in `claude/settings.json`; and the `wt` git-worktree + cmux workflow for
isolating parallel sessions. `promote-skill` moves skills between repo-local and global scope.

## Tests

```bash
bats tests/
```

Covers the executable surface (`wt`, `promote-skill`, install, hooks, settings) and a
frontmatter smoke check for every skill.
