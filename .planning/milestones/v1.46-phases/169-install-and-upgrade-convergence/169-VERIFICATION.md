---
phase: 169-install-and-upgrade-convergence
verified: 2026-10-24T15:38:53Z
status: passed
score: 4/4 roadmap truths verified; 24/24 plan truths verified
covered_files:
- .planning/VERIFICATION-POLICY.md
- .planning/phases/169-install-and-upgrade-convergence/169-01-PLAN.md
- .planning/phases/169-install-and-upgrade-convergence/169-01-SUMMARY.md
- .planning/phases/169-install-and-upgrade-convergence/169-02-PLAN.md
- .planning/phases/169-install-and-upgrade-convergence/169-02-SUMMARY.md
- .planning/phases/169-install-and-upgrade-convergence/169-03-PLAN.md
- .planning/phases/169-install-and-upgrade-convergence/169-03-SUMMARY.md
- .planning/phases/169-install-and-upgrade-convergence/169-04-PLAN.md
- .planning/phases/169-install-and-upgrade-convergence/169-04-SUMMARY.md
- .planning/phases/169-install-and-upgrade-convergence/169-05-PLAN.md
- .planning/phases/169-install-and-upgrade-convergence/169-05-SUMMARY.md
- .planning/phases/169-install-and-upgrade-convergence/169-EXECUTION-GATES.md
- .planning/phases/169-install-and-upgrade-convergence/169-PATTERNS.md
- .planning/phases/169-install-and-upgrade-convergence/169-RESEARCH.md
- .planning/phases/169-install-and-upgrade-convergence/169-REVIEW-DISPOSITION.md
- .planning/phases/169-install-and-upgrade-convergence/169-REVIEW-FIX.md
- .planning/phases/169-install-and-upgrade-convergence/169-REVIEW.md
- .planning/phases/169-install-and-upgrade-convergence/169-SECURITY.md
- .planning/phases/169-install-and-upgrade-convergence/169-UAT.md
- .planning/phases/169-install-and-upgrade-convergence/169-UI-REVIEW.md
- .planning/phases/169-install-and-upgrade-convergence/169-VALIDATION.md
- PRODUCT.md
- README.md
- docs/adoption-demo.md
- docs/install-and-onboard.md
- docs/operator-admin.md
- docs/supported-surface.md
- docs/upgrading/host-admin-integration.md
- examples/adoption_demo/lib/adoption_demo_web/operator_authorization.ex
- examples/adoption_demo/lib/adoption_demo_web/plugs/require_operator.ex
- examples/adoption_demo/lib/adoption_demo_web/router.ex
- lib/lockspire/generators/install.ex
- lib/lockspire/generators/templates.ex
- lib/lockspire/install/file_transaction.ex
- lib/lockspire/install/operation_plan.ex
- lib/lockspire/install/verify.ex
- lib/lockspire/web/admin_routes.ex
- lib/mix/tasks/lockspire.upgrade.ex
- lib/mix/tasks/lockspire.verify.ex
- mix.exs
- mix.lock
- priv/templates/lockspire.install/operator_authorization.ex
- priv/templates/lockspire.install/router.ex
- scripts/acceptance/clean_room/admin_receipts.py
- scripts/acceptance/clean_room/build_provider.py
- scripts/acceptance/clean_room/package_input.py
- scripts/acceptance/clean_room_admin_journey.py
- test/clean_room/provider_host/lib/clean_room_provider_web/operator_authorization.ex
- test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs
- test/clean_room/test_admin_journey.py
- test/integration/install_admin_integration_test.exs
- test/integration/install_generator_test.exs
- test/integration/install_upgrade_test.exs
- test/lockspire/adoption_demo_admin_integration_test.exs
- test/lockspire/adoption_demo_docker_contract_test.exs
- test/lockspire/adoption_demo_operator_guard_test.exs
- test/lockspire/clean_room_admin_integration_test.exs
- test/lockspire/clean_room_release_source_contract_test.exs
- test/lockspire/documentation_contract_test.exs
- test/lockspire/install/file_transaction_test.exs
- test/lockspire/install/verify_test.exs
- test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs
- test/mix/tasks/lockspire_verify_test.exs
- test/support/fixtures/install_upgrade/README.md
- test/support/fixtures/install_upgrade/v1_45_forward_router.ex.eex
- test/support/generated_host_app_web/operator_authorization.ex
- test/support/generated_host_app_web/router.ex
- test/support/generated_host_app_web/router/lockspire.ex
- test/support/lockspire/release_proof/documentation_assertions.ex
- test/support/lockspire/web/admin_proof/route_assertions.ex
covered_digest: v3:sha256:c1989e7aea4dee1ffa0c918ed6cc4c1ec23496817fcdea754b7fb73eaec7be80
behavior_unverified: 0
overrides_applied: 0
assumptions:
  - id: A-169-HDX-04
    status: unresolved_unclassified
    disposition: The probe supplies no additional acceptance predicate. Written HDX-04 criteria have independent executable coverage; no predicate or pass was invented.
  - id: transaction-concurrency-boundary
    status: bounded
    disposition: Evidence covers process interruption and ordinary errors; simultaneous writers, hostile same-user ancestor replacement, power-loss durability, and containing-directory fsync are outside the claim.
