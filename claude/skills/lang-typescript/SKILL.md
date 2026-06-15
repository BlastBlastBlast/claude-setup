---
name: lang-typescript
description: Use when writing or reviewing TypeScript code — strict tsconfig, no any, prefer unknown, discriminated unions, type-only imports, validate inputs at boundaries. Loads TypeScript conventions.
---

# TypeScript conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.
> Complements `lang-js` (general JS idioms — `const`, arrow functions, ES modules); this skill
> covers the **type system**, so don't restate JS runtime idioms here.

## Core idioms

- **Compile under `strict: true` — non-negotiable.** The `strict` family is a single master
  switch that turns on `noImplicitAny`, `strictNullChecks`, `strictFunctionTypes`,
  `strictPropertyInitialization`, `useUnknownInCatchVariables`, and more. It's "equivalent to
  enabling all of the strict mode family options" and gives "stronger guarantees of program
  correctness." Treat a type error as a build failure, not a suggestion.
- **Add `noUncheckedIndexedAccess`.** Indexed/array access then yields `T | undefined` instead
  of `T`, forcing you to handle the missing-key/out-of-bounds case the type system otherwise
  hides. Prefer `exactOptionalPropertyTypes` too, so `prop?: X` means "absent or `X`," never
  "present and `undefined`."
- **Ban `any`; reach for `unknown` and narrow.** `any` "disables all further type checking"
  on that value, and it's contagious — every expression derived from it becomes `any` too, so
  a single `any` quietly erodes safety well beyond one line. `unknown` is the safe top type:
  like `any` it holds any value, but it forbids property access and calls until you narrow it
  (via `typeof`, `instanceof`, an `in` check, or a validator). typescript-eslint's
  `no-explicit-any` (in `recommended`) enforces this.
- **Discriminated unions over loose object shapes.** Give each variant a shared literal tag
  (`type: "ok" | "err"`) so a `switch` on the tag narrows the payload exhaustively; add a
  `never` default branch to make missing cases a compile error. Prefer a union of string
  literals to a runtime `enum` where the values are just a closed set of tags.
- **Lowercase primitives — `string`/`number`/`boolean`/`symbol`/`object`**, never the boxed
  `String`/`Number`/`Boolean`/`Object` wrapper types (the official Do's and Don'ts). Use
  `unknown` rather than `object` or `{}` for "any value."
- **`import type` for type-only imports** (typescript-eslint `consistent-type-imports`). The
  `type` keyword signals the import exists only in the type system, so transpilers can drop it
  "without knowing the types of the dependencies" — required for safe single-file transpilation
  under `isolatedModules`.

## Reuse & helpers

- **Derive types; don't hand-maintain duplicates.** Build new shapes from existing ones with
  built-in utility types — `Partial`, `Required`, `Readonly`, `Pick`, `Omit`, `Record`,
  `ReturnType`, `Parameters` — so a change to the source type propagates. A single source of
  truth beats two declarations that drift.
- **Let inference do the work.** Don't annotate a local whose initializer already fixes its
  type. Annotate the *boundaries* — exported function parameters and return types, public
  surfaces — and let the body infer.
- **Generics with constraints, not `any`, for reusable code.** A `<T>` (optionally
  `<T extends ...>`) preserves the caller's type through the call; `any` throws it away. Prefer
  a single signature with union/optional params over near-duplicate overloads.

## Architecture

- **`tsc --noEmit` in CI is the type gate** (with `strict: true` set in `tsconfig.json`, not
  as a CLI flag); pair it with **typescript-eslint**.
  Use the type-checked configs (`recommended-type-checked` / `strict-type-checked`) for rules
  that need type info — e.g. `no-floating-promises`, which flags a Promise created "without any
  code set up to handle any errors it might throw" (handle it with `await`, `.catch`, `return`,
  or an explicit `void`).
- **Choose `interface` vs `type` deliberately.** `interface` for object/class shapes that may
  be extended or `implements`-ed (it also supports declaration merging); `type` for unions,
  tuples, mapped/conditional types, and aliases interfaces can't express. Be consistent within
  a module.
- **Validate external/untyped input at trust boundaries — don't cast.** Network responses,
  `JSON.parse`, env vars, and form data arrive as `unknown`; a `value as Shape` cast is an
  unchecked lie. Parse with a schema validator (**zod** — TypeScript-first, zero-dependency,
  ~2kb) so one schema yields both the runtime check and the static type via `z.infer`. Use
  `safeParse` at boundaries where bad input is expected and you want a result, not a throw.

## Anti-patterns

- **`as` casts and `any` to silence the compiler** — they relocate the bug to runtime. Parse
  and narrow instead:

  ```typescript
  // wrong — cast asserts a shape the value may not have; no runtime check
  const user = JSON.parse(body) as User;
  console.log(user.email.toLowerCase()); // throws at runtime if email is missing

  // right — validate at the boundary; type is inferred from the schema
  const UserSchema = z.object({ email: z.string().email() });
  type User = z.infer<typeof UserSchema>;        // single source of truth: schema → type
  const user = UserSchema.parse(JSON.parse(body)); // type User, or throws on bad input
  ```

- Explicit `any` (use `unknown` + narrowing); `@ts-ignore`/`@ts-expect-error` to bury an error.
- Boxed wrapper types `String`/`Number`/`Boolean`/`Object` instead of lowercase primitives.
- Non-null assertions (`x!`) sprinkled to defeat `strictNullChecks` instead of narrowing.
- Stacks of overloads that differ only in trailing params or one arg's type — use optional
  params / union types.
- A floating Promise (unawaited, unhandled) — swallows rejections and races operations.
- Plain `import` for a type-only symbol; `enum` where a union of string literals fits better.

## Sources

- TypeScript `tsconfig` reference — `strict` and the strict-mode family, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`: https://www.typescriptlang.org/tsconfig/#strict
- TypeScript Handbook — Everyday Types / Narrowing (`unknown`, discriminated unions, `never` exhaustiveness): https://www.typescriptlang.org/docs/handbook/2/everyday-types.html , https://www.typescriptlang.org/docs/handbook/2/narrowing.html
- TypeScript Handbook — Do's and Don'ts (lowercase primitives, avoid `any`/use `unknown`, overloads → optional/union params): https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html
- typescript-eslint — `no-explicit-any` (`unknown` over `any`; in `recommended`): https://typescript-eslint.io/rules/no-explicit-any/
- typescript-eslint — `consistent-type-imports` / `import type` and `isolatedModules`: https://typescript-eslint.io/rules/consistent-type-imports/
- typescript-eslint — `no-floating-promises` (type-checked configs): https://typescript-eslint.io/rules/no-floating-promises/
- TypeScript Handbook — Utility Types (`Partial`/`Pick`/`Omit`/`Record`/`ReturnType`): https://www.typescriptlang.org/docs/handbook/utility-types.html
- Zod — TypeScript-first runtime validation, `parse`/`safeParse`, `z.infer`: https://zod.dev/
