---
name: model-update
description: Use when a new Claude model or generation is released ("Opus 6 is out"), when asked whether the current setup is optimal for a given model ("evaluate our setup for X", "optimize the config for Y"), when switching default models, or when prompts/skills written for an older model over-trigger, over-verify, or over-delegate on a newer one. Fetches the model's documentation, evaluates every loaded instruction surface against it, and produces a prioritized optimization report before changing anything. Not for migrating API code — use /claude-api migrate for that.
---

# Model update: evaluate and align a Claude setup with a model

New model generations change which instructions help and which hurt: rules written to
protect against an old model's weaknesses become taxes on a newer one (Opus 5: verification
instructions caused over-verification; "CRITICAL: YOU MUST" caused overtriggering). This
skill re-derives the setup from verified documentation instead of porting old rules forward.
**The direction of change is usually subtraction.** The deliverable is a prioritized
optimization report; apply changes only after the user picks from it.

Coverage beats speed here: a missed doc page or an unaudited surface is a silent quality tax
every session thereafter. Sweep wide, then filter.

## Phase 1 — Discover the setup (what is actually loaded)

Enumerate every instruction surface the harness loads, discovering paths rather than
assuming them:

| Surface | Where to look |
|---|---|
| Global + project CLAUDE.md / AGENTS.md | `~/.claude/CLAUDE.md`, repo roots, nested dirs |
| Settings (model, effort, env caps, permissions, hooks) | `~/.claude/settings.json`, repo `.claude/settings*.json` |
| Skills | `~/.claude/skills/`, repo `.claude/skills/`, plugin-provided |
| Agent/subagent definitions (frontmatter `model:` pins) | `~/.claude/agents/`, repo `.claude/agents/`, plugin-bundled agents — the files that actually route work to model tiers |
| Plugins + their bundled prompts | `enabledPlugins` in settings; bodies under `~/.claude/plugins/cache/` and `~/.claude/plugins/marketplaces/` |
| Path-scoped rules | `.claude/rules/` (user + repo) |
| Hooks/guards | settings `hooks` entries and the scripts they call |
| Output style, memory | settings `outputStyle`; `~/.claude/projects/<slug>/memory/` |

Record for each: where it lives, when it loads (always / on-trigger / on-demand), and its
rough always-loaded token cost. This inventory is the audit's checklist — a surface not
inventoried is a surface not evaluated.

## Phase 2 — Sweep the model's documentation (subagents, primary sources)

Enumerate before reading: fetch the docs index first — `platform.claude.com/llms.txt` (fall
back to the sitemap or docs landing page) and the same for `code.claude.com/docs` — and
filter for every page mentioning the model or its generation. Typical hit set: the model's
`prompting-claude-<model>` page, `whats-new-<model>`, the migration guide's section,
effort, thinking, context windows, pricing, plus harness pages (best-practices, memory,
sub-agents, costs, settings/changelog for new config surfaces and version gates).

Then dispatch parallel research subagents on a cheaper tier (follow the local CLAUDE.md's
model-selection rules if it has them; otherwise `model: "sonnet"`), one per cluster:

1. Platform docs for the model + generation (from the index sweep above).
2. Harness docs (code.claude.com) for changed defaults, new config, version gates.
3. Anthropic blog/engineering posts ("<model> prompting", "context engineering",
   "system prompt") + release announcement.
