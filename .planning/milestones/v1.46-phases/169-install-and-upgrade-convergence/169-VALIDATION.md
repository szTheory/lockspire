---
phase: "169"
slug: "install-and-upgrade-convergence"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-22"
source_revision: 04438699011fc22f52c5ea3ff4aa2f014520b26c
---

# Phase 169 — Validation Strategy

> Validate generated adoption, migration safety, structural diagnostics and maintained host convergence on the current locked runtime. Execution outcomes are recorded below; this artifact remains draft until the applicable validation workflow audits it.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix.ConnTest, Phoenix.LiveViewTest, compiled Phoenix router metadata |
| Config | `mix.exs`, `config/test.exs` |
| Runtime prefix | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec` |
| Quick routing check | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs` |
| Full regression gate | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` |
| Format gate | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted` |
| Timing | Measure focused command runtime during execution; full suite is a wave/phase gate, not the per-edit feedback loop. |

## Sampling Rate

- After each task, run its owning focused tests. Every runnable PLAN verification command must have an observable `fails_when` signal.
- After each wave, run the relevant completed-phase test union; before closure run the whole phase union, format check, `mix test.fast`, and `git diff --check`.
- Capture test counts, elapsed time, source revision, result and evidence limits. If a focused command exceeds 30 seconds, choose a meaningful smaller target for per-edit feedback and retain the full check at the task/wave gate.

## Requirement Verification Map

The final decomposition has five two-task plans in three waves. Phase 169 execution is complete; the automated evidence is recorded below without changing the validation draft or Nyquist sign-off status.

| Requirement | Secure behavior / acceptance | Type | Owning existing test files | Status |
|-------------|------------------------------|------|----------------------------|--------|
| HDX-01 | Fresh helper compiles native shared routes; unfinished HTTP and LiveView authorization deny access; endpoint/browser/session guidance is explicit; no assumed host account schema | integration / compiled routes / connected mount | `test/integration/install_generator_test.exs`, `test/lockspire/web/admin_routes_compile_test.exs`, `test/lockspire/web/admin_route_inventory_test.exs` | pass — Plans 01/04 and final 144-test union |
| HDX-02 | Legacy managed conversion; dry-run leaves bytes and manifest unchanged; repeat apply is safe; drift/collisions refuse; host policy/config bytes preserved; transaction/recovery stays intact | filesystem integration | `test/integration/install_upgrade_test.exs` | pass — 15 conversion tests; 24 upgrade/transaction tests |
| HDX-03 | Compiled route/action/session/pipeline/hook inventory and actual first-match dispatch distinguish canonical, incomplete, shadowed and legacy hosts; sentinel secrets absent; policy-proof limit explicit | unit / Mix task / compiled routing | `test/lockspire/install/verify_test.exs`, `test/mix/tasks/lockspire_verify_test.exs` | pass — 31 native verifier tests; 40 complete diagnostic tests |
| HDX-04 | Demo and maintained generated/clean-room hosts use reusable declarations; no duplicate inventory or masking admin forward; docs agree | source contract / compiled routing / connected lifecycle | `test/lockspire/adoption_demo_operator_guard_test.exs`, `test/lockspire/clean_room_release_source_contract_test.exs`, `test/lockspire/web/admin_route_separation_test.exs`, `test/lockspire/web/live/admin/admin_route_integration_test.exs` | pass — 6 demo tests; 16 clean-room tests; final docs contract |

Focused phase union:

```bash
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/adoption_demo_operator_guard_test.exs test/lockspire/clean_room_release_source_contract_test.exs
```

## Wave 0 Requirements

Existing infrastructure covers the phase; no new framework or dependency setup is needed. Add regression cases to the owning files as part of implementation, and keep generated host fixtures coherent with the manifest ownership model. If new test files are introduced, declare their creation before any verification command references them.

New tests are created before first use: `install_admin_integration_test.exs` in 169-01 Task 1; `adoption_demo_admin_integration_test.exs` in 169-04 Task 1; `clean_room_admin_integration_test.exs` in 169-04 Task 2. Each lives in the existing root test selector. No new framework, external API, package install, schema change or CI lane is planned.

## Final Task / Command / Threat Map

All Mix commands use the proven prefix `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec`. The table abbreviates only that prefix; PLAN task commands contain the complete invocation and an immediately following `fails_when`. Nonzero exit or zero executed tests fails any test row.

