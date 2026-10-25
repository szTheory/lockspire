---
phase: 172-authorization-responses
plan: "01"
subsystem: auth
tags: [oauth, oidc, phoenix, elixir, response-mode, pkce]

requires:
  - phase: 171-accepted-baseline-finding-qualification
    provides: Frozen A171-003 counterexample plus existing callback, state, and silent-authentication proof owners.
provides:
  - Unsupported binary response_mode uses the existing browser error disposition and returns HTTP 400 without a callback redirect.
  - Durable Router regression proves valid query-mode host handoff and unsupported-mode behavior; PAR retains OAuth JSON errors.
  - Selective manifest audits for the controller test and Phase 172–173 roadmap selector, with historical qualification bytes preserved.
affects: [phase-172-verification, phase-173-conditional-par]

actuals:
  tokens: 2113
  tasks: 2
  commits: 5
commits: 5
plan_head_before: 6e1606519ce767ea90a1469a5639ff23d623539f
plan_head_after: a615410b4c86d5a37437b24afe490ee67580b7be

tech-stack:
  added: []
  patterns:
    - Unsupported protocol values use the existing browser_error/3 disposition when the callback must not receive an OAuth Error Response.
    - A source-bound Router test runs a valid control before the candidate request.
    - Frozen qualification inputs are reconciled with ordered manifest digests and append-only old/new audits.

key-files:
  created: [.planning/phases/172-authorization-responses/172-01-SUMMARY.md]
  modified:
    - lib/lockspire/protocol/authorization_request.ex
    - test/lockspire/web/authorize_controller_test.exs
    - test/lockspire/web/pushed_authorization_request_controller_test.exs
    - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json

key-decisions:
  - "Unsupported binary response_mode is classified with browser_error/3, retaining invalid_request, the static description, and invalid_response_mode reason code."
  - "The supported-mode allow set, defaults, JWT normalization, strict-signing rejection, PAR normalization, and host login policy remain unchanged."

patterns-established:
  - "For protocol corrections, prove the valid neighboring control before asserting the selected failure response through the production Router."
  - "When ExUnit console output is unsupported by the RED classifier, adapt the unchanged named result to TAP and retain the raw trace for semantic review."

requirements-completed: [AUTHR-01, AUTHR-02, AUTHR-03]
coverage:
  - id: D1
    description: Unsupported response_mode returns a first-party HTTP 400 with no Location or structured OAuth response parameters after a valid query-mode host handoff.
    requirement: AUTHR-02
    verification:
      - kind: integration
        ref: test/lockspire/web/authorize_controller_test.exs#A171-003 unsupported response_mode returns a first-party HTTP 400 after a valid query control
        status: pass
    human_judgment: false
  - id: D2
    description: POST /par keeps unsupported response_mode as HTTP 400 OAuth JSON and creates no pushed request.
    requirement: AUTHR-02
    verification:
      - kind: integration
        ref: test/lockspire/web/pushed_authorization_request_controller_test.exs#POST /par keeps unsupported response_mode errors as OAuth JSON
        status: pass
    human_judgment: false
  - id: D3
    description: Existing exact-redirect, callback-state, prompt=none, max_age, fresh auth_time, strict-signing, and JWT-mode owners pass at current source.
    requirement: AUTHR-01
    verification:
      - kind: integration
        ref: test/integration/phase37_protocol_strictness_e2e_test.exs (5 tests)
        status: pass
      - kind: integration
        ref: test/lockspire/protocol/authorization_request_test.exs and test/lockspire/protocol/pushed_authorization_request_test.exs (included in focused four-suite run)
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-10-24
status: complete
---

# Phase 172 Plan 01: Authorization Response Summary

**Unsupported `response_mode` now reaches the existing first-party HTTP 400 path, while a valid query control, PAR JSON behavior, and the qualified authorization cases remain intact.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-24T22:46:46Z
- **Completed:** 2026-10-24T22:52:19Z
- **Tasks:** 2
- **Files modified or created:** 5

## Accomplishments

