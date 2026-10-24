---
phase: 164-client-secret-expiry-atomic-rotation
plan: "06"
subsystem: auth
tags: [oauth, dcr, client-secrets, redaction, documentation, postgres]
requires:
  - phase: 162
    provides: Normative nil/zero/positive lifetime, legacy, and token-validity contract
  - phase: 163
    provides: Lifetime-aware storage, transaction boundaries, and app-state foundations
  - phase: 164-01 through 164-05
    provides: Secret issue/authentication/rotation behavior and PostgreSQL race evidence
provides:
  - Non-vacuous audit, telemetry, log, and public-error redaction evidence from finite Basic and JWT secret operations
  - Correct DCR secret lifetime guidance and admin wording for prospective policy and explicit legacy replacement
  - Executed Phase 164 focused, normal-suite, and PostgreSQL race validation record
affects: [164-independent-verification, 165-management-lifetimes, 166-cross-phase-proof]
actuals:
  tokens: 7346.5
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 7e83b5cf7653dcbcf523968cdf1200b8f809dc33
plan_head_after: 288af0f769fcf9d1a1e8fa3690eb1247e2e515ee
tech-stack:
  added: []
  patterns:
    - Redaction checks require positive integer counts for each observed event class and exercise finite DCR Basic/JWT secret registration and rotation before scanning observed output.
    - Admin and host guidance distinguish prospective secret policy, stored credential lifetimes, and independent issued-token validity.
key-files:
  created: []
  modified:
    - test/lockspire/protocol/dcr_telemetry_redaction_test.exs
    - lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex
    - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
    - PRODUCT.md
    - test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs
    - test/lockspire/web/live/admin/policies_live/dcr_test.exs
    - docs/dynamic-registration.md
    - docs/upgrading/client-lifetimes.md
    - docs/client-secret-jwt-host-guide.md
    - test/lockspire/client_lifetime_guidance_test.exs
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-VALIDATION.md
key-decisions:
  - "No new observability event family was needed: existing registration, token issuance/failure, and operator-rotation events carried the exercised lifecycle evidence."
  - "DCR secret policy is prospective; existing secrets retain their stored expiry, and legacy dates remain advisory until explicit replacement."
  - "Management-token lifecycle remains Phase 165 work; final packaged cross-phase proof remains Phase 166 work."
patterns-established:
  - "Redaction acceptance requires positive integer counts for every subscribed lifecycle event before sensitive-material scans."
requirements-completed: []
coverage:
  - id: D1
    description: Finite-secret Basic/JWT lifecycle operations are observed and their audit, telemetry, log, and public-error outputs are scanned for secret material.
    requirement: DCR-07
    verification:
      - kind: integration
        ref: "test/lockspire/protocol/dcr_telemetry_redaction_test.exs#finite secret issuance, token use, expiry rejection, and operator replacement are observed and redacted"
        status: pass
      - kind: unit
        ref: "test/lockspire/redaction/redaction_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Admin guidance describes unlimited, finite, prospective, and replacement behavior in PRODUCT vocabulary.
    requirement: DCR-07
    verification:
      - kind: unit
        ref: "test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/policies_live/dcr_test.exs and test/lockspire/web/live/admin/vocabulary_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: Host docs match secret expiry, legacy replacement, adapter clock, PUT, and independent token semantics; integrated gates record visible exclusions and race evidence.
    requirement: DCR-08
    verification:
      - kind: unit
        ref: "C063a: client_lifetime_guidance_test.exs, architecture_fitness_test.exs, compatibility_baseline_contract_test.exs — 20 tests"
        status: pass
      - kind: integration
        ref: "C063b: mix test.fast — 2 properties, 2348 tests, 0 failures, 440 excluded, 6 skipped"
        status: pass
      - kind: integration
        ref: "C063c: explicit PostgreSQL race, rollback, and adapter conformance selection — 32 tests"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-10-21
status: complete
---

# Phase 164 Plan 06: Finite-Secret Redaction, Guidance, and Integrated Proof Summary

**Actual finite-secret registration, token use, expiry rejection, and operator replacement now feed redaction assertions; admin and host guidance reflect the enforced prospective lifetime contract.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-21T15:24:57Z
- **Completed:** 2026-10-21T15:33:28Z
- **Tasks:** 3/3
- **Files modified:** 11

