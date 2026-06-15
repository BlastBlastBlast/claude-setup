# Public language-skill batch (Item D) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Author five expert-sourced global language skills — `lang-go`, `lang-kotlin`, `lang-typescript`, `lang-rust`, `lang-java` — in the public `claude-setup` repo, each research-gated and matching the `lang-python`/`lang-js` shape.

**Architecture:** One feature branch in `~/dev/claude-setup-public`. Each language is an independent unit: a research-gated subagent gathers authoritative sources, fills the fixed 5-section template, and the skill is gated by an explicit bats smoke test (written first, fails, then passes once the skill exists). One batched PR to public `main`; the TrustHere fork picks it up via `git pull upstream main`.

**Tech Stack:** Markdown skills (`SKILL.md` + optional `tooling.md`), `bats` smoke tests, `research-to-skill` + `superpowers:writing-skills` authoring process, Context7 / WebFetch for source research.

---

## Pre-flight

- All work is in `~/dev/claude-setup-public` on branch `feature/lang-skills-batch` (already created; the design spec is committed there at `docs/specs/2026-06-15-public-language-skills-batch-design.md`).
- Reference exemplar to match for shape/depth/tone: `claude/skills/lang-python/SKILL.md`.
- Template: `claude/skills/research-to-skill/template.md`.
- The smoke test helper `_assert_valid_skill` and the auto-discovery test already exist in `tests/skills.bats`; we add one explicit named test per new skill.

## File Structure

Created per language `lang-<x>` (x ∈ go, kotlin, typescript, rust, java):
- `claude/skills/lang-<x>/SKILL.md` — the skill. The 5 sections (Core idioms · Reuse & helpers · Architecture · Anti-patterns · Sources), repo-local-precedence line, routing `description`. Single responsibility: that language's expert conventions. Kept lean (< ~500 lines).
- `claude/skills/lang-<x>/tooling.md` — OPTIONAL companion, created only if endorsed-library catalogs / sample CI YAML would push `SKILL.md` past lean. Single responsibility: on-demand tooling/library reference for that language.

Modified:
- `tests/skills.bats` — add one explicit `@test` per new skill (5 total).

## Per-language authoring procedure (P1–P7)

Each language task below supplies its own concrete **inputs** (frontmatter `description`, research anchors, headline idioms), then runs this identical procedure. Read it once; every task invokes P1–P7.

- **P1 — Write the failing smoke test.** Add the task's `@test` block (given verbatim in the task) to `tests/skills.bats`, after the existing `lang-js` test block.
- **P2 — Run it; verify it FAILS.** `cd ~/dev/claude-setup-public && bats tests/skills.bats -f "lang-<x>"` → Expected: FAIL ("missing: …/lang-<x>/SKILL.md").
- **P3 — Research pass (research-gated; dispatch a subagent).** Dispatch a subagent to run the authoritative-source research pass for this language using the task's research anchors. Priority: official language docs / style guides → language maintainers → widely-respected expert reference repos. Use Context7 for library docs and WebFetch for official sites. The subagent returns: the conventions per section, the canonical formatter/linter/build tool, any authority-gated endorsed libraries, and a `Sources` list (URLs). **No claim without a citable authoritative source — omit rather than guess** (esp. libraries; ecosystems churn).
- **P4 — Author `SKILL.md`.** Fill `claude/skills/lang-<x>/SKILL.md` from `research-to-skill/template.md`, in section order, using P3's findings. Match `lang-python`'s tone/density. Apply the tooling-depth policy: formatter/linter/build inline as idioms; endorsed libraries inline only if authority-gated; push bulky library catalogs / sample CI YAML to `tooling.md` ONLY if `SKILL.md` would exceed ~500 lines (and link to it from the skill). Every convention must trace to a `Sources` entry; drop any line without a source.
- **P5 — Well-formedness check.** Hand off to `superpowers:writing-skills` to verify frontmatter and that the routing `description` reads like a user request (so auto-invocation fires). Confirm the 5 sections are present and in order, and the repo-local-precedence line is the first body line.
- **P6 — Run tests; verify GREEN.** `bats tests/skills.bats -f "lang-<x>"` → PASS. Then `bats tests/` → all green.
- **P7 — Commit.** `git add claude/skills/lang-<x>/ tests/skills.bats && git commit -m "feat: add lang-<x> conventions skill"` (add `tooling.md` to the path if created).

---

## Task 1: lang-go

**Files:**
- Create: `claude/skills/lang-go/SKILL.md` (+ optional `claude/skills/lang-go/tooling.md`)
- Modify: `tests/skills.bats`

**Inputs:**
- Frontmatter `description`: `Use when writing or reviewing Go code — gofmt-formatted, explicit error handling, small interfaces, stdlib-first, accept interfaces/return structs. Loads Go conventions.`
- Headline idioms to anchor Core idioms: `gofmt` is non-negotiable; handle every `error` explicitly (no silent `_`); small interfaces defined at the consumer; accept interfaces, return concrete types; zero-value-useful structs; `context.Context` as first param for cancellation.
- Research anchors (P3): Effective Go; Go Code Review Comments / Google Go Style Guide; `gofmt`/`go vet`; `golangci-lint`; standard project layout guidance. Endorsed libs only if authority-gated (stdlib-first posture — be conservative).

