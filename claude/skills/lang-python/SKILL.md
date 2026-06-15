---
name: lang-python
description: Use when writing or reviewing Python code — type hints everywhere, X | None over Optional, TypedDict/Pydantic boundaries, parameterized SQL. Loads Python conventions.
---

# Python conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.

## Core idioms

- **Type hints on every parameter and return — no exceptions.** Annotate public surfaces
  fully; a missing return type is a defect, not a style preference.
- **Use `X | None` and `X | Y`** — the PEP 604 union operator. `None | T` / `T | None` is
  exactly `Optional[T]`, so write `int | None`, never `Optional[int]` or `Union[int, str]`.
- **Docstrings on public surfaces.** PEP 257: all modules, and all functions/classes
  exported by a module, get docstrings; public methods including `__init__` too.
- **Naming.** Leading single underscore = internal/module-private: `_flatten()`,
  `_build_row()`. PEP 8 says internal interfaces (functions, classes, attributes) should
  be prefixed `_`, and `from M import *` skips underscore names. `snake_case` for
  functions/variables, `CapWords` for classes, `UPPER_CASE` for module constants.
- **Imports.** Absolute from the app root (more readable, better errors). Explicit
  relative (`from . import sibling`) is the acceptable form *within* a package; never use
  implicit relative imports. One import per line; stdlib / third-party / local grouped.
- **Module-level logger:** `logger = logging.getLogger(__name__)` at module top. Logger
  names then track the package hierarchy. In library code, don't configure or log to the
  root logger; get a module logger with `logging.getLogger(__name__)`.

## Reuse & helpers

- **All DB work goes through the canonical context manager:**
  `with get_connection() as conn:` — never open (or close) a raw connection by hand. The
  context manager owns lifecycle and cleanup.
- **Explicit `conn.commit()` after writes.** DB-API does not autocommit; a write without a
  commit is a silent data-loss bug.

## Architecture

- **Type the boundaries.** Use `TypedDict` for complex return shapes — dictionaries with a
  fixed set of string keys and per-key value types (PEP 589; the canonical case is
  JSON-shaped data). Use a Pydantic `BaseModel` for validated *input* at trust boundaries.

## Anti-patterns

- `Optional[X]` / `Union[X, Y]` — replaced by `X | None` / `X | Y` (PEP 604).
- f-strings or string concatenation to build SQL — an injection vector. Pass values as
  parameters; let the driver bind them. Always use `%s` placeholders and a tuple of args
  (PEP 249 `format`/`pyformat` paramstyles):

  ```python
  # wrong — f-string interpolation is an injection vector
  cur.execute(f"SELECT * FROM users WHERE id = {user_id}")

  # right — %s placeholder, tuple args, driver binds the value
  cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
  ```

- Manually opened DB connections — bypass `get_connection()` and you leak/mis-scope them.
- A write path with no `conn.commit()` — changes silently vanish.
- Implicit relative imports and bare `from module import *`.
- Untyped or undocumented public functions; logging to the root logger from library code.

## Sources

- PEP 604 — Allow writing union types as `X | Y`: https://peps.python.org/pep-0604/
- PEP 589 — TypedDict: Type Hints for Dictionaries with a Fixed Set of Keys: https://peps.python.org/pep-0589/
- PEP 8 — Style Guide for Python Code (naming, imports): https://peps.python.org/pep-0008/
- PEP 257 — Docstring Conventions: https://peps.python.org/pep-0257/
- PEP 249 — Python Database API Specification v2.0 (paramstyle / parameter binding): https://peps.python.org/pep-0249/
- Python `logging` HOWTO (`getLogger(__name__)` convention): https://docs.python.org/3/howto/logging.html
- Python `typing` module reference: https://docs.python.org/3/library/typing.html