gaps: []
deferred:
  - truth: Candidate-package adoption, real browser/socket transport, exact Phoenix 1.8.5 / LiveView 1.1.28 runtime proof, and required CI execution.
    addressed_in: Phase 170
    evidence: Phase 170 roadmap scope and the Phase 169 UAT/validation limits explicitly assign these checks to Phase 170.
source_revision: aaca516db3f33409feb5f4709887ba14a87a51b1
re_verification:
  previous_status: passed
  previous_effective_status: stale
  previous_verified: "2026-10-23 23:32:10+00:00"
  gaps_closed: []
  gaps_remaining: []
  regressions: []
human_verification: []
---

# Phase 169: Install and Upgrade Convergence — Verification Report

**Phase Goal:** A new or existing Phoenix host can adopt the canonical admin integration safely, understand its remaining host responsibilities and diagnose incomplete wiring.
**Verified:** 2026-10-24T15:38:53Z
**Status:** passed
**Re-verification:** Yes — stale covered inputs rechecked inline; no implementation replay

## Goal Achievement

### Re-verification at aaca516d

Re-ran the verification-only execute-phase route inline on 2026-10-24T15:38:53Z. All plans
already have summaries; no implementation task was repeated. The shared record
is [verification-refresh-167-169.md](../../verification-refresh-167-169.md).

The current-source combined selector passed **211 tests in 63.3 seconds** across
19 files. A separate compatibility selector passed **6 tests**. The clean-room
Python harness passed **36 tests in 35.198 seconds** with the documented BEAM
environment. Setup and every final selector exited zero. These runs used a fresh
disposable database and serialized Mix selectors; the exact environment, commands,
files and logs are recorded in the shared record. This one union supplies both
phase checks and prior-phase regression coverage without repeating shared tests.

Rechecked the roadmap criteria, plan truths, required artifacts, links, test
assertions and existing per-prohibition closure records against current source.
No disabled requirement tests, circular inventory oracle, stub implementation,
new goal gap or reopened prohibition was found. Prior broad-suite counts below
remain historical evidence; no fresh broad, browser, package, exact-floor or remote
CI execution is claimed by this refresh. Phase 170 retains its own proof records.

### Changed-input review

Only `docs/supported-surface.md` and the clean-room `build_provider.py` moved
within the earlier report's covered set. The docs now describe Phase 170's
separately recorded local proof and distinguish expected CI runtimes from
observed local execution. The builder retains default deny-first installer
output and requires explicit `admin_proof` opt-in for synthetic policy, proof
routes and exact-floor selection. Frozen pair locks, reused-pair refusal,
bounded subprocesses, endpoint session wiring and overlay separation were
reviewed; the existing source/compile contracts and Python tests exercise them.
Installer ownership, checksum/transaction recovery and structural diagnostics
remain wired and pass the shared behavior selector. No new issue was found.

