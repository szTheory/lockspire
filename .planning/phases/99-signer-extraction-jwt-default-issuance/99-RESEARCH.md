# Phase 99: Signer Extraction + JWT-Default Issuance - Research

**Researched:** 2026-05-28
**Domain:** Elixir/Phoenix OAuth/OIDC token issuance (RFC 9068 `at+jwt` signing, RFC 8707 resource indicators, runtime policy resolution, admin LiveView)
**Confidence:** HIGH (every claim verified against the live codebase at the cited line numbers; no external dependency research required)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Create `Lockspire.Protocol.AccessTokenSigner` with a single public function that accepts the already-built `%Lockspire.Domain.Token{}` struct plus the issuance `request` (carrying `key_store`, `now`, and `token_format_options`) and the `client`, and returns the existing `{:ok, raw_token, token_hash}` triple. The signer owns BOTH branches internally: `:jwt` (JOSE sign, including `fetch_signing_key/1` + `decode_private_jwk/1` extracted from `rfc8693_exchange.ex`) and `:opaque` (delegate to `TokenFormatter.format_access_token/1`).
- **D-02:** Each of the five issuance paths feeds the signer the canonical `%Token{}` and changes its mint site to ONE line — swapping `TokenFormatter.format_access_token(...)` for `AccessTokenSigner.issue(token, client, request)` at `token_exchange.ex:~1397` and `refresh_exchange.ex:~286`, and replacing the RFC 8693 path's inline `sign_jwt_access_token/6` body with a call into the shared module. After this phase no `at+jwt` signing logic remains outside `AccessTokenSigner` (ROADMAP success criterion #5).
- **D-03:** The signer's emitted token must pass the Phase 98 verifier unchanged: `typ: "at+jwt"` header and `iss`/`sub`/`exp`/`iat`/`aud`/`client_id`/`jti`/`scope` claims exactly as `rfc8693_exchange.ex:317-348` does today (`iss = Config.issuer!()`, `exp = iat + 3600`, `jti` from `TokenFormatter`). Custom-claim merge with the restricted-claim drop (`~w(iss sub aud exp iat jti client_id)`) preserved for the RFC 8693 path.
- **D-04:** Server-wide `access_token_format` (default `:jwt`) lives as a new `Ecto.Enum` column on the runtime-editable `ServerPolicy` record, alongside `dpop_policy`/`security_profile`/`registration_policy` — NOT in boot-time `Config`. Reachable via the existing `Repository.get_server_policy()`.
- **D-05:** The format decision is resolved in exactly ONE place — inside `AccessTokenSigner` — using the existing `SecurityProfile.resolve_effective_profile/2` precedence pattern as the template: per-client `access_token_format` (`:jwt | :opaque | nil`) takes precedence; `nil` inherits server-wide `ServerPolicy.access_token_format`, which defaults `:jwt`.
- **D-06:** Add `access_token_format` as a **nullable** `Ecto.Enum` with values `[:jwt, :opaque]` and **no DB default** (`nil` = inherit) on `client_record.ex`. Thread through `changeset/2` cast, `update_changeset/2` cast (both), `to_domain/1`, and the `Domain.Client` struct. Precedent: `id_token_signed_response_alg`.
- **D-07:** Admin client-detail UI adds an `inherit | jwt | opaque` `<select>` mirroring `dpop_policy`, `inherit`→`nil`, plus a `defaults_for/2` clause, a `normalize_mutable_field/2` clause, and a display row in `show.ex`. Doclink → `docs/protect-phoenix-api-routes.md`.
- **D-08:** The signer derives `aud` from the `%Token{}`'s `audience` field: when non-empty, `aud = audience`; when empty, `aud = [client_id]`. (See Pitfall 3 — the RFC 8693 carve-out needs a string, not a list.)
- **D-09:** AC and refresh already thread `resource` into `%Token{}.audience`; AUD-01/02 for those two is satisfied by D-08. **Device and CIBA do NOT** — they hardcode `audience: []` and never call `validate_requested_resources`. AUD-01 for device/CIBA requires **net-new wiring**.
- **D-10:** The RFC 8693 token-exchange path keeps `aud = client.client_id` when no `resource` is supplied (AUD-03, no behavior change). When `resource` IS supplied, existing behavior preserved; Phase 99 only routes it through the shared signer.
- **D-11:** Add `access_token_signing_alg_values_supported` to `discovery.ex` `openid_configuration/0` as the literal list `["RS256", "ES256", "PS256"]`, published unconditionally. Do NOT reuse `SecurityProfile.allowed_signing_algorithms/1`.

### Claude's Discretion

- Exact public function name/arity of `AccessTokenSigner` (`issue/3` suggested), provided it takes `%Token{}` + `client` + `request` and returns `{:ok, raw, hash}`.
- Whether `fetch_signing_key/1` and `decode_private_jwk/1` move wholesale into `AccessTokenSigner` or into a shared helper, provided no JOSE-signing logic stays duplicated.
- Exact migration filename/structure, provided nullable with no DB default for the per-client column.
- Exact admin select label copy and doclink anchor text, provided `inherit/jwt/opaque` options and the `docs/protect-phoenix-api-routes.md` target are preserved.
- Internal naming of the format-resolution helper, provided precedence is per-client → server-default → `:jwt`.

### Deferred Ideas (OUT OF SCOPE)

