---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "07"
subsystem: security-testing
tags: [elixir, python, dcr, telemetry, redaction, acceptance]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Fixed lifecycle, expiry and replacement behavior used as the test oracle
  - phase: 166-06
    provides: Selected client/transaction storage composition and recovery paths
provides:
  - Positive DCR lifecycle telemetry and persisted audit evidence before redaction scans
  - Safe deliberate-failure telemetry diagnostics and app-expiry rejection attribution
  - Shared credential registration for raw, Base64, URL-encoded and SHA-256 representations
  - Allowlisted packaged child receipts and identifier/count-only failure summaries
affects: [client-lifetime-packaged-proof, dcr-security-evidence]
actuals:
  tokens: 10621
  tasks: 2
  commits: 5
commits: 5
plan_head_before: 57a5910c44aad426a72c924c836d19ba80718302
plan_head_after: fd7095d1dd0c1f6e50698821c3a4039f6f181e17
tech-stack:
  added: []
  patterns:
    - Register returned credential forms before process output can reach retained evidence
    - Keep child receipts to validated outcome markers and fixed process fields
    - Require positive event and durable audit observations before sensitive-value scans
key-files:
  created:
    - test/acceptance/client_lifetime_redaction_test.py
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-07-01-RED-EVIDENCE.json
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-07-02-RED-EVIDENCE.json
  modified:
    - test/lockspire/protocol/dcr_telemetry_redaction_test.exs
    - scripts/acceptance/clean_room/redaction.py
    - scripts/acceptance/clean_room/client_lifetime_upgrade.py
    - scripts/acceptance/clean_room_saas_journey.py
key-decisions:
  - Keep failure summaries to known stage/scenario/event/field identifiers and a nonnegative count.
  - Do not pass registered credentials in child arguments; retain only allowlisted process outcomes.
  - Treat app-expiry PUT rejection as failure telemetry with no successful management audit row.
requirements-completed: [DCR-18]
coverage:
  - id: D1
    description: Integrated DCR telemetry redaction checks require positive events and audit rows and safely report deliberate detector failures.
    requirement: DCR-18
    verification:
      - kind: integration
        ref: test/lockspire/protocol/dcr_telemetry_redaction_test.exs#app expiry has an observed rejected update and no success audit row
        status: pass
      - kind: integration
        ref: test/lockspire/protocol/dcr_audit_attribution_test.exs#no DCR audit row is attributed to :operator across the full DCR write surface
        status: pass
    human_judgment: false
  - id: D2
    description: Packaged child output, argv, exceptions and receipts retain no credential or raw payload and reject empty proof.
    requirement: DCR-18
    verification:
      - kind: unit
        ref: test/acceptance/client_lifetime_redaction_test.py#LifetimeRedactionTest
        status: pass
      - kind: unit
        ref: python3 -m py_compile scripts/acceptance/clean_room/redaction.py scripts/acceptance/clean_room/client_lifetime_upgrade.py scripts/acceptance/clean_room_saas_journey.py
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-10-22
status: complete
---

# Phase 166 Plan 07: Telemetry and Packaged Output Redaction Summary

**DCR lifecycle proof now requires observed telemetry and durable audit evidence before scanning, while child-process receipts and failure messages retain only safe identifiers and counts.**

## Performance

- **Duration:** 7 minutes.
- **Started:** 2026-10-22T00:53:28Z.
- **Completed:** 2026-10-22T01:00:39Z.
- **Tasks:** 2/2.
- **Files changed:** 7 plan files, including two RED evidence records.

## Accomplishments

- Replaced telemetry leak assertion messages that included plaintext fragments and captured event payloads with event, field, and match-count diagnostics. A deliberate failing assertion proves the diagnostic itself stays safe.
- Required positive lifecycle telemetry and persisted audit rows before the redaction sweep. App expiry at equality now proves a rejected self-management update has failure attribution and no successful management audit row; existing tests preserve self-management versus host-recovery actors and rollback-without-success behavior.
- Extended the shared Python redactor to register generated values, Base64 and URL-encoded forms, and SHA-256 digests. The upgrade runner rejects registered secrets in argv, separates stdout/stderr, discards raw child output, validates bounded receipt fields, and reports only known identifiers and counts.
- Replaced the SaaS journey’s exception rendering with the same safe failure-summary boundary.

