# Global Claude Code Instructions

## Working principles (all languages, all repos)

- **Research before you assume — when setting direction.** When adopting a new language, framework,
  tool, or pattern, or setting a convention others will follow, check current best practice — don't rely
  on training data. Routine code in an established codebase follows the codebase, no research needed.
  Source priority: (1) Anthropic official (`code.claude.com/docs`, the `claude-api` skill, the
  `claude-code-guide` agent), (2) Context7 for library docs, (3) recognized maintainers, (4) community.
  Cite the source when setting a convention.
- **Reuse before you create.** Find the canonical helper/class that already does the job (check the area's
  `AGENTS.md`, search the code) and call or extend it. Never reimplement its logic inline.
- **Organize by area; keep files small.** Prefer a folder of small single-purpose files over one large
  file; a large file is a refactor signal. When an area grows, give it a nested `AGENTS.md` recording its
  conventions, gotchas, and the abstractions to reuse — so reuse patterns stay discoverable.
- **Tooling** installs via Homebrew, declared in a Brewfile — no manual downloads unless no formula exists.
- **Large files in git:** split source into smaller files (never Git LFS — it breaks diff/blame/review).
  Large binary/generated assets (images, geojson, datasets) → Git LFS via `.gitattributes`.

## When I have to run something, give me the command

Default stays: if you can do it yourself and you're allowed to, do it. This applies only when the step
genuinely requires **me** — an interactive login (`gcloud auth login`, `op signin`), a PR merge you've been
told to hand over, something outside your sandbox, or a decision that's mine to make. In that case:

- Give the **exact command, copy-pasteable, on its own line** — not a description of it.
- Real values, no placeholders: `gh pr merge 277 --merge -d`, not `gh pr merge <number>`.
- One block, in run order, with the flags I actually want (merge commit, delete branch, `--force-with-lease`).
- One line on what it does and what to check afterwards, then stop — no need to ask permission to run
  something only I can run.
- Inside a Claude Code session, note that I can run it in place with the `! <command>` prefix.

Don't manufacture a handoff for work you could have finished. Reads, edits, tests and builds are yours to
run — hand back the command instead of doing the work and you've just made me the executor.

## Model selection for agentic work

Plan → execute, with plan precision as the controlling variable: the sharper the plan, the cheaper the
executor can be. Opus does judgment, Sonnet does mechanics.

| Role | Model |
|---|---|
| Planning — spec reading, scope decisions, writing implementation plans | Opus |
| Execution coordination (subagent-driven-development loop) | Opus |
| Spec review / code review between tasks | Opus |
| Implementation subagent — task **fully specified** (exact files, code, tests; no spikes, no open design decisions) | **Sonnet** |
| Implementation subagent — task has unknowns (debugging, spikes, design gaps, plan conflicts with reality) | Opus |
| Exploration / fact-finding (codebase mapping, doc lookups) | Agent-definition default |

- **Always set `model` explicitly on every Agent dispatch** — an omitted model runs on the session model,
  silently putting mechanical work on the most expensive tier. Generic dispatches (`general-purpose`,
  `claude`, no type) get `model: "sonnet"`; only read-only agents that pin their own cheaper model
  (`Explore`, `claude-code-guide`) may omit it. Forks always run on the parent model and ignore `model`.
- For a genuinely trivial step (one read/grep, no synthesis), don't dispatch — do it inline.
- Executors don't replan: if execution reveals a plan defect, fix the plan at the planning tier.

## Commits

- **No AI attribution anywhere** — no `Co-Authored-By`, no "Generated with Claude Code" footer, no
  Claude/AI mention in commit messages or PR bodies. I'm responsible for whatever lands in the repo.
- Conventional format: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`. Multi-line body — blank line, then
  bullets for what changed and why — when the change needs explanation.

## Git workflow

- Branch from `main`, kebab-case with a prefix: `feature/`, `fix/`, `refactor/`. Keep branches short-lived
  and focused (review + merge within 1–3 days).
- Update a branch by rebasing onto main — never merge `main` into a feature branch:
  `git fetch origin && git rebase origin/main`, resolve, `git rebase --continue`.
- Force push only with `--force-with-lease`, and only on your own branch.
- **Don't merge PRs yourself.** Stop at "PR open + green CI" and hand me the command. Integration is a
  merge commit — `gh pr merge <n> --merge -d` — never squash or rebase-merge; keep the classic
  "Merge pull request #N from …" commit.
- Only merge on green CI (`gh pr checks`); rare exceptions only, e.g. an emergency hotfix.
- Interactive git flags (`-i`) don't work in this environment — hand those to me.

## Tests

- Test-first for features and bugfixes; skip for trivial one-line diffs.
- Right-sized and risk-driven: cheap unit tests by default, integration tests selectively at real
  boundaries, E2E sparingly for critical paths. Test where risk concentrates, not for coverage's sake.
- Each test pins one behavior and is named for it — an executable spec. Prune redundant tests; don't
  maximize volume.
- Always clean up test data in fixture teardown.

## Security

- **Gate sensitive data and operations behind authorization.** Where the boundary sits is a per-project
  architectural decision; enforce it server-side regardless.
- **Don't log or expose PII by default** — minimize and protect sensitive data.

## Session hygiene & review handoffs

- Hand off at natural seams (task done, tests green, work committed), not when the window forces it.
  Current models hold quality across large contexts — the seam is the trigger, not a fill percentage.
- **Checkpoint as you go:** commit finished work, write conclusions to docs rather than carrying them in
  context, `/clear` between unrelated tasks, delegate read-heavy investigation to subagents. When handing
  off, use the `handoff` skill — a handoff I can't resume from one paste isn't a handoff.
- When you'd ask me to eyeball something — a diff, a plan/doc, rendered UI — offer [Crit](https://crit.md/)
  instead of pointing me at a file: `crit` for the working diff, `crit <file>` for a plan/doc, live-app or
  static-HTML mode for UI. Only when `crit` is on `PATH`; it's an offer, not a gate; skip trivial one-liners.

## Claude 5 models: skill carve-outs

These instructions take precedence over any skill's own text (Opus 5-class models self-verify and
over-delegate; verification prose and hard gates written for older models now cost quality — see
`~/dev/opus5-claude-md-ruleset.md`):

- **Superpowers Iron Laws are judgment guides, not gates.** Apply `verification-before-completion`,
  `systematic-debugging`, and `test-driven-development` as engineering criteria; skip their
  rationalization tables, restart mandates, and re-check loops. Evidence before claiming done still holds —
  run the check once and show output; don't re-verify verified work.
- **Skip `brainstorming`'s hard-gate for bounded/mechanical tasks** (a describable-in-one-sentence diff,
  file moves, config edits). Use it for genuinely architectural or creative work.
- **Reviews scale with the diff.** Fresh-context review (`requesting-code-review`, `/code-review`) only for
  non-trivial diffs; a same-prompt check suffices for small ones. Never spawn a subagent to verify or
  double-check your own work.
- **Report reviews fully, filter later:** findings carry confidence + severity; never pre-filter to
  "high-severity only".

## Language conventions

Per-language conventions live in on-demand skills, loaded only when relevant: `lang-go`, `lang-java`,
`lang-js`, `lang-kotlin`, `lang-python`, `lang-rust`, `lang-typescript`. Repo-local `AGENTS.md` /
`CLAUDE.md` conventions take precedence over these skills. Author new language skills with
`research-to-skill` (authoritative sources + a `Sources` block).