- DPoP/mTLS-bound `at+jwt` end-to-end pipeline proof — Phase 100 (BIND-01..03). Phase 99 only ensures the signer **carries `cnf`**; no enforcer code, no e2e tests.
- `[:lockspire, :rs, :token_format]` telemetry, `docs/upgrading/v1.27.md`, `mix lockspire.doctor token_format`, install-template uncomment — Phase 102.
- Adoption-demo `200-with-issued-token` smoke + demo router `audience:` reconciliation — Phase 101.
- Accepting `at+jwt` at `/userinfo` (UNIFIED-01) — explicitly deferred. Phase 99 PRESERVES the JWT-for-host-APIs / opaque-for-Lockspire-resources split. **Do NOT touch `/userinfo` or `/introspect`.**
- Emitting `application/at+jwt` (stricter `typ`) — keep exact `at+jwt` absent a conformance reason.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGNER-01 | Shared `Protocol.AccessTokenSigner` owns `at+jwt` signing; `rfc8693_exchange.ex:317-361` block extracted; called from all 5 paths; no duplicate signing logic. | Extraction source verified at `rfc8693_exchange.ex:317-361` (Standard Stack / Code Examples). The five mint seams located and their **actual** return shapes documented (Pitfall 1 — they are NOT uniform `{:ok, raw, hash}` today). |
| SIGNER-02 | Signer respects per-client + server-wide policy; produces opaque via `TokenFormatter` when `:opaque`; format decision in one place. | Precedence template `SecurityProfile.resolve_effective_profile/2:29-60` verified. ServerPolicy reachable via `request.opts[:server_policy_store]` or `:key_store` (both `Repository`) — see Architecture Patterns. |
| FORMAT-01 | Server-wide `access_token_format` (default `:jwt`); operators can set `:opaque`. | `ServerPolicyRecord` column pattern verified (`server_policy_record.ex:14-28`). Migration precedent verified. **Open Question 1: where the server-wide value is *edited* (admin surface) is undecided.** |
| FORMAT-02 | Per-client `access_token_format` override (`:jwt \| :opaque \| nil`); visible in admin client-detail with doclink. | `id_token_signed_response_alg` is an exact field-for-field precedent (`client_record.ex:57,129,218,288` / `domain/client.ex:50,112`). UI-SPEC fully specifies the surface. |
| AUD-01 | `resource=<URI>` → `aud = [resource]` across AC/refresh/device/CIBA. | AC (`token_exchange.ex:705`) + refresh (`refresh_exchange.ex:306`) already thread resource. Device (`:809`/`955`) + CIBA hardcode `audience: []` — net-new validation+threading required (Pitfall 2). |
| AUD-02 | `resource=` absent on AC/refresh/device/CIBA → `aud = [client_id]`. | D-08 derivation. **Note the list-vs-string nuance vs AUD-03 (Pitfall 3).** |
| AUD-03 | `resource=` absent on RFC 8693 → `aud` stays `client_id` (no change). | Current code emits `aud => client.client_id` (string, `rfc8693_exchange.ex:327`); existing test asserts `payload["aud"] == client.client_id` (string, `rfc8693_exchange_test.exs:192`). Carve-out is string, not list (Pitfall 3). |
| DISCOVERY-01 | Discovery advertises `access_token_signing_alg_values_supported: ["RS256","ES256","PS256"]`. | `discovery.ex:86-96` static block + `id_token_signing_alg_values_supported` sibling (`:95`,`:154-156`). **Gating nuance flagged (Pitfall 4).** |
</phase_requirements>

## Summary

This is a backend-heavy refactor-and-default-flip phase against a mature, well-factored Elixir/Phoenix OAuth library. The CONTEXT.md produced during discuss-phase is exceptionally well-grounded — its eleven locked decisions (D-01..D-11) cite precise line numbers, and **all of them verified true** against the live codebase. There is no new external dependency: JOSE 1.11.12 (already a dep, already the only `at+jwt` signer today) provides everything. There is no package legitimacy audit to run because no package is being added.

The primary research value, therefore, is **discrepancy-surfacing**: places where the requirement phrasing or a locked decision understates the implementation reality, and where a naive "one-line swap" will break an existing green test or fail the Phase 98 verifier. Five such findings dominate the Common Pitfalls section: (1) the five mint seams do **not** share the `{:ok, raw, hash}` return shape today — AC/device/CIBA `build_access_token/6` returns `{%Token{}, raw_string}` and persists the `%Token{}.token_hash` separately, so the "one-line swap" must reconcile hash ownership; (2) device and CIBA genuinely need net-new `resource`→`audience` validation, not propagation; (3) the `aud` carve-out for RFC 8693 is a **string** (`client_id`) while AC/refresh/device/CIBA want a **list** (`[client_id]`) — a uniform `[client_id]` derivation would turn `rfc8693_exchange_test.exs:192` red; (4) the refresh path builds its rotated access token with `account_id: nil`, so the JWT `sub` must be sourced from `presented_refresh_token.account_id`, not from the rotated token; (5) DISCOVERY-01's "gate on token_endpoint mounted" does not match the actual `id_token_signing_alg_values_supported` sibling, which is published unconditionally in the static block.

**Primary recommendation:** Build `AccessTokenSigner.issue(%Token{}, %Client{}, request) :: {:ok, raw, hash}` as a single resolution point, extract `fetch_signing_key/1` + `decode_private_jwk/1` + the JOSE sign block wholesale from `rfc8693_exchange.ex`, derive `aud` from `%Token{}.audience` with an explicit string-vs-list carve-out for the exchange path, and treat device/CIBA resource threading + refresh `sub`-sourcing as real implementation tasks. Mirror `id_token_signed_response_alg` field-for-field for the per-client column and `SecurityProfile` for the precedence resolver.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `at+jwt` signing (JOSE) | API/Backend (`Protocol.AccessTokenSigner`) | — | All issuance is server-side protocol logic; key material never leaves the BEAM. |
| Format-policy resolution (per-client → server → `:jwt`) | API/Backend (inside signer) | Database (ServerPolicy + Client records) | D-05: one resolution point; reads durable policy rows. |
| Server-wide `access_token_format` storage | Database (`lockspire_server_policies`) | API/Backend (`Admin.ServerPolicy` context) | D-04: runtime-editable durable row, not boot-time `Config`. |
| Per-client `access_token_format` override storage | Database (`lockspire_clients`) | API/Backend (`Clients` + `Admin.Clients`) | D-06: nullable column; admin-mutable via `update_changeset`. |
| `resource`→`aud` derivation | API/Backend (signer reads `%Token{}.audience`) | API/Backend (per-path `validate_requested_resources`) | RFC 8707 validation stays per-path; signer only reads the resolved audience. |
| Per-client override editing | Frontend Server (admin client-detail LiveView) | API/Backend (`Admin.Clients.update_client`) | FORMAT-02: the only net-new frontend surface (per UI-SPEC). |
| Discovery advertisement | API/Backend (`Protocol.Discovery`) | — | DISCOVERY-01: static metadata in `openid_configuration/0`. |
| Signer `cnf` carry-through | API/Backend (signer copies `%Token{}.cnf`) | — | Phase 100 dependency; Phase 99 must propagate, not enforce. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `jose` | 1.11.12 | JWT/JWS signing for `at+jwt` | `[VERIFIED: mix.lock]` Already the ONLY `at+jwt` signer in the codebase (`rfc8693_exchange.ex:340-346`). No new dep. |
| `jason` | 1.4 | JWK JSON decode (`decode_private_jwk/1`) | `[VERIFIED: mix.exs:48]` Already used in the extraction source (`rfc8693_exchange.ex:386`). |
| `ecto_sql` | 3.13.5 | `Ecto.Enum` columns + migrations | `[VERIFIED: mix.exs]` All policy fields use `Ecto.Enum` over `:text` columns. |
| `phoenix_live_view` | 1.1.28 | Admin client-detail override `<select>` | `[VERIFIED: mix.exs]` Existing admin LiveView (`form_component.ex`, `show.ex`). |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:crypto` (OTP) | bundled | `Policy.hash_token/1` (SHA-256 of the raw token) | The signer's `token_hash` for the persisted `%Token{}` comes from `Policy.hash_token(raw)` (JWT path, `rfc8693_exchange.ex:348`) or `TokenFormatter.hash_token/1` (opaque path) — they are the same SHA-256 hex. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Policy.hash_token/1` for JWT hash | `TokenFormatter.hash_token/1` | Identical implementation (both `:sha256 \|> :crypto.hash \|> Base.encode16(:lower)`). `[VERIFIED: token_formatter.ex:23-27]`. Pick one for the signer and use it for both branches to keep hashing uniform. |
| Signer fetches ServerPolicy itself | Pass resolved format in `request` | Signer-fetches is cleaner (D-05 one-place); the request already carries `server_policy_store: Repository` (`token_controller.ex:24`), so the signer can call `Repository.get_server_policy()` or the store callback. **Recommend signer-fetches** to keep all five call sites one-line. |

