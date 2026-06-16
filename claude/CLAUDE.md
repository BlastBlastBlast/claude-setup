# Global Claude Code Instructions

## Working principles (all languages, all repos)

- **Research before you assume.** Before setting a pattern, writing non-trivial code, or
  adopting a new language/framework/tool, check current best practice — don't rely on
  training data. Source priority: (1) Anthropic official (`code.claude.com/docs`, the
  `claude-api` skill, the `claude-code-guide` agent), (2) Context7 for library docs,
  (3) recognized maintainers/experts, (4) community. Cite the source when setting a convention.
- **Verify before you claim.** Never say "done / fixed / passing" without showing the
  evidence — the command and its output, test results, or a screenshot. If you can't
  verify it, don't ship it.
- **Reuse before you create.** Before writing new code in a domain, actively find the
  canonical helper/class that already does it — check the area's `AGENTS.md` and search
  the code (use the `feature-dev` code-explorer for non-trivial cases). Call or extend it;
  never reimplement its logic inline.
- **Organize by area; keep files small.** Prefer a folder of small, single-purpose files
  over one large file. A large file signals a refactor (existing large files may be
  extended, then refactored later). When an area grows, give it a nested `AGENTS.md` that
  records its conventions, gotchas, AND the canonical abstractions to reuse (the classes
  and helpers to call instead of reinventing) — so reuse patterns stay discoverable
  instead of getting lost.
- **Keep complexity low.** Avoid deep nesting and nested loops — extract named functions
  instead. Choose data structures by access pattern (dict for keyed lookup, list for
  ordered iteration).
- **Type everything.** Strong typing by default; type hints on every parameter/return in
  dynamically typed languages; docstrings on public surfaces.
- **Large files in git:** source → split into smaller files (never Git LFS — it breaks
  diff/blame/review). Large binary/generated assets (images, geojson, embeddings,
  datasets) → Git LFS via `.gitattributes`.
- **Tooling:** install/update via Homebrew (declared in a Brewfile); no manual downloads
  unless no formula/cask exists.

## Review handoffs
- **Hand reviews to Crit.** When you'd ask the user to eyeball something themselves — a code
  diff, a plan/doc, or rendered UI/design — offer to open it in [Crit](https://crit.md/) instead
  of pointing them at a file: `crit` for the working diff, `crit <file>` for a plan/doc, Crit's
  live-app / static-HTML mode for UI/design review. Only when `crit` is on `PATH`; it's an offer,
  not a gate; skip trivial one-liners.

## Session & context hygiene
- Context is the constraint; performance degrades as it fills. Hand off around ~50%
  context. Use `/clear` between unrelated tasks. Delegate read-heavy investigation to
  subagents so the main context stays clean.

## Commits
No AI attribution anywhere — the developer is responsible for whatever ends up in the repo.
Never add `Co-Authored-By` lines, "Generated with Claude Code" footers, or any other Claude/AI
mention to commit messages or PR descriptions.

Use conventional commit format: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`.
Multi-line bodies when the change needs explanation — blank line, then bullet points for what changed and why.

## Git workflow
- Always branch from `main`, kebab-case with prefix: `feature/`, `fix/`, `refactor/`
- Keep branches short-lived and focused (aim to review + merge within 1–3 days)
- Update a branch/PR by rebasing onto main — never merge `main` into a feature branch:
  `git fetch origin && git rebase origin/main`, resolve, `git rebase --continue`
- Force push only with lease, and only on your own branch: `git push --force-with-lease`
- Integrate PRs with a merge commit (`gh pr merge --merge`) — never squash or rebase-merge;
  keep the classic "Merge pull request #N from …" commit. Delete the branch after (`-d`)
- Only merge a PR with green CI (`gh pr checks`); rare exceptions only (e.g. emergency hotfix)

## Tests
- Test-first for features and bugfixes; skip for trivial one-line diffs.
- Right-sized and risk-driven: favor cheap unit tests; use integration tests selectively
  at real boundaries; E2E sparingly for critical paths. Test where risk concentrates, not
  for coverage's sake. Each test pins one behavior (an executable spec). Prune redundant
  tests — don't maximize volume.
- `test_<module>.py` matches source module name
- Group by concept in classes: `class TestCampaignFunnel:`
- One scenario per test method, descriptive name: `def test_cross_customer_isolation(self):`
- Session-scoped fixtures for infrastructure, function-scoped for test data
- Always clean up test data in fixture teardown

---

## Language conventions
Per-language conventions live in on-demand skills (loaded only when relevant), not in this file:
- Go → `lang-go` skill
- Java → `lang-java` skill
- JavaScript → `lang-js` skill
- Kotlin → `lang-kotlin` skill
- Python → `lang-python` skill
- Rust → `lang-rust` skill
- TypeScript → `lang-typescript` skill

Repo-local `AGENTS.md` / `CLAUDE.md` conventions take precedence over these skills. Author new
language skills with the `research-to-skill` skill (authoritative sources + a `Sources` block).

## Security
- **Least privilege:** grant the narrowest scope/permissions that work; isolate filesystem and network access so a compromise can't escalate or exfiltrate.
- **Never hardcode secrets** — load credentials from a secret manager/env; keep them out of source and logs.
- **Treat all external input as untrusted:** parameterize queries and shell calls (never string-build SQL/commands); avoid dynamic code execution (`eval`, `pickle`, raw `innerHTML`).
- **Gate sensitive data and operations behind authentication/authorization** — the enforcement boundary is a per-project architectural decision; check it server-side.
- **Defense in depth:** no single check is a guarantee; layer in-editor review, PR review, and CI scanning.
- **Don't expose or log PII by default** — minimize and protect sensitive data.
