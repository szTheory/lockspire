---
phase: 138
slug: baseline-inventory-evidence-taxonomy
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-28
audited: 2026-09-24
---

# Phase 138 — Validation Strategy

> Retrospective Nyquist audit of the executed baseline-inventory and evidence-taxonomy contracts, including Plans 138-26 through 138-29 gap closure.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (project-native) plus production Bash smoke checks |
| **Config file** | `mix.exs` |
| **Focused gap command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_path_gap --only phase138_source_authority_gap --only phase138_closeout_gap --only phase138_redaction_gap --only phase138_relation_gap` |
| **Full contract command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/lockspire/release/repository_hygiene_contract_test.exs` |
| **Full project command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci` |
| **Live relation command** | `env -u LOCKSPIRE_INVENTORY_TEST_GITHUB_FINGERPRINT -u LOCKSPIRE_INVENTORY_TEST_MAINTAINED_FINGERPRINT bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` |
| **Measured focused gap runtime** | 214.1 seconds for 5 tests on 2026-09-10 |

---

## Sampling Rate

- **After collector/test changes:** Run the affected `phase138_*_gap` tag.
- **After each gap-closure plan:** Run the complete repository-hygiene contract.
- **Before immutable publication:** Run repository hygiene, release readiness, and `mix ci` from one clean committed base.
- **After lifecycle bookkeeping:** Run the live production relation with both legacy fingerprint variables unset.
- **Failure rule:** Zero executed tests, a nonzero exit, a non-complete receipt, or `refresh_required` is not green evidence.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Observable Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|---------------------|-----------|-------------------|-------------|--------|
| 138-26-01 | 138-26 | 26 | BASE-02 | T-138-108, T-138-111 | Real tab/newline worktree paths each produce one exact, 12-field, proposal-only row; malformed structured input is partial | integration | Focused gap command with `--only phase138_path_gap` | ✅ | ✅ green |
| 138-26-02 | 138-26 | 26 | BASE-01 | T-138-109, T-138-110 | Relative replacement affects only the caller-resolved target, and missing `jq` fails before source work or mutation | integration/smoke | Focused gap command with `--only phase138_path_gap` | ✅ | ✅ green |
| 138-27-01 | 138-27 | 27 | TRIAGE-01, TRIAGE-02, LOOSE-01 | T-138-112, T-138-115 | Matching caller fingerprints cannot authorize unavailable/drifted evidence; agreeing live fixture sources can authorize | integration | Focused gap command with `--only phase138_source_authority_gap` | ✅ | ✅ green |
| 138-27-02 | 138-27 | 27 | BASE-01, LOOSE-01 | T-138-113, T-138-114 | Body forgeries, duplicate metadata, and surplus ROADMAP/STATE changes refresh; one exact bounded closeout authorizes | integration | Focused gap command with `--only phase138_closeout_gap --only phase138_relation_gap` | ✅ | ✅ green |
| 138-28-01 | 138-28 | 28 | BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01 | T-138-116, T-138-117 | AWS, Slack, JWT, PEM, bearer, GitHub, and opaque credentials are absent raw across Git/GitHub/maintained outputs while identities remain distinct | integration | Focused gap command with `--only phase138_redaction_gap` | ✅ | ✅ green |
| 138-28-02 | 138-28 | 28 | BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01 | T-138-118, T-138-119 | Git SHAs, evidence IDs, UUIDs, versions, public URLs, release names, and ordinary prose remain visible | integration | Focused gap command with `--only phase138_redaction_gap` | ✅ | ✅ green |
| 138-29-01 | 138-29 | 29 | BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01 | T-138-120 through T-138-124 | The clean corrected base publishes one one-parent/one-path immutable proposal-only ledger after full gates and double collection | integration/smoke | Full contract, release-readiness, `mix ci`, API coverage, assumption-delta, and schema-drift commands recorded in `138-29-SUMMARY.md` | ✅ | ✅ green |
| 138-29-02 | 138-29 | 29 | BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01 | T-138-121, T-138-124 | Current live Git/GitHub/maintained observations and exact lifecycle commits resolve to `snapshot_relation: authorized_bookkeeping` | smoke | Live relation command above | ✅ | ✅ green |
| 138-34-01 | 138-34 | 34 | BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01 | T-138-145, T-138-149 | Every Phase 138 summary classifies as fully automated with no malformed or human-presented deliverable | integration | Classifier loop recorded in `138-34-PLAN.md` | ✅ | ✅ green |
| 138-34-02 | 138-34 | 34 | BASE-02 | T-138-147, T-138-148 | Release-hygiene CI runs the portable finalizer router exactly once without adding the GSD lifecycle suite or duplicating the ExUnit matrix | unit/integration | `node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs && bash scripts/ci/lint_workflows.sh` | ✅ | ✅ green |
| 138-34-03 | 138-34 | 34 | BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01 | T-138-146, T-138-149 | The complete repository-hygiene contract passes before UAT records 95 automated passes and thirteen resolved gaps | integration | Full contract command plus UAT count assertions recorded in `138-34-PLAN.md` | ✅ | ✅ green |

## Requirement Coverage

| Requirement | Behavioral Coverage | Current Status |
|-------------|---------------------|----------------|
| BASE-01 | Baseline failure states, caller-relative targets, dependency preflight, exact lifecycle classification, immutable publication, and live relation | COVERED |
| BASE-02 | Deterministic branch/tag/worktree rows, hostile legal path bytes, stable identity, safe display, and proposal-only dispositions | COVERED |
| TRIAGE-01 | Authenticated paginated PR collection, outer/nested identity consistency, live-source authority, redaction, and fail-closed receipts | COVERED |
| TRIAGE-02 | Authenticated issue pagination, honest complete-zero, namespace separation, live-source authority, and safe display | COVERED |
| LOOSE-01 | Maintained-family discovery, active/archive semantics, deduplication, redaction, exact closeout metadata, and partial failure states | COVERED |

## Gap-Closure Audit

| Former Gap | Behavioral Proof | Result |
|------------|------------------|--------|
| Canonical inventory stale at HEAD | Immutable ledger anchors plus the production live relation at lifecycle HEAD | FILLED |
| Tab/newline worktree paths corrupt rows | Real linked worktrees with both legal delimiter characters | FILLED |
| Environment fingerprints bypass live sources | Matching-value spoof attempts against unavailable/drifted sources | FILLED |
| Forged or surplus GSD closeout metadata authorizes | Twenty-two malformed/forged variants plus exact positive control | FILLED |
| Common and opaque credentials cross render boundaries | Credential matrix across Git, GitHub, maintained, receipt, limitation, and diagnostic paths with benign controls | FILLED |
| Relative output is re-rooted after repository `cd` | Nested caller fixtures for `name.md` and `../name.md`, with non-target byte sentinels | FILLED |
| Phase 138 deliverables fall back to conversational UAT | All 34 summaries classify in coverage mode with `all_auto_covered=true`, zero errors, and zero presented entries | FILLED |
| Portable finalizer routing lacks recurring CI ownership | Seven-test Node router suite runs exactly once in release-hygiene; workflow lint rejects lifecycle-suite or duplicate-matrix drift | FILLED |
| Phase 139 proof fixtures depend on active numeric labels | Semantic phase attributes preserve generated values while the complete 45-test repository-hygiene contract remains green | FILLED |
| Thirteen historical UAT automation gaps remain unresolved | Tests 83–95 map one-to-one to existing executable coverage and the terminal receipt records 95 passes / 13 resolved gaps | FILLED |

## Fresh Audit Evidence — 2026-09-10

| Command | Result |
|---------|--------|
| Focused five-tag adversarial command | Exit 0; 5 tests, 0 failures, 28 excluded; 214.1 seconds |
| Live production relation command | Exit 0; ledger `891fe796e86a9e803669cc977e96cbeccf6f34aa`, closeout `c872cd23d4bee940ad34485d28de2791ee7f8245` classified `gsd_plan_closeout`, working tree clean, `snapshot_relation: authorized_bookkeeping` |
| Plan 138-29 full project gate | `mix ci`: 1,402 main tests and 102 integration tests, 0 failures; formatter, compile warnings, cycles, Credo, Sobelow, docs, audit, and package checks passed |

No test or implementation change was required by this audit. The existing gap tests are behavioral rather than structural: they invoke the production collector/relation CLI against real or hermetic repositories and assert externally observable output, mutation boundaries, exit status, and authority decisions.

---

## Manual-Only Verifications

None. Mutable external state is sampled by the executable production relation, while hermetic process fixtures exercise its failure and adversarial branches.

## Validation Audit 2026-09-10

| Metric | Count |
|--------|-------|
| Requirements audited | 5 |
| Historical verification gaps audited | 6 |
| New gaps found | 0 |
| Resolved | 6 |
| Escalated | 0 |

## Validation Audit 2026-09-12

| Metric | Count |
|--------|-------|
| Phase summaries classified | 34 |
| Plan 138-34 tasks audited | 3 |
| Historical UAT gaps reverified | 13 |
| New behavioral tests required | 0 |
| Resolved validation-map gaps | 4 |
| Escalated | 0 |

### Fresh Plan 138-34 Evidence

| Command | Result |
|---------|--------|
| Phase-summary coverage classifier loop | Exit 0; 34 summaries in coverage mode, all automated, zero errors, zero presented entries |
| `node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs` | Exit 0; 7 tests, 0 failures |
| `bash scripts/ci/lint_workflows.sh` plus CI ownership assertions | Exit 0; router invocation present exactly once, lifecycle suite absent, fast ExUnit owner retained |
| Full repository-hygiene contract command | Exit 0; 45 tests, 0 failures; 719.3 seconds |
| UAT receipt count assertions | 95 passes, 95 automated sources, 13 resolved gaps, 0 issues/pending/skipped/blocked |

Plan 138-34 introduced no uncovered requirement behavior. Its metadata and UAT work reuse existing behavioral production-CLI coverage, while the only new recurring behavior—the portable finalizer router—is exercised by a focused seven-test Node suite. The authorized semantic Phase 139 fixture-label repair changes fixture construction rather than assertions; the focused contract and the complete repository-hygiene suite prove the generated behavior remains green.

---

## Validation Sign-Off

- [x] All tasks have behavioral automated verification.
- [x] All five Phase 138 requirements map to existing executable tests.
- [x] All six historical verification gaps have passing adversarial coverage.
- [x] Every focused test was executed; no zero-test result was accepted.
- [x] No watch-mode flags are present.
- [x] `mix ci` is green at the corrected publication base.
- [x] The production relation is green after bounded lifecycle bookkeeping.
- [x] Plan 138-34 coverage metadata classifies all 34 summaries without human presentation.
- [x] The portable finalizer router runs exactly once in release-hygiene CI and passes its seven-test contract.
- [x] The terminal UAT receipt contains 95 automated passes and thirteen resolved gaps.
- [x] The authorized semantic Phase 139 fixture-label repair preserves the complete 45-test behavioral contract.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** validated — 2026-09-12


## Validation Audit 2026-09-24

| Metric | Count |
|--------|-------|
| Phase summaries classified | 34 |
| Plan 138-34 tasks audited | 3 |
| New behavioral tests required | 0 |
| Uncovered requirements | 0 |
| Manual-only items | 0 |

Plan 138-34 adds machine-derived coverage metadata, a portable router contract already covered by its recorded unit and workflow-lint evidence, and UAT receipt bookkeeping. All five phase requirements remain covered by the existing executable contracts; no new behavioral validation gap was found.