4. The bundled `claude-api` skill's `shared/model-migration.md` — read the model's section
   directly; it carries behavioral-shift prompt snippets before the web does. (Reading it
   for behavior is in scope; running code migration from it is not. If the skill or file
   isn't installed on this machine, skip the cluster and list it in the coverage gaps.)
5. Upstreams of installed third-party skills/plugins: releases and issues mentioning the
   model — maintainers confirm behavioral problems before docs do.

Cover the sibling models too: setups route work across tiers (e.g. Sonnet executors), so a
generation update is never one model's quirks alone.

Verification rules (learned the hard way):
- A claim without a primary-source quote is discarded — secondary coverage embellishes.
- Numbers are cited only if verbatim in an Anthropic source.
- Record refuted claims alongside verified ones so the next run doesn't re-investigate.

Distill into a ruleset file: **one file per generation** — a tier release within an existing
generation (a new Haiku/Sonnet in a documented family) appends a section to that generation's
file rather than forking a new one; only a new generation starts a new file. Place it next to
the setup's CLAUDE.md (or wherever the setup keeps its docs). Three lists: **DELETE** (rules
the model now makes counterproductive), **ADD** (Anthropic's tested snippets for its real
quirks), **ADJUST** (effort, thinking, caps, routing, structure), each entry sourced. When
starting a successor file, update every back-reference to the superseded one.

## Phase 3 — Evaluate and report

Audit every Phase 1 surface against the ruleset. Per surface:

| Surface | Check |
|---|---|
| CLAUDE.md files | Per line: "would removing this cause a mistake on the new model?" Watch for rules now followed *too* literally. Then the additive lens: does the ruleset's ADD/ADJUST list imply a missing line (a new tier row in a model-routing table, a new quirk snippet)? Keep always-loaded files lean (< 200 lines). If an installed copy diverges from a repo-tracked copy, check whether that's intentional before "fixing" it. |
| Settings | Model ID (exact string from the migration guide/models table, verbatim — never constructed; keep a context suffix like `[1m]` only if still documented), effort, subagent caps, deny/allow, plugin enablement. |
| Skills | Descriptions trigger-sharp with negative scope; bodies judgment-framed, no MUST/NEVER scaffolding; lookup material in `references/`. |
| Plugins | Bundled prompts for baked-in conflicts (severity filters, forced verification, delegation pushes) — un-overridable from CLAUDE.md; may warrant a disable. |
| Hooks/guards | Still enforce what prose was demoted from; test for false positives against real command shapes. |
| Tier placement | For each prose line, ask in order: violation observable in a tool call → hook; "must never happen" expressible as a glob → deny rule; conditional-on-path → rules; conditional-on-task → skill; pure judgment → stays prose. Don't convert judgment calls — a hook that polices judgment false-positives. If the setup documents its own procedure (e.g. `docs/enforcement-tiers.md`), follow that. |
| Version floor | If the setup declares a minimum harness version (e.g. `MIN_CLAUDE_CODE_VERSION` in its installer), check whether newly adopted version-gated config raises it — map features to versions via `code.claude.com/docs/en/changelog`. |

**Deliver the report before changing anything**: findings prioritized by impact, each with
the surface, the verified source, the proposed change (delete/add/adjust/move-tier), and the
expected effect (tokens, latency, quality, safety). Include a coverage appendix — which
surfaces and doc pages were checked — and finish with a completeness pass: any doc page
unread, surface unaudited, claim unverified becomes a listed gap, not a silent omission.

## Phase 4 — Apply and ship (on approval)

- Apply what the user selects. Must-never rules go to deterministic layers (guard hooks,
  `permissions.deny`), never prose; guard changes are test-first if the setup has a test
  suite. Validate settings JSON after every edit.
- **How to ship depends on what Phase 1 found:**
  - *Setup lives in a git repo* (a dotfiles/claude-setup repo): document the run in its
    docs, sync its README/plugin docs to the actual settings state, and ship per that repo's
    workflow (branch → PR → the user merges). Mind live symlinks: if `~/.claude` symlinks
    into the repo, edits are live immediately and branch switches can revert working files.
  - *No setup repo* (bare `~/.claude/`): apply directly to the discovered surfaces, keep the
    optimization report as the record (save it next to the setup's CLAUDE.md), and suggest
    putting the config under version control as its own finding.
- Update harness memory if this machine uses it (`~/.claude/projects/<slug>/memory/` +
  `MEMORY.md` index); skip silently where the convention doesn't exist.
- Check harness version gates before relying on new config surfaces (`claude --version`) —
  older harnesses ignore unknown settings silently.
