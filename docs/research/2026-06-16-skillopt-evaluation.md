# SkillOpt — evaluation & decision (2026-06-16)

**Decision: DEFER.** SkillOpt optimizes a skill document against an *automatic, held-out, per-task
score* we do not have for our skills, and our corpus is the subjective coding-conventions kind that
Anthropic's own `skill-creator` says should not be auto-scored. Revisit if/when we build a graded
skill-quality benchmark (sketch below).

This evaluates [`microsoft/SkillOpt`](https://github.com/microsoft/SkillOpt) for our skill-authoring
pipeline (the 7 `lang-*` convention skills + `research-to-skill`). All numeric/behavioral claims
below were verified against primary sources; see **Sources**.

## What SkillOpt is

A **text-space optimizer** that "trains" a natural-language skill document against a scored task
environment, without touching model weights. A separate optimizer model proposes *bounded
add/delete/replace edits* to a single skill doc; an edit is accepted **only when a held-out
selection score improves** (validation-gated search). It borrows deep-learning framing — epochs,
batch size, "textual learning-rate budgets", rejected-edit buffers. Output is a deployable
`best_skill.md` (typically 300–2,000 tokens) used with zero extra inference-time calls.

**Maturity:** MIT, `microsoft` org, ~7.5k stars / ~720 forks, actively maintained (last push
2026-06-15). But it is **v0.1.0 and ~5 weeks old** (created 2026-05-08) — packaged research code,
not a stable dependency. No explicit authored "Limitations" section was found.

## The "+19.1 points in Claude Code" claim — verified & decoded

The number is **real and correctly attributed** — not a misattribution. README and the arXiv
abstract both state, verbatim, that on GPT-5.5 optimized skills lift average no-skill accuracy by
"+23.5 points in direct chat, +24.8 inside the Codex agentic loop, and **+19.1 inside Claude
Code**".

But decoded, three caveats matter:
- **It is GPT-5.5 run *inside the Claude Code CLI as a harness*** — Claude Code is the agent
  harness, not a Claude model doing the work. Easy to misread as "Claude got +19.1".
- **It is an average over six diverse benchmarks** — SearchQA, SpreadsheetBench, OfficeQA, DocVQA,
  LiveMathematicianBench, ALFWorld — **none of them a coding benchmark.**
- **Baseline is "no-skill"** accuracy; the lift is from deploying the optimized `best_skill.md`.

So the headline is a genuine result, but it is *not* evidence of gains on code-convention skills.

## What it requires

- **An automatic, per-task scoring signal with a held-out split.** The whole method is
  validation-gated; there is no human-in-the-loop grading. To optimize our own material we must
  implement a custom environment under `skillopt/envs/` supplying our own scorer and task set.
- **Target model + optimizer model API access**, and budget for many scored rollouts during
  optimization (cost scales with rollouts × tasks × iterations).
- **Python 3.10+**, `pip install skillopt`. Supports OpenAI/Azure/Claude/Qwen/MiniMax backends and
  Codex CLI / Claude Code CLI harnesses (model-agnostic, not Claude-specific).

## SkillOpt vs the official `skill-creator` plugin

The handoff's prior was "`skill-creator` already does this, so defer". That prior is **only partly
right** — the two do *different* things:

| Capability | `skill-creator` (Anthropic, enabled) | SkillOpt |
|---|---|---|
| Auto-optimize the skill **description** (frontmatter) | **Yes** — closed loop, train/test split, picks best-by-test trigger score | n/a |
| Auto-optimize the skill **body** text | **No** — body is rewritten by Claude from human review; its analyzer is explicitly *forbidden* from suggesting edits during benchmarking | **Yes** — validation-gated bounded edits to the body |
| Measure outputs / benchmark | Yes — LLM-judge over human-authored assertions + programmatic checks; pass/fail | Yes — automatic per-task score |
| Variance analysis | Yes — repeated runs, mean ± stddev, flaky-eval flags (observational only) | implicit in held-out scoring |
| Requires an automatic metric | Only for trigger optimization; body eval can be qualitative/human | **Always** |

So SkillOpt **adds a real capability** `skill-creator` lacks — automated *body* optimization. The
overlap argument is therefore the *weak* reason to defer. The strong reasons are below.

## Decision & rationale — DEFER

1. **No metric.** SkillOpt only improves a skill against an automatic graded score, and we have no
   such scorer for our skills.
2. **Wrong skill type.** Our corpus is `lang-*` *subjective coding conventions/style* — exactly the
   category `skill-creator` says to evaluate qualitatively, "don't force assertions onto things that
   need human judgment." Auto-scoring these is itself an unsolved problem.
3. **Proven value is elsewhere.** SkillOpt's demonstrated gains are on objective-answer tasks
   (QA/math/spreadsheet/interactive-env), a different shape from "did the generated code follow our
   conventions".
4. **Maturity.** v0.1.0, ~5 weeks old — not yet a dependency to build a pipeline on.

The blocker is not overlap with `skill-creator`; it is that adopting SkillOpt presupposes a graded
skill-quality benchmark we have not built. That is real R&D, out of scope here.

## Revisit conditions + benchmark sketch

Revisit SkillOpt if **any** of these change:
- We build (or acquire) an **automatic, held-out skill-quality benchmark** for a skill domain.
- We add **objective-answer skills** (where correctness is machine-checkable) to the corpus.
- SkillOpt matures past 0.x with stable APIs and documented limitations.

**What a first benchmark could look like (sketch, not a commitment):** pick a skill domain with a
*machine-checkable* success signal — **not** the subjective `lang-*` style skills. For example a
hypothetical "generate-a-CLI-from-a-spec" skill: a task set of spec→expected-behavior pairs, an
automatable scorer (does the generated tool pass a fixed test suite?), and a train/held-out split.
That gives SkillOpt the validation gate it needs. Style/convention skills would require a proxy
metric (e.g. linter/formatter pass-rate on generated code) whose validity is itself unproven — a
poor first target. Start objective; only attempt subjective skills once the harness is trusted.

## Sources

- Repo + README: <https://github.com/microsoft/SkillOpt> ·
  <https://raw.githubusercontent.com/microsoft/SkillOpt/main/README.md>
- Repo metadata (stars/forks/license/dates): <https://api.github.com/repos/microsoft/SkillOpt>
- Benchmark/env list: <https://github.com/microsoft/SkillOpt/tree/main/skillopt/envs>
- Paper: arXiv 2605.23904, "SkillOpt: Executive Strategy for Self-Evolving Agent Skills" —
  <https://arxiv.org/abs/2605.23904>
- Project page: <https://microsoft.github.io/SkillOpt/>
- `skill-creator` (Anthropic, installed): `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/` —
  `SKILL.md`, `scripts/run_loop.py`, `scripts/improve_description.py`, `scripts/aggregate_benchmark.py`,
  `agents/grader.md`, `agents/analyzer.md`.
