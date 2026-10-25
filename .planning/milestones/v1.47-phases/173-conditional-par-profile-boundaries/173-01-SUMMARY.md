---
phase: 173-conditional-par-profile-boundaries
plan: "01"
subsystem: auth
tags: [oauth, oidc, par, pkce, phoenix, ecto, exunit]
requires:
  - phase: 171-accepted-baseline-finding-qualification
    provides: Frozen P171-005 counterexample and retained PAR lifecycle/profile owners
  - phase: 172-authorization-responses
    provides: Supported response-mode behavior and established authorization validation boundary
provides:
  - Stored pushed authorization parameters remain authoritative when the outer authorize request adds conflicting fields
  - Durable real-Router P171-005 RED/GREEN regression with exact relative consent route and persisted projection assertions
  - Selective Phase 171 qualification input audit for the changed Phase 15 test and Phase 172–173 roadmap selector
affects: [Phase 171 verification, Phase 172 verification, Phase 174 packaged proof and delivery]
actuals:
  tokens: 5427 # chars/4 across the realized code, ledger, STATE, and summary diff
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns:
    - Reconstruct pushed authorization only from stored request fields, then run the existing validation pipeline
    - Prove Router handoff through independent one-use references and persisted interaction state
key-files:
  created:
    - .planning/phases/173-conditional-par-profile-boundaries/173-01-SUMMARY.md
  modified:
    - lib/lockspire/protocol/authorization_request.ex
    - test/lockspire/protocol/authorization_request_test.exs
    - test/integration/phase15_par_authorization_e2e_test.exs
    - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
key-decisions:
  - "Removed the blanket outer-parameter conflict rejection at the existing resolver; preserved stored-only reconstruction and the distinct request plus request_uri collision guard."
  - "Used a reference-only control followed by a separately pushed conflicting-scope candidate, and required exact relative consent routing plus persisted client, scopes, state and nonce."
  - "Kept external provider-origin, TLS, proxy and browser profiles supplemental and unlaunched; Phase 174 retains packaging, CI and delivery work."
patterns-established:
  - "PAR conflict regressions must assert the consumed reference's stored interaction fields, not just redirect status."
  - "Qualification audits update only reviewed identities and append source-attributed old/new hashes."
requirements-completed: [PARB-01, PARB-02, PARB-03]
coverage:
  - id: D1
    description: Pushed scope, state, nonce and client remain authoritative through real PAR and authorize Router calls.
    requirement: PARB-02
    verification:
      - kind: integration
        ref: "test/integration/phase15_par_authorization_e2e_test.exs#P171-005 pushed scope remains authoritative after an independent reference-only consent control"
        status: pass
      - kind: unit
        ref: "test/lockspire/protocol/authorization_request_test.exs#resolves pushed parameters despite conflicting outer authorization parameters"
        status: pass
    human_judgment: false
  - id: D2
    description: Existing PAR lifecycle, required-PAR, strictness, configured discovery and response-mode behavior remain green.
    requirement: PARB-01
    verification:
      - kind: integration
        ref: "Phase 15 plus discovery owners: 11 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "Phase 37 strictness owner: 5 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "Phase 172 response-mode tagged owner: 1 test, 0 failures"
        status: pass
      - kind: unit
        ref: "Authorization/PAR controller and protocol shared suites: 94 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: Frozen qualification content and historical receipt/probe bytes remain intact with only authorized input hashes audited.
    requirement: PARB-03
    verification:
      - kind: unit
        ref: "test/lockspire/qualification_ledger_contract_test.exs: 22 tests, 0 failures"
        status: pass
      - kind: other
        ref: "Frozen-content, audit-chain and historical-byte provenance invariant"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-10-24
status: complete
commits: 3
plan_head_before: 79048ed2ea3e3ec060a4bbd671e7ba58e80f1b8b
plan_head_after: 88f6bb3d72b8dda3ffcf83cf804209ae7e2cde35
---

# Phase 173 Plan 01: Conditional PAR & Profile Boundaries Summary

**Pushed authorization parameters now remain authoritative across conflicting outer authorize fields, with same-test Router RED/GREEN and retained lifecycle/profile proof.**