### Advisory (New Scope, Unevidenced)

None.

### Decision Coverage

No CONTEXT.md - nothing to check. The owner query skipped cleanly; no decisions
were inferred.

The goal is achieved for the repository-source, host-server lifecycle, and guidance scope assigned to Phase 169. The four roadmap success criteria and all 24 plan-level must-have truths are supported by implementation, connected/compiled behavior tests, and the final sequential test evidence below. No user-reported pass is used.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A fresh generated host has explicit route/session, endpoint/browser, and host-authorization wiring; an unfinished staff-policy seam denies by default. (HDX-01) | ✓ VERIFIED | `priv/templates/lockspire.install/router.ex` emits `lockspire_routes/0`, a host pipeline, and the canonical `AdminRoutes` macro; `operator_authorization.ex` denies in both Plug and `on_mount`. `install_admin_integration_test.exs` renders the actual installer output into a temporary host, compiles it, proves HTTP and disconnected/connected hook denial, then proves an explicitly host-authorized connected LiveView. Route inventory/compile and clean-room source-contract tests cover 29 routes, order, session and endpoint declarations. |
| 2 | Existing generated hosts have a concrete, safe path from forward-only routing; previews are read-only, repeats are safe, drift is refused, and host policy/configuration is preserved. (HDX-02) | ✓ VERIFIED | `OperationPlan` checks manifest ownership/checksums and routes mutations through `FileTransaction`; host authorization output is create-only and excluded from managed overwrite authority. Upgrade and transaction tests exercise pinned historical conversion, entire-tree preview snapshots, absent/legacy metadata, drift/collision refusal, idempotence, interrupted recovery/retry, and preservation of competing host bytes. The final transaction remediation tests passed in the recorded sequential run. |
| 3 | `mix lockspire.verify` distinguishes canonical compiled routing and authorization declarations from incomplete, shadowed, or legacy wiring and reports safe, actionable diagnostics with a structural-policy limit. (HDX-03) | ✓ VERIFIED | `verify.ex` reads `AdminRoutes.__route_inventory__/0`, compares compiled route/session/hook structure, and calls `Phoenix.Router.route_info/4` for effective dispatch. The public Mix task aggregates these checks. Verifier/task tests cover default/root/nested mounts, route mutations and first-match shadowing, missing/malformed declarations, sentinel redaction, and the explicit limit that structural checks do not prove host policy. |
| 4 | Demo, generated and maintained clean-room hosts share the reusable declarations, and the install/admin/supported/upgrade guidance agrees with that path. (HDX-04) | ✓ VERIFIED | Demo router uses one native `AdminRoutes` declaration and retains host Plug, layout and current-account hook; the hook resolves current account policy on mount/navigation. Clean-room tests compile actual installer-rendered helper and overlay at default/custom mounts. The four reader guides and demo guidance describe the same seam; documentation contract verifies ExDoc grouping and package inventory. UAT limits package/browser/floor claims to Phase 170. |

**Score:** 4/4 roadmap truths verified; 24/24 plan-level must-have truths verified; 0 present-but-behavior-unverified truths.

### Required Artifacts