## Accomplishments

- Extended the DCR redaction sweep with real finite Basic and JWT secret registration, authorization-code token issuance, equality-time secret rejection, and operator secret replacement. It requires positive integer counts for every subscribed event class before scanning captured telemetry, persisted audit rows for both clients, captured failure logs, and public error values for plaintext, stored hashes, the old/new persisted encrypted JWT verifiers, PKCE verifier material, and sensitive structural keys. A focused follow-up corrected the count assertion and nested-tuple scanner gaps found in independent security review; that review remains pending.
- Corrected blank and zero admin hints to say “No automatic expiry.” Positive-duration help now explains that the setting applies to new or replaced secrets and that changing policy leaves existing stored lifetimes alone. Retired wording is recorded in `PRODUCT.md`.
- Reconciled DCR PUT guidance: PUT rotates the app management token and preserves the client secret. The example no longer suggests a client-secret replacement or returns replacement plaintext.
- Updated host docs for strict expiry equality, non-secret exemptions, independent assertion timing/replay, issued-token validity, explicit legacy-secret replacement, and the same-arity adapter clock contract.
- Recorded focused, normal-suite, race, rollback, adapter, and database-cleanup evidence in `164-VALIDATION.md` while leaving independent Nyquist and security sign-off pending.

## Task Commits

1. **164-06-01: Observe finite-secret events and prove redaction** — `051880f1` (`test`)
2. **164-06-02: Make secret lifetime admin guidance truthful** — `8c25c2e7` (`fix`)
3. **164-06-03: Reconcile host guidance and execute the complete phase gate** — `288af0f7` (`docs`)
4. **Independent-review redaction evidence follow-up** — `42d0fd0f` (`test`)
5. **Independent UI-copy review follow-up** — `c7e29dcb` (`fix`)

**Plan metadata:** `2bd4d979` (`docs`: record plan execution closeout)

## Verification

All Mix commands used Elixir `1.18.4-otp-27`, OTP `27.3.4.15`, the supplied Mix and Hex homes, and the dedicated `lockspire_phase164_validation` database.

- C061 redaction selection, rerun after the independent-review correction: **26 tests, 0 failures**. Each subscribed event class must have a present, positive integer count; negative controls reject missing and nil counts and detect a sensitive key nested under a tuple. The live lifecycle includes finite Basic token issuance/expiry rejection/rotation and finite JWT registration/rotation. The old/new persisted encrypted JWT verifier values are unsealed and matched to their generated plaintexts, then scanned with available stored hashes across captured telemetry, both clients' audit rows, failure logs, and the public error. Independent security re-audit remains pending.
- C062 admin and vocabulary selection: **23 tests, 0 failures**.
- UI-copy review follow-up selection (rendered DCR page, lifetime hints, vocabulary contract, and host guidance): **28 tests, 0 failures**. Rendered copy now states which expiry is enforced, keeps app management-token expiry scoped to Phase 165, and explains that older advisory secret dates are replaced under the current setting.
- C063a guidance, architecture, and compatibility: **20 tests, 0 failures**.
- C063b `mix test.fast`: **2 properties, 2,348 tests, 0 failures, 440 excluded, 6 skipped**.
- C063c explicit PostgreSQL race, rollback, and adapter-conformance selection with `--include postgres_race`: **32 tests, 0 failures**.
- Post-run database query confirmed `current_database() = lockspire_phase164_validation`; counts for `secret-%` clients and their audit, token, JTI, interaction, device, and CIBA rows were all zero, as were singleton server-policy rows.
- `git diff --check` passed before the task commits.
- The packaged clean-room upgrade proof was not repeated because this plan changed no schema, migration, installer, package, or generated-host inputs. Phase 166 retains that cross-phase proof.

Exact command lines and the phase-wide exclusion boundary are recorded in `164-VALIDATION.md`. The normal `mix test.fast` result does not substitute for the separate PostgreSQL selection. Phase 164 plan 164-05's race-only subset independently reported 11 tests, 0 failures, and no exclusions; C063c also ran rollback and adapter-conformance coverage.

## New Symbols and Compatibility

