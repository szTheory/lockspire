# Phase 162 Lifetime Semantics and Upgrade Contract

> **Design contract only. Expected contract behavior; runtime not exercised.** This artifact selects acceptance behavior for Phases 163–166. It does not assert current Lockspire enforcement.

<a id="policy-and-time"></a>
## Policy and time (D-01–D-05; DCR-02)

The three independent settings are DCR app lifetime, shared-secret lifetime, and registration access-token (app-management token) lifetime. For each, `nil`/JSON `null` and integer `0` mean unlimited. A positive integer is a number of seconds from that lifetime's issuance event. Zero is never immediate expiry. Accept only `nil` or an integer in `0..2147483647`; reject booleans, strings, fractional numbers, containers, negative values and larger integers at every supported host configuration, programmatic persistence, registration and replacement-policy boundary. Invalid policy or authoritative lifetime state is a configuration/server error, not a credential rejection or an unlimited fallback. With no shared secret, shared-secret lifetime is inapplicable.

At UTC second 100, registration under app=60, secret=10, management=20 produces deadlines 160, 110 and 120. Store finite deadlines at whole-second UTC precision. Eligibility is strictly `now < deadline`: 109/110/111 tests the secret boundary; the same before/equality/after rule applies to app and management deadlines. No assertion-skew leeway applies. A guarded operation captures one decision time after blocking locks and current-row reload; that time governs both eligibility and replacement deadlines. A request that entered before a deadline but obtains its lock at equality is expired.

Policy is snapshotted at issuance. Changing policy at 105 does not rewrite the three stored deadlines. With replacement secret policy 30 and management policy 40, secret rotation at 107 gives secret deadline 137; management PUT at 108 gives management deadline 148. App remains 160 and each operation preserves the unrelated credential deadline. GET, authentication and enablement do not renew dates. App expiry has no renewal event here; new registration is required. Direct/operator registration retains its existing policy boundary; DCR provenance controls DCR defaults. Public-key and mTLS clients have no shared-secret lifetime gate.

| Lifetime | `nil` / `0` | Positive `N` | Renewal |
|---|---|---|---|
| DCR app | unlimited | registration time + N | none; new registration |
| shared secret | unlimited | secret issuance time + N | explicit secret rotation |
| management token | unlimited | token issuance time + N | successful PUT or authorized host recovery |

<a id="consumer-and-token-contract"></a>
## Consumer and token contract (D-06–D-10; DCR-02/DCR-03)

App expiry is separate from disabled state and deletion. Preserve registration, consent and audit history. Every relevant consumer checks both current enabled state and the finite app deadline, including public clients. Recheck at authorization completion and token-producing persistence boundaries; queued work and previously accepted requests grant no continuing authority. Failed app eligibility at code redemption writes no token and does not consume the code. Workers/pruners are not enforcement.

| Consumer | Expired-app result / boundary | Case |
|---|---|---|
| Authorization intake | reject before login/consent; never redirect to unvalidated URI | C-APP-01 |
| Resume, remembered consent, approval | recheck; no code; redirect only after URI trust | C-APP-02 |
| PAR create and use | reject at creation and again at use | C-APP-03 |
| Device create, verify, approve | reject creation; no approval; render safely | C-APP-04 |
| CIBA initiation, poll, push worker | reject initiation/issuance; worker reloads current state | C-APP-05 |
| Code redemption | reject; no token write or code consumption | C-APP-06 |
| Refresh, device/CIBA poll, existing grants | reject replacement issuance; preserve grant expiry/replay | C-APP-07 |
| RFC 8693 requesting client | reject ineligible caller | C-APP-08 |
| RFC 8693 subject/actor token | reject ineligible issuing app as `invalid_grant` | C-APP-09 |
| Introspection caller | fail client authentication | C-APP-10 |
| Introspection target | owned authorized target yields only `active:false` | C-APP-11 |
| UserInfo | 401 Bearer `invalid_token` before host claims | C-APP-12 |
| Revocation | caller auth required; otherwise non-disclosing success for eligible callers | C-APP-13 |
| Management GET/DELETE | valid current token can read/delete expired enabled app | C-APP-14 |
| Management PUT/self-rotation | expired enabled app gets 403 `registration_expired` | C-APP-15 |
| Explicitly disabled app | deny protocol and all self-management, including GET/DELETE | C-APP-16 |
| Discovery/JWKS | unaffected provider-level public surfaces | C-APP-17 |
| Host/RP session and account policy | unaffected and host-owned; no logout promise | C-APP-18 |