Plan artifact queries found 15/15 artifacts present and substantive. Their executable wiring was checked in source and traced through the listed behavior tests.

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `priv/templates/lockspire.install/operator_authorization.ex` | Host-owned deny-first Plug and LiveView hook | ✓ VERIFIED | Rendered by installer inventory as `ownership: :host_owned`; always denies until implemented; integration test compiles and exercises both boundaries. |
| `priv/templates/lockspire.install/router.ex` | Generated canonical routes and explicit host seam | ✓ VERIFIED | Emitted helper calls the native macro with the host pipeline and hook; compiled rendered-host test and 29-route assertions. |
| `test/integration/install_admin_integration_test.exs` | Rendered fresh-host behavior | ✓ VERIFIED | Uses actual installer output, compiles host, tests denial and implemented-policy allowance including LiveView connection. |
| `test/support/fixtures/install_upgrade/v1_45_forward_router.ex.eex` | Pinned historical forward-only host | ✓ VERIFIED | Upgrade tests render the fixture against its recorded manifest hash and convert via the public task. |
| `lib/lockspire/install/operation_plan.ex` | Immutable upgrade planning, dry-run and ownership rules | ✓ VERIFIED | Calls recovery/transaction APIs; no-override planning preserves manifest inputs and preview selects read-only inspection. |
| `test/integration/install_upgrade_test.exs` | Historical conversion and preservation behavior | ✓ VERIFIED | Covers conversion, repeat, drift, policy/config bytes, preview and recovery refusal. |
| `lib/lockspire/install/verify.ex` | Structural route/session/hook diagnostics | ✓ VERIFIED | Uses compiled inventory and first-match router dispatch; emits bounded actionable checks. |
| `lib/lockspire/web/admin_routes.ex` | Canonical reusable native route inventory | ✓ VERIFIED | Exposes the shared inventory/macro; compile and inventory suites assert exact paths, actions, session and order. |
| `test/lockspire/install/verify_test.exs` | Structural verifier behavior | ✓ VERIFIED | Exercises normal, malformed, incomplete and shadowed compiled-router cases. |
| `examples/adoption_demo/lib/adoption_demo_web/operator_authorization.ex` | Current host demo policy hook | ✓ VERIFIED | Resolves the session reference through `Accounts`; integration tests reject forged/stale/nonstaff identities and test navigation. |
| `test/lockspire/adoption_demo_admin_integration_test.exs` | Demo route and connected authorization behavior | ✓ VERIFIED | Checks actual compiled route inventory, anonymous/nonstaff denial, authorized overview and native LiveView navigation. |
| `test/lockspire/clean_room_admin_integration_test.exs` | Maintained clean-room host integration | ✓ VERIFIED | Compiles the generated helper plus overlay at default and nested custom mounts and invokes deny callbacks. |
| `docs/upgrading/host-admin-integration.md` | Concrete migration and reconciliation guide | ✓ VERIFIED | Describes checksum-trusted conversion, read-only/recovery preview, safe repeat, manual drift reconciliation, host policy, endpoint/browser work and proof limits. |
| `.planning/phases/169-install-and-upgrade-convergence/169-UAT.md` | Per-criterion automated closure ledger | ✓ VERIFIED | Individually records four requirements and three prohibitions with method, result, revision, files and limitations; keeps A-169-HDX-04 unresolved/unclassified. |
| `.planning/phases/169-install-and-upgrade-convergence/169-VALIDATION.md` | Final command, threat and proof-boundary record | ✓ VERIFIED | Contains final sequential runs and excludes invalid concurrent attempts; scopes package, browser, exact-floor and CI work to Phase 170. |

### Key Link Verification

The generic `verify.key-links` query reports several false negatives because it looks for literal target paths in source and does not follow macros, aliases, generated bytes, or test execution. I traced each declared link to its actual API call and behavior test; the false negatives are not missing wiring.

