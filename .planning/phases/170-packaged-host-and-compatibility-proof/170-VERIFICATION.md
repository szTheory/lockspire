---
phase: 170-packaged-host-and-compatibility-proof
verified: 2026-10-24T10:03:44Z
status: passed
score: 24/24 must-haves verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-01-PLAN.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-01-SUMMARY.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-02-PLAN.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-02-SUMMARY.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-03-PLAN.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-03-SUMMARY.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-04-PLAN.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-04-SUMMARY.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-05-PLAN.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-05-SUMMARY.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-ACCEPTANCE.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-REGRESSION.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-REMEDIATION.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-REVIEW-DISPOSITION.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-REVIEW.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-SECURITY.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-UAT.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-UI-REVIEW.md
  - .planning/phases/170-packaged-host-and-compatibility-proof/170-VALIDATION.md
  - compatibility/phoenix_1_8_live_view_1_1/lib/lockspire_compatibility_fixture.ex
  - compatibility/phoenix_1_8_live_view_1_1/mix.exs
  - compatibility/phoenix_1_8_live_view_1_1/mix.lock
  - compatibility/phoenix_1_8_live_view_1_1/test/admin_host_runtime_test.exs
  - compatibility/phoenix_1_8_live_view_1_1/test/test_helper.exs
  - docs/maintainer-release.md
  - docs/supported-surface.md
  - lib/lockspire/web/admin_mount.ex
  - lib/lockspire/web/live/admin/clients_live/index.ex
  - lib/lockspire/web/live/admin_layout_live.ex
  - scripts/acceptance/clean_room/admin_receipts.py
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room/package_input.py
  - scripts/acceptance/clean_room_admin_journey.py
  - scripts/ci/run_host_integration_proof.sh
  - test/browser/packaged_admin_proof.mjs
  - test/browser/packaged_admin_proof_test.mjs
  - test/clean_room/provider_host/admin_proof.exs
  - test/clean_room/provider_host/admin_proof_live_view.js
  - test/clean_room/test_admin_journey.py
  - test/lockspire/ci_test_matrix_contract_test.exs
  - test/lockspire/compatibility_baseline_contract_test.exs
  - test/lockspire/documentation_contract_test.exs
  - test/lockspire/host_integration_ci_contract_test.exs
  - test/lockspire/web/live/admin/admin_route_integration_test.exs
  - test/lockspire/web/live/admin/device_authorizations_live_test.exs
  - test/lockspire/web/live/admin/interactions_live_test.exs
covered_digest: "v3:sha256:49f6876c77e90751e27ede65aef1962da8fc961a47bce671d3fab6824f2dd39c"
behavior_unverified: 0
overrides_applied: 0
human_verification: []
decision_coverage:
  honored: 0
  total: 0
  not_honored: []
  skipped: "No CONTEXT.md - nothing to check."
---

# Phase 170: Packaged Host and Compatibility Proof Verification Report

**Phase Goal:** Maintainers can establish the delivered admin integration's behavior from the candidate package and supported runtime versions through reproducible automated checks.
**Verified:** 2026-10-24T10:03:44Z
**Status:** passed
**Re-verification:** No — initial verification

## Verification Basis

I inspected the five plans and summaries, roadmap criteria, requirements, project verification policy, acceptance/UAT/validation/remediation/security/review/regression/UI reports, actual source, generated-host templates, workflows, compatibility fixture and current receipts. Current checkout HEAD is `9ecd7d15`; final runtime receipts bind source `7a845ba3e142f3ff1e717d85ebc017d02becfae2`. `git diff 7a845ba3..HEAD` contains only phase acceptance/audit documents; the runtime source represented by the receipts has not changed since their run.

## Roadmap Success Criteria

