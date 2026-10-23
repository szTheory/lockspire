---
phase: "169"
slug: install-and-upgrade-convergence
status: verified
threats_open: 0
threats_total: 22
threats_closed: 22
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-23"
source_revision: 13e673ceeeab17befd669581d359e63d4f0e5b59
---

# Phase 169 — Security

Independent `gsd-security-auditor` review inspected the implementation and behavioral tests for the existing plan-time register. All 21 numeric threats and the shared `T-169-SC` condition are closed: 19 high and 3 medium threats, all dispositioned mitigate. No risk acceptance or transfer was inferred.

## Trust Boundaries

| Boundary | Description | Data crossing |
|----------|-------------|---------------|
| Host policy → HTTP and LiveView admin entry | Generated policy denies until host implementation; current authority remains host-owned | Host session identity reference and policy decision |
| Manifest and host files → operation plan/transaction | Checksums authorize managed updates; new policy is create-only and unmanaged | File bytes, checksums, paths and recovery journal |
| Host compiled metadata → verifier output | Exact structure and effective dispatch are checked; policy semantics are not certified | Route/action/session/hook declarations |
| Runtime configuration → diagnostics/evidence | Fixed structural guidance excludes secret values and arbitrary exception terms | Redacted results and safe remediation |
| Host sources → adoption evidence | Demo/clean-room reuse the canonical route inventory; evidence types remain explicit | Source, compiled routes and server lifecycle results |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and inspected evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------------------|--------|
| T-169-01 | Elevation of privilege | Generated policy | high | mitigate | `priv/templates/lockspire.install/operator_authorization.ex:18,25` denies HTTP/hook entry; `test/integration/install_admin_integration_test.exs:19,74` covers untouched denial and explicitly implemented connected allowance. | closed |
| T-169-02 | Spoofing | Generated identity seam | high | mitigate | Untouched seam always denies; test-owned policy resolves identity independently at HTTP/hook boundaries (`install_admin_integration_test.exs:243,253`); empty sessions and forged assigns tested at line 44. No account schema or allow-boolean generated. | closed |
| T-169-03 | Tampering | Install ownership/destinations | high | mitigate | `generators/templates.ex:19` declares host ownership; `install/operation_plan.ex:188,386` excludes policy from managed authority and revalidates destinations. Generator tests at lines 80,521,697 prove ownership, stale installs and collision refusal. | closed |
| T-169-04 | Elevation of privilege | Generated route ordering | high | mitigate | Router template lines 55,59 and `web/admin_routes.ex:88,103` order host Plug/hooks before guards and public forward. Inventory/compile/separation tests verify exact route/action order and required wiring. | closed |
| T-169-05 | Tampering | Historical ownership | high | mitigate | `install/operation_plan.ex:228,250,286` validates manifest entries, checksums and duplicates. Upgrade tests lines 132,343,482 cover conversion, repeats, drift and malformed entries. Pinned fixture matches source `69c05922` with SHA-256 `7b1b73ec53d27641166306bce963fcb9e2d7d73ab2059598b9829b92971221c1`. | closed |
| T-169-06 | Elevation of privilege | New upgrade policy seam | high | mitigate | `install/operation_plan.ex:297,324,188` creates only absent policy and excludes it from managed files; upgrade tests lines 217,360 prove exclusion and customized-policy preservation. | closed |
| T-169-07 | Tampering | Preview/recovery boundary | high | mitigate | `install/operation_plan.ex:47` selects read-only recovery inspection; `install/file_transaction.ex:88` does not recover/write. Upgrade test line 243 and transaction tests lines 101,136 verify snapshots and unsafe-path refusal. | closed |
| T-169-08 | Denial of service | Interrupted apply | high | mitigate | Operation plan line 162 and transaction lines 202,304,343,373 preserve manifest-last journal/rollback ordering. Transaction tests lines 77,101,153 cover rollback/retry and interruption after policy/helper writes. | closed |
| T-169-09 | Tampering | Stale operations | high | mitigate | Operation plan lines 377,406 revalidate checksums; transaction lines 373,388,397 recheck preimages and create exclusively. Upgrade test line 290 exercises appearing destinations, edited files and competing plans without clobbering. | closed |
| T-169-10 | Elevation of privilege | Effective routing diagnostics | high | mitigate | `install/verify.ex:228,366,399,433,477` uses canonical exact inventory, session and first-match dispatch. Verifier tests lines 604,614,646 cover mounts, mutations and shadowing. | closed |
| T-169-11 | Spoofing | Incomplete host wiring | high | mitigate | Verifier lines 447,505 require host hooks/pipelines before the expected guard/router; AdminRoutes line 129 rejects missing compile-time options. Verifier test lines 614,1025 and task test line 470 cover malformed, misordered and legacy cases. | closed |
| T-169-12 | Information disclosure | Diagnostic output | high | mitigate | Verifier lines 192,275,477 use fixed errors and canonical expected labels, excluding arbitrary metadata/exception contents. Task tests lines 92,103,244,367,387,409 inject and exclude nonvacuous secret/metadata/exception sentinels. | closed |
| T-169-13 | Elevation of privilege | Diagnostic claim boundary | high | mitigate | Verifier lines 24,207,258,275,285 include the policy-proof limit on success/error/unavailable paths; task help line 50 identifies host behavioral tests. Task tests lines 341,361,387,451 assert public output. | closed |
| T-169-14 | Denial of service | Malformed metadata | medium | mitigate | Verifier lines 44,192,275,421,444,471 preserve aggregate checks and bounded shape fallbacks. Verifier tests lines 660,685,959 cover malformed/exception and independent aggregate findings. | closed |
| T-169-15 | Elevation of privilege | Demo route migration | high | mitigate | Demo router line 60 uses one canonical declaration; HTTP Plug line 12 and hook line 9 preserve host authorization. Demo integration test line 52 covers anonymous/nonstaff/ops HTTP, connected Overview and native navigation. | closed |
| T-169-16 | Spoofing | Demo identity hook | high | mitigate | Demo OperatorAuthorization lines 10,28,35 resolve `demo_login` via Accounts on mount/params; CurrentAccount line 8 resolves HTTP identity independently. Demo test lines 125,131 cover navigation, forged assigns and invalid/nonstaff references. | closed |
| T-169-17 | Tampering | Duplicate demo routing | high | mitigate | Demo router lines 60,75 retain one macro and separate public forward. Demo integration tests lines 44,52 refute copied admin declarations/fallback and inspect exact compiled inventory plus actual connection. | closed |
| T-169-18 | Elevation of privilege | Clean-room policy | high | mitigate | Clean-room OperatorAuthorization lines 13,19 denies Plug/hook entry; router patch lines 4,35 invokes generated helper. Clean-room integration tests lines 11,74 compile actual output/overlay at default/nested mounts and exercise denying callbacks. | closed |
| T-169-19 | Information disclosure | Emitted session configuration | medium | mitigate | `scripts/acceptance/clean_room/build_provider.py:68,105,134` emits synthetic local config, environment key lookup and shared socket/cookie options. Source-contract test line 117 and integration test line 93 use temporary emitted source and isolated cleanup; no live key expansion. | closed |
| T-169-20 | Elevation of privilege | Adoption guidance | high | mitigate | Install guide lines 98,106 and host-admin upgrade guide lines 100,120 describe guarded routes, current host checks and event/disconnect ownership; rendered-host and upgrade-preservation behavioral tests back the walkthrough. | closed |
| T-169-21 | Repudiation | Evidence claims | medium | mitigate | `169-UAT.md` has criterion/method/result/revision/files/limits per acceptance and prohibition, disclaims user-reported passes, retains the unclassified assumption and Phase 170 owners; final logs corroborate counts/seeds. | closed |
| T-169-SC | Tampering | Package installation | high | mitigate | Dependency/lockfile diff since phase baseline shows only root `mix.exs` ExDoc extras/group changes. No dependency or package installation was introduced; the conditional legitimacy gate was not triggered. | closed |

