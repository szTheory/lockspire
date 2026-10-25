---
phase: "175"
slug: "accepted-baseline-verifier-compatibility-contract"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-25"
---

# Phase 175 — Validation Strategy

> Eight tasks were verified across three sequential waves. Candidate `4fa03cefd18894e25d3777187e5f00e773a2b18a` passed its recorded gates. Entry-main acceptance remains `173059a166e9ade0f5f57c9980b7b2400a98538c`; final integrated-main acceptance remains Phase 178 work. Future 176–178 runtime proof rows remain pending by design.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit with PostgreSQL integration; existing exact-main helper and narrow Python metadata checks |
| Config file | mix.exs, test/test_helper.exs, config/test.exs |
| Quick run command | `mix test test/lockspire/security/client_secret_verifier_compatibility_test.exs` (current root and declared-floor contexts: 10 tests each, 0 failures) |
| Focused persisted command | `MIX_ENV=test mix test --include integration test/integration/client_secret_jwt_legacy_age_test.exs` (10 tests, 0 failures) |
| Full suite command | `mix ci` |
| Runtime | Elixir 1.19.5 / OTP 28.5; focused persisted caller 0.1s, compatibility 0.07s (root) / 0.1s (declared floor); candidate `mix ci` 5m55s; exact-main helper 22 PASS / 2 WARN / 0 BLOCK |

## Sampling Rate

- After each qualification change: run its narrow test and contract validation.
- After each plan wave: run focused changed tests; before verification run `mix ci`.
- Initial baseline acceptance precedes qualification edits. Candidate qualification uses exact-source CI and frozen-input reconciliation, separately from accepted-main evidence. The single final milestone PR and integrated-main helper acceptance belong to Phase 178.
- Target feedback latency: focused checks under 30 seconds, with actual timings recorded; full contributor/hosted gates may take longer.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 175-01-01 | 01 | 1 | VBASE-01 | T-175-01, T-175-02 | Reviewed lineage, immutable exact receipt, synchronized main, local/hosted no-publish gates | existing acceptance helper | `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha 173059a166e9ade0f5f57c9980b7b2400a98538c --warn-disposition 'adoption demo stopped containers=retain-demo-containers' --warn-disposition 'adoption demo volumes=retain-demo-volumes' --format json` | helper tracked; receipt `175-MAIN-ACCEPTANCE.json` | green |
| 175-01-02 | 01 | 1 | VBASE-01 | T-175-01, T-175-02, T-175-03 | Receipt preservation, complete custody and final checkout state | digest/metadata assertions + reviewed custody | Receipt-preservation Python assertions recorded in 175-01-SUMMARY; reviewed custody in `175-CUSTODY.md` | receipt and metadata tracked | green; human custody review recorded |
| 175-02-01 | 02 | 2 | VBASE-02 | T-175-04, T-175-07 | Persisted caller age/lifecycle distinctions and durable effects with independent clocks/JTIs | PostgreSQL integration | `MIX_ENV=test mix test --include integration test/integration/client_secret_jwt_legacy_age_test.exs` | created; 10 tests, 0 failures | green |
| 175-02-02 | 02 | 2 | VBASE-02 | T-175-05, T-175-06 | Public authenticated metadata, historical shapes and original finite deadline; helper compatibility | focused ExUnit + PostgreSQL caller | `mix test test/lockspire/security/client_secret_verifier_compatibility_test.exs` (root and declared-floor contexts); persisted caller command from 175-02-01 | created; initial 9 tests per context, 0 failures; post-review current suite 10 per context, 0 failures | green |
| 175-02-03 | 02 | 2 | VBASE-02 | T-175-06 | Explicit native-age/public-metadata policy gates; no silent validity extension | material gate assertion + approved policy disposition | Task 175-02-03 exact material-gate Python assertions; JSON parse and `git diff --check` | qualification and policy revision tracked | green; owner-approved revision and both material gates qualified |
| 175-03-01 | 03 | 3 | VBASE-02 | T-175-08, T-175-10 | Qualified exact config/format/helper contract and evidence lineage | finite ledger semantic validator + compatibility regression | `mix test test/lockspire/security/client_secret_verifier_contract_test.exs test/lockspire/security/client_secret_verifier_compatibility_test.exs` | created; included in combined 29/0 run | green |
| 175-03-02 | 03 | 3 | VBASE-02 | T-175-09, T-175-10, T-175-11 | Store authority, exhaustive inventory, atomic preservation, fingerprint/JTI and disclosure proof ownership | finite ledger contradiction/completeness validation | `mix test test/lockspire/security/client_secret_verifier_contract_test.exs` | created; validator 9/0; combined 29/0 | green; future runtime proof remains assigned to 176–178 |
| 175-03-03 | 03 | 3 | VBASE-01, VBASE-02 | T-175-01, T-175-06, T-175-10 | Final tested/accepted source reconciliation and material-gate agreement | full contributor gate + source/digest assertions | `mix ci`; then the exact Python final-source assertion in amended 175-03-PLAN.md | CI recorded at candidate `4fa03cefd18894e25d3777187e5f00e773a2b18a`; final-source record tracked | green; final-main acceptance deferred to 178 |

