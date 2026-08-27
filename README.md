# claude-setup

Global Claude Code + cmux configuration and automation. The canonical source of truth for
`~/.claude/`, `~/.config/cmux/`, and personal `bin/` tools — symlinked into place and
provisioned via Homebrew, so a fresh machine matches this repo with one command.

## Why this exists

Out of the box, Claude Code is capable but unopinionated — it infers conventions per session,
and quality drifts with them. This repo encodes a senior engineer's defaults **once, globally**,
so every session in every repo starts with the same discipline, tooling, and guardrails instead
of relying on you to request (and re-request) them each time.

| | Vanilla Claude Code | With this setup |
|---|---|---|
| **Coding standards** | Infers patterns from training data | Researches current best practice and **cites** it; language skills bias generation toward expert-grade, idiomatic code |
| **Claims of "done"** | May assert success unverified | Must show the command + output as evidence before claiming done |
| **Reuse** | May reimplement existing logic inline | Finds and extends the canonical helper first |
| **Workflow** | Ad-hoc edits | Brainstorm → spec → plan → TDD → review, via the `superpowers` skills |
| **Git & commits** | Inconsistent | Branch from `main`, conventional commits, rebase-not-merge, merge-commit PRs |
| **Parallel work** | One session; branches collide | Many isolated `wt` worktree + cmux sessions running side by side |
| **Safety** | Reads anything; no secret guard | Denies reading `.env`/keys/`~/.ssh`; blocks destructive Bash (`rm -rf`, `sudo`, force-push) via a `PreToolUse` guard; `gitleaks` pre-commit; least-privilege command allowlist |
| **Reproducibility** | Drifts per machine | One repo, one `./install.sh`, symlinked into `~/.claude` everywhere |

The net effect: less babysitting and second-guessing. Claude defaults to the practices you'd
otherwise have to spell out every session — `claude/CLAUDE.md` carries the universal principles,
the skills make them executable, and the tooling (`wt`, hooks, permissions) enforces the rest.

## Install (fresh machine)

```bash
git clone <repo-url> ~/dev/claude-setup
cd ~/dev/claude-setup
./install.sh
```

`install.sh` is idempotent: it symlinks config into place (backing up any pre-existing real
files to `*.bak.*`), sets `core.hooksPath` to `hooks/`, and runs `brew bundle`. Re-run it any
time after pulling changes.

It also checks the Claude Code version against `MIN_CLAUDE_CODE_VERSION` (currently 2.1.219 —
the floor for the subagent caps and path-scoped rules this config uses) and **warns** if the
harness is older: outdated harnesses ignore unknown config silently, so a version below the
floor means the caps and rules simply don't apply. Claude Code self-updates, so the fix is
usually just restarting it.

## What's in here

Everything below `claude/` is **user-level**, so once symlinked it applies in **every** repo
you open with Claude Code (each repo can still layer its own `CLAUDE.md`/`AGENTS.md` on top).