Paths shortened within rows resolve under `lib/lockspire/`, `test/lockspire/install/`, `test/mix/tasks/`, or the explicitly named demo/clean-room source as appropriate. Full paths and individual methods are also recorded in the plan summaries and UAT ledger.

## Accepted Risks Log

No accepted risks. No transferred threats. No implementation gap was silently converted into acceptance. No unregistered summary threat flags were present.

`A-169-HDX-04` remains an explicitly unresolved, unclassified probe assumption with no additional predicate; it is neither risk acceptance nor an invented threat closure.

## Evidence and Limits

The auditor read implementation and behavioral tests directly and confirmed no implementation/test-source changes after `13e673ce`. Existing execution logs were inspected, not rerun during this audit:

- Phase union: `/tmp/lockspire169-plan05-union-final.log`, 144 passed, 52.1 seconds, seed 61505.
- Broad selector: `/tmp/lockspire169-plan05-fast-final-clean.log`, 2,006 passed, 6 skipped, 497 excluded, 192.8 seconds, seed 78614, disposable database `lockspire_phase169_fast_final` and isolated Hex cache.

Untouched generated denial establishes HTTP denial plus direct disconnected/connected-socket hook callbacks. Clean-room denial establishes compiled routing and direct Plug/hook callbacks. Explicit generated-host allowance and the demo exercise connected LiveViewTest lifecycle. None establishes candidate-package consumption, browser/socket transport, exact-floor execution or remote CI; Phase 170 owns those. Transaction evidence does not extend to unsupported simultaneous writers or hostile same-user ancestor replacement.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-23 | 22 | 22 | 0 | Independent gsd-security-auditor; parent persisted verdict |

## Sign-Off

- [x] All planned threats have a disposition and inspected mitigation evidence.
- [x] Accepted risks documented: none.
- [x] `threats_open: 0` confirmed; no below-threshold open findings.
- [x] `status: verified` set after independent audit.

**Approval:** verified 2026-10-23; no user-reported pass inferred.
