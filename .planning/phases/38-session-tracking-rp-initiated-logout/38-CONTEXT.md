# Phase 38: Session Tracking & RP-Initiated Logout - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver durable `sid` (Session ID) tracking on interaction and token records, implement a `GET /POST /end_session` endpoint with a host-owned session clearing seam, and add the discovery and admin-UI surfaces that make the feature operator-complete.

This phase covers:
- New `sid` field on `lockspire_interactions` and `lockspire_tokens` (migration + domain)
- `sid` emitted as an OIDC claim in all issued ID tokens
- `revoke_by_sid/1` in the token store
- `GET /end_session` and `POST /end_session` endpoints with `id_token_hint`, `client_id`, `post_logout_redirect_uri`, and `state` parameter handling
- Host logout seam: redirect-pattern with signed `return_to`, configured via `config :lockspire, logout_path:`
- `end_session_endpoint` in OIDC discovery; `backchannel_logout_supported: false` and `frontchannel_logout_supported: false` as truthful placeholders
- `post_logout_redirect_uris` field on client records + admin UI
- `sid` visible in token detail admin view
- Lockspire-owned "You have been signed out" fallback page (plain controller render)
- Generator update: host logout route template

**Not in scope (Phase 39):** Back-Channel Logout webhook dispatch, Front-Channel Logout iframe rendering, session-level revocation UI, flipping BCL/FCL discovery flags to true.

</domain>

<decisions>
## Implementation Decisions

### sid scope & lifecycle

- **D-01:** `sid` is **per-interaction** scope. Each authorization flow generates its own sid. Lockspire does not attempt to observe cross-client browser sessions since the host owns the web session and Lockspire cannot observe it.
- **D-02:** `sid` is generated at **interaction creation time** — when the `lockspire_interactions` row is first inserted at the `/authorize` endpoint. Always present; no null sid edge cases or lifecycle ambiguity.
- **D-03:** `sid` is **denormalized on `token_record`** as a new `sid` field on `lockspire_tokens`. Same pattern as `interaction_id` already denormalized on tokens. Fast lookups by sid without join; safe even if the interaction row is later purged.
- **D-04:** `sid` is **always emitted as the OIDC `sid` claim** in issued ID tokens (`IdToken.sign/1`). Required for Phase 39 BCL where the logout token's sid must match the ID token's sid.
- **D-05:** Phase 38 includes **`revoke_by_sid/1`** in the token store — marks all active (non-revoked, non-redeemed) tokens for a session as revoked. Phase 39 calls this function without schema changes.

### Host logout seam

- **D-06:** **Redirect pattern** — mirrors `redirect_for_login`. Lockspire redirects the user to a host-owned path with a signed, time-limited `return_to` URL. The host clears the browser session and redirects to the Lockspire `return_to`. Lockspire's completion endpoint then redirects to `post_logout_redirect_uri` (or shows the logged-out page).
- **D-07:** Lockspire passes **`account_id` + signed `return_to` URL** to the host logout path. Minimal surface, consistent with the login seam. No wider JWT struct needed.
- **D-08:** Host logout path is configured via **`config :lockspire, logout_path: "/your/path"`**. Explicit config key; no convention-based routes.
- **D-09:** **Always immediate** — no confirmation step in the Lockspire protocol. If the host wants a confirmation page, it implements that in its own route before redirecting to `return_to`.
- **D-10:** If the `return_to` signed token fails validation on the completion endpoint, **treat as logout success anyway** — log the validation failure, revoke the session's tokens (if sid is known from the return_to payload), and redirect to `post_logout_redirect_uri` or the logged-out page. Do not strand the user.
- **D-11:** `revoke_by_sid` is called **at end_session completion** — after the host returns to Lockspire's completion endpoint. Not at end_session start.
- **D-12:** If the `logout_path` config key is **not set, raise at startup** with a clear error message pointing to the install guide. Fail fast; no silent runtime fallback.
- **D-13:** **Generator update** — Phase 38 emits a host logout route template in the generated host code, pre-wired to clear the session and redirect to `return_to`. Consistent with how consent and device-verify routes are generated.

### /end_session strictness

