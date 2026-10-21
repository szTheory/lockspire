# Phase 163 implementation and proof coverage

The rows below connect the Phase 162 normative inventory to Phase 163's
implementation and executable evidence. “Slice pass” refers to the commands
recorded in the named 163-01 through 163-13 summary. The final `mix test.fast`
gate passed on a fresh isolated PostgreSQL database; independent review and
phase sign-off remain pending as recorded in `163-VALIDATION.md`.

## Requirements and phase success criteria

| Requirement / criterion | Implementation and observed proof | Status |
|---|---|---|
| DCR-05 | Explicit lifetime snapshot and eligibility: `test/integration/app_lifetime_registration_test.exs` (`registration persists its app lifetime and current eligibility rejects the deadline`); consumer equality/disabled cases in `app_lifetime_authorization_test.exs`, `app_lifetime_code_redemption_test.exs`, and `app_lifetime_refresh_test.exs`. | Slice evidence and fresh full-suite gate passed; independent review pending |
| DCR-06 | Current app checks and durable token caps across the complete online inventory below; code, refresh, poll, push and RFC 8693 use focused integration files named per case. Storage rollback and independent waits are covered by `client_lifetime_rollback_test.exs`, `client_lifetime_client_wait_test.exs`, and `client_lifetime_grant_wait_test.exs`. | Slice evidence and fresh full-suite gate passed; independent review pending |
| DCR-13 | Legacy v0/promotion behavior: `test/lockspire/storage/client_lifetime_promotion_test.exs`; prefix-aware DDL and lock timeout: `test/integration/app_lifetime_migration_test.exs`; pinned package journey and old-writer boundary: `test/integration/app_lifetime_packaged_upgrade_test.exs`. | Slice evidence, receipt, and fresh full-suite gate passed; independent review pending |
| DCR-14 | Adapter contract and rollback: `test/lockspire/storage/client_lifetime_conformance_test.exs`; custom prefix package path: `app_lifetime_packaged_upgrade_test.exs`; installer collision/checksum/no-overwrite: `test/lockspire/install/migrations_test.exs`. Unsupported declaration, missing guard, dropped state, authority mismatch, or split rollback fails closed. | Slice evidence and fresh full-suite gate passed; independent review pending |
| SC-1: new snapshots and applicable consumers | Registration plus C-APP-01–16 and C-TOK-01–03 below. | Slice evidence and fresh full-suite gate passed; independent review pending |
| SC-2: legacy treatment and deploy/rollback boundary | Promotion and actual packaged public/tenant_auth journeys; old writers stop before the first v1 write, migration checksums are retained, and v1 data is retained. See 163-13-SUMMARY.md receipt evidence. | Slice evidence, receipt, and fresh full-suite gate passed; independent review pending |
| SC-3: built-in, generated/custom-prefix and custom adapter outcomes | Prefix-aware migration/installer tests and adapter conformance; unsupported contracts return configuration/storage failure rather than unlimited eligibility. | Slice evidence and fresh full-suite gate passed; independent review pending |
| SC-4: boundary, disabled state and token behavior | Equality and disabled cases across authorization, code, refresh, poll, device, CIBA, introspection, revocation and management; signed and opaque outputs are checked. | Slice evidence and fresh full-suite gate passed; independent review pending |

## Normative app consumer inventory

Each Phase 162 C-APP row has a Phase 163 implementation/proof location. Test
names below are exact ExUnit descriptions; paths are repository-relative.