New access and refresh expiry is `min(ordinary expiry, finite app deadline)`. Persisted expiry, signed access JWT `exp`, and response `expires_in` agree. At 159 with ordinary access expiry 3759 and app deadline 160, all report expiry 160 and `expires_in=1`; issuance at 160 is rejected. Refresh uses its own ordinary TTL under the same cap. Codes, PAR, device/CIBA request TTLs and ID-token/session semantics retain their own rules. Existing JWT signatures cannot learn later disablement; offline verification and introspection caches may be stale. Online Lockspire consumers check current issuing-app state. Do not promise universal immediate revocation or host/RP logout.

Shared-secret expiry gates Basic, post and secret-JWT equally. Assertion expiry, algorithm and replay checks remain independent. Secret expiry alone does not revoke issued tokens; confidential refresh still needs current client authentication. Public-key/mTLS methods have no shared-secret expiry.

<a id="management-and-wire"></a>
## Management and wire metadata (D-11–D-17; DCR-03)

Management lifetime defaults to unlimited and may be finite by explicit host policy. GET never rotates or extends a credential. Successful PUT replaces mutable metadata and immediately rotates the management token under current policy; the old token then fails. Lost PUT response recovery requires authorized host staff rotation. Registration intake `:disabled` blocks new registrations but does not disable existing management. Explicitly disabled apps remain blocked.

Existing host staff authorization is the sole recovery authority. Recovery atomically replaces the management token/deadline, shows plaintext once via existing handling, and preserves app/secret deadlines and disabled state. At 125 with management duration 40, recovery yields 165 while app=160 and secret=110 stay unchanged. At app equality 160 a valid recovered token may GET/DELETE but PUT gets 403. Client ID, setup token, expired token and secret grant no recovery authority.

For a shared secret, standard `client_secret_expires_at` is Unix seconds or `0` and is omitted without a shared secret. Server-owned `lockspire_client_expires_at` and `lockspire_registration_access_token_expires_at` are numeric Unix seconds or `0`, not RFC fields and not access-token `expires_in`. GET never discloses plaintext secret or management token.

PUT includes unchanged `client_id`; mutable metadata follows replacement semantics. Reject `registration_access_token`, `registration_client_uri`, `client_secret_expires_at`, `client_id_issued_at`; an included `client_secret` must match current material and never rotates it. Extension omission preserves values; identical echoes succeed; changed extensions return 400 `invalid_client_metadata`. Intake rejects either client-supplied extension with that code.

Missing management Bearer returns 401 with Bearer challenge and no error detail. Wrong, expired or replaced token, unknown app, or disabled-app credential returns 401 Bearer `invalid_token`. Valid credential on expired-app PUT returns 403 in the registration error envelope with local `registration_expired`; success is PUT/GET 200 and DELETE 204. Client-auth failures retain 401 `invalid_client` and Basic challenge. Introspection invalid caller is 401; authorized owned inactive target is 200 `{"active":false}`. UserInfo is 401 Bearer `invalid_token`; valid caller with bad grant input receives `invalid_grant`. Authorization failure before trusted redirect is local; after trust, use `access_denied` and original state. Device/CIBA grant expiry remains `expired_token`. Revocation stays non-disclosing for eligible callers. Never collapse endpoint-specific failures.

<a id="legacy-storage-concurrency-deployment"></a>
## Legacy, storage, concurrency and deployment (D-18–D-25; DCR-04)

All pre-upgrade app and credential lifetimes are effectively unlimited in built-in enforcement. Historical secret dates may be null, creation-time, past, future or stale after rotation; none is authoritative. Report unlimited (`0` where applicable). Do not infer from creation time or current policy. Host-specific stricter controls remain host-owned.

Persist `lifetime_version` 0 (legacy) or 1 (authoritative), nullable `client_expires_at` and `registration_access_token_expires_at`, and reuse the existing secret expiry column. Additive migration marks existing rows v0; new registrations write v1. On v1, null means authoritative unlimited. Missing or unknown version from an aware adapter is a configuration/server error.

