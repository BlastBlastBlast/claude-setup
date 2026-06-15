# Public language-skill batch (Item D) Design

Status: **approved design**, ready for implementation plan.
Branch: `feature/lang-skills-batch` (in `~/dev/claude-setup-public`).
Builds on: `docs/specs/2026-06-15-layer2-language-skills-design.md` — which deferred
`lang-go`/`lang-kotlin`/`lang-swift` as YAGNI, "minted on demand via the meta-skill when
actually needed." This is that on-demand minting, now that they're needed.

## Goal

Author five expert-sourced, LLM-optimized language skills — `lang-go`, `lang-kotlin`,
`lang-typescript`, `lang-rust`, `lang-java` — via the `research-to-skill` process, matching
the established `lang-python`/`lang-js` shape. The deeper purpose (unchanged from Layer 2):
make each language LLM-optimized by capturing how *real expert programmers* write it
(authoritative sources, not training-data sludge or media "experts"), so generated code is
enterprise-clean, readable, reuse-oriented, and architecturally sound — without sacrificing
build/iteration speed.

These skills are **general**, so they live upstream: authored in `~/dev/claude-setup-public`,
PR'd to public `main`, then picked up in the TrustHere fork via `git pull upstream main`.

## Governing constraint — source authority (applies to every skill)

Every convention in a skill must trace to an authoritative source. Hierarchy (from
`research-to-skill`):

- **Language conventions:** official language docs / style guides, the language's own
  maintainers, and widely-respected expert practitioners / reference repos. **Never**
  popularity-by-volume, blog SEO, or media influencers.
- **Endorsed libraries / tooling:** named only when **authority-gated** — official or de-facto
  standard with a citable source. Where there's no authoritative endorsement, omit rather than
  guess. Library ecosystems churn; the skill must stay durable.
- Every skill ends with a **`Sources`** block citing what it was built from. No source → the
  line does not go in the skill.

Research depth is **Standard**: official style guide + maintainer docs + canonical tooling per
skill, ~6–10 cited sources — matching `lang-python`'s depth. No assumption-based content; the
research gate is not skipped for any language.

## Shared skill contract (identical shape for all five)

Each `lang-<x>` follows the `research-to-skill` template, in this order:

```
---
name: lang-<x>
description: Use when writing or reviewing <Language> code — <key idioms>. Loads <Language> conventions.
---

# <Language> conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.

## Core idioms      — typing, naming, imports, the language's non-negotiables
## Reuse & helpers  — how to find/extend existing code in THIS language before writing new
## Architecture     — componentization & structure defaults; architecture over micro-optimization
## Anti-patterns    — training-data sludge to avoid; what NOT to do
## Sources          — authoritative references this skill was built from
```

- The `description` must read like a user request ("Use when writing <Language>…") so
  auto-invocation fires. Lead the idiom list with the language's headline non-negotiables.
- Universal principles (reuse, architecture-over-micro-opt, complexity discipline, strong
  typing, readability) live **once** in `CLAUDE.md`; each skill is that vision *projected into
  one language's idioms* — it makes the global rule concrete, it does not restate it.
- The exact `SKILL.md` format/frontmatter is grounded against `superpowers:writing-skills` +
  `code.claude.com/docs` during authoring — not guessed.

### Tooling-depth policy (settled in brainstorming)

