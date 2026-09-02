---
name: handoff
description: Use when ending a session, handing off work for a fresh session, or the user says "hand off", "wrap up", "write a handoff", or asks to /clear and continue later. Writes a continuation-ready handoff doc outside the repo and hands back a paste-ready resume prompt. Not for mid-task checkpointing (commit and keep going).
---

# Session handoff

A handoff is complete when a fresh session can resume from one paste. Write the doc, hand back the
prompt, then tell the user to `/clear`.

## Where handoffs live

Outside the working repo, so "never committed" is structural rather than a rule to remember in every
repo's `.gitignore`. `claude-handoff` owns the layout — never hand-build these paths:

```
~/.claude/handoffs/<worktree-slug>/
  <YYYY-MM-DD-HHMM>-<topic>.md
  latest.md            -> the newest handoff; stable path, the manual fallback
  PENDING.<pane-key>   -> consumed by the SessionStart hook, so it fires once
```

The slug is per **worktree**, not per repo: parallel-agent tooling (Orca, `wt`) gives each agent its
own worktree, and that is different work on a different branch. The pointer is per **session**, so
two agents sharing one worktree cannot clobber each other.

## Writing it

```bash
DIR=$(claude-handoff dir)
FILE="$DIR/$(date +%Y-%m-%d-%H%M)-<topic>.md"
```

Write to `$FILE`, structured top-down by what the next session reads first. **No continuation prompt
inside the file** — the file is what the prompt points *at*, so a copy of it at the top is just
something to get stale:

1. **`# <Topic>`** as the first line. The hook reads this heading back to the user to confirm it
   resumed the right handoff, so make it specific — "Handoff skill: hook + skill wired, tests
   pending", not "Handoff".
2. **State:** what's finished (with evidence — test output, commit SHAs), what's in flight, what's
   untouched.
3. **Decisions and their why** — anything a fresh session would otherwise re-litigate.
4. **Gotchas discovered** — the non-obvious things that cost time this session.
5. **Next action** — the single concrete thing to do first.

Before writing: commit finished work, so the doc references commits rather than uncommitted state.
Conclusions live in the doc, not in chat scrollback — write them down even if they were already said
in conversation.

## Then register and hand back

```bash
claude-handoff pointer "$FILE"          # arms the hook, repoints latest.md
```

Print the continuation prompt in chat **and** copy it, because `/clear` wipes the transcript — a
prompt that exists only in scrollback is unrecoverable the moment it is needed:

```bash
printf '%s' "Resume the handoff at $FILE — read it and continue from its Next action." | pbcopy
```

Close by telling the user, in this order: the file path, that the prompt is in their clipboard, and
that after `/clear` the hook should offer the handoff on its own — `⌘V` if it doesn't.

## Why four layers

The hook is convenience, never load-bearing. The file is on disk before the `/clear`, so the
fallback ladder is: hook fires → type `go`; hook silent → `⌘V`; clipboard clobbered → say
`resume the handoff at ~/.claude/handoffs/<slug>/latest.md`. No rung loses work.

To satisfy yourself the hook works before trusting it — this only prints what Claude Code would
send, and changes nothing:

```bash
echo '{"hook_event_name":"SessionStart","source":"clear","cwd":"'"$PWD"'"}' | claude-handoff hook
```

Fires on `/clear` only. After quitting and relaunching, resume via `latest.md` by hand.
