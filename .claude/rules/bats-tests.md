---
paths:
  - "tests/**"
---

# Bats conventions for this repo

- Every executable surface change (install.sh, bin/*, hooks/*) lands with bats coverage in
  the same commit; guard changes are test-first.
- Load `helper` and use `$REPO_ROOT`; derive destinations from `$HOME` so tests can override
  it (see install.bats).
- Guard tests go through the `_guard` helper in hooks.bats — it builds the hook JSON via an
  env var so test strings need no escaping. Blocked = exit 2, allowed = exit 0.
- When a test needs strings the guard itself would block (curl-pipe examples, attribution
  markers), keep them inside the `_guard` argument — never in a raw shell command.
- `skip` (with a reason) when an optional dependency is absent (`gitleaks`, `claude`), so the
  suite stays green on minimal machines.