## Performance

- **Duration:** About 5 minutes of captured execution
- **Started:** 2026-10-24T23:26:01Z (first captured runtime/precondition check)
- **Completed:** 2026-10-24T23:31:12Z
- **Tasks:** 2
- **Files modified:** 4, plus this new summary

## Accomplishments

- Removed the early blanket rejection of authorization fields accompanying `request_uri`; kept the distinct `request` plus `request_uri` collision check, reference prefix validation, client binding, one-use consume, and stored-only parameter reconstruction.
- Added a tagged Phase 15 real-Router regression. Its independent reference-only control reached the exact relative consent path and persisted pushed client/scopes/state/nonce before a distinct reference with outer `scope=profile` was tried.
- Reconciled the obsolete protocol expectation so conflicting outer redirect, scope, state, nonce, PKCE challenge and method leave the stored callback, profile/email scopes, state, nonce, S256 challenge and method authoritative.
- Audited only the Phase 15 test and roadmap selector identities in the canonical Phase 171 ledger. Frozen case content, historical source and observation identities, receipt/probe bytes, frozen timestamp, qualification SHA and existing audit prefix remain unchanged.

## Source-Bound RED/GREEN Evidence

Command for both runs:

```sh
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/integration/phase15_par_authorization_e2e_test.exs --trace --only phase173_par_authority
```

| Run | Source and test identity | Result |
|---|---|---|
| Entry / RED | Entry commit `79048ed2ea3e3ec060a4bbd671e7ba58e80f1b8b`; protocol SHA-256 `2279206b3c3b27b5f1526b426863089b81b06883d586a97aa3e90fd8cc320e3a`; test SHA-256 `9a286e37949857ced7bdf5672d01a9d7d89c4f381d579be7aff6e9a5c3c35413` | Both real PAR POSTs returned references; the reference-only consent control and persisted projection passed. The separate candidate reached the expected assertion and failed with `expected consent handoff, got HTTP 400`. ExUnit: 4 tests, 1 failure. This is the normative RED. |
| Corrected / GREEN | Fix commit `a15e397441017d2c6199ed6a5eb21cb67ebc0e36`; protocol SHA-256 `3dd97834e94398f6f26abae578085e01f70ecb42f8bc4d3235074c62ad7f63da`; same test SHA-256 `9a286e37949857ced7bdf5672d01a9d7d89c4f381d579be7aff6e9a5c3c35413` | The same candidate reached consent and its persisted interaction matched pushed client, `email`/`openid`, state and nonce. ExUnit: 4 tests, 0 failures. |

The initial test attempt stopped at a helper assertion because Phoenix included `charset=utf-8` in the JSON Content-Type. That setup mismatch was corrected to check the `application/json` media type before RED was counted. The original Phase 171 counterexample was not rerun or changed.

## Retained Verification

All Mix commands used Elixir 1.19.5, OTP 28.5 and the owned `lockspire_171_main_20261024b` database.

| Owner | Command/result |
|---|---|
| Authorization and PAR controllers/protocol | `mix test --include integration test/lockspire/web/authorize_controller_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs` — 94 tests, 0 failures. |
| Phase 15 lifecycle and configured discovery | `mix test --include integration test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/web/discovery_controller_test.exs` — 11 tests, 0 failures. Includes replay/one-use, required-PAR and auth-code plus PKCE; discovery proves configured issuer `https://example.test/lockspire` and mounted endpoints at the source-host boundary. |
| Phase 37 strictness and host seam | `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs` — 5 tests, 0 failures. |
| Phase 172 response mode | `mix test test/lockspire/web/authorize_controller_test.exs --trace --only phase172_response_mode` — 1 test, 0 failures. |
| Formatting | `mix format --check-formatted lib/lockspire/protocol/authorization_request.ex test/lockspire/protocol/authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs` — passed. |
| Strict Credo | `mix credo --strict` — 683 files, 66 checks, no issues. |
| Qualification ledger | `mix test test/lockspire/qualification_ledger_contract_test.exs` — 22 tests, 0 failures. |
| Frozen provenance | Exact plan invariant passed: `Frozen content/history preserved; owned manifest audit chain verified`. `git diff --check` passed; no tracked deletions or new stub patterns were introduced. |

