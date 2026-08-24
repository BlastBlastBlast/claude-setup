#!/usr/bin/env bats

load helper

setup() {
  load_install
}

@test "link_file creates a symlink pointing at the source" {
  src="${BATS_TEST_TMPDIR}/source.txt"
  dest="${BATS_TEST_TMPDIR}/nested/dir/dest.txt"
  echo "hello" > "$src"

  run link_file "$src" "$dest"

  [ "$status" -eq 0 ]
  [ -L "$dest" ]
  [ "$(cat "$dest")" = "hello" ]
}

@test "link_file backs up a pre-existing real file" {
  src="${BATS_TEST_TMPDIR}/source.txt"
  dest="${BATS_TEST_TMPDIR}/dest.txt"
  echo "new" > "$src"
  echo "old" > "$dest"

  run link_file "$src" "$dest"

  [ "$status" -eq 0 ]
  [ -L "$dest" ]
  [ "$(cat "$dest")" = "new" ]
  # the old real file was preserved as a .bak.* sibling
  run bash -c "cat ${BATS_TEST_TMPDIR}/dest.txt.bak.*"
  [ "$output" = "old" ]
}

@test "link_file is idempotent when the correct symlink already exists" {
  src="${BATS_TEST_TMPDIR}/source.txt"
  dest="${BATS_TEST_TMPDIR}/dest.txt"
  echo "data" > "$src"

  link_file "$src" "$dest"
  run link_file "$src" "$dest"   # second run

  [ "$status" -eq 0 ]
  [ -L "$dest" ]
  # no backup was created on the idempotent second run
  run bash -c "ls ${BATS_TEST_TMPDIR}/dest.txt.bak.* 2>/dev/null | wc -l | tr -d ' '"
  [ "$output" = "0" ]
}

@test "links creates every expected symlink under a temp HOME" {
  export HOME="${BATS_TEST_TMPDIR}/home"
  export XDG_CONFIG_HOME="${HOME}/.config"
  mkdir -p "$HOME"

  run links

  [ "$status" -eq 0 ]
  [ "$(readlink "$HOME/.claude/CLAUDE.md")" = "${REPO_ROOT}/claude/CLAUDE.md" ]
  [ "$(readlink "$HOME/.claude/settings.json")" = "${REPO_ROOT}/claude/settings.json" ]
  [ "$(readlink "$HOME/.claude/skills")" = "${REPO_ROOT}/claude/skills" ]
  [ "$(readlink "$HOME/.claude/rules")" = "${REPO_ROOT}/claude/rules" ]
  [ "$(readlink "$HOME/.config/cmux/cmux.json")" = "${REPO_ROOT}/cmux/cmux.json" ]
  [ "$(readlink "$HOME/.local/bin/wt")" = "${REPO_ROOT}/bin/wt" ]
  [ "$(readlink "$HOME/.local/bin/promote-skill")" = "${REPO_ROOT}/bin/promote-skill" ]
  [ "$(readlink "$HOME/.local/bin/claude-guard-destructive")" = "${REPO_ROOT}/bin/claude-guard-destructive" ]
  [ "$(readlink "$HOME/.local/bin/claude-guard-agent-dispatch")" = "${REPO_ROOT}/bin/claude-guard-agent-dispatch" ]
  [ "$(readlink "$HOME/.zshrc")" = "${REPO_ROOT}/shell/zshrc" ]
  [ "$(readlink "$HOME/.config/sheldon/plugins.toml")" = "${REPO_ROOT}/shell/sheldon/plugins.toml" ]
}

# check_claude_version tests stub `claude` via a fake bin dir on PATH; the
# check must always exit 0 (warn-only) and warn exactly when below the floor.
_fake_claude() {
  local ver="$1" bindir="${BATS_TEST_TMPDIR}/fakebin"
  mkdir -p "$bindir"
  printf '#!/bin/sh\necho "%s (Claude Code)"\n' "$ver" > "$bindir/claude"
  chmod +x "$bindir/claude"
  export PATH="$bindir:$PATH"
}

@test "check_claude_version passes silently at or above the floor" {
  _fake_claude "$MIN_CLAUDE_CODE_VERSION"
  run check_claude_version
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "check_claude_version warns (but exits 0) below the floor" {
  _fake_claude "2.1.100"
  run check_claude_version
  [ "$status" -eq 0 ]
  [[ "$output" == *"2.1.100"* ]]
  [[ "$output" == *"silently ignored"* ]]
}

@test "check_claude_version warns (but exits 0) when claude is missing" {
  bindir="${BATS_TEST_TMPDIR}/emptybin"
  mkdir -p "$bindir"
  PATH="$bindir:/usr/bin:/bin" run check_claude_version
  [ "$status" -eq 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "every claude/rules file has a paths frontmatter list" {
  for f in "${REPO_ROOT}"/claude/rules/*.md; do
    run python3 -c "
import sys
head = open('$f').read().split('---')
assert head[1].strip().startswith('paths:'), '$f missing paths frontmatter'
"
    [ "$status" -eq 0 ]
  done
}

@test "_set_hooks_path points a repo's git hooks at the tracked hooks/ dir" {
  tmprepo="${BATS_TEST_TMPDIR}/hookrepo"
  mkdir -p "$tmprepo"
  git -C "$tmprepo" init -q -b main

  # _set_hooks_path acts on $REPO_DIR; point it at the throwaway repo so the test
  # is isolated and never mutates the checkout it runs in.
  REPO_DIR="$tmprepo"
  run _set_hooks_path
  [ "$status" -eq 0 ]

  run git -C "$tmprepo" config --local core.hooksPath
  [ "$status" -eq 0 ]
  [ "$output" = "hooks" ]
}