- Changed only the unsupported binary mode disposition in `AuthorizationRequest.validate_response_mode/1` to the existing `browser_error/3` helper. The controller and HTML renderer remain unchanged.
- Added the exact OIDC Router regression. Its query-mode control reached `/sign-in` with `source=authorize`, a nonempty `interaction_id`, and `return_to` under `/lockspire/consent/`. The binary candidate returns HTTP 400, `text/html`, no `Location`, and no JSON, form, or encoded query-style OAuth response parameters.
- Added the PAR preservation regression: unsupported mode remains HTTP 400 `application/json` with `invalid_request`, the static description, no `Location`, no-store/no-cache headers, and no new pushed-request row.
- Reconciled only the controller test and Phase 172–173 roadmap selector hashes in the frozen Phase 171 ledger.

## Source-Bound RED/GREEN Evidence

The pre-fix run used the owned Elixir 1.19.5 / OTP 28.5 runtime and database:

```text
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/web/authorize_controller_test.exs --trace --only phase172_response_mode
```

- **RED:** exit 2; the named test executed, its valid query-mode handoff assertions passed, and the candidate failed at `assert binary_conn.status == 400`: actual 302, expected 400. ExUnit reported `1 test, 1 failure (24 excluded)` in 0.2s. This was a normative assertion failure, not setup, fixture, compilation, or database failure.
- **RED source identity:** HEAD `6e1606519ce767ea90a1469a5639ff23d623539f`; production file SHA-256 `941e92750677f815243ca9b40792f878693983bbcbd14ae5d738cd102c05aa82`; regression file SHA-256 during the RED run `3cbde05e5f3d2c6bde6dc4f7a51133bc7df72d8087d064650c01f01ebd4371e4`.
- **Classifier:** the initial checker invocation rejected raw ExUnit output as an unsupported report format. A temporary ExUnit-trace-to-TAP parser adapter preserved the raw trace and mapped the single identified failed assertion; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`, `target_test_failed`, exit 2. The temporary record was removed after classification.
- **GREEN:** the identical tagged test command passed after the correction: `1 test, 0 failures (24 excluded)` in 0.2s. It passed again on the final formatted regression at HEAD `d7fa46e209a71b25ab8ab380f2ad707d494f329c`, with the same one-test result. Final production file SHA-256 is `2279206b3c3b27b5f1526b426863089b81b06883d586a97aa3e90fd8cc320e3a`; final regression file SHA-256 is `92d53caee7c915ffddde13ce1181fb10c19d0d1c778be7c976cd12dc5e19bf05`.

The historical Phase 171 probe remains qualification evidence only. It records the earlier source `30e385a33bb2a7f67d94c558dedf7691ecde5863` and was not relabeled as a Phase 172 run.

## Preserved Authorization Evidence

| Qualified case | Current owner exercised | Result |
|---|---|---|
| A171-001 exact callback | `phase37_protocol_strictness_e2e_test.exs#exact redirect_uri mismatches stay on the browser-safe surface` | Pass |
| A171-002 callback error/state | `authorize_controller_test.exs#redirect-safe validation failures redirect with oauth error params and preserved state` | Pass in focused suite |
| A171-004 prompt none | `phase37_protocol_strictness_e2e_test.exs#prompt=none with no visible host session returns login_required without host login redirection` | Pass |
| A171-005 stale freshness | `phase37_protocol_strictness_e2e_test.exs#prompt=none plus stale auth_time under max_age returns login_required` | Pass |
| A171-006 fresh auth_time | `phase37_protocol_strictness_e2e_test.exs#fresh auth emits integer auth_time in the ID token when max_age or explicit auth_time demand is present` | Pass |

The supported/default, strict-signing, JWT response-mode, and PAR validation owners also passed in the focused suites. Phase 37 ran with `--include integration`: 5 tests, 0 failures (0.2s). The four focused controller/protocol suites, including integration-tagged tests, ran after formatting: 94 tests, 0 failures (1.3s). The Phase 37 integration run is separate from that 94-test run.

## Validation and Ledger Audit

