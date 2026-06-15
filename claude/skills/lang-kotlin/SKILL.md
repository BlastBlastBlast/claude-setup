---
name: lang-kotlin
description: Use when writing or reviewing Kotlin code — null-safety over !!, val over var, immutable defaults, expression idioms, coroutines for async. Loads Kotlin conventions.
---

# Kotlin conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.

## Core idioms

- **`val` over `var` — immutable by default.** Declare locals and properties `val` unless
  they're reassigned after init. Prefer read-only collection interfaces (`List`, `Set`,
  `Map`) and the immutable builders (`listOf`, `setOf`, `mapOf`) over their mutable
  counterparts (`MutableList`, `arrayListOf`, `HashSet`) when the value isn't mutated.
- **Lean on null-safety; NEVER use `!!`.** `!!` is "one of the only possible causes of an
  NPE in Kotlin" — it converts a `T?` to `T` and throws at runtime if it was null. Reach
  for the safe call `?.`, the Elvis operator `?:` (with `return`/`throw` for early exit:
  `val name = node.name ?: return null`), `as?` for safe casts, `x?.let { … }` to run on
  non-null, and `requireNotNull`/`checkNotNull` when a null genuinely is a precondition
  failure (they throw a *meaningful* message and smart-cast the result to non-null).
- **Prefer expression bodies and expression forms.** Single-expression functions: `fun
  area() = w * h`, not a `{ return … }` block. Use the expression form of `if`, `when`, and
  `try` (`return if (x) foo() else bar()`). Use `if` for a binary choice; `when` for three
  or more branches.
- **Model data with `data class`; model closed alternatives with `sealed`.** `data class`
  gives you `equals`/`hashCode`/`toString`/`copy` for value-shaped types. A `sealed` class
  or interface caps a hierarchy so `when` over it is exhaustive with no `else` — the
  compiler flags a new case you forgot to handle. Idiomatic for result/error and state types.
- **Use scope functions deliberately, not reflexively.** `let` (run on non-null, transform
  via `it`), `apply` (configure, returns receiver), `also` (side effect via `it`), `run`
  (configure + compute), `with` (group calls). They add *no* capability — only readability.
  The docs say to avoid overusing them and to avoid nesting/over-chaining: it's easy to lose
  track of what `this`/`it` refers to.
- **Coroutines + structured concurrency for async.** `suspend` functions, launched with the
  `launch` / `async`(+`await`) builders inside a `CoroutineScope` (create one with the
  suspending `coroutineScope { … }`). Children
  form a tree under the parent; the parent waits for them, and a parent failure/cancellation
  recursively cancels children — no leaked work.
- **Naming.** `UpperCamelCase` for classes/objects; `lowerCamelCase` (no underscores) for
  functions, properties, locals; `SCREAMING_SNAKE_CASE` for `const`/top-level `val`
  constants; lowercase, no-underscore packages. Backing property prefixed `_`
  (`private val _items`; public `val items: List<T> get() = _items`). Acronyms: two-letter
  acronyms both caps (`IO` → `IOStream`), longer ones capitalize first only
  (`Xml` → `XmlFormatter`, `Http` → `HttpClient`).
- **Strings & lambdas.** Templates (`"$name: ${items.size}"`) over concatenation;
  `trimIndent()`/`trimMargin()` over `\n`. Single non-nested lambda uses `it`; name the
  parameter for nested lambdas. Use named arguments for repeated same-type / `Boolean` args.

## Reuse & helpers

- **Stdlib + extension functions first.** Before adding a type or a free helper, look for an
  existing stdlib collection operator (`map`/`filter`/`associate`/`groupBy`/`filterNotNull`)
  or extension function and use/extend it. Prefer higher-order functions over manual loops
  (exception: a plain `for` over `forEach` unless the receiver is nullable or it's part of a
  longer chain). Add an extension function to enrich a type you don't own instead of wrapping it.
- **`typealias` for repeated complex types.** A functional type or parameterized type used
  across the codebase gets a named alias: `typealias ClickHandler = (View, Event) -> Unit`.