## Verification

- Task 166-07-01: `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/lockspire/protocol/dcr_telemetry_redaction_test.exs test/lockspire/protocol/dcr_audit_attribution_test.exs --max-failures 1 --timeout 55000` — **7 tests, 0 failures**.
- Task 166-07-02: `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_redaction_test.py' -v` — **7 tests, 0 failures**. The cases cover registered credential forms, stdout/stderr, argv rejection, exception reduction, allowlisted output, unexpected receipt fields, and zero scenarios.
- Python compilation passed for all three changed acceptance scripts and the focused test module. `git diff --check` passed.
- Both RED records passed `gsd_run check tdd-red-evidence` with `RED_EVIDENCE_OK`; the target tests failed on the intended diagnostic/API assertions before the GREEN commits.
- These focused checks do not execute the full packaged legacy-upgrade journey. The candidate-bound packaged proof remains with the later Phase 166 plans.

## Task Commits

1. **166-07-01 RED: telemetry diagnostic safety test** — `9a530f8b` (`test`).
2. **166-07-01 GREEN: safe telemetry diagnostics** — `ff9a6622` (`fix`).
3. **166-07-01: app-expiry and positive audit evidence** — `79fba826` (`test`).
4. **166-07-02 RED: safe receipt diagnostic test** — `04aad454` (`test`).
5. **166-07-02 GREEN: packaged output redaction** — `fd7095d1` (`fix`).

## Files Created/Modified

- `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` — positive event/audit gates, safe leak diagnostics, app-expiry rejection and no-success assertions.
- `test/acceptance/client_lifetime_redaction_test.py` — focused output-boundary and receipt tests.
- `scripts/acceptance/clean_room/redaction.py` — credential representation registration and safe failure summaries.
- `scripts/acceptance/clean_room/client_lifetime_upgrade.py` — safe child-process execution and exact receipt allowlists.
- `scripts/acceptance/clean_room_saas_journey.py` — safe journey exception reporting and expanded material registration.
- `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-07-01-RED-EVIDENCE.json` and `166-07-02-RED-EVIDENCE.json` — classifier-validated RED evidence.

## Decisions Made

- Child-process proof output retains only uppercase numeric observation markers and the exact process identity fields needed by the upgrade receipt.
- Registered credentials in child arguments fail before process startup; no generated credential is handed through argv.
- Error summaries accept only known identifiers and a nonnegative count, so arbitrary exception or assertion text cannot be rendered.

## Deviations from Plan

None. No dependencies or new harnesses were added.

## Issues Encountered

- The initial ExUnit RED output used its native text report, which the classifier does not parse. A TAP adaptation was added while preserving the complete raw ExUnit report, matching the established Phase 166 RED evidence pattern.
- One audit assertion initially queried outside the `client_disabled` action and failed. The query was corrected to include the persisted action, then the full task command passed.

## User Setup Required

None.

## Next Phase Readiness

The focused redaction and attribution guardrails are ready for the Phase 166 packaged host journeys. This plan makes no claim that the complete candidate package or live CI proof ran.

## Self-Check: PASSED

- All seven files listed under `key-files` exist.
- Commits `9a530f8b`, `ff9a6622`, `79fba826`, `04aad454` and `fd7095d1` are ancestors of `HEAD`.
- `git rev-list --count 57a5910c44aad426a72c924c836d19ba80718302..fd7095d1dd0c1f6e50698821c3a4039f6f181e17` measured **5 task commits**. The realized diff was 42,484 characters; `actuals.tokens` is 10,621 (characters divided by four).
- Parent-owned `.planning/STATE.md`, `.planning/state.json` and `.planning/ROADMAP.md` edits were left untouched and unstaged.
