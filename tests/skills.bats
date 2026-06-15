#!/usr/bin/env bats

load helper

# Path to the repo's tracked skills dir.
SKILLS_DIR="${REPO_ROOT}/claude/skills"

# Echo the frontmatter block (between the first two '---' lines) of a SKILL.md.
_frontmatter() {
  awk '
    NR==1 && $0!="---" { exit 1 }
    NR==1               { next }
    $0=="---"           { found=1; exit }
    { print }
    END { exit !found }
  ' "$1"
}

# Assert a SKILL.md has a frontmatter block with a non-empty description.
_assert_valid_skill() {
  local f="$1"
  [ -f "$f" ] || { echo "missing: $f"; return 1; }
  [ "$(head -n1 "$f")" = "---" ] || { echo "no frontmatter open in $f"; return 1; }
  local fm; fm="$(_frontmatter "$f")" || { echo "bad frontmatter in $f"; return 1; }
  echo "$fm" | grep -qE '^description:[[:space:]]*\S' || { echo "empty/missing description in $f"; return 1; }
}

@test "research-to-skill skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/research-to-skill/SKILL.md"
}

@test "every skill under claude/skills has valid frontmatter" {
  shopt -s nullglob
  local found=0
  for f in "$SKILLS_DIR"/*/SKILL.md; do
    found=1
    run _assert_valid_skill "$f"
    [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  done
  [ "$found" -eq 1 ] || skip "no skills present yet"
}

@test "lang-python skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-python/SKILL.md"
}

@test "lang-js skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-js/SKILL.md"
}

@test "lang-go skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-go/SKILL.md"
}

@test "lang-kotlin skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-kotlin/SKILL.md"
}

@test "lang-typescript skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-typescript/SKILL.md"
}

@test "lang-rust skill has valid frontmatter and a routing description" {
  _assert_valid_skill "$SKILLS_DIR/lang-rust/SKILL.md"
}

@test "_assert_valid_skill rejects a SKILL.md whose frontmatter is not closed" {
  local d="${BATS_TEST_TMPDIR}/unclosed"
  mkdir -p "$d"
  printf -- '---\nname: x\ndescription: no closing fence here\n\n# body\n' > "$d/SKILL.md"
  run _assert_valid_skill "$d/SKILL.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"bad frontmatter"* ]]
}
