---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "05"
subsystem: auth
tags: [elixir, oauth, token-exchange, storage, postgres]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Fixed DCR lifetime and transaction-authority contracts
  - phase: 164-client-secret-expiry-atomic-rotation
    provides: Shared-secret expiry and atomic token lifecycle behavior
  - phase: 165-management-token-lifecycle-recovery
    provides: Management-token lifecycle and recovery contracts
provides:
  - User-approved client_store and transaction_store application selectors with Repository defaults
  - Production token-route selection with shared-authority validation and fail-closed rejection
affects: [phase-166-custom-store-proof, client-lifetime-guidance]
actuals:
  tokens: 3286
  tasks: 2
  commits: 3
commits: 3
plan_head_before: 36bedc9185db721f8d76179d839f439c9b75036f
plan_head_after: 2ac5c9700aecd53d2cdb31b39867efb4333c0082
tech-stack:
  added: []
  patterns:
    - Config selector getters preserve explicit invalid values so protocol adaptation fails closed
    - Selected client and transaction stores declare one authority with actual participant modules
key-files:
  created:
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-SELECTOR-DECISION.json
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-05-RED-EVIDENCE.json
    - test/integration/client_lifetime_selected_store_test.exs
  modified:
    - lib/lockspire/config.ex
    - lib/lockspire/web/controllers/token_controller.ex
    - test/lockspire/config_test.exs
key-decisions:
  - "Record the user's explicit approval for :client_store and :transaction_store, each defaulting to Lockspire.Storage.Ecto.Repository."
  - "Keep custom-store support scoped to a matching shared PostgreSQL transaction authority; retain built-in token, audit, policy, and other protocol stores."
patterns-established:
  - "Production token routing obtains the client and transaction adapters through Lockspire.Config while keeping other stores on Repository."
requirements-completed: [DCR-17, DCR-18, DCR-19]
coverage:
  - id: D1
    description: "The approved client and transaction selectors default to Repository and work through real token HTTP issuance."
    requirement: DCR-17
    verification:
      - kind: unit
        ref: test/lockspire/config_test.exs#client and transaction store selectors
        status: pass
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs#configured store callbacks participate in production token issuance
        status: pass
    human_judgment: false
  - id: D2
    description: "Unsupported selector values and mismatched transaction authority return server_error before code redemption."
    requirement: DCR-18
    verification:
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs#invalid and mismatched store tests
        status: pass
    human_judgment: false
  - id: D3
    description: "The narrowed host selection contract is explicit and its scoped support claim is retained for guidance work."
    requirement: DCR-19
    verification:
      - kind: other
        ref: .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-SELECTOR-DECISION.json
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-10-22
status: complete
---

# Phase 166 Plan 05: Configured Client and Transaction Store Selection Summary

**User-approved `client_store` and `transaction_store` selectors now drive real token issuance, preserve the Repository defaults, and reject unsupported or mismatched storage authority before consuming authorization codes.**

## Performance

- **Duration:** Approximately 4 minutes.
- **Started:** 2026-10-22T00:39:37Z.
- **Completed:** 2026-10-22T00:44:02Z.
- **Tasks:** 2/2.
- **Files modified or created:** 6, including the RED evidence receipt.

## Accomplishments

- Recorded the user's response, “what do u recommend? do that,” as approval of the recommended `:client_store` and `:transaction_store` keys. Both default to `Lockspire.Storage.Ecto.Repository`; support remains limited to the named PostgreSQL-delegating composition with a matching shared authority.
- Added `Lockspire.Config.client_store/0` and `transaction_store/0`. Explicit unsupported values pass through to protocol adaptation and fail closed instead of falling back to `Repository`.
- Wired the selected client and transaction stores into production `/token` exchange. Existing token, audit, interaction, policy, replay, device, CIBA and key stores remain on `Repository`; internal dependency modules remain private.
- Proved selected client lookup, client locking and transaction callbacks execute during successful routed issuance. Invalid module selection and mismatched authority both return `server_error` while preserving the authorization code and token rows.

