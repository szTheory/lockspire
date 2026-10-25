---
phase: "174"
slug: "packaged-proof-delivery-handoff"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-24"
---

# Phase 174 — Validation Strategy

## Test Infrastructure

Existing ExUnit, Python acceptance helpers, package binding, maintainer authority and seven-job CI train. No framework/dependency install. Every source Mix command uses `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b`; clean-room runners retain their own random run-owned DBs/ports/temp directories.

Quick feedback uses focused current source owners and Python runner checks. Package proof uses an actual archive through existing package-clean host machinery. Plan 174-01 creates the exact `selected_authorization_par` group, repeatable `--selected-case`, `--selected-receipt`, `--check-selected-receipt`, `--expected-source-revision` and `--expected-receipt-sha256` interfaces before use. The separate `selected_receipts.py` contract is tested in Python and invoked from the existing ExUnit source-CI contract, with no runtime dependency on planning artifacts. The current DCR lifetime parser/validator remains intact. Full candidate gate is complete local `mix ci` plus all seven required hosted jobs at the exact candidate head; main acceptance remains conditional on actual reviewed integration.

Execution evidence is recorded below and in the linked phase artifacts. The complete selected package receipt is bound to source `f01b6ef77889d38b032944eb37069d6d4b3b3171` and its proof index; its 12 cases passed with no failures or skips, and redaction/cleanup passed. Four current source-owner runs passed 132 tests total. The exact candidate `ec6361d9840f2adfda85116d72fec0efe9065c6c` passed local `mix ci` and all seven canonical hosted jobs on attempt 2. The delivery artifact records PR #140 open, main acceptance absent, and a concrete blocker/next action. These observations validate the planned checks; they do not claim accepted-main, publication, external-profile, or phasewide post-plan review/audit completion. Those final phase gates remain parent-owned.

## Sampling Rate

- Per implementation task: focused checks appropriate to the changed harness/fixture/receipt or guidance.
- First vertical slice: a real packaged request/control with bound archive/tree/vendor/resolved/compiled evidence before case expansion.
- After final shipped inputs settle: all applicable selected package cases and current source owners, redaction/cleanup/receipt checks, current verifier/security owners, then complete candidate gates.
- Planning-only completion changes receive deliberate owner freshness review. Never reconstruct historical receipts, relabel prior RED/GREEN or rerun the historical deliberate-RED probe as a green gate.

## Per-Task Verification Map

