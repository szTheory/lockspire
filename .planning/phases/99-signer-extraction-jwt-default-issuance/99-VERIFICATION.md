---
phase: 99-signer-extraction-jwt-default-issuance
verified: 2026-05-28T11:05:00Z
status: human_needed
score: 8/8 must-have requirements verified
overrides_applied: 0
human_verification:
  - test: "Decide disposition of CR-01 (latent MatchError on corrupt stored JWK)"
    expected: "Either accept the risk for v1.27 (error-path-only edge case; happy path unaffected) and track the fix, OR fix sign_jwt/2 to use a `with`+`else` (mirroring IdToken.sign/1) so a corrupt active signing key returns a structured `:token_signing_failed` 500 instead of an uncaught MatchError + stacktrace on EVERY grant path."
    why_human: "The code review flagged this as Critical because the JWT-default flip routes AC/refresh/device/CIBA through the same hard match. It is real and still present (access_token_signer.ex:168, unfixed), but it does NOT block any of the 8 requirements or 5 success criteria — all functional/happy paths work and the suite is green (1030/0). This is a risk-acceptance decision, not an automated pass/fail."
deferred: []
---

# Phase 99: Signer Extraction + JWT-Default Issuance — Verification Report

**Phase Goal:** One shared `Lockspire.Protocol.AccessTokenSigner` owns RFC 9068 `at+jwt` issuance across the AC, refresh, device, CIBA, and RFC 8693 paths; the default access-token format flips from opaque to `:jwt`; per-client overrides and audience semantics are coherent and discoverable.
**Verified:** 2026-05-28T11:05:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

All 8 phase requirements (SIGNER-01/02, FORMAT-01/02, AUD-01/02/03, DISCOVERY-01) and all 5 ROADMAP success criteria are observably true in the live codebase. The full suite is green (`mix test` → **1030 tests, 0 failures, 284 excluded**). The phase goal is achieved.

Status is `human_needed` — not because any must-have failed, but because the standard code review (`99-REVIEW.md`) raised one **Critical** finding (CR-01) that is real and still present in the code, and whose disposition (accept-and-track vs. fix-now) is a human risk decision. It does not block the functional goal.

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| SC1 | Fresh deploy (server default) mints `at+jwt` on AC/refresh/device/CIBA with no per-client config | ✓ VERIFIED | `ServerPolicy` defstruct default `:jwt` (server_policy.ex:38); migration backfills singleton `null: false, default: "jwt"`; all four paths route through `AccessTokenSigner.issue` (token_exchange.ex:1492, refresh_exchange.ex:107). AC/refresh/device JWT tests assert `typ == "at+jwt"`. |
| SC2 | Admin client-detail can read & change per-client override (`:jwt`/`:opaque`/`nil`) + doclink | ✓ VERIFIED | form_component.ex:108-131 — `<select name="client[access_token_format]">` with inherit/jwt/opaque + `<a href="docs/protect-phoenix-api-routes.md">`; show.ex:214-216 global/override/effective rows; 65 admin/show tests green |
| SC3 | `resource=` → `aud=[resource]`; absent → `aud=[client_id]` on AC/refresh/device/CIBA; exchange `aud` stays bare-string `client_id` | ✓ VERIFIED | `derive_aud/2` (signer:121-123) list form; `issue_exchange/4` (signer:78) bare-string; tests: AC aud (token_exchange_test.exs:202), device:1485, CIBA:1574, refresh aud (refresh_exchange_test.exs:670/704), AUD-03 sentinel (rfc8693_exchange_test.exs:203) |
| SC4 | Discovery advertises `access_token_signing_alg_values_supported: ["RS256","ES256","PS256"]` | ✓ VERIFIED | discovery.ex:40 literal + :102 in the **unconditional** base map; discovery tests green |
| SC5 | No duplicated `at+jwt` signing logic; `rfc8693_exchange.ex:317-361` block gone; every path calls `AccessTokenSigner` | ✓ VERIFIED | Single `JOSE.JWT.sign` access-token site at signer:171. rfc8693_exchange.ex: `JOSE.(JWT\|JWS).(sign\|compact)` count = **0**, `defp (fetch_signing_key\|decode_private_jwk\|decode_erlang_jwk)` count = **0**, `AccessTokenSigner` referenced (2×) |