| # | Success criterion | Status | Evidence and limit |
|---|---|---|---|
| SC-170-01 | Candidate-installed host proves connected operation, navigation, reconnect, denial, mounts, and public access | ✓ VERIFIED | Six current real Chrome/CDP receipts; each passes 16/16 exact cases at `/lockspire`, `/teams/ops/identity`, and `/`. Each binds package/source/runtime identity and reports process, DB, profile, and run-root cleanup true. Synthetic disposable host only. |
| SC-170-02 | Browser evidence covers endpoint session, assets, host-path signing, and remains distinct from server lifecycle | ✓ VERIFIED | Browser receipt `evidence_kind: real_browser_cdp` proves real asset responses, WebSocket LiveView join, navigation/reconnect and path observations. Separate `shared_host_lifecycle` receipts report 43 locked and 44 floor tests. No compilation-only inference. |
| SC-170-03 | Route/session/authorization/navigation regressions run on locked and exact floor pairs | ✓ VERIFIED | Receipts show Phoenix/LiveView `1.8.13/1.2.10` and exact floor `1.8.5/1.1.28`; both browser matrices pass. The final floor fixture rerun passed 44 tests. Actual local BEAM was Elixir 1.20.4/OTP 29, distinct from expected CI BEAM; no broader range is claimed. |
| SC-170-04 | Required CI wiring runs bounded proof, fails visibly, and emits safe source/package-bound evidence without visual approval | ✓ VERIFIED | Existing Integration Checks and Minimum Supported Elixir/OTP workflow jobs invoke the wrapper; contract tests cover failure propagation, independently expected receipt identity, exact case/type checks and safe upload staging. Workflow lint and contract tests pass locally. No hosted run or external branch-protection configuration was observed. |

## Observable Truths

The 20 plan truths below are all checked in addition to the four roadmap criteria; duplicated outcomes are not used to reduce scope.

