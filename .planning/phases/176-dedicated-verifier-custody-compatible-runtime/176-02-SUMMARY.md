---
phase: 176-dedicated-verifier-custody-compatible-runtime
plan: "02"
subsystem: security
tags: [client-secret-jwt, verifier-custody, immutable-config, redaction]

requires:
  - phase: 176-dedicated-verifier-custody-compatible-runtime
    provides: Complete verifier context and native LSCV1 reader/sealer from Plan 01
provides:
  - Immutable node-local verifier configuration with absent, valid, and invalid-present states
  - Complete explicit overrides checked against startup-known endpoint/session and signing key bytes
  - Operation-local verifier configuration failures with unaffected persisted Basic/post authentication
affects: [client_secret_jwt, phase-176-plan-03, phase-176-plan-04, phase-176-rollout]

actuals:
  tokens: 8161
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 42699b59ce4aedbfef625a72a4cb7a36d2875d6a
plan_head_after: 8a065b60faebc92ee18c3f4eaa5c88fa5cca48d3

tech-stack:
  added: []
  patterns:
    - Persistent-term node snapshots retain full verifier state and a hidden startup comparison set
    - Explicit legacy endpoint key selection occurs only for allowed non-LSCV reads
    - Diagnostic validation reasons map to stable typed operation errors

key-files:
  created:
    - test/lockspire/config_client_secret_verifier_test.exs
    - test/integration/client_secret_verifier_configuration_test.exs
  modified:
    - lib/lockspire/application.ex
    - lib/lockspire/config.ex
    - lib/lockspire/protocol/client_auth/client_secret_jwt.ex
    - lib/lockspire/security/client_secret_verifier.ex
    - lib/lockspire/security/client_secret_verifier/context.ex

key-decisions:
  - "Present-but-invalid verifier configuration is retained at startup and fails verifier operations locally; it does not disable unrelated hash authentication."
  - "Complete overrides use the immutable startup-known purpose-key comparison set; partial overrides never merge with ambient fields."
  - "Staged keys, including an optional current ID, preserve legacy writes until dedicated mode is explicitly selected."
  - "SEC-02 edge E02 remains flagged unclassified; no probe pass or automatic dismissal is claimed."

patterns-established:
  - "Resolve optional verifier configuration once at application start and never consult mutable app env on a request cache miss."
  - "Keep invalid diagnostic reason codes internal; public JWT failures remain the existing unavailable mapping."

requirements-completed: [SEC-01, SEC-02, VUP-02]
coverage:
  - id: D1
    description: "Node-local configuration distinguishes absent, staged, dedicated, and invalid-present states and keeps overrides complete."
    requirement: SEC-01
    verification:
      - kind: unit
        ref: test/lockspire/config_client_secret_verifier_test.exs#startup retains absent, valid, and invalid-present settings as distinct states
        status: pass
      - kind: unit
        ref: test/lockspire/config_client_secret_verifier_test.exs#application environment edits and concurrent reads cannot hot reload the snapshot
        status: pass
    human_judgment: false
  - id: D2
    description: "Verifier key grammar and purpose separation reject invalid or reused material, while invalid verifier settings preserve persisted Basic/post authentication."
    requirement: SEC-02
    verification:
      - kind: unit
        ref: test/lockspire/config_client_secret_verifier_test.exs#exact grammar rejects duplicates, unknown options, invalid current, and contradictory modes
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_configuration_test.exs#invalid verifier configuration fails JWT and sealing locally while persisted hash auth works
        status: pass
    human_judgment: false
  - id: D3
    description: "Local staged and dedicated configuration behavior is implemented without claiming fleet readiness; E02 remains unclassified."
    requirement: VUP-02
    verification:
      - kind: unit
        ref: test/lockspire/config_client_secret_verifier_test.exs#staged keys including a current ID retain legacy writes
        status: pass
    human_judgment: true
    rationale: "Local tests cannot establish fleet parity, reader readiness, backup, quiescence, or rollback safety; the unclassified E02 probe also remains open."

