---
name: research-to-skill
description: Use when creating or updating a Claude Code skill — especially a language/framework conventions skill — to research authoritative sources first, fill the standard template, and require a Sources block. Wraps superpowers writing-skills.
---

# research-to-skill

Author skills the right way: research authoritative sources BEFORE writing, fit a
consistent template, and cite every convention. This is a thin process on top of
`superpowers:writing-skills` — it adds the front-half discipline, then hands off.

> Repo-local conventions take precedence; this process produces global skills by default.

## When to use
Creating a new `lang-<x>` (or framework) skill, or revising one. Also any skill where
correctness depends on external best practice rather than local taste.

## Process (do in order — do not skip the research gate)

1. **Define scope.** One language/framework/topic per skill. Name it `lang-<x>` for a
   language. Decide scope: global (`claude/skills/`) unless it is project-specific.

2. **Authoritative-source research pass.** Gather conventions from, in priority order:
   - **Methodology (how to author skills):** Anthropic official only — this skill,
     `superpowers:writing-skills`, `code.claude.com/docs`. Use the `claude-code-guide` agent
     for Claude Code questions.
   - **Language/framework conventions:** official docs / style guides, the language's own
     maintainers, and widely-respected expert practitioners and reference repos. Use Context7
     for library docs and `WebFetch` of official doc sites.
   - **NEVER** rely on popularity-by-volume, blog SEO, or media "experts". If a claim has no
     authoritative source, it does not go in the skill.

3. **Fill the standard template** (see `template.md` in this skill's directory). Every
   `lang-<x>` skill has these sections, in order: Core idioms, Reuse & helpers, Architecture,
   Anti-patterns, Sources. Open with the repo-local-precedence deferral line.

4. **Express the universal vision in this language's idioms.** The global principles (reuse
   over re-creation, architecture over micro-optimization, complexity discipline, strong
   typing, readability) live once in `CLAUDE.md`. The skill makes them concrete for the
   language — it does not restate them.

5. **Require a `Sources` block.** List the authoritative references the skill was built from.
   No source → cut the line.

6. **Keep it lean.** `SKILL.md` under ~500 lines; push long reference material into companion
   files loaded on demand. The `description` must read like a user request ("Use when writing
   <Language>…") so auto-invocation fires.

7. **Hand off to `superpowers:writing-skills`** for final well-formed authoring and the
   frontmatter/routing-description check.

## Done when
- The skill follows the template, every convention traces to a cited source, the `Sources`
  block is present, and the frontmatter smoke check (`tests/skills.bats`) passes.