- The canonical **formatter / linter / build tool** are **idioms**, written **inline** in Core
  idioms / Architecture and cited in `Sources` (e.g. "`gofmt` is non-negotiable", "all code
  passes `clippy`", "compile under the strict `tsconfig`").
- **Endorsed community libraries** are named only when authority-gated (see above), inline and
  cited.
- **Bulky reference material** — endorsed-library catalogs, sample CI workflow YAML — is pushed
  to an **on-demand companion (`tooling.md`)** in the skill's directory, and **only when** it
  would push `SKILL.md` past lean (< ~500 lines). Default is inline; the companion is the
  exception, decided per language during the research pass.
- **Rejected:** a separate cross-cutting CI/tooling skill — it breaks per-language
  auto-invocation, mixes ecosystems, and creates a maintenance seam. Tooling stays with its
  language for discoverability.

## Per-language research anchors (Standard depth)

Starting authoritative sources for each research pass (each subagent extends as needed; all
claims cited):

- **Go:** Effective Go, Google Go Style Guide / Go Code Review Comments, `gofmt`,
  `golangci-lint`; stdlib-first posture, explicit error handling, small interfaces.
- **Kotlin:** Kotlin Coding Conventions (kotlinlang.org), JetBrains library API guidelines,
  `ktlint`/`detekt`; null-safety idioms, coroutines, `kotlinx.serialization`.
- **TypeScript:** TypeScript Handbook, strict `tsconfig`, `typescript-eslint`; no-`any`,
  discriminated unions, `zod` at trust boundaries. Distinct from `lang-js` (types-first).
- **Rust:** Rust API Guidelines, `rustfmt`, `clippy`, The Book idioms; ownership/borrowing,
  `Result`/`?`, `serde`/`tokio`/`thiserror` where genuinely canonical.
- **Java:** Google Java Style Guide, *Effective Java* (Bloch) idioms, Oracle docs;
  records/sealed types, `Optional` for null-safety, `spotless`/Checkstyle/Error Prone.

## Execution (Approach A — batched, subagent-driven)

1. Implementation plan written via `superpowers:writing-plans`.
2. **One research-gated subagent per skill**, dispatched in parallel — independent units, no
   shared state (`superpowers:dispatching-parallel-agents` /
   `superpowers:subagent-driven-development`). Each subagent:
   a. Runs the authoritative-source research pass (Context7 for library docs, WebFetch for
      official sites) for its language.
   b. Fills the standard template; decides inline-vs-`tooling.md` per the tooling policy.
   c. Hands off to `superpowers:writing-skills` for frontmatter/routing well-formedness.
   d. Returns `SKILL.md` (+ optional `tooling.md`) and its `Sources` list.
3. Main session integrates each into `claude/skills/lang-<x>/`, adds an explicit per-skill
   test, and runs the gate.

## Testing & verification (risk-driven)

- `tests/skills.bats` already auto-discovers `claude/skills/*/SKILL.md` and asserts valid
  frontmatter + non-empty routing `description` — the five new skills are covered automatically.
- Add one explicit `@test` per new skill, matching the existing `lang-python`/`lang-js` blocks
  (a named, discoverable smoke test per skill).
- Manual review gate per skill: all five sections present in order, every convention traces to
  a cited `Sources` entry, `description` reads like a user request, `SKILL.md` < ~500 lines.
- No tests for static skill prose beyond the frontmatter smoke check (no testing for its own
  sake). Full `bats tests/` green before merge.

## Integration / git

- Single branch `feature/lang-skills-batch` in `~/dev/claude-setup-public`.
- Conventional commits; **no `Co-Authored-By`**.
- **One batched PR** to public `main` (the five share one contract → review together for
  consistency), green CI, merge commit, delete branch.
- Then in the fork: `git pull upstream main` to pick up the new skills.

## Out of scope (YAGNI / parked)

- `designing-apis` topic skill, `lang-bash`, `lang-sql` — deferred to a later round.
- **Statusline feature work** — a separate side-item (the `claude-context-monitor` statusline
  could surface repo+worktree identity, a 1M badge with a 50% handoff threshold, session
  economics, and effort/thinking state — all backed by real statusline JSON fields). Gets its
  own spec; not part of this batch.
- **SkillOpt empirical tuning** — Microsoft's validation-gated skill optimizer (reported
  +19.1 pts in Claude Code) is a compelling future R&D track, but requires a graded benchmark
  of generated code we don't have. Its own spec, much larger than D.

## Done criteria

- `lang-go`, `lang-kotlin`, `lang-typescript`, `lang-rust`, `lang-java` exist as well-formed
  global skills, each following the template with a cited `Sources` block, each activating
  (smoke check green).
- Every convention traces to an authoritative source; endorsed libraries are authority-gated;
  any `tooling.md` companion is justified by lean limits.
- Explicit per-skill bats tests added; full `bats tests/` green.
- One PR merged to public `main` with green CI; branch deleted; fork updated via
  `git pull upstream main`.
