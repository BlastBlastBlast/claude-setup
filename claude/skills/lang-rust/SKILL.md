---
name: lang-rust
description: Use when writing or reviewing Rust code — rustfmt + clippy clean, Result with ?, no unwrap in libs, borrow over clone, thiserror/anyhow for errors. Loads Rust conventions.
---

# Rust conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.

## Core idioms

- **`rustfmt` is non-negotiable; let the machine own layout.** Run `cargo fmt`; CI gates with
  `cargo fmt --all -- --check` (exits non-zero on any unformatted code). Defaults conform to
  the formalized Rust Style Guide — don't hand-tune formatting.
- **`clippy` clean, warnings-as-errors in CI.** Run `cargo clippy`; gate CI with
  `cargo clippy --all-targets -- -D warnings`. `correctness` lints are `deny` by default;
  `style`/`complexity`/`perf`/`suspicious` warn. `pedantic`/`nursery` are opt-in, and never
  enable `clippy::restriction` wholesale (lints there contradict each other).
- **Propagate errors with `Result<T, E>` + `?`, not panics.** Recoverable failures return
  `Result`; `?` early-returns on `Err`/`None` and converts the error via the `From` trait, so
  one function can funnel several error types into one. `panic!` is for unrecoverable bugs /
  invariant violations only (out-of-bounds, "can't happen" states).
- **No `unwrap()` / `expect()` in library code.** Each is a latent panic. Handle the
  `Result`/`Option`, return it with `?`, or convert (`ok_or`, `map_err`). Acceptable in
  tests, examples, and prototypes where a panic is the intended failure mode.
- **Borrow over clone.** Take `&T`, `&str`, `&[T]` instead of owned `String`/`Vec<T>` /
  `.clone()` when you only read. Reach for `clone()` deliberately, not to silence the borrow
  checker — restructure ownership instead.
- **Naming follows RFC 430 (C-CASE).** `UpperCamelCase` types/traits/enum-variants,
  `snake_case` modules/functions/methods, `SCREAMING_SNAKE_CASE` consts/statics. Acronyms are
  one word: `Uuid`, not `UUID`. Drop the `get_` prefix on getters (`first()`, not
  `get_first()`). The only exception is a bare `get()` with no suffix when there's a single
  obvious thing to retrieve (`Cell::get`) — never a `get_`-suffixed name.
- **Conversion-method prefixes signal cost/ownership (C-CONV).** `as_` = free borrowed→borrowed
  view, `to_` = expensive (does work; may allocate), `into_` = consuming owned→owned (non-Copy).

## Reuse & helpers

- **Implement standard traits so your types interoperate (C-COMMON-TRAITS).** Eagerly derive
  `Debug`, `Clone`, `PartialEq`/`Eq`, `Hash`, `Default`, etc. where they make sense — the
  orphan rule means downstream crates can't add them for you.
- **Conversions via `From`/`TryFrom`, never `Into`/`TryInto` (C-CONV-TRAITS).** `Into`/`TryInto`
  come free via blanket impls; implementing them directly is redundant.
- **Prefer iterators and the type system over hand-rolled loops.** Chain `map`/`filter`/
  `collect`; collections that implement `FromIterator` + `Extend` (C-COLLECT) plug straight
  into `collect()`. Express invariants in types (`Option`/`Result`/enums) so the compiler
  enforces them rather than runtime checks.
- **`std` first.** Reach for the standard library before a dependency; satisfy its existing
  traits (`Iterator`, `Display`, `From`, `std::error::Error`) instead of inventing parallels.

## Architecture

- **Newtypes for domain meaning.** Wrap primitives in a tuple struct (`struct UserId(u64);`)
  to make illegal states unrepresentable and to attach trait impls under the orphan rule. The
  wrapper is elided at compile time — zero runtime cost.
- **Error types implement `std::error::Error` + `Send` + `Sync` (C-GOOD-ERR).** Never use
  `()` as an error type; give errors a meaningful `Display`.
- **`thiserror` for library errors, `anyhow` for application errors.** In libraries, derive
  per-domain enums with `thiserror` (generates `Display`, `Error`, and `#[from]` conversions;
  it stays out of your public API). In application/binary code, return `anyhow::Result<T>` and
  add `.context("…")` at call sites — when you don't need callers to match on the variant.
- **Architecture over micro-optimization.** Keep `cargo build` / `cargo test` / `cargo clippy`
  in the loop and gate them in CI before reaching for hand-tuned cleverness.

## Anti-patterns

- **`unwrap()` / `expect()` in library code** — a latent panic. Propagate with `?` instead:

  ```rust
  // wrong — panics on a missing/invalid value the caller can't recover from
  fn load(path: &str) -> Config {
      let text = std::fs::read_to_string(path).unwrap();
      toml::from_str(&text).expect("valid config")
  }

  // right — return a Result; ? propagates and From-converts each error
  fn load(path: &str) -> Result<Config, ConfigError> {
      let text = std::fs::read_to_string(path)?;
      Ok(toml::from_str(&text)?)
  }
  ```

- **Reflexive `.clone()`** to dodge the borrow checker, where a `&T` / `&str` / `&[T]` borrow
  would do.
- **`panic!` for recoverable errors** (bad input, missing file) instead of returning `Result`.
- **`anyhow` in a library's public API** — callers lose the ability to match on error
  variants; use a `thiserror` enum there.
- **`get_`-prefixed getters**, `UPPERCASE` acronyms in type names (`UUID` → `Uuid`), or
  implementing `Into`/`TryInto` directly.
- **Hand-formatting** to fight `rustfmt`, or letting `clippy` warnings ride in CI.

## Sources

- Rust API Guidelines — Naming (C-CASE, C-CONV, C-GETTER, C-ITER): https://rust-lang.github.io/api-guidelines/naming.html
- Rust API Guidelines — Interoperability (C-COMMON-TRAITS, C-CONV-TRAITS, C-COLLECT, C-SERDE, C-GOOD-ERR): https://rust-lang.github.io/api-guidelines/interoperability.html
- The Rust Book — Error Handling (`Result` vs `panic!`, recoverable vs unrecoverable): https://doc.rust-lang.org/book/ch09-00-error-handling.html
- The Rust Book — Recoverable Errors with `Result` (the `?` operator, `From` conversion, `Box<dyn Error>`): https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html
- The Rust Book — Advanced Traits (newtype pattern, zero-cost wrapper, orphan rule): https://doc.rust-lang.org/book/ch20-02-advanced-traits.html
- Clippy (official) — lint groups, `cargo clippy -- -D warnings`: https://doc.rust-lang.org/clippy/ , https://rust-lang.github.io/rust-clippy/
- rustfmt (official) — `cargo fmt`, `--check` in CI, Rust Style Guide defaults: https://github.com/rust-lang/rustfmt
- `thiserror` (library error enums; derives `std::error::Error`, stays out of public API): https://github.com/dtolnay/thiserror
- `anyhow` (application error propagation; `anyhow::Result`, `.context()`): https://github.com/dtolnay/anyhow
- `serde` (ecosystem-standard serialization framework, `Serialize`/`Deserialize`): https://serde.rs/
- `tokio` (ecosystem-standard async runtime): https://tokio.rs/