| # | Truth | Status | Evidence |
|---|---|---|---|
| P01-1 | An actual candidate package installs a disposable host whose signed staff session loads real assets, completes an authorized WebSocket LiveView join and navigates at `/lockspire/admin`. | ✓ VERIFIED | Candidate archive/tree-bound receipts; Chrome/CDP observes assets, handshake, successful LiveView join and DOM/path navigation. |
| P01-2 | Existing provider callers and generated package authorization retain deny-by-default behavior; only explicit disposable proof hosts implement synthetic current staff policy. | ✓ VERIFIED | Generated authorization template still returns 403/redirect by default; proof override lives under `test/clean_room/provider_host/` and is opt-in via `admin_proof=True`. Host ownership audit and default-deny tests pass. |
| P01-3 | Receipt schema 1 binds join/navigation to source, archive/tree and runtimes, records cleanup, and retains no credentials/session/raw frames. | ✓ VERIFIED | All six current receipts pass strict validator with expected run ID, source `7a845ba3…`, pair, mount, hashes, version and exact cases; cleanup booleans are true. Receipt allowlist and sentinel tests pass. |
| P01-4 | Browser/host errors, timeout, malformed observation and failed cleanup fail nonzero; static HTML or open socket alone cannot pass. | ✓ VERIFIED | Node 8/8 and Python 36/36 harness suites exercise failed joins, malformed/empty/duplicate observations, timeout, subprocess/signal and cleanup failures; full-case validator requires successful join/navigation evidence. |
| P02-1 | Real packaged browser operation, same-session navigation, params patches and transport reconnect work at default, nested and root mounts. | ✓ VERIFIED | Three mounts × two dependency pairs, 16/16 cases per receipt; observations include native parameter changes, genuine LiveSocket disconnect/reconnect and subsequent navigation. |
| P02-2 | Anonymous/nonstaff HTTP, cached join after authority withdrawal, denied reconnect and denied native navigation stop before protected callbacks/data. | ✓ VERIFIED | `anonymous_http_denied`, `nonstaff_http_denied`, `cached_join_denied`, `reconnect_denied`, and `params_denied` pass in every current matrix cell with protected callback counters. |
| P02-3 | Public/consent LiveView transitions do not confer admin authority; anonymous discovery and JWKS stay public at each mount. | ✓ VERIFIED | `public_session_denied`, `consent_session_denied`, `public_discovery`, `public_jwks`, and `public_protocol_error` pass per receipt; public cases assert no staff authorization decision. |
| P02-4 | Receipts distinguish server lifecycle, browser join/reconnect and cross-session redirect/fresh entry; reload or DOM class alone cannot pass. | ✓ VERIFIED | Lifecycle and browser evidence have distinct receipt kinds. Browser cases require WebSocket join/hook counters, socket close/rejoin and path/callback evidence; the validator rejects incomplete case/evidence sets. |
| P03-1 | Same four route/inventory/session/connected-authorization/navigation tests execute on current and exact-floor Phoenix/LiveView. | ✓ VERIFIED | Final lifecycle receipts report 43 locked and 44 floor tests; local exact-floor fixture rerun passed 44/44 and reports Phoenix 1.8.5 / LiveView 1.1.28. |
| P03-2 | Full package/browser journey runs on exact floor at default/nested/root with actual versions asserted. | ✓ VERIFIED | Three final floor receipts each pass 16/16; receipt validator compares pair, exact Phoenix/LiveView, source and candidate identity. |
| P03-3 | Root locks and ordinary provider defaults stay unchanged; floor resolution is immutable and isolated. | ✓ VERIFIED | Floor uses dedicated fixture lock and pair-specific cache/hash; root `mix.lock` is not changed by this phase; exact fixture `deps.get --check-locked` succeeded. Generated provider deny template remains unchanged. |
| P03-4 | Compilation, source contracts, server lifecycle and browser evidence are distinct and name exact versions. | ✓ VERIFIED | Separate CI/source contract checks, `shared_host_lifecycle` receipts and `real_browser_cdp` receipts report different evidence kinds and observed runtime versions. |
| P04-1 | Existing required Integration Checks and minimum-supported jobs execute bounded locked/floor proof with visible nonzero failures. | ✓ VERIFIED | `.github/workflows/ci.yml` invokes the pair wrapper in both jobs without `continue-on-error`; wrapper preserves child status; CI contract and failure-injection tests pass. Hosted job execution remains unobserved. |
| P04-2 | Uploaded evidence is checked against independent source/pair/mount/runtime/candidate identity and excludes raw diagnostics/session data. | ✓ VERIFIED | Wrapper validates safe receipts against separately held expected values before staging; only validated JSON receipts are uploaded on success. Python sentinel/error tests pass. |
| P04-3 | Missing/stale/duplicate/incomplete/timed-out/failed-cleanup/malformed evidence cannot seal CI green. | ✓ VERIFIED | Python 36-test suite includes hostile receipt paths and wrapper fake-tool failures; Node suite checks exact unique case set; CI contract tests assert nonzero propagation and upload gating. |
| P04-4 | Exact version/hash comparisons and nonnegative integer millisecond values reject coercion, fractional, negative, nonfinite and boolean values. | ✓ VERIFIED | Strict Python schema checks require exact runtime/hash values and `type(duration_ms) is int`; associated malformed-type and receipt tests pass. |
| P04-5 | CI topology/pins/job names and prior protocol/lifetime checks remain; local lint is not remote-run evidence. | ✓ VERIFIED | Workflow diff preserves existing named jobs and immutable action/service pins; CI test-matrix contract and lint pass. Acceptance ledger labels local evidence separately and states no remote run. |
| P05-1 | Maintainers have exact pair commands and six-cell table with accurate limits. | ✓ VERIFIED | `170-ACCEPTANCE.md`, `docs/supported-surface.md`, and `docs/maintainer-release.md` give locked/floor invocations, prerequisites, versions, mounts, receipt types and local/remote boundary; documentation contract tests pass. |
| P05-2 | Each criterion and kept prohibition has individual evidence closure; descriptor-less items do not silently become human checkpoints. | ✓ VERIFIED | `170-UAT.md` maps each HPROOF requirement, roadmap criterion, P-170-01/02 and A-170-01/02 individually to evidence and limits. The two assumptions remain unclassified and add no predicate; prohibition closures are source/evidence audits. |
| P05-3 | Final evidence refreshes after covered-source changes; historical receipts/closures do not substitute. | ✓ VERIFIED | Current final-containment receipts bind runtime source `7a845ba3…`; superseded initial/intermediate and timed-out floor artifacts are identified as historical and excluded. No later runtime source delta exists. |

