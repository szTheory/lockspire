# Phase 46 Research: Security, Documentation, and Code Quality for 1.0 GA

This document analyzes three critical gray areas for Lockspire's upcoming 1.0 GA release, providing tradeoffs, ecosystem idioms, industry lessons, and definitive recommendations.

---

## 1. Security Tooling: Sobelow vs. MixAudit vs. Manual Review

### Approaches & Tradeoffs
*   **Sobelow (Static Analysis):** 
    *   *Pros:* Specifically designed for Phoenix and Plug applications. Automatically detects common web vulnerabilities (XSS, CSRF, SQL injection, directory traversal). Fast and integrates well into CI.
    *   *Cons:* Can produce false positives. Mostly focused on web layers; won't catch deeply embedded domain logic flaws or cryptographic misuse unless it fits a known pattern.
*   **MixAudit / Dependabot (Dependency Scanning):**
    *   *Pros:* Catches known CVEs in upstream libraries (e.g., a vulnerability in `jason` or `plug`). Essential for library maintainers to ensure they aren't passing vulnerable dependency trees to users.
    *   *Cons:* Only checks dependencies, not first-party code.
*   **Manual Security Audit:**
    *   *Pros:* Deep contextual understanding. Can catch complex logic flaws, state-machine bypasses, and OIDC/OAuth2 protocol violations that automated tools miss.
    *   *Cons:* Expensive, time-consuming, and prone to human error or fatigue. Doesn't scale with every commit.

### Elixir/Phoenix Idioms
The Elixir community heavily relies on automated tooling in CI pipelines. A standard production-grade open-source Elixir library will run `mix format --check-formatted`, `mix deps.unlock --check-unused`, `mix credo --strict`, `mix dialyzer`, `mix hex.audit`, `mix deps.audit` (MixAudit), and `mix sobelow` on every PR. 

### Lessons Learned from Successful Libraries
*   **Oban / Ash:** Both heavily utilize automated CI checks to prevent regressions, but their core security models (e.g., Oban's job isolation, Ash's policy-based authorization) require meticulous manual design and review.
*   **Devise / Doorkeeper (Ruby):** Auth libraries in Ruby often struggled with ecosystem CVEs. Tools like `bundler-audit` became mandatory. Automated static analysis (Brakeman, the Ruby equivalent to Sobelow) is a hard requirement for any serious Rails auth tool.

### Recommendation
**Use a "Defense in Depth" automated approach: Both Sobelow and MixAudit, augmented by focused manual review for crypto/OIDC boundaries.**
Do not choose between them; they do different things. 
1.  **Depend on `mix_audit`** to ensure Lockspire doesn't ship with vulnerable dependencies.
2.  **Enforce `sobelow --config`** in CI to catch basic Plug/Phoenix routing and rendering flaws.
3.  **Manual Review Scope:** Reserve manual security review strictly for Lockspire's cryptographic signatures, token generation, and OIDC protocol conformance (e.g., FAPI strictness). 
*Developer Ergonomics:* Generate a `.sobelow-conf` file to ignore known/accepted false positives so CI remains green and developers aren't plagued by noise.

---

## 2. Public API Surface Documentation

### Approaches & Tradeoffs
*   **Document Everything (No `@moduledoc false`):**
    *   *Pros:* Maximum transparency. Users can read hexdocs to understand exactly how the library works internally.
    *   *Cons:* Users *will* rely on undocumented or internal functions. When you refactor an internal module in a minor release, you will break their code, violating SemVer and eroding trust.
*   **Curated Top-Level Docs (Hide internals with `@moduledoc false`):**
    *   *Pros:* Clear delineation of the public contract. Allows the maintainer to freely refactor internal architecture without releasing breaking changes. Generates clean, navigable Hexdocs.
    *   *Cons:* Requires discipline to maintain the boundary. Sometimes requires `defdelegate` boilerplate to expose internal functionality cleanly.

### Elixir/Phoenix Idioms
Elixir places a massive premium on documentation (Hexdocs are considered first-class). The idiom is absolutely to use `@moduledoc false` for internal modules. The community standard is that if it is in Hexdocs, it is part of the public API and bound by Semantic Versioning. If it is hidden, users use it at their own risk.