All commands assume checkout root. Every runnable `<automated>` command in the plans has an immediately adjacent `<fails_when>`. Focused Python/status feedback is short; genuine package, `mix ci`, hosted and main gates may take longer. Use tool yielding/polling of at most 60 seconds while they run. No old deliberate-RED qualification probe is a green gate.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Execution Evidence | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|-------------------|--------|
| 174-01-01 | 01 | 1 | CPROOF-01, CPROOF-02 | T-174-01/02/03/05/06 | Genuine A171-003 query-control→binary rejection through archive/host/HTTP/strict partial receipt; negative validation and observed cleanup | Python + ExUnit + package HTTP | `python3 test/acceptance/selected_receipt_test.py`; prefixed `mix test test/lockspire/clean_room_release_source_contract_test.exs`; prefixed journey `--only selected_authorization_par --selected-case A171-003 --selected-receipt .artifacts/phase174/tracer.json` | `selected_receipts.py`, `selected_receipt_test.py`, source-CI bridge and runner present | Plan 01 summary: A171-003 packaged tracer; 11 Python tests; 7 ExUnit tests; partial receipt checker passed | green |
| 174-01-02 | 01 | 1 | CPROOF-01, CPROOF-02 | T-174-03/04/06 | Exact callback/state, absent/stale auth and signed integer freshness from narrow host session fixtures | Python + package HTTP | Python receipt test; explicit six A selectors to existing journey and `.artifacts/phase174/authorization.json` | Host fixtures and selected runner paths present | Plan 01 summary: A171-001–006 package receipt, 6/6 cases; redaction and cleanup true | green |
| 174-02-01 | 02 | 2 | CPROOF-01, CPROOF-02 | T-174-07/08 | Required-PAR/S256/replay, wrong-client burn, expiry, independent pushed-scope control and exact consent/persisted projection; mounted discovery | Python + package HTTP | Python receipt test; explicit six P selectors and `.artifacts/phase174/par.json` | Runner, strict receipt module and test present | Plan 02 summary: complete A/P package receipt, 12/12; receipt suite 16 tests; external binding check passed | green |
| 174-02-02 | 02 | 2 | DELIV-01 | T-174-09 | Guidance/floor limits, actual proper-role code/security review and two current judgment lifecycle transitions | ExUnit + diff + role-owned review | Prefixed source-CI contract; scoped `git diff --check`; proper gsd-code-reviewer/gsd-security-auditor results | Guidance, review, security and disposition reports present | Plan 02 summary: review clean; Plan 02 security 4/4 closed; scoped judgment flags retained | green |
| 174-03-01 | 03 | 3 | CPROOF-01, DELIV-01 | T-174-10/16 | Five old descriptor-less prohibition lifecycles are judged only after scoped evidence; narrowly audit 171-03/guidance identities | Focused GREEN + ledger + role review | Existing prefixed tagged A171-003 and P171-005 commands; prefixed `mix test test/lockspire/qualification_ledger_contract_test.exs` | Prior plan/ledger/disposition files and selective audit present | Plan 03 summary: focused corrections and ledger contract passed; 171/172/173 verifier records current | green |
| 174-03-02 | 03 | 3 | CPROOF-01, CPROOF-02, DELIV-02 | T-174-01/02/10/11 | Freeze shipped inputs; reuse all ten source owners/two real RED/GREEN corrections; complete twelve-ID package proof and reviewed evidence-led ranking before candidate freeze | Existing ExUnit + package HTTP + receipt checker + ranking review | Four inherited source-owner/ledger commands; complete journey and exact source/digest checker; review dated MILESTONE-ARC sources/triggers with v1.47 scope/decision gates unchanged and later candidate/main outcomes pending | `174-INPUT-FREEZE.json`, `174-SOURCE-PROOF.json`, `174-PACKAGE-PROOF.json`, `174-PROOF-INDEX.json` and ranking present | Plan 03 summary and evidence audit: four source runs 132/132; package receipt 12/12; proof-index receipt digest matches | green |
| 174-03-03 | 03 | 3 | DELIV-01 | T-174-12/16 | Proper prior verifier owners reassess settled inputs/current GREEN and regenerate current fingerprints; bounded audit has no future/self-report dependency | Typed SDK status + role-owned reassessment | `gsd_run query verification.status` for each exact 171/172/173 directory, parsed and asserted passed as written in the plan | Prior reports and bounded audit present | Evidence audit: 171 10/10, 172 11/11, 173 6/6; all status passed; 3/2/2/2 judgment flags retained | green |
| 174-04-01 | 04 | 4 | DELIV-01 | T-174-13 | Complete local/exact-candidate seven-job graph and recorded execution-point contract-preserving snapshot; ordinary later SDK updates get scoped owner applicability review without restamping/CI-result loops | Full local + hosted CI + ancestry/delta/hash snapshot | Prefixed `mix ci`; exact-commit run/jobs; Python permits only nine exact report/delivery paths after executed candidate, preserving every scope/goal/requirement/decision/plan/validation/ranking definition and frozen input/proof-index hash; record actual command/time/HEAD/delta; scoped owner reviews subsequent SDK STATE/VALIDATION/completion deltas before goal verification | `174-CANDIDATE-GATES.json` present | Candidate gates: exact candidate local exit 0; canonical run 40156252600 attempt 2 has seven unique successful jobs; 63 frozen hashes match | green |
| 174-04-02 | 04 | 4 | DELIV-02 | T-174-14/15 | Agent inspects actual PR/audit/ref/JSON facts; real reviewed main or blockers, custody and read-only reassessment of frozen ranking/flags, no invented human checkpoint | Git/API/report inspection + conditional receipt validation | Git status/worktree/diff checks; agent-readable PR/reports/refs; conditional Python validates receipt/local/seven-job CI/Release-no-publish/WARN/frozen-input binding or explicit blocked/nonempty blocker/next action; main helper only at actual synchronized delivery; final observations go only in delivery/disposition reports | `174-DELIVERY.md` and candidate records present; main receipt absent while unmerged | Delivery records PR #140 open, main receipt absent, actual blocker and next action; accepted-main not claimed | green |