- No production symbols or exported arities changed.
- The docs describe the existing `rotate_client_secret/4` adapter clock-function input without changing the callback arity.
- No dependency, schema, migration, or event family was added.

## TDD Evidence

- Task 164-06-02 followed a copy-first RED/GREEN cycle: the updated hint test failed against the old “already expired” wording; after the hint, page copy, and vocabulary table changed, C062 passed.
- Task 164-06-01 was test-only. Its early attempts exposed redirect and expected-audit fixture mistakes, which were corrected before the passing C061 run. Those setup/assertion failures are not treated as semantic RED evidence. The observed lifecycle already passed the existing redaction seam, so no production leak fix was justified. This plan does not claim phase-wide strict TDD compliance.

## Decisions Made

- No new event family was needed because the existing event paths exposed the real registration, token issuance/failure, and operator-rotation lifecycle.
- A DCR policy edit is prospective and does not change stored existing-secret expiry. Legacy advisory values remain non-authoritative until explicit secret replacement.
- Management-token lifetime/recovery remains owned by Phase 165. Final packaged cross-phase proof remains owned by Phase 166.

## Deviations from Plan

- Task 164-06-01 did not produce classifier-validated semantic RED evidence. This task extended an existing test-only redaction seam, and the real lifecycle data passed the existing redaction implementation without requiring a production change. The initial test runs failed on fixture setup and an incorrect expected audit label, not on the intended redaction behavior; no such run is counted as RED evidence.

## Security Audit Follow-up

- Corrected lifecycle event assertions to use `Map.fetch!/2` and require an integer count greater than zero for every subscribed event class. Negative controls prove missing and nil counts are rejected.
- Added tuple recursion to the sensitive-key detector with a nested-tuple negative control.
- Added actual finite `client_secret_jwt` registration and rotation. The test unseals old/new verifier values read back from storage to confirm they match the generated plaintexts, then scans those values and available hashes, including audit rows for both clients.
- Focused verification after these changes: **26 tests, 0 failures**. Runtime leakage was not observed; independent security re-audit is pending. Test commit: `42d0fd0f`.

## UI Copy Audit Follow-up

- The DCR expiry introduction now distinguishes enforced app and secret expiry from app management-token expiry, which remains unenforced and owned by Phase 165.
- App-lifetime help now describes Lockspire's enforcement for new apps. Secret-lifetime help explains that policy edits leave existing expiry unchanged and that an older app's advisory date is replaced using the current setting when its secret is replaced.
- Added each removed phrase to the PRODUCT retired-wording table and asserted the full rendered copy. The focused rendered-copy, lifetime-hint, vocabulary, and guidance selection passed: **28 tests, 0 failures**.
- The independent UI review artifact remains auditor-owned and was not edited. Implementation commit: `c7e29dcb`.

## Issues Encountered

- The existing authorization-code helper used a redirect URI outside the DCR fixture allowlist. The test now creates the authorization code with the registered redirect URI.
- The persisted registration audit action is `dcr_client_created`; the test uses that observed audit class while retaining the `dcr:register` telemetry event.
- The SDK `roadmap.update-plan-progress 164` command skipped because the Phase 164 detail has no writable progress row. The roadmap now records 6/6 plans executed while keeping phase verification pending; no requirements were marked complete.

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. No new network endpoint, authentication path, storage surface, or trust boundary was added.

## Next Phase Readiness

Plan 164-06 implementation and validation are ready for independent goal, security, coverage, and Nyquist verification. This summary does not mark Phase 164 or DCR-07/08/09 complete in planning state. Management-token behavior remains with Phase 165; final cross-phase packaged proof remains with Phase 166.

---
*Phase: 164-client-secret-expiry-atomic-rotation*
*Completed: 2026-10-21*

## Self-Check: PASSED

- The summary file exists.
- Task commits `051880f1`, `8c25c2e7`, and `288af0f7` are ancestors of HEAD.
- The measured plan commit count is three from `7e83b5cf7653dcbcf523968cdf1200b8f809dc33` to `288af0f769fcf9d1a1e8fa3690eb1247e2e515ee`.
- The three task commits contain no tracked file deletions.
- No task files remain uncommitted; pre-existing `.planning/config.json` and `.planning/state.json` changes remain outside task staging.