### Lessons Learned from Successful Libraries
*   **Devise (Ruby):** Historically suffered from users monkey-patching deep internal classes because the "public API" wasn't strongly delineated. This made upgrading Devise notoriously painful.
*   **Oban (Elixir):** Masterclass in API design. The `Oban` module is a clean facade. Internals like `Oban.Peer` or database polling mechanisms are hidden or clearly marked, allowing the creators to completely rewrite the engine without breaking user apps.
*   **Ecto (Elixir):** Clearly separates public APIs (`Ecto.Repo`, `Ecto.Query`) from internal adapters and engines (`Ecto.Adapters.SQL` internals).

### Recommendation
**Strictly curate the public API using `@moduledoc false` for all internals.**
For a 1.0 GA release, the documentation should be a curated tour of the public contract.
1.  Hide all internal workers, protocol parsers, and storage adapters with `@moduledoc false`.
2.  Use `groups_for_modules` and `extras` in `mix.exs` to organize the Hexdocs into logical sections (e.g., "Core", "Plugs", "Configuration").
3.  Expose complex internal behavior through a clean, top-level facade module (e.g., `Lockspire`).
*Developer Ergonomics:* This guarantees the Principle of Least Surprise. When a developer looks at the Hexdocs, they see exactly what they are *supposed* to use, reducing cognitive load and preventing them from accidentally tying their app to a volatile internal function.

---

## 3. Code Quality (Credo Strictness)

### Approaches & Tradeoffs
*   **Fix all 48 Strict Issues:**
    *   *Pros:* Achieves "perfect" compliance. CI is trivial to set up (`mix credo --strict`).
    *   *Cons:* Often leads to "Credo-driven development" where developers ruin perfectly readable code (e.g., breaking up a clear multi-line string or extracting micro-functions) just to satisfy a pedantic linter rule (like `Refactor.Nesting` or `Readability.AliasOrder`).
*   **Abandon Strict Mode:**
    *   *Pros:* Less friction.
    *   *Cons:* Accumulates technical debt. Inconsistent styling makes the codebase harder for new open-source contributors to navigate.
*   **Curated Strict Mode (Tweak `.credo.exs`):**
    *   *Pros:* Enforces consistency where it matters (cyclomatic complexity, naming conventions) but ignores rules that harm readability.
    *   *Cons:* Takes 30-60 minutes to calibrate the configuration file.

### Elixir/Phoenix Idioms
The Elixir ecosystem strongly values tooling, but prefers pragmatism over dogmatism. Most elite Elixir libraries run Credo in strict mode, but they **customize their `.credo.exs` file heavily** to disable rules that conflict with the team's definition of readability. 

### Lessons Learned from Successful Libraries
*   **Phoenix / LiveView:** The core teams use Format and Credo but often disable rules regarding module aliases or single-pipe chains if the resulting code reads more like natural domain language.
*   **General Industry:** Blindly fixing linting errors for a 1.0 release without questioning the rules often introduces bugs. Refactoring purely for a linter right before GA is a known anti-pattern.

### Recommendation
**Adopt a "Curated Strict Mode" via `.credo.exs`. Do NOT blindly fix all 48 issues.**
For the 1.0 GA release:
1.  Run `mix credo --strict`.
2.  Review the 39 Readability and 9 Refactoring issues.
3.  If an issue highlights a genuine code smell (e.g., a massive 100-line function, missing documentation on a public function), **fix it**.
4.  If an issue highlights a pedantic rule that makes the code *harder* to read (e.g., forcing an alias where a fully qualified module name provides better context, or whining about a single-pipe chain that improves flow), **disable or adjust the rule in `.credo.exs`**.
5.  Once the configuration matches your actual standard of readability, enforce `mix credo --strict` in CI.
*Developer Ergonomics:* This respects the developer's time and intelligence. It ensures the codebase remains highly readable and consistent without treating the linter as an infallible dictator.

---
**Summary of GA Alignment:**
All three recommendations align on a single philosophy: **Curated, Pragmatic Boundaries.** 
*   Security relies on curated automation + focused manual boundaries. 
*   Documentation relies on curated public facades + hidden internal boundaries. 
*   Code Quality relies on curated linter rules + enforced CI boundaries. 
This provides maximum developer ergonomics and safety for the 1.0 GA release.