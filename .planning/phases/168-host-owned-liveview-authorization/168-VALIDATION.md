---
phase: "168"
slug: "host-owned-liveview-authorization"
status: planned
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-22"
---

# Phase 168 — Validation Strategy

Planning contract only; no Phase 168 runtime result is claimed. Three plans contain six tasks across three sequential waves. Runtime evidence and closure dispositions remain pending execution. Authoring revision: `66fa5c7aa5ee873ecfb2746f52190d03fda97f5f`; bind actual results to the executed source revision, rather than restamping this revision as a runtime pass.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix.ConnTest, Phoenix.LiveViewTest, router metadata |
| Configuration | mix.exs; config/test.exs; existing host fixture and test endpoint |
| Runtime prefix | ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec |
| Quick run | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` |
| Focused union | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` |
| Full suite | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` |
| Format | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted` |
| Estimated runtime | Measure during execution; focused feedback target under 30 seconds after compilation |

## Sampling Rate

- After each task, run the smallest owning test selection; no three consecutive tasks without automated feedback.
- Verify the leading end-to-end tracer before expansion tasks. Keep negative assertions for no protected render/data/action and positive controls for allowed staff.
- After each wave, run its focused union. Run format, full suite and `git diff --check` once at the final phase gate; repeat only after relevant changes/failures.
- Every runnable task command has a `<fails_when>` stating its observable failure signal.
- If a focused file exceeds the latency budget, use deterministic ExUnit tags and record the complete selected union. Do not drop acceptance rows to reduce runtime.

## Per-Task Verification Map

Command aliases below expand to the full Test Infrastructure commands above; execution must record the actual command and result, not just the alias. Every task has an automated command immediately followed by an observable fails_when. No textual count/negative-grep gates are used.

| Plan/task | Requirement | Predicate and evidence | Automated selection | Threat Ref | Status |
|-----------|-------------|------------------------|---------------------|------------|--------|
| 168-01 Task 1 (tracer) | HAUTH-01, HAUTH-02 | Real default admin HTTP/connected success; authenticated policy refusal; connected denial after authorized static response and current-policy withdrawal | Runtime prefix + `mix test test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/admin_route_separation_test.exs` | T-168-01, T-168-02, T-168-04 | pending |
| 168-01 Task 2 | HAUTH-01, HAUTH-02 | Missing/invalid/disallowed HTTP matrix; independent disconnected hook and connected probe sentinel ordering; concurrent provenance/cleanup; absent/nil/empty wiring refused | Runtime prefix + `mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/admin_route_separation_test.exs` | T-168-01 through T-168-05 | pending |
| 168-02 Task 1 (tracer) | HAUTH-02, HAUTH-04 | Original signed response joins a distinct connected process; policy withdrawal denies new join without another GET or session callback | Quick run | T-168-06, T-168-08 | pending |
| 168-02 Task 2 | HAUTH-02, HAUTH-04 | Current session invalidation/binding removal, identity deletion and permission withdrawal denied; still-authorized allowed at default/nested/root; no protected callback/data/action | Runtime prefix + `mix test test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` | T-168-06 through T-168-09 | pending |
| 168-03 Task 1 (tracer) | HAUTH-03 | Connected consent cross-session error redirect, explicit fresh HTTP/live denial or allowed entry with current policy | Runtime prefix + `mix test test/lockspire/web/admin_route_separation_test.exs` | T-168-10, T-168-13 | pending |
| 168-03 Task 2 | HAUTH-01 through HAUTH-04 | Public/consent boundary matrix; 29 destination metadata and live-navigation outcomes at all mounts; native patch current-policy guard; complete evidence map | Focused union, Format, Full suite, `git diff --check` | T-168-10 through T-168-14; all phase threats in final union | pending |

T-168-SC is reserved/shared across plans: no dependency installations are planned. ASVS L1, block critical/high; mitigate medium threats at primary boundaries. No new package legitimacy or schema push task is applicable: this phase changes only fixture/tests/evidence, no new package or schema files. If an install is proposed later, research legitimacy audit plus blocking assumed/suspect-package review must precede it.

