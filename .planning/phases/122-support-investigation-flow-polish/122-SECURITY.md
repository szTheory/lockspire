---
phase: 122
slug: support-investigation-flow-polish
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: 2026-06-28
verified: 2026-06-28
register_authored_at_plan_time: true
---

# Phase 122 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Security enforcement was checked. The installed `gsd-tools` build does not expose the workflow's `loop render-hooks verify:post --raw` command, but the local capability registry defines `secure-phase` as a `verify:post` step gated by `workflow.security_enforcement`, and the project has no false override. Capability defaults set security enforcement on with ASVS level 1 and `block_on: high`.

Phase 122 has plan-time `<threat_model>` blocks in all three plans. No existing phase-local security file was present, so this audit created the phase security artifact from the plan and summary artifacts. The shared supply-chain item `T-122-SC` appeared in each plan and is deduplicated below.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator browser -> LiveView URL params | Account, client, status, and scope filters enter token and consent index LiveViews through query parameters and form controls. | Support filters and raw form values |
| LiveView -> Admin API | Index/detail LiveViews read and mutate data through existing `Lockspire.Admin` delegations. | Token and consent read models; revoke commands |
| Admin data -> rendered HTML | Token, consent, account, client, family, scope, timestamp, status, and lineage data becomes operator-visible HTML. | Redacted handles, statuses, scopes, timestamps, and consequence copy |
| Operator browser -> LiveView event | Confirmation checkbox input crosses into token, family, and consent revoke event handlers. | Destructive-action confirmation state |
| Revocation result -> operator copy | Backend success, failure, and closed states are summarized for support operators. | Non-final failure copy and closed-state notices |
| Source/test repo -> package surface | Support UI source changes must not create public component, route, schema, package, or browser-tooling commitments. | Admin UI source, tests, docs, and package metadata |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-122-01 | Information Disclosure | Token/consent index rendered HTML | mitigate | Indexes render decision summaries and dense rows with redacted client/account/family handles via `long_value`; route tests deny token hashes, secrets, verifier, auth-code, user-code, and plaintext token terms. Evidence: `tokens_live/index.ex:54-83`, `tokens_live/index.ex:137-176`, `consents_live/index.ex:54-83`, `consents_live/index.ex:129-169`, `tokens_live_test.exs:83`, `tokens_live_test.exs:137-139`, `consents_live_test.exs:125`, `consents_live_test.exs:166`. | closed |
| T-122-02 | Elevation of Privilege | Index actions | mitigate | Index pages expose only filter submit and detail review navigation actions backed by existing routes; no revoke, bulk, reveal, export, debug, protocol, storage, or host-policy controls were introduced. Evidence: `tokens_live/index.ex:89-117`, `tokens_live/index.ex:171-175`, `consents_live/index.ex:89-113`, `consents_live/index.ex:164-168`. | closed |
| T-122-03 | Denial of Service | Dense rows at narrow widths | mitigate | Token and consent indexes use existing `dense_resource_row` and `long_value` primitives; source contract requires dense rows and refutes `resource_item` for both support indexes. Evidence: `tokens_live/index.ex:137-176`, `consents_live/index.ex:129-169`, `design_system_contract_test.exs:984-996`. | closed |
| T-122-04 | Tampering | LiveView data access | mitigate | Index reads stay behind `Admin.list_tokens/1` and `Admin.list_consents/1`; current source scan found no raw `Repo`, `Repository`, schema, migration, bulk, reveal, export, or debug additions in the four phase LiveViews. Evidence: `tokens_live/index.ex:185-195`, `consents_live/index.ex:178-188`. | closed |
| T-122-05 | Tampering | Token revoke/family revoke forms | mitigate | Token and family revoke handlers require explicit checkbox confirmation, keep existing Admin API mutation calls, and disable closed/no-family actions through explicit predicates. Evidence: `tokens_live/show.ex:42-88`, `tokens_live/show.ex:264-345`, `tokens_live/show.ex:375-403`, `tokens_live_test.exs:228-244`, `tokens_live_test.exs:332-382`. | closed |
| T-122-06 | Repudiation | Token revocation failure copy | mitigate | Failure branches use locked non-final copy stating revocation could not be confirmed and the token may still be active; tests assert the copy renders through error primitives. Evidence: `tokens_live/show.ex:10-12`, `tokens_live/show.ex:53-55`, `tokens_live/show.ex:86-88`, `tokens_live_test.exs:256-263`. | closed |
| T-122-07 | Information Disclosure | Token detail rendered HTML | mitigate | Token detail renders durable metadata with redacted/opaque handles through `long_value` and tests deny hashes, raw sensitive account/family values, and plaintext token material. Evidence: `tokens_live/show.ex:172-220`, `tokens_live/show.ex:238-255`, `tokens_live_test.exs:173-177`, `tokens_live_test.exs:209-213`. | closed |
| T-122-08 | Elevation of Privilege | Token detail action surface | mitigate | Token detail exposes only single-token and family revocation actions backed by `Admin.revoke_token/2` and `Admin.revoke_token_family/2`; copy explicitly avoids host logout, account suspension, consent revocation, worker control, and plaintext recovery claims. Evidence: `tokens_live/show.ex:42-88`, `tokens_live/show.ex:258-345`, `tokens_live/show.ex:467-521`. | closed |
| T-122-09 | Denial of Service | Token detail long lineage | mitigate | Token lineage and durable metadata use existing `dense_resource_row`, `long_value`, and `timestamp` primitives for long handles and timestamps. Evidence: `tokens_live/show.ex:172-220`, `tokens_live/show.ex:238-255`. | closed |
| T-122-10 | Tampering | Consent revoke form | mitigate | Consent revoke handler requires explicit checkbox confirmation, keeps the existing `Admin.revoke_consent/2` call, and disables already-revoked actions. Evidence: `consents_live/show.ex:38-55`, `consents_live/show.ex:181-215`, `consents_live/show.ex:248-255`, `consents_live_test.exs:211-218`, `consents_live_test.exs:247-250`. | closed |
| T-122-11 | Repudiation | Consent revocation failure copy | mitigate | Failure branch uses locked non-final copy stating revocation could not be confirmed and the consent grant may still be active; tests assert the copy renders through error primitives. Evidence: `consents_live/show.ex:11-13`, `consents_live/show.ex:46-48`, `consents_live_test.exs:230-237`. | closed |
| T-122-12 | Information Disclosure | Consent detail rendered HTML | mitigate | Consent detail renders redacted consent, account, and client pivots and long scope values; tests deny consent hash, secret, token, verifier, user-code, and raw sensitive account leakage. Evidence: `consents_live/show.ex:100-130`, `consents_live/show.ex:132-175`, `consents_live_test.exs:159-169`, `consents_live_test.exs:186-192`. | closed |
| T-122-13 | Elevation of Privilege | Consent detail action surface | mitigate | Consent detail exposes only the existing revoke-consent action and disabled already-revoked state; copy limits the consequence to future remembered-consent reuse and does not imply host account, session, token, worker, reveal/export/debug, bulk, or protocol controls. Evidence: `consents_live/show.ex:38-48`, `consents_live/show.ex:177-215`, `consents_live/show.ex:295-304`. | closed |
| T-122-14 | Denial of Service | Consent detail long scopes | mitigate | Consent detail wraps scope context through existing `long_value`; component stress/source tests cover long-value and error-summary primitives. Evidence: `consents_live/show.ex:114`, `consents_live/show.ex:174`, `design_system_component_stress_test.exs:149-150`. | closed |
| T-122-SC | Tampering | npm/pip/cargo/mix installs | accept | Accepted risk documented below. Phase summaries record `tech-stack.added: []`; `mix.exs`, `mix.lock`, package metadata, browser tooling, schema, and migration files were outside planned phase files. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-122-SC | T-122-SC | Package-install supply-chain review is accepted as not applicable because Phase 122 added no npm, pip, cargo, Hex, browser-tooling, or Mix dependency. The three summaries list no added tech stack, and package metadata/lockfiles were outside the executed phase scope. | Plan-time threat register; verified by security audit | 2026-06-28 |