- Formatter check for the three edited Elixir files: pass.
- `mix credo --strict`: pass; 683 source files, 8,333 modules/functions, no issues.
- `mix test test/lockspire/qualification_ledger_contract_test.exs`: pass; 22 tests, 0 failures (8.6s).
- Frozen-content check against ledger baseline `ce11a5a74384e42328dc2aa3b7f06db539cf896e`: pass. Cases, requirement dispositions, receipt/probe bytes, audit prefix, `matrix.frozen_at=2026-10-24T20:49:46Z`, and `matrix.qualification_sha=6d9a5db65f8cc3cb8c64ea0dd51ad022a6b18945` were preserved.
- Ordered manifest `input_digest`: `c20ab6075973d27eb0e15d9de70910fd25ddde8bf2e5864d653cd1fab3e73c93` → `294a30ba5593c55ecb35e475f3e9f26897bbc448b15d4d90cc3d22b271d7da0c`.

| Input | Previous SHA-256 | Current SHA-256 | Reason |
|---|---|---|---|
| `test/lockspire/web/authorize_controller_test.exs` | `382ce013af67d40df21f12d49e4918a9442b8bae52d788becdd92ebc8edd6590` | `92d53caee7c915ffddde13ce1181fb10c19d0d1c778be7c976cd12dc5e19bf05` | Added the durable A171-003 Router regression and query control. |
| `.planning/ROADMAP.md#phases-172-173-contract` | `f064cef43676cc0db066ecfcb321f6e2351a1c08b0fe137f13e34d1c812ec9af` | `029eb665d728efda5ea6d348ac562d2e7948e7ed881170b55b4a2ced6ea2b08f` | Reconciled the planning selector after the Phase 172 plan/count update in `6e160651`; the roadmap was otherwise clean. |

No other manifest identity differed from its current input. All changes, including the ledger, pass `git diff --check`.

## Task Commits

1. **172-01-01 RED:** `3920a860` — add failing unsupported response-mode Router regression.
2. **172-01-01 GREEN:** `2f9bd3ad` — classify unsupported mode as a browser error.
3. **172-01-01 PAR preservation:** `6225876d` — retain PAR OAuth JSON error behavior.
4. **172-01-01 formatting:** `d7fa46e2` — format the new response assertions.
5. **172-01-02 ledger audit:** `a615410b` — reconcile only the two reviewed manifest identities.

## Decisions Made

- Used the existing protocol `browser_error/3` and controller HTML path. This keeps callback parameters out of the browser error response while preserving the current static explanation and reason code.
- Kept the strict signing rejection and pushed-request normalization unchanged; the PAR test verifies its separate backchannel representation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected the browser error helper arity.**
- **Found during:** Task 172-01-01 GREEN compile.
- **Issue:** The first implementation attempt called nonexistent `browser_error/4`; the existing helper is `browser_error/3` and intentionally carries no callback or state.
- **Fix:** Removed the params argument and retained the existing error, description, and reason code.
- **Files modified:** `lib/lockspire/protocol/authorization_request.ex`.
- **Verification:** The identical tagged Router regression passed after correction.
- **Committed in:** `2f9bd3ad`.

**Total deviations:** 1 auto-fixed blocking issue. **Impact:** Corrected the implementation to the existing safe helper; no scope or API expansion.

## Issues Encountered

The generic RED evidence checker does not parse ExUnit console output. The temporary TAP adapter was derived from the actual trace and accepted the exact target failure; no dependency or persistent test tooling was added. The first formatter check reported only line wrapping in the new assertions; the formatter corrected it and the final format check passed.

## Known Stubs

None.

## Threat Flags

None. The change alters only the existing protocol error disposition; it adds no network endpoint, authorization path, file access pattern, or schema boundary.

## Next Phase Readiness

The scoped runtime correction, source-bound RED/GREEN, existing case checks, and frozen-ledger audit are ready for independent Phase 172 verification. `A-EDGE-AUTHR-03` and both descriptor-less prohibitions remain flagged-unverified; passing ExUnit does not dispose of them. Phase 171 historical observation, acceptance, and optional-profile claims remain unchanged.

## Self-Check: PASSED

- Summary file exists.
- All five task commits are ancestors of the current HEAD.
- Final production, regression, PAR test, and qualification ledger files exist with the source identities recorded above.

---
*Phase: 172-authorization-responses*
*Plan: 172-01*
*Completed: 2026-10-24*