| Path | Symlinked / wired to | Purpose |
|------|----------------------|---------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Universal working principles — research-before-assuming, reuse, file organisation & typing discipline, git workflow, commits, tests, security. |
| `claude/settings.json` | `~/.claude/settings.json` | Model, status line, permissions (allow read-only/safe `git`+`gh`; **deny** reading `.env`/keys/`~/.ssh`), and the `PostToolUse` context-monitor hook. |
| `claude/skills/` | `~/.claude/skills/` | Global skills — see [Skills](#skills). |
| `claude/rules/` | `~/.claude/rules/` | Path-scoped rules (`paths:` frontmatter) — load only when Claude reads matching files, keeping conditional guidance out of the always-loaded context. |
| `cmux/cmux.json` | `~/.config/cmux/cmux.json` | cmux config + the **"Claude session"** workspace layout (claude pane + shell pane). |
| `bin/wt` | `~/.local/bin/wt` | git worktree + cmux session lifecycle — see [Parallel sessions](#parallel-sessions-wt--cmux). |
| `bin/promote-skill` | `~/.local/bin/promote-skill` | Move a skill between a repo's `.claude/skills/` and global scope. |
| `bin/claude-guard-destructive` | `~/.local/bin/claude-guard-destructive` | `PreToolUse(Bash)` guard: blocks fetch-and-execute (`curl \| sh`), bare force-push (`--force-with-lease` stays allowed), AI-attribution footers, non-conventional commit messages, and merging main into a branch. |
| `bin/claude-guard-agent-dispatch` | `~/.local/bin/claude-guard-agent-dispatch` | `PreToolUse(Agent)` guard: blocks generic subagent dispatches that omit an explicit `model` (typed agents and forks exempt). |
| `docs/enforcement-tiers.md` | — | The classification procedure: which guidance becomes a hook, deny rule, path-scoped rule, or skill — plus authoring contracts and the tier inventory. |
| `shell/zshrc` | `~/.zshrc` | Managed zsh config — prompt, history (`atuin`), and tooling; sources `shell/wt.sh`. |
| `shell/sheldon/plugins.toml` | `~/.config/sheldon/plugins.toml` | `sheldon` zsh plugin declarations. |
| `shell/wt.sh` | sourced from `~/.zshrc` | Makes `wt here` `cd` your shell into the worktree automatically. |
| `hooks/pre-commit` | `core.hooksPath=hooks` | `gitleaks` secret scan before every commit (this repo only). |

## Skills

**Language conventions** — auto-invoke when you write or review that language, biasing
generation toward expert-grade, idiomatic code. Each is sourced from authoritative references
(official docs / style guides / language maintainers), follows one 5-section template (Core
idioms · Reuse & helpers · Architecture · Anti-patterns · Sources), and cites every convention:

`lang-python` · `lang-js` · `lang-typescript` · `lang-go` · `lang-rust` · `lang-java` · `lang-kotlin`

**Session workflow:**

- **`handoff`** — end-of-session handoff doc with a paste-ready continuation prompt at the top,
  so a fresh session resumes from one paste after `/clear`.

**Meta / lifecycle:**

- **`research-to-skill`** — author a new conventions skill the right way: authoritative-source
  research first, the standard template, a required `Sources` block. Wraps superpowers
  `writing-skills`.
- **`bin/promote-skill`** — graduate a repo-local skill to global (`up`) or seed a repo-local
  one from a global skill (`down`); `--dry-run`/`--force`, validates the target first.

Skills follow Claude 5-era conventions: trigger-sharp descriptions that state when NOT to fire,
judgment criteria instead of MUST/NEVER mandates, and lookup material in on-demand files rather
than the always-loaded body.

## Plugins

Plugins are enabled in `claude/settings.json` and apply in every repo. We keep the public set
**official-only** (from `anthropics/claude-plugins-official`) — installing a plugin runs its code
and hooks, so it is a code-trust decision; native config + `CLAUDE.md` conventions are preferred
over third-party plugins. A bats test enforces that the public `settings.json` enables only
official-marketplace plugins.

Enabled (official):

- **`superpowers`** — the brainstorm → spec → plan → TDD → review skill workflow. Runs under the
  **Claude 5 carve-outs** in `claude/CLAUDE.md` (Iron Laws as judgment rather than gates,
  brainstorming skipped for bounded mechanical tasks, reviews scaled to the diff, no subagent
  verifying its own session's work) — Opus 5-class models self-verify, so hard verification
  scaffolding written for older models now costs quality.
- **`code-review`** — PR-style review of a diff.
- **`security-guidance`** — security review of pending changes.
- **`code-simplifier`** — reuse/simplify/efficiency cleanups.
- **`skill-creator`** — author, evaluate, and benchmark skills (incl. description optimization + variance analysis).
- **`session-report`** — end-of-session summaries.
- **`pyright-lsp`** / **`typescript-lsp`** — language-server diagnostics for Python / TypeScript.

Deliberately disabled:

- **`feature-dev`** — its bundled code-reviewer only reports findings at confidence ≥ 80, which
  measurably depresses review recall on Opus 5 (Anthropic's guidance: report everything, filter in
  a separate pass); it also duplicates the superpowers pipeline.

📖 Rationale, trust notes, and surface tags for every plugin (official vs community):
[`docs/plugins.md`](docs/plugins.md).

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

## Review handoffs (crit)

[`crit`](https://crit.md/) (installed via the `Brewfile`) gives a local PR-style review loop for
agent output. Per a `claude/CLAUDE.md` convention, when Claude would ask you to eyeball a diff,
plan/doc, or rendered UI, it offers to open it in Crit instead — `crit` for the working diff,
`crit <file>` for a doc, live-app/static-HTML mode for UI. It is an offer, not a gate, and only when
`crit` is on `PATH`.

## Status line + context monitor (optional)

The status line and context-usage monitor come from the open-source
[`stigsb/claude-context-monitor`](https://github.com/stigsb/claude-context-monitor) (Go). They
are genuinely optional: `settings.json` references them at `$HOME/.local/bin/` behind an
`[ -x … ]` check, so if they aren't installed the hook and status line exit silently and
Claude Code simply runs plain. To enable:

```bash
brew install go
go install github.com/stigsb/claude-context-monitor/...@latest
./install.sh   # links whatever it finds in $(go env GOPATH)/bin
```

`install.sh` links the two binaries if they are already built, and otherwise prints a one-line
note with these commands — so a fresh machine is told once, at install time, rather than
discovering it later.

## Secrets

Never commit secrets. This repo ignores `.env*`, `*.pem`, `*.key` and runs a `gitleaks`
pre-commit hook (`core.hooksPath hooks`). For values the config must reference, use a
1Password (`op://…`) or `sops` reference — never a plaintext value. The global `settings.json`
also **denies Claude from reading** `.env*`, key files, and `~/.ssh/**` in any repo, and a
`PreToolUse` guard (`bin/claude-guard-destructive`) blocks destructive Bash commands (`rm -rf`,
`sudo`, `git push --force`) before they run.

## Design

A layered global setup: universal principles in `claude/CLAUDE.md`; per-language conventions as
on-demand, expert-sourced skills authored via the `research-to-skill` meta-skill;
permissions/hooks in `claude/settings.json`; and the `wt` git-worktree + cmux workflow for
isolating parallel sessions. `promote-skill` moves skills between repo-local and global scope.

The setup is tuned for the **Claude 5 / Opus 5 generation** (2026-08): advisory prose only where
judgment is wanted; deterministic layers — hooks, permission deny rules, subagent caps
(`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`/`_CONCURRENT_SUBAGENTS`) — for everything that must never
happen; verification right-sized to the diff instead of mandated; and a lean CLAUDE.md with
conditional guidance pushed into skills (task-conditional) and `claude/rules/`
(path-conditional). `install.sh` guards the harness version floor these mechanisms need. Sources: Anthropic's
[Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
and [The new rules of context engineering for Claude 5-generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models).

## Tests

```bash
bats tests/
```

Covers the executable surface (`wt`, `promote-skill`, install, hooks, settings) and a
frontmatter smoke check for every skill.