| Wave | Task | Requirement | Exact command after prefix | Threat Ref | Expected evidence | Outcome |
|------|------|-------------|----------------------------|------------|-------------------|---------|
| 1 | 169-01-1 | HDX-01 | `mix test test/integration/install_admin_integration_test.exs` | T-169-01, T-169-02 | Actual rendered helper: HTTP denial, hook denial, explicit host-policy implementation and real connected overview | pass — Plan 01 summary |
| 1 | 169-01-2 | HDX-01, HDX-04 | `mix test test/integration/install_generator_test.exs test/integration/install_admin_integration_test.exs test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs` | T-169-03, T-169-04 | Ownership/parity, mount boundaries/order, concurrent immutable matching and stale install refusal | pass — Plan 01 summary |
| 2 | 169-02-1 | HDX-02 | `mix test test/integration/install_upgrade_test.exs` | T-169-05, T-169-06 | Pinned historical conversion, older optional fields, create-only policy, preservation/idempotence | pass — 15 tests |
| 2 | 169-02-2 | HDX-02 | `mix test test/integration/install_upgrade_test.exs test/lockspire/install/file_transaction_test.exs` | T-169-07, T-169-08, T-169-09 | Full-tree read-only preview, interrupted apply/recovery and stale competitor refusal | pass — 24 tests |
| 2 | 169-03-1 | HDX-03 | `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs test/lockspire/web/admin_route_inventory_test.exs` | T-169-10, T-169-11 | Public native success/legacy failure and one inventory source | pass — 31 verifier tests |
| 2 | 169-03-2 | HDX-03 | `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` | T-169-12, T-169-13, T-169-14 | Exact malformed/incomplete/shadowed matrix, safe output and visible policy limit | pass — 40 tests |
| 2 | 169-04-1 | HDX-04 | `mix test test/lockspire/adoption_demo_operator_guard_test.exs test/lockspire/adoption_demo_admin_integration_test.exs` | T-169-15, T-169-16, T-169-17 | Actual demo canonical router, HTTP/connected policy and no masking declaration | pass — 6 tests |
| 2 | 169-04-2 | HDX-01, HDX-04 | `mix test test/lockspire/clean_room_release_source_contract_test.exs test/lockspire/clean_room_admin_integration_test.exs test/lockspire/web/admin_route_separation_test.exs` | T-169-18, T-169-19 | Emitted endpoint/session and actual overlay/helper compile/request denial | pass — 16 tests |
| 3 | 169-05-1 | HDX-01–04 | `mix test test/lockspire/documentation_contract_test.exs test/integration/install_admin_integration_test.exs test/integration/install_upgrade_test.exs test/mix/tasks/lockspire_verify_test.exs` | T-169-20 | Guide/package inventory and source-grounded behavioral walk-through | pass — 35 tests in 10.4s (seed 875269) |
| 3 | 169-05-2 | HDX-01–04 | Full phase union in 169-05 Task 2, `mix format --check-formatted`, `mix test.fast`; unprefixed `git diff --check 9500bb4707e24639886382ad5f5e0f0d89488bb9` | T-169-21; all phase threats | Final source-bound results and individual automated closure ledger | pass — 144 tests in 52.1s (seed 61505); format passed; fast 2,006 tests in 192.8s (seed 78614); diff-check passed |

Wave 1 proves the generated path before expansion. Wave 2 plans 02/03/04 have no modified-file overlap; their new tests must use unique temporary roots/namespaces, with only Plan 02 owning the existing fixed upgrade fixture. Wave 3 depends on all three. `T-169-SC` is reserved in every plan: no installation is planned, and any later package addition must satisfy the legitimacy gate before installation.

## Probe Disposition and Explicit Criteria

The supplied spec-less probe proposed eight items. Seven have defensible explicit predicates in PLAN must_haves; one stays an assumption. No backstop or invented passed probe is used.