- **D-14:** `id_token_hint` validation: **validate signature** using Lockspire's own JOSE signing keys, **tolerate expiry** (hints are intentionally presented after expiry per OIDC spec). Extract `sub` and `sid` from validated claims.
- **D-15:** `post_logout_redirect_uri` requires **exact match against client's registered `post_logout_redirect_uris`** (new field on client record). Same strict model as `redirect_uri`. Unregistered URIs are rejected. No partial-match or domain-prefix leniency.
- **D-16:** If **no `id_token_hint`** is provided: proceed anyway. Still redirect to host logout path to clear the browser session and redirect to `post_logout_redirect_uri` if registered. Token revocation is **skipped** (no sid to revoke against).
- **D-17:** If **no `post_logout_redirect_uri`** (or the provided URI is not registered): show Lockspire-owned minimal "You have been signed out" page. No redirect to `client_uri`.
- **D-18:** `/end_session` accepts **both GET and POST** per OIDC RP-Initiated Logout requirement.
- **D-19:** `end_session_endpoint` published in OIDC discovery in Phase 38. `backchannel_logout_supported: false` and `frontchannel_logout_supported: false` also published as truthful placeholders for Phase 39.
- **D-20:** If both `client_id` and `id_token_hint` are provided, **reject if `client_id` is not in `id_token_hint`'s `aud`**. Prevents one client from initiating logout using another client's ID token.

### Admin UI surface

- **D-21:** `sid` appears in the **existing token detail view** (`tokens_live/show.ex`). Not in the token list view. **View-only** in Phase 38 — no session-level revocation UI.
- **D-22:** No separate Sessions admin LiveView in Phase 38. Session-level revocation UI and session browsing handled in Phase 39.
- **D-23:** `post_logout_redirect_uris` field added to **client edit + show views** (`clients_live/show.ex` and `clients_live/form_component.ex`). Operators need to register the field for the feature to work.
- **D-24:** Lockspire-owned "logged out" page is a **plain controller render** — no LiveView. Minimal static template. Consistent with how error pages work in Lockspire.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements

- `.planning/ROADMAP.md` — Phase 38 goal, success criteria (SLO-01, SLO-02), and dependency on Phase 37
- `.planning/REQUIREMENTS.md` — SLO-01 (sid tracking) and SLO-02 (end_session + host seam); Phase 39 requirements (SLO-03, SLO-04) are out of scope for this phase
- `.planning/PROJECT.md` — embedded-library boundaries, host seam ownership model, Ecto/Postgres durable truth constraint
- `.planning/STATE.md` — current milestone state and accumulated protocol-boundary decisions

### Key implementation files (migration targets)

- `lib/lockspire/storage/ecto/interaction_record.ex` — existing interaction schema; `sid` field added here via migration
- `lib/lockspire/storage/ecto/token_record.ex` — existing token schema; `sid` field denormalized here via migration
- `lib/lockspire/storage/ecto/client_record.ex` — client schema; `post_logout_redirect_uris` field added here
- `lib/lockspire/storage/interaction_store.ex` — interaction persistence; sid generation goes here
- `lib/lockspire/domain/interaction.ex` — interaction domain struct; add `sid` field

### Protocol layer (integration points)

- `lib/lockspire/protocol/authorization_flow.ex` — where sid is assigned (interaction creation path)
- `lib/lockspire/protocol/id_token.ex` — sid claim emission point in ID token signing
- `lib/lockspire/host/account_resolver.ex` — host seam callbacks; logout pattern follows the same redirect philosophy as `redirect_for_login`
- `lib/lockspire/host/interaction_result.ex` — existing host handoff struct for login; logout return_to follows the same pattern

### Web layer (new routes and controllers)

- `lib/lockspire/web/router.ex` — end_session route addition point; also where completion endpoint is mounted
- `lib/lockspire/web/controllers/discovery_controller.ex` — end_session_endpoint + BCL/FCL metadata publication

### Admin UI (modification targets)

- `lib/lockspire/web/live/admin/tokens_live/show.ex` — sid display in token detail view
- `lib/lockspire/web/live/admin/clients_live/show.ex` — post_logout_redirect_uris display in client detail
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — post_logout_redirect_uris editing in client form

### Install generator

- `lib/mix/tasks/lockspire.install.ex` — generator update to emit host logout route template

### Standards (authoritative)

