#!/usr/bin/env bats

@test "bats harness runs" {
  result="$((1 + 1))"
  [ "$result" -eq 2 ]
}