**Installation:** None. No package added. (Package Legitimacy Audit not applicable — zero new dependencies.)

## Package Legitimacy Audit

**Not applicable.** Phase 99 adds no external packages. All capabilities use dependencies already present and already in production use for this exact purpose (`jose`, `jason`, `ecto_sql`, `phoenix_live_view`). No `slopcheck` / `npm view` / `pip index` gate is required.

## Architecture Patterns

### System Architecture Diagram

```
                        POST /token  (token_controller.ex)
                  request.opts = [key_store: Repository,
                                  server_policy_store: Repository,
                                  token_store: Repository, now: ...]
                                       |
              +------------------------+------------------------+-------------------+
              |            |           |            |                               |
        authorization   refresh     device        CIBA                      RFC 8693
           code         rotation     grant        grant                  token-exchange
        (redeem_code) (rotate_*)  (redeem_      (redeem_                 (sign_or_format_
              |            |        device_       ciba_                   access_token)
              |            |        grant)        grant)                       |
              |            |           |            |                          |
        builds %Token{} with audience field set per path:                      |
        AC: audience = requested_resources  (token_exchange.ex:705)            |
        refresh: audience = requested_resources (refresh_exchange.ex:306)      |
        device: audience = []  <-- AUD-01 GAP (token_exchange.ex:955)          |
        CIBA:   audience = []  <-- AUD-01 GAP (token_exchange.ex:809)          |
              |            |           |            |                          |
              +------------+-----------+------------+--------------------------+
                                       |
                          Lockspire.Protocol.AccessTokenSigner.issue/3
                                       |
                    resolve_format(client, server_policy)   <-- D-05, ONE place
                    per-client access_token_format
                      ? :jwt | :opaque
                      : server_policy.access_token_format (default :jwt)
                                       |
              +------------------------+------------------------+
              | format == :jwt                                 | format == :opaque
              v                                                v
      fetch_signing_key(request)                       TokenFormatter.format_access_token
      decode_private_jwk                                  -> {raw, hash}
      base_claims:
        iss=Config.issuer!(), sub=token.account_id,
        aud=derive_aud(token, client),  <-- D-08 + Pitfall 3 carve-out
        exp=iat+3600, iat, client_id, jti, scope,
        cnf=token.cnf  <-- Phase 100 dependency
      JOSE.JWT.sign(jwk, %{alg, kid, typ:"at+jwt"}, claims)
      -> {compact_jwt, Policy.hash_token(compact_jwt)}
                                       |
                                       v
                       {:ok, raw_token, token_hash}
                                       |
            persisted %Token{token_hash: hash} + raw flows to response
                                       |
                                       v
                  Phase 98 verifier (verify_token.ex) accepts at+jwt
```

### Recommended Module Layout

```
lib/lockspire/protocol/
├── access_token_signer.ex   # NEW (SIGNER-01/02, AUD-01..03 derivation, D-05 resolution)
├── rfc8693_exchange.ex      # signing block REMOVED; calls AccessTokenSigner
├── token_exchange.ex        # build_access_token/6 calls signer (AC/device/CIBA)
├── refresh_exchange.ex      # build_rotated_access_token calls signer
├── token_formatter.ex       # unchanged (opaque path the signer delegates to)
├── security_profile.ex      # unchanged (resolution-precedence template)
└── discovery.ex             # DISCOVERY-01 static key added

lib/lockspire/domain/
├── client.ex                # + access_token_format field (mirror id_token_signed_response_alg)
└── server_policy.ex         # + access_token_format field (default :jwt)

lib/lockspire/storage/ecto/
├── client_record.ex         # + access_token_format Ecto.Enum (changeset + update_changeset + to_domain)
└── server_policy_record.ex  # + access_token_format Ecto.Enum (changeset + to_domain)

lib/lockspire/admin/
├── clients.ex               # + @mutable_fields + normalize_mutable_field clause
└── server_policy.ex         # + put_access_token_format/1 (Open Question 1)

lib/lockspire/web/live/admin/clients_live/
├── form_component.ex        # + <select> + defaults_for clause
└── show.ex                  # + global/override/effective rows + effective resolver

priv/repo/migrations/
└── <ts>_add_access_token_format.exs   # client (nullable) + server_policy (default "jwt")
```

### Pattern 1: One-place format resolution (mirror `SecurityProfile`)

**What:** Resolve `effective_format = per_client || server_default || :jwt` inside the signer, modeled on `SecurityProfile.resolve_effective_profile/2`.
**When to use:** Every issuance path — the signer is the single resolution point (D-05).
**Note the inherit-sentinel difference:** `SecurityProfile` uses the atom `:inherit`; `access_token_format` uses `nil` for inherit (D-06, nullable column, no DB default). So the resolver branches on `nil`, not on `:inherit`.

```elixir
# Source: pattern from security_profile.ex:29-59 (VERIFIED), adapted for nil-inherit
defp resolve_format(%Client{access_token_format: fmt}, _server_policy)
     when fmt in [:jwt, :opaque],
     do: fmt

defp resolve_format(%Client{access_token_format: nil}, %ServerPolicy{access_token_format: server_fmt}),
  do: server_fmt || :jwt
```

### Pattern 2: Audience derivation with the RFC 8693 carve-out (D-08 + Pitfall 3)

**What:** Derive `aud` from `%Token{}.audience`. For AC/refresh/device/CIBA, emit a **list**; for the RFC 8693 no-resource path, the existing test demands a **string** (`client_id`).
**When to use:** Inside the signer when building `base_claims`.

```elixir
# AC/refresh/device/CIBA: list form (success criterion #3, AUD-02)
defp derive_aud([], client_id), do: [client_id]      # absent resource -> [client_id]
defp derive_aud(audience, _client_id) when audience != [], do: audience   # [resource]

# RFC 8693 no-resource: string form, preserving rfc8693_exchange_test.exs:192
# (assert payload["aud"] == client.client_id  -- a bare string, not a list)
```