- [ ] **Step 1 (P1): Add the failing smoke test** — insert into `tests/skills.bats` after the `lang-js` test:

```bash
@test "lang-go skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-go/SKILL.md"
}
```

- [ ] **Step 2 (P2): Verify it fails** — `bats tests/skills.bats -f "lang-go"` → FAIL ("missing: …/lang-go/SKILL.md").
- [ ] **Step 3 (P3): Research pass** — dispatch the research subagent with the Go anchors above.
- [ ] **Step 4 (P4): Author `claude/skills/lang-go/SKILL.md`** from the template using P3 findings; tooling-depth policy applied.
- [ ] **Step 5 (P5): Well-formedness check** via `superpowers:writing-skills`.
- [ ] **Step 6 (P6): Run tests** — `bats tests/skills.bats -f "lang-go"` → PASS; `bats tests/` → all green.
- [ ] **Step 7 (P7): Commit** — `git add claude/skills/lang-go/ tests/skills.bats && git commit -m "feat: add lang-go conventions skill"`.

---

## Task 2: lang-kotlin

**Files:**
- Create: `claude/skills/lang-kotlin/SKILL.md` (+ optional `claude/skills/lang-kotlin/tooling.md`)
- Modify: `tests/skills.bats`

**Inputs:**
- Frontmatter `description`: `Use when writing or reviewing Kotlin code — null-safety over !!, val over var, immutable defaults, expression idioms, coroutines for async. Loads Kotlin conventions.`
- Headline idioms: prefer `val`; lean on null-safety (`?.`, `?:`, never `!!`); data/sealed classes for modelling; expression-bodied functions; scope functions (`let`/`apply`/etc.) used deliberately not reflexively; coroutines + structured concurrency for async.
- Research anchors (P3): Kotlin Coding Conventions (kotlinlang.org); JetBrains library author API guidelines; `ktlint` / `detekt`; `kotlinx.coroutines`, `kotlinx.serialization` (JetBrains-maintained → authority-gated).

- [ ] **Step 1 (P1): Add the failing smoke test:**

```bash
@test "lang-kotlin skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-kotlin/SKILL.md"
}
```

- [ ] **Step 2 (P2): Verify it fails** — `bats tests/skills.bats -f "lang-kotlin"` → FAIL.
- [ ] **Step 3 (P3): Research pass** — dispatch with the Kotlin anchors.
- [ ] **Step 4 (P4): Author `claude/skills/lang-kotlin/SKILL.md`.**
- [ ] **Step 5 (P5): Well-formedness check.**
- [ ] **Step 6 (P6): Run tests** — `-f "lang-kotlin"` PASS; `bats tests/` green.
- [ ] **Step 7 (P7): Commit** — `git commit -m "feat: add lang-kotlin conventions skill"`.

---

## Task 3: lang-typescript

**Files:**
- Create: `claude/skills/lang-typescript/SKILL.md` (+ optional `claude/skills/lang-typescript/tooling.md`)
- Modify: `tests/skills.bats`

**Inputs:**
- Frontmatter `description`: `Use when writing or reviewing TypeScript code — strict tsconfig, no any, prefer unknown, discriminated unions, type-only imports, validate inputs at boundaries. Loads TypeScript conventions.`
- Headline idioms: compile under strict `tsconfig` (`strict: true`); ban `any`, prefer `unknown` + narrowing; discriminated unions over enums where apt; `type`/`interface` chosen deliberately; `import type` for type-only; validate external input at trust boundaries (`zod`). Note: complements, does not duplicate, `lang-js` (this is the types-first layer).
- Research anchors (P3): TypeScript Handbook + `tsconfig` reference (typescriptlang.org); `typescript-eslint` recommended configs; `zod` (de-facto standard runtime validation → authority-gated, cite).

- [ ] **Step 1 (P1): Add the failing smoke test:**

```bash
@test "lang-typescript skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-typescript/SKILL.md"
}
```

- [ ] **Step 2 (P2): Verify it fails** — `bats tests/skills.bats -f "lang-typescript"` → FAIL.
- [ ] **Step 3 (P3): Research pass** — dispatch with the TypeScript anchors.
- [ ] **Step 4 (P4): Author `claude/skills/lang-typescript/SKILL.md`.**
- [ ] **Step 5 (P5): Well-formedness check.**
- [ ] **Step 6 (P6): Run tests** — `-f "lang-typescript"` PASS; `bats tests/` green.
- [ ] **Step 7 (P7): Commit** — `git commit -m "feat: add lang-typescript conventions skill"`.

---

## Task 4: lang-rust

**Files:**
- Create: `claude/skills/lang-rust/SKILL.md` (+ optional `claude/skills/lang-rust/tooling.md`)
- Modify: `tests/skills.bats`

