---
name: lang-go
description: Use when writing or reviewing Go code — gofmt-formatted, explicit error handling, small interfaces, stdlib-first, accept interfaces/return structs. Loads Go conventions.
---

# Go conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.

## Core idioms

- **`gofmt` is non-negotiable.** Let the machine own formatting: run `gofmt` (or `go fmt`,
  which works at package level). Standard-library code is all `gofmt`-formatted. Don't hand-
  tune layout — if a new situation looks wrong after `gofmt`, rearrange the program, don't
  work around the formatter.
- **Handle every `error` explicitly.** A function returning an `error` must have it checked:
  handle it, return it, or — only in truly exceptional cases — `panic`. Never discard with
  `_`. In the rare case you must ignore one, add a comment explaining why it's safe.
- **Wrap errors with `%w` to preserve the chain.** `fmt.Errorf("decompress %s: %w", name, err)`
  adds context while keeping the original inspectable via `errors.Is` / `errors.As`. Use `%v`
  when the wrapped error is an implementation detail you don't want to expose as a stable
  API — `%w` adds an `Unwrap` chain that becomes part of your public contract.
- **Error strings are lowercase, no trailing punctuation** (unless they begin with a proper
  noun or acronym) — they're printed mid-sentence after surrounding context.
- **Keep the happy path at minimal indentation.** Handle the error first and `return`; omit
  the `else` after a branch that ends in `return`/`break`/`continue`.
- **Define small interfaces at the consumer.** Interfaces belong in the package that *uses*
  the value, not the one that implements it. One- or two-method interfaces are the norm;
  name single-method ones with the `-er` suffix (`Reader`, `Writer`). Don't define an
  interface before there's a real use, and don't add interfaces "for mocking."
- **Accept interfaces, return concrete types.** Implementing packages return concrete
  (pointer or struct) types so new methods can be added without refactoring callers.
- **Make the zero value useful.** Design types so the zeroed value works without
  initialization — `bytes.Buffer`'s zero value is an empty buffer ready to use; a zero
  `sync.Mutex` is an unlocked mutex. No constructor needed.
- **`context.Context` is the first parameter.** `func F(ctx context.Context, /* … */)`.
  Pass it through for cancellation/deadlines; never store a `Context` in a struct — thread
  it as a parameter on each method that needs it.
- **Naming.** `MixedCaps` / `mixedCaps`, never underscores. The first character's case sets
  export visibility. Getters drop the `Get` prefix: field `owner` → method `Owner()`.
  Local variable names are short (`i`, `c`); the further a name is used from its
  declaration, the more descriptive it should be.
- **`any`, not `interface{}`** in new code (Go 1.18+ alias).

## Reuse & helpers

- **Stdlib first.** Go's standard library is the default toolbox — reach for it before
  adding a dependency. Find the existing `-er` interface or helper and satisfy/extend it
  rather than inventing a parallel abstraction.
- **Satisfy existing interfaces implicitly.** Implement `io.Writer`, `fmt.Stringer`,
  `error`, etc. so your types plug into stdlib and existing code; no `implements` keyword
  needed — the method set is the contract.

## Architecture

- **Package per purpose, named for what it provides.** Short, lowercase, single-word, no
  underscores or `mixedCaps`. Omit the package name from its identifiers (`http.Server`,
  not `http.HTTPServer`; `time.Now()` returns `time.Time`). Avoid grab-bag names like
  `util`, `common`, `misc`, `api`, `types` — they accumulate unrelated code.
- **Doc comments on all exported names**, plus non-trivial unexported decls. Full sentences
  beginning with the name and ending in a period (`// Encode writes the JSON encoding…`).
  The package comment sits adjacent to the `package` clause with no blank line.
- **Architecture over micro-optimization.** Lean on the toolchain to keep quality high:
  `go vet` for suspicious constructs, `go build` / `go test` in the loop, and
  `golangci-lint run` — the de-facto aggregate runner that runs 100+ linters in parallel —
  in CI. Wire these into the build before reaching for hand-tuned cleverness.

## Anti-patterns

- **Discarding errors with `_`** — silent failure. `fi, _ := os.Stat(path)` then
  `fi.IsDir()` panics when the path is missing:

  ```go
  // wrong — error dropped; nil-deref panic when path doesn't exist
  fi, _ := os.Stat(path)
  if fi.IsDir() { … }

  // right — check, then use
  fi, err := os.Stat(path)
  if err != nil {
      return err
  }
  if fi.IsDir() { … }
  ```

- **Capitalized / punctuated error strings** (`fmt.Errorf("Something bad.")`) — break
  mid-sentence log formatting.
- **`interface{}`** in new code — write `any`.
- **Interfaces defined on the implementor side** "for mocking," or before any caller exists.
- **Returning an interface from a constructor** when a concrete struct would do — it blocks
  adding methods later.
- **Storing a `context.Context` in a struct field** instead of passing it as a parameter.
- **Getters prefixed `Get`** (`GetOwner()`); generic package names (`util`, `common`).
- **Hand-formatting** to fight `gofmt`, or skipping doc comments on exported names.

## Sources

- Effective Go (formatting, error handling, interfaces, naming, zero value, getters, packages): https://go.dev/doc/effective_go
- Go Code Review Comments (handle errors, error strings, indent error flow, interfaces at consumer, contexts, package names, doc comments): https://go.dev/wiki/CodeReviewComments
- Google Go Style Guide — Decisions (error handling choices, `any` over `interface{}`, error strings): https://google.github.io/styleguide/go/decisions
- Go blog — Working with Errors in Go 1.13 (`%w` wrapping, `errors.Is`/`errors.As`): https://go.dev/blog/go1.13-errors
- Go blog — Package names (short lowercase single-word names; avoid `util`/`common`): https://go.dev/blog/package-names
- `go vet` / `gofmt` (official tooling): https://pkg.go.dev/cmd/vet , https://pkg.go.dev/cmd/gofmt
- golangci-lint — fast Go linters runner (`golangci-lint run`): https://golangci-lint.run/