RFC 9068 §3 / RFC 7519 §4.1.3 permit `aud` as either a single StringOrURI or an array. The carve-out is legal; the planner must decide how the signer knows which form to emit (recommend: a per-path flag on the request, or a distinct exchange-path code path that keeps the legacy string).

### Pattern 3: Per-client nullable enum (mirror `id_token_signed_response_alg`)

**What:** A nullable `Ecto.Enum` threaded record→changeset(s)→domain→admin.
**Worked precedent (all VERIFIED):**
- `client_record.ex:57` — `field(:id_token_signed_response_alg, Ecto.Enum, values: [:RS256, :ES256, :PS256, :EdDSA])` (no default → nil)
- `client_record.ex:129` — cast in `changeset/2`
- `client_record.ex:218` — cast in `update_changeset/2` (the admin-mutable path — MUST add here too)
- `client_record.ex:288` — `to_domain/1` mapping
- `domain/client.ex:50,112` — struct field + default `nil`
- migration: `add :access_token_format, :text` (nullable; precedent `..._add_token_endpoint_auth_signing_alg_to_lockspire_clients.exs`)

### Anti-Patterns to Avoid

- **Uniform `[client_id]` audience for all five paths:** Breaks `rfc8693_exchange_test.exs:192` (expects string). Keep the exchange-path carve-out (Pitfall 3).
- **Reusing `SecurityProfile.allowed_signing_algorithms/1` for DISCOVERY-01:** Returns `["RS256","ES256","PS256","EdDSA"]` for `:none` (`security_profile.ex:64`) and `["ES256","PS256"]` under FAPI — neither matches the required `["RS256","ES256","PS256"]`. Use a literal (D-11). `[VERIFIED: security_profile.ex:62-64]`.
- **Sourcing JWT `sub` from the rotated refresh access token:** `build_rotated_access_token` sets `account_id: nil` (`refresh_exchange.ex:303`). The JWT `sub` must come from `presented_refresh_token.account_id` (Pitfall 5).
- **Putting `access_token_format` in boot-time `Config`:** D-04 mandates ServerPolicy (runtime-editable, admin-visible, Phase 102 doctor-readable).
- **Storing an `:inherit` sentinel for the per-client field:** `nil` is the inherit state (D-06).
- **Touching `/userinfo` or `/introspect`:** They keep opaque tokens. Out of scope (Deferred).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWT signing | Custom JWS compact serializer | `JOSE.JWT.sign/3` + `JOSE.JWS.compact/1` (already in `rfc8693_exchange.ex:340-346`) | JOSE handles alg/kid/typ header + base64url + signature; hand-rolling invites `alg=none` and canonicalization bugs. |
| Token hashing | Ad-hoc hash | `Policy.hash_token/1` or `TokenFormatter.hash_token/1` (identical SHA-256 hex) | One hashing convention; the verifier and stores already assume it. |
| Format precedence | New resolver | `SecurityProfile.resolve_effective_profile/2` pattern | Established per-client→global→default idiom; consistency with PAR/DPoP/profile resolution. |
| Per-client enum plumbing | New plumbing shape | Copy `id_token_signed_response_alg` field-for-field | A complete, tested worked example already exists. |
| Admin override `<select>` + normalize | New form idiom | Copy `dpop_policy` select + `normalize_dpop_policy` shape (with `inherit→nil` like `normalize_authorization_signing_alg`) | UI-SPEC locks the idiom; drift is mechanically detectable. |
| Resource validation | New RFC 8707 validator | `validate_requested_resources/2` (AC at `token_exchange.ex:661`, refresh at `refresh_exchange.ex:155`) | Device/CIBA should call the same shape, not invent a parallel one (AUD-01). |

**Key insight:** Phase 99 is overwhelmingly a *consolidation* phase. Almost every "new" thing has a precedent module to copy. The only genuinely novel logic is (a) the signer's `aud` carve-out, (b) device/CIBA resource threading, and (c) the refresh `sub`-sourcing — and even those reuse existing helpers.

## Runtime State Inventory

> This is a code refactor + additive-column phase, not a rename/migration of stored data. Still, the JWT-default flip changes runtime *behavior* for existing clients, so the relevant categories are answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Existing `lockspire_clients` rows have no `access_token_format` column. After migration they are `NULL` = inherit = `:jwt` (the new server default). **No data backfill needed** — `nil` is the intended inherit state. Existing already-issued **opaque** access tokens in `lockspire_tokens` remain valid and continue to back `/userinfo` + `/introspect` (unchanged). | Migration adds nullable column (per-client) + defaulted column (server). No row rewrite. |
| Live service config | `lockspire_server_policies` is a singleton row (`@singleton_id 1`). The migration's `default: "jwt"` applies to the existing singleton on column-add (Postgres backfills the default). `[VERIFIED: server_policy_record.ex:10,47]` | Verify the existing singleton row gets `access_token_format = "jwt"` after migration (it will, via column default). |
| OS-registered state | None — pure library code. | None. |
| Secrets/env vars | None new. Signing keys (`SigningKey` / JWKS) are unchanged; the signer reuses `fetch_active_signing_key/1`. | None. |
| Build artifacts | None — no package rename, no egg-info equivalent. The library is consumed as a hex dep by host apps; host apps run the new migration on upgrade (Phase 102 owns the upgrade guide). | None in Phase 99. |

**The canonical question (post-change runtime state):** After the column is added, every existing client with `access_token_format = NULL` will, on its next token request, receive an `at+jwt` instead of an opaque token (because the server default is now `:jwt`). This is the intended FORMAT-01/MIGRATE-01 behavior. The migration guide and doctor task that make this *visible* to operators are Phase 102 — Phase 99 only makes it *true*.

## Common Pitfalls

### Pitfall 1: The five mint seams do NOT share a return shape today

