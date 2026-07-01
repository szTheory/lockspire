# Phase 99: Signer Extraction + JWT-Default Issuance - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

One shared `Lockspire.Protocol.AccessTokenSigner` owns RFC 9068 `at+jwt` issuance across the authorization-code (AC), refresh, device, CIBA, and RFC 8693 token-exchange paths; the server-wide default access-token format flips from opaque to `:jwt`; per-client overrides and `resource`→`aud` audience semantics are coherent, durable, and discoverable. This is the issuance half that Phase 97's D-07 forward-reference caveat promised and Phase 98's hardened verifier already accepts.

In scope: extract the `at+jwt` signing block from `rfc8693_exchange.ex:317-361` into `Protocol.AccessTokenSigner` and route all five issuance paths through it (SIGNER-01); resolve the format-policy decision (per-client override → server default → `:jwt`) in exactly one place inside the signer (SIGNER-02); add a runtime-editable server-wide `access_token_format` default `:jwt` on the `ServerPolicy` record (FORMAT-01); add a nullable per-client `access_token_format` override with full record/changeset/domain plumbing plus an admin client-detail select + doclink (FORMAT-02); derive `aud` from `%Token{}.audience` — `[resource]` when present, `[client_id]` when absent — including **net-new** `resource` threading for the device and CIBA grant paths (AUD-01/02), preserving `aud = client_id` on the RFC 8693 path with no resource (AUD-03); publish `access_token_signing_alg_values_supported: ["RS256","ES256","PS256"]` unconditionally in discovery (DISCOVERY-01).

Out of scope (lands later in v1.27): DPoP-bound and mTLS-bound `at+jwt` end-to-end pipeline proof (Phase 100, BIND-01..03); adoption-demo smoke proving `200` with an issued `at+jwt` (Phase 101, DEMO-01..03); install-template uncomment, `[:lockspire, :rs, :token_format]` telemetry, `docs/upgrading/v1.27.md` migration guide, and `mix lockspire.doctor token_format` task (Phase 102, SCAFFOLD/TELEMETRY/MIGRATE). Phase 99 does NOT change the verifier (`verify_token.ex`, shipped in Phase 98), `/userinfo`, or `/introspect` — opaque tokens continue to back the Lockspire-owned RS endpoints.
</domain>

<decisions>
## Implementation Decisions

### AccessTokenSigner module shape and call-site contract (SIGNER-01)

- **D-01:** Create `Lockspire.Protocol.AccessTokenSigner` with a single public function that accepts the already-built `%Lockspire.Domain.Token{}` struct plus the issuance `request` (carrying `key_store`, `now`, and `token_format_options`) and the `client`, and returns the existing `{:ok, raw_token, token_hash}` triple — the exact shape `rfc8693_exchange.ex:317-348` returns today and that `build_access_token/6` (`token_exchange.ex:1387-1418`) and `refresh_exchange.ex:284-310` already destructure. The signer owns BOTH branches internally: `:jwt` (JOSE sign, including `fetch_signing_key/1` + `decode_private_jwk/1` extracted from `rfc8693_exchange.ex`) and `:opaque` (delegate to `TokenFormatter.format_access_token/1`).
- **D-02:** Each of the five issuance paths feeds the signer the canonical `%Token{}` it already constructs and changes its mint site to ONE line — swapping `TokenFormatter.format_access_token(...)` for `AccessTokenSigner.issue(token, client, request)` at `token_exchange.ex:~1397` and `refresh_exchange.ex:~286`, and replacing the RFC 8693 path's inline `sign_jwt_access_token/6` body with a call into the shared module. After this phase no `at+jwt` signing logic (JOSE sign, claim assembly) remains outside `AccessTokenSigner` — satisfies ROADMAP success criterion #5.
- **D-03:** The signer's emitted token must pass the Phase 98 verifier unchanged: it MUST set the `typ: "at+jwt"` header and the `iss`/`sub`/`exp`/`iat`/`aud`/`client_id`/`jti`/`scope` claims exactly as the current `rfc8693_exchange.ex:317-348` base_claims map does (`iss = Config.issuer!()`, `exp = iat + 3600`, `jti` from `TokenFormatter`). Custom-claim merge with the restricted-claim drop (`~w(iss sub aud exp iat jti client_id)`) is preserved for the RFC 8693 path.