**Score:** 24/24 truths verified; behavior-unverified: 0.

## Prohibitions

| Prohibition | Status | Evidence and limit |
|---|---|---|
| P-170-01: Proof infrastructure must not move account/staff identity/policy, login, layout, or branding ownership into Lockspire or require a separate auth service. | ✓ VERIFIED | Production changes are native LiveView navigation and placement of mount-path alignment validation at HTTP entry; current host authorization remains at LiveView boundaries. Generated authorization remains deny-by-default. Synthetic identity/session/policy and proof controls are disposable host code. Package/source boundary audit and 19-threat security audit confirm no production identity/auth API expansion. Arbitrary host policy correctness is not claimed. |
| P-170-02: Package, browser, lifecycle and exact-version evidence must remain distinct and must not be fabricated from compilation or replaced with subjective screenshot/manual approval. | ✓ VERIFIED | Strict evidence kinds and receipts distinguish actual package/browser transport from lifecycle and compilation/contracts. Exact runtime assertions and six actual browser matrices are present. No screenshot signoff or remote-run claim is made. |

The unclassified assumptions A-170-01 and A-170-02 remain unclassified because the source probes supply no additional acceptance predicate; no synthetic pass criterion was introduced.

## Required Artifacts

Plan artifact query result: **16/16 passed across five plans**. Each artifact exists and is substantive; the manual link trace below supplements the structural query, whose lexical matcher did not recognize several indirect Python/fixture links.

| Artifact | Status | Evidence |
|---|---|---|
| `scripts/acceptance/clean_room_admin_journey.py` | ✓ VERIFIED | Package selection, proof-host install, pair/version validation, browser invocation, cleanup, and strict receipt writing; imports package/builder/receipt APIs. |
| `scripts/acceptance/clean_room/build_provider.py` | ✓ VERIFIED | Distinct proof opt-in, mount normalization, pair lock selection, candidate compile binding, source-boundary auditing, and package-template route install. |
| `scripts/acceptance/clean_room/admin_receipts.py` | ✓ VERIFIED | Exact schema, runtime/hash/case/type checks, evidence kinds, cleanup and contradiction rejection. |
| `test/clean_room/provider_host/admin_proof.exs` | ✓ VERIFIED | Substantive host-owned identity, signed session, authorization hooks, current authority and protected fixture observations. |
| `test/browser/packaged_admin_proof.mjs` | ✓ VERIFIED | Real Chrome/CDP and WebSocket browser interactions; exact full scenario observations and owned cleanup. |
| `compatibility/phoenix_1_8_live_view_1_1/{mix.exs,mix.lock,lib/*,test/*}` | ✓ VERIFIED | Frozen floor fixture imports the original route/session tests and runs its host-runtime suite; exact lock check and 44 tests passed. |
| `scripts/ci/run_host_integration_proof.sh`, `.github/workflows/ci.yml` | ✓ VERIFIED | Bounded, fail-closed pair wrapper is called in both existing jobs; validated-only artifact staging and contracts. |
| `docs/supported-surface.md`, `docs/maintainer-release.md` | ✓ VERIFIED | Executable commands and accurate scope/prerequisite interpretation; docs contracts pass. |
| `170-ACCEPTANCE.md`, `170-UAT.md` | ✓ VERIFIED | Six-cell receipts and per-requirement/criterion/prohibition closure ledger with evidence boundaries. |

## Key Link Verification