## Qualification Provenance

- Existing Phase 15 test identity changed from `a1529fd15509347e9ea76fdcc3d603182c3582d9cb105c47e18d2bf0b5df69be` to `9a286e37949857ced7bdf5672d01a9d7d89c4f381d579be7aff6e9a5c3c35413`.
- The `phases-172-173-contract` roadmap selector changed from `c565ffa0bd38152b2c309ef8a9936df3499768754e95981378ab6e623e7e94f6` to `a0441aa756a8e22557b1a4f012f0ffef11537f2d109e8c4c55708f944332e266` after the Phase 173 plan entry was added.
- Two attributed records were appended; the ordered manifest digest is now `ed2ef990dd80b0eab18e3ad69400870cb54c01899464137697a6e9e3b58f371e`. The protocol unit test remains outside the manifest and was not added as a new identity.
- Phase 171 and Phase 172 verification reports list the changed authorization source as a covered input; Phase 171 also covers the Phase 15 test and ledger. Their prior reports were left untouched. Their verifier owners should regenerate them after Phase 173 completion metadata settles.

## Scope and Evidence Limits

P171-001/002/003/004/006 retain their existing owners and passed in the listed controller, Phase 15, Phase 37 and discovery runs. The three fallback assumptions remain unresolved and flagged: generic interruption/parallel behavior for PARB-01, the unclassified PARB-02 edge, and generic external-profile interruption/parallel behavior for PARB-03. Both descriptor-less prohibitions remain flagged-unverified; no human approval or universal claim was inferred.

External provider-origin, TLS, proxy and browser profiles remain unavailable, unlaunched, supplemental and non-certifying. No package, candidate/CI, certification or delivery result is claimed; Phase 174 owns those items. The changed paths add no endpoint, schema, dependency, auth path or host-policy surface.

## Task Commits

1. **Task 1 RED test:** `d23e05f0` — `test(173-01): prove pushed scope authority before correction`
2. **Task 1 correction:** `a15e3974` — `fix(173-01): honor stored parameters for pushed authorization`
3. **Task 2 ledger audit:** `88f6bb3d` — `docs(173-01): audit owned qualification inputs`

## Deviations from Plan

None - plan executed exactly as written. The JSON media-type helper was adapted to Phoenix's emitted charset suffix before the valid RED/GREEN sequence.

## Issues Encountered

The initial RED attempt failed before consent because the test helper expected an exact Content-Type header without Phoenix's charset parameter. The assertion was corrected to recognize `application/json`; the next run proved the reference-only control before the intended candidate HTTP 400 failure.

## Next Phase Readiness

The selected Phase 173 source behavior and retained source-host checks are complete. Phase 171 and Phase 172 verifier owners need to refresh their covered-file reports after the final completion metadata audit. Phase 174 remains responsible for packaged proof, candidate/CI and delivery.

## Self-Check: PASSED

- Summary file exists at the canonical phase path.
- Task commits `d23e05f0`, `a15e3974`, and `88f6bb3d` are ancestors of the current HEAD.
- `gsd-tools check evaluation-scope --plan 173-01 --commits-only --raw` resolved the plan and found all three plan commits on this branch.

---
*Phase: 173-conditional-par-profile-boundaries*
*Completed: 2026-10-24*

## Post-Execution Prohibition Lifecycle — 2026-10-24

The initial verifier returned human_needed solely for the two automatically unresolved prohibition items, after verifying all six behavioral truths. The original report is preserved in git. A subsequent canonical-contract review classifies both as resolved/judgment, supported by scoped independent reviews under the user's delegated autonomous authority. See 173-DISPOSITIONS.md. **unverified-prohibition — human review recommended (2 items).** These non-authoritative judgments are not mechanical verification or human confirmation; all three generic edge assumptions retain their unresolved provenance. The verification owner must regenerate the report under the documented autonomous judgment soft-gate. No runtime or test code changed for this lifecycle correction.
