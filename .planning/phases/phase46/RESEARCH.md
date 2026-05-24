# Phase 46: Documentation & Security Audit - Research

**Researched:** 2024-05-04
**Domain:** Codebase documentation, public API typespecs, security auditing tooling, and 1.0 release readiness.
**Confidence:** HIGH

## Summary

The Lockspire codebase is generally well-structured for the 1.0 release, but its documentation still heavily references its preview state (`v0.1` or `v0.2.0`). Significant features added in recent phases—like Device Authorization Flow (Phase 30) and Dynamic Client Registration (Phase 29)—are incorrectly listed as "out of scope" or "unsupported" in `README.md` and `SECURITY.md`. 

While the codebase maintains an excellent CI gate for testing and code quality (`credo`, `dialyzer`), it currently lacks automated vulnerability scanning for dependencies (`mix_audit`) and static application security testing (`sobelow`). Several public modules are missing `@doc` annotations, and ExDoc compilation emits warnings for hidden types.

**Primary recommendation:** Introduce `sobelow` and `mix_audit` to the CI pipeline, add missing `@doc` blocks to public interfaces, and aggressively update all markdown guides to reflect Lockspire's 1.0 feature completeness (specifically DCR and Device Flow).

## Documentation Coverage & Public Modules

The core public API modules exist but are missing function-level documentation (`@doc`):

1. `lib/lockspire.ex`: Has `@moduledoc` and full `@spec` annotations, but lacks `@doc` blocks for `config/0`, `issuer/0`, `logout_path/0`, and `account_resolver!/0` (only `mount_path/0` has one).
2. `lib/lockspire/admin.ex`: Acts as the operator-facing service boundary with full typespecs and `defdelegate` definitions, but completely lacks `@doc` descriptions for its functions.
3. `lib/lockspire/config.ex`: Lacks `@doc` for several configuration helpers (e.g., `repo!/0`, `issuer!/0`, `oban_config/0`).
4. **ExDoc Warnings:** Running `mix docs` produces 20 warnings. The documentation references types in hidden modules (`@moduledoc false`), which causes ExDoc compilation warnings. Specifically:
   - `Lockspire.Protocol.DpopPolicy.Resolved.t()`
   - `Lockspire.Protocol.ParPolicy.Resolved.t()`
   - `Lockspire.Protocol.DcrPolicy.Resolved.t()`
   - `Lockspire.Protocol.SecurityProfile.Resolved.t()`
   - `Lockspire.Protocol.Registration.Success.t()` / `Error.t()`
   - `Lockspire.Protocol.RegistrationManagement.UpdateSuccess.t()`
   - `Lockspire.Protocol.LogoutPropagation.Result.t()`

## Security Auditing Tools

**Current State:**
- The CI pipeline (`.github/workflows/ci.yml`) runs `mix deps.audit` during the "Fast Checks" job.
- However, `mix.exs` aliases `"deps.audit": ["hex.audit"]`. The `hex.audit` task only checks for *retired* packages, **not** security vulnerabilities (CVEs).
- `credo --strict` and `dialyzer` are correctly run via `mix qa`.

**Needed for 1.0:**
1. **`mix_audit`**: We must add `{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}` to `mix.exs` and update the alias so `deps.audit` actually checks for CVEs.
2. **`sobelow`**: We must add `{:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}` to `mix.exs` and integrate it into the CI pipeline (e.g., `mix sobelow --config` or as part of the `qa` alias).

## Documentation Updates for 1.0 Architecture

The following markdown files contain outdated preview constraints that must be updated for the 1.0 release:

### `README.md`
- **Outdated Claim:** Refers to Lockspire as a `v0.1` preview.
- **Outdated Claim:** "What v0.1 does not include" lists `device flow` and `dynamic client registration`. Both of these are now fully implemented and supported. 
- **Action:** Update the language to reflect 1.0 readiness and move DCR and Device Flow to the "What v1.0 includes" section.

### `SECURITY.md`
- **Outdated Claim:** "Unsupported or out-of-scope surfaces include: ... device flow". 
- **Action:** Device Flow is now a supported surface (Phase 31). DCR is also supported within a specific slice. The security posture of these features needs to be documented here rather than being listed as out-of-scope.

### `docs/supported-surface.md`
- **Outdated Claim:** "Lockspire v0.2.0 is a preview release".
- **Action:** This document needs to be graduated to the canonical 1.0 contract. The section "1.0 bar" defines the requirements (stable support, green release gates, evidence). The text must be rewritten to assert that Lockspire now meets this 1.0 bar.

### `docs/getting-started.md`
- **Action:** Needs to be updated to mention new architectural capabilities (like DCR self-service clients or Device Flow endpoints) so users understand the full breadth of Lockspire's 1.0 features.

## Common Pitfalls

### Pitfall 1: Delegated Functions Missing Docs
**What goes wrong:** `ex_doc` does not automatically copy `@doc` strings from the target module to the module using `defdelegate` unless explicitly configured.
**Why it happens:** In `lib/lockspire/admin.ex`, all functions are `defdelegate`.
**How to avoid:** Ensure `@doc` strings are written directly above the `defdelegate` definitions in `admin.ex` so they appear in the generated documentation.

## Open Questions (RESOLVED)

1. **Hidden Types in ExDoc**
   - What we know: Protocol modules use internal `Resolved` structs that are hidden via `@moduledoc false`.
   - What's unclear: Should we expose these modules by removing `@moduledoc false`, or should we stop referencing their `t()` types in the public documentation?
   - RESOLVED: Stop referencing hidden `t()` types in the public API specs (replace with `map()` or `struct()`) to keep internal structures private.