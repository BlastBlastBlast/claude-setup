#!/usr/bin/env bats

load helper

setup() { load_wt; }

@test "wt help prints usage" {
  run main help
  [ "$status" -eq 0 ]
  [[ "$output" == *"wt new [name]"* ]]
}

@test "wt with unknown command errors and prints usage" {
  run main bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown command"* ]]
}

@test "wt new creates a worktree, branch, and gitignores .worktrees" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH

  run main new feature/foo

  [ "$status" -eq 0 ]
  [ -d "$repo/.worktrees/feature-foo" ]
  git -C "$repo" show-ref --verify --quiet refs/heads/feature/foo
  grep -qxF ".worktrees/" "$repo/.gitignore"
  [[ "$output" == *"cd "* ]]
}

@test "wt new does not duplicate the .gitignore entry on a second worktree" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  main new feature/foo
  main new feature/bar
  run grep -cxF ".worktrees/" "$repo/.gitignore"
  [ "$output" -eq 1 ]
}

@test "wt ls lists worktrees including a created one" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  main new feature/foo
  run main ls
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-foo"* ]]
}

@test "wt rm removes the worktree and deletes the branch" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  main new feature/foo
  run main rm feature/foo
  [ "$status" -eq 0 ]
  [ ! -d "$repo/.worktrees/feature-foo" ]
  run git -C "$repo" show-ref --verify --quiet refs/heads/feature/foo
  [ "$status" -ne 0 ]
}

@test "wt rm removes a worktree whose branch was renamed after creation" {
  # `wt` itself recommends `git branch -m` to rename; after a rename the dir name
  # (.worktrees/feature-foo) no longer matches the branch (feature/bar), so rm must
  # resolve the real path from git, not reconstruct it from the branch name.
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  main new feature/foo
  git -C "$repo" branch -m feature/foo feature/bar
  run main rm feature/bar
  [ "$status" -eq 0 ]
  [ ! -d "$repo/.worktrees/feature-foo" ]
  run git -C "$repo" show-ref --verify --quiet refs/heads/feature/bar
  [ "$status" -ne 0 ]
}

@test "wt here creates an isolated worktree on an auto-named branch and prints its path" {
  repo="$(make_temp_repo)"; cd "$repo"
  unset CMUX_SOCKET_PATH
  path="$(main here 2>/dev/null)"
  [ -n "$path" ]
  [ -d "$path" ]
  [ -d "$repo/.worktrees" ]
  grep -qxF ".worktrees/" "$repo/.gitignore"
  # auto branch is wt/scratch-*
  git -C "$repo" branch --list 'wt/scratch-*' | grep -q 'wt/scratch-'
}

@test "wt here <name> creates a worktree on that branch and prints only the path on stdout" {
  repo="$(make_temp_repo)"; cd "$repo"
  unset CMUX_SOCKET_PATH
  path="$(main here docs 2>/dev/null)"
  # stdout is ONLY the path (so `cd "$(wt here)"` works). Compare against the
  # git-canonicalized root, since on macOS $repo is a /var symlink to /private/var.
  [ "$path" = "$(git -C "$repo" rev-parse --show-toplevel)/.worktrees/docs" ]
  [ -d "$path" ]
  git -C "$repo" show-ref --verify --quiet refs/heads/docs
}

@test "wt here bases the new branch off main even when HEAD is elsewhere" {
  repo="$(make_temp_repo)"; cd "$repo"
  unset CMUX_SOCKET_PATH
  # diverge: make a second branch with an extra commit, check it out
  git -C "$repo" checkout -q -b other
  echo more > "$repo/extra.txt"; git -C "$repo" add -A; git -C "$repo" commit -q -m extra
  main here fromMain >/dev/null 2>&1
  # fromMain's HEAD must equal main's HEAD (based off main, not 'other')
  [ "$(git -C "$repo" rev-parse main)" = "$(git -C "$repo" rev-parse fromMain)" ]
}

@test "wt new with no name creates an auto-named worktree" {
  repo="$(make_temp_repo)"; cd "$repo"
  unset CMUX_SOCKET_PATH
  run main new
  [ "$status" -eq 0 ]
  git -C "$repo" branch --list 'wt/scratch-*' | grep -q 'wt/scratch-'
}

@test "wt help lists the here command" {
  run main help
  [ "$status" -eq 0 ]
  [[ "$output" == *"wt here"* ]]
}

@test "wt here reuses an existing branch without error" {
  repo="$(make_temp_repo)"; cd "$repo"
  unset CMUX_SOCKET_PATH
  git -C "$repo" branch existing-branch
  path="$(main here existing-branch 2>/dev/null)"
  [ -n "$path" ]
  [ -d "$path" ]
  git -C "$repo" show-ref --verify --quiet refs/heads/existing-branch
}

@test "_workspace_label is '<icon> <repo-basename>/<branch>'" {
  run _workspace_label "/Users/me/dev/trusthere" "feature/maptiler"
  [ "$status" -eq 0 ]
  # Suffix is "<repo>/<branch>"; an icon prefix precedes it (asserted without
  # embedding the glyph here, so the test doesn't depend on its encoding).
  [[ "$output" == *"trusthere/feature/maptiler" ]]
  [ "$output" != "trusthere/feature/maptiler" ]
}

@test "wt new reports adding .worktrees to .gitignore" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  run main new feature/foo
  [ "$status" -eq 0 ]
  [[ "$output" == *"added '.worktrees/' to .gitignore"* ]]
}

@test "wt new links a gitignored .env into the worktree as a symlink" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  printf '.env\n' > "$repo/.gitignore"
  printf 'EXAMPLE_VAR=1\n' > "$repo/.env"
  run main new feature/foo
  [ "$status" -eq 0 ]
  [ -L "$repo/.worktrees/feature-foo/.env" ]
  [ "$(readlink "$repo/.worktrees/feature-foo/.env")" = "../../.env" ]
  [[ "$output" == *"linked .env"* ]]
}

@test "wt new warns and does not link a .env that is not gitignored" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  printf 'EXAMPLE_VAR=1\n' > "$repo/.env"
  run main new feature/foo
  [ "$status" -eq 0 ]
  [ ! -e "$repo/.worktrees/feature-foo/.env" ]
  [[ "$output" == *"not gitignored"* ]]
}

@test "wt new honors WT_LINK_FILES to link extra gitignored files" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  printf '.env\nmyconf\n' > "$repo/.gitignore"
  printf 'EXAMPLE_VAR=1\n' > "$repo/.env"
  printf 'k=v\n' > "$repo/myconf"
  WT_LINK_FILES=".env myconf" run main new feature/foo
  [ "$status" -eq 0 ]
  [ -L "$repo/.worktrees/feature-foo/.env" ]
  [ -L "$repo/.worktrees/feature-foo/myconf" ]
}

@test "wt new skips WT_LINK_FILES entries that contain a slash" {
  repo="$(make_temp_repo)"
  cd "$repo"
  unset CMUX_SOCKET_PATH
  mkdir -p "$repo/sub"; printf 'x=1\n' > "$repo/sub/file"
  WT_LINK_FILES="sub/file" run main new feature/foo
  [ "$status" -eq 0 ]
  [ ! -e "$repo/.worktrees/feature-foo/sub/file" ]
  [[ "$output" == *"only repo-root files are linked"* ]]
}
