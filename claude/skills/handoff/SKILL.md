---
name: handoff
description: Use when ending a session, handing off work for a fresh session, or the user says "hand off", "wrap up", "write a handoff", or asks to /clear and continue later. Writes a continuation-ready handoff doc. Not for mid-task checkpointing (commit and keep going).
---

# Session handoff

A handoff is complete when a fresh session can resume from one paste. Write the doc, then tell the
user to `/clear`.

## The handoff doc

Write to the repo's `docs/` (e.g. `docs/HANDOFF.md` or `docs/HANDOFF-<date>-<topic>.md`), structured
top-down by what the next session reads first:

1. **Continuation prompt at the very top**, ready to paste verbatim after `/clear`. It must stand
   alone: the handoff doc's own path, the branch and commit, and the next concrete action. If the
   next session can't resume from that one paste, the handoff isn't done.
2. **State:** what's finished (with evidence — test results, commit SHAs), what's in flight, what's
   untouched.
3. **Decisions and their why** — anything a fresh session would otherwise re-litigate.
4. **Gotchas discovered** — the non-obvious things that cost time this session.

## Before writing

- Commit finished work first; the doc references commits, not uncommitted state.
- Conclusions live in the doc, not in the chat scrollback — write them down even if they were
  already said in conversation.
- If the user should eyeball something before continuing, offer crit (`crit` for the working diff,
  `crit <file>` for a doc) rather than pointing at a file — only when `crit` is on `PATH`.

## After writing

Tell the user: the doc's path, and that they can `/clear` and paste the continuation prompt to
resume.