### Receipt and proof acceptance contract

- Runtime selection constants use exactly `A171-001` through `A171-006` and `P171-001` through `P171-006`. A bounded run explicitly emits `selection=partial` and its selected IDs. The default final sweep requires all twelve and emits `complete` only after actual positive passed execution per ID, with zero failed/skipped cases. Missing/unimplemented IDs raise; there is no implicit skip.
- Validator tests reject null/empty, partial-as-complete, missing/duplicate/unknown IDs, failed/skipped/zero executions, unsafe/unknown/missing observations, strict-count violations, mismatched source/archive/tree/vendor/resolved/compiled identity, false redaction/cleanup and substituted valid receipt bytes against an externally supplied expected digest. These are behavior tests with independent fixtures/mutations, not source-string assertions.
- The runner uses existing package-input/host provenance, redaction, run-root ownership and cleanup helpers. Only safe status/boolean/count/identity projections survive. Token signatures and host auth_time equality are observed before reduction to safe facts. Host fixture times are refreshed through configured integer-only run-owned files immediately before login, avoiding stale controls after long package setup.
- `174-PROOF-INDEX.json` joins original IDs/owners and actual receipt bytes; source code and source tests never import/read it. Runtime remains usable in a source PR/CI checkout without planning files.

## Dependency and Source Coverage Audit

Four sequential waves are intentional: all expansion tasks share the journey/receipt files; final freeze follows all shipped inputs/review fixes; prior report freshness follows legitimate lifecycle/manifest changes; candidate gates follow final proof. There is no same-wave file overlap between plans. Calibration returned factor `0.5`, sample count `10`, confidence `high`; estimates use raw × 0.5. Plans contain 2/2/3/2 tasks and no task owns more than five files.

| Source | ID / feature | Plan/task | Status / explanation |
|--------|--------------|-----------|----------------------|
| GOAL | Review source-bound selected behavior and resume honest delivery through existing train | 01–04 | COVERED |
| REQ | CPROOF-01 deterministic owners, original correction RED/GREEN, applicable negative/security evidence | 01, 02, 03 | COVERED; IDs in frontmatter |
| REQ | CPROOF-02 actual packaged embedded host/source identity, supplemental limits | 01, 02, 03 | COVERED; IDs in frontmatter |
| REQ | DELIV-01 current bounded evidence/verification/security, matching guidance, complete candidate gates | 02, 03, 04 | COVERED; scoped guidance/reviews, prior verifier records and exact local/hosted candidate gates are recorded; parent-owned phasewide final verification/security/review/audit remains pending |
| REQ | DELIV-02 reviewed delivery/main or blockers, retention and ranking | 03, 04 | COVERED; ranking update precedes candidate freeze; delivery records the observed open PR, absent main receipt, blocker, next action, custody and final read-only reassessment |
| RESEARCH | Existing journey/package-input/host machinery; separate strict selected receipt; no new framework | 174-01-01 | COVERED |
| RESEARCH | Appropriate openid/email scopes, host-owned time/session, signed fresh/stale proof | 174-01-01/02 | COVERED |
| RESEARCH | All frozen A/P cases, independent controls/exact media types/relative consent/persisted equality | 174-01-02, 174-02-01, 174-03-02 | COVERED |
| RESEARCH | Source/archive/tree/vendor/resolved/compiled binding, safe output and observed owned cleanup | 01–03 | COVERED |
| RESEARCH | Final input freeze, bounded evidence index, original RED/GREEN preservation and prior-owner freshness | 174-03-01/02/03 | COVERED |
| RESEARCH | Complete local mix ci and exactly seven hosted jobs; floor advisory and support truth | 174-02-02, 174-04-01 | COVERED |
| RESEARCH | Train authority, conditional synchronized-main helper, retained worktree/demo custody/ranking | 174-03-02, 174-04-02 | COVERED; ranking reviewed before candidate, final read-only reassessment after gates |
| RESEARCH | Honest autonomous prohibition lifecycle and generic/external limits | 174-02-02, 174-03-01/03, 174-04-02 | COVERED |
| CONTEXT | D-01 frozen twelve IDs/ten owners/two actual regressions | 174-01-01, 174-02-01, 174-03-02 | COVERED |
| CONTEXT | D-02 bounded existing journey/package boundary, separate receipt | 174-01-01, 174-02-01 | COVERED |
| CONTEXT | D-03 narrow synthetic scope/authentication-time fixture | 174-01-01/02 | COVERED |
| CONTEXT | D-04 actual wire/persisted observations/controls and external limits | 174-01-01/02, 174-02-01 | COVERED |
| CONTEXT | D-05 freeze actual covered inputs, no restamping/identity loops | 174-03-02/03, 174-04-01/02 | COVERED |
| CONTEXT | D-06 scoped prior verifier reassessment and owned history audits | 174-03-01/02/03 | COVERED |
| CONTEXT | D-07 focused checks then complete local/exact-head hosted gates and matching guidance/floor caveat | 174-02-02, 174-04-01 | COVERED |
| CONTEXT | D-08 reviewed train, exact main if reached or real blockers | 174-04-01/02 | COVERED |
| CONTEXT | D-09 run-owned cleanup and explicit retained custody | 174-01-01, 174-04-02 | COVERED |
| CONTEXT | D-10 embedded/security/dependency/product/release limits and ranking | 174-02-02, 174-03-02, 174-04-01/02 | COVERED; pre-candidate ranking write, read-only final reassessment |
| CONTEXT | D-11 preserve automatic provenance, actual resolved/judgment lifecycle, prominent flags | 174-02-02, 174-03-01/03, 174-04-02 | COVERED |

