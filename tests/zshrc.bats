#!/usr/bin/env bats

load helper

ZSHRC="${REPO_ROOT}/shell/zshrc"

# The helper names zshrc sources, from the `for _helper in ... ; do` line.
_helper_list() {
  sed -nE 's/^for _helper in (.*); do$/\1/p' "$ZSHRC"
}

@test "zshrc is valid zsh syntax" {
  run zsh -n "$ZSHRC"
  [ "$status" -eq 0 ]
}

@test "zshrc sources no path outside the repo's own shell/ dir" {
  # A hardcoded ~/dev/claude-setup breaks any clone that lives elsewhere, and
  # silently no-ops the helper (issue #25).
  run grep -nE 'source .*(\$HOME|~)/dev/' "$ZSHRC"
  [ "$status" -ne 0 ]
}

@test "every helper zshrc sources exists in shell/" {
  helpers="$(_helper_list)"
  [ -n "$helpers" ]
  for h in $helpers; do
    [ -f "${REPO_ROOT}/shell/${h}.sh" ] || {
      echo "zshrc sources shell/${h}.sh, which is not in the repo" >&2
      return 1
    }
  done
}

@test "every helper in shell/ is sourced by zshrc" {
  helpers="$(_helper_list)"
  for f in "${REPO_ROOT}"/shell/*.sh; do
    name="$(basename "$f" .sh)"
    [[ " $helpers " == *" $name "* ]] || {
      echo "shell/${name}.sh exists but zshrc never sources it" >&2
      return 1
    }
  done
}

@test "CLAUDE_SETUP_SHELL_DIR resolves through the ~/.zshrc symlink" {
  realdir="${BATS_TEST_TMPDIR}/clone/shell"
  mkdir -p "$realdir" "${BATS_TEST_TMPDIR}/home"
  # Use the resolution line exactly as it appears in the real zshrc.
  grep -E '^CLAUDE_SETUP_SHELL_DIR=' "$ZSHRC" > "$realdir/zshrc"
  echo 'print -r -- "$CLAUDE_SETUP_SHELL_DIR"' >> "$realdir/zshrc"
  ln -s "$realdir/zshrc" "${BATS_TEST_TMPDIR}/home/.zshrc"
  # :A resolves every symlink, so compare against the fully-resolved path
  # (BATS_TEST_TMPDIR itself sits under /var -> /private/var on macOS).
  realdir="$(cd "$realdir" && pwd -P)"

  run zsh -c "source '${BATS_TEST_TMPDIR}/home/.zshrc'"
  [ "$status" -eq 0 ]
  [ "$output" = "$realdir" ]
}

@test "kubectl helper defines kc, kcns and the k alias" {
  run zsh -c "autoload -Uz compinit && compinit -u -d '${BATS_TEST_TMPDIR}/zcompdump'
              source '${REPO_ROOT}/shell/kubectl.sh'
              typeset -f kc >/dev/null && typeset -f kcns >/dev/null && alias k >/dev/null"
  [ "$status" -eq 0 ]
}

@test "wt helper defines the wt wrapper, and zshrc does not redefine it inline" {
  run zsh -c "source '${REPO_ROOT}/shell/wt.sh'; typeset -f wt >/dev/null"
  [ "$status" -eq 0 ]

  # A second, inline definition in zshrc would shadow shell/wt.sh and lose the
  # `wt rm` case it handles.
  run grep -nE '^\s*wt\(\)' "$ZSHRC"
  [ "$status" -ne 0 ]
}
