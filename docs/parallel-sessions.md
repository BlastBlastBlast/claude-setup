# Parallel sessions: `wt` + cmux — usage

Quick reference for running multiple isolated Claude Code sessions with git worktrees and cmux.

## Mental model

- **git worktree** = a second checkout of the same repo on its own branch, in its own folder —
  so two sessions never collide.
- **cmux has two levels of "tabs":**
  - **Vertical tabs** (left sidebar) = **workspaces** — one session in one directory. This is
    what `wt` creates.
  - **Horizontal tabs inside a workspace** = **surfaces / panes** — multiple terminals (or a
    browser/editor) within one workspace.
- **`wt` = the glue:** it creates a worktree *and* opens a cmux workspace sitting in it with
  `claude` already running — in one command — labeled `<repo>/<branch>`.

## `wt` commands

`wt` always acts on the repo of your **current directory**. Worktrees live at
`<repo>/.worktrees/<branch>`, branched off `main` (falling back to `HEAD`).

| Command | What it does |
|---|---|
| `wt new [name]` | Create a worktree on a new branch, then (inside cmux) open a **new vertical tab** in it with `claude` running, named `<repo>/<branch>`. |
| `cd "$(wt here [name])"` | Create a worktree but drop the **current** tab into it (renames the workspace `<repo>/<branch>`). Prints only the path on stdout, hence the `cd "$(…)"` wrapper. |
| `wt ls` | List active worktrees. |
| `wt rm <branch>` | Remove the worktree and delete the branch. (Close the cmux tab yourself.) |

- Omit `[name]` to get an auto-named scratch branch (`wt/scratch-<ts>-<pid>`); rename later with
  `git branch -m <name>`. Worktrees are always on a real branch (never detached), so work is
  never garbage-collected.
- Outside cmux, `wt new` just prints a `cd … && claude` hint instead of opening a tab.
- Source the optional `shell/wt.sh` in your shell rc to make `wt here` `cd` your shell directly
  (no `cd "$(…)"` wrapper needed).

## cmux keybindings (defaults)

| Level | Action | Shortcut |
|---|---|---|
| **Vertical tabs** (workspaces) | select by number / jump | **⌘1–9** / **⌘P** |
| | rename / close / group | **⌘⇧R** / **⌘⇧W** / **⌘⇧G** |
| **Horizontal tabs** (surfaces in a workspace) | new surface / new tab / close tab | **⌘T** / **⌘N** / **⌘W** |
| | next / prev / pick by number | **⌘⇧]** / **⌘⇧[** / **⌃1** |
| | split right / split down | **⌘D** / **⌘⇧D** |
| | move focus / zoom split / equalize | **⌘⌥←↑↓→** / **⌘⇧↵** / **⌘⌃=** |
| Either | command palette | **⌘⇧P** |

**No-worktree quick session:** **⌘⇧P** → **"Claude session"** opens a claude-pane + shell-pane
split **in the current directory** (no worktree) — for a quick in-place session.

## Typical sequence

You're in a tab with a terminal in, say, `~/dev/my-project` on `main`:

1. **Spin off an isolated session:** `wt new feature/login-fix`
   → a new vertical tab `my-project/feature-login-fix` appears, in `.worktrees/feature-login-fix`
   on branch `feature/login-fix`, with Claude running. Work there.
2. **More parallel sessions:** `wt new feature/other`, `wt new docs/cleanup` — each its own tab +
   branch + checkout. Your `main` tab stays clean throughout.
3. **Switch between them:** **⌘1–9** or **⌘P**.
4. **See what's open:** `wt ls`.
5. **Done with a branch (merged/abandoned):** `wt rm feature/login-fix`, then close that tab.

## Close & re-start a worktree

Closing a cmux **tab** does **not** remove the git **worktree** — they're independent (see the
known limitation below). After closing a tab, `wt ls` will still show the worktree. So:

- **Reuse it** (you closed the tab by accident, want the work back): open a new session on the
  existing dir — `cd <repo>/.worktrees/<branch> && claude`, or open that folder via **⌘O** /
  the "Claude session" palette command.
- **Start fresh** (clean slate): `wt rm <branch>` first, then `wt new <branch>`. Don't skip the
  `wt rm` — re-running `wt new <branch>` while the worktree dir still exists **fails** (the
  branch is already checked out there).

## Cross-repo

Open a tab in a *different* repo and run `wt new …` there — it makes worktrees for *that* repo
(and labels the tab with that repo's name). So you can have one project's feature tabs and
another project's tabs side by side.

## Rule of thumb

- Isolated branch work in parallel → **`wt new [name]`** (new tab) or **`cd "$(wt here [name])"`**
  (this tab).
- A quick claude+shell in the directory you're already in → the **"Claude session"** palette
  command.

## Known limitation

`wt rm` removes the git worktree and branch but does **not** close the cmux tab/workspace —
close it manually. Conversely, closing the tab leaves the worktree in place (use `wt rm`).
