---
phase: "175"
slug: "accepted-baseline-verifier-compatibility-contract"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-25"
---

# Phase 175 — Validation Strategy

> Eight tasks are planned across three sequential waves. All execution evidence remains pending; structural plan checks do not qualify runtime, native-age policy, metadata support or accepted main.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit with PostgreSQL integration; existing exact-main helper and narrow Python metadata checks |
| Config file | mix.exs, test/test_helper.exs, config/test.exs |
| Quick run command | `mix test test/lockspire/security/client_secret_verifier_compatibility_test.exs` (created by 175-02-02) |
| Focused persisted command | `MIX_ENV=test mix test --include integration test/integration/client_secret_jwt_legacy_age_test.exs` (created by 175-02-01) |
| Full suite command | `mix ci` |
| Runtime | Measure during execution; focused caller tests must provide prompt feedback; exact-main helper is a separate long-running acceptance gate |

## Sampling Rate

- After each qualification change: run its narrow test and contract validation.
- After each plan wave: run focused changed tests; before verification run `mix ci`.
- Initial baseline acceptance precedes qualification edits. Final tested-source acceptance follows qualification/contract reconciliation, using the same existing helper in an owned clean checkout. No local test result substitutes for accepted-main evidence.
- Target feedback latency: focused checks under 30 seconds, with actual timings recorded; full contributor/hosted gates may take longer.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 175-01-01 | 01 | 1 | VBASE-01 | T-175-01, T-175-02 | Reviewed lineage, immutable exact receipt, synchronized main, local/hosted no-publish gates | existing acceptance helper | `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha "$ACCEPTED_SHA" "${EXACT_WARN_ARGS[@]}" --format json` | helper tracked; receipt pending | pending |
| 175-01-02 | 01 | 1 | VBASE-01 | T-175-01, T-175-02, T-175-03 | Receipt preservation, complete custody and final checkout state | digest/metadata assertions + reviewed custody | Exact Python byte/digest/status/identity assertions in task 175-01-02 | historical receipt tracked; new evidence pending | pending |
| 175-02-01 | 02 | 2 | VBASE-02 | T-175-04, T-175-07 | Persisted caller age/lifecycle distinctions and durable effects with independent clocks/JTIs | PostgreSQL integration | `MIX_ENV=test mix test --include integration test/integration/client_secret_jwt_legacy_age_test.exs` | created in this task before verify | pending |
| 175-02-02 | 02 | 2 | VBASE-02 | T-175-05, T-175-06 | Public authenticated metadata, historical shapes and original finite deadline; helper compatibility | focused ExUnit + PostgreSQL caller | `mix test test/lockspire/security/client_secret_verifier_compatibility_test.exs`; same persisted command as 175-02-01 | focused file created in this task before verify | pending |
| 175-02-03 | 02 | 2 | VBASE-02 | T-175-06 | Explicit native-age/public-metadata policy gates; no silent validity extension | material gate assertion + GSD revision when needed | Exact Python material_gates/approved-policy/dependent_planning assertions in task 175-02-03 | qualification record created in 175-02-01/02 | pending — execution blocking |
| 175-03-01 | 03 | 3 | VBASE-02 | T-175-08, T-175-10 | Qualified exact config/format/helper contract and evidence lineage | finite ledger semantic validator + compatibility regression | `mix test test/lockspire/security/client_secret_verifier_contract_test.exs test/lockspire/security/client_secret_verifier_compatibility_test.exs` | validator created in this task before verify | pending |
| 175-03-02 | 03 | 3 | VBASE-02 | T-175-09, T-175-10, T-175-11 | Store authority, exhaustive inventory, atomic preservation, fingerprint/JTI and disclosure proof ownership | finite ledger contradiction/completeness validation | `mix test test/lockspire/security/client_secret_verifier_contract_test.exs` | created by 175-03-01 | pending |
| 175-03-03 | 03 | 3 | VBASE-01, VBASE-02 | T-175-01, T-175-06, T-175-10 | Final tested/accepted source reconciliation and material-gate agreement | full contributor gate + existing helper + exact metadata/digest assertions | `mix ci`; `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha "$FINAL_ACCEPTED_SHA" "${FINAL_EXACT_WARN_ARGS[@]}" --format json`; exact Python final-source assertions in task | helper tracked; final metadata/receipt pending | pending |

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

- VBASE-01 unclassified edge remains an explicit unresolved flagged assumption; baseline helper/custody review is its concrete audit route, not an automatic probe resolution.
- VBASE-02 adjacency, empty and ordering edges have explicit must-have predicates in 175-03: distinct equality semantics/case identity, absent/empty/null/singleton/partial outcomes and stable bounded inventory continuation/completion.
- Three bespoke prohibitions are descriptor-less `projectProhibitions` projections, all unresolved/flagged-unverified. They require honest verifier review; no check descriptors or passing judgments are invented.
- Exact public config/format/helper/maintenance contracts freeze during execution only after material qualification. Future-owned runtime/maintenance/package proof rows remain pending and do not expand Phase 175 into implementation.

## Validation Sign-Off

- [x] Final plan task IDs/commands and threat references populated (planning artifact only)
- [ ] Every task has automated verify or explicit Wave 0 dependency
- [ ] No three consecutive tasks lack automated verification
- [ ] Wave 0 covers all missing test references
- [ ] No watch flags; focused timings recorded
- [ ] Fresh exact-main helper evidence accepted
- [ ] Material native/migrated age qualification disposition recorded
- [ ] `nyquist_compliant: true` set only with execution evidence

**Approval:** pending execution
