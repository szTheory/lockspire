---
phase: 01-foundation-and-host-seam
plan: 01
subsystem: auth
tags: [elixir, phoenix, liveview, ecto, oban, opentelemetry, config, host-seam]
requires: []
provides:
  - Embedded Lockspire OTP application skeleton
  - Runtime config helpers for repo, issuer, mount path, and host resolver lookup
  - Singular AccountResolver host seam with structured claims and interaction types
  - Contract tests for config wiring and host seam behaviour usage
affects: [phase-02-authorization-core, phase-03-oidc-and-token-lifecycle, install-dx]
tech-stack:
  added: [phoenix, phoenix_live_view, ecto_sql, postgrex, oban, opentelemetry_api, telemetry]
  patterns: [embedded-library otp app, explicit runtime config, behaviour-driven host seam]
key-files:
  created:
    - mix.exs
    - .formatter.exs
    - .gitignore
    - config/config.exs
    - lib/lockspire.ex
    - lib/lockspire/application.ex
    - lib/lockspire/config.ex
    - lib/lockspire/host/account_resolver.ex
    - lib/lockspire/host/claims.ex
    - lib/lockspire/host/interaction_result.ex
    - test/test_helper.exs
    - test/lockspire/config_test.exs
    - mix.lock
  modified: []
key-decisions:
  - "Kept the public Lockspire API to config lookup helpers only so protocol entrypoints do not leak into Phase 1."
  - "Represented host integration as one AccountResolver behaviour plus typed structs instead of loose callback config or macros."
  - "Started Lockspire.Application with only library-owned supervision capacity and no host session or account assumptions."
patterns-established:
  - "Runtime config is a locator for explicit host modules, not the behavior surface."
  - "Host-owned seams return structured data types for claims and login handoff."
requirements-completed: [INTE-01, INTE-02]
duration: 3min
completed: 2026-04-22
---

# Phase 01 Plan 01: Establish library structure, public API boundaries, and configuration model Summary

**Embedded Lockspire OTP bootstrapping with explicit runtime config and a typed AccountResolver host seam**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-23T03:47:15Z
- **Completed:** 2026-04-23T03:50:37Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Created the initial `:lockspire` Mix project, formatter config, runtime config defaults, and OTP application module.
- Added a narrow root API plus `Lockspire.Config` helpers that raise clear missing-config errors for required host wiring.
- Defined the singular host seam as `Lockspire.Host.AccountResolver` with structured `Claims` and `InteractionResult` types, then locked the contract with ExUnit tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the base OTP application and dependency skeleton** - `c839753` (`feat`)
2. **Task 2: Define the narrow public API and host seam behaviours** - `8897c5d` (`feat`)
3. **Task 3: Add contract-focused tests for runtime config and host seam wiring** - `ab0bae1` (`test`)

## Files Created/Modified
- `mix.exs` - Defines the Lockspire library app, OTP application, and core Phoenix/Ecto/Oban/OpenTelemetry dependencies.
- `.formatter.exs` - Establishes formatter coverage for mix, config, lib, and test files.
- `.gitignore` - Ignores Elixir build artifacts and `.DS_Store` files created during local verification.
- `config/config.exs` - Seeds runtime config keys for repo, account resolver, issuer, mount path, and Oban.
- `lib/lockspire.ex` - Exposes the small public API for config and host seam lookup.
- `lib/lockspire/application.ex` - Starts the embedded Lockspire supervisor without host auth assumptions.
- `lib/lockspire/config.ex` - Centralizes runtime config access and actionable missing-key errors.
- `lib/lockspire/host/account_resolver.ex` - Defines the host-owned behaviour for account resolution, claims, and login handoff.
- `lib/lockspire/host/claims.ex` - Provides a typed claims struct for ID token and userinfo enrichment.
- `lib/lockspire/host/interaction_result.ex` - Provides a typed login handoff struct.
- `test/test_helper.exs` - Boots ExUnit for the new library.
- `test/lockspire/config_test.exs` - Verifies config lookups, missing-config failures, and behaviour usability from a host module.
- `mix.lock` - Locks the resolved dependency set used by compilation and tests.

## Decisions Made
- Kept `Lockspire` limited to configuration and seam discovery helpers so later protocol work can stay behind internal boundaries.
- Used one explicit `Lockspire.Host.AccountResolver` behaviour for host-owned account resolution, claim generation, and login redirects.
- Added a minimal `.gitignore` because first-build artifacts (`_build/`, `deps/`) would otherwise remain as untracked generated files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected the OpenTelemetry API dependency to a published Hex version**
- **Found during:** Task 3 verification
- **Issue:** The plan specified `opentelemetry_api ~> 1.6`, but Hex currently publishes `1.5.0` as the latest available version, so `mix deps.get` failed.
- **Fix:** Changed the dependency requirement to `~> 1.5`, fetched dependencies, and committed the resolved `mix.lock`.
- **Files modified:** `mix.exs`, `mix.lock`
- **Verification:** `mix deps.get`, `mix compile`, and `mix test test/lockspire/config_test.exs` all passed after the change.
- **Committed in:** `ab0bae1`

**2. [Rule 3 - Blocking] Added missing test and ignore scaffolding required for a greenfield Elixir repo**
- **Found during:** Task 3 implementation and verification
- **Issue:** The repo had no `test/test_helper.exs` or `.gitignore`, which would block `mix test` and leave generated `_build/` and `deps/` directories untracked.
- **Fix:** Added `test/test_helper.exs` and a minimal `.gitignore` covering Elixir build outputs and `.DS_Store`.
- **Files modified:** `test/test_helper.exs`, `.gitignore`
- **Verification:** `mix test test/lockspire/config_test.exs` passed and generated build artifacts no longer appeared as actionable untracked files.
- **Committed in:** `ab0bae1`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required to make the planned library skeleton verifiable on a real Hex-backed Elixir environment. No scope creep introduced.

## Issues Encountered
- Hex prompted for user authentication during `mix deps.get`, but public dependency resolution completed successfully without a Hex login.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 2 can build authorization services against a stable root namespace, OTP app, and explicit host seam contract.
- Later phases can add storage, generators, and web layers without reopening the host-ownership boundary established here.

## Self-Check: PASSED
- Found `.planning/phases/01-foundation-and-host-seam/01-01-SUMMARY.md`
- Found task commits `c839753`, `8897c5d`, and `ab0bae1`