| Requirement / edge | Planned predicate | Evidence owner | Disposition |
|--------------------|-------------------|----------------|-------------|
| HDX-01 adjacency | Exact admin segments, literal new versus parameter path, adjacent-prefix nonmatches | 169-01-2 and existing route inventory tests | resolved: explicit |
| HDX-01 empty | Missing/empty pipeline/hooks refuse compilation; nil/empty session cannot turn generated denial into allowance | 169-01-1/2 | resolved: explicit |
| HDX-01 ordering | Canonical order, host-first hooks and consent/admin before public forward | 169-01-2 | resolved: explicit |
| HDX-01 concurrency | Immutable repeated/concurrent matching plus stale install/preflight refusal preserves competing bytes | 169-01-2 | resolved: explicit, bounded |
| HDX-02 concurrency | Interruption recovery and stale competing precomputed-plan/destination refusal; no simultaneous-writer promise | 169-02-2 | resolved: explicit, bounded |
| HDX-03 boundary | Root/default/nested mounts and adjacent segment/parameter boundaries checked through compiled dispatch | 169-03-2 | resolved: explicit |
| HDX-03 precision | Exact route/view/action/session/hook equality; one missing/duplicate/wrong tuple fails | 169-03-2 | resolved: explicit |
| HDX-04 unclassified | A-169-HDX-04: no additional predicate was supplied; written HDX-04 criteria remain fully required | 169-05 and verification ledger | unresolved flagged assumption |

Concurrency limits: stale operations, exclusive creates, immutable matching and recoverable interruption are tested; simultaneous generator writers and hostile same-user ancestor replacement are not newly guaranteed. FileTransaction's existing containment limit remains explicit.

## Prohibition Recall and Automated Closure Rules

Stage 1 adversarial recall considered ten candidates per requirement:

| Requirement | Raw candidate concerns |
|-------------|------------------------|
| HDX-01 | Library-owned staff accounts; assumed roles; allow-all seam; cached authority; copied routes; missing endpoint session; missing JS; changed host branding; host login takeover; path collisions |
| HDX-02 | Policy overwrite; runtime config overwrite; managed drift; invented historical authority; dry-run mutation; non-idempotent retry; partial apply; symlink escape; stale preflight; unexpected input reset |
| HDX-03 | Policy certification; transport/package/floor overclaim; secret output; forward false positive; shadowing; approximate tuple match; crash on metadata; missing aggregate errors; guessed host identity; false success from empty hooks |
| HDX-04 | Mandatory standalone service; duplicate demo route source; host layout takeover; policy takeover; contradictory guides; unsupported scope expansion; fake browser proof; package-proof claim from source; unseen fixture drift; manual approval substituted for tests |

Stage 2 retained three bespoke product/ownership/transparency prohibitions. Routine matching, drift, idempotence, collision and fixture correctness belong to behavioral criteria/code review. Canon security concerns (generic access-control, secret disclosure and filesystem traversal) are referred to `$gsd-secure-phase` and the phase STRIDE mitigations rather than minted as extra prohibitions. Embedded-library/host-ownership and evidence limits are grouped into the three kept items below; no kept item was silently dismissed.

The actual `projectProhibitions` serializer from `gsd-core/bin/lib/probe-core.cjs` produced descriptor-less `{statement, status: unresolved}` entries. Those exact projections are in Plans 01, 02 and 03. Initial disposition stays flagged-unverified, not silently green. Project VERIFICATION-POLICY resolves missing descriptors through the following explicit evidence rules, without automatic human UAT:

| Item | Automated/source closure rule | Durable record |
|------|--------------------------------|----------------|
| P-169-01 | Rendered untouched HTTP/hook denial, host-owned manifest exclusion, implemented-host connected path, and source responsibility audit establish no identity/policy/layout takeover | Separate 169-UAT row: criterion, test names/method, result, revision, files and limits |
| P-169-02 | Whole-tree policy/config preservation; create-only bootstrap; checksum/drift/refusal; byte-identical dry-run/repeat; interrupted recovery tests plus ownership source audit | Separate 169-UAT row with the same evidence fields |
| P-169-03 | Public passing/failing output tests state structural limit; guide/source audit distinguishes policy/server-lifecycle/package/transport/exact-floor evidence; Phase 170 remains owner | Separate 169-UAT row with the same evidence fields |

Any missing result remains an explicit verification gap. Reopen a closed record only for a relevant source/criterion change, regression or contradictory evidence; descriptor absence alone is not a reopening trigger. The unclassified edge remains an assumption, not an invented prohibition or human signoff.

## Multi-Source Coverage Audit

