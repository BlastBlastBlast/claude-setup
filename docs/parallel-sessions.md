# Parallel sessions: `wt` + cmux — usage

Quick reference for running multiple isolated Claude Code sessions with git worktrees and cmux.

## Mental model

- **cmux vertical tab = a workspace = one terminal/session** in some directory (what you open manually).
- **git worktree = a second checkout of the same repo on its own branch**, in its own folder — so two sessions never collide.
- **`wt` = the glue:** it creates a worktree *and* opens a cmux tab sitting in it with `claude` already running — in one command.

## Commands

| Command | What it does |
|---|---|
| `wt new <branch>` | Create a worktree at `.worktrees/<branch>` on a new branch, then (inside cmux) open a **new vertical tab** in it with `claude` running. |
| `wt ls` | List active worktrees. |
| `wt rm <branch>` | Remove the worktree and delete the branch. (Close the cmux tab yourself.) |

Outside cmux, `wt new` just prints a `cd … && claude` hint instead of opening a tab.

**Lower-level / Claude-driven:** `wt` calls cmux's own CLI (`cmux new-workspace`, `cmux notify`, …) under the hood. You rarely type those, but the installed **cmux-skills** let Claude itself drive cmux — e.g. ask Claude to "open a worktree session for X", or have it notify you when a session needs input.

**No-worktree quick session:** Cmd+Shift+P → **"Claude session"** opens a claude-pane + shell-pane split **in the current directory** (no worktree) — for a quick in-place session.

## Typical sequence

You're in a tab with a terminal in, say, `~/dev/my-project` on `main`:

1. **Spin off an isolated session:** `wt new feature/login-fix`
   → a new vertical tab appears, already in `.worktrees/feature-login-fix` on branch `feature/login-fix`, with Claude running. Work there.
2. **More parallel sessions:** `wt new feature/other`, `wt new docs/cleanup` — each its own tab + branch + checkout. Your `main` tab stays clean throughout.
3. **Switch between them:** Cmd+1…9 or Cmd+P.
4. **See what's open:** `wt ls`.
5. **Done with a branch (merged/abandoned):** `wt rm feature/login-fix`, then close that tab.

## Cross-repo

Open a tab in a *different* repo and run `wt new …` there — it makes worktrees for *that* repo. So you can have your project feature tabs and another project's tabs side by side.

## Rule of thumb

- Isolated branch work in parallel → **`wt new <branch>`**
- A quick claude+shell in the directory you're already in → the **"Claude session"** palette command

## Known limitation

`wt rm` removes the git worktree and branch but does **not** close the cmux tab/workspace — close it manually. (Auto-close is a possible future enhancement.)
