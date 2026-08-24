# Enforcement tiers: turning CLAUDE.md prose into hooks, rules, and skills

How to decide where a piece of guidance belongs, and how to author each tier. This is the
procedure behind the 2026-08 Opus 5 alignment; the `model-update` skill applies it on every
model release, and the `instruction-files` rule loads the short version whenever an
instruction file is edited.

## The classification procedure

For each line of CLAUDE.md (or any candidate guidance), ask in order:

1. **Is the violation observable in a tool call?** (a command string, a tool input field,
   a file write) → **hook**. Prose can stay as *generative* guidance — the prose tells
   Claude what to produce, the hook guarantees drift is caught. Examples here:
   conventional-commit prefix, bare force-push, AI-attribution footers, merge-main-into-
   feature, model-less generic subagent dispatch.
2. **Is it a "must never happen" expressible as a command/path pattern?** →
   **`permissions.deny`** (simpler than a hook when a glob suffices; a hook when the
   pattern needs logic a glob can't express, like the force-with-lease exception).
3. **Is it conditional on file paths?** → **`.claude/rules/*.md`** with `paths:`
   frontmatter — loads only when Claude reads matching files.
4. **Is it conditional on task type?** → **skill** — trigger-sharp description with
   negative scope.
5. **None of the above (pure judgment)?** → it stays prose in CLAUDE.md, and must pass
   "would removing this cause a mistake?"

**What NOT to convert:** judgment calls (reuse-before-create, test-where-risk-concentrates,
scope discipline). A hook that polices judgment produces false positives and teaches
workarounds; prose is the right tool there. More hooks is not better — every hook runs on
every matching event, and every false positive costs a retry. Each one must earn its place
with a concrete failure it prevents.

## Authoring hooks (PreToolUse guards)

Contract (docs: code.claude.com/docs/en/hooks): JSON payload on stdin (`tool_name`,
`tool_input`, …); **exit 2 blocks the call** (≥ 2.1.214), exit 0 allows; stderr becomes the
model-visible reason. House conventions:

- **Fail open** on unparseable input — a guard is defense in depth, not the only gate.
- **Segment-scope command matching**: a flag must appear in the same `|;&`-free segment as
  its command, or strings in unrelated commands false-positive (learned when the force-push
  guard blocked its own test suite).
- Expect **self-triggering**: a guard that matches patterns will match those patterns quoted
  in commit messages and heredocs. Write the block-reason to allow rephrasing, and keep
  pattern-shaped content in script files.
- **Test-first in `tests/hooks.bats`** via the `_guard`/`_agent_guard` helpers — one test per
  block case, one per legitimate near-miss (the force-with-lease, the CLAUDE.md mention, the
  amend without message).
- Wire in `claude/settings.json` under `hooks.PreToolUse` with the tool-name matcher, and
  symlink the script via `install.sh`.

## Authoring rules

- One `.md` per concern; `paths:` (glob array) is the only supported frontmatter field.
  Without it the rule loads always — then it belongs in CLAUDE.md instead.
- User-level (`claude/rules/` → `~/.claude/rules/`) for cross-repo path patterns;
  repo-level (`.claude/rules/`) for this repo's own conventions.
- Keep each rule as lean as a CLAUDE.md section: judgment criteria, no MUST/NEVER
  scaffolding. Verify loading with `/context` (Memory files section).

## Current inventory (keep in sync)

| Guidance | Tier | Where |
|---|---|---|
| fetch-and-execute, force-push, attribution, commit format, merge-main | Hook | `bin/claude-guard-destructive` |
| Model-less generic subagent dispatch | Hook | `bin/claude-guard-agent-dispatch` |
| Secrets reads, `rm -rf`, `sudo`, `gh pr merge` | Deny | `claude/settings.json` permissions |
| Instruction-file tiering/writing conventions | Rule | `claude/rules/instruction-files.md` |
| bats conventions | Rule (repo) | `.claude/rules/bats-tests.md` |
| Session handoff protocol | Skill | `claude/skills/handoff` |
| Model-release realignment | Skill | `claude/skills/model-update` |
| Everything judgment-shaped | Prose | `claude/CLAUDE.md` (< 200 lines) |
