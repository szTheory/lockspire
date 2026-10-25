---
phase: "174"
slug: "packaged-proof-delivery-handoff"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-24"
---

# Phase 174 — Validation Strategy

## Test Infrastructure

Existing ExUnit, Python acceptance helpers, package binding, maintainer authority and seven-job CI train. No framework/dependency install. Every source Mix command uses `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b`; clean-room runners retain their own random run-owned DBs/ports/temp directories.

Quick feedback uses focused current source owners and Python runner checks. Package proof must use an actual archive through the existing package-clean host machinery. The selected-case scenario interface/receipt does not exist yet: planner must name exact new symbols/flags and verify creation before invocation. Full candidate gate is local `mix ci` plus all seven required hosted jobs on the exact candidate head; main acceptance is conditional on actual reviewed integration.

## Sampling Rate

- Per implementation task: focused checks appropriate to the changed harness/fixture/receipt or guidance.
- First vertical slice: a real packaged request/control with bound archive/tree/vendor/resolved/compiled evidence before case expansion.
- After final shipped inputs settle: all applicable selected package cases and current source owners, redaction/cleanup/receipt checks, current verifier/security owners, then complete candidate gates.
- Planning-only completion changes receive deliberate owner freshness review. Never reconstruct historical receipts, relabel prior RED/GREEN or rerun the historical deliberate-RED probe as a green gate.

## Per-Task Verification Map

Planner must replace provisional identifiers and planned interfaces with actual tasks, threat references and runnable commands with stated failure signals.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| provisional-174-package | pending | pending | CPROOF-01, CPROOF-02 | pending | Package-clean real HTTP proves selected projections with safe controls and narrow host fixtures | Package HTTP / contract | Existing clean_room_saas_journey.py with new bounded group; exact interface to be planned | Existing machinery; new group/index missing | pending |
| provisional-174-candidate | pending | pending | CPROOF-01, CPROOF-02, DELIV-01 | pending | Current source/package evidence and verifier/security owners; complete exact-head candidate gates | ExUnit/Python/full contributor/hosted CI | Prefixed focused owners and `mix ci`; exact-SHA seven-job inspection | Existing owners/CI; new evidence pending | pending |
| provisional-174-delivery | pending | pending | DELIV-01, DELIV-02 | pending | Exact PR/main/blocker truth, owned cleanup and explicit historical retention/ranking | Authority/identity/artifact review | Existing train and conditional exact-main acceptance with actual required WARN dispositions | Existing authority; current handoff missing | pending |

## Wave 0 Requirements

- [ ] Bounded selected-case group and validated evidence index/receipt keyed by the frozen twelve IDs
- [ ] Synthetic host fixture email scope and host-supplied authentication-time capability where needed
- [ ] Exact package input/runner commands and artifact paths defined before execution
- [ ] Current prior verifier-owner refresh path, preserving historical outputs and judgment lifecycle
- [ ] Dated handoff with exact package/candidate/CI/main or blockers and resource custody

## Manual-Only Verifications

Review judgments retain their declared non-authoritative flags in autonomous mode. They are not fabricated mechanical coverage or human confirmation. Actual required reviewer/integration approvals remain governed by the existing train; record concrete blockers only after the work is reviewable. Publication and unavailable external profiles are unselected, not waived selected behavior.

## Validation Sign-Off

- [ ] Every selected case has an existing source owner and applicable package projection
- [ ] Actual plan IDs/threats/commands mapped; no three-task automated sampling gap
- [ ] Package identity, redaction and owned cleanup verified; historical evidence unchanged
- [ ] Prior/current verifier owners and focused security reflect actual covered inputs
- [ ] Complete local and hosted candidate gates observed at exact identities
- [ ] Main/delivery and retained-resource handoff is exact and honest
- [ ] Final audit sets status/Nyquist fields from actual evidence and remaining limitations

Approval: pending execution and audit.
