# Optional wt shell integration — source from your ~/.zshrc or ~/.bashrc:
#     source /path/to/claude-setup/shell/wt.sh
# Makes `wt here [name]` cd the current shell into the new worktree, and `wt rm`
# cd the shell back to the main checkout when you remove the worktree you're in
# (otherwise the shell's CWD would be left dangling). Both rely on the same
# contract: `bin/wt` prints a cd target on stdout, and this wrapper does the cd.
# All other subcommands pass through unchanged.
wt() {
  case "${1:-}" in
    here|rm)
      local _wt_dir
      _wt_dir="$(command wt "$@")" || return $?
      [ -n "$_wt_dir" ] && builtin cd "$_wt_dir"
      ;;
    *)
      command wt "$@"
      ;;
  esac
}