**Score:** 5/5 success criteria verified · 8/8 requirements satisfied

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SIGNER-01 | 99-03/04/05 | Shared signer owns `at+jwt`; old block extracted; no dup logic | ✓ SATISFIED | Single JOSE site (signer:171); SC5 grep gates = 0; all 5 paths call `issue`/`issue_exchange` |
| SIGNER-02 | 99-03 | Format decided in one place; `:opaque` via TokenFormatter | ✓ SATISFIED | `resolve_format/2` (signer:89-98) per-client→server→:jwt; opaque branch `format_opaque/1` (signer:156) delegates to TokenFormatter |
| FORMAT-01 | 99-01 | Server-wide default `:jwt`, runtime-settable | ✓ SATISFIED | ServerPolicy default `:jwt`; `Admin.ServerPolicy.put_access_token_format/1` (server_policy.ex:67) → `update_server_policy` |
| FORMAT-02 | 99-01/06 | Nullable per-client override visible in admin + doclink | ✓ SATISFIED | Client nullable field (client.ex:115, both changesets client_record.ex:135/225); admin select + rows + doclink (Plan 06) |
| AUD-01 | 99-04/05 | `resource=` → `aud=[resource]` threaded AC/refresh/device/CIBA | ✓ SATISFIED | AC threads `requested_resources`; device/CIBA net-new `validate_grant_resources` (token_exchange.ex:712) + `validated_audience`; refresh threads `requested_resources`. Tests at device:1485, CIBA:1574, refresh:670 |
| AUD-02 | 99-03/04/05 | absent `resource=` → `aud=[client_id]` (list) | ✓ SATISFIED | `derive_aud([], cid) -> [cid]` (signer:122); tests token_exchange_test.exs:162/1530/1619, refresh:704 |
| AUD-03 | 99-03/05 | exchange `aud` stays bare-string `client_id` | ✓ SATISFIED | `issue_exchange/4` passes `client.client_id` (string) to `base_claims`; sentinel rfc8693_exchange_test.exs:203 green |
| DISCOVERY-01 | 99-02 | discovery advertises the alg triple unconditionally | ✓ SATISFIED | discovery.ex:40/102, unconditional base map |