duration: 12min
completed: 2026-10-25
status: complete
---

# Phase 176 Plan 02: Immutable Verifier Configuration and Failure Isolation Summary

**The verifier reader now uses a startup-frozen custody context, rejects invalid-present settings locally, and leaves persisted Basic/post hash authentication available.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-25T21:53:37Z
- **Completed:** 2026-10-25T22:05:38Z
- **Tasks:** 2
- **Files modified:** 7
- **Observed RED-to-GREEN commit interval:** 2m 31s for Task 1; 4m 51s for Task 2.

## Accomplishments

- Added startup resolution for absent, valid, and invalid-present verifier configuration. The immutable `:persistent_term` context includes the startup-known cross-purpose key comparison set; getters fail closed if that snapshot is uninitialized.
- Enforced the frozen four-option grammar, optional reader-only `:current`, all existing standard/Base64URL encodings, duplicate option/ID/decoded-byte rejection, and complete override validation against the startup comparison set.
- Routed JWT reads through the snapshot. LSCV-family reads do not resolve endpoint secrets; only allowed legacy reads receive an explicit endpoint secret at the integration boundary.
- Proved invalid configuration rejects JWT verification and sealing without changing stored client credentials, while a separately persisted client-secret-post client still authenticates using its stored hash.
- Startup warnings, context inspection, and auth telemetry omit supplied sentinels. Public JWT auth errors keep the existing `client_secret_verifier_unavailable` mapping.
- Preserved the flagged, unclassified SEC-02 edge E02. No probe pass or fleet-readiness claim is made.

## Task Commits

1. **Task 1 RED:** `91f79577` — `test(176-02): add failing verifier snapshot contract`
2. **Task 1 GREEN:** `1d9ad0d5` — `feat(176-02): cache verifier custody context`
3. **Task 2 RED:** `cdb57669` — `test(176-02): cover invalid verifier config isolation`
4. **Task 2 GREEN:** `8a065b60` — `feat(176-02): enforce verifier config isolation`

## Files Created/Modified

- `lib/lockspire/application.ex` — resolves and retains verifier state without making startup depend on optional verifier config.
- `lib/lockspire/config.ex` — exposes snapshot access, complete override validation, and startup-only cross-purpose key collection.
- `lib/lockspire/security/client_secret_verifier/context.ex` — retains safe invalid-state diagnostics, frozen comparison bytes, and the optional staged current key.
- `lib/lockspire/security/client_secret_verifier.ex` — maps invalid-context details to the stable typed configuration error and accepts the absent legacy state.
- `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` — uses the snapshot and resolves legacy endpoint key material only for allowed non-LSCV reads.
- `test/lockspire/config_client_secret_verifier_test.exs` — state, grammar, override, snapshot-concurrency, purpose-separation, and redaction coverage.
- `test/integration/client_secret_verifier_configuration_test.exs` — persisted JWT and post-auth behavior, operation-local failure, no row/effect mutation, telemetry/log redaction, and dedicated reads without endpoint-secret resolution.

## Decisions Made

- The startup comparison set is stored in the node context so request-time overrides do not reread mutable application environment.
- Validator detail remains available as an allowlisted internal diagnostic; verifier operations return the contract’s stable configuration error.
- The entire `LSCV` family bypasses legacy endpoint-key lookup, preserving reserved-family no-downgrade behavior.

## TDD Gate Compliance