### Format-policy resolution: home and precedence (FORMAT-01, SIGNER-02)

- **D-04:** The server-wide `access_token_format` setting (default `:jwt`) lives as a new `Ecto.Enum` column on the runtime-editable `ServerPolicy` record (`domain/server_policy.ex`, `storage/ecto/server_policy_record.ex:14-25`), alongside `dpop_policy`/`security_profile`/`registration_policy` — NOT in boot-time `Config` (`config.ex`). Reachable via the existing `Repository.get_server_policy()` (already called at `discovery.ex:159`). Rationale: operators must flip it at runtime, the admin UI must show global+override+effective coherently, and Phase 102's doctor task needs a runtime row to read. `Config` stays reserved for deploy-time keys (issuer, mount_path, signing_alg).
- **D-05:** The format decision is resolved in exactly ONE place — inside `AccessTokenSigner` — using the existing `SecurityProfile.resolve_effective_profile/2` precedence pattern (`security_profile.ex:29-60`) as the template: per-client `access_token_format` (`:jwt | :opaque | nil`) takes precedence; `nil` inherits the server-wide `ServerPolicy.access_token_format`, which defaults `:jwt`. Per-client always wins over server default (FORMAT-02's "independently of the server default").

### Per-client override: field, migration, plumbing, admin surface (FORMAT-02)

- **D-06:** Add `access_token_format` as a **nullable** `Ecto.Enum` with values `[:jwt, :opaque]` and **no DB default** (so `nil` = inherit) on `storage/ecto/client_record.ex`. Thread it through `changeset/2` cast (`client_record.ex:106-162`), `update_changeset/2` cast (`client_record.ex:200-234`, the admin-mutable path — MUST be in both), `to_domain/1` mapping (`client_record.ex:263+`), and add it to the `Domain.Client` struct (`domain/client.ex`). Precedent to mirror exactly: `id_token_signed_response_alg` (the existing nullable per-client enum at `client_record.ex:57,129,218,288` / `domain/client.ex:50`).
- **D-07:** The admin client-detail UI adds an `inherit | jwt | opaque` `<select>` mirroring the `dpop_policy` override control (`web/live/admin/clients_live/form_component.ex:95-105`), with the `inherit` option mapping to a `nil` cast, plus a `defaults_for/2` clause, a `normalize_mutable_field/2` clause in `admin/clients.ex:472-484`, and a display row in `show.ex` alongside the existing global/override/effective rows (`show.ex:169-171`). The doclink points to `docs/protect-phoenix-api-routes.md` (Phase 97 D-06 canonical contract page) explaining the JWT-vs-opaque tradeoff.

### Audience semantics and the device/CIBA resource gap (AUD-01, AUD-02, AUD-03)

- **D-08:** The signer derives `aud` from the `%Token{}`'s `audience` field: when non-empty, `aud = audience` (which equals `[resource]` after `validate_requested_resources`); when empty, `aud = [client_id]`. This keeps `aud` derivation in one place and matches the existing `aud => client.client_id` default at `rfc8693_exchange.ex:327`.
- **D-09:** **AC and refresh already thread `resource` into `%Token{}.audience`** (`token_exchange.ex:661-689,705`; `refresh_exchange.ex:155-178,306`) — AUD-01/02 for those two paths is satisfied by D-08 with no new threading. **Device and CIBA do NOT** — they hardcode `audience: []` on the grant (`token_exchange.ex:809,955`) and never call `validate_requested_resources`. So AUD-01 for device/CIBA requires **net-new wiring**: extract `resource` from `params` and validate it against the grant's authorized audience inside `redeem_device_grant`/`redeem_ciba_grant` (`token_exchange.ex:970-988,824-842`) before `build_access_token`. Treat this as real implementation work, not propagation.
- **D-10:** The RFC 8693 token-exchange path keeps `aud = client.client_id` when no `resource` is supplied (AUD-03, no shipped-behavior change — matches `rfc8693_exchange.ex:327`). When `resource` IS supplied on the exchange path, existing behavior is preserved as-is; Phase 99 does not alter the exchange path's resource handling beyond routing it through the shared signer.

### Discovery advertisement (DISCOVERY-01)

- **D-11:** Add `access_token_signing_alg_values_supported` to `discovery.ex` `openid_configuration/0` (static block ~`discovery.ex:86-96`) as the literal list `["RS256", "ES256", "PS256"]`, published **unconditionally** (gated only on `token_endpoint` being mounted, like the sibling alg lists). Do NOT reuse `SecurityProfile.allowed_signing_algorithms/1` — it returns `EdDSA` for `:none` (`security_profile.ex:64`) and only `["ES256","PS256"]` under FAPI, neither matching the required truthful triple. Publishing always is truthful because Phase 99 makes every grant path able to mint `at+jwt` by default (ROADMAP success criterion #4).

### Claude's Discretion

- Exact public function name/arity of `AccessTokenSigner` (`issue/3` suggested), provided it takes `%Token{}` + `client` + `request` and returns `{:ok, raw, hash}` per D-01.
- Whether `fetch_signing_key/1` and `decode_private_jwk/1` move wholesale into `AccessTokenSigner` or into a shared helper both modules call, provided no JOSE-signing logic remains duplicated (D-02).
- Exact migration filename/structure for the nullable `access_token_format` column, provided it is nullable with no DB default (D-06).
- Exact admin select label copy and doclink anchor text, provided the `inherit/jwt/opaque` options and the `docs/protect-phoenix-api-routes.md` target are preserved (D-07).
- Internal naming of the format-resolution helper inside `AccessTokenSigner`, provided the precedence is per-client → server-default → `:jwt` (D-05).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and prior decisions
- `.planning/PROJECT.md` — v1.27 milestone goal; Branch A + JWT-default issuance Key Decision (lines ~225-227); standing sustainment-default policy
- `.planning/REQUIREMENTS.md` — SIGNER-01/02, FORMAT-01/02, AUD-01/02/03, DISCOVERY-01 verbatim; traceability (Phase 99 = 8 reqs); Out-of-Scope rationale
- `.planning/ROADMAP.md` — Phase 99 goal, five success criteria, build-order rationale (Phase 98 precedes 99 so the verifier accepts what the new signer produces)
- `.planning/STATE.md` — milestone position, decisions log, session continuity
- `.planning/METHODOLOGY.md` — assumption-first decisive defaults, least-surprise host seam, one-shot recommendation bundle, high-threshold escalation
- `.planning/phases/97-contract-docs-first/97-CONTEXT.md` — D-06 contract sentence (Lockspire issues `at+jwt` by default; the page Phase 99's admin doclink targets); D-07 forward-reference caveat whose issuance half Phase 99 closes
- `.planning/phases/98-plug-hardening/98-CONTEXT.md` — D-02/D-03 `validate_rfc9068_compliance` claim/header contract the Phase 99 signer MUST satisfy (`typ: at+jwt`, `iss`, `exp`, `iat`, `sub`); intentional verifier/signer asymmetry margin (verifier accepts `application/at+jwt` + case variants)

### Signer extraction source and issuance seams
- `lib/lockspire/protocol/rfc8693_exchange.ex` — lines 317-361: `sign_jwt_access_token/6` (the only `at+jwt` signing site today; base_claims shape), `fetch_signing_key/1`, `decode_private_jwk/1`. Extraction source for SIGNER-01.
- `lib/lockspire/protocol/token_exchange.ex` — `build_access_token/6` (1387-1418, shared AC/device/CIBA mint seam); call sites `redeem_code` (~702), `redeem_ciba_grant` (~834), `redeem_device_grant` (~980); response assembly `build_success_response/8` (1029-1056, `access_token: raw_access_token`); device/CIBA `audience: []` hardcodes at 809/955 (the AUD-01 gap)
- `lib/lockspire/protocol/refresh_exchange.ex` — lines 284-310 (`build_rotated_access_token/6` mint seam); 155-178 (resource→audience threading)
- `lib/lockspire/protocol/token_formatter.ex` — `format_access_token/1` (32-byte opaque path the signer delegates to for `:opaque`; also source of `jti`)

### Format-policy home and precedence template
- `lib/lockspire/protocol/security_profile.ex` — lines 29-60: `resolve_effective_profile/2` (per-client → global → default precedence template for D-05); `allowed_signing_algorithms/1` at 62-64 (why D-11 does NOT reuse it)
- `lib/lockspire/domain/server_policy.ex` — server-policy domain struct (home for server-wide `access_token_format`, D-04)
- `lib/lockspire/storage/ecto/server_policy_record.ex` — lines 14-25: existing runtime policies as `Ecto.Enum` with defaults (the pattern D-04 extends); `Repository.get_server_policy()` already called at `discovery.ex:159`

### Per-client field precedent and plumbing
- `lib/lockspire/storage/ecto/client_record.ex` — lines 57, 129, 218, 263+: `id_token_signed_response_alg` (exact nullable-per-client-enum precedent for D-06); `changeset/2` (106-162), `update_changeset/2` (200-234, admin-mutable), `to_domain/1` (263+)
- `lib/lockspire/domain/client.ex` — line ~50: `id_token_signed_response_alg` in the struct (mirror for the new field); plain struct, not Ecto

### Admin client-detail UI (FORMAT-02)
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — lines 95-199, 409-426: `dpop_policy`/`par_policy`/`security_profile` override `<select>` + `defaults_for/2` pattern D-07 mirrors
- `lib/lockspire/web/live/admin/clients_live/show.ex` — lines 169-171: global/override/effective display rows
- `lib/lockspire/admin/clients.ex` — lines 472-484: `normalize_mutable_field/2` (where the `inherit`→`nil` mapping lands)

### Discovery
- `lib/lockspire/protocol/discovery.ex` — lines 86-96 (static metadata block where DISCOVERY-01 key slots in), 95/154-156 (`id_token_signing_alg_values_supported` sibling precedent), 159 (`get_server_policy()` call)

### Standards
- RFC 9068 (`at+jwt` claim/header shape — already implemented at `rfc8693_exchange.ex:317-348`)
- RFC 8707 (`resource` → `aud` — already implemented via `validate_requested_resources/2`)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `{:ok, raw, hash}` return triple is already the universal contract across `rfc8693_exchange.ex` (signed) and `TokenFormatter` (opaque) consumers — `AccessTokenSigner` slots into it with one-line call-site swaps rather than a new return shape.
- `SecurityProfile.resolve_effective_profile/2` (`security_profile.ex:29-60`) is the canonical per-client-override → server-default → hardcoded-default resolver; FORMAT/SIGNER policy precedence reuses this pattern verbatim instead of inventing one.
- `ServerPolicy` already stores `dpop_policy`/`security_profile`/`registration_policy` as runtime-editable `Ecto.Enum`s with defaults (`server_policy_record.ex:14-25`) — the server-wide `access_token_format` is one more column in the same shape.
- `id_token_signed_response_alg` is a complete worked example of a nullable per-client enum threaded record→changeset(s)→domain→admin-UI — D-06/D-07 follow it field-for-field.
- The admin override controls (`form_component.ex:95-199`) already implement the `inherit/<value>` select + `defaults_for/2` + `normalize_mutable_field/2` + global/override/effective display idiom.

### Established Patterns
- One canonical resolution point per concern: the format decision resolves inside the signer (D-05), mirroring how Phase 98 kept opaque-rejection to one structural check and challenge-derivation to one binding-claim read.
- `Lockspire.Config.issuer!/0` is the canonical issuer accessor (call-site precedent at `discovery.ex:67`, `introspection_controller.ex:68`); the extracted signer keeps calling it for `iss`.
- Discovery publishes alg-support lists as fixed/derived values gated on the relevant endpoint being mounted; DISCOVERY-01's fixed triple follows the `id_token_signing_alg_values_supported` slot.

### Integration Points
- Phase 98's shipped verifier (`verify_token.ex`, `validate_rfc9068_compliance/2`) is the contract the Phase 99 signer must satisfy — `typ: at+jwt` header + `iss`/`exp`/`iat`/`sub`. The verifier's deliberate acceptance of `application/at+jwt` and case variants (Phase 98 D-03) gives the signer formatting latitude but Phase 99 should keep emitting exact `at+jwt` unless there's a conformance reason to change.
- Phase 100's DPoP/mTLS-bound end-to-end proof depends on the Phase 99 signer correctly carrying `cnf.jkt` / `cnf["x5t#S256"]` from the `%Token{}` into the minted `at+jwt` — the signer must propagate the token's `cnf` claim, not just iss/sub/aud.
- Phase 102's `mix lockspire.doctor token_format` task and migration guide depend on D-06's nullable-`nil`-inherit semantics to identify which clients inherit the new `:jwt` default.
- Phase 101's adoption-demo `200-with-issued-token` proof depends on the AC path actually minting `at+jwt` by default after this phase.
</code_context>

<specifics>
## Specific Ideas

- Preferred Phase 99 feel: **one signer, one format decision, one audience derivation** — extraction collapses duplication rather than spreading new branches across five paths.
- The device/CIBA `resource`-threading gap (D-09) is the one place the requirement's phrasing understates the work: AC/refresh propagate `resource` today, device/CIBA need net-new validation+threading. Planner should size this as real implementation, and the AUD-01 verification must explicitly exercise a `resource=`-scoped device flow and a `resource=`-scoped CIBA flow, not just AC/refresh.
- Server-wide setting belongs on `ServerPolicy` (runtime, admin-visible, doctor-readable), not `Config` (deploy-time) — this is the least-surprise host-seam choice and the one that makes Phase 102's operator tooling possible.
- Discovery publishes the fixed truthful triple `["RS256","ES256","PS256"]`, not a profile-derived list — truthfulness over cleverness (ROADMAP success criterion #4).
- Signer must carry the token's `cnf` claim through to the JWT so Phase 100's sender-constraint proof has a bound `at+jwt` to verify end-to-end.

## Methodology Lenses Applied
- **Assumption-first decisive defaults / one-shot bundle:** all five areas resolved decisively from real call sites; only DISCOVERY-01's gating flagged as a one-line product choice (recommended unconditional).
- **Least-surprise host seam:** server-wide format on durable `ServerPolicy` rather than ambient `Config`; per-client override visible in admin with a tradeoff doclink.
- **High-threshold escalation:** the device/CIBA audience gap is behavior-shaping but codebase-grounded, so it's a locked decision (D-09), not an escalation.
</specifics>

<deferred>
## Deferred Ideas

- DPoP/mTLS-bound `at+jwt` end-to-end pipeline proof — Phase 100 (BIND-01..03). Phase 99 only ensures the signer carries `cnf`; it does not add enforcer code or end-to-end tests.
- `[:lockspire, :rs, :token_format]` telemetry, `docs/upgrading/v1.27.md` migration guide, `mix lockspire.doctor token_format` task, install-template canonical-block uncomment (SCAFFOLD-01) — Phase 102.
- Adoption-demo `200-with-issued-token` smoke proof and demo router `audience:` reconciliation — Phase 101 (DEMO-01..03).
- Accepting `at+jwt` at `/userinfo` (one-token-everywhere, UNIFIED-01) — explicitly deferred in REQUIREMENTS.md Future Requirements; today's JWT-for-host-APIs / opaque-for-Lockspire-resources split is the canonically endorsed phantom-token pattern and Phase 99 preserves it.
- Emitting `application/at+jwt` (stricter `typ`) on the signer side — the Phase 98 verifier already accepts it, but Phase 99 keeps exact `at+jwt` absent a conformance reason; revisit only if a certification profile requires it.
</deferred>

---

*Phase: 99-signer-extraction-jwt-default-issuance*
*Context gathered: 2026-05-28*