## Architecture

- **Let tooling own formatting and quality — it's an idiom, not optional.** Run **ktlint**
  (anti-bikeshedding linter with a built-in formatter, `ktlint -F` / `--format`) and/or
  **detekt** (static analysis for code smells and complexity) in the editor and in CI;
  treat compiler warnings as errors in the build. Don't hand-tune layout. Use the Gradle
  Kotlin DSL (`build.gradle.kts`) for type-checked, IDE-completable build scripts.
- **Class member order is logical, not alphabetical:** properties + initializers, secondary
  constructors, methods, then `companion object` — related code together so a top-to-bottom
  read follows the logic.
- **File naming.** One public class → file named for it (`Person.kt`); several top-level
  declarations → a descriptive `UpperCamelCase` name. Avoid meaningless names like `Util`.
- **Library/public-API surfaces are explicit.** State member visibility explicitly (turn on
  the compiler's *explicit API mode* so nothing leaks public by accident), declare return
  and property types explicitly rather than relying on inference, and KDoc every public
  member. Endorsed JetBrains libraries: `kotlinx.coroutines` for async, `kotlinx.serialization`
  for (de)serialization.

## Anti-patterns

- **`!!` to silence the nullable type** — re-introduces the NPE that Kotlin's type system
  exists to prevent. Express the intent instead:

  ```kotlin
  // wrong — throws a bare NPE at runtime if header is absent
  val token = request.header("Authorization")!!.removePrefix("Bearer ")

  // right — Elvis for a real fallback / early exit (or requireNotNull for a precondition)
  val token = request.header("Authorization")?.removePrefix("Bearer ")
      ?: return Unauthorized
  ```

- **`var` (or mutable collections) where a `val` / read-only interface would do.**
- **Block bodies for one-liners** (`fun f(): Int { return 1 }`) — use `fun f() = 1`.
- **`if`/`when` as statements** assigning into a `var` instead of the expression form.
- **A `when` over a sealed type with a catch-all `else`** — it defeats exhaustiveness, so the
  compiler stops warning you when a new subtype is added.
- **Reflexive / nested / over-chained scope functions** that obscure what `this`/`it` is.
- **Inferred return types and implicit public visibility on a library's public API**; missing
  KDoc on public members.

## Sources

- Kotlin Coding Conventions (val over var, immutable interfaces, naming, expression bodies, `if`/`when`, scope-function choice, member/file layout, strings, lambdas, type aliases, library visibility/return-type/KDoc rules): https://kotlinlang.org/docs/coding-conventions.html
- Kotlin Null safety (`?.`, `?:`, `!!` as the cause of NPEs, `as?`, `let`, `requireNotNull`/`checkNotNull`): https://kotlinlang.org/docs/null-safety.html
- Kotlin Scope functions (`let`/`run`/`with`/`apply`/`also` purpose; avoid overuse/nesting): https://kotlinlang.org/docs/scope-functions.html
- Kotlin Coroutines basics (structured concurrency, `suspend`, `coroutineScope`, `launch`/`async`, cancellation propagation): https://kotlinlang.org/docs/coroutines-basics.html
- Kotlin Sealed classes and interfaces (exhaustive `when`, no `else`): https://kotlinlang.org/docs/sealed-classes.html
- Library authors' guidelines — Simplicity / explicit API mode (explicit visibility + explicit public types): https://kotlinlang.org/docs/api-guidelines-simplicity.html
- ktlint — anti-bikeshedding Kotlin linter with built-in formatter (`ktlint -F`): https://github.com/pinterest/ktlint
- detekt — static code analysis for Kotlin (code smells, complexity; Gradle/CLI/CI): https://detekt.dev/
- kotlinx.coroutines (JetBrains-maintained async library): https://github.com/Kotlin/kotlinx.coroutines
- kotlinx.serialization (JetBrains-maintained serialization library): https://github.com/Kotlin/kotlinx.serialization