| Wave | Plan | Needs | Creates | Checkpoint |
|------|------|-------|---------|------------|
| 1 | 168-01 | Phase 167 native routes and fixture | Current authority contract and entry denial proof | none |
| 2 | 168-02 | 168-01 fixture/session/trace contract | Cached-response distinct connected-join proof | none |
| 3 | 168-03 | 168-01/02 proven entry/rejoin | Cross-session/patch/destination proof and final evidence closure | none |

Shared fixture/integration files and global mount/observer authority make sequential waves intentional. No same-wave file or mutable-state overlap exists. Estimates use measured calibration factor 0.5, sample_count=6, confidence=high: raw 32000/25000/36000 tokens → calibrated 16000/12500/18000. Existing modified code/CI paths were grounded by nonempty `git ls-files -- <path>` during planning; phase artifacts are newly authored paths. Installed dependency source is reference-only, never an edit target.

## Wave 0 Requirements

- Reuse existing endpoint, RepoCase and host route fixtures; no framework or dependency installation is required.
- Add deterministic mutable current-host-authority scenarios, with cleanup and isolation, to cover authenticated-but-disallowed and authority-withdrawal cases.
- The leading tracer establishes public `live(sent_conn)` on an already-rendered 200 response before expansion. Installed LiveViewTest documents this without a path as converting the existing response to a connected view immediately. Plan 02 preserves that original signed response/session for a distinct new server process and explicitly asserts no additional GET/session callback. Runtime success is pending; unsupported behavior must remain a visible blocker, never be replaced by fresh-GET denial alone.
- Serialize global mount configuration changes and restore state with `on_exit`.

No separate Wave 0 scaffold is needed: all owning test files, ExUnit, endpoints and repository support already exist. Task 168-01.1 creates the mutable authority and first new regression in those existing files before its verify. Wave 0 completion remains false until the execution evidence is recorded.

## Probe and Assumption Ledger

No SPEC or CONTEXT was supplied; the user authorized research and planning from the approved requirements/roadmap. No new user decision is manufactured. All eight rows from the orchestrator's edge report are retained below: five explicit planned predicates and three flagged unresolved assumptions. Original probe status was unresolved for all eight; explicit-predicate authoring is not a claim that runtime verification has passed.