Promote legacy rows only as a locked whole-row write: reload current row; preserve identity, hashes, enabled state and unrelated metadata; normalize all three deadlines to null; set only the replacement credential's deadline; set v1; atomically persist credentials, version, deadlines and audit. At 107, management-only replacement under policy 20 yields management=127, secret hash unchanged, app/secret unlimited. At 108, secret-only rotation under policy 30 yields secret=138, app/management unlimited. Already-authoritative unrelated deadlines remain unchanged. Ordinary reads, metadata-only changes and enable/disable do not promote; PUT does because it replaces management token. No eager fleet backfill or adoption command. Finite app expiry for legacy rows requires new registration.

Custom stores declare lifetime-aware client-store contract version 1 at the existing adapter boundary. Conformance requires round trips for version/deadlines, current-row guarded management and issuance, and atomic credential/verifier/version/deadline/audit changes. Missing or unsupported declaration/schema, unknown row version or dropped fields fails closed as configuration/server error. Token internals consume adapted dependencies; they do not probe callbacks.

Management mutations bind current credential hash and URL under lock, check enabled state and operation-specific deadlines, and apply only intended metadata to the current row. Two PUTs with one old token have one winner. Stale writes cannot restore a rotated secret or enabled state. DELETE, self-rotation and host recovery share current-state ordering. On write/audit failure, all credential/verifier/version/deadline/audit changes roll back. Issuance revalidates app and verified credential identity at final guarded boundary. Lock order: client rows by stable ID, grant/request rows by stable kind/ID, then token/family rows by stable kind/ID. Sample one decision time after waits. Reads linearize at successful current-state check; completed responses are not retroactively invalidated. Do not hold locks during network or response rendering.

Deployment order: existing code/schema; new prefix-aware additive packaged migration (example prefix `tenant_auth`, shipped checksums unchanged) while old code runs; stage new code and aware adapters without ingress; drain/stop old web, admin, jobs and CLI writers; cut over new ingress; first authoritative v1 write. Mixed old/new serving cannot claim enforcement. Before the first v1 write, additive-schema rollback to old code is compatible. Afterward retain schema/state and fix forward or use an enforcement-aware rollback build. Never reset versions/deadlines or drop columns as rollback. Validate DDL lock duration operationally; additive does not mean lock-free.

<a id="proof-and-handoff"></a>
## Proof and handoff (D-26–D-27)

Phase 163 owns app/storage focused tests; 164 shared-secret tests; 165 management tests. Phase 166 owns cross-phase clock-boundary journeys, PostgreSQL races/rollback, fresh/legacy/custom-store packaged hosts, CI, scoped security review and public/operator truth synchronization. Preserve PKCE S256, exact redirect matching, hashed secrets, single-use codes, refresh-family reuse revocation, no implicit flow, no `alg=none`, and redaction. Proof must observe actual expiry, rotation and recovery; zero observed events cannot pass. Host recovery attribution must differ from self-management, and telemetry/audit must exclude plaintext credentials, verifier material and hashes. Correct false PUT-secret-rotation wording only after behavior is proven. Public/operator language uses PRODUCT.md vocabulary and distinguishes expired, disabled and unknown. No admin redesign or storage-version detail for support staff.

## Requirement and decision map

| Owner | Decisions | Cases |
|---|---|---|
| Policy/time | D-01–D-05 | C-POL-01–C-POL-13 |
| Consumers/tokens | D-06–D-10 | C-APP-01–C-APP-18; C-TOK-01–C-TOK-04 |
| Management/wire | D-11–D-17 | C-MGMT-01–C-MGMT-12 |
| Legacy/storage | D-18–D-21 | C-LEG-01–C-LEG-08 |
| Concurrency/deploy | D-22–D-25 | C-RACE-01–C-RACE-06; C-DEP-01–C-DEP-04 |
| Proof/handoff | D-26–D-27 | C-PROOF-01–C-PROOF-04 |

| Requirement | Substantive owner |
|---|---|
| DCR-02 | Policy/time and consumers/tokens |
| DCR-03 | Management/wire |
| DCR-04 | Legacy/storage and concurrency/deploy |
