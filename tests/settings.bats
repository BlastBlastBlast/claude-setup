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

@test "settings.json enables exactly the recommended official plugin shortlist" {
  run python3 -c "
import json
ep = json.load(open('$SETTINGS')).get('enabledPlugins', {})
expected = {
  'superpowers@claude-plugins-official',
  'feature-dev@claude-plugins-official',
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