**What goes wrong:** D-01/D-02 describe a "one-line swap" of `TokenFormatter.format_access_token(...)` for `AccessTokenSigner.issue(...)` returning `{:ok, raw, hash}`. But the AC/device/CIBA seam `build_access_token/6` does NOT return `{:ok, raw, hash}` — it returns `{%Token{...token_hash: hash}, raw_string}` (`token_exchange.ex:1400-1417`), building the `%Token{}` (with its `token_hash`) and the raw string together, then **persisting the `%Token{}` separately** from the raw string that flows to the response. The refresh seam computes both tokens *before* the `%Token{}` is built (`format_refresh_rotation_tokens/1`, `refresh_exchange.ex:284-289`) and stores `formatted_access_token.token_hash` into the rotated `%Token{}` (`:300`). Only the RFC 8693 path actually returns the bare `{:ok, raw, hash}` triple (`rfc8693_exchange.ex:309-310,348`).
**Why it happens:** The opaque path historically computes `{raw, hash}` together and the `%Token{}` carries the hash for persistence. A JWT's hash is `Policy.hash_token(jwt)` and the `%Token{}` must carry *that* hash, not a random one.
**How to avoid:** The signer must return `{:ok, raw, hash}` AND the call sites must thread `hash` into the persisted `%Token{}.token_hash` (currently they set it from `formatted_access_token.token_hash`). For AC/device/CIBA, this means `build_access_token/6` calls the signer, sets `%Token{token_hash: hash}`, and returns `{access_token, raw}` (keeping its 2-tuple internal contract) — so the "one-line swap" is really "swap the formatter call and re-point `token_hash` to the signer's hash." Size this as a small-but-real edit per path, not a literal one-liner.
**Warning signs:** A test where the persisted token's hash does not match `Policy.hash_token(returned_jwt)` → `/introspect` or revocation lookups fail because the stored hash ≠ hash-of-presented-token.

### Pitfall 2: Device and CIBA need net-new resource validation (not propagation)

**What goes wrong:** Treating AUD-01 as "thread the existing resource through" for all four grant paths. Device (`build_device_grant`, `token_exchange.ex:955`) and CIBA (`build_ciba_grant`, `:809`) hardcode `audience: []` and never call `validate_requested_resources/2`. There is no resource flowing through to thread.
**Why it happens:** Device/CIBA grants were built without resource-indicator support; AC/refresh got it later.
**How to avoid:** In `redeem_device_grant` (`token_exchange.ex:970`) and `redeem_ciba_grant` (`:824`), extract `resource` from `params` and validate it against the grant's authorized audience (mirror `validate_requested_resources/2` from `:661`) *before* `build_access_token`, then set `%Token{audience: validated}`. **The AUD-01 verification MUST exercise a `resource=`-scoped device flow and a `resource=`-scoped CIBA flow** — AC/refresh coverage alone does not prove device/CIBA (CONTEXT "Specific Ideas").
**Warning signs:** Device/CIBA `at+jwt` always has `aud: [client_id]` even when `resource=` was supplied → AUD-01 silently unmet for two of four paths.

### Pitfall 3: The RFC 8693 `aud` carve-out is a STRING, not a list

**What goes wrong:** Implementing D-08 as a uniform `aud = audience || [client_id]` (always a list). The shipped RFC 8693 path emits `aud => client.client_id` as a **bare string** (`rfc8693_exchange.ex:327`), and `rfc8693_exchange_test.exs:192` asserts `payload["aud"] == client.client_id` (string). A uniform list derivation turns that test red and changes shipped behavior — violating AUD-03 ("no shipped-behavior change").
**Why it happens:** RFC 9068/7519 allow `aud` as string OR array, and the codebase happens to use both forms across paths.
**How to avoid:** AC/refresh/device/CIBA emit the **list** form (`[resource]` or `[client_id]`); the RFC 8693 no-resource path keeps the **string** form (`client_id`). The signer needs to know which form to emit — recommend a per-call flag (e.g., `request` or an `issue/3` option carrying `:audience_form` or distinguishing the exchange path), or keep the exchange path's `aud` assembly in its own thin wrapper that calls the shared JOSE-sign helper with a string `aud`.
**Warning signs:** `rfc8693_exchange_test.exs:192` fails with `[client_id] != client_id`.

### Pitfall 4: DISCOVERY-01 gating does not match the actual sibling

**What goes wrong:** D-11 says publish `access_token_signing_alg_values_supported` "gated only on `token_endpoint` being mounted, like the sibling alg lists." But the actual sibling `id_token_signing_alg_values_supported` is in the **static** map block (`discovery.ex:95`) and is published **unconditionally** — it is NOT gated on `token_endpoint` mounting. The endpoint-conditional alg lists (`token_endpoint_auth_signing_alg_values_supported`, etc.) ARE gated, but those are the auth-method lists, not the id-token-signing list.
**Why it happens:** "sibling alg lists" is ambiguous — there are two families (the always-present `id_token_signing_alg_values_supported` and the conditionally-present `*_endpoint_auth_signing_alg_values_supported`).
**How to avoid:** Match the truer sibling: add `access_token_signing_alg_values_supported` as a static key alongside `id_token_signing_alg_values_supported` in the `openid_configuration/0` map (`discovery.ex:86-96`), published unconditionally. This satisfies success criterion #4 ("published truthfully because issuance can mint at+jwt on every grant path") and is the simplest correct interpretation. Flag to the planner: if a real `token_endpoint`-mounted gate is desired, it must be added deliberately (it does not exist for `id_token_signing_alg_values_supported`). `[VERIFIED: discovery.ex:86-96,154-156]`.
**Warning signs:** A discovery test expecting the key to be absent when token_endpoint is unmounted (no such test exists today — `discovery_test.exs` asserts the conditional `*_endpoint_auth_*` keys are absent, a different family).

### Pitfall 5: Refresh rotated access token has `account_id: nil` — JWT `sub` must come from the presented token

**What goes wrong:** Minting the refresh `at+jwt` with `sub` read from the rotated access `%Token{}` yields `sub: nil`, which fails the Phase 98 verifier's `:missing_sub` check (`verify_token.ex:354-358`). `build_rotated_access_token` sets `account_id: nil` (`refresh_exchange.ex:303`).
**Why it happens:** The opaque path never needed `sub`, so the rotated access token's `account_id` was never populated.
**How to avoid:** Source `sub` from `presented_refresh_token.account_id` (the presented token carries the subject). Either set `%Token{access_token | account_id: presented_refresh_token.account_id}` before calling the signer, or pass the subject explicitly. The signer derives `sub` from `%Token{}.account_id` (D-03), so the simplest fix is populating the rotated token's `account_id`.
**Warning signs:** Refresh-issued `at+jwt` rejected by the verifier as `:missing_sub`; or `sub` claim is `null`.

### Pitfall 6: `Ecto.Enum` column must pair with a `:text` DB column

**What goes wrong:** Adding an `Ecto.Enum` field without a matching `:text` column (or vice versa) — code pattern-matching on `:jwt` silently fails because the value is the string `"jwt"`. This is an explicitly-noted pitfall in the codebase (`server_policy_record.ex:23-24,30,82-84`).
**How to avoid:** Migration adds `:text` columns; record schema declares `Ecto.Enum`. Per-client: `add :access_token_format, :text` (nullable). Server: `add :access_token_format, :text, null: false, default: "jwt"` (precedent: `..._add_security_profile_to_clients_and_policies.exs`). `[VERIFIED: migration precedent file]`.

