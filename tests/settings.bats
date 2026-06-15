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