| From → To | Status | Manual trace |
|---|---|---|
| Journey CLI → builder/package input | ✓ WIRED | CLI calls `prepare_package`, passes candidate identity and `admin_proof=True`/pair/mount into `prepare_provider`, then checks candidate binding. |
| Proof host → generated route template | ✓ WIRED | Builder installs the generated route helper inside the selected mount scope, then overlays only host-owned proof policy; package-generated `lockspire_routes/0` remains the route source. |
| Browser observations → receipt validator | ✓ WIRED | Node returns bounded observations; Python journey maps them into schema 1 and invokes `write_receipt`, which applies strict validation before atomic receipt output. |
| Journey CLI → browser runner | ✓ WIRED | Python invokes Node with run root, pair-selected host origin, mount, scenario and ephemeral capability; browser reports actual observations. |
| Browser runner → proof host | ✓ WIRED | Browser drives real DOM/LiveSocket actions; host records current-authority, hook, callback and protected-data counters consumed by browser assertions. |
| Floor fixture → shared integration test | ✓ WIRED | `Code.require_file` loads the same original admin integration test source after narrow compatibility bootstrap; observed 44 tests pass. |
| Builder → floor lock/cache | ✓ WIRED | Pair table selects `compatibility/phoenix_1_8_live_view_1_1/mix.lock`; lock hash separates cache, and floor runtime is asserted before accepting evidence. |
| Workflow jobs → pair wrapper | ✓ WIRED | Existing locked and minimum-supported job steps call wrapper with the corresponding pair; no ignored failure mode. |
| Wrapper → validator/staged receipt | ✓ WIRED | Each browser run uses independently generated expectations and strict validator before moving safe receipt into upload directory. |
| Maintainer docs → wrapper | ✓ WIRED | Docs include the exact supported locked/floor wrapper commands and preconditions. |
| UAT ledger → acceptance matrix | ✓ WIRED | UAT entries refer to current acceptance receipts/matrix and state each evidence limit. |

## Data-Flow Trace (Level 4)

