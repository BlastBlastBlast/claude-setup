# Sourced by every .bats file. Loads install.sh functions without running main.
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

load_install() {
  [[ -f "${REPO_ROOT}/install.sh" ]] || { echo "install.sh not found at ${REPO_ROOT}" >&2; return 1; }
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/install.sh"
}

# Create a temp git repo with one commit; echo its path. Used by wt tests.
make_temp_repo() {
  local dir="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config user.name "Test"
  git -C "$dir" config commit.gpgsign false
  echo "init" > "$dir/README.md"
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "init"
  echo "$dir"
}

load_wt() {
  [[ -f "${REPO_ROOT}/bin/wt" ]] || { echo "bin/wt not found at ${REPO_ROOT}" >&2; return 1; }
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/bin/wt"
}

load_promote_skill() {
  [[ -f "${REPO_ROOT}/bin/promote-skill" ]] || { echo "bin/promote-skill not found at ${REPO_ROOT}" >&2; return 1; }
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/bin/promote-skill"
}