- `https://openid.net/specs/openid-connect-rpinitiated-1_0.html` — RP-Initiated Logout spec (end_session parameter semantics, GET+POST requirement, id_token_hint validation guidance)
- `https://openid.net/specs/openid-connect-backchannel-1_0.html` — Back-Channel Logout spec (sid semantics, logout token structure — read for Phase 38 sid design to ensure Phase 39 compatibility)
- `https://openid.net/specs/openid-connect-session-1_0.html` — Session Management spec (sid claim semantics, check_session_iframe — iframe out of scope for Phase 38)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Host.InteractionResult` — existing host handoff struct (`login_path`, `return_to`, `params`). The logout redirect pattern follows the same shape: Lockspire redirects user to a host path with a signed `return_to`.
- `Lockspire.Host.AccountResolver.redirect_for_login/2` — existing precedent for the redirect-pattern host seam. The logout seam mirrors this: one configured path, one signed return URL.
- `Interaction` + `InteractionRecord` — already persist multiple timestamps and the `account_id`. `sid` is a new UUID field added alongside these. Migration pattern is established by prior phases (auth_time, max_age added in Phase 37).
- `TokenRecord.family_id` denormalization — existing precedent for denormalizing a foreign reference onto tokens to avoid join-dependent queries. `sid` follows the same pattern.
- Existing admin token show/detail view (`tokens_live/show.ex`) — already displays jti, family_id, cnf, etc. Adding `sid` is a field addition.
- `clients_live/form_component.ex` — already handles multi-value fields (scopes, redirect_uris). `post_logout_redirect_uris` follows the same textarea/list pattern.

### Established Patterns

- **Durable Ecto/Postgres truth over transport-only inference** — sid lives in DB rows, not in-process state or JWT-only.
- **Thin Phoenix adapters over protocol-owned correctness** — end_session validation logic lives in a protocol module, not in the controller.
- **Strict exact-match validation** — redirect_uri uses exact match; `post_logout_redirect_uri` uses the same model.
- **Signed, time-limited return_to URLs** — existing pattern in the login/interaction flow; logout completion uses the same signing approach.
- **Fail-fast startup validation** — Lockspire already validates required config at startup; `logout_path` follows the same guard.
- **Narrow, truthful discovery** — discovery is updated only when the feature is provably shipped (BCL/FCL published as `false` until Phase 39).

### Integration Points

- `InteractionStore` / `Repo` — sid generation happens at interaction insert; `revoke_by_sid/1` is a new query function on the token store.
- `IdToken.sign/1` — new `sid` claim added alongside existing `sub`, `iss`, `aud`, `iat`, `exp`, `nonce`, `auth_time`.
- `DiscoveryController` — add `end_session_endpoint` to the JSON payload; `backchannel_logout_supported: false`, `frontchannel_logout_supported: false`.
- `TokenStore` — new `revoke_by_sid/1` that updates all matching active tokens to `revoked_at = now()`.
- Router — new routes: `get "/end_session", EndSessionController, :show` and `post "/end_session", EndSessionController, :create`; plus a completion route `get "/end_session/complete", EndSessionController, :complete`.
- `ClientRecord` — new `post_logout_redirect_uris` field (`:array, :string`), same type as `redirect_uris`.

</code_context>

<specifics>
## Specific Ideas

- The host logout seam deliberately mirrors `redirect_for_login` to keep the Lockspire integration surface familiar. A host that has already implemented the login seam will recognize the pattern immediately.
- `revoke_by_sid/1` should be built in Phase 38 even though Phase 39 is the primary consumer — it ships alongside the migration and avoids Phase 39 needing to touch the token schema again.
- The "logged out" page should be minimal and host-overridable via the standard Phoenix template override path, similar to Lockspire's consent UI layout pattern.
- `backchannel_logout_supported: false` and `frontchannel_logout_supported: false` in discovery are truthful placeholders — Phase 39 flips them to true. Do not omit them; their absence would make it harder for RPs to understand the roadmap.

</specifics>

<deferred>
## Deferred Ideas

- **Session-level revocation UI** — `revoke_by_sid/1` is built in Phase 38 but the admin UI button handled in Phase 39 when BCL/FCL tooling context makes the feature coherent.
- **Back-Channel Logout webhook dispatch** — Phase 39 (SLO-03).
- **Front-Channel Logout iframe rendering** — Phase 39 (SLO-04).
- **`frontchannel_logout_supported: true` / `backchannel_logout_supported: true`** — discovery flags flipped in Phase 39 when the mechanisms are live.
- **`check_session_iframe`** — OIDC Session Management iframe mechanism; not in scope for Phases 38 or 39.
- **New Sessions admin LiveView** — session browsing surface may be worth adding after Phase 39 when session lifecycle tooling is complete.

</deferred>

---

*Phase: 38-session-tracking-rp-initiated-logout*
*Context gathered: 2026-04-29*
