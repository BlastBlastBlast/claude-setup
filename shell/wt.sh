# Optional wt shell integration — source from your ~/.zshrc or ~/.bashrc:
#     source /path/to/claude-setup/shell/wt.sh
# Makes `wt here [name]` cd the current shell into the new worktree automatically,
# instead of needing `cd "$(wt here)"`. All other subcommands pass through.
wt() {
  if [ "${1:-}" = "here" ]; then
    local _wt_dir
    _wt_dir="$(command wt "$@")" || return $?
    [ -n "$_wt_dir" ] && builtin cd "$_wt_dir"
  else
    command wt "$@"
  fi
}