Each runnable `<automated>` in PLAN.md has an immediately following `<fails_when>` sibling. The plan command is canonical for Python assertions and dynamic warning-array construction. Missing/failed/unavailable evidence is nonzero/unmet, never green. Helper/full-suite gates may exceed 60 seconds; preserve output and keep progress updates while running. Focused checks target under 60 seconds with actual durations recorded.

## Wave 0 Requirements

- Select an installed supported Elixir/OTP pair; Mix shim currently has no selected ASDF version.
- Verify PostgreSQL readiness for persisted caller tests; no in-memory substitute satisfies them.
- Establish read access to exact GitHub CI/Release evidence before baseline acceptance.
- 175-02-01 creates authentic historical fixtures and actual persisted JWT caller tests with fresh distinct JTIs before verification.
- 175-02-02 creates public metadata/helper qualification with safe decoding and unsupported-shape dispositions; both existing dependency contexts must have observed evidence or blocking unavailability.
- 175-03-01 creates the finite JSON ledger and focused semantic validator before verification; use mutated ledger cases to reject missing/duplicate/wrong-owner/false-pass data. No generic proof framework.
- 175-01 creates evidence/custody records using the existing helper's unchanged stdout format; 175-03-03 separately reconciles final accepted source.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Retained unique work and unknown resource ownership | VBASE-01 | Identity and custodian disposition require review | Compare retained delivery delta and resource identities; retain uncertain work; annotate separately from immutable receipts |
| Native storage-age policy and scope revision | VBASE-02 | Material security-policy disposition cannot be inferred from a passing test | Record qualified caller/support effects; explicit GSD revision if needed; block Phase 176 planning while unresolved |

## Probe and Scope Dispositions

- VBASE-01 unclassified edge remains an explicit unresolved flagged assumption; baseline helper/custody review is its concrete audit route, not an automatic probe resolution. This phase's observed baseline and custody evidence are recorded; the assumption itself is not marked mechanically resolved.
- VBASE-02 adjacency, empty and ordering edges have explicit must-have predicates in 175-03: distinct equality semantics/case identity, absent/empty/null/singleton/partial outcomes and stable bounded inventory continuation/completion.
- Three bespoke prohibitions are descriptor-less `projectProhibitions` projections, all unresolved/flagged-unverified. They require honest verifier review; no check descriptors or passing judgments are invented.
- Exact public config/format/helper/maintenance contracts freeze during execution only after material qualification. Future-owned runtime/maintenance/package proof rows remain pending and do not expand Phase 175 into implementation.

## Validation Sign-Off

- [x] Final plan task IDs/commands and threat references populated (planning artifact only)
- [x] Every task has recorded automated verification or explicit human review where the behavior requires judgment
- [x] No three consecutive tasks lack automated verification
- [x] Wave 0 prerequisites and missing test references were addressed in the execution record
- [x] Focused timings and full candidate CI stage counts recorded
- [x] Fresh exact-main helper evidence accepted for entry SHA `173059a166e9ade0f5f57c9980b7b2400a98538c`
- [x] Material native/migrated age and metadata-reader qualification dispositions recorded
- [x] `nyquist_compliant: true` is based on completed task verification; Phase 176–178-owned runtime rows remain pending

**Approval:** validated against recorded execution evidence; independent phase verification remains a separate Phase 176 dispatch gate.


## Validation Audit

- Gaps found: 8 task rows were still pending in the draft; the Task 03-03 command did not match the amended plan's source reconciliation gate.
- Resolved: 8/8 task verification rows now match recorded evidence, including root/declared-floor coverage, owner-approved policy qualification, and exact candidate reconciliation.
- Escalated: 0. The VBASE-01 flagged assumption remains explicitly unresolved; 176–178-owned runtime proof rows remain pending by design.
- Candidate evidence: `4fa03cefd18894e25d3777187e5f00e773a2b18a`; entry accepted SHA: `173059a166e9ade0f5f57c9980b7b2400a98538c`; final-main acceptance deferred to Phase 178.
