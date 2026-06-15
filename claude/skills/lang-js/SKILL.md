---
name: lang-js
description: Use when writing or reviewing JavaScript code — const by default, arrow functions, optional chaining, no globals, camelCase/UPPER_CASE. Loads JavaScript conventions.
---

# JavaScript conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.

## Core idioms

- **`const` by default; `let` only when the binding is reassigned; never `var`.** `const`
  and `let` are block-scoped with a temporal dead zone; `var` is function-scoped and hoists,
  which is the bug source. `const` is an immutable *binding*, not an immutable value — you can
  still mutate the object/array it points at, you just can't reassign the name. Reach for
  `let` only when the binding must change.
- **Arrow functions for callbacks and short expressions.** They have no own `this` — they
  capture `this` lexically from the enclosing scope, which is exactly what inline callbacks
  (array methods, promise chains, and event handlers that don't need `this`) want. Use concise
  body (`x => x * 2`) for single expressions.
- **Do not use arrow functions as methods, constructors, or generators.** Arrow functions
  have no own `this`/`arguments`, cannot be called with `new`, and cannot `yield`. Use a
  method shorthand or `function` for object methods and constructors.
- **Optional chaining (`?.`) instead of defensive `if`/`&&` chains.** `obj.first?.second`
  short-circuits to `undefined` when the left side is `null`/`undefined`, replacing
  `obj.first && obj.first.second`. The right operand is not evaluated when it short-circuits.
- **`camelCase` for variables, functions, and instances; `UPPER_SNAKE_CASE` for module-level
  constants** that are exported / known to never change.
- **Boolean flags prefixed with `is`** (`isLoading`, `isVisible`) so the name reads as a
  predicate.

## Reuse & helpers

- **Import existing module exports; don't copy a function across modules.** Use named
  `import { fn } from "./mod.js"` (or the default export) to share code — a function defined
  in a module is module-scoped and must be exported to be reused.
- **Use built-in `Array` iteration methods (`map`/`filter`/`reduce`/`find`/`some`) over
  hand-rolled index loops** for transforming and querying collections. Always `return` from
  the callback (for concise arrow bodies `x => expr` the `return` is implicit; block bodies `x => { … }` always need an explicit `return`).

## Architecture

- **Use ES modules for boundaries.** Module top-level bindings are scoped to the module and
  do not leak to the global object; modules run in strict mode automatically and execute once.
  Expose the surface explicitly via `export`; keep everything else module-private.
- **When module syntax is unavailable (classic scripts), wrap code in an IIFE** (a bare block
  only scopes `let`/`const`, not `var`) **so declarations stay local** instead of leaking onto
  `globalThis`.

## Anti-patterns

- `var` — function-scoped and hoisted; replaced by block-scoped `const`/`let`.
- Leaking top-level bindings onto the global object (classic scripts without an IIFE/module).
- Long defensive `&&`/`if` chains where `?.` fits:

  ```javascript
  // wrong — manual existence checks down the chain
  const city = user && user.address && user.address.city;

  // right — optional chaining short-circuits on null/undefined
  const city = user?.address?.city;
  ```

- Arrow functions used as object methods or constructors (wrong/absent `this`; not `new`-able).
- Reassigning a `const`-bound name (throws `TypeError`) — use `let` if it must change.

## Sources

- MDN — `const`: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/const
- MDN — `let` (block scope, TDZ vs `var`): https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/let
- MDN — Optional chaining (`?.`): https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Optional_chaining
- MDN — Arrow function expressions (lexical `this`, limitations): https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Arrow_functions
- MDN — JavaScript modules (module scope, strict mode, import/export): https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules
- Airbnb JavaScript Style Guide — 2.1 prefer `const`, 2.2 `let` over `var`, 4.7 array callback return, 8.1 arrow functions for callbacks, 23.2 camelCase, 23.8 UPPER_SNAKE_CASE constants: https://github.com/airbnb/javascript