| Source | ID / item | Plan | Status | Notes |
|--------|-----------|------|--------|-------|
| GOAL | Safe fresh/existing canonical adoption, responsibilities and diagnosis | 01–05 | COVERED | Entire Phase 169 outcome |
| REQ | HDX-01 | 01, 04, 05 | COVERED | Emitted native path/deny seam, browser/endpoint and host guidance |
| REQ | HDX-02 | 02, 05 | COVERED | Trusted historical conversion and transactional safety |
| REQ | HDX-03 | 03, 05 | COVERED | Exact metadata/dispatch, actionable safe bounded output |
| REQ | HDX-04 | 01, 04, 05 | COVERED | Generated/demo/clean-room/docs converge |
| RESEARCH | Single AdminRoutes inventory and native fixed-session contract | 01, 03, 04 | COVERED | No copied host inventory |
| RESEARCH | Compiling always-deny host Plug/on_mount; no account schema | 01, 02, 04 | COVERED | A1 resolved as implementation choice; host policy stays editable |
| RESEARCH | Current-policy mount/params and host event/logout responsibilities | 01, 04, 05 | COVERED | No continuous revocation promise |
| RESEARCH | Browser/session/endpoint/assets/signing setup | 01, 04, 05 | COVERED | Declaration/guidance now, actual client transport Phase 170 |
| RESEARCH | Exact routes/first-match shadowing/pipeline/hook diagnostics | 03 | COVERED | A2 current runtime, exact-floor validation Phase 170 |
| RESEARCH | Real historical manifest ownership; optional field compatibility | 02 | COVERED | A3 grounded in pinned v1.45 and actual older manifest history |
| RESEARCH | OperationPlan/FileTransaction, drift, dry-run, recovery and symlink bounds | 01, 02 | COVERED | No replacement writer or stronger hostile-writer claim |
| RESEARCH | Redaction and honest policy proof limits | 03, 05 | COVERED | Sentinel cases and evidence audit |
| RESEARCH | Supported/install/admin/demo/upgrade docs and runtime regressions | 01–05 | COVERED | Existing selectors reused; no UI redesign or package publication |
| RESEARCH / contribution | External API capability gate | 01–05; COVERAGE.md | COVERED | Detector matched local endpoint wiring; reasoned no-external-API declaration records the actual scope |
| CONTEXT | No CONTEXT.md or D-NN decisions exists | 01–05 | COVERED | User approved proceeding without it; requirements/roadmap constrain plans |

Exclusions are not gaps: Phase 170 owns actual candidate-package, browser/socket, exact supported floor/current-pair integration and required CI proof. Existing protocol behavior/security defaults, host identity/login/layout ownership and unrelated prior debt remain unchanged in scope.

## Planning Baseline

At `9500bb4707e24639886382ad5f5e0f0d89488bb9`, the proven runtime command `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` with the exact prefix above produced **50 passed in 14.4 seconds**. Existing compiler warnings were present. This grounds command paths/timing; it does not establish any new Phase 169 behavior. No implementation source was changed during planning.

## Manual-Only Verifications

None planned. Follow `.planning/VERIFICATION-POLICY.md`: close routine acceptance and prohibitions with executable evidence and a durable closure ledger. A missing descriptor is a planning defect with an explicit closure rule, not an automatic human checkpoint. No UI copy overhaul or manual signoff is in scope.

Phase 170 owns packaged candidate adoption, real browser/socket transport and exact minimum dependency runtime proof. Current repository compile, connected LiveViewTest and source-contract checks establish only their stated properties.

## Execution Results (169-05)

All final commands used the locked Elixir/Erlang prefix. Phase union and fast-suite
logs are in `/tmp/lockspire169-plan05-union-final.log` and
`/tmp/lockspire169-plan05-fast-final-clean.log` for this execution session.
The tested docs/evidence tree is committed at `95a4f8d4`; the route, template,
diagnostic, and source-contract corrections are in `13e673ce`.