| ID | Requirement / category | Original probe | Planned predicate or flagged assumption | Owner / closure |
|----|------------------------|----------------|-----------------------------------------|-----------------|
| A-168-P01 | HAUTH-01 / concurrency | If interrupted or run in parallel, what is guaranteed? | Explicit: mixed allowed/denied requests under a fixed mount preserve decision and trace provenance; supervised workers and authority cleanup leave the next request unaffected. | 168-01.2 HTTP assertions and interruption/cleanup controls; T-168-04. |
| A-168-P02 | HAUTH-02 / unclassified | unclassified — review manually | FLAGGED UNRESOLVED: no behavioral dimension was supplied. Do not invent an additional acceptance contract or resolve via backstop. | Preserve the flag; approved HAUTH-02 scope is separately tested by 168-01 and 168-02. No automatic human UAT follows from this classifier label. |
| A-168-P03 | HAUTH-03 / boundary | What happens exactly at each min/max/threshold — and one step either side? | Explicit: exact admin bases and literal /clients/new select protected destinations; near-prefix siblings do not enter admin; every task/detail suffix retains protected metadata. No numeric threshold is inferred. | Existing independent inventory boundaries retained/extended in 168-03.2; T-168-11. |
| A-168-P04 | HAUTH-03 / adjacency | When two things are exactly equal or just touch, do they merge, collide, or separate? | Explicit: public/consent sessions remain distinct from :lockspire_admin; overlapping literal/parameterized and nested task suffixes select their own expected action and complete host hooks. | 168-03.1/2 separation, selected-route assertions and behavioral destination checks; T-168-10/11. |
| A-168-P05 | HAUTH-03 / empty | What is the result for empty, single-element, or null input? | Explicit: missing/nil/empty required pipeline/hooks are refused; one hook and ordered multiple hooks preserve all destination protection metadata. | 168-01.2 compile cases and 168-03.2 complete metadata; T-168-03/11. |
| A-168-P06 | HAUTH-03 / ordering | When elements compare equal, is output order specified and stable? | Explicit: repeated/concurrent route matching preserves exact declared inventory and hook order, including one view module with different actions; destination host hooks precede AdminMount. No arbitrary sorting interface is introduced. | Existing repeat/concurrent inventory and ordered multi-hook compile controls retained by 168-03.2; T-168-11. |
| A-168-P07 | HAUTH-03 / precision | Where can precision loss, overflow, or rounding/tie-breaking occur — and what is the exact contract (e.g. half-up vs half-to-even, ceil/floor/truncate)? | FLAGGED UNRESOLVED: the source defines no numeric authorization threshold, arithmetic or rounding contract. Resource identifiers remain existing opaque route inputs; inventing a numeric policy would change scope. | Preserve missing-contract flag; approved route/session authorization checks proceed in 168-03.2. Request classification only if numeric behavior is introduced or acceptance changes. |
| A-168-P08 | HAUTH-04 / unclassified | unclassified — review manually | FLAGGED UNRESOLVED: no extra reconnect dimension was supplied. Do not mark it resolved/backstop based on passing written cases. | Keep flag separate from approved invalid-session/deleted-identity/withdrawn-policy/allowed matrix in 168-02. No invented human check. |

Additional research assumptions, not replacements for the eight rows:

| ID | Status / criterion | Evidence / limits |
|----|--------------------|-------------------|
| A-168-LV-REJOIN (research A1) | Mechanism grounded, runtime pending: public live(initial_sent_conn) must start a distinct connected lifecycle from unchanged initial signed HTML/session after old PID termination. | Installed LiveViewTest live/3 docs and source support already-rendered conn without GET; 168-02 requires runtime proof and no HTTP/session callback. If unsupported, retain failure and amend the server lifecycle plan; Phase 170 transport ownership does not waive this server proof. |
| A-168-XSESSION | Mechanism grounded, runtime pending: live_redirect returns distinct-session error; fresh source-cookie HTTP/live entry rechecks current host policy. | Installed helper docs/source; 168-03.1/2 prove each stage. No actual browser reload is claimed. |
| A-168-PATCH | Existing native patch links do not remount on_mount. | 168-03.2 composes a host-owned handle_params guard through the existing on_mount seam; current policy is resolved at each params transition before protected params. Events and proactive logout/disconnect remain host responsibilities. |

### Prohibition recall and descriptor-less closure ledger

Recall considered per-requirement silent drift: host-owned account/session/permission takeover; allow-all host example; protected data before denial; stale flags; combined public/consent staff auth; duplicated route inventory; continuous-revocation claims; arbitrary role/MFA/tenant policy; package/browser/exact-floor overclaims; forced manual signoff. Routine engineering candidates belong to the denial/edge matrix and code review. Canon authentication/access-control and disclosure items refer to the STRIDE/ASVS register and `$gsd-secure-phase`, rather than being minted as extra prohibitions. Two bespoke ownership/evidence constraints survive precision. No prohibition is silently dismissed.

The two frontmatter entries were produced by the shared `projectProhibitions` serializer from unresolved items. Their projection has only `statement` and `status: unresolved`; no wired check descriptor is added. The serializer/disposition remains flagged-unverified. The ledger below supplies explicit evaluation criteria and closure methods; a later successful ledger review does not fabricate a wired machine pass or erase the original flags.

