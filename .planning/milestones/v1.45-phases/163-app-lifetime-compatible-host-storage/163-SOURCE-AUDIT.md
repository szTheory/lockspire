# Phase 163 source and decision audit

This audit connects the roadmap, requirements, research constraints, assumptions,
and all locked decisions to implementation and evidence. Status means an
executed slice has evidence; phase completion remains pending until the current
full-suite gate and independent review are recorded in `163-VALIDATION.md`.

## Roadmap goal and success criteria

| Source | Item | Implementation / proof | Status |
|---|---|---|---|
| ROADMAP goal | New and existing hosts persist and enforce app lifetime through explicit storage support. | `app_lifetime_registration_test.exs`, `client_lifetime_conformance_test.exs`, `app_lifetime_migration_test.exs`, and `app_lifetime_packaged_upgrade_test.exs`. | COVERED |
| ROADMAP SC-1 | New snapshots and applicable current-request consumers, including no-secret apps. | Registration/consumer matrix in `163-COVERAGE.md`; public-client and no-secret cases are in authorization/device tests. | COVERED |
| ROADMAP SC-2 | Legacy compatibility and executable upgrade/rollback boundary. | Promotion tests and actual pinned package receipt in `163-13-SUMMARY.md`; old writer drain precedes v1 write. | COVERED |
| ROADMAP SC-3 | Fresh, generated/custom-prefix and custom adapter storage, with explicit unsupported outcome. | Installer migration tests, public and `tenant_auth` package journey, and positive/negative adapter conformance. | COVERED |
| ROADMAP SC-4 | Boundary, disabled and token semantics without pruning dependency. | Equality, disabled, signed/opaque, and durable rollback cases in the consumer matrix and storage tests. | COVERED |

## Requirement source coverage

| Requirement | Source requirement | Executed proof | Status |
|---|---|---|---|
| DCR-05 | New app stores selected effective lifetime and distinguishes disabled from expired. | `app_lifetime_registration_test.exs`, authorization equality/disabled cases, and final issuance cases in `163-COVERAGE.md`. | COVERED |
| DCR-06 | Applicable protocol paths check app expiry consistently and issued tokens follow the selected cap without worker scheduling. | All C-APP rows and C-TOK rows in `163-COVERAGE.md`, plus independent-wait and rollback suites. | COVERED |
| DCR-13 | Existing hosts upgrade without guessing rejection deadlines from ambiguous old dates. | v0 promotion and migration tests; actual 1.6.1-to-candidate package receipt across both prefixes. | COVERED |
| DCR-14 | Fresh and custom-storage hosts can satisfy a documented contract; unsupported storage fails explicitly. | Adapter conformance and dependency adaptation tests; packaged migration proof and host guidance. | COVERED |

## Research constraints and assumptions

| Source | Constraint / assumption | Evidence | Status |
|---|---|---|---|
| R-01 | Versioned client aggregate, explicit constructors, no date-based legacy backfill. | `app_lifetime_registration_test.exs`; `client_lifetime_promotion_test.exs`; migration tests. | COVERED |
| R-02 | Adapter-owned declaration and typed support; no permissive capability fallback. | `client_lifetime_conformance_test.exs`, including missing/unknown/dropped-state adapter cases. | COVERED |
| R-03 | One shared transaction authority, current-row delta updates, explicit rollback. | `client_lifetime_rollback_test.exs`; adapter conformance authority/split-backend cases. | COVERED |
| R-04 | Stable client/grant/token lock order; final time after all waits. | `client_lifetime_client_wait_test.exs`, `client_lifetime_grant_wait_test.exs`. | COVERED |
| R-05 | One capped expiry truth for access/refresh; signer is pure construction. | Code, refresh, poll and RFC 8693 capped-output tests in `163-COVERAGE.md`. | COVERED |
| R-06 | No network, host, delivery or response work while durable row locks are held. | JARM-after-lock test in `app_lifetime_authorization_test.exs`; CIBA push-after-transaction test in `app_lifetime_ciba_push_test.exs`; guarded consumer tests. | COVERED |
| R-07 | Prefix-aware additive migration and operational lock procedure. | `app_lifetime_migration_test.exs`, installer migration tests, and `docs/upgrading/client-lifetimes.md`. | COVERED |
| R-08 | Real pinned old/candidate packages in isolated processes. | `app_lifetime_packaged_upgrade_test.exs`; receipt names old/candidate process results. | COVERED |
| R-09 | Independent PostgreSQL waits and durable rollback evidence. | Client/grant wait tests identify PIDs/blockers; rollback test asserts durable rows and audits. | COVERED |
| R-10 | No dependencies; retain repository facade and typed token dependency architecture. | `mix.exs`/`mix.lock` unchanged by this plan; architecture fitness and dependency adaptation tests. | COVERED |
| R-11 | Preserve redaction, endpoint trust, and distinction between store failure and credential rejection. | Authorization safe-redirect cases, adapter invalid-state cases, client-auth/consumer HTTP mapping tests; all prior summaries retain existing security tests. | COVERED |
| A1 | Adapter shape must preserve a narrow explicit host seam. | Chosen contract is `lifetime_contract/0`, `lock_clients/1`, and shared transaction authority; proved by conformance and dependency tests. | COVERED; assumption resolved |
| A2 | Existing package harness can run two pinned binaries against isolated databases. | Completed package journey with separate roots/processes and public/tenant_auth receipt. | COVERED; assumption resolved |
| A3 | App caps can be delivered without closing later credential scope. | C-TOK app cap tests cover access/refresh. Shared-secret and management-token lifecycle ownership remains 164/165; final cross-phase reconciliation remains 166. | COVERED; scope preserved |