| Command | Result | Evidence boundary |
|---------|--------|-------------------|
| Task 1 tracer: documentation contract, generated admin integration, upgrade integration, verifier task tests | 35 passed in 10.4s; seed 875269 | Repository tests and current locked runtime only. |
| Final Phase 169 union from Plan 169-05 Task 2 | 144 passed in 52.1s; seed 61505 | Includes connected server-side LiveView tests; not browser/socket transport. |
| `mix format --check-formatted` | Pass | Static formatting only. |
| `mix test.fast` | 2,006 passed (2 properties and 2,004 tests), 6 skipped, 497 excluded; 192.8s; seed 78614 | Ran with `LOCKSPIRE_TEST_DB_NAME=lockspire_phase169_fast_final` and `HEX_HOME=/tmp/lockspire-phase169-hex`. `mix test.setup` migrates but does not clear a previously used test database; the default `lockspire_test` had stale rows, so final broad evidence uses a fresh disposable database. |
| `git diff --check 9500bb4707e24639886382ad5f5e0f0d89488bb9` | Pass after removing two pre-existing trailing spaces in `169-PATTERNS.md` | Whitespace/conflict-marker check only. |

Task 1's focused selector and tracer both passed 35 tests. During final broad
verification, two stale static assertions were updated to the emitted
`AdminRoutes` contract and its shared route inventory. The generated template
was also aligned with the formatted maintained fixture. The final fast suite
and phase union passed after those changes. Existing compiler/type-analysis and
generated-fixture warnings remain; no unrelated warning cleanup was attempted.

The implementation, runtime-source explanation, and admin behavior tests do
not establish candidate-package consumption, browser/socket transport, exact
Phoenix 1.8.5 / LiveView 1.1.28 execution, or required CI. Phase 170 retains
each of those evidence owners. No visual approval or user-reported pass is
claimed. The independent validation audit on 2026-10-23 inspected actual
behavioral tests and the final logs, found no coverage gaps across all four
requirements and ten tasks, and confirmed no implementation/test source
changes after the tested source revision `13e673ce`.

## Validation Sign-Off

### Final recovery-remediation revalidation

The final implementation/test revision is `04438699011fc22f52c5ea3ff4aa2f014520b26c`; later commits change documentation and audit evidence only. Review-driven recovery tests strengthen the existing HDX-02 task coverage without adding a new requirement or test-framework dependency. Independent final code review is clean across the preserved 41-file scope, and security re-audit closed all 22 planned threats at this revision.

Final checks ran sequentially because selectors share `test/support/fixtures/generated_host_app`; separate databases alone do not isolate that filesystem fixture. Earlier concurrent union/fast attempts collided and are excluded from proof. The valid final runs are:

| Gate | Final outcome | Log / environment |
|------|---------------|-------------------|
| Phase 169 union, all 16 paths from Plan 05 | 160 passed; 61.0s; seed 866719 | `/tmp/lockspire169-serial-union.log`; fresh DB `lockspire_phase169_serial_union` |
| Prior Phase 167–168 bounded regression, six files | 63 passed; 31.4s; seed 527074 | `/tmp/lockspire169-final-regression.log`; fresh DB `lockspire_phase169_serial_regression` |
| `mix test.fast` | 2,022 passed (2 properties, 2,020 tests); 6 skipped; 497 excluded; 206.0s; seed 198176 | `/tmp/lockspire169-serial-fast.log`; fresh DB `lockspire_phase169_serial_fast` |
| `mix format --check-formatted` | Exit 0 | `/tmp/lockspire169-final-format.log` |
| `git diff --check dd1521e2` | Exit 0 after audit-report whitespace correction | Entire Phase 169 baseline diff |

All Mix commands used `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1` and the isolated `HEX_HOME=/tmp/lockspire-phase169-hex`. The transaction-only selector passed 24 tests and combined transaction/upgrade/generator selector passed 55 in the remediation run. No code changed after these final source-bound checks. Process-interruption/ordinary-error behavior is covered; power-loss durability, directory fsync, hostile same-user path replacement and simultaneous writers are not claimed. Phase 170 retains package/browser/socket/exact-floor/CI evidence.

- [x] Final task IDs, threat references and verification commands mapped after planning.
- [x] Every task has automated verification; no three consecutive tasks without it.
- [x] New test references have creation dependencies; no watch-mode commands.
- [x] Focused check timings measured and acceptable for per-edit feedback; broad commands remain task/wave gates.
- [x] Execution outcomes, source revision and scope limits recorded.
- [x] `nyquist_compliant: true` set by the applicable validation workflow after independent audit.

**Approval:** automated validation verified 2026-10-23; no separate human UAT requested.

## Validation Audit 2026-10-23

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