- **Task 1 RED:** The target snapshot API assertion failed before implementation. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` for one discovered test and no setup or load failures. The implementation then passed the planned config/application suite with 14 tests and 0 failures.
- **Task 1 GREEN feedback:** The existing native tracer and parser suites passed together with 11 tests and 0 failures. Their first run found that the Plan 01 facade rejected the absent context; the scoped fix restored the frozen absent-legacy path.
- **Task 2 RED:** The persisted-client integration target failed on the planned assertion because the facade returned the validator detail `invalid_options` instead of `client_secret_verifier_configuration_invalid`. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK` for one discovered test and no setup or load failures.
- **Task 2 GREEN:** The exact task integration command passed with 13 tests and 0 failures. The final combined config, integration, tracer, and parser command passed with 24 tests and 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Allow the absent context through the shared verifier facade**
- **Found during:** Task 1, existing legacy tracer verification
- **Issue:** The Plan 01 facade accepted only `state: :valid`, so the required absent-setting legacy path failed before endpoint-secret unsealing.
- **Fix:** Let the facade accept the absent state and use its existing legacy-read path with the explicitly supplied integration key.
- **Files modified:** `lib/lockspire/security/client_secret_verifier.ex`
- **Verification:** Existing tracer and parser command passed with 11 tests and 0 failures.
- **Committed in:** `1d9ad0d5`

**2. [Rule 1 - Bug] Map invalid-context diagnostics to the stable operation error**
- **Found during:** Task 2 RED integration
- **Issue:** Invalid context validation detail escaped `seal/3` and `open/4` as `invalid_options`, while the accepted internal operation contract requires `client_secret_verifier_configuration_invalid`.
- **Fix:** Preserve allowlisted diagnostics in the retained context but map invalid configuration at the facade boundary to the stable typed error.
- **Files modified:** `lib/lockspire/security/client_secret_verifier.ex`
- **Verification:** The Task 2 persisted-client integration test passed, including unchanged hash/verifier fields and unaffected post authentication.
- **Committed in:** `8a065b60`

**3. [Rule 2 - Missing critical behavior] Keep the cross-purpose comparison set immutable**
- **Found during:** Task 2 configuration review
- **Issue:** Validating operation overrides by rescanning app env would make cross-purpose rejection change after startup and violate the immutable custody contract.
- **Fix:** Retain startup-known endpoint/session and signing KEK bytes inside the context, omit them from inspection, and use only that snapshot to validate overrides.
- **Files modified:** `lib/lockspire/security/client_secret_verifier/context.ex`, `lib/lockspire/config.ex`
- **Verification:** A test changes endpoint config after resolution and verifies override validation still uses the startup comparison set.
- **Committed in:** `8a065b60`

**4. [Rule 1 - Bug] Avoid endpoint-secret lookup for dedicated envelopes**
- **Found during:** Task 1 reader integration review
- **Issue:** A `legacy_read: :allow` context caused the integration layer to resolve the endpoint secret even for dedicated LSCV envelopes.
- **Fix:** Resolve and pass endpoint material only for non-LSCV input on an allowed legacy path; malformed LSCV-family inputs remain reserved and never fall back.
- **Files modified:** `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`
- **Verification:** Dedicated persisted authentication passed while endpoint config was set to a non-key value that would fail any legacy key lookup.
- **Committed in:** `8a065b60`

**Total deviations:** 4 auto-fixed (three Rule 1, one Rule 2). **Impact:** These fixes enforce the plan’s absent-state compatibility, typed failure, immutable comparison, and dedicated custody boundaries. No dependencies, schema, signing format, or later writer/age/maintenance work was added.

## Issues Encountered

- ExUnit’s native reporter is not one of the GSD RED-evidence adapters. Temporary TAP formatter output was used for both target RED runs; each report was accepted by the canonical `tdd-red-evidence` check. Temporary reports and formatter source were removed after classification.
- The repository Git metadata required an approved sandbox escalation for atomic commits. All four commits were made on the current milestone branch after root and branch assertions.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can use the new snapshot and complete override APIs for client material and direct-registration work. Reader configuration, existing legacy compatibility, and invalid-present operation isolation are covered. E02 remains flagged unclassified; these local tests do not establish fleet readiness, backup, quiescence, or rollback safety.

## Self-Check: PASSED

The SUMMARY exists, all four task commits are ancestors of the plan head, and `git diff --check` passed.

---
*Phase: 176-dedicated-verifier-custody-compatible-runtime*
*Completed: 2026-10-25*