## Locked decision audit

| Decision | Evidence produced by the selected implementation | Status |
|---|---|---|
| D-01 | Shared eligibility plus endpoint-owned mapping; state-preserving fetch and local safe error cases in authorization, UserInfo, revocation, introspection, and management suites. | COVERED |
| D-02 | Public/private and no-secret paths, disabled/equality behavior, and client-auth entry cases across `app_lifetime_authorization_test.exs`, device, code, and credential-auth suites. | COVERED |
| D-03 | Authorization ingress/resume/approval, PAR create/use, device verification, CIBA approval and queued push tests. | COVERED |
| D-04 | UserInfo current adapter before host claims; RFC 8693 requester/subject/actor checks; introspection owned target; offline `VerifyToken` has no client lookup. | COVERED |
| D-05 | `app_lifetime_management_test.exs`: expired enabled GET/DELETE allowed, PUT rejected; disabled and stale credentials denied; intake closure independent. | COVERED |
| D-06 | Stable locks, current-row identity and fresh post-wait time in client/grant wait tests, including opposing RFC 8693 identity order. | COVERED |
| D-07 | Code remains unconsumed and token/audit/grant/client writes roll back after final app rejection or injected storage failure. | COVERED |
| D-08 | Existing outer transaction abstraction retained; rollback explicitly propagated; atomicity tests assert durable state. | COVERED |
| D-09 | Explicit clocks threaded through client-auth/CIBA and sampled after locks; deterministic equality/wait tests. | COVERED |
| D-10 | Ordinary grant, refresh, poll/push and RFC 8693 signed/opaque outputs share the final app cap. | COVERED |
| D-11 | JARM remote resolution and CIBA delivery execute after row locks/issuance transaction; tests assert order. | COVERED |
| D-12 | New records explicitly version 1; migrated records version 0; missing/unknown invalid; historical secret dates preserved. | COVERED |
| D-13 | v0 reads stay unlimited regardless of legacy secret date; credential replacement promotion canonicalizes state atomically; metadata/enablement do not promote. | COVERED |
| D-14 | Adapter-owned typed contract is validated once during dependency adaptation, not inferred from permissive capability defaults. | COVERED |
| D-15 | Declared transaction authority identifies participating store roles and must match client and transaction stores. | COVERED |
| D-16 | Reusable positive/negative conformance verifies finite/unlimited/v0, current rows, rollback, missing support, dropped fields, missing guard and split authority. | COVERED |
| D-17 | One new packaged prefix-aware expansion; installer protects prior migration bytes/checksums and host files. | COVERED |
| D-18 | PostgreSQL DDL lock timeout observed and retry succeeds after release; guidance avoids universal duration and zero-downtime claim. | COVERED |
| D-19 | Actual stage/drain/cutover journey proves all old processes exit before v1; unsafe post-v1 old binary is explicitly excluded and state retained. | COVERED |
| D-20 | Pinned 1.6.1 old package and current package run separately on both prefixes; nil/creation/past/future/stale dates observed. | COVERED |
| D-21 | Real independent PIDs and `pg_blocking_pids` confirm client and later grant waits before advancing deterministic time. | COVERED |
| D-22 | Before/equality/after, policy/credential provenance, disabled/expired, public/no-secret, queued work, stale auth, client and grant waits, signed/opaque tokens, all issuance routes, and rollback are represented in focused cases. | COVERED |
| D-23 | No project dependency, account/recovery system, broad admin redesign, or service is added; repository facade and dependency seams remain. | COVERED |
| D-24 | Host guidance is tied to migration/package/runtime evidence, names offline JWT limits, avoids internal version UI, and leaves credential/operator reconciliation for 166. | COVERED |

## Scope boundaries

Phase 163 app-lifetime coverage does not complete DCR-07–12 or DCR-15–19.
Shared-secret enforcement remains Phase 164; app management-token expiry and
recovery remain Phase 165; cross-phase operator and release reconciliation
remains Phase 166. The umbrella lifetime todo stays pending until those owners
finish their work. No external provider API is part of this feature, so external
API integration coverage is not applicable; internal OAuth app consumers are
covered by C-APP-01–18.
