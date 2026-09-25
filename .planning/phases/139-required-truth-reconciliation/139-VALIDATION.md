---
phase: "139"
slug: "required-truth-reconciliation"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-11"
updated: "2026-09-13"
---

# Phase 139 — Validation Strategy

> Retrospective Nyquist audit for exact-SHA acceptance, release, hygiene, planning truth, lifecycle integration, and supplemental evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | ExUnit, Node `node:test`, repository-local Bash, Git, and workflow lint |
| **Quick run** | Focused ExUnit tags plus the command-router and lifecycle Node suites |
| **Full run** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix ci` |
| **External boundary** | Final live acceptance requires synchronized `HEAD`, local `main`, and `origin/main`; the repository does not manufacture this state. |

## Sampling and Failure Policy

- Run directly affected ExUnit or Node contracts after every change.
- Run `bash scripts/ci/lint_workflows.sh` after shell, workflow, or capability changes.
- Run Phase 139 acceptance, cancellation, and lifecycle adversaries at the wave boundary.
- A nonzero exit, zero executed tests, unresolved hygiene `BLOCK`, undispositioned `WARN`, mismatched workflow SHA, incomplete receipt, or `refresh_required` relation is not green evidence.
- Historical output is supporting evidence only; current changed paths require fresh focused verification.

## Requirement Coverage

| Requirement | Status | Automated evidence | External/manual boundary |
|-------------|--------|--------------------|--------------------------|
| CI-06 | DEFERRED TO PHASE 140 ENTRY GATE | Exact-SHA identity, sealed-candidate authentication, fast-forward, retry, and hostile-field contracts | Canonical CI for synchronized `main` must be authenticated by the blocking Phase 140 `plan:pre` hook before planning starts. |
| CI-07 | DEFERRED TO PHASE 140 ENTRY GATE | Release graph, intentional no-publish, durable receipt, and same-SHA contracts | The push-triggered Release result for synchronized `main` must be authenticated by the same blocking hook before planning starts. |
| CI-08 | COVERED | Conformance and redacted supplemental-evidence contracts | Supplemental external evidence remains non-gating. |
| QUAL-05 | COVERED | Proof-quality, formatting, Credo, Sobelow, docs, audit, package, and focused regression gates | None. |
| HYGIENE-05 | COVERED | Full receipt authentication precedes ref mutation; WARN and exact-SHA matrices pass | Live ref synchronization remains an operator action. |
| HYGIENE-06 | COVERED | Blocking supported hooks, router supervision, workflow lint, and supply-chain contracts pass | None. |
| TRUTH-03 | COVERED | Exact completion cardinality, lifecycle classification, and planning-consistency contracts pass | None. |
| TRUTH-04 | COVERED | Immutable public `1.5.0` release-chain contracts pass | Public GitHub/Hex corroboration is read-only external evidence. |
| TRUTH-05 | COVERED | Protected release graph and immutable full-SHA action-reference contracts pass | None. |

## Per-Task Verification Map

| Task | Requirements | Automated command | Status |
|------|--------------|-------------------|--------|
| 139-01 — exact-SHA acceptance contract | QUAL-05, HYGIENE-05 | Repository-hygiene `phase139_exact_sha_hygiene` tests | COVERED; live CI-06/CI-07 deferred to Phase 140 entry gate |
| 139-02 — proof quality and shell lint | QUAL-05, HYGIENE-06 | Proof-quality tests; workflow lint | COVERED |
| 139-03 — release graph and immutable actions | CI-07, HYGIENE-06, TRUTH-05 | Release CI and workflow supply-chain contracts | COVERED |
| 139-04 — maintained truth | CI-08, TRUTH-03, TRUTH-04 | Planning-consistency and maintained-source contracts | COVERED |
| 139-05 — lifecycle/main relation | HYGIENE-05, HYGIENE-06, TRUTH-03 | Phase-139 inventory relation and pre-verifier refresh contracts | COVERED |
| 139-06 — sealed landing and durable receipt | CI-06, CI-07, CI-08, QUAL-05, HYGIENE-05, TRUTH-04 | Final-acceptance and acceptance-receipt adversarial matrices | COVERED |
| 139-07 — installed lifecycle routing | All Phase 139 requirements | Production router and installed-lifecycle Node suites | COVERED |

## Repaired Blockers

| Prior blocker | Repair | Verification |
|---------------|--------|--------------|
| Unsupported completion hook and removed runtime helper | Rebased ownership to blocking supported `execute:post` and `plan:pre` gates; added a project-owned sealed state helper and installed-manifest parity | Installed hook/lifecycle contracts green |
| Ref mutation before complete authentication | Added sealed-candidate verification before `update-ref` or push; bound writer, hook, transformation, before/after, lifecycle point, and exact candidate | Hostile field matrix preserves local and advertised refs |
| Ambiguous completion classification | Enforced exact cardinality/value for completion fields and lifecycle chain | Duplicate valid `Progress:` and prefix-valid `Phase:` cases reject |
| Router-only cancellation leaked descendants | Added parent-liveness supervision and detached-group cleanup | HUP, INT, and TERM production-router cases green |
| Planning records contradicted each other | Reconciled Phase 139 to 7/7 and ready for verification | Planning-consistency contract green |
| macOS Bash portability | Removed associative-array dependency and guarded empty indexed-array expansion under `set -u` | Exact-SHA happy/hostile pair green under Bash 3.2 |
| Test signal escaped its fixture | Changed the fake interrupted `mix` command to self-signal rather than signal its parent | Exact-SHA interruption case stays fail-closed without sibling SIGTERM |
| Exact-head normalization depended on extra Git subprocesses | Normalize refs already equal to the authenticated sealed head directly; retain ancestry proof for intermediate refs | Inventory, final-acceptance, and durable-receipt matrix: 3/3 green |

## Fresh Evidence

- `MIX_ENV=test mix test.fast`: 1,417 tests, 0 failures, 6 skipped; this completed before the final narrow Bash/ref-normalization deltas.
- Exact-SHA focused selection after the Bash and signal repairs: 2 tests, 0 failures.
- Phase-139 inventory/final-acceptance/durable-receipt selection after the final ref-normalization repair: 3 tests, 0 failures.
- Combined production-router and installed-lifecycle Node suites: 16 tests, 0 failures.
- Planning consistency: 1 test, 0 failures.
- Workflow/shell lint, `mix format --check-formatted`, Credo, Sobelow, docs, dependency audit, and package build passed during the repair run.

## External Final Acceptance

Repository-owned validation is complete. Live acceptance is deliberately still pending because the refs are not synchronized:

- repair implementation tip before this validation record: `2098ba8df5ef4c7188a4fd7cf1b5ce8b304107cb`
- local `main`: `c8525a894e2d4da606cd18040e9301b8eb4311d7`
- `origin/main`: `d82eaa1c74f396c5eb5dcfa393ddd5dd952acb92`
- live `.git/lockspire-phase-139-acceptance-v1.json`: absent

The finalizer must authenticate the sealed candidate, perform the exact fast-forward/push at the supported blocking boundary, re-query canonical same-SHA CI and intentional Release no-publish evidence, and only then write the live receipt. This is not a remaining Nyquist coverage gap and was not auto-executed as part of a repository repair.

## Validation Sign-Off

- [x] Every plan task has automated coverage or an explicit external boundary.
- [x] All repository-owned validation blockers are repaired.
- [x] Receipt authentication precedes ref mutation.
- [x] Router-only cancellation reaps its detached process tree.
- [x] Maintained planning records expose one coherent Phase 139 posture.
- [x] All 19 plan prohibitions have enforcement or explicit boundary coverage.
- [x] `nyquist_compliant: true` is supported by executable coverage.
- [ ] Final synchronized-main live acceptance and external same-SHA evidence are pending.

**Approval:** validated — repository-owned gaps repaired; live synchronized-main acceptance remains an explicit external operation.

## Gap Closure Proof Map

The initial report above is immutable historical evidence (`status: gaps_found`, 8/19 truths). The gap IDs below preserve its observable-truth order; closure status is based on the named current proof and does not rewrite that report. G-139-02 was behavior-unverified because the original verifier's bounded attempt timed out, not because the behavior was absent.

| Gap ID | Initial report truth | Current executable owner | Closure status |
|---|---|---|---|
| G-139-01 | Truth 1 — synchronized final exact acceptance SHA and no-publish evidence | Plan 139-09 post-transition acceptance/receipt; remains pending until live receipt | PENDING_EXTERNAL |
| G-139-02 | Truth 2 — hostile exact-SHA fixtures fail closed (behavior-unverified) | `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase139_gap_closure`, `exact-SHA repository hygiene fails every ambiguous or stale path closed` | AUTOMATED |
| G-139-03 | Truth 3 — mix ci executes tests at captured SHA and is green | `test/lockspire/quality/proof_quality_baseline_test.exs`, `requires active proof to contain no macro injection, history reads, or count thresholds`; final mix ci remains a lifecycle gate | AUTOMATED_WITH_FINAL_GATE |
| G-139-04 | Truth 6 — workflow/shell lint and semantic phase-label proof pass | `test/lockspire/quality/proof_quality_baseline_test.exs`, `finds phase-numbered labels only inside the explicitly scoped current-proof inventory`; `bash scripts/ci/lint_workflows.sh` | AUTOMATED |
| G-139-05 | Truth 10 — planning records expose one coherent active Phase 139 posture | `test/lockspire/quality/phase_139_planning_consistency_test.exs`, `maintained Phase 139 records expose one lifecycle posture` | AUTOMATED |
| G-139-06 | Truth 13 — execute:post publishes one current ledger before verification | Plan 139-09 portable lifecycle `installed capability renders fresh ordered lifecycle hooks`; live-runtime parity was verified by the fixture-backed command after GSD 1.14.0 activated the capability | AUTOMATED_LIVE |
| G-139-07 | Truth 14 — supported post-transition gate authenticates sealed lifecycle before Phase 140 | Plan 139-09 portable lifecycle `host workflows expose only supported fresh lifecycle boundaries`; live-runtime parity was verified by the fixture-backed command after GSD 1.14.0 activated the capability | AUTOMATED_LIVE |
| G-139-08 | Truth 15 — main advances only after complete receipt/lifecycle authentication | Plan 139-09 `Phase 139 exact landing and receipt failure matrices remain green` | AUTOMATED |
| G-139-09 | Truth 16 — durable out-of-worktree exact-SHA receipt is retained | Plan 139-09 acceptance receipt and supported post-transition execution; remains pending until live receipt | PENDING_EXTERNAL |
| G-139-10 | Truth 17 — installed recovery blocks later routing and retries only unfinished work | Plan 139-09 portable lifecycle `Phase 139 host lifecycle preserves durable post-transition recovery` | AUTOMATED |
| G-139-11 | Truth 18 — exact completion cardinality and production-router cancellation | `maintained Phase 139 records expose one lifecycle posture`; Plan 139-09 router `cancelling only the production router terminates and reaps its complete finalizer process group` | AUTOMATED |

## Required Portable Lifecycle CI Contract

The existing `Release Hygiene Drift` job runs `LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` once, immediately after its standalone router contract and before the Release Please runtime dependency audit. The source-level owner is `test/lockspire/workflow_supply_chain_contract_test.exs`, test `release hygiene runs the portable phase-finalizer lifecycle exactly once in protected order`; it pins the unique top-level read-only permission, release-hygiene job identity/runner/timeout, all existing step names/order, and the router → lifecycle → release audit sequence.

Current-host parity remains an execution boundary: live rendering checks compare the active capability with the same tracked fixture after installation. The portable CI fixture is test input only and does not install GSD or authorize runtime behavior. G-139-01 and G-139-09 remain `PENDING_EXTERNAL` until the supported post-transition path authenticates the synchronized SHA and retains a valid mode-0600 receipt outside the worktree.

## Prohibition Enforcement

Each statement below is copied verbatim from a completed Plan 139-01 through 139-07. Enforcement owners name a tracked test module and an existing test/helper entry point. A passing prose claim alone is not counted as enforcement.

| Source prohibition | Tracked owner | Entry point | Status |
|---|---|---|---|
| "The acceptance path must not substitute the Phase 138 publication, a phase-branch head, the historical 1.5.0 source, or an arbitrary newest green run for synchronized final main." | `test/lockspire/release/repository_hygiene_contract_test.exs` | `exact-SHA repository hygiene joins synchronized local and workflow truth` | ENFORCED |
| "A push-triggered no-publish Release outcome must not dispatch protected publication, mutate release-owned files, or be described as a published release." | `test/lockspire/release_ci_evidence_contract_test.exs` | `release push is no-publish while protected dispatch retains the publication graph` | ENFORCED |
| "Untrusted workflow output or WARN text must not expose credentials, environment values, raw logs, or uncontrolled response bodies in the receipt." | `test/lockspire/release/repository_hygiene_contract_test.exs` | `sealed candidate records exact live acceptance outside the worktree` | ENFORCED |
| "Making the local gate green must not add ShellCheck suppressions, weaken proof-quality matching, exclude active files, delete lifecycle assertions, or replace failures with ignored exits." | `test/lockspire/quality/proof_quality_baseline_test.exs` | `requires active proof to contain no macro injection, history reads, or count thresholds` | ENFORCED |
| "The narrow gate repair must not become broad refactoring, dependency work, protocol work, or Phase 140 cleanup." | `test/lockspire/quality/phase_139_planning_consistency_test.exs` | `maintained Phase 139 records expose one lifecycle posture` | ENFORCED |
| "Contract hardening must not edit the authoritative workflows or composite action merely to satisfy assertions, dispatch a workflow, publish a package, or change Release Please ownership." | `test/lockspire/workflow_supply_chain_contract_test.exs` | `immutable action references include the repository-controlled composite exactly once` | ENFORCED |
| "The action-pin scan must not stop at workflow files or accept tags, branches, shortened digests, variable expressions, or mutable aliases for external actions." | `test/lockspire/workflow_supply_chain_contract_test.exs` | `immutable action references include the repository-controlled composite exactly once` | ENFORCED |
| "Planning reconciliation must not rewrite archived or shipped history, describe v1.38 as released, or bind the historical 1.5.0 chain to the newer acceptance SHA." | `test/lockspire/quality/phase_139_planning_consistency_test.exs` | `maintained Phase 139 records expose one lifecycle posture` | ENFORCED |
| "Maintained release prose must not claim that a push publishes, that a tag is accepted by exact-ref dispatch, or that GitHub release creation precedes Hex publication." | `test/lockspire/release_ci_evidence_contract_test.exs` | `release push is no-publish while protected dispatch retains the publication graph` | ENFORCED |
| "Supplemental OIDF/FAPI evidence must not become required acceptance, a certification claim, an unredacted record, or a reason to conceal retained failures." | `test/lockspire/conformance_redacted_evidence_contract_test.exs` | `evidence builder records only bounded receipt fields and refuses secrets or raw paths` | ENFORCED |
| "A stale or mismatched Phase 138 ledger must not be relabeled current, hand-edited in place, appended with acceptance claims, or used to authorize inventory dispositions." | `test/lockspire/release/repository_hygiene_contract_test.exs` | `baseline snapshot relation fails closed on topology and destructive bookkeeping drift` | ENFORCED |
| "Ledger refresh must not amend, force-push, rewrite earlier ledger commits, change more than the canonical ledger path, or execute any proposal from the inventory." | `test/lockspire/release/repository_hygiene_contract_test.exs` | `baseline snapshot relation resolves only the current immutable ledger publication` | ENFORCED |
| "Post-transition verification must not infer authority from commit subjects alone, allow unrelated ref movement, mutate the ledger, or clear the host-owned lifecycle receipt." | `test/lockspire/release/repository_hygiene_contract_test.exs` | `baseline snapshot relation fails closed on topology and destructive bookkeeping drift` | ENFORCED |
| "Final acceptance must not force-push, rewrite history, delete refs, close PRs/issues, merge dependency work, or perform any Phase 140 cleanup." | `test/lockspire/release/repository_hygiene_contract_test.exs` | `sealed candidate advances main through one exact fast-forward` | ENFORCED |
| "The acceptance finalizer must not dispatch Release, publish to Hex, create a tag or GitHub release, or edit version/changelog/manifest/package state." | `test/lockspire/release_ci_evidence_contract_test.exs` | `release push is no-publish while protected dispatch retains the publication graph` | ENFORCED |
| "The final live receipt must not be committed, staged, written inside the worktree, contain secrets/raw logs, or claim the Phase 139 SHA is the 1.5.0 release source." | `test/lockspire/release/repository_hygiene_contract_test.exs` | `sealed candidate records exact live acceptance outside the worktree` | ENFORCED |
| "The capability must not run Phase 139 mutation or acceptance logic for Phase 140/141, silently accept malformed phase argv, or leave a Phase 139 failure unable to block later routing." | `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs` | `other strictly numeric phases are inert successes` | ENFORCED |
| "The installed hook must not publish a release, rewrite history, perform cleanup, commit the live receipt, or add a public Lockspire/runtime surface." | `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` | `Phase 139 host lifecycle preserves durable post-transition recovery` | ENFORCED |
| "Installed runtime copies must not become source authority or be hand-edited instead of reinstalling from tracked capability source." | `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` | `installed capability renders fresh ordered lifecycle hooks` | ENFORCED |

**Discovered prohibitions:** 19 (3 + 2 + 2 + 3 + 3 + 3 + 3). **Mapped rows:** 19. **Unresolved:** 0. **flagged-unverified:** 0.

The machine-checked contract in `phase_139_planning_consistency_test.exs` extracts these source statements, verifies one matching row per statement, checks each owner is tracked and the entry point exists, and rejects nonzero unresolved counts or `flagged-unverified` dispositions. G-139-01 and G-139-09 remain pending until Plan 139-09's supported live post-transition acceptance actually produces the receipt for the synchronized SHA.

## Plan 139-09 Execution Checkpoint

**Status:** Task 1 is complete. Commit `bd652415` contains its implementation, and the complete live fixture-backed command passed 16/16 on 2026-09-24 after installed GSD reached 1.14.0 and the project capability became active. Task 2 adds the recurring portable CI contract. Plan 139-09 remains incomplete until Task 2 verification and the final synchronized-main receipt boundary are honestly recorded; Phase 139 remains incomplete.

| Boundary | Evidence | Result |
|---|---|---|
| Portable router and lifecycle suites | `HOME=/private/tmp/lockspire-no-global-gsd GSD_TOOLS= LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` — 16 tests, 0 failures | PASS |
| Current GSD runtime and project capability | Installed GSD reached 1.14.0 and `lockspire-phase-finalizer` became active | PASS |
| Live lifecycle hooks and combined suite | Complete live fixture-backed router/lifecycle command — 16 tests, 0 failures on 2026-09-24 | PASS; Task 1 evidence at `bd652415` |
| Task 2 required CI contract | `mix test test/lockspire/workflow_supply_chain_contract_test.exs`, portable Node lifecycle command, and `bash scripts/ci/lint_workflows.sh` | Workflow lint PASS; source syntax PASS; Node portable mode 14/16 tests PASS, with two nested Mix commands blocked by sandbox `Mix.PubSub` TCP `:eperm`; focused ExUnit likewise blocked by `Mix.PubSub` TCP `:eperm` |
| Final synchronized-main receipt | Supported post-transition acceptance must authenticate the synchronized SHA and write the retained external receipt | PENDING_EXTERNAL — G-139-01 and G-139-09 remain open |

The earlier sandbox-only failure remains part of the execution history and is not erased by the later live pass. Task 2 must not claim G-139-01 or G-139-09 complete until the supported post-transition path writes a valid receipt for the synchronized SHA.
