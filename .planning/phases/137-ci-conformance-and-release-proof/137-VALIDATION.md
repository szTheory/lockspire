---
phase: 137
slug: ci-conformance-and-release-proof
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-27
audited: 2026-08-27
---

# Phase 137 — Validation Strategy

> Every implementation task has executable repository proof. The two remaining
> hosted acceptance checks are recorded separately because they require
> protected credentials and external state, not because test coverage is absent.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, shell/Python contract fixtures, native Erlang coverdata |
| **Config file** | `test/test_helper.exs`, `mix.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `MIX_ENV=test mix test` with the Phase 137 contract files listed below |
| **Full suite command** | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` |
| **Complete quality command** | `MIX_ENV=dev mix qa && mix deps.audit && mix docs.verify && mix package.build && mix qa.dialyzer` |
| **Estimated runtime** | Focused contracts under 15 seconds; complete partitions about 90 seconds locally |

## Sampling Rate

- **After every task commit:** Run the plan's focused ExUnit and script syntax command.
- **After every plan wave:** Run all Phase 137 contract tests plus workflow lint.
- **Before phase verification:** Run fast and integration partitions exactly once and aggregate their same-SHA coverdata.
- **Before release readiness:** Run the complete quality command, workflow lint, and repository hygiene gate.
- **Max focused feedback latency:** 15 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 137-01-01 | 01 | 1 | CI-01 | T-137-01..02 | Both routers scan and missing/broadly ignored scans fail closed | contract + real tool | `mix test test/lockspire/ci_security_dependency_contract_test.exs && bash scripts/ci/check_sobelow_routers.sh` | ✅ | ✅ green |
| 137-01-02 | 01 | 1 | CI-03 | T-137-03..04 | Unused locks and compile-connected cycles block CI | contract + real tool | `bash scripts/ci/check_dependency_truth.sh && mix test test/lockspire/architecture_fitness_test.exs` | ✅ | ✅ green |
| 137-02-01 | 02 | 1 | CI-02 | T-137-05..06 | Each partition exports one native same-SHA coverage input | contract | `mix test test/lockspire/ci_test_matrix_contract_test.exs test/lockspire/coverage_baseline_contract_test.exs` | ✅ | ✅ green |
| 137-02-02 | 02 | 1 | CI-02 | T-137-07..08 | Aggregation rejects missing, duplicate, changed, or mismatched inputs | contract | `mix test test/lockspire/ci_coverage_aggregation_contract_test.exs` | ✅ | ✅ green |
| 137-03-01 | 03 | 2 | CI-02 | T-137-09 | Protocol branches have behavior-oriented coverage | behavior | `mix test test/lockspire/coverage/protocol_behavior_test.exs` | ✅ | ✅ green |
| 137-03-02 | 03 | 2 | CI-02 | T-137-10 | Integration boundary branches have behavior proof | behavior | `mix test test/lockspire/coverage/integration_surface_behavior_test.exs` | ✅ | ✅ green |
| 137-03-03 | 03 | 2 | CI-02 | T-137-11..12 | Storage/operator absences and aggregate floor are proven | behavior + aggregate | `mix test test/lockspire/coverage/storage_operator_behavior_test.exs` plus native aggregate | ✅ | ✅ green |
| 137-04-01 | 04 | 2 | CI-01, CI-02, CI-03 | T-137-13..14 | Required jobs transport immutable evidence only | workflow contract | `mix test test/lockspire/ci_workflow_evidence_contract_test.exs` | ✅ | ✅ green |
| 137-04-02 | 04 | 2 | CI-01, CI-02, CI-03 | T-137-15..16 | Workflow permissions/actions/dependency gates remain pinned | supply-chain contract | `mix test test/lockspire/ci_static_contract_test.exs && bash scripts/ci/lint_workflows.sh` | ✅ | ✅ green |
| 137-05-01 | 05 | 1 | CONF-01 | T-137-17..18 | Suite sources and OCI images have immutable identities | contract | `mix test test/lockspire/conformance_immutable_inputs_contract_test.exs` | ✅ | ✅ green |
| 137-05-02 | 05 | 1 | CONF-01 | T-137-19..20 | Preparation rejects checksum, archive, and compose drift | parser + shell | `python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only` | ✅ | ✅ green |
| 137-06-01 | 06 | 2 | CONF-01, CONF-02 | T-137-21..22 | Shared runner invokes the pinned plan and classifies failures | command-level | `mix test test/lockspire/conformance_profile_execution_test.exs` | ✅ | ✅ green |
| 137-06-02 | 06 | 2 | CONF-02 | T-137-23..24 | Only allowlisted receipt fields survive ephemeral cleanup | redaction contract | `mix test test/lockspire/conformance_redacted_evidence_contract_test.exs` | ✅ | ✅ green |
| 137-07-01 | 07 | 3 | CONF-01, CONF-02 | T-137-25..26 | Scheduled/manual jobs are least-privilege and receipt-only | workflow contract | `mix test test/lockspire/conformance_workflow_contract_test.exs && bash scripts/ci/lint_workflows.sh` | ✅ | ✅ green |
| 137-07-02 | 07 | 3 | CONF-02 | T-137-27..28 | Diagnostics and docs preserve supplemental, non-certifying truth | task + docs | `mix test test/mix/tasks/lockspire/oidf_conformance_test.exs && mix docs.verify` | ✅ | ✅ green |
| 137-08-01 | 08 | 2 | REL-01 | T-137-29..30 | Both clean-room roles consume one verified tar or exact Hex version | source contract + E2E | `mix test test/lockspire/clean_room_release_source_contract_test.exs` and integration partition | ✅ | ✅ green |
| 137-08-02 | 08 | 2 | REL-01 | T-137-31..32 | Provenance errors fail before host boot and remain redacted | negative contract | `mix test test/lockspire/clean_room_release_source_contract_test.exs` | ✅ | ✅ green |
| 137-09-01 | 09 | 3 | REL-01, REL-02 | T-137-33..35 | Strict manifest binds SHA, tar bytes, and tool identities | command-level | `mix test test/lockspire/release_artifact_chain_contract_test.exs` | ✅ | ✅ green |
| 137-09-02 | 09 | 3 | REL-01, REL-02 | T-137-36..37 | Exact bytes upload and exact public checksum/version are required | local HTTP + contract | `mix test test/lockspire/release_artifact_chain_contract_test.exs test/lockspire/release/release_automation_contract_test.exs` | ✅ | ✅ green |
| 137-10-01 | 10 | 3 | REL-01, REL-02 | T-137-38..40 | Verified SHA/artifact identity crosses protected jobs as data | workflow contract | `mix test test/lockspire/release_workflow_artifact_contract_test.exs test/lockspire/release_ci_evidence_contract_test.exs` | ✅ | ✅ green |
| 137-10-02 | 10 | 3 | REL-01, REL-02 | T-137-41..42 | Public verification and evidence retention fail closed | workflow + docs | `mix test test/lockspire/release/release_automation_contract_test.exs && bash scripts/ci/lint_workflows.sh` | ✅ | ✅ green |