Deferred ideas remain excluded: publication, external profile preparation/certification, general overlap/interruption guarantees, SEC-01 migration, KMS/Vault and unrelated storage/UI. No selected source item is missing. Actual required remote/review/main outcomes remain observations to obtain, never planning-time green claims.

## Spec-less Edge Coverage and Assumptions

No SPEC exists; the actual seven-row fallback report is lifted without silent drops. Three rows have defensible bounded explicit acceptance in plan truths; four remain flagged assumptions. No generic prompt is converted into a fabricated protocol/concurrency guarantee and no backstop marker is invented.

| Requirement / category | Original probe | Lifecycle / verification | Planned treatment |
|------------------------|----------------|--------------------------|-------------------|
| CPROOF-01 adjacency | When two things are exactly equal or just touch, do they merge, collide, or separate? | unresolved / null | Flagged generic assumption; the finite selection supplies no universal equality/touching contract. Identity mismatch/duplicate tests are separate concrete receipt checks. |
| CPROOF-01 empty | What is the result for empty, single-element, or null input? | resolved / explicit | 174-01 truth: reject null/empty observations/collection and single-case-as-complete; explicit single-case runs are partial. |
| CPROOF-01 ordering | When elements compare equal, is output order specified and stable? | unresolved / null | Flagged generic assumption; no new equal-priority ordering guarantee is selected. Exact ID membership is required independently. |
| CPROOF-02 unclassified | unclassified — review manually | unresolved / null | Flagged assumption, scoped role review; no invented universal package test. |
| DELIV-01 boundary | What happens exactly at each min/max/threshold — and one step either side? | resolved / explicit | 174-04 truth: exact candidate and exactly seven unique canonical successful jobs; six/eight/duplicates/other-SHA cannot pass. |
| DELIV-01 precision | Where can precision loss, overflow, or rounding/tie-breaking occur — and what is the exact contract? | resolved / explicit | 174-04 truth: full lowercase identities and strict exact integer counts, no truncation/float/bool coercion. |
| DELIV-02 unclassified | unclassified — review manually | unresolved / null | Flagged assumption, scoped custody/authority handoff review; no invented mechanical approval or universal clean-workspace guarantee. |

Also retain the three Phase 173 generic limits: interruption/concurrency, unclassified PAR behavior, and supplemental external-profile interruption/parallel guarantees. Their unresolved provenance remains visible and does not substitute for a concrete selected-case failure or proof.

## Prohibition Lifecycle and Ownership