| Case | Consumer / outcome | Exact proof | Durable or externally visible observation |
|---|---|---|---|
| C-APP-01 | Authorization intake; reject before host login/consent and only redirect after URI trust. | `test/integration/app_lifetime_authorization_test.exs` — `expired public app redirects only to its registered URI and never hands off to the host`; `an expired app with an unregistered redirect receives a local error`; `expired private-key client is rejected at browser intake too`. | No host handoff; registered redirect receives the safe error; unregistered URI receives local response. |
| C-APP-02 | Resume, remembered consent and approval recheck current app. | Same file — `resume and remembered-consent code paths recheck app state after ingress`; `approval at app deadline equality rolls back interaction, remembered consent, and code`. | Interaction/consent/code state stays unchanged at equality; no code is issued. |
| C-APP-03 | PAR rejects at create and rechecks accepted request_uri at use. | Same file — `PAR creation rejects an app at deadline equality and leaves no request`; `an accepted PAR is rejected at current app deadline equality on request_uri use`. | No PAR row on rejected create; previously accepted PAR cannot authorize after deadline. |
| C-APP-04 | Device creation, lookup and approval enforce current state. | `test/integration/app_lifetime_device_test.exs` — `device creation that passes authentication but reaches the client lock at app expiry writes no request`; `verification approval rechecks a disabled app after client and request locks`; `verification lookup rejects a pending request when the app deadline is reached`; `device approval at app deadline preserves pending state and writes no approval audit`. | No request/approval write on rejection; queued request remains pending and has no approval audit. |
| C-APP-05 | CIBA initiation, queued approval and push reload app state. | `test/integration/app_lifetime_ciba_approval_test.exs` — `CIBA initiation rechecks app expiry after host resolution before writing a request`; `queued CIBA request cannot approve at app expiry and does not write approval audit`; `queued CIBA request cannot approve after the client is disabled`; plus `test/integration/app_lifetime_ciba_push_test.exs` — `queued push reloads current app state and refuses app equality before delivery`. | No initiation/approval audit at rejection; push is not delivered when the current app is ineligible. |
| C-APP-06 | Authorization-code redemption rechecks and preserves unconsumed grant. | `test/integration/app_lifetime_code_redemption_test.exs` — `redemption at the current app deadline leaves the grant untouched`; `authorization-code tokens share the final app-capped lifetime`; `opaque code grants persist the same app-capped access expiry`. | Rejection leaves the code unconsumed; allowed signed/opaque issuance persists the same capped expiry. |
| C-APP-07 | Refresh and device/CIBA polls reject replacement issuance without breaking replay semantics. | `test/integration/app_lifetime_refresh_test.exs` — `app deadline equality rejects without consuming or changing the family or audit`; `valid replay still revokes every token in the refresh family`; `test/integration/app_lifetime_poll_issuance_test.exs` — both `approved device request is not consumed when app expires at final issuance` and CIBA equivalent. | Rejected artifact remains pending/current family and audit are unchanged; eligible replay still revokes the family. |
| C-APP-08 | RFC 8693 requesting client is checked and caps output. | `test/integration/app_lifetime_rfc8693_test.exs` — `requester deadline caps opaque durable output and response at final time`; `signed exchange uses the same final app deadline in JWT, row and response`. | Response, durable row and JWT share the final cap for the selected output representation. |
| C-APP-09 | RFC 8693 subject and actor issuing clients are checked independently. | Same file — `expired subject and actor issuers reject before host validation or writes`; `subject and actor durable identities reach host validation and actor expiry gates independently`; `final equality rejects without writing an output token or audit`. | Expired issuer prevents host work/output writes; subject and actor identity are preserved and independently gated. |
| C-APP-10 | Introspection caller authentication uses current app state. | `test/integration/app_lifetime_online_consumers_test.exs` — `introspection returns only active false when an owned token issuer is currently expired`; companion disabled and invalid-adapter cases in `test/integration/app_lifetime_authorization_test.exs` and client auth focused tests from 163-03. | Current caller and issuer rows are read through declared store; expired owned target is inactive, not disclosed as active. |
| C-APP-11 | An owned token whose issuing app expired returns only inactive. | Same online-consumer test as C-APP-10. | Result is exactly `%{active: false}`; no token claims are returned. |
| C-APP-12 | UserInfo rejects an expired issuer before host claims. | Same file — `UserInfo checks the custom current app before host callbacks`; `the HTTP UserInfo challenge maps an expired issuing app to invalid_token`. | Custom store is queried; host callback count stays zero; HTTP is 401 Bearer `invalid_token`. |
| C-APP-13 | Revocation authenticates current caller while retaining non-disclosing success for eligible unknown tokens. | Same file — `revocation rejects an expired caller and preserves success for an eligible unknown token`. | Expired confidential/public caller gets 401 `invalid_client`; eligible caller gets `:ok` for unknown token. |
| C-APP-14 | Expired enabled app can read/delete own registration. | `test/integration/app_lifetime_management_test.exs` — `expired enabled app allows GET and DELETE but rejects PUT without changing state`. | GET remains available, DELETE succeeds, and rejected PUT leaves client state intact. |
| C-APP-15 | Expired enabled app cannot update/self-rotate. | Same test as C-APP-14. | PUT returns 403 `registration_expired`; credentials and app state are unchanged. |
| C-APP-16 | Disabled app is denied protocol and all self-management operations. | `app_lifetime_management_test.exs` — `closed intake does not block management, while disabled and stale credentials do`; `app_lifetime_authorization_test.exs` — `disabled apps are rejected before host work and invalid adapter state fails locally`. | Disabled/stale credentials are denied; closed registration intake alone does not block allowed management. |
| C-APP-17 | Discovery and JWKS remain provider-level public surfaces. | `app_lifetime_online_consumers_test.exs` — `provider discovery remains independent of client app lifetime`. | Discovery and JWKS endpoints both return HTTP 200 and the published key is present. |
| C-APP-18 | Host/RP session and account policy remain host-owned; no logout side effect is promised. | No new app-lifetime behavior is attached to host resolver/session/logout routes. Ownership boundary is documented in `docs/architecture.md`; the unrelated logout baseline is `test/integration/phase39_logout_propagation_e2e_test.exs`. | This is an unaffected-boundary disposition, not a claim that expiry immediately clears host sessions or propagates logout. |

