---
name: lang-java
description: Use when writing or reviewing Java code — favor immutability, records for data, Optional over null, program to interfaces, prefer composition, static factories. Loads Java conventions.
---

# Java conventions

> Repo-local conventions (`AGENTS.md` / `CLAUDE.md` / `.claude`) take precedence over this skill.

## Core idioms

- **Minimize mutability.** Make value classes immutable: declare fields `private final`, expose
  no mutators, and make the class `final` (or use a private constructor + static factory) so it
  can't be subclassed into mutability. Immutable objects are inherently thread-safe and freely
  shareable (Effective Java Item 17).
- **Use `record` for transparent data carriers.** A `record Point(int x, int y) {}` generates the
  `private final` fields, canonical constructor, accessors, and `equals`/`hashCode`/`toString` for
  you; the class is implicitly `final` and the data immutable. Reach for records instead of
  hand-writing data-holder classes; add compact-constructor validation when needed.
- **Return `Optional<T>` for a possibly-absent *return value* — never for fields or parameters.**
  `Optional` exists to force callers to confront a "no result" outcome that `null` lets them ignore;
  use it judiciously as a return type (Effective Java Item 55). Don't store it in a field, accept it
  as a parameter, or wrap collections (return an empty collection instead). It is a value-based
  class — never compare with `==`.
- **Program to interfaces.** Declare variables and parameters by the interface, instantiate the
  implementation: `List<String> names = new ArrayList<>();`, `Map<K,V> m = new HashMap<>();`. This
  lets you swap implementations without touching callers (Effective Java Item 64; prefer interfaces
  to abstract classes, Item 20).
- **Static factory methods over constructors** where a name clarifies intent or instances can be
  cached/reused: `of`, `valueOf`, `from`, `getInstance` (Effective Java Item 1). Unlike
  constructors, they have descriptive names and aren't required to return a fresh object each call.
- **Override `equals` and `hashCode` together.** Overriding one without the other breaks hash-based
  collections; obey the `equals` general contract (reflexive, symmetric, transitive, consistent) and
  always override `hashCode` when you override `equals` (Effective Java Items 10, 11). Records do this
  for you.
- **`try`-with-resources for every `AutoCloseable`.** `try (var in = Files.newInputStream(p)) { … }`
  closes resources correctly even on exception — the try block's exception propagates as primary,
  and any exception from `close()` is attached as suppressed (`Throwable.getSuppressed()`) rather
  than overwriting it as `try`/`finally` would — preferred over `try`/`finally` (Effective Java Item 9).
- **Annotate `@Override` whenever it is legal** — the compiler then catches signature mistakes
  (Google Java Style §6.1).
- **Naming.** Classes `UpperCamelCase` (nouns); methods/fields `lowerCamelCase` (methods are verbs);
  constants (`static final`, deeply immutable) `UPPER_SNAKE_CASE`; packages all-lowercase letters and
  digits, no underscores (Google Java Style §5).

## Reuse & helpers

- **Reach into `java.util` first.** The Collections Framework (`List`, `Map`, `Set`, `Deque`),
  `Optional`, `Comparator`, and `Stream` cover most needs — find the existing type before inventing
  one. Use the standard `java.time` for dates/times and `java.nio.file` (`Path`, `Files`) for I/O.
- **Implement standard interfaces** (`Comparable`, `Iterable`, `AutoCloseable`, `Comparator`) so your
  types plug into existing library code and the for-each / try-with-resources machinery.
- **Prefer enums to `int`/`String` constants** for fixed sets of values — type-safe, namespaced, and
  usable in `switch` (Effective Java Item 34).

## Architecture

- **Favor composition over inheritance.** Hold a collaborator as a field and delegate, rather than
  extending a class to reuse it — inheritance across package boundaries is fragile and breaks
  encapsulation (Effective Java Item 18). Use inheritance only for genuine "is-a" relationships you
  control.
- **Model closed hierarchies with `sealed` types.** A `sealed interface Shape permits Circle, Square`
  restricts which classes may implement it, so the compiler knows the full set — pairs naturally with
  records and exhaustive `switch` (JEP 409).
- **Formatting is a machine job.** Run `google-java-format` (or wire it through the Spotless
  Gradle/Maven plugin) so layout matches the Google Java Style Guide and never appears in review.
  Imports are explicit — no wildcard (`*`) imports (Google Java Style §3.3.1).
- **Lint as part of the build.** Run Error Prone as a compiler plug-in to catch common bug patterns
  at compile time, and Checkstyle to enforce remaining style rules — wire both into Gradle/Maven CI
  rather than relying on review.

## Anti-patterns

- **Returning `null` for "no result," or `Optional` in the wrong place.** `null` returns invite
  `NullPointerException`; `Optional` in fields/parameters/collections is misuse:

  ```java
  // wrong — null return; caller forgets the check and NPEs
  User find(String id) { return cache.get(id); }      // may be null
  void greet(Optional<String> name) { … }             // Optional parameter

  // right — Optional return forces the caller to handle absence
  Optional<User> find(String id) { return Optional.ofNullable(cache.get(id)); }
  void greet(String name) { … }                        // plain parameter
  ```

- **Mutable "data classes"** with public setters where a `record` (or an immutable class) belongs.
- **Coding to concrete types** — `ArrayList<String> x = new ArrayList<>();` instead of `List<String>`.
- **Overriding `equals` without `hashCode`** (or vice versa) — silently breaks `HashMap`/`HashSet`.
- **Comparing `Optional` (or other value-based types) with `==`** instead of `.isPresent()`/`.equals`.
- **`try`/`finally` to close resources** where `try`-with-resources is correct and exception-safe.
- **Wildcard imports** and hand-formatted layout that fights `google-java-format`.
- **Inheritance for code reuse** across packages where composition + delegation is safer.

## Sources

- Google Java Style Guide (source structure, no-wildcard imports, naming, formatting, `@Override`, Javadoc): https://google.github.io/styleguide/javaguide.html
- Oracle — Record Classes (generated members, immutability, transparent data carriers): https://docs.oracle.com/en/java/javase/21/language/records.html
- OpenJDK JEP 409 — Sealed Classes (`sealed`/`permits`, closed hierarchies): https://openjdk.org/jeps/409
- Oracle — `java.util.Optional` API (container for a possibly-absent value; value-based, don't compare with `==`): https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Optional.html
- Effective Java, 3rd ed. (Joshua Bloch) — Item 1 static factories, Item 9 try-with-resources, Items 10/11 equals & hashCode, Item 17 minimize mutability, Item 18 composition over inheritance, Item 20 interfaces over abstract classes, Item 34 enums, Item 55 return Optionals judiciously, Item 64 program to interfaces: https://www.informit.com/store/effective-java-9780134686059
- google-java-format (reformats to Google Java Style; Spotless integration): https://github.com/google/google-java-format
- Error Prone — compile-time bug-pattern static analysis hooked into javac: https://errorprone.info/
- Checkstyle — style-rule enforcement wired into Maven/Gradle: https://checkstyle.sourceforge.io/