Spec-less recall considered false acceptance, evidence relabeling, host ownership, retained data deletion, scope expansion, weak security defaults, skipped proof, misleading support, raw secrets and publication bypass. Routine correctness is assigned to concrete tests/review; canonical security items refer to the STRIDE/ASVS checks rather than minting duplicate prohibitions. Two phase-wide values/authority declarations survive in 174-01: evidence must not be relabeled across trust categories, and host account/session/login/claims/consent/branding/product policy must not move into Lockspire. Their projection was produced with the canonical `projectProhibitions` serializer: statement + unresolved status, descriptor-less, with no invented check fields. Plan 174-02-02 owns their evidence-supported `resolved/judgment` transition before final proof/candidate freeze; final scoped review is read-only for plan content and retains prominent non-authoritative flags under the specific autonomous soft-gate.

Known older declarations require explicit ownership: 171-01 has one, 171-03 has two and 172-01 has two unresolved descriptor-less items. Plan 174-03-01 owns scoped review and lifecycle-only edits in those three files. Only 171-03 is a frozen manifest entry; only its genuinely changed identity and the owned supported-surface guidance identity may receive attributed old/new/date/source-SHA/reason audits. Other selectors/manifest entries, frozen cases and original receipt/probe bytes remain unchanged. Proper verifier roles own all regenerated reports/fingerprints. Favorable prose must not be silently absorbed as passed while canonical lifecycle remains unresolved.

Track actual flags separately by phase. If all scoped judgments complete, expected counts are 171=3, 172=2, 173=2 and 174=2 (nine recommendations, not nine mechanically verified truths); report actual counts and real gaps. Original automatic declarations/reports remain in git history. No human confirmation or mechanical enforcement is invented. Real required human action or behavior gaps still block; the canonical resolved/judgment autonomous soft-gate never silently drops flags or hard-halts solely on the recommendation.

## Planning Checks and Authority Boundaries

- Existing project source/owner/guide paths were checked with `git ls-files`; new files and runtime outputs are explicitly listed under each plan's artifacts section. Named retained worktree paths are custody inventory, not edit targets. No runtime mirror path is used.
- Read-only prior status baseline: 171=`stale` (covered ledger/protocol/Phase15/controller moved), 172=`stale` (covered ledger/protocol moved), 173=`passed`. Owned lifecycle/ledger changes will require proper affected-owner reassessment after inputs settle.
- API detector over Phase 174 roadmap section + plan bodies returned `detected:false` (normal exit 1 for a negative verdict). `COVERAGE.md` already declares no external API integration. Assumption-delta detector returned `detected:false`. No AI/UI/product identity/schema/platform expansion is selected, and no schema push task is applicable.
- No new package/install task exists; existing dependencies are reused. STRIDE IDs are unique across the phase (`T-174-01`–`T-174-16`, with shared reserved `T-174-SC`); ASVS L1 blocks high/critical. Prior lifecycle reassessment owns T-174-16.
- Reversibility warning on 174-04-02 is a settled-door advisory: D-08 already authorizes the existing reviewed train. It creates no new approval requirement and never bypasses real review/audit/protection conditions.
- Bounded source-bound audit precedes final Phase 174 verification. Canonical full milestone audit may legitimately follow phase completion. If that is a remaining train prerequisite, record the concrete integration blocker/continuation; never make this phase depend on its own future completed report, fabricate an audit pass or re-run runtime proof solely for metadata.
- Candidate identity is the immutable actually executed SHA, not the moving evidence-record HEAD. At its recorded task-1 execution point, Plan 174-04 recomputes real ancestry, every intervening commit's paths (including merge-parent differences), staged/unstaged/nonignored-untracked paths and frozen shipped input/proof-index hashes. Exactly nine report/delivery paths may differ. All PLAN/CONTEXT/VALIDATION files, PROJECT/REQUIREMENTS/ROADMAP/STATE/MILESTONE-ARC, frozen selection/proof inputs and shipped source remain excluded, so acceptance definitions cannot change under the evidence-only allowance. Lifecycle transitions occur in 174-02 and ranking is reviewed in 174-03 before candidate freeze; final flag/ranking review is read-only. A wildcard or attested boolean is insufficient. A later allowed evidence-only commit does not require restamping/CI reruns. Normal subsequent SDK task/plan/phase STATE tracking, verify:post VALIDATION map/status/audit and final completion metadata instead receive scoped owner review of exact before/after deltas before goal verification, confirming acceptance content unchanged and regenerating only affected reports/fingerprints. That review preserves the recorded snapshot identity and does not invent a fresh strict-gate pass; unreviewed scope/criteria changes return to planning/proof owners. Candidate checks stay in the milestone checkout; synchronized main authority uses an owned separate checkout, preserving squash-merge identities.

