---
paths:
  - "**/CLAUDE.md"
  - "**/AGENTS.md"
  - "**/SKILL.md"
  - "**/.claude/rules/**"
  - "**/.claude/settings*.json"
---

# Editing instruction files (CLAUDE.md, AGENTS.md, skills, rules)

Place guidance in the cheapest tier that still fires:

| Guidance shape | Tier |
|---|---|
| Universal, every task | CLAUDE.md — keep under 200 lines; per line ask "would removing this cause a mistake?" |
| "Every time X, do Y" | A hook (deterministic), not prose |
| "Must never happen" | `permissions.deny` or a PreToolUse guard, not prose |
| Conditional on file paths | A `.claude/rules/*.md` with `paths:` frontmatter (its only supported field) |
| Conditional on task type | A skill — description states when to fire AND when not to |
| Lookup material (tables, skeletons, catalogs) | `references/*.md` inside the skill, loaded on demand |

Writing style: judgment criteria over MUST/NEVER mandates — current models follow rigid rules
too literally and emphasis inflation causes overtriggering. State the criterion and the reason
("a wrapping CTA reads as broken"), not an ALL-CAPS ban. Skill descriptions are always-loaded:
keep them trigger-sharp, third-person, with negative scope, and never summarize the skill's
workflow in them.

The full classification procedure (the five ordered questions, hook/rule authoring contracts,
and the current tier inventory) lives in the setup repo's `docs/enforcement-tiers.md` — read it
before converting prose to a hook or rule, or adding a new one.
