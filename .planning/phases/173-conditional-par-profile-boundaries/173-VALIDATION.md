---
phase: "173"
slug: "conditional-par-profile-boundaries"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-24"
---

# Phase 173 — Validation Strategy

## Test Infrastructure

Existing ExUnit, Phoenix.ConnTest, integration fixtures and ledger contract suffice. No install, migration or framework change. Prefix every Mix invocation with `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b`.

Quick feedback: tagged new Phase 15 PAR integration regression with `--include integration`. Shared checks: Phase 15 integration, authorization-request protocol, pushed-authorization-request protocol and authorization/PAR controllers. Retained metadata owner: discovery controller. Ledger contract, strict Credo and edited-file formatting are phase gates. Focused feedback target below 60 seconds; record actual timing.

## Sampling Rate

- New candidate must fail normatively before production correction after a valid independently pushed control. Record source/file identities and actual assertion/output; setup/replay failures do not establish RED.
- Run identical regression after correction and retained shared-path owners before task completion.
- Run ledger after selective reviewed test/roadmap hash reconciliation. Final completion metadata can require another audit and verification-owner regeneration.
- No old intentional-RED probe, optional profile or baseline acceptance rerun is part of the green command.

## Per-Task Verification Map

Planner must replace provisional rows with actual task IDs, commands and threat references.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| provisional-173-authority | pending | 1 | PARB-01, PARB-02 | pending | Independent real PAR control and conflict candidate preserve pushed client/scopes/state/nonce; actual RED/GREEN | Router/integration | Prefixed `mix test --include integration test/integration/phase15_par_authorization_e2e_test.exs` with new tag | Existing file; new regression pending | pending |
| provisional-173-preservation | pending | 1 | PARB-01, PARB-02, PARB-03 | pending | Preserve binding/expiry/one-use/required-PAR/PKCE/current policy and configured metadata | Protocol/controller/integration | Prefixed selected owner suites including discovery and Phase 172 response-mode regression | yes | pending |
| provisional-173-provenance | pending | 1 | PARB-01, PARB-02, PARB-03 | pending | Only reviewed current input identities change; historical receipt/probe/cases preserved | Contract | Prefixed `mix test test/lockspire/qualification_ledger_contract_test.exs` plus preservation invariant | yes | pending |

## Wave 0 Requirements

Existing infrastructure covers all selected requirements. No missing framework/config. New regression belongs in existing implementation work.

## Manual-Only Verifications

All selected behavior has automated owners. Unavailable external transport/browser profiles are supplemental and unselected, not manually waived selected behavior. Review audit ownership and actual evidence identities.

## Validation Sign-Off

- [ ] Plan task IDs, threats and executable commands mapped
- [ ] All tasks have automated verification, no three-task sampling gap
- [ ] Actual normative RED and identical-test GREEN recorded
- [ ] Shared lifecycle/policy/metadata behavior preserved
- [ ] Historical evidence preserved and selective ledger audit passes
- [ ] Actual timings recorded; final validation audit sets status and Nyquist fields

Approval: pending execution and audit.
