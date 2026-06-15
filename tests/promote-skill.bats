#!/usr/bin/env bats

load helper

setup() { load_promote_skill; }

# A minimal valid skill dir at $1/<name>/SKILL.md with frontmatter.
_make_skill() {
  local root="$1" name="$2"
  mkdir -p "$root/$name"
  cat > "$root/$name/SKILL.md" <<EOF
---
name: $name
description: Test skill $name for promote-skill.
---

# $name
body
EOF
}

@test "promote-skill help prints usage" {
  run main help
  [ "$status" -eq 0 ]
  [[ "$output" == *"promote-skill up <name>"* ]]
  [[ "$output" == *"promote-skill down <name>"* ]]
}

@test "promote-skill with unknown command errors and prints usage" {
  run main bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown command"* ]]
}

@test "up copies a repo skill into the global skills dir" {
  repo="$(make_temp_repo)"; cd "$repo"
  _make_skill "$repo/.claude/skills" demo
  global="${BATS_TEST_TMPDIR}/global"; mkdir -p "$global"

  GLOBAL_SKILLS_DIR="$global" run main up demo

  [ "$status" -eq 0 ]
  [ -f "$global/demo/SKILL.md" ]
  [[ "$output" == *"copied skill"* ]]
}

@test "down copies a global skill into the current repo's .claude/skills" {
  repo="$(make_temp_repo)"; cd "$repo"
  global="${BATS_TEST_TMPDIR}/global"; _make_skill "$global" demo

  GLOBAL_SKILLS_DIR="$global" run main down demo

  [ "$status" -eq 0 ]
  [ -f "$repo/.claude/skills/demo/SKILL.md" ]
  # down must warn that global overrides project on name collision
  [[ "$output" == *"skillOverrides"* ]]
}

@test "up fails when the source skill is missing" {
  repo="$(make_temp_repo)"; cd "$repo"
  global="${BATS_TEST_TMPDIR}/global"; mkdir -p "$global"
  GLOBAL_SKILLS_DIR="$global" run main up nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "up fails when the source is not a well-formed skill (no SKILL.md)" {
  repo="$(make_temp_repo)"; cd "$repo"
  mkdir -p "$repo/.claude/skills/broken"   # dir exists, no SKILL.md
  global="${BATS_TEST_TMPDIR}/global"; mkdir -p "$global"
  GLOBAL_SKILLS_DIR="$global" run main up broken
  [ "$status" -ne 0 ]
  [[ "$output" == *"SKILL.md"* ]]
}

@test "up refuses to overwrite an existing target without --force" {
  repo="$(make_temp_repo)"; cd "$repo"
  _make_skill "$repo/.claude/skills" demo
  global="${BATS_TEST_TMPDIR}/global"; _make_skill "$global" demo
  GLOBAL_SKILLS_DIR="$global" run main up demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"exists"* ]]
}

@test "up --force overwrites an existing target" {
  repo="$(make_temp_repo)"; cd "$repo"
  _make_skill "$repo/.claude/skills" demo
  global="${BATS_TEST_TMPDIR}/global"; _make_skill "$global" demo
  GLOBAL_SKILLS_DIR="$global" run main up --force demo
  [ "$status" -eq 0 ]
}

@test "--dry-run reports the action without creating the target" {
  repo="$(make_temp_repo)"; cd "$repo"
  _make_skill "$repo/.claude/skills" demo
  global="${BATS_TEST_TMPDIR}/global"; mkdir -p "$global"
  GLOBAL_SKILLS_DIR="$global" run main up --dry-run demo
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN"* ]]
  [ ! -e "$global/demo" ]
}

@test "up --force refuses when source and target resolve to the same path" {
  repo="$(make_temp_repo)"; cd "$repo"
  _make_skill "$repo/.claude/skills" demo
  ln -s "$repo/.claude/skills" "${BATS_TEST_TMPDIR}/global-link"
  GLOBAL_SKILLS_DIR="${BATS_TEST_TMPDIR}/global-link" run main up --force demo
  [ "$status" -ne 0 ]
  [[ "$output" == *"same path"* ]]
  # the source skill must still exist (was NOT rm -rf'd)
  [ -f "$repo/.claude/skills/demo/SKILL.md" ]
}
