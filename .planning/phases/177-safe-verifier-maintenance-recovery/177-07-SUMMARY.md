---
phase: 177-safe-verifier-maintenance-recovery
plan: "07"
subsystem: auth-storage
tags: [elixir, ecto, postgresql, credential-redaction, tdd]

requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: Selected client storage and verifier maintenance boundaries from Plan 01.
provides:
  - Nested client inspection omits stored client-secret hashes, verifier ciphertext, and registration-token hashes.
  - Existing full-client reads and writes suppress Ecto SQL Logger and query telemetry channels.
  - Client-store Postgrex and connection errors become fixed safe reasons before callers can inspect them.
affects: [177-08, 177-09, verifier-disclosure, storage-logging]

actuals:
  tokens: 5977
  tasks: 2
  commits: 4
commits: 4
plan_head_before: ed91bde98e33ab1c9591acfbf1f985a6fe67de00
plan_head_after: f7e96e914ba3bb8ccda8dc7ae0b17c541980348a

tech-stack:
  added: []
  patterns: [Ecto redacted fields, recursive domain Inspect exclusions, sensitive repository query options, bounded storage error mapping]

key-files:
  created:
    - test/lockspire/security/client_secret_verifier_inspection_test.exs
    - test/integration/client_secret_verifier_maintenance_disclosure_test.exs
    - .planning/phases/177-safe-verifier-maintenance-recovery/177-07-01-red-evidence.json
    - .planning/phases/177-safe-verifier-maintenance-recovery/177-07-02-red-evidence.json
  modified:
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/repository/client_store.ex

key-decisions:
  - "Preserve RegistrationResult and rotation handoff shapes; redact stored credentials recursively without adding a wrapper struct."
  - "Apply the existing sensitive repository option to every full-client query/write so Logger and query telemetry are both suppressed."
  - "Map raw Postgrex and DBConnection failures to fixed reasons while preserving ordinary validation and lifetime outcomes."

patterns-established:
  - "Inspection tests cover Ecto schema/changeset and nested domain/client result values while keeping sentinel values out of failure output."
  - "Persisted query-channel tests use an observed non-sensitive control before asserting no sensitive events or logs."

requirements-completed: [VPROOF-01]
coverage:
  - id: D1
    description: "Ecto and nested client inspection hides stored credential values while public registration and one-time handoff contracts remain intact."
    requirement: VPROOF-01
    verification:
      - kind: unit
        ref: "test/lockspire/security/client_secret_verifier_inspection_test.exs#stored credentials are hidden throughout supported nested inspections"
        status: pass
    human_judgment: false
  - id: D2
    description: "Existing persisted client operations suppress SQL Logger/query telemetry material and map hostile database failures to safe outcomes."
    requirement: VPROOF-01
    verification:
      - kind: integration
        ref: "test/integration/client_secret_verifier_maintenance_disclosure_test.exs"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 07: Stored Client Credential Disclosure Summary

**Stored client credentials are hidden in nested inspection, existing client SQL channels are suppressed, and raw storage failures are reduced to safe reasons.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-26T01:23:47Z
- **Completed:** 2026-10-26T01:31:04Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Marked client-secret hash, dedicated verifier ciphertext, and registration access-token hash as Ecto redacted fields; added recursive `Domain.Client` Inspect exclusions.
- Preserved `RegistrationResult`, three-key secret-material maps, and the existing authorized one-time plaintext handoff shape.
- Suppressed both Ecto query channels on existing full-client fetch/list/lock/insert/update/registration-management/secret-rotation operations and returned fixed safe reasons for database exceptions.
- Added nested inspection tests and PostgreSQL disclosure tests with positive Logger/telemetry controls and a hostile trigger error.

## Task Commits

1. **177-07-01: Redact stored credentials in schema and nested domain inspection** — `b66e8c75` (RED), `99cf175c` (GREEN).
2. **177-07-02: Suppress both client query channels and map unsafe storage diagnostics** — `a24ffa3f` (RED), `f7e96e91` (GREEN).

Measured plan range: 4 commits from `ed91bde9` through `f7e96e91`.

## Files Created/Modified

- `lib/lockspire/storage/ecto/client_record.ex` — Ecto redaction for stored client credentials.
- `lib/lockspire/domain/client.ex` — recursive inspection exclusion for stored credential fields.
- `lib/lockspire/storage/ecto/repository/client_store.ex` — sensitive options on full-client queries and writes, plus safe database error mapping.
- `test/lockspire/security/client_secret_verifier_inspection_test.exs` — schema, changeset, nested result and handoff-shape coverage.
- `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` — real PostgreSQL Logger/telemetry capture and hostile database error coverage.
- `177-07-01-red-evidence.json`, `177-07-02-red-evidence.json` — validated TDD RED records.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix format --check-formatted` — passed.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_inspection_test.exs test/lockspire/clients_secret_material_test.exs` — exit 0, 7 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs` — exit 0, 2 tests, 0 failures.
- Combined focused rerun — 9 tests, 0 failures; `git diff --check` passed.

## TDD Evidence

Both RED records returned `RED_EVIDENCE_OK` from `gsd-tools check tdd-red-evidence`; the test commits precede their GREEN implementation commits. RED failures were the intended nested-inspection leak and existing client SQL disclosure. The integration reporter emitted TAP while Logger output was redirected, so sentinel values did not appear in command output.

## Decisions Made

- Kept the public result types and exact helper/map contracts unchanged; nested domain inspection redacts stored fields recursively.
- Reused `Support.repo_options(sensitive: true)`, which disables both `log` and `telemetry_event`; no host-global logging policy was changed.
- Replaced raw Postgrex and DBConnection errors with `:storage_error` and `:storage_unavailable` before returning through client-store operations.

## Deviations from Plan

None. No dependencies, schema columns, migrations, protocol changes, or new public result structs were introduced.

## Issues Encountered

- ExUnit's default console report is not a supported RED evidence format. A temporary ExUnit reporter emitted TAP from the real test events; it was removed after both RED records passed the evidence checker.
- The first integration fixture reused a registration-token hash across two clients and correctly hit the unique lookup boundary. The test fixture now uses distinct markers so each operation exercises one stored client.

## User Setup Required

None. The configured PostgreSQL integration database was available.

## Next Phase Readiness

Plan 07 closes existing inspection and Ecto query-channel disclosures. Host instrumentation and PostgreSQL server logging remain host responsibilities. No Phase 177 or Phase 178 completion is claimed.

## Self-Check: PASSED

- All five implementation and test files listed as key files exist.
- All four task commits are ancestors of the measured plan head.
- The plan ledger measures 4 commits from `ed91bde9` through `f7e96e91`.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*