## Verification

Used Elixir 1.18.4 / OTP 27.3.4.15 and the dedicated PostgreSQL test database.

- Plan command: `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/lockspire/config_test.exs test/integration/client_lifetime_selected_store_test.exs test/lockspire/protocol/token_exchange/dependencies_test.exs --max-failures 1 --timeout 55000` — **18 tests, 0 failures**.
- Routed integration selection — **3 tests, 0 failures**; configured callbacks were observed and both rejection cases left the code unredeemed.
- RED evidence: the invalid-selector target failed before implementation because the route returned `200` instead of `500`. Native ExUnit output is not a supported classifier format, so the unchanged raw report was retained and parsed into TAP without altering the target name or assertion values; `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- `mix format` and `git diff --check` passed.

## Task Commits

1. **166-05-01: Decide the precise new public selection contract** — `f297c2da` (`docs`).
2. **166-05-02 RED: Verify configured token store composition** — `7665e80c` (`test`).
3. **166-05-02 GREEN: Select stores in token issuance** — `2ac5c970` (`feat`).

## Files Created/Modified

- `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-SELECTOR-DECISION.json` — explicit user response, chosen selectors, keys and confirmation time.
- `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-05-RED-EVIDENCE.json` — raw ExUnit report and classifier-validated TAP adaptation.
- `lib/lockspire/config.ex` — documented selector accessors and Repository defaults.
- `lib/lockspire/web/controllers/token_controller.ex` — configured client and transaction stores passed to token exchange.
- `test/lockspire/config_test.exs` — default, explicit and malformed-value selector behavior.
- `test/integration/client_lifetime_selected_store_test.exs` — routed callback participation, issuance and fail-closed authority checks.

## Decisions Made

- Adopt the user's approved narrow selectors and retain Repository as the default for each.
- Keep the support claim to the named shared PostgreSQL-delegating composition; do not expose internal dependency adapters or add a generalized store registry.

## Deviations from Plan

**1. [Rule 3 - Blocking] Adapted native ExUnit RED output for the TDD evidence classifier.**
- **Found during:** Task 2 RED phase.
- **Issue:** The configured classifier accepts TAP, JUnit XML, Swift Testing, Python `unittest`, and Go output, but not native ExUnit output.
- **Fix:** Retained the unchanged ExUnit report and generated a TAP representation from the exact named failure and status assertion; the classifier confirmed `RED_EVIDENCE_OK`.
- **Files modified:** `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-05-RED-EVIDENCE.json`.
- **Verification:** The original run reported the named assertion failure (`left: 200`, `right: 500`); the classifier matched the target and returned `RED_EVIDENCE_OK`.
- **Committed in:** `7665e80c`.

**Total deviations:** 1 process adaptation. **Impact:** No production scope change; the test-first evidence remains machine checked and preserves the original report.

## Issues Encountered

- Initial fixture references used unqualified nested module names. The integration run exposed the mismatch; the fixtures were corrected to reference their full module names before the GREEN verification passed.
- The execution workspace blocked writes to Git metadata under its default sandbox. The task commits were recorded through the approved Git metadata escalation; only plan-specific files were staged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 166-06 can use the approved selectors for configured replacement-path proof. It must retain the matching shared authority and Repository defaults established here. This plan covers issuance selection only; it does not claim that the full DCR-17–19 phase gates are complete.

## Self-Check: PASSED

- Selector decision receipt, RED evidence, implementation and tests exist in the worktree.
- Task commits `f297c2da`, `7665e80c` and `2ac5c970` are ancestors of the plan head.
- The focused command and all plan-level success criteria passed.
- Parent-owned `.planning/STATE.md`, `.planning/state.json` and `.planning/ROADMAP.md` were not staged or edited by this plan executor.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-22*