## Code Examples

### The extraction source (the canonical `at+jwt` signing block — move this into the signer)

```elixir
# Source: lib/lockspire/protocol/rfc8693_exchange.ex:317-348 (VERIFIED)
defp sign_jwt_access_token(client, subject_token, scopes, issued_at, custom_claims, request) do
  case fetch_signing_key(request) do
    {:ok, %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}} ->
      {:ok, jwk_map} = decode_private_jwk(private_jwk)
      jti = TokenFormatter.format_access_token(token_format_options(request)).token

      base_claims = %{
        "iss" => Config.issuer!(),
        "sub" => subject_token.account_id,
        "aud" => client.client_id,            # <-- STRING form (RFC 8693 carve-out, Pitfall 3)
        "exp" => DateTime.add(issued_at, 3600, :second) |> DateTime.to_unix(),
        "iat" => DateTime.to_unix(issued_at),
        "client_id" => client.client_id,
        "jti" => jti,
        "scope" => Enum.join(scopes, " ")
      }

      restricted = ~w(iss sub aud exp iat jti client_id)
      claims = Map.merge(base_claims, Map.drop(custom_claims, restricted))

      {_, compact} =
        JOSE.JWT.sign(JOSE.JWK.from_map(jwk_map),
          %{"alg" => alg, "kid" => kid, "typ" => "at+jwt"}, claims)
        |> JOSE.JWS.compact()

      {:ok, compact, Policy.hash_token(compact)}
    {:error, reason} -> # ...500 server_error...
  end
end
```

The new signer generalizes this: `sub` from `%Token{}.account_id`, `aud` from `derive_aud/2` (Pitfall 3), `scope` from `%Token{}.scopes`, plus `cnf` from `%Token{}.cnf` (Phase 100). Custom-claim merge stays only on the exchange path.

### The signing key source (reused unchanged)

```elixir
# Source: lib/lockspire/protocol/rfc8693_exchange.ex:363-399 (VERIFIED) — move with the signer
# fetch_signing_key(request) reads request.opts[:key_store] (default Config.repo!())
# and calls key_store.fetch_active_signing_key()  -> %{kid, alg, private_jwk_encrypted}
# decode_private_jwk/1 tries Jason.decode then non_executable_binary_to_term fallback.
```

### Request opts available to the signer (VERIFIED at the controller)

```elixir
# Source: lib/lockspire/web/controllers/token_controller.ex:22-31 (VERIFIED)
opts: [client_store: Repository, token_store: Repository]
      |> Keyword.put(:server_policy_store, Repository)   # <-- signer reads ServerPolicy here
      |> Keyword.put(:key_store, Repository)              # <-- signer reads signing key here
      |> Keyword.put(:secret_key_base, conn.secret_key_base)
      # ... (now is injected via Keyword.get_lazy(:now, ...) per module)
```

### Admin `<select>` + normalize idiom to mirror