## Wave 0 Requirements

Existing ExUnit, shell, Python, PostgreSQL, coverage, and workflow-lint infrastructure covers all phase requirements. No Wave 0 test scaffolding is missing.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Default-branch OIDC/FAPI workflow executes against configured providers and retains only receipts | CONF-02 | Requires repository secrets, GitHub-hosted Docker, and the pinned external OIDF suite | Dispatch `Supplemental OIDF Conformance` with all profile secrets configured; inspect job classification and artifact inventories. |
| Protected release realizes one checksum through Hex, HexDocs, and exact-version clean-room proof | REL-01, REL-02 | Requires protected publication credentials and immutable external registry state | Run an approved release or staging-equivalent through prepublish, protected publish, and post-publish; compare every retained checksum and artifact inventory. |

These checks are external acceptance evidence. Their implementation paths have automated topology, negative, byte-capture, redaction, and command-level tests.

## Validation Audit 2026-08-27

| Metric | Count |
|--------|-------|
| Tasks mapped | 20 |
| Requirements with automated implementation proof | 7/7 |
| Missing automated references | 0 |
| Manual external acceptance checks | 2 |

## Validation Sign-Off

- [x] All tasks have an executable automated verification command.
- [x] Sampling continuity: no consecutive task gap exists.
- [x] Existing infrastructure covers all references; no Wave 0 files are missing.
- [x] No watch-mode flags are used.
- [x] Focused feedback latency is under 15 seconds.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** validated 2026-08-27