| From → To | Status | Evidence |
|---|---|---|
| `lib/lockspire/generators/templates.ex` → generated authorization template | WIRED | Inventory entry names the template, output path and `:host_owned` ownership; installer render test asserts emitted file and ownership. |
| Generated router template → `AdminRoutes` | WIRED | `lockspire_routes/0` expands into `lockspire_admin_routes/2`; rendered-host test compiles and dispatches the emitted helper. |
| Fresh-host test → generated router template | WIRED | Integration test renders public installer bytes instead of copying an independent helper. |
| Upgrade task → `OperationPlan` → `FileTransaction` | WIRED | Public task calls `OperationPlan.upgrade`; planning path calls transaction recovery/apply; transaction tests cover publication and recovery. |
| Verifier → `AdminRoutes` / `Phoenix.Router` | WIRED | Inventory is obtained from `AdminRoutes`; exact effective dispatch uses `route_info/4`; verifier tests exercise both. |
| `mix lockspire.verify` → verifier checks | WIRED | Task invokes and aggregates `Lockspire.Install.Verify` checks; task tests cover successful/failing safe output. |
| Demo router and policy → canonical inventory and `Accounts` | WIRED | One macro call in router; hook resolves `demo_login` through `Accounts.get/1`; compiled route and connected LiveView tests exercise the flow. |
| Clean-room overlay → generated helper | WIRED | Patch calls the rendered helper and supplies host-owned Plug/hook; integration test compiles actual overlay plus installer output. |
| Install/upgrade guidance → templates/tasks | WIRED | Guides name the actual helper, macro, task options and ownership behavior; documentation contract and behavioral tests cover the described path. |
| `mix.exs` → upgrade guide | WIRED | ExDoc extras, Upgrade group and package inventory include the guide; documentation contract asserts inclusion and no duplicate entry. |

### Data-Flow Trace (Level 4)

No new dynamic UI artifact was introduced. For generated/runtime outputs, data flows from installer-rendered template bytes into a compiled Phoenix router; effective paths are returned by Phoenix's compiled route inventory and selected by `route_info/4`. Upgrade planning reads manifest checksums and current host bytes, creates a plan, and passes artifacts to the file transaction. No rendered value in this phase terminates in a static/mock data source.

### Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| HDX-01 | 169-01, 169-04, 169-05 | SATISFIED | Installer-rendered compile/request/connected LiveView denial and host-authorized path; endpoint/router contracts and docs tests. |
| HDX-02 | 169-02, 169-05 | SATISFIED | Pinned history, checksum authority, whole-tree dry-run, repeated apply, drift refusal, host-byte preservation and interruption/retry behavior. |
| HDX-03 | 169-03, 169-05 | SATISFIED | Compiled structure and dispatch checks, failure/redaction output tests, actionable migration hints and explicit policy limit. |
| HDX-04 | 169-01, 169-04, 169-05 | SATISFIED | Demo and clean-room macro convergence plus install/admin/supported/upgrade documentation and ExDoc/package contract. |

No Phase 169 requirement is orphaned. HPROOF-01, HPROOF-02 and HPROOF-03 are separate Phase 170 requirements, not Phase 169 gaps.

### Prohibitions

| Prohibition | Verification | Status |
|---|---|---|
| P-169-01: preserve host identity, accounts, login and policy ownership | Installer-rendered fail-closed seam, host-owned inventory classification, independent HTTP/hook checks and source review | VERIFIED |
| P-169-02: preserve host authorization and configuration decisions | Checksum-tracked managed updates, absent-only seam creation, byte snapshots, drift/collision refusal and transaction recovery tests | VERIFIED |
| P-169-03: keep diagnostics/adoption claims within evidence | Sentinel-redaction tests, explicit structural-policy limit, source review and Phase 170 ownership in guidance | VERIFIED |

The original plans' missing prohibition descriptors are planning metadata; the project verification policy and executable evidence resolve these records without inventing a human-approval requirement.

### Assumptions and Evidence Limits

- `A-169-HDX-04` remains an unresolved, unclassified probe assumption. The probe supplies no separate predicate. Written HDX-04 criteria are independently test-covered, so this does not create an unknown requirement or an invented pass.
- Transaction guarantees cover process interruption and ordinary errors. Simultaneous writers, hostile same-user ancestor replacement, power-loss durability, and containing-directory fsync remain outside the claim. Unsupported hard-link and cross-filesystem publication refuses safely.
- Tests exercise repository source and current locked runtime. They do not establish candidate-package consumer adoption, actual browser/socket transport, exact Phoenix 1.8.5 / LiveView 1.1.28 behavior, or remote required-CI results. Those checks remain assigned to Phase 170.
- The roadmap query still displays `4/5 plans executed` and 169-05 unchecked even though `169-05-SUMMARY.md`, UAT and final validation evidence exist. This is a roadmap bookkeeping discrepancy; it does not contradict the observed implementation or test outcomes and was not edited as part of this verification.