**Inputs:**
- Frontmatter `description`: `Use when writing or reviewing Rust code — rustfmt + clippy clean, Result with ?, no unwrap in libs, borrow over clone, thiserror/anyhow for errors. Loads Rust conventions.`
- Headline idioms: `rustfmt` + `clippy` clean; propagate errors with `Result` + `?`; no `unwrap()`/`expect()` in library code; prefer borrowing over cloning; newtypes for domain meaning; `thiserror` for library errors / `anyhow` for applications.
- Research anchors (P3): Rust API Guidelines; `rustfmt` + `clippy` docs; The Rust Book idioms (error handling, ownership); `serde`/`tokio`/`thiserror` (canonical → authority-gated, cite).

- [ ] **Step 1 (P1): Add the failing smoke test:**

```bash
@test "lang-rust skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-rust/SKILL.md"
}
```

- [ ] **Step 2 (P2): Verify it fails** — `bats tests/skills.bats -f "lang-rust"` → FAIL.
- [ ] **Step 3 (P3): Research pass** — dispatch with the Rust anchors.
- [ ] **Step 4 (P4): Author `claude/skills/lang-rust/SKILL.md`.**
- [ ] **Step 5 (P5): Well-formedness check.**
- [ ] **Step 6 (P6): Run tests** — `-f "lang-rust"` PASS; `bats tests/` green.
- [ ] **Step 7 (P7): Commit** — `git commit -m "feat: add lang-rust conventions skill"`.

---

## Task 5: lang-java

**Files:**
- Create: `claude/skills/lang-java/SKILL.md` (+ optional `claude/skills/lang-java/tooling.md`)
- Modify: `tests/skills.bats`

**Inputs:**
- Frontmatter `description`: `Use when writing or reviewing Java code — favor immutability, records for data, Optional over null, program to interfaces, prefer composition, static factories. Loads Java conventions.`
- Headline idioms (Effective Java): minimize mutability (final fields, immutable value types); `record` for data carriers; `Optional` for absent returns (not fields/params); program to interfaces; favor composition over inheritance; static factory methods over constructors where they add clarity.
- Research anchors (P3): Google Java Style Guide; *Effective Java* (Bloch) idioms; Oracle Java docs (records, sealed types); `spotless`/Checkstyle + Error Prone for the tooling line.

- [ ] **Step 1 (P1): Add the failing smoke test:**

```bash
@test "lang-java skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-java/SKILL.md"
}
```

- [ ] **Step 2 (P2): Verify it fails** — `bats tests/skills.bats -f "lang-java"` → FAIL.
- [ ] **Step 3 (P3): Research pass** — dispatch with the Java anchors.
- [ ] **Step 4 (P4): Author `claude/skills/lang-java/SKILL.md`.**
- [ ] **Step 5 (P5): Well-formedness check.**
- [ ] **Step 6 (P6): Run tests** — `-f "lang-java"` PASS; `bats tests/` green.
- [ ] **Step 7 (P7): Commit** — `git commit -m "feat: add lang-java conventions skill"`.

---

## Task 6: Final verification & PR

**Files:** none (integration only).

- [ ] **Step 1: Full test run** — `cd ~/dev/claude-setup-public && bats tests/` → Expected: all green (prior count + 5 new explicit skill tests).
- [ ] **Step 2: Lean check** — for each new skill: `wc -l claude/skills/lang-*/SKILL.md` → Expected: each < ~500 lines. Any `tooling.md` companion is justified by content that would otherwise exceed lean.
- [ ] **Step 3: Sources audit** — open each `SKILL.md`; confirm every convention traces to a `Sources` entry and the `Sources` block is present and non-empty.
- [ ] **Step 4: Push & open PR** — `git push -u origin feature/lang-skills-batch` then `gh pr create --base main` with a body summarizing the five skills and the research-gated process. (Per global workflow: merge with a merge commit and green CI; delete the branch after.)
- [ ] **Step 5: Fork pickup (after merge)** — in `~/dev/claude-setup` (the fork): `git pull upstream main` to bring the new skills into the daily driver. Update `docs/HANDOFF.md` to mark Item D done and point to Item E.

## Self-Review (completed during authoring)

- **Spec coverage:** all five languages (Tasks 1–5) ✓; shared contract/template (P4) ✓; tooling-depth policy (P4) ✓; source-authority + Sources block (P3/P4, Task 6 Step 3) ✓; Standard research depth via anchors (per-task Inputs) ✓; explicit per-skill bats tests + full green (P1/P6, Task 6 Step 1) ✓; one batched PR + fork pickup (Task 6 Steps 4–5) ✓; lean limit (Task 6 Step 2) ✓.
- **Placeholder scan:** the only non-literal content is the skills' prose body, which is necessarily research-derived (P3); the concrete artifacts — bats tests, frontmatter `description` lines, research anchors, template, commands — are all literal. No TBD/TODO.
- **Type/name consistency:** skill dir names (`lang-go`/`lang-kotlin`/`lang-typescript`/`lang-rust`/`lang-java`), test names, and commit messages are consistent across tasks and match `SKILLS_DIR/<name>/SKILL.md`.