```elixir
# Source: lib/lockspire/web/live/admin/clients_live/form_component.ex:95-106 (VERIFIED)
#   <select> with inherit/value options, selected={@defaults.<field> == "<value>"}
# Source: lib/lockspire/admin/clients.ex:484-489 (dpop) + :611-629 (authz alg nil-cast) (VERIFIED)
#   normalize_mutable_field(:access_token_format, v): "inherit"/nil -> nil, "jwt" -> :jwt,
#   "opaque" -> :opaque, else -> :error (HYBRID of normalize_dpop_policy + normalize_authorization_signing_alg)
# Source: form_component.ex:406-416 defaults_for(:edit) — needs nil-aware helper (nil -> "inherit"),
#   unlike dpop_policy which uses plain Atom.to_string (it's never nil). Mirror the nil-guard at :427-429.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `at+jwt` signing only on RFC 8693 exchange path; all other paths opaque | Shared `AccessTokenSigner` mints `at+jwt` by default on AC/refresh/device/CIBA | This phase (v1.27) | The library's default access-token shape flips opaque → JWT. |
| Default access-token format `:opaque` | Default `:jwt` (server-wide, runtime-editable; per-client override) | This phase | Host Phoenix API routes verify JWTs via `Lockspire.Plug.VerifyToken` (Phase 98) without per-client config. |

**Deprecated/outdated:** Nothing deprecated. Opaque remains a first-class per-client opt-in and the only shape for `/userinfo` + `/introspect`. RFC 9068 (`at+jwt`) is current and is the canon-endorsed access-token-as-JWT profile.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `request.opts[:server_policy_store]` (= `Repository`) is the cleanest way for the signer to read `ServerPolicy`; passing it pre-resolved would force more than one line at call sites. | Standard Stack / Architecture | If the team prefers pre-resolving format outside the signer, D-05's "one place" still holds but the signer signature changes. Low risk — both satisfy D-05. |
| A2 | DISCOVERY-01 should be published unconditionally (matching `id_token_signing_alg_values_supported`), not gated on `token_endpoint`. | Pitfall 4 | If a real mount-gate is wanted, planner adds it deliberately; success criterion #4 says "published truthfully," which unconditional satisfies. Flagged, not assumed-silent. |
| A3 | The RFC 8693 path keeps a **string** `aud`; the other four emit a **list**. | Pitfall 3, AUD-03 | Verified against `rfc8693_exchange_test.exs:192`; if the team chooses to update that test to expect a list, the carve-out can collapse — but AUD-03 says "no shipped-behavior change," so the conservative reading (keep string) is correct. |
| A4 | `Policy.hash_token/1` and `TokenFormatter.hash_token/1` are interchangeable (identical SHA-256 hex). | Standard Stack | Verified identical implementations; if one diverges later, the signer should standardize on one. Very low risk. |
| A5 | Server-wide `access_token_format` editing surface is undecided (see Open Question 1); the `Admin.ServerPolicy.put_*` context pattern exists but no `policies_live` page is specified. | FORMAT-01 / Open Questions | If FORMAT-01 requires an *admin page* (not just a context function), that's net-new UI not covered by the UI-SPEC. **Needs user confirmation.** |

## Open Questions

1. **Where is the server-wide `access_token_format` *edited*?**
   - What we know: D-04 puts the value on `ServerPolicy` (runtime-editable); `Admin.ServerPolicy` has a clean `put_*` context pattern (`put_dpop_policy/1`, `put_security_profile/1`, `server_policy.ex:55-83`); there is an existing `policies_live/` admin area (`dpop.ex`, `security_profile.ex`, `dcr`) where server-wide policies are toggled. The UI-SPEC scopes the *frontend* surface to ONLY the per-client override on client-detail.
   - What's unclear: FORMAT-01 says operators "can set this to `:opaque`" (runtime-editable) — does Phase 99 ship an admin `policies_live` page for the server-wide toggle, or only the `Admin.ServerPolicy.put_access_token_format/1` context function (with the page deferred)? The UI-SPEC does not mention a server-wide page; the per-client UI is the only specified surface.
   - Recommendation: Ship the `put_access_token_format/1` context function (needed regardless, and by `Repository.update_server_policy`) so the value IS runtime-settable. Decide with the user whether a `policies_live` page is in Phase 99 scope or deferred to Phase 102 (which already owns operator-facing tooling). The default server value is `:jwt`, so a fresh deploy needs no edit to satisfy success criterion #1; the edit surface only matters for opting *out*. **Suggest: ship the context function in Phase 99, defer the dedicated admin page unless the user wants it now.**

2. **Does the signer emit `aud` form-switching via the request, or via two entry points?**
   - What we know: The carve-out (Pitfall 3) requires string `aud` for RFC 8693 no-resource, list `aud` elsewhere.
   - What's unclear: cleanest mechanism — a `request`-carried flag, an `issue/3` option, or a thin exchange-specific wrapper around a shared JOSE-sign core.
   - Recommendation: Claude's discretion per D-01's "whether helpers move wholesale or into a shared helper." A shared `sign/4` core (jwk, header, claims) + two thin callers (one assembling list `aud`, one assembling string `aud`) keeps JOSE-sign logic single-sourced (satisfies success criterion #5) while honoring the carve-out. Planner picks.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `jose` | `at+jwt` signing | ✓ | 1.11.12 | — (no fallback needed; already in use) |
| `jason` | JWK decode | ✓ | 1.4.x | — |
| `ecto_sql` + Postgres | Migrations + Ecto.Enum | ✓ | 3.13.5 / PG 14+ | — |
| `phoenix_live_view` | Admin override `<select>` | ✓ | 1.1.28 | — |
| Active signing key (RS256/ES256/PS256) in `lockspire_signing_keys` | JWT minting at runtime | ✓ (sourced via `fetch_active_signing_key/1`) | n/a | If no active key, the signer returns the existing 500 `:token_signing_failed` (`rfc8693_exchange.ex:350-359`) — preserve this error path. |

**Missing dependencies with no fallback:** None. **Missing with fallback:** None. All issuance infrastructure already exists and is in production use for the RFC 8693 path.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir 1.18) |
| Config file | `test/test_helper.exs`; aliases in `mix.exs` (`test.setup`, `test.fast`) |
| Quick run command | `mix test test/lockspire/protocol/<file>.exs:<line>` |
| Full suite command | `mix test.setup && mix test` (or `mix test.fast`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SIGNER-01 | Shared signer mints `at+jwt`; no duplicate signing logic | unit | `mix test test/lockspire/protocol/access_token_signer_test.exs` | ❌ Wave 0 (new) |
| SIGNER-01 | RFC 8693 path routes through shared signer; custom claims preserved | unit | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs` | ✅ (extend) |
| SIGNER-02 | `:opaque` policy → opaque token via `TokenFormatter`; format decided in one place | unit | `mix test test/lockspire/protocol/access_token_signer_test.exs` | ❌ Wave 0 |
| FORMAT-01 | Server-wide default `:jwt`; settable to `:opaque` (context fn) | unit | `mix test test/lockspire/admin/server_policy_test.exs` | ✅ (extend — verify exists) |
| FORMAT-01 | Fresh-deploy AC path mints `at+jwt` with no client config | integration | `mix test test/lockspire/protocol/token_exchange_test.exs` | ✅ (extend) |
| FORMAT-02 | Per-client override read/write; nullable; admin-mutable via `update_changeset` | unit | `mix test test/lockspire/storage/ecto/` + `test/lockspire/admin/clients_test.exs` | ✅ (extend) |
| FORMAT-02 | Admin client-detail `<select>` + show rows render and persist | LiveView | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs` | ✅ (extend) |
| AUD-01 | `resource=` → `aud=[resource]` on **AC** | unit | `mix test test/lockspire/protocol/token_exchange_test.exs` | ✅ (extend) |
| AUD-01 | `resource=` → `aud=[resource]` on **refresh** | unit | `mix test test/lockspire/protocol/refresh_exchange_test.exs` | ✅ (extend) |
| AUD-01 | `resource=` → `aud=[resource]` on **device** (net-new threading) | integration | `mix test test/lockspire/protocol/device_authorization_test.exs` | ✅ (extend) |
| AUD-01 | `resource=` → `aud=[resource]` on **CIBA** (net-new threading) | integration | `mix test test/lockspire/protocol/token_exchange_test.exs` (CIBA grant) | ✅ (extend) |
| AUD-02 | `resource=` absent → `aud=[client_id]` (list) on AC/refresh/device/CIBA | unit | path-specific test files above | ✅ (extend) |
| AUD-03 | `resource=` absent on RFC 8693 → `aud=client_id` (**string**, unchanged) | unit | `mix test test/lockspire/protocol/rfc8693_exchange_test.exs:192` | ✅ (must stay green) |
| DISCOVERY-01 | `access_token_signing_alg_values_supported == ["RS256","ES256","PS256"]` | unit | `mix test test/lockspire/protocol/discovery_test.exs` | ✅ (extend) |
| Phase 98 contract | Signer output passes `validate_rfc9068_compliance` (typ/iss/exp/iat/sub) | unit | `mix test test/lockspire/plug/verify_token_test.exs` (round-trip) | ✅ (verify integration) |

### Sampling Rate

- **Per task commit:** the path-specific quick run (e.g., `mix test test/lockspire/protocol/access_token_signer_test.exs`).
- **Per wave merge:** `mix test test/lockspire/protocol/ test/lockspire/admin/ test/lockspire/web/live/admin/clients_live/`.
- **Phase gate:** `mix test.setup && mix test` fully green before `/gsd:verify-work`. **`rfc8693_exchange_test.exs:192` and all Phase 98 verifier tests are regression sentinels — they MUST stay green** (AUD-03 + verifier contract).

### Wave 0 Gaps

- [ ] `test/lockspire/protocol/access_token_signer_test.exs` — new; covers SIGNER-01/02, format resolution (per-client/server/default precedence), `aud` derivation (list vs string carve-out), `cnf` carry-through, missing-key 500 path.
- [ ] Confirm `test/lockspire/admin/server_policy_test.exs` exists; if not, add coverage for `put_access_token_format/1` (FORMAT-01).
- [ ] Device + CIBA `resource=`-scoped fixtures (Pitfall 2 — AUD-01 must exercise these explicitly).
- [ ] No framework install needed — ExUnit is present and all sibling test files exist.

## Security Domain

> `security_enforcement` is absent in `.planning/config.json` (= enabled). Included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 99 issues tokens for already-authenticated grants; auth happens upstream. |
| V3 Session Management | no | Token lifecycle unchanged; no session changes. |
| V6 Cryptography (token signing) | yes | JOSE `JOSE.JWT.sign/3` with active key alg (RS256/ES256/PS256). **Never hand-roll JWS.** No `alg=none` (AGENTS.md security default). Header pins `alg`+`kid` from the active key. |
| V7 Error Handling & Logging | yes | Signing failure → existing 500 `:token_signing_failed` with `Logger.error` (no key material logged). Preserve redaction. |
| V8/V9 Data Protection / Communications | yes | Private JWK stored encrypted (`private_jwk_encrypted`); decoded only in-memory via `decode_private_jwk/1`. Do not log decoded JWK. |
| V13 API & Web Service (audience) | yes | `aud` claim correctness is the cross-API-reuse defense (RFC 8707). AUD-01..03 ARE the V13 control: `resource`→`aud` binds the token to its intended resource. |

### Known Threat Patterns for Elixir/Phoenix OAuth issuance

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `alg=none` / alg confusion in minted JWT | Spoofing / Tampering | Header `alg` taken from the active signing key only; JOSE pins it; no client-controlled alg. Verifier (Phase 98) uses `verify_strict` with `@allowed_algs`. `[VERIFIED: verify_token.ex:584]` |
| Cross-API token reuse (wrong `aud`) | Elevation of Privilege | Correct `resource`→`aud` derivation (AUD-01..03); `Lockspire.Plug.VerifyToken` enforces audience (VERIFIER-06, Phase 98). Device/CIBA gap (Pitfall 2) is a real reuse risk if left unaddressed. |
| `typ` confusion (JWT vs at+jwt) | Spoofing | Signer sets `typ: "at+jwt"`; verifier rejects non-`at+jwt` (`:invalid_typ`, `verify_token.ex:312-319`). Signer MUST keep exact `at+jwt`. |
| Missing `sub`/`exp`/`iat` (refresh `account_id: nil`) | Repudiation / Tampering | Source `sub` from presented token (Pitfall 5); `exp = iat + 3600`, `iat` always set. Verifier enforces all three. |
| Stored-hash / presented-token mismatch (Pitfall 1) | Tampering / DoS on revocation | Persist `Policy.hash_token(jwt)` as `%Token{}.token_hash` so introspection/revocation by hash works. |
| Sender-constraint downgrade (`cnf` dropped) | Spoofing | Signer copies `%Token{}.cnf` into the JWT so Phase 100 can verify DPoP/mTLS binding end-to-end. Dropping `cnf` would silently unbind the token. |

## Sources

### Primary (HIGH confidence — live codebase, verified at cited lines)
- `lib/lockspire/protocol/rfc8693_exchange.ex:299-399` — extraction source (`sign_or_format_access_token`, `sign_jwt_access_token`, `fetch_signing_key`, `decode_private_jwk`)
- `lib/lockspire/protocol/token_exchange.ex:661-689,691-748,799-822,824-1027,1029-1056,1387-1418,1815-1824` — AC/device/CIBA seams, `validate_requested_resources`, `build_access_token`, `audience: []` hardcodes, success-response, `token_format_options`
- `lib/lockspire/protocol/refresh_exchange.ex:18-39,58-139,155-181,284-310` — refresh flow, resource threading, `build_rotated_access_token` (`account_id: nil`)
- `lib/lockspire/protocol/security_profile.ex:1-65` — precedence template + `allowed_signing_algorithms` (why D-11 avoids it)
- `lib/lockspire/protocol/discovery.ex:78-108,154-163` — `openid_configuration/0`, sibling alg list, `get_server_policy` usage
- `lib/lockspire/protocol/token_formatter.ex:1-52` — opaque path + `hash_token`
- `lib/lockspire/domain/token.ex`, `lib/lockspire/domain/client.ex:21-22,46-50,108-112`, `lib/lockspire/domain/server_policy.ex` — domain structs
- `lib/lockspire/storage/ecto/client_record.ex:16-93,104-162,198-234,263-290`, `server_policy_record.ex:13-104` — record plumbing + Ecto.Enum precedents
- `lib/lockspire/admin/clients.ex:14-33,460-524,558-631`, `lib/lockspire/admin/server_policy.ex:40-83` — mutable fields, normalizers, `put_*` pattern
- `lib/lockspire/web/live/admin/clients_live/form_component.ex:85-216,395-431`, `show.ex:1-110,160-219,560-599` — admin UI idioms + effective resolution
- `lib/lockspire/web/controllers/token_controller.ex:14-32` — `request.opts` assembly (`server_policy_store`, `key_store`, `now`)
- `lib/lockspire/plug/verify_token.ex:307-358,584-730` — Phase 98 compliance contract the signer must satisfy
- `test/lockspire/protocol/rfc8693_exchange_test.exs:180-193` — `aud == client.client_id` (string) regression sentinel
- `test/lockspire/protocol/discovery_test.exs:120-200` — discovery alg-list assertion shapes
- `priv/repo/migrations/20260430151849_add_security_profile_to_clients_and_policies.exs`, `20260525143000_add_token_endpoint_auth_signing_alg_to_lockspire_clients.exs` — migration precedents
- `mix.exs`, `mix.lock` — dependency versions (jose 1.11.12)
- `.planning/config.json` — `nyquist_validation: true`, `commit_docs: true`
- `AGENTS.md` — project security defaults (no `alg=none`, redaction)

### Secondary (MEDIUM confidence)
- RFC 9068 §2.1/§2.2/§3 (`at+jwt` typ header, required claims, `aud` as string-or-array) — corroborates the carve-out legality and Phase 98 contract. `[CITED: training knowledge of RFC 9068]`
- RFC 8707 (`resource`→`aud`) — corroborates AUD-01..03 derivation. `[CITED: training knowledge of RFC 8707]`

### Tertiary (LOW confidence)
- None — every actionable claim is grounded in the live codebase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all libs verified in `mix.lock` and already used for this exact purpose.
- Architecture / extraction boundary: HIGH — every line number in CONTEXT.md (D-01..D-11) verified true; discrepancies (return-shape, aud carve-out, refresh sub, discovery gating) found by reading the actual code and tests.
- Pitfalls: HIGH — each pitfall is anchored to a specific line and, where applicable, an existing test that would break.
- Open Questions: MEDIUM — Open Question 1 (server-wide edit surface) is a genuine scope ambiguity between FORMAT-01 and the UI-SPEC; flagged for user confirmation.

**Research date:** 2026-05-28
**Valid until:** 2026-06-27 (stable internal codebase; re-verify line numbers if `token_exchange.ex` / `rfc8693_exchange.ex` change before planning).