### Historical Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Fresh generated host denies until policy is implemented | Final Phase 169 union includes `install_admin_integration_test.exs` and rendered-host compile/request tests | Union: 160 passed | ✓ PASS |
| Historical upgrade preview, refusal, recovery and retry preserve host bytes | Final union plus transaction/upgrade focused recovery evidence | Union: 160 passed; focused transaction: 24 passed; combined transaction/upgrade/generator: 55 passed | ✓ PASS |
| Verifier rejects incomplete/shadowed structure and redacts sentinels | Final union includes verifier, route compile/inventory and Mix task tests | Union: 160 passed | ✓ PASS |
| Demo and clean-room hosts use actual canonical declarations | Final union includes demo and clean-room connected/compiled integration tests | Union: 160 passed | ✓ PASS |

### Historical Test and Quality Evidence

Final checks ran sequentially with Elixir 1.20.4-otp-29 / Erlang 29.1.1 and fresh isolated databases. These original full-suite artifacts remain historical; this refresh reran the bounded shared selection described above.

| Check | Recorded outcome | Evidence |
|---|---|---|
| Phase 169 union (all 16 selectors) | 160 passed, 61.0s, seed 866719 | `/tmp/lockspire169-serial-union.log`, fresh database `lockspire_phase169_serial_union` |
| Prior Phase 167–168 six-file regression | 63 passed, 31.4s, seed 527074 | `/tmp/lockspire169-final-regression.log`, fresh database `lockspire_phase169_serial_regression` |
| `mix test.fast` | 2,022 passed (2 properties + 2,020 tests), 6 skipped, 497 excluded; 206.0s, seed 198176 | `/tmp/lockspire169-serial-fast.log`, fresh database `lockspire_phase169_serial_fast` |
| Transaction-focused recovery selector | 24 passed; combined transaction/upgrade/generator selector 55 passed | Recovery remediation evidence in `169-VALIDATION.md` and `169-SECURITY.md` |
| `mix format --check-formatted` | Exit 0 | `/tmp/lockspire169-final-format.log` |
| `git diff --check dd1521e2` | Exit 0 | Final phase baseline diff; result recorded in `169-VALIDATION.md` |

The requirement-linked test scan found no disabled tests. The anti-pattern scan found no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, or placeholder implementation in the 41 changed implementation/test/docs files. Matches for the word “Placeholder” occur only in verifier test fixture route modules and are test inputs, not product stubs. Independent review disposition records five recovery findings fixed and zero open; the final review is clean across 41 files. Security re-audit reports 22/22 threats closed, including all affected transaction threats, with no accepted risk or transfer.

### UI Review

The UI review found no changed rendered visual surface. This phase changes generated integration, diagnostics and guidance while retaining the demo layout/branding. No six-pillar score or screenshot is claimed; visual signoff is not needed for the scoped work. The UAT/UI audit leaves actual browser interaction and transport to Phase 170.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | — | No unresolved debt markers or production stubs found in the changed-file scope | — | No blocker |

## Human Verification Required

None. Written acceptance criteria, behavioral properties, and evidence boundaries have deterministic source/test coverage. The unresolved assumption has no predicate to hand to a human; the explicit project policy says not to invent a manual checkpoint for it.

## Gaps Summary

No Phase 169 goal gaps remain. Phase 170's package, browser/socket, exact-floor and required-CI proof remains deferred to that phase by explicit roadmap ownership and does not reduce this phase's narrower goal achievement.

---

_Verified: 2026-10-24T15:38:53Z_
_Verifier: the agent (gsd-verifier)_