All 8 IDs declared across plan frontmatter (99-01..99-06) match REQUIREMENTS.md Phase-99 mapping exactly. **No orphaned requirements** (REQUIREMENTS.md maps exactly these 8 to Phase 99; all are claimed by a plan).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/lockspire/protocol/access_token_signer.ex` | Shared signer, one-place format res, aud derivation (≥60 lines) | ✓ VERIFIED | 234 lines; `issue/3` + `issue_exchange/4`; single JOSE site; WIRED from 3 call sites |
| `lib/lockspire/protocol/token_exchange.ex` | AC/device/CIBA mint via signer + device/CIBA resource validation | ✓ VERIFIED | `build_access_token/6` → signer (:1492); device/CIBA `validate_grant_resources` + threaded audience |
| `lib/lockspire/protocol/refresh_exchange.ex` | Rotation via signer; sub from presented token | ✓ VERIFIED | `issue` at :107; rotated `account_id: source_token.account_id` (:310) |
| `lib/lockspire/protocol/rfc8693_exchange.ex` | Signing block removed; routes through signer (string aud) | ✓ VERIFIED | `issue_exchange/4` at :327; JOSE/helper counts = 0 |
| `lib/lockspire/protocol/discovery.ex` | alg triple literal in static map | ✓ VERIFIED | :40 + :102 unconditional |
| `priv/repo/migrations/20260528150000_add_access_token_format.exs` | dual-table cols (client nullable, server default jwt) | ✓ VERIFIED | both `alter table`; clients nullable; server `null: false, default: "jwt"`; column live in test SQL |
| `lib/lockspire/domain/server_policy.ex` + record | default `:jwt`, Ecto.Enum, runtime setter | ✓ VERIFIED | domain default :38; record Ecto.Enum :25; setter wired |
| `lib/lockspire/domain/client.ex` + record | nullable field, both changesets, to_domain | ✓ VERIFIED | client.ex:115 nil default; record schema:62, changesets:135/225, to_domain:296 |
| `lib/lockspire/admin/clients.ex` | @mutable_fields + normalize (inherit→nil) | ✓ VERIFIED | :30 mutable; :517 normalize clause; :618-635 normalizer (inherit/nil/""→nil) |
| `form_component.ex` / `show.ex` | override select + doclink + 3 display rows | ✓ VERIFIED | select :108-131; rows :214-216; effective resolution :603-609 mirrors signer precedence |
| `test/.../access_token_signer_test.exs` | signer unit coverage | ✓ VERIFIED | exists; covers jwt claims+hash, precedence, opaque, aud carve-out, cnf, missing-key 500 |

### Key Link Verification

| From | To | Via | Status |
| ---- | -- | --- | ------ |
| token_exchange.ex (AC/device/CIBA) | `AccessTokenSigner.issue` | `build_access_token/6` (3 callers: :761/:901/:1053) | ✓ WIRED |
| refresh_exchange.ex | `AccessTokenSigner.issue` | rotation mint :107; sub from presented token :310 | ✓ WIRED |
| rfc8693_exchange.ex | `AccessTokenSigner.issue_exchange` | exchange custom-claims branch :327 | ✓ WIRED |
| signer `:jwt` branch | `JOSE.JWT.sign` | single signing site :171 | ✓ WIRED |
| signer `:opaque` branch | `TokenFormatter.format_access_token` | `format_opaque/1` :157 | ✓ WIRED |
| signer | `server_policy_store.get_server_policy` | `server_policy/1` reads default :100-111 | ✓ WIRED |
| Admin.ServerPolicy | `Repository.update_server_policy` | `put_access_token_format/1` :67-69 | ✓ WIRED |
| client_record | `Domain.Client.access_token_format` | `to_domain/1` :296 | ✓ WIRED |
| form_component | admin/clients normalize | `client[access_token_format]` → `normalize_mutable_field/2` → `update_changeset/2` | ✓ WIRED |
| show.ex effective row | `ServerPolicy.access_token_format` | `resolve_effective_access_token_format/2` :603-609 | ✓ WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Full suite green | `mix test` | 1030 tests, 0 failures (284 excluded) | ✓ PASS |
| Signer + discovery + admin show | `mix test access_token_signer_test discovery_test show_test` | 65 tests, 0 failures | ✓ PASS |
| Device/CIBA/refresh `resource=` aud | grep + suite | tests assert `aud == [resource]` and `aud == [client_id]` | ✓ PASS |
| AUD-03 bare-string sentinel | `mix test rfc8693_exchange_test` | rfc8693_exchange_test.exs:203 green | ✓ PASS |
| Migration column live | observed in test SQL | `access_token_format` present in `lockspire_server_policies` SELECT | ✓ PASS |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| access_token_signer.ex | 168 | Hard match `{:ok, jwk_map} = decode_private_jwk(...)` (no `with`/`else`) | ⚠️ Warning (CR-01) | On a corrupt/non-decodable stored active JWK, raises `MatchError` → uncaught 500 + stacktrace instead of the structured `:token_signing_failed` error the module promises. JWT-default flip routes AC/refresh/device/CIBA through this match, widening the blast radius. NO test covers this path. |
| access_token_signer.ex | 203 | `fetch_active_signing_key()` arity-0 vs behaviour arity-1 (WR-01) | ℹ️ Info | Works today (Repository default-arg + test mock define arity-0); a faithful arity-1 host `:key_store` would raise `UndefinedFunctionError`. |
| rfc8693_exchange.ex | 35-44 | `now/1` evaluated twice → JWT iat/exp vs persisted timestamps diverge by µs (WR-02) | ℹ️ Info | Correctness/consistency, not security; JWT carries authoritative exp |
| refresh_exchange.ex | 332 | rotated refresh token `account_id: nil` → audit `subject_id: nil` (WR-05) | ℹ️ Info | Observability gap (pre-existing); repository back-fills at persistence |
| discovery.ex | 102 | non-standard metadata key (IN-01) | ℹ️ Info | Intentional/documented (DISCOVERY-01); harmless to spec clients |

No `TBD`/`FIXME`/`XXX` debt markers in any phase-99 modified file. No `TODO`/`HACK`/`PLACEHOLDER`. No stub returns.

### Human Verification Required

#### 1. CR-01 — Latent MatchError on a corrupt stored signing key (review-flagged Critical)

**Test:** Review `lib/lockspire/protocol/access_token_signer.ex:165-191` (`sign_jwt/2`). The line `{:ok, jwk_map} = decode_private_jwk(private_jwk)` is a hard match. `fetch_signing_key/1` only guarantees `private_jwk_encrypted` is a binary, not that it decodes to a JWK map; `decode_private_jwk/1` can return `{:error, :invalid_signing_key}`. Confirm the desired behavior when an operator's active signing key is stored-but-corrupt.
**Expected:** Decide one of:
  (a) **Fix now** — convert to `with {:ok, ...} <- fetch_signing_key(request), {:ok, jwk_map} <- decode_private_jwk(private_jwk) do ... else {:error, reason} -> <structured 500>` (mirroring the already-correct `IdToken.sign/1` at id_token.ex:36/56-58), plus a regression test seeding a non-decodable `private_jwk_encrypted` that asserts `{:error, %Error{reason_code: :token_signing_failed}}`; OR
  (b) **Accept for v1.27** — document the risk (error-path-only; requires a corrupt active key; happy path and all 1030 tests unaffected) and track the fix as follow-up. Consider IN-04's suggestion to extract a single shared JWK decoder so the fix applies uniformly across the 5 modules that copy `decode_private_jwk/1`.
**Why human:** The review classified this Critical because the JWT-default flip makes the crash reachable on every grant path. It is genuinely present and unfixed (verified at :168, no `else`/`rescue`). But it does NOT fail any of the 8 requirements or 5 success criteria — every functional/happy path works and the suite is green. Choosing fix-now vs. accept-and-track is a risk decision, not an automated determination.

### Gaps Summary

No functional gaps. All 8 requirements and all 5 ROADMAP success criteria are observably true in the live codebase, backed by a green 1030-test suite and targeted JWT-claim assertions (typ/sub/aud/cnf), format-precedence tests, the SC5 single-signer grep gates (JOSE/helper counts = 0 in `rfc8693_exchange.ex`), and the AUD-03 bare-string sentinel.

The single open item is CR-01: a pre-existing hard-match robustness defect that the phase materially widened (now on every default grant path) but left unfixed. It is error-path-only and untested. Because the code review rated it Critical and no later phase (100/101/102) addresses signer error-handling, it is surfaced for a human accept-or-fix decision rather than silently passing.

---

_Verified: 2026-05-28T11:05:00Z_
_Verifier: Claude (gsd-verifier)_
