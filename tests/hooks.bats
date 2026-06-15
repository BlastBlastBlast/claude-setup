#!/usr/bin/env bats

load helper

@test "pre-commit hook blocks a staged secret" {
  command -v gitleaks >/dev/null || skip "gitleaks not installed"
  repo="${BATS_TEST_TMPDIR}/hookrepo"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email t@e.x
  git -C "$repo" config user.name t
  git -C "$repo" config commit.gpgsign false
  git -C "$repo" config core.hooksPath "${REPO_ROOT}/hooks"
  # GitHub classic PAT format reliably detected by gitleaks (AWS example keys are allowlisted).
  printf 'GITHUB_TOKEN=ghp_A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8\n' > "$repo/leak.txt" # gitleaks:allow
  git -C "$repo" add -A
  run git -C "$repo" commit -m "should be blocked"
  [ "$status" -ne 0 ]
}

@test "pre-commit hook allows a clean commit" {
  command -v gitleaks >/dev/null || skip "gitleaks not installed"
  repo="${BATS_TEST_TMPDIR}/cleanrepo"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email t@e.x
  git -C "$repo" config user.name t
  git -C "$repo" config commit.gpgsign false
  git -C "$repo" config core.hooksPath "${REPO_ROOT}/hooks"
  echo "hello world" > "$repo/ok.txt"
  git -C "$repo" add -A
  run git -C "$repo" commit -m "clean"
  [ "$status" -eq 0 ]
}