## Wave 0 Requirements

- [x] 174-01-01: create bounded group, separate strict receipt module/test, source-CI execution and actual packaged tracer
- [x] 174-01-02: add narrow host-owned authentication-time fixtures and six authorization projections
- [x] 174-02-01: implement all six PAR/discovery projections; complete default sweep cannot skip an ID
- [x] 174-02-02: settle shipped guidance and proper-role focused reviews before freeze
- [x] 174-03-01: perform actual prior lifecycle review and only declared owned identity audits
- [x] 174-03-02/03: final complete proof/index/freeze, current source GREEN and proper prior verifier reports
- [x] 174-04: actual exact candidate gates and dated delivery/custody/ranking/flag handoff

## Manual-Only Verifications

Review judgments retain their declared non-authoritative flags in autonomous mode. They are not fabricated mechanical coverage or human confirmation. Actual required reviewer/integration approvals remain governed by the existing train; record concrete blockers only after the work is reviewable. Publication and unavailable external profiles are unselected, not waived selected behavior.

## Validation Sign-Off

- [x] Every selected case has an existing source owner and applicable package projection
- [x] Actual plan IDs/threats/commands mapped; no three-task automated sampling gap
- [x] Package identity, redaction and owned cleanup verified; historical evidence unchanged
- [x] Prior/current verifier owners and focused security reflect actual covered inputs
- [x] Complete local and hosted candidate gates observed at exact identities
- [x] Agent inspected actual PR/audit/ref/JSON facts; optional main receipt passes concrete checks or an actual blocked/unreached-main handoff has a nonempty blocker/next action; retained-resource handoff is exact and honest
- [x] Final audit sets status/Nyquist fields from actual evidence and remaining limitations

Planning sign-off: all four requirements and D-01–D-11 covered; 4 plans / 4 waves / 9 tasks. Frontmatter/structure checks pass; 30 automated commands have adjacent failure conditions and valid shell syntax; 16 nonreserved threat IDs are unique; each task owns at most five files and waves have no file overlap. The settled D-08 reversibility advisory is recorded above. Execution checks and scoped verifier/review evidence are recorded above; parent-owned phasewide final verification, security/review gates and canonical milestone audit remain pending.

## Validation Audit 2026-10-25

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 9 |
| Escalated | 0 |

## Final source review and regression update

The full eight-file source review is clean after valid-receipt substitution repair `a00f0d0a8e4cc276403b5f5dccf37bb63f900458` (Python 16/16; ExUnit bridge 7/7). The affected complete package sweep passed 12/12 at `73bb46811f4b76b2372b4af2b4e21aaf42893ac1`; proper affected prior verifiers are current. Independent ASVS L1 review verifies 17 declared mitigations with focused post-repair applicability review; historical findings remain recorded.

The required current-milestone cross-phase regression gate ran at `3fb357f19252fc760ccc59b6a28c4067439ebf5a`: the nine current test files collected from Phase 171–173 reports, excluding `test_helper.exs` and historical deliberate-RED probes, passed **139 tests, 0 failures**, exit 0. Command: process-local Elixir 1.19.5/OTP 28.5 and owned database `lockspire_171_main_20261024b`, `mix test --include integration` followed by those nine paths. A durable run-owned log and exit marker captured the result; timeout was 1800 seconds. Source/harness/criteria inputs were unchanged during the gate.

Candidate ec6361d predates the repaired test and remains historical evidence. Replacement-candidate local and hosted CI is pending before DELIV-01 can pass; final goal verification and canonical milestone audit also remain pending. The validated coverage map establishes appropriate checks, not premature completion of those gates.
