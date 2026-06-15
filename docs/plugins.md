# Claude Code plugins — curated recommendations

A sourced, opinionated guide to which Claude Code plugins are worth enabling, and why. The goal is
**advantage**: plugins that measurably improve coding efficiency, code quality, or workflow — not
coverage for its own sake.

## How to read this

- **Enabling a plugin is a code-trust decision.** Plugins can ship skills, slash commands, subagents,
  hooks, MCP servers, and LSP configs — and hooks/MCP/binaries execute code in your environment.
  Apply least privilege: enable what buys a clear advantage, and review third-party code before
  trusting it. ([plugin structure](https://code.claude.com/docs/en/plugins.md#plugin-structure-overview))
- **Enablement** lives in `claude/settings.json`: `enabledPlugins` maps `name@marketplace` → `true`;
  `extraKnownMarketplaces` registers non-official marketplaces.
  ([settings](https://code.claude.com/docs/en/settings.md),
  [marketplaces](https://code.claude.com/docs/en/discover-plugins.md#configure-team-marketplaces))
- **No surface tags.** Claude Code's official plugin system has **no** `[cli]` / `[cli desktop web]`
  surface tags — the `tags` field in the official marketplace manifest is null. Instead this guide
  uses a **Ships** column (skills / commands / agents / hooks / lsp / mcp).
  ([source: official `marketplace.json`](https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json))
- **Trust gate (community plugins):** a community plugin is *eligible* to enable only if it clears all
  of — meaningful traction + active maintenance, a named/reputable author, a hands-on code review of
  its hooks/scripts/network/permissions, and no unexplained risk. Trust is the floor; **value** (a
  real, non-redundant advantage) is the selection criterion.

## Summary — what we enable

All enabled picks are **Anthropic first-party** (`@claude-plugins-official`). See the rationale for the
official-only posture in [Why no community plugins](#why-we-enable-no-community-plugins).

| Plugin | Source | Ships | Advantage | Enabled |
|---|---|---|---|---|
| superpowers | official | skills | Brainstorm→spec→plan→TDD→review workflow framework | ✅ baseline |
| feature-dev | official | agents, commands | Guided feature dev (explorer/architect/reviewer agents) | ✅ baseline |
| code-review | official | commands | PR review with confidence-scored findings | ✅ baseline |
| security-guidance | official | hooks | Security pattern + diff review on edits/commits | ✅ baseline |
| code-simplifier | official | agents | Refactors recently-changed code for clarity | ✅ added |
| skill-creator | official | agents, commands, skills | Authors/improves skills **with evals + variance analysis** | ✅ added |
| session-report | official | commands | HTML session report: tokens, cache, cost, subagents | ✅ added |
| pyright-lsp | official | lsp | Real Python type-checking & navigation | ✅ added |
| typescript-lsp | official | lsp | Real TS/JS type-checking & navigation | ✅ added |

## Anthropic first-party

Source repo: [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins).
These are published by Anthropic, so the trust question is settled — the only question is value.

### Enabled

#### code-simplifier — `code-simplifier@claude-plugins-official`
- **What:** an agent that simplifies/refines recently-modified code for clarity and consistency while
  preserving behavior. Ships: agents.
- **Use when:** cleaning up a diff before review.
- **Advantage:** code quality. (Partly overlaps a manual "simplify" pass; value is running it as a
  dispatched agent over a diff.)
- Source: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-simplifier

#### skill-creator — `skill-creator@claude-plugins-official`
- **What:** create new skills, improve existing ones, and **measure skill performance with evals and
  variance analysis**. Ships: agents, commands, skills.
- **Use when:** authoring or tuning a skill and you want evidence an edit actually helped.
- **Advantage:** workflow/meta — adds a measurement loop that prompt-only skill authoring lacks.
- Source: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator

#### session-report — `session-report@claude-plugins-official`
- **What:** generates an HTML report of a session — token usage, cache efficiency, subagents, skills,
  most expensive prompts. Ships: commands.
- **Use when:** auditing context/token spend (supports a "hand off around ~50% context" discipline).
- **Advantage:** efficiency — makes context/cost visible instead of guessed.
- Source: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/session-report

#### pyright-lsp — `pyright-lsp@claude-plugins-official`
- **What:** Python language server (Pyright) for type-checking and code intelligence. Ships: lsp.
- **Use when:** working in a typed Python codebase.
- **Advantage:** code quality + efficiency — real diagnostics and go-to-definition instead of
  text-only reasoning. **Prereq:** Pyright available (e.g. `npm i -g pyright` / Homebrew).
- Source: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pyright-lsp

#### typescript-lsp — `typescript-lsp@claude-plugins-official`
- **What:** TypeScript/JavaScript language server. Ships: lsp.
- **Use when:** working in TS/JS.
- **Advantage:** same as above for TS/JS. **Prereq:** `typescript-language-server` available.
- Source: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/typescript-lsp

### Useful, but not enabled by default (enable per need)

- **commit-commands** — commit/push/PR commands. Overlaps a hand-rolled git workflow; enable if you
  want canned git commands.
- **claude-md-management** — audit/improve `CLAUDE.md`, capture session learnings.
- **hookify** — generate hooks from patterns/instructions (alternative to writing hooks by hand).
- **plugin-dev** — toolkit for building plugins (hooks/MCP/commands/agents).
- **mcp-server-dev** — skills for designing/building MCP servers.
- **pr-review-toolkit** — multi-faceted PR-review agents (overlaps `code-review`).
- **frontend-design** — production-grade frontend/UI generation.
- **code-modernization** — staged legacy-modernization workflow.
- **session/output styles** — `explanatory-output-style`, `learning-output-style`.
- **ralph-loop** — iterative self-referential improvement loops.
- **claude-code-setup** — one-shot "analyze this repo and recommend automations".
- **agent-sdk-dev**, **mcp-tunnels**, **math-olympiad**, **cwc-makers** — niche/specialized.

**LSP family (enable per language you use):** `clangd` (C/C++), `csharp`, `gopls` (Go), `jdtls`
(Java), `kotlin`, `liquid` (Shopify), `lua`, `php`, `ruby`, `rust-analyzer`, `swift` — same shape as
the Python/TS LSPs above; each needs its language server installed.
Source: https://github.com/anthropics/claude-plugins-official/tree/main/plugins

## Community plugins

We **document** the strongest community options with trust notes but **enable none by default** (see
[why](#why-we-enable-no-community-plugins)). Traction figures observed **2026-06-15**; they age — re-check
before enabling. Each entry below was traction-screened; the top candidates were also code-reviewed.

### Code-reviewed (cleared a hands-on review)

#### wshobson/agents — *document-only (cherry-pick)*
- **What:** a marketplace of 80+ specialized subagents + domain plugins (backend, data, infra,
  security, perf). Install: `/plugin marketplace add wshobson/agents`, then per-domain plugins.
- **Traction (2026-06-15):** ~36.8k★, ~4.0k forks, last commit 2026-06-15; author Seth Hobson (well-known).
- **Trust review:** 80/82 plugins are **pure markdown** (agents/skills) — zero executable surface,
  safe to cherry-pick. **Avoid** the two hook-bearing plugins (`protect-mcp`, `review-agent-governance`):
  they run an opaque third-party npm package on *every* tool call. No install scripts, no `curl|sh`.
- **Value:** complementary domain specialists (cloud-infra, k8s, observability, DB) the official
  agents don't cover. Language plugins (e.g. `python-development`) may conflict with your own curated
  language guidance — cherry-pick the orthogonal ones.
- Source: https://github.com/wshobson/agents

#### shinpr/claude-code-workflows — *document-only*
- **What:** a gated pipeline (requirements→design→plan→tasks→impl) with per-stage agents, enforced
  design-doc-vs-code verification, and automated test/lint/type fixing.
- **Traction (2026-06-15):** ~453★, ~68 forks, last commit 2026-06-13, 0 open issues; author shinpr.
- **Trust review:** prompt-only — no hooks/MCP/network/destructive commands; the auto-fixer runs your
  project's own test/lint/build via standard Bash + Edit, fully under your permission gating; commits
  only on approval. (Three external URL-sourced sub-plugins are unreviewed.)
- **Value:** the design-verification + auto-fix pipeline overlaps a brainstorm→plan→TDD workflow;
  `dev-skills` is the lightest-footprint piece to try.
- Source: https://github.com/shinpr/claude-code-workflows

#### athola/claude-night-market — *document-only (intent covered natively)*
- **What:** 23 plugins; notable for **enforcement hooks** — e.g. `conserve` (block `rm -rf /`, `sudo`,
  `curl|sh`, force-push-to-main, `cat .env`) and `imbue` (TDD gate + commit hygiene, incl. blocking
  `Co-Authored-By`).
- **Traction (2026-06-15):** ~309★, ~27 forks, last commit 2026-06-14; single author.
- **Trust review:** no malware/obfuscation/exfil; `conserve` is clean (localhost-only). **Caveats:**
  `imbue` pings public package registries (opt-out env var); `leyline` ships an **opt-out self-star
  hook** that uses your `gh`/`GITHUB_TOKEN` — distasteful, set `CLAUDE_NIGHT_MARKET_NO_STAR_PROMPT=1`
  if you ever enable it; `gauntlet`/`egregore` block commits/session-exit by default.
- **Why we don't enable it:** the valuable intent is reproducible with first-party means — commit
  rules belong in `CLAUDE.md`, and the destructive-command block is implemented natively via
  `permissions.deny` + an owned guard hook (see [Built-in safety](#built-in-safety-instead-of-a-community-hook)).
  Enable yourself only if you want the hooks turned into hard gates without maintaining your own.
- Source: https://github.com/athola/claude-night-market

#### egorfedorov/claude-context-optimizer — *document-only (try-it)*
- **What:** local token-usage analytics — flags read-but-unused files, heatmaps, budget alerts.
- **Traction (2026-06-15):** ~53★, ~10 forks, last commit 2026-05-09; single author.
- **Trust review:** **fully local, zero network, zero npm deps**, no install scripts — trivially
  auditable. Caveats: logs the first 200 chars of each prompt to disk; a crypto-donation banner
  (silence with `CCO_QUIET=1`); a per-tool-call `node` spawn adds latency. "Savings" are
  self-estimated heuristics, not measured.
- **Value:** orthogonal context/cost observability, but unproven payoff + overhead — try it, don't
  bank on the headline numbers.
- Source: https://github.com/egorfedorov/claude-context-optimizer

### Traction-screened, not recommended

- **ruvnet/ruflo** (~59.6k★, very active) — heavyweight multi-agent "swarm" meta-harness; ~646 open
  issues and **unverified** benchmark/cost claims; may clash with a skills-based workflow. Skip unless
  you specifically want swarm orchestration. https://github.com/ruvnet/ruflo
- **catlog22/Claude-Code-Workflow** (~2.1k★) — JSON-driven multi-LLM delegation framework; not a
  standard `/plugin` package (integration cost). https://github.com/catlog22/Claude-Code-Workflow
- **sangrokjung/claude-forge** (~746★) — large "batteries-included" bundle that substantially
  duplicates official feature-dev/code-review/superpowers. https://github.com/sangrokjung/claude-forge
- **BMAD ports** (`aj-geddes/claude-code-bmad-skills`, ~448★, slowing) — agile-role method; overlaps
  planning skills. Upstream [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) is active.

**Excluded (failed traction/trust):** `PabloLION/bmad-plugin`, `flight505/dincoder-plugin`
(abandoned), `nxtg-ai/forge-plugin`, `chanwit/tdg` (stale + redundant).

## Install these — shortlist

Add to `claude/settings.json` → `enabledPlugins` (all `@claude-plugins-official`):

| Plugin | Advantage |
|---|---|
| `code-simplifier` | refactor/cleanup of changed code |
| `skill-creator` | skill authoring + evals/variance |
| `session-report` | token/cache/cost observability |
| `pyright-lsp` | Python type-checking & navigation (needs Pyright) |
| `typescript-lsp` | TS/JS type-checking & navigation (needs the TS server) |

(On top of the baseline `superpowers`, `feature-dev`, `code-review`, `security-guidance`.)

### Why we enable no community plugins

We surveyed and code-reviewed the strongest community options (above). The two cleanest — `conserve`
(destructive-command block) and `imbue` (commit hygiene) — would have been enable candidates, but their
value is reproducible with **first-party** means at lower trust exposure:

- **Commit hygiene** (no `Co-Authored-By`, conventional commits, test-first) lives in `CLAUDE.md` — an
  instruction, not an imported hook.
- **Destructive-command safety** is implemented natively (next section) — no third-party code to trust
  or maintain.

Importing a single-author marketplace to enforce rules we already have isn't worth the trust/maintenance
cost. Community plugins remain documented here so you can make your own call.

### Built-in safety (instead of a community hook)

This setup blocks destructive commands using native config rather than a community plugin:

- **`permissions.deny`** in `settings.json` denies `rm -rf /*`, `sudo*`, `git push --force*`/`-f`, and
  reads of `.env`/`.ssh`/key files. ([permissions](https://code.claude.com/docs/en/settings.md)) This is
  a best-effort first gate: argument-matching deny rules are inherently fragile (e.g. flag reordering),
  so it's defense-in-depth, backstopped by Claude Code's built-in `rm -rf /` circuit breaker.
- **A `PreToolUse` guard hook** (`bin/claude-guard-destructive`) is the reliable layer for the
  fetch-and-execute pattern a static deny-list can't match: it blocks a downloader (`curl`/`wget`) fed
  into a shell via a pipe, process substitution (`bash <(curl …)`), command substitution
  (`sh -c "$(curl …)"`), or `eval`.

Both are first-party, auditable, and owned — the protection `conserve` offers without the external
dependency.

## Sources

- Claude Code — plugins: https://code.claude.com/docs/en/plugins.md
- Claude Code — discover/marketplaces: https://code.claude.com/docs/en/discover-plugins.md
- Claude Code — settings: https://code.claude.com/docs/en/settings.md
- Official marketplace repo: https://github.com/anthropics/claude-plugins-official
- Official marketplace manifest (tags=null): https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/.claude-plugin/marketplace.json
- Community repos cited inline above (links per entry).

*Traction figures observed 2026-06-15. Re-verify before enabling any community plugin — stars,
maintenance, and ownership change.*
