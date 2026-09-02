#!/usr/bin/env bats

load helper

HO="${REPO_ROOT}/bin/claude-handoff"
SETTINGS="${REPO_ROOT}/claude/settings.json"

setup() {
  export CLAUDE_HANDOFF_HOME="${BATS_TEST_TMPDIR}/handoffs"
  REPO="$(make_temp_repo)"
}

# Write a handoff in $REPO and arm the pointer; echoes the file path.
arm() {
  local dir topic="${1:-A topic}"
  dir="$(cd "$REPO" && "$HO" dir)"
  printf '# %s\n\nbody\n' "$topic" > "$dir/h.md"
  (cd "$REPO" && "$HO" pointer "$dir/h.md" >/dev/null)
  echo "$dir/h.md"
}

clear_event() { printf '{"hook_event_name":"SessionStart","source":"clear","cwd":"%s"}' "$REPO"; }

@test "handoffs are stored outside the working repo" {
  dir="$(cd "$REPO" && "$HO" dir)"
  [[ "$dir" == "${CLAUDE_HANDOFF_HOME}"/* ]]
  [[ "$dir" != "$REPO"/* ]]
}

@test "two worktrees of one repo get different handoff dirs" {
  git -C "$REPO" worktree add -q -b feat "${BATS_TEST_TMPDIR}/wt" >/dev/null 2>&1 || skip "worktree unsupported"
  a="$(cd "$REPO" && "$HO" dir)"
  b="$(cd "${BATS_TEST_TMPDIR}/wt" && "$HO" dir)"
  [ "$a" != "$b" ]
}

@test "hook injects the pending handoff on /clear" {
  file="$(arm 'Resume this work')"
  output="$(clear_event | (cd "$REPO" && "$HO" hook))"
  echo "$output" | grep -q 'SessionStart'
  echo "$output" | grep -q 'Resume this work'
  echo "$output" | grep -qF "$file"
}

@test "hook fires exactly once - a second /clear injects nothing" {
  arm >/dev/null
  clear_event | (cd "$REPO" && "$HO" hook) >/dev/null
  second="$(clear_event | (cd "$REPO" && "$HO" hook))"
  [ "$second" = "{}" ]
}

@test "hook ignores sources other than /clear" {
  arm >/dev/null
  out="$(printf '{"source":"startup","cwd":"%s"}' "$REPO" | (cd "$REPO" && "$HO" hook))"
  [ "$out" = "{}" ]
}

@test "a handoff in one repo never leaks into another" {
  arm >/dev/null
  other="${BATS_TEST_TMPDIR}/other"; mkdir -p "$other"; git -C "$other" init -q -b main
  out="$(printf '{"source":"clear","cwd":"%s"}' "$other" | (cd "$other" && "$HO" hook))"
  [ "$out" = "{}" ]
}

@test "hook emits valid JSON and exits 0 on garbage input" {
  run bash -c "echo 'not json' | '$HO' hook"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"
}

@test "hook output is valid JSON when it injects" {
  arm >/dev/null
  clear_event | (cd "$REPO" && "$HO" hook) | python3 -c "
import json,sys
d = json.load(sys.stdin)
assert d['hookSpecificOutput']['hookEventName'] == 'SessionStart'
assert d['hookSpecificOutput']['additionalContext']
"
}

# Tools that manage their own hook entries (Orca, for one) rewrite settings.json
# in place. One has appended a SessionStart of its own before now, which
# silently shadowed ours as a duplicate JSON key - last key wins. Both
# assertions below turn that drift into a test failure rather than a handoff
# that quietly stops resuming.
@test "settings.json registers the handoff SessionStart hook" {
  run python3 -c "
import json
ss = json.load(open('$SETTINGS'))['hooks']['SessionStart']
cmds = [h['command'] for e in ss for h in e.get('hooks', [])]
assert any('claude-handoff hook' in c for c in cmds), cmds
"
  [ "$status" -eq 0 ]
}

@test "settings.json has no duplicate hook keys" {
  run python3 -c "
import json, collections
def check(pairs):
    dupes = [k for k, c in collections.Counter(k for k, _ in pairs).items() if c > 1]
    assert not dupes, f'duplicate keys: {dupes}'
    return dict(pairs)
json.loads(open('$SETTINGS').read(), object_pairs_hook=check)
"
  [ "$status" -eq 0 ]
}

@test "install.sh links claude-handoff onto PATH" {
  run grep -F 'link_file "$REPO_DIR/bin/claude-handoff"' "${REPO_ROOT}/install.sh"
  [ "$status" -eq 0 ]
}