## Threat Flags

No unregistered threat flags were recorded. `122-01-SUMMARY.md`, `122-02-SUMMARY.md`, and `122-03-SUMMARY.md` each declare `## Threat Flags` as none, with no new endpoints, auth paths, file access, schemas, migrations, package dependencies, or new trust-boundary surfaces.

## Verification Commands

| Command | Result |
|---------|--------|
| `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | Passed: 64 tests, 0 failures. Existing pre-test KeyCache startup log appeared before ExUnit ran; the command exited 0. |
| Source guard: `rg -n "Admin\\.get_token|Admin\\.revoke_token|Admin\\.revoke_token_family|Admin\\.get_consent|Admin\\.revoke_consent|Admin\\.list_tokens|Admin\\.list_consents|Repo\\.|Repository\\.|Ecto|schema|migration|bulk|reveal|export|debug" ...` | Only the expected Admin delegation calls were found in the four phase LiveViews; no raw repo/storage/package/unsupported action additions were found. |

`MIX_ENV=test mix test.fast --max-failures 5` was not used as the Phase 122 security verdict because `122-03-SUMMARY.md` records unrelated Phase 115 adoption-demo release-readiness failures in pre-existing dirty docs/scripts. The focused Phase 122 gate passed against current files.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-28 | 15 | 15 | 0 | Codex / gsd-secure-phase |

## Security Audit 2026-06-28

| Metric | Count |
|--------|-------|
| Threats found | 15 |
| Closed | 15 |
| Open | 0 |

The plan-time threat register is complete for this phase. All mitigated threats were verified against current source and focused tests; the single accepted supply-chain threat is documented in the Accepted Risks Log. No implementation files were modified by this security audit.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-28