## Token and storage proof

| Case | Exact proof | Observed contract |
|---|---|---|
| C-TOK-01 | `test/integration/app_lifetime_code_redemption_test.exs` (`authorization-code tokens share the final app-capped lifetime`), `app_lifetime_refresh_test.exs` (`refresh access and replacement refresh expiries share the app cap`), and `app_lifetime_rfc8693_test.exs` signed/opaque cap tests. | Stored access expiry, JWT `exp`, and response `expires_in` derive from the single final decision time and app deadline; refresh replacement is capped too. |
| C-TOK-02 | `app_lifetime_code_redemption_test.exs` (`redemption at the current app deadline leaves the grant untouched`) and `app_lifetime_refresh_test.exs` equality case. | Equality rejects before grant/family consumption, token insertion, or audit append. |
| C-TOK-03 | `test/integration/app_lifetime_poll_issuance_test.exs` and `app_lifetime_ciba_push_test.exs` (signed/opaque, poll/push cases). | Delayed issuance uses the current app cap; rejected work remains durable and push delivery occurs after issuance commit. |

## Adapter, PostgreSQL and packaged evidence

- `test/lockspire/storage/client_lifetime_conformance_test.exs` verifies finite,
  unlimited and explicit v0 round trips, expired/disabled fetch preservation,
  stable current-row guard order, custom adapter conformance, explicit shared
  transaction authority, and rollback when audit or token/grant writes fail.
- `test/lockspire/storage/client_lifetime_client_wait_test.exs` confirms the
  holder/contender PostgreSQL PID relationship with `pg_blocking_pids` before
  resampling app equality, disabled state, or stale preverified credentials.
  `client_lifetime_grant_wait_test.exs` covers the later grant-row wait and
  delivery after locks are released. `client_lifetime_rollback_test.exs`
  asserts durable state after failed audits and writes.
- `test/integration/app_lifetime_migration_test.exs` observes installed
  PostgreSQL DDL (constant v0 default, nullable authoritative dates) and a real
  bounded lock-timeout/retry after release. `test/lockspire/install/migrations_test.exs`
  asserts checksum preservation and refusal to overwrite or collide.
- `test/integration/app_lifetime_packaged_upgrade_test.exs` runs the pinned
  Hex 1.6.1 old package and candidate in isolated roots/processes on real
  PostgreSQL for `public` and `tenant_auth`. Plan 163-13's receipt records five
  old-written rows per prefix; nil, creation-time, past, future, and stale-after-
  rotation historical dates; successful old reads/rotation before cutover;
  all old processes stopped before v1 write; preserved prior migration
  checksums; retained v1 state; and clean database teardown. Receipt:
  `/private/tmp/lockspire-163-13-all-receipt.json`, SHA-256
  `5edde26983007bf875e6ea7e10fe273c5a0e5d764359ae1e5069fdc009fa9ebf`.
- No external provider/service API is introduced or consumed by this feature.
  External API integration coverage is therefore not applicable: there is no
  external API surface to exercise. The internal OAuth consumers are enumerated
  exhaustively in C-APP-01–18 above.