| Output | Source | Status |
|---|---|---|
| Rendered client list and task paths | Installed candidate package → disposable host database seeded via public Lockspire host facade → real Phoenix LiveView render → Chrome DOM/path and successful join observations | ✓ FLOWING; browser matrix validates assets, joins, rendered navigation and host path prefixes. |
| Authorization decisions and protected callback counts | Disposable host's mutable synthetic current-authority policy → HTTP/on-mount/connected hooks → protected callback/data counters → browser assertions | ✓ FLOWING; test authority is not represented as product host identity correctness. |
| Public endpoint observations | Real anonymous discovery/JWKS/protocol HTTP requests against the same package host, independently counted from staff checks | ✓ FLOWING; public cases pass at all mounts. |
| Retained proof evidence | Observed bounded browser/runtime output plus independently measured candidate/run identity → strict receipt validator → safe JSON artifact | ✓ FLOWING; no raw frames, cookies, credentials, HTML or logs retained in receipts. |

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Full package browser matrix on locked and exact floor pairs | Current final receipts under `.artifacts/phase170/final-containment-{locked,floor-retry}` | Six receipts independently revalidated: 16/16 each, all cleanup true | ✓ PASS |
| Shared server lifecycle on locked and exact floor pairs | Current lifecycle receipts | 43 locked; 44 floor; versions 1.8.13/1.2.10 and 1.8.5/1.1.28 | ✓ PASS |
| Receipt binding and full scenario set | `python3 scripts/acceptance/clean_room/admin_receipts.py --check ...` for each of six receipts with recorded run ID and expected source/pair/mount/hash/version | All six accepted; all require exact 16 case IDs | ✓ PASS |
| Browser tracer logic | `node --test test/browser/packaged_admin_proof_test.mjs` | 8 passed, 0 failed | ✓ PASS |
| Harness errors, redaction, cleanup and receipt failures | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` | 36 passed, 0 failed | ✓ PASS |
| CI, compatibility and documentation contract | Fresh DB `mix test.setup`, then three relevant test files on Elixir 1.20.4/OTP 29 | 19 passed, 0 failed | ✓ PASS |
| Exact-floor generated fixture | `MIX_ENV=test asdf exec mix deps.get --check-locked && MIX_ENV=test asdf exec mix lockspire.test.setup && MIX_ENV=test asdf exec mix test test/admin_host_runtime_test.exs` | 44 passed; runtime asserted Phoenix 1.8.5 / LiveView 1.1.28 | ✓ PASS |

The first Python rerun without ASDF selection failed during class setup when its `mix hex.build` subprocess resolved a nonfunctional system Mix (28 checks had started). The documented ASDF-pinned rerun passed all 36. This is an invocation setup issue, not a code gap.

## Requirements Coverage

| Requirement | Source | Status | Evidence |
|---|---|---|---|
| HPROOF-01 | Roadmap/REQUIREMENTS.md | ✓ SATISFIED | Six candidate-package Chrome/CDP receipts prove admin operation, navigation, reconnect, denial and public access across three mounts. |
| HPROOF-02 | Roadmap/REQUIREMENTS.md | ✓ SATISFIED | Locked and exact-floor lifecycle/browser results with observed pair versions; 43/44 lifecycle tests. |
| HPROOF-03 | Roadmap/REQUIREMENTS.md | ✓ SATISFIED | Required workflow job wiring, bounded failure-visible wrapper, exact receipt contract, failure-injection tests and safe artifact staging. Remote execution was not observed and is not claimed. |

No orphaned Phase 170 requirement IDs were found.

## Anti-Patterns and Test Quality

| Scan | Result | Classification |
|---|---|---|
| `TBD`, `FIXME`, `XXX` in changed implementation/tests/docs | None found | No debt-marker blocker. |
| Placeholder/TODO/empty implementation grep | Matches reviewed in context | `return []` is fail-closed malformed-observation rejection; empty catches occur in owned-process best-effort shutdown before cleanup status is checked; “not available” is a real UI error/recovery state. None is an unpopulated product feature or user-visible stub. |
| Disabled requirement tests | None found in linked Node/Python/ExUnit tests | No skipped-only criterion. |
| Circular tests | None found | Browser receipts use actual candidate install and Chrome/CDP; fake observations are limited to error/schema regression branches. |
| Assertion strength | Behavioral | Browser cases assert multi-step join, navigation, reconnect, denial, callback counters and public access; lifecycle tests run actual LiveView requests. |

The historical independent review covered 27 changed source files, excluded the compatibility lock by stated scope, fixed CR-01 artifact path escape, then re-reviewed clean with 0 open findings. Security audit covers 19/19 threats, including the final containment delta. A separate 202-test prior-phase regression gate and validation/finalizer reports are recorded in phase evidence; no fresh broad-suite result is claimed after the wrapper-only final containment change. UI review is provisional/code-only; native browser cases are functional evidence, not visual approval.

## Probe Execution

No phase-declared `probe-*.sh` was found, and no roadmap success criterion requires a probe. A-170-01/A-170-02 remain unclassified source-probe assumptions with no acceptance predicate; no probe pass is fabricated.

## Decision Coverage

Skipped by the decision-coverage gate: no Phase 170 CONTEXT.md exists, so there were no trackable decisions to compare.

## Human Verification Required

N/A. This phase defines no visual redesign or subjective signoff criterion. The only browser acceptance is functional and automated. No hosted CI run was observed, but the task requires verifiable workflow wiring, not a newly dispatched remote run; local evidence is not presented as remote success. The two unclassified assumptions add no additional acceptance predicate.

## Gaps Summary

No blocking gaps. All roadmap criteria, 20 plan truths, 3 requirements and both prohibitions are verified. Exact host/runtime and CI boundaries are stated above: local locked/floor proof ran on Elixir 1.20.4/OTP 29, CI is wired for its expected BEAM versions, hosted CI status is unavailable, and arbitrary adopter authorization policy plus continuous revocation on an already-connected socket are not claimed by this phase.

---

_Verified: 2026-10-24T10:03:44Z_  
_Verifier: the agent (gsd-verifier)_