| ID / location | Criterion | Automated/source closure method | Result / revision | Evidence limits / reopen trigger |
|---------------|-----------|----------------------------------|-------------------|----------------------------------|
| P-168-01 / 168-01 must_haves.prohibitions | Lockspire retains no new staff identity/login/session/role policy implementation; required host pipeline/hooks and policy-owned redirect remain explicit. | Run focused union; inspect changed production diff (expected none) and host fixture separation. Confirm mutable identities/sessions/policy and params guard are confined to test/support. Bind findings to executed revision and actual paths. | Pending execution/source evaluation; authoring source 66fa5c7aa5ee873ecfb2746f52190d03fda97f5f. | Proves this library seam/example, not arbitrary adopter authorization. Reopen only for relevant covered-source change or contradictory evidence. No human judgment is inherently required by missing descriptor. |
| P-168-02 / 168-02 must_haves.prohibitions | Phase 168 claims HTTP/server lifecycle/navigation/rejoin only; no continuous old-socket revocation, real transport, package or exact-floor pass is implied. | Compare actual helpers, source/lock versions, focused results and SUMMARY/verification wording to claimed boundaries; 168-02 proves cached-response new connected process, 168-03 separates cross-session redirect and fresh GET. Record test facts separately from scoped source/evidence review. | Pending execution/evidence review; authoring source 66fa5c7aa5ee873ecfb2746f52190d03fda97f5f. | New connected server join is not browser network recovery. Phase 170 owns transport/package/exact-floor proof; Phase 169 owns guidance convergence. Reopen on changed claims/helpers or contrary evidence. |

At closure record each item's criterion, method, actual result, source revision and limits in this ledger or a linked phase UAT/verification closure ledger; retain original serialized flags as historical metadata. If evidence is insufficient, record a specific gap and obtain/add the missing deterministic proof. Do not convert missing descriptors into a blanket human UAT request. Phase 167's two resolved prohibitions in 167-UAT.md remain closed; this phase evaluates only its changed/new source and claims, and any reopening must name a relevant changed-evidence trigger.

## Multi-Source Coverage Audit

| SOURCE | ID / source item | Plan / task | Disposition |
|--------|------------------|-------------|-------------|
| GOAL | Current host staff policy controls HTTP and LiveView entry while host retains identity/permission ownership | 168-01 through 03 | COVERED: entry, new join, destination/patch proof and ownership ledger. |
| REQ | HAUTH-01 initial HTTP/no data/no action/allowed staff | 168-01.1/2; final 168-03.2 union | COVERED. |
| REQ | HAUTH-02 disconnected/connected current authority and required wiring refusal | 168-01.1/2, 168-02.1/2 | COVERED. |
| REQ | HAUTH-03 public/consent and admin destination/session/hooks | 168-03.1/2 | COVERED including same-view params patches. |
| REQ | HAUTH-04 invalid/withdrawn/allowed reconnect authorization | 168-02.1/2 | COVERED as original signed-session new connected server lifecycle; actual transport owner remains 170. |
| RESEARCH | Align nonempty-ID HTTP fixture with independently current identity, valid session and staff policy | 168-01.1/2 | COVERED by deterministic host-only authority and denial matrix. |
| RESEARCH | Missing/invalid/disallowed/allowed controls at HTTP/disconnected/connected; no protected callback/data/action | 168-01.1/2, 168-02.2 | COVERED with real-page and independent sensitive probe controls. |
| RESEARCH | Complete 29-route/action protected metadata and actual destination execution | 168-03.2 | COVERED with independent literal inventory and allowed/denied navigation, retaining existing route semantics. |
| RESEARCH | Cross-session mechanism and proof boundary | 168-03.1/2 | COVERED: error redirect then explicit fresh HTTP/live entry; public/consent stay separate. |
| RESEARCH | Fresh authority on rejoin, actual lifecycle not synthetic socket only | 168-02.1/2 | COVERED: cached original HTML/session and new PID; mechanism failure stays visible. |
| RESEARCH | Current host policy / no account or role engine / host ongoing event and disconnect responsibility | 168-01 contract; 168-03.2 guard/ledger | COVERED host-owned composition and explicit limits. |
| RESEARCH | No production restructuring, no dependency upgrade, no private join patches, exact evidence/versions | All plans, final ledger | COVERED by test-only changes and current locked runtime evidence. |
| RESEARCH | Mutable state isolation, serial global config, cleanup/concurrency | 168-01.1/2 and all later fixture consumers | COVERED; no sleeps/polling. |
| RESEARCH | Automation-first verification, reuse CI selection, preserve closed 167 UAT | 168-03.2 and closure ledger | COVERED; local checks do not claim remote CI. |
| RESEARCH | Generator/demo/install/upgrade/docs convergence | Approved Phase 169 | EXCLUDED from Phase 168 by approved roadmap owner, not dropped. |
| RESEARCH | Candidate package, actual browser/socket, exact Phoenix 1.8.5/LiveView 1.1.28 and required proof CI | Approved Phase 170 | EXCLUDED from Phase 168 by approved roadmap owner; current lock pair is 1.8.13/1.2.10. |
| CONTEXT | No CONTEXT.md or D-NN decisions supplied | Approved specless planning | N/A, no invented locked decisions or deferred ideas. |

