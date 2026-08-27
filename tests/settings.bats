#!/usr/bin/env bats

load helper

SETTINGS="${REPO_ROOT}/claude/settings.json"

@test "settings.json is valid JSON" {
  run python3 -c "import json,sys; json.load(open('$SETTINGS'))"
  [ "$status" -eq 0 ]
}

@test "settings.json has no hardcoded /Users/<name>/ absolute paths" {
  run grep -nE '/Users/[^/"]+/' "$SETTINGS"
  [ "$status" -ne 0 ]   # grep finds nothing -> non-zero exit
}

@test "settings.json references the statusline via a portable \$HOME path" {
  run grep -F '$HOME/.local/bin/claude-statusline' "$SETTINGS"
  [ "$status" -eq 0 ]
}

# The status line and context monitor are optional (README), so every reference
# to them must tolerate absence. Unguarded, the PostToolUse hook printed a
# "No such file or directory" error after every single tool call on a machine
# that had not installed them by hand.
_optional_tool_commands() {
  python3 -c "
import json
s = json.load(open('$SETTINGS'))
cmds = [h.get('command','')
        for ev in s.get('hooks', {}).values()
        for grp in ev for h in grp.get('hooks', [])]
cmds.append(s.get('statusLine', {}).get('command', ''))
for c in cmds:
    if 'claude-statusline' in c or 'claude-context-monitor' in c:
        print(c)
"
}

@test "every optional-tool reference is guarded by an executable check" {
  run _optional_tool_commands
  [ "$status" -eq 0 ]
  [ -n "$output" ]
  while IFS= read -r cmd; do
    [[ "$cmd" == *'[ -x '* ]] || {
      echo "unguarded optional-tool reference: $cmd" >&2
      return 1
    }
  done <<< "$output"
}

@test "a guarded optional-tool command exits 0 and stays silent when absent" {
  while IFS= read -r cmd; do
    # $HOME points at an empty dir, so no optional binary exists.
    run env HOME="${BATS_TEST_TMPDIR}/emptyhome" /bin/sh -c "$cmd" <<< '{"tool_name":"Bash"}'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
  done <<< "$(_optional_tool_commands)"
}

@test "a guarded optional-tool command execs the binary when it is present" {
  fakehome="${BATS_TEST_TMPDIR}/fakehome"
  mkdir -p "$fakehome/.local/bin"
  for tool in claude-statusline claude-context-monitor; do
    printf '#!/bin/sh\nprintf RAN\n' > "$fakehome/.local/bin/$tool"
    chmod +x "$fakehome/.local/bin/$tool"
  done

  while IFS= read -r cmd; do
    run env HOME="$fakehome" /bin/sh -c "$cmd" <<< '{"tool_name":"Bash"}'
    [ "$status" -eq 0 ]
    [ "$output" = "RAN" ]
  done <<< "$(_optional_tool_commands)"
}

@test "settings.json enables exactly the recommended official plugin shortlist" {
  run python3 -c "
import json
ep = json.load(open('$SETTINGS')).get('enabledPlugins', {})
expected = {
  'superpowers@claude-plugins-official',
  'code-review@claude-plugins-official',
  'security-guidance@claude-plugins-official',
  'code-simplifier@claude-plugins-official',
  'skill-creator@claude-plugins-official',
  'session-report@claude-plugins-official',
  'pyright-lsp@claude-plugins-official',
  'typescript-lsp@claude-plugins-official',
}
enabled = {k for k, v in ep.items() if v is True}
assert enabled == expected, f'enabled {sorted(enabled)} != shortlist {sorted(expected)}'
"
  [ "$status" -eq 0 ]
}

@test "settings.json enables only official-marketplace plugins" {
  run python3 -c "
import json
s = json.load(open('$SETTINGS'))
assert not s.get('extraKnownMarketplaces', {}), 'unexpected extra marketplace declared in public settings'
ep = s.get('enabledPlugins', {})
bad = [k for k in ep if not k.endswith('@claude-plugins-official')]
assert not bad, f'non-official plugin enabled: {bad}'
"
  [ "$status" -eq 0 ]
}

@test "settings.json denies destructive shell commands" {
  run python3 -c "
import json
deny = json.load(open('$SETTINGS')).get('permissions', {}).get('deny', [])
need = ['Bash(rm -rf /*)', 'Bash(sudo*)', 'Bash(git push --force*)']
missing = [d for d in need if d not in deny]
assert not missing, f'missing deny rules: {missing}'
"
  [ "$status" -eq 0 ]
}

@test "settings.json wires the destructive-command guard as a Bash PreToolUse hook" {
  run python3 -c "
import json
pre = json.load(open('$SETTINGS')).get('hooks', {}).get('PreToolUse', [])
cmds = [h.get('command','') for grp in pre if grp.get('matcher')=='Bash' for h in grp.get('hooks',[])]
assert any('claude-guard-destructive' in c for c in cmds), 'guard hook not wired for Bash PreToolUse'
"
  [ "$status" -eq 0 ]
}
