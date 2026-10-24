---
phase: "172"
slug: "authorization-responses"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-24"
---

# Phase 172 — Validation Strategy

## Test Infrastructure

Existing ExUnit, Phoenix.ConnTest and integration infrastructure covers this phase. No installation or configuration change is needed. Every Mix command uses `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b`.

Quick check: `mix test test/lockspire/web/authorize_controller_test.exs` with that prefix. Shared-path checks: `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs`. Phase gate adds `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs`, the existing qualification ledger contract, strict Credo, and formatting for edited Elixir files. Estimated focused feedback is under 60 seconds; record actual timings during execution.

## Sampling Rate

- Run the named new HTTP regression before the production correction and afterward. Record actual RED/GREEN output and source/file identities.
- After the implementation task, run controller, authorization-request and pushed-authorization-request suites.
- Before completion, verify relevant integration, ledger integrity, strict lint and formatting. Historical Phase 171 observations do not count as execution at new source.

## Per-Task Verification Map

Planner must replace provisional task identifiers with actual plan task IDs and threat references before sealing the plan.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| provisional-172-implementation | pending | 1 | AUTHR-01, AUTHR-02 | pending | Unsupported mode returns HTTP 400 with no callback or structured OAuth parameters; valid query control preserves host handoff | Router/controller | Prefixed controller suite above, named regression for RED/GREEN | Existing file; new regression pending | pending |
| provisional-172-preservation | pending | 1 | AUTHR-01, AUTHR-02, AUTHR-03 | pending | Preserve exact redirects, supported/strict modes, PAR normalization, silent auth and freshness | Unit/integration | Prefixed shared-path suites and Phase 37 integration above | yes | pending |
| provisional-172-provenance | pending | 1 | AUTHR-01, AUTHR-02, AUTHR-03 | pending | Selectively audit intentional frozen-input changes; preserve original receipt, cases and probe | Contract | Prefixed `mix test test/lockspire/qualification_ledger_contract_test.exs` | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The new regression is implementation work in an existing suite, not a missing framework. No external profile preparation/run is selected.

## Manual-Only Verifications

All selected runtime behaviors have automated verification. Review selective manifest changes against declared ownership and unchanged historical identities; retain actual command evidence.

## Validation Sign-Off

- [ ] Actual plan task IDs and threat references mapped
- [ ] Every task has automated verification; no three consecutive tasks without it
- [ ] Actual regression RED/GREEN recorded
- [ ] Shared modes, host seam and ledger preservation verified
- [ ] No watch-mode flags; focused feedback timings recorded
- [ ] Validation audit sets final status and Nyquist fields from evidence

Approval: pending execution and audit.
