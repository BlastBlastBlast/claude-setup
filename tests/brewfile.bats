#!/usr/bin/env bats

load helper

BREWFILE="${REPO_ROOT}/Brewfile"

@test "Brewfile declares the crit review tool" {
  run grep -E '^brew "crit"' "$BREWFILE"
  [ "$status" -eq 0 ]
}
