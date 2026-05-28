---
phase: 99
slug: signer-extraction-jwt-default-issuance
status: verified
threats_open: 0
asvs_level: 2
created: 2026-05-28
---

# Phase 99 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Audit disposition: every declared mitigation was verified present in implemented
code (grep for the concrete call/pattern in the cited file, plus the cited test
assertion). Documentation and intent were not accepted as evidence. The threat
register authored at plan time is authoritative; no fresh STRIDE scan was performed.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Client → token endpoint | OAuth grant paths (AC / refresh / device / CIBA / RFC 8693) request access tokens | grant params incl. `resource`, `subject_token`, `custom_claims` |
| Token signer → relying party | `AccessTokenSigner` mints RFC 9068 `at+jwt` or opaque tokens | signed JWT claims (`iss/sub/aud/exp/iat/jti/client_id/scope/cnf`) |
| Operator (admin LiveView) → durable config | Per-client `access_token_format` override + server-wide default | enum value `jwt`/`opaque`/inherit(nil) |
| Issuer → discovery consumer | `/.well-known/openid-configuration` advertises signing algs | `access_token_signing_alg_values_supported` literal |
| Signing key store → signer | Active signing key fetch (alg/kid/private JWK) | private key material (never logged) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation (verified evidence) | Status |
|-----------|----------|-----------|-------------|--------------------------------|--------|
| T-99-01 | Tampering | server_policy admin/domain/record | mitigate | `put_access_token_format/1` → `normalize_access_token_format/1` maps only `:jwt`/`:opaque` (+strings), else `{:error, :invalid_access_token_format}` (admin/server_policy.ex:67,241-258); `ServerPolicyRecord` `Ecto.Enum values: [:jwt, :opaque]` + `validate_required` rejects out-of-set at cast (server_policy_record.ex:25,80) | closed |
| T-99-02 | Elevation of Privilege | default token format | **accept** | Default-flip to `:jwt` blast radius accepted — existing opaque tokens stay valid; migration only adds columns; per-client `:opaque` opt-in remains. Documented in Accepted Risks Log (RISK-99-02). | closed |
| T-99-03 | Tampering | migration + record schemas | mitigate | Migration adds `:text` columns to both tables (migration 20260528150000:9,16) paired with `Ecto.Enum` fields so `:jwt` persists/loads as `"jwt"` (server_policy_record.ex:25, client_record.ex:62) | closed |
| T-99-04 | Information Disclosure | discovery | mitigate | `@access_token_signing_alg_values_supported ["RS256","ES256","PS256"]` literal advertised (discovery.ex:40,102); test asserts triple + profile-independence (discovery_test.exs:518,534-535) | closed |
| T-99-05 | Spoofing | discovery | mitigate | Same literal deliberately excludes `none`/`EdDSA` (not derived from `SecurityProfile.allowed_signing_algorithms/1`); test contrasts with id_token list which DOES carry none/EdDSA (discovery.ex:40; discovery_test.exs:514-554) | closed |
| T-99-06 | Spoofing/Tampering | access_token_signer | mitigate | JWT header `alg`/`kid` taken only from `fetch_signing_key/1`; `typ: "at+jwt"` hardcoded; no client-controlled alg; `none` never emitted (access_token_signer.ex:166-176,196-216) | closed |
| T-99-07 | Information Disclosure | access_token_signer | mitigate | 500 error path logs `inspect(reason)` only (access_token_signer.ex:180); test `refute log =~ "private_jwk"/"BEGIN"/private-exponent` (access_token_signer_test.exs:285-297,328-340) | closed |
| T-99-08 | Elevation of Privilege | access_token_signer | mitigate | `aud` derives strictly from `token.audience` or `[client_id]` (derive_aud/2:121-123); signer never reads `resource` from raw params; restricted-claim drop `~w(iss sub aud exp iat jti client_id)` on exchange custom claims (access_token_signer.ex:79) | closed |
| T-99-09 | Spoofing | access_token_signer | mitigate | Signer sets exact `typ: "at+jwt"` (access_token_signer.ex:172); round-trip asserted `header["typ"] == "at+jwt"` (access_token_signer_test.exs:112) | closed |
| T-99-10 | Spoofing | access_token_signer | mitigate | `maybe_put_cnf/2` copies `token.cnf` only when present (access_token_signer.ex:144,147-148); tests assert copy + omit (access_token_signer_test.exs:255,265) | closed |
| T-99-11 | Elevation of Privilege | token_exchange (device/CIBA) | mitigate | `validate_grant_resources/2` rejects out-of-set resource with `invalid_target`/`:invalid_resource`/400 (token_exchange.ex:712-743); threaded into `redeem_device_grant`/`redeem_ciba_grant` before mint; only validated reaches `%Token{audience}` (token_exchange.ex:899,903,1050,1055) | closed |
| T-99-12 | Tampering/DoS | token_exchange | mitigate | `build_access_token/6` re-points `%Token{}.token_hash` to signer's returned hash (token_exchange.ex:1492-1494); test asserts `token_hash == Policy.hash_token(success.access_token)` (token_exchange_test.exs:174) | closed |
| T-99-13 | Spoofing | token_exchange (device/CIBA) | mitigate | Resource-scoped device flow asserts `aud == [resource]` (token_exchange_test.exs:1485) AND resource-scoped CIBA flow asserts `aud == [resource]` (token_exchange_test.exs:1574+; claim assertion `aud == ["https://api.ciba.example.com"]`) | closed |
| T-99-14 | Repudiation/Tampering | refresh_exchange | mitigate | `build_rotated_access_token/5` sources `account_id` from `presented_refresh_token.account_id` before signing (refresh_exchange.ex:310,106-108); test asserts `payload["sub"] == "subject-refresh"` + `refute is_nil(sub)` (refresh_exchange_test.exs:629-630) | closed |
| T-99-15 | Spoofing | rfc8693_exchange | mitigate | Exchange path mints via `issue_exchange/4` → bare-string `aud == client_id`; regression sentinel asserts `payload["aud"] == client.client_id` + `is_binary(payload["aud"])` (rfc8693_exchange.ex:326; rfc8693_exchange_test.exs:201-204) | closed |
| T-99-16 | Tampering | rfc8693_exchange | mitigate | Grep gate: `JOSE.(JWT\|JWS).(sign\|compact)` == 0 and `defp (fetch_signing_key\|decode_private_jwk\|decode_erlang_jwk)` == 0 in rfc8693_exchange.ex; all signing flows through `AccessTokenSigner` (rfc8693_exchange.ex:12,326). `JOSE.JWT.peek_payload`/`to_map` retained for actor-token decode only (not signing) | closed |
| T-99-17 | Tampering | access_token_signer / rfc8693_exchange | mitigate | Restricted-claim drop `~w(iss sub aud exp iat jti client_id)` in `issue_exchange/4` (access_token_signer.ex:79); test asserts attacker `iss`/`aud` custom claims ignored (rfc8693_exchange_test.exs:200-203) | closed |
| T-99-18 | Information Disclosure | rfc8693_exchange | mitigate | Exchange signing error path is the signer's path (logs `inspect(reason)` only); covered by the no-leak signer test (access_token_signer.ex:180; access_token_signer_test.exs:285-297) | closed |
| T-99-19 | Tampering | admin/clients + client domain/record | mitigate | `normalize_mutable_field(:access_token_format, ...)` → `normalize_access_token_format/1` maps only inherit/jwt/opaque/nil/"" else `:error` (admin/clients.ex:517-522,618-635); `validate_access_token_format_if_present/1` rejects unknown (admin/clients.ex:358-373); `update_changeset` `Ecto.Enum` rejects out-of-set (client_record.ex:62,225) | closed |
| T-99-20 | Information Disclosure | clients_live/show | mitigate | `resolve_effective_access_token_format/2` uses per-client → server-default → `:jwt` precedence (show.ex:603-612) matching signer `resolve_format/2`; tests assert override + effective coherence (show_test.exs) | closed |
| T-99-21 | Tampering | form_component + show | mitigate | inherit → `nil` (no sentinel atom): `format_default_for_select(nil) -> "inherit"` (form_component.ex:472), `access_token_format_override_label(nil) -> "inherit"` (show.ex:615), `edit_attrs` threads param (show.ex:493); nil stored & rendered as inherit | closed |
| T-99-SC | Tampering | supply chain | **accept** | No packages added in Phase 99; `mix.lock` unchanged across all 6 plans; no install task exists. Documented in Accepted Risks Log (RISK-99-SC). | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| RISK-99-02 | T-99-02 | Default access-token format flips from opaque to `:jwt`. Blast radius accepted: existing opaque tokens remain valid (introspection/revocation by hash is format-agnostic — `token_hash` re-pointed to signer hash); the migration only adds columns and backfills the singleton server-policy row to `"jwt"` via the column default (no row rewrite); any client that needs opaque can opt in via the per-client `access_token_format: :opaque` override. | szTheory | 2026-05-28 |
| RISK-99-SC | T-99-SC | Supply-chain (npm/pip/cargo/hex). Phase 99 added zero new packages across all 6 plans; `mix.lock` is unchanged from the base commit (deps were only fetched, never added); no install/build task was introduced. No new third-party attack surface. | szTheory | 2026-05-28 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-28 | 22 | 22 | 0 | gsd-security-auditor (Claude Opus 4.7) |

Notes for this run:
- 20 `mitigate` threats verified by locating the concrete call/pattern in the cited
  implementation file plus the cited test assertion. No threat marked closed on
  code-structure inference alone.
- 2 `accept` threats (T-99-02, T-99-SC) closed by documenting in the Accepted Risks Log above.
- SUMMARY `## Threat Flags`: 99-02 explicitly declares "None"; 99-01/03/04/05/06 use
  "Threat Surface" sections that map all surface to existing register IDs. No
  unregistered flags (new attack surface with no threat mapping) were found.
- T-99-16 grep gates re-run live during audit: forbidden `JOSE.(JWT|JWS).(sign|compact)`
  and key-fetch helper definitions return 0 matches in rfc8693_exchange.ex.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-28