No in-scope source item is unplanned. Three missing probe contracts remain flagged assumptions; they do not erase the separate approved HAUTH acceptance criteria. No manual visual signoff or broad new product decision is introduced.

## CI and Evidence Closure Rules

- Existing mix test.fast selects test/lockspire, test/mix and test/integration while excluding lifetime_package. All new acceptance cases remain unexcluded in existing test/lockspire files. Recheck that selector during 168-03.2; add no duplicate CI job.
- Capture command exit status, failed/selected test names, executed revision, actual versions and exact evidence kind. Tests must run before a result is called passed. A focused selection target is under 60 seconds after compilation; if exceeded, use deterministic tags with a recorded complete union, without omitting any acceptance row. Final test.fast may exceed 60 seconds; yield/poll and communicate during it.
- Denial checks require positive marker controls and per-boundary fresh observations. HTTP 403 does not prove a connected hook; a synthetic connected socket is callback evidence only; a fresh GET rejoin does not alone prove cached-session new connected join.
- No new visual/manual verification is scheduled. A specific unproven behavior remains a gap until suitable automated/source evidence exists. Record and reuse each closed ledger row while its source and acceptance remain valid.

## Planning-Time Gate Evidence

All three plans passed frontmatter.validate and verify.plan-structure (two tasks each, no errors); complete closing output tags were checked after writing. The inherited `git diff --check` is intentionally applied before the last task commit to the uncommitted tree, with an additional explicit source-base diff check covering earlier committed tasks. API coverage detector examined the nonempty Phase 168 roadmap section plus all three plan bodies and returned `detected:false` (normal no-integration exit 1), so no API matrix/declaration is required. Assumption-delta scan returned `detected:false`. No scoped schema pattern is modified and no schema push is required. Graph context is disabled in this project; no graph freshness claim is made. These are planning checks only, not test/runtime acceptance.

## Manual-Only Verifications

None required by the approved Phase 168 acceptance scope. Browser/socket transport, packaged adoption and exact supported-floor runtime proof remain Phase 170; generator/demo/upgrade convergence remains Phase 169. Native host logout/disconnect and event-level policy are explicit responsibilities; no continuous permission-revocation promise is introduced.

## Validation Sign-Off

- [ ] Final tasks mapped to automated checks and unique threat IDs.
- [ ] New paths created before use and no watch-mode commands.
- [ ] HTTP, disconnected/connected mount, cross-session navigation and reconnect are distinguished.
- [ ] Denial matrix has absent, invalid, valid-but-disallowed and currently allowed controls with no protected data/action assertions.
- [ ] Execution results and evidence limits recorded before setting nyquist_compliant true.

**Approval:** Approved requirement/roadmap scope; plan validation and runtime execution evidence are separate. Runtime validation pending; do not set nyquist_compliant or wave_0_complete true before the required checks and closure records exist.
