# Phase 100: Sender-Constraint End-to-End Proof - Research

**Researched:** 2026-05-28
**Domain:** Elixir/Phoenix OAuth resource-server plug pipeline; RFC 9449 (DPoP) + RFC 8705 (mTLS) sender-constrained `at+jwt` proof-of-possession; ExUnit integration + contract testing
**Confidence:** HIGH

## Summary

This is a **verification-first phase against a settled technical approach** (CONTEXT.md D-01..D-10). The dominant research output is not "what stack/library" — it is (a) confirming every cited `file:line` anchor and helper signature still matches the live code so the executor can rely on them, (b) surfacing the landmines in the DPoP nonce-retry dance, the KeyCache publish-then-sign timing, and the cross-plug `binding_verified` signal, and (c) a **Validation Architecture** that gives faithful (not shallow) proofs for BIND-01/02/03.

Every load-bearing anchor in CONTEXT.md was verified against the live tree and **all match** (a few line numbers drift by 1-2 lines or off-by-a-clause; flagged inline, none material). The signer (`AccessTokenSigner.issue/3`) copies `token.cnf` into the JWT via `maybe_put_cnf/2` — confirmed at `access_token_signer.ex:144,147-148`. The three BIND-03 edit targets (`access_token.ex`, `enforce_sender_constraints.ex`, `require_token.ex`) are exactly as described, and `binding_verified` exists **nowhere** in `lib/` or `test/` today (net-new). The four RECIPE-01 canonical pipeline blocks all already declare `VerifyToken → EnforceSenderConstraints → RequireToken` in correct order, so D-05's ordering clause is satisfied by current content and does not ripple the content hash.

**The single most important finding** is the resolution of CONTEXT.md's flagged behavior-change risk. CONTEXT.md feared "any pre-existing test that ran a bound token through `VerifyToken → RequireToken` *without* `EnforceSenderConstraints` will newly fail-closed." Exhaustive search found the only such call sites are in `verify_token_test.exs:947-1037` — and **every one of them deliberately induces a `VerifyToken` error** (wrong audience/scope/typ), so the token always carries `error != nil` and never reaches the pass-through clause where the D-03 guard lives. Therefore **no existing test newly fail-closes** provided the D-03 guard is gated on `error: nil` (only intercepts what would otherwise pass). The only test that *must* be updated is the struct-defaults test in `access_token_test.exs` (it asserts "all fields default to nil"; the new field defaults to `false`). This is a far cleaner reconciliation story than feared.

**Primary recommendation:** Lift the phase81 DPoP harness, swap its hand-signed JWT for an `AccessTokenSigner.issue/3` mint (publishing a key with BOTH `public_jwk` for KeyCache AND `private_jwk_encrypted` for the signer), and write the D-03 guard as a new `RequireToken.call/2` clause ordered before the pass-through but gated on `binding_requirements != nil and binding_verified == false and error == nil`, routing through the existing `handle_structured_error` sender-constraint path.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**BIND-03 bypass closure — runtime fail-closed guard + contract-test ordering clause (defense-in-depth)**

- **D-01:** Add a `binding_verified` field to `%Lockspire.AccessToken{}` (`lib/lockspire/access_token.ex`), **defaulting to `false`** — a fail-closed default ("not verified until something proves otherwise"). Do NOT remove or repurpose any of the existing seven fields. This is the explicit, named breadcrumb that records "sender constraints were enforced," replacing the current state where `RequireToken` cannot tell "EnforceSenderConstraints ran and passed" from "it was omitted."
- **D-02:** `Lockspire.Plug.EnforceSenderConstraints` sets `binding_verified: true` on the `access_token` assign on **every success path** where it actually validated a binding — the DPoP-success→mTLS-skip path, the mTLS-success path, and the DPoP+mTLS-both-success path (`enforce_sender_constraints.ex:67-78,111-128`). The bearer/unconstrained no-op path (`binding_requirements` is `nil`) is unchanged and leaves `binding_verified: false` — that value is never consulted for unbound tokens (see D-03). This is the one bit of new enforcer code in the phase.
- **D-03:** `Lockspire.Plug.RequireToken` (`require_token.ex:20-35`) gains a fail-closed clause, ordered **before** the existing `%AccessToken{error: nil, claims: present} -> conn` pass-through: when a token has `binding_requirements != nil` **and** `binding_verified == false` (i.e. a bound token reached `RequireToken` without enforcement having marked it), halt fail-closed with a sender-constraint error (`403`, `error: "invalid_token"`, sender-constraint `error_description`, challenge derived from binding type like the existing sender-constraint path). **Disambiguator (the surprise-free guarantee):** the guard fires ONLY for tokens that arrived bound; bearer-only routes carry `binding_requirements: nil` and pass through exactly as today. There is no legitimate configuration in which a bound token should be honored without its proof checked, so the guard has zero false-positive surface.
- **D-04:** Do **NOT** clear `binding_requirements` on success as the verified-signal. The host controller reads `binding_requirements` off `conn.assigns.access_token` for legitimate visibility (the `phase81` proof controller asserts `binding_requirements: %{dpop_jkt: jkt}`). Use the positive `binding_verified` breadcrumb (D-01) instead — clearing the field would destroy host-facing data and conflate "verified" with "absent."
- **D-05:** Also add the contract-test layer (defense-in-depth, mirroring Phase 98's both-mechanisms posture for VERIFIER-06): a `release_readiness_contract_test` clause asserting all four RECIPE-01 canonical pipeline sites order `VerifyToken → EnforceSenderConstraints → RequireToken`. Reuse the existing `extract_canonical_pipeline!/2` helper and the four-file iteration the audience clause already uses (`release_readiness_contract_test.exs:140-157,761-791`); assert ordering via byte-offset comparison or a single `~s` multiline regex over the normalized block. **All four blocks already declare the three plugs in correct order today**, so this clause is satisfied by current content and does NOT ripple the four-file content hash.

**BIND-01 — DPoP-bound `at+jwt` end-to-end proof**

- **D-06:** Prove BIND-01 by running a DPoP-bound `at+jwt` (carrying `cnf.jkt`) through the real `GeneratedHostAppWeb.Endpoint` whose `:lockspire_protected_api` pipeline is exactly the canonical 3-plug chain (`test/support/generated_host_app_web/router.ex:19-27`), supplying a valid `DPoP:` proof (with the nonce-challenge/retry dance), and asserting `200` with `conn.assigns.access_token` populated and `binding_type: "dpop"`. Lift the existing harness in `test/integration/phase81_generated_host_route_protection_e2e_test.exs:150-215` (DPoP proof via `JarTestHelpers.sign_dpop_proof/2`, `jkt` via `DPoP.thumbprint/1`).
- **D-07:** Mint the bound token via `Lockspire.Protocol.AccessTokenSigner.issue/3` with a `%Token{cnf: %{"jkt" => jkt}}` — exercising Phase 99's `maybe_put_cnf/2` carry-through — **rather than** hand-signing with `JOSE.JWT.sign` as `phase81` does. This is the refinement over `phase81`: BIND-01 must prove that *the Phase 99 signer's `cnf` carry-through* survives the pipeline, not just that the plug chain works on a hand-crafted JWT.

**BIND-02 — mTLS-bound `at+jwt` end-to-end proof**

- **D-08:** Prove BIND-02 (genuinely new — no existing full-pipeline mTLS-to-`200` test) by minting an `at+jwt` with `cnf["x5t#S256"]` and presenting the bound client cert via `conn.private[:lockspire_mtls_cert]` — the primary path in `EnforceSenderConstraints.fetch_mtls_cert/2` (`enforce_sender_constraints.ex:178-189`). Derive the token's `cnf["x5t#S256"]` from the same cert string via `Lockspire.Protocol.MTLSTokenBinding.thumbprint/1` so `confirmation_matches?/2` (`mtls_token_binding.ex:22-27`) passes. Assert `200` with `conn.assigns.access_token` populated and `binding_type: "mtls"`. Mint via `AccessTokenSigner.issue/3` per D-07 (synthetic string cert is sufficient for the proof; a real DER-cert/`:mtls_extractor` path is not required — see Deferred).

**Bound-token issuance fixture**

- **D-09:** Issue both bound tokens via `AccessTokenSigner.issue/3` and publish the signing key to `KeyCache` so `VerifyToken` resolves the `kid` (the `verify_token_test.exs:39-91` / `access_token_signer_test.exs:21-31` recipe: generate key → `Repository.publish_key/1` → `send(KeyCache, :refresh)` → sign). Do NOT drive a full DB-backed token-endpoint exchange (clients, grants, DPoP-at-`/token`, mTLS client-auth) — that is heavier than the proof needs and the signer path is faithful to the thing being proven (signer `cnf` carry-through → verifier → enforcer).

**Test placement**

- **D-10:** Add one new `test/integration/phase100_sender_constraint_e2e_test.exs` (`@moduletag :integration`, `@endpoint GeneratedHostAppWeb.Endpoint`, `async: false`, mirroring `phase81`) holding the BIND-01 (DPoP) and BIND-02 (mTLS) happy-path proofs side-by-side. Add the BIND-03 contract-ordering clause (D-05) to the existing `test/lockspire/release_readiness_contract_test.exs`. Add a BIND-03 **negative** runtime test (a bound token through a `VerifyToken → RequireToken` pipeline that omits `EnforceSenderConstraints` returns fail-closed `403`, while a bearer token through the same pipeline still returns `200`) at the plug layer (alongside `enforce_sender_constraints_test.exs` / `require_token` tests).

### Claude's Discretion

- Exact name/shape of the BIND-03 fail-closed clause and its error map in `RequireToken`, provided it routes through the existing sender-constraint error/challenge emission (`handle_structured_error`/`handle_invalid_token`) and returns `403` for the bound-but-unverified case (D-03).
- Whether `EnforceSenderConstraints` sets `binding_verified: true` by re-assigning the `access_token` at each success return or via one shared helper, provided every binding-validated success path sets it and the no-op bearer path does not (D-02).
- Exact ordering-assertion technique in the contract test (offset comparison vs multiline regex), provided it composes with `extract_canonical_pipeline!/2` and does not introduce a parallel extraction path (D-05).
- Exact DPoP proof/nonce-retry construction and key-publish plumbing in the new test, provided BIND-01 mints through `AccessTokenSigner.issue/3` (D-07/D-09).
- Exact synthetic cert string and `cnf["x5t#S256"]` derivation for BIND-02, provided the presented cert and the token's confirmation thumbprint agree via `MTLSTokenBinding.thumbprint/1` (D-08).

### Deferred Ideas (OUT OF SCOPE)

- **Export the protected-route pipeline as a single composed `Plug.Builder` unit** (e.g. `plug Lockspire.ProtectedAPI, scopes: [...], audience: ...`) so the secure ordering is the only orderable thing and omission of `EnforceSenderConstraints` becomes *structurally impossible* rather than runtime-detected. The Phase 100 `binding_verified` guard is forward-compatible with it. v1.28+ candidate.
- **Real DER-cert / `:mtls_extractor` end-to-end proof for BIND-02** — Phase 100 uses a synthetic string cert via `conn.private[:lockspire_mtls_cert]`, which faithfully exercises `confirmation_matches?/2`. A real-cert-chain proof is heavier and not required.
- **Full token-endpoint issuance fixture** (DB-backed clients/grants, DPoP-at-`/token`, mTLS client-auth) instead of `AccessTokenSigner.issue/3` — more faithful to production `cnf` origin but far heavier than this proof needs.
- **DPoP-at-RS replay-store durability gap (RS-DPoP-01)** — already deferred in REQUIREMENTS.md; Phase 100 does not address replay-store durability.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **BIND-01** | A DPoP-bound `at+jwt` issued by the AC/refresh/device/CIBA paths carries `cnf.jkt` and is verified end-to-end through `VerifyToken → EnforceSenderConstraints → RequireToken`, returning a usable `%AccessToken{}` to the host controller. No new enforcer code; proof only. | Phase81 DPoP harness (`phase81_...e2e_test.exs:150-215`) proves the plug-chain happy path today via a hand-signed JWT. The refinement (D-07) is minting via `AccessTokenSigner.issue/3` so the proof exercises Phase 99's `maybe_put_cnf/2` (`access_token_signer.ex:144,147-148`). Issuance fixture: `Repository.publish_key/1` + KeyCache refresh + `issue/3` (verified §"DPoP issuance + key linkage"). Nonce-retry dance is load-bearing — see Pitfall 1. |
| **BIND-02** | An mTLS-bound `at+jwt` carries `cnf["x5t#S256"]` and is verified end-to-end. No new enforcer code; proof only. | Genuinely new — no existing full-pipeline mTLS→200 test. `EnforceSenderConstraints.fetch_mtls_cert/2` reads `conn.private[:lockspire_mtls_cert]` first (`enforce_sender_constraints.ex:178-189`). `MTLSTokenBinding.thumbprint/1` (`mtls_token_binding.ex:7-17`) makes `cnf["x5t#S256"]` reproducible from the same cert string. `confirmation_matches?/2` at `mtls_token_binding.ex:22-29` (CONTEXT cited 22-27; actual fallthrough at 29). Reuse the `put_private(:lockspire_mtls_cert, "mtls-cert")` pattern from `enforce_sender_constraints_test.exs:192-234`. |
| **BIND-03** | A pipeline missing `EnforceSenderConstraints` after `VerifyToken` either fails closed in `RequireToken` (when `binding_requirements` is non-nil) or is asserted-against by `release_readiness_contract_test`. Sender-constraint bypass via misordered pipeline no longer reachable in the blessed path. | Net-new runtime guard (D-01..D-03) + contract clause (D-05). `binding_verified` exists nowhere today (verified). The reconciliation risk is resolved: only `verify_token_test.exs:947-1037` chains bound tokens through `VerifyToken→RequireToken` without `EnforceSenderConstraints`, and all carry `error != nil` so they never reach the guarded pass-through. Only `access_token_test.exs:7-19` needs an additive update for the new field default. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `at+jwt` issuance with `cnf` carry-through | Issuance (`AccessTokenSigner`) | — | Library-owned protocol truth; the proof must originate here per D-07, not from a hand-signed JWT |
| Signing-key resolution (private, for signing) | Storage (`Repository.fetch_active_signing_key`) | — | Signer reads private JWK directly from repo, not KeyCache |
| Signing-key resolution (public, for verification) | KeyCache (in-process) | Storage (`Repository.publish_key`) | `VerifyToken.fetch_key/1 → KeyCache.get_key/1`; KeyCache is refreshed from the repo |
| Token shape/claim/`cnf` verification | RS plug `VerifyToken` | — | Derives `binding_type`/`binding_requirements` from `cnf` (`verify_token.ex:133-134,467-537`); read-only for Phase 100 |
| Proof-of-possession enforcement (DPoP/mTLS) | RS plug `EnforceSenderConstraints` | `ProtectedResourceDPoP.validate_access/2`, `MTLSTokenBinding.confirmation_matches?/2` | Owns the binding check; edited by D-02 to set the `binding_verified` breadcrumb |
| Fail-closed gate + WWW-Authenticate emission | RS plug `RequireToken` | `ProtectedResourceChallenge` | Final pipeline gate; edited by D-03 to reject bound-but-unverified tokens |
| Misorder structural assertion | Contract test (`release_readiness_contract_test`) | `extract_canonical_pipeline!/2` | Defense-in-depth across the four RECIPE-01 doc/template sites |
| Host visibility of binding metadata | Host controller (`ProtectedApiController`) | — | Reads `access_token.binding_type` / `binding_requirements`; the reason D-04 must NOT clear `binding_requirements` |

## Standard Stack

This is an internal library proof phase. **No new external packages are introduced.** All work uses the existing stack already in `mix.exs`.

### Core (already present — verified in `mix.exs`)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `~> 1.8.5` | Router/endpoint/controller; `Phoenix.ConnTest` for the e2e harness | Project framework |
| `jose` | `~> 1.11` | JWT signing/verification; `JOSE.JWT.sign`, `JOSE.JWS.compact` | Already owns all protocol-sensitive JOSE work |
| `jason` | `~> 1.4` | JSON encode/decode of bodies and JWK | Project default |
| `plug` (via phoenix/bandit) | — | `Plug.Test`, `Plug.Conn`, `put_private/3` | Plug-unit fixtures |
| `ex_unit` (stdlib) | Elixir 1.19.5 | `@moduletag :integration`, `async: false` | Test framework |

**Runtime:** Elixir 1.19.5, Erlang/OTP 28 (verified via `elixir --version`).

### Supporting (test helpers — already present)
| Helper | Location | Purpose |
|--------|----------|---------|
| `JarTestHelpers.generate_ec_keys/0` | `test/support/jar_test_helpers.ex:46` | EC keypair for the DPoP proof key |
| `JarTestHelpers.sign_dpop_proof/2,3` | `test/support/jar_test_helpers.ex:82` | Signs the DPoP proof JWT |
| `DPoP.thumbprint/1` | `lib/lockspire/protocol/dpop.ex` | Computes `jkt` from the public DPoP JWK |
| `DPoP.access_token_ath/1` | `lib/lockspire/protocol/dpop.ex:57-62` | `ath` claim hash binding the proof to the access token |
| `MTLSTokenBinding.thumbprint/1` | `lib/lockspire/protocol/mtls_token_binding.ex:7-17` | `x5t#S256` from cert string |
| `GeneratedHostAppWeb.ProtectedApiReplayStore` | `test/support/generated_host_app_web/controllers/protected_api_controller.ex:1-5` | Accepting DPoP replay store (`{:ok, :accepted}`) wired into the endpoint |

**Installation:** none required.

## Package Legitimacy Audit

**Not applicable — Phase 100 installs no external packages.** All dependencies are already declared in `mix.exs` (verified). The phase adds one struct field, two small plug edits, and three test files/clauses using the existing stack. No `mix deps.get` change is expected.

## Architecture Patterns

### System Architecture Diagram (BIND-01/02 end-to-end data flow)

```
                          ┌─────────────────────── ISSUANCE FIXTURE (test setup) ───────────────────────┐
                          │                                                                              │
   generate RSA key ──▶ Repository.publish_key(%SigningKey{                                              │
                          │   public_jwk: ...,            ◀── used by VerifyToken via KeyCache           │
                          │   private_jwk_encrypted: ...  ◀── used by AccessTokenSigner.fetch_signing_key│
                          │   status: :active })                                                         │
                          │        │                                                                     │
              send(KeyCache, :refresh); :sys.get_state(KeyCache)  ── makes kid resolvable to VerifyToken │
                          │        │                                                                     │
   %Token{cnf: %{"jkt"|"x5t#S256" => ...}} ──▶ AccessTokenSigner.issue/3 ── maybe_put_cnf ──▶ at+jwt     │
                          └──────────────────────────────────────────────────────────────────│─────────┘
                                                                                               │ (raw at+jwt)
   ┌──────────────── REQUEST (Phoenix.ConnTest get/2 against GeneratedHostAppWeb.Endpoint) ────▼─────────┐
   │  Authorization: "DPoP <token>"  + DPoP: <proof>     (BIND-01)                                       │
   │  Authorization: "Bearer <token>" + conn.private[:lockspire_mtls_cert]=<cert>   (BIND-02)            │
   └───────────────────────────────────────────│────────────────────────────────────────────────────────┘
                                                ▼
   pipeline :lockspire_protected_api  (router.ex:19-27 — the canonical 3-plug chain)
                                                │
        ┌──────────── VerifyToken ─────────────┘
        │   • KeyCache.get_key(kid) → JOSE verify_strict
        │   • derives binding_type / binding_requirements from cnf  (verify_token.ex:133-134)
        │   → %AccessToken{error: nil, binding_requirements: %{dpop_jkt|mtls_x5t_s256 => ...}}
        ▼
   EnforceSenderConstraints  (binding_requirements is a map → enforce_constraints/3)
        │   BIND-01: ProtectedResourceDPoP.validate_access/2
        │            scheme=DPoP → token → target_uri → proof(+NONCE) → ath → jkt match → replay record
        │            ⚠ FIRST call w/o nonce → {:error, use_dpop_nonce}; RETRY w/ nonce → {:ok}
        │   BIND-02: fetch_mtls_cert (conn.private) → MTLSTokenBinding.confirmation_matches?
        │   D-02 EDIT: on success set binding_verified: true on the access_token assign
        ▼
   RequireToken  (require_token.ex:19-36)
        │   D-03 EDIT (new clause, ordered BEFORE pass-through, gated on error: nil):
        │     binding_requirements != nil AND binding_verified == false → 403 sender-constraint fail-closed
        │   existing pass-through: %AccessToken{error: nil, claims: present} → conn
        ▼
   ProtectedApiController.show/2  → 200 JSON with access_token.{binding_type, binding_requirements, ...}
```

### Recommended Test/Code Structure

```
lib/lockspire/
├── access_token.ex                       # D-01: add binding_verified: false (7 → 8 fields)
└── plug/
    ├── enforce_sender_constraints.ex      # D-02: set binding_verified: true on success paths
    └── require_token.ex                   # D-03: new fail-closed clause before pass-through

test/
├── integration/
│   └── phase100_sender_constraint_e2e_test.exs   # NEW (D-10): BIND-01 DPoP + BIND-02 mTLS happy paths
├── lockspire/
│   ├── access_token_test.exs              # UPDATE: add binding_verified default assertion
│   ├── plug/
│   │   ├── enforce_sender_constraints_test.exs  # ADD: binding_verified: true set on success
│   │   └── require_token_test.exs         # ADD (D-10 negative): bound-but-unverified → 403; bearer → pass
│   └── release_readiness_contract_test.exs # ADD (D-05): ordering clause over the 4 RECIPE-01 files
```

### Pattern 1: Issue a bound `at+jwt` via the real signer with a repo-published key
**What:** Publish a signing key carrying BOTH public and private material, refresh KeyCache, then mint via `AccessTokenSigner.issue/3`. This is the issuance fixture for D-07/D-09.
**When to use:** BIND-01 and BIND-02 token minting.
**Why this shape:** `AccessTokenSigner.fetch_signing_key` reads `private_jwk_encrypted` from `Config.repo!()` (`access_token_signer.ex:196-216`); `VerifyToken.fetch_key/1` reads the public JWK from `KeyCache` (`verify_token.ex:576-577`). The `kid` in the minted JWT header must be resolvable by BOTH. The phase81 `publish_signing_key/1` recipe already publishes both halves — reuse it as the base (it is the right shape; phase81 only differs in that it then hand-signs instead of calling the signer).

```elixir
# Source: synthesized from phase81_...e2e_test.exs:257-283 (key publish)
#         + access_token_signer.ex:55-66 (issue/3) + verified linkage
defp publish_signing_key(kid) do
  key = JOSE.JWK.generate_key({:rsa, 2048})
  {_fields, jwk} = JOSE.JWK.to_map(key)

  {:ok, _} =
    Repository.publish_key(%SigningKey{
      kid: kid, kty: :RSA, alg: "RS256", use: "sig",
      public_jwk: jwk |> Map.take(["kty", "kid", "alg", "use", "n", "e"])
                      |> Map.merge(%{"kid" => kid, "alg" => "RS256", "use" => "sig"}),
      private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
      status: :active, published_at: DateTime.utc_now(),
      activated_at: DateTime.utc_now(), metadata: %{}
    })

  send(KeyCache, :refresh)
  :sys.get_state(KeyCache)   # ⚠ SYNCHRONIZATION POINT — see Pitfall 2
  :ok
end

# Mint via the real signer so cnf carry-through is exercised (D-07)
token = %Lockspire.Domain.Token{
  token_hash: "unused", token_type: :access_token,
  client_id: "generated-host-api-client",
  account_id: "generated-host-user",
  scopes: ["read:billing"], audience: ["billing-api"],
  cnf: %{"jkt" => jkt},                       # BIND-01  (or %{"x5t#S256" => tp} for BIND-02)
  issued_at: DateTime.utc_now(),
  expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
}
{:ok, raw_at_jwt, _hash} = AccessTokenSigner.issue(token, client, request)
# `request` opts default key_store to Config.repo!() (TestRepo) and need a
# server_policy_store or none (resolve_format falls back to :jwt when nil).
```

> **Note on `iss` / `aud`:** `base_claims/3` sets `iss => Config.issuer!()` and `aud` from `token.audience` (list). The integration test must set `Application.put_env(:lockspire, :issuer, @issuer)` so `Config.issuer!()` matches what `VerifyToken` pins, and pass `audience: "billing-api"` on the VerifyToken plug (the router already does). `aud` is a LIST `["billing-api"]` from the signer; the existing audience check accepts list `aud` (phase81's bearer test uses string `aud` but the signer emits a list — confirm the audience matcher accepts both; this is the one spot to watch in BIND-01/02 assembly).

### Pattern 2: The DPoP nonce-challenge/retry dance (BIND-01)
**What:** A DPoP-bound request to the RS first returns `401 use_dpop_nonce` with a `DPoP-Nonce` header; the client re-issues the proof embedding that nonce, then gets `200`.
**When to use:** BIND-01 only (mTLS has no nonce dance).
**Why mandatory:** `ProtectedResourceDPoP.validate_proof` runs with `nonce_purpose: :resource_server` (`protected_resource_dpop.ex:80`), which requires a nonce; the first proof (no nonce) yields `{:error, :missing_dpop_nonce}` → `use_dpop_nonce_error`. This is exactly the three-request shape phase81 uses (`phase81_...e2e_test.exs:165-206`).

```elixir
# Source: phase81_...e2e_test.exs:175-206 (verified live)
# 1) proof WITHOUT nonce  → 401 error="use_dpop_nonce" + DPoP-Nonce header
# 2) extract retry_nonce  → build proof WITH that nonce
# 3) proof WITH nonce      → 200, conn.assigns.access_token populated
proof = generate_dpop_proof(dpop_keys.private_jwk, raw_at_jwt, retry_nonce)
```

### Pattern 3: Fail-closed cross-plug breadcrumb (D-01/D-02/D-03)
**What:** A positive `binding_verified` boolean defaulting `false`, set `true` by the upstream plug, checked by the downstream plug. Idiomatic for a fixed library-owned pipeline (cf. Guardian `Plug.Pipeline` private state).
**Critical ordering constraint (D-03):** The new `RequireToken` clause must be ordered **before** the pass-through clause AND must NOT match error-carrying tokens. The cleanest shape is a guard on the same struct head as the pass-through:

```elixir
# Source: synthesized from require_token.ex:19-36 + verified reconciliation analysis
def call(conn, _opts) do
  case conn.assigns[:access_token] do
    # D-03: bound token that reached RequireToken unverified → fail-closed.
    # MUST be gated on error: nil so it never intercepts tokens that already
    # failed in VerifyToken (those go to the structured/invalid clauses below).
    %AccessToken{error: nil, binding_requirements: req, binding_verified: false}
    when not is_nil(req) ->
      handle_structured_error(conn, sender_constraint_bypass_error(req))   # → 403

    %AccessToken{error: nil, claims: claims} when not is_nil(claims) ->
      conn                                                                 # unchanged pass-through

    # ... existing error clauses unchanged ...
  end
end
```

The bypass error map should carry `category: :sender_constraint` and a binding-derived `challenge:` (DPoP-bound → `:dpop`; mTLS-bound → `:bearer`) so it routes through the existing `handle_structured_error/2 → handle_invalid_token/2` path and emits a coherent `WWW-Authenticate` (Integration Point with Phase 98's challenge taxonomy). **Status note:** D-03 specifies `403` for the bound-but-unverified case; the existing `handle_invalid_token/2` sends `401`. The planner must add a `403`-status path (mirror `handle_insufficient_scope/2` which already sends 403) or set status explicitly — this is a Claude's-Discretion shape detail but the 403 vs 401 distinction is load-bearing per D-03 and BIND-03 success criterion 3.

### Anti-Patterns to Avoid
- **Hand-signing the BIND-01/02 JWT with `JOSE.JWT.sign`** (what phase81 does). This proves only the plug chain, not Phase 99's `cnf` carry-through. D-07 forbids it.
- **Writing the D-03 guard to match `binding_requirements != nil` regardless of `error`.** This would intercept the `verify_token_test.exs:947-1037` error-carrying bound tokens and change their challenge/status — breaking passing tests and conflating "bound token failed verification" with "bound token skipped enforcement." Gate on `error: nil`.
- **Clearing `binding_requirements` as the verified signal** (D-04 forbids). The host controller reads it.
- **Driving a full DB-backed token-endpoint exchange** to obtain the bound token (D-09 forbids — heavier than the proof needs).
- **Omitting the `:sys.get_state(KeyCache)` synchronization** after `send(KeyCache, :refresh)` — the refresh is async; the sync read is required before signing/verifying (Pitfall 2).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DPoP proof signing for the test | Custom JWS proof builder | `JarTestHelpers.sign_dpop_proof/2` + `generate_dpop_proof/3` (lift from phase81) | Gets `htm`/`htu`/`iat`/`jti`/`ath`/`nonce` shape right; matches what `ProtectedResourceDPoP` validates |
| `jkt` thumbprint | Manual SHA-256 of JWK | `DPoP.thumbprint/1` | Canonical JWK thumbprint per RFC 7638 |
| `x5t#S256` thumbprint | Manual SHA-256 of cert | `MTLSTokenBinding.thumbprint/1` | The exact function `confirmation_matches?/2` reverses; keeps both sides in agreement |
| `at+jwt` minting with `cnf` | Hand-built `JOSE.JWT.sign` | `AccessTokenSigner.issue/3` | The thing under proof (Phase 99 carry-through); hand-signing defeats the proof's purpose |
| Canonical-pipeline extraction (D-05) | New regex/parse path | `extract_canonical_pipeline!/2` + the four-file `{path, kind}` iteration | Reuses Phase 97/98 machinery; a parallel path would drift from the content-hash invariant |
| Key publish + cache refresh | New cache primitive | `Repository.publish_key/1` + `send(KeyCache, :refresh)` + `:sys.get_state/1` | The established publish-then-sign recipe (`verify_token_test.exs:39-91`, phase81) |
| Sender-constraint WWW-Authenticate emission (D-03 guard) | New challenge formatter | `RequireToken.handle_structured_error/2` + `ProtectedResourceChallenge.put_dpop_challenge/3` | Existing path already emits DPoP/Bearer challenges with `algs=`; reuse keeps the Phase 98 taxonomy coherent |

**Key insight:** Every primitive this phase needs already exists and is tested. The phase is composition + one new field + one new guard clause + assertions — not new protocol code.

## Runtime State Inventory

> Phase 100 is **not** a rename/refactor/migration phase — it adds a struct field, two plug edits, and tests. No stored runtime state, OS registrations, or external service config carries a renamed string. The one persistence-adjacent concern is the test-only signing key.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified. The new `binding_verified` field lives only on the in-flight `%AccessToken{}` plug struct, never persisted. `%Lockspire.AccessToken{}` has no Ecto schema; it is a transient pipeline value. | none |
| Live service config | None — verified. No n8n/Datadog/Tailscale-style external config. The only "live config" is `Application.put_env(:lockspire, ...)` set in test `setup_all` (issuer, repo, scopes) — test-scoped, not durable. | none |
| OS-registered state | None — verified. No Task Scheduler/launchd/systemd/pm2 registrations touch this phase. | none |
| Secrets/env vars | None — verified. The test signing key is generated in-process (`JOSE.JWK.generate_key`) and published to the sandboxed `TestRepo`; no SOPS/.env keys are added or renamed. | none |
| Build artifacts | None — verified. No `pyproject.toml`/`mix.exs` name change; `mix compile` is green at baseline (verified). Adding a struct field recompiles `access_token.ex` and its dependents automatically. | none |

## Common Pitfalls

### Pitfall 1: The DPoP nonce-retry dance is mandatory for BIND-01
**What goes wrong:** A BIND-01 test that sends a single DPoP proof (no nonce) and expects `200` will get `401 use_dpop_nonce` instead.
**Why it happens:** `ProtectedResourceDPoP.validate_proof` runs with `nonce_purpose: :resource_server` (`protected_resource_dpop.ex:80`); the resource-server nonce is required. First proof without a nonce → `{:error, :missing_dpop_nonce}` → `use_dpop_nonce_error` (`protected_resource_dpop.ex:87-88,321-329`).
**How to avoid:** Reproduce the exact three-request shape from `phase81_...e2e_test.exs:165-206` — (1) proof without nonce → assert `401`/`use_dpop_nonce` + extract `DPoP-Nonce`; (2) build a new proof embedding that nonce; (3) re-request → `200`.
**Warning signs:** `401` with `error="use_dpop_nonce"` on what should be the success request.

### Pitfall 2: KeyCache refresh is asynchronous
**What goes wrong:** Sign/verify happens before KeyCache has the new key; `VerifyToken` returns unknown-kid `invalid_token`.
**Why it happens:** `send(KeyCache, :refresh)` is a cast; the cache reloads in a `handle_info` (`key_cache.ex:44`). Without a synchronous follow-up the test races the refresh.
**How to avoid:** Always follow `send(KeyCache, :refresh)` with `:sys.get_state(KeyCache)` (a synchronous call that blocks until the refresh message is processed) — exactly as phase81 (`:257-283`) and `verify_token_test.exs:56-57` do.
**Warning signs:** Flaky `invalid_token` / unknown-kid failures that pass on re-run.

### Pitfall 3: `htu`/`target_uri` and host/port must match across proof and request
**What goes wrong:** DPoP `htu` mismatch → `invalid_dpop_htu` or replay-key/target mismatch.
**Why it happens:** `EnforceSenderConstraints.request_target_uri/1` reconstructs the URI from `conn.scheme/host/port/request_path/query_string` (`enforce_sender_constraints.ex:161-172`). The proof's `htu` must equal this. phase81 fixes `host: "api.example.test", port: 80` on the conn and uses `@protected_target_uri "http://api.example.test/api/billing/summary"` in the proof.
**How to avoid:** Use the phase81 `protected_conn/0` (host/port pin) and the same `@protected_target_uri` constant in `generate_dpop_proof/3`.
**Warning signs:** `invalid_dpop_htu` / `dpop_binding_mismatch` reason codes.

### Pitfall 4: D-03 guard must not break the existing bound-token error tests
**What goes wrong:** A too-broad guard (matching any `binding_requirements != nil`) intercepts the `verify_token_test.exs:947-1037` tokens (DPoP/mTLS-bound tokens that *fail* audience/scope/typ in VerifyToken) and changes their status/challenge, turning green tests red.
**Why it happens:** Those tokens carry `binding_requirements` (from `cnf`) AND `error != nil`. A guard not gated on `error: nil` would catch them.
**How to avoid:** Gate the D-03 clause on `error: nil` (it should fire only for tokens that would otherwise pass through). Verified: with that gate, **zero** existing tests newly fail-closed. See "State of the Art / reconciliation analysis."
**Warning signs:** `verify_token_test.exs` "challenge derivation from binding" describe block goes red.

### Pitfall 5: The struct-defaults test asserts "all fields default to nil"
**What goes wrong:** Adding `binding_verified: false` (not nil) leaves `access_token_test.exs:7-19` incomplete (the test enumerates fields but does not assert the new one); a future "exhaustive defaults" expectation could drift.
**Why it happens:** D-01 deliberately uses a non-nil fail-closed default.
**How to avoid:** Update `access_token_test.exs` to add `assert token.binding_verified == false` in the defaults test (an additive, expected change — reconcile, do not work around). This is the ONLY existing test that *must* change for D-01.
**Warning signs:** A reviewer noting the defaults test no longer enumerates all fields.

### Pitfall 6: Signer `aud` is a list; the route audience option is a string
**What goes wrong:** `AccessTokenSigner` emits `aud => ["billing-api"]` (list, from `token.audience`). phase81's hand-signed bearer test used a string `aud`. If the VerifyToken audience matcher only accepted a string, BIND-01/02 would fail audience.
**Why it happens:** D-07's switch from hand-signed (string aud) to signer (list aud) changes the `aud` wire shape.
**How to avoid:** Confirm the VerifyToken audience matcher accepts list `aud` (RFC 9068 `aud` is a list-or-string per RFC 7519). If it does (expected — Phase 98 hardened this), pass `audience: "billing-api"` on the plug and `audience: ["billing-api"]` on the `%Token{}`. The planner should add a Wave-0 check that the matcher handles list `aud`, since the existing phase81 happy-path used string `aud`.
**Warning signs:** `invalid_audience` on a token whose `aud` list contains the expected value.

## Code Examples

### BIND-02 mTLS happy-path assembly (synthetic cert)
```elixir
# Source: enforce_sender_constraints_test.exs:192-216 (cert pattern, verified live)
#         + mtls_token_binding.ex:7-17 (thumbprint) + D-08
cert = "phase100-mtls-client-cert"
{:ok, x5t} = Lockspire.Protocol.MTLSTokenBinding.thumbprint(cert)

token = %Lockspire.Domain.Token{
  token_hash: "unused", token_type: :access_token,
  client_id: "generated-host-api-client", account_id: "generated-host-user",
  scopes: ["read:billing"], audience: ["billing-api"],
  cnf: %{"x5t#S256" => x5t},
  issued_at: DateTime.utc_now(),
  expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
}
{:ok, raw, _} = AccessTokenSigner.issue(token, client, request)

conn =
  protected_conn()
  |> put_req_header("authorization", "Bearer #{raw}")
  |> Plug.Conn.put_private(:lockspire_mtls_cert, cert)   # primary fetch_mtls_cert path
  |> get(@protected_route)

assert conn.status == 200
assert %{"access_token" => %{"binding_type" => "mtls"}} = Jason.decode!(conn.resp_body)
```

### BIND-03 negative + bearer-still-passes (plug layer, D-10)
```elixir
# Source: synthesized from require_token_test.exs + D-03 disambiguator
# Bound-but-unverified → fail-closed 403 (the bypass closure proof)
bound = %AccessToken{error: nil, claims: %{"sub" => "u"},
                     binding_requirements: %{dpop_jkt: "x"}, binding_verified: false}
conn = conn(:get, "/") |> assign(:access_token, bound) |> RequireToken.call([])
assert conn.status == 403 and conn.halted

# Bearer (unbound) → still passes (the surprise-free guarantee)
bearer = %AccessToken{error: nil, claims: %{"sub" => "u"}, binding_requirements: nil}
conn = conn(:get, "/") |> assign(:access_token, bearer) |> RequireToken.call([])
refute conn.halted
```

### D-05 contract ordering clause (reusing existing extraction)
```elixir
# Source: release_readiness_contract_test.exs:140-157,761-791 (verified live)
test "all four RECIPE-01 sites order VerifyToken → EnforceSenderConstraints → RequireToken (BIND-03)" do
  files = [
    {@protect_phoenix_api_routes_path, :elixir_in_markdown_fence},
    {@adoption_demo_router_path, :elixir},
    {@install_template_router_path, :elixir_in_commented_heredoc},
    {@adoption_smoke_script_path, :python_commented}
  ]

  for {path, kind} <- files do
    bytes = extract_canonical_pipeline!(path, kind)
    v = byte_offset(bytes, "Lockspire.Plug.VerifyToken")
    e = byte_offset(bytes, "Lockspire.Plug.EnforceSenderConstraints")
    r = byte_offset(bytes, "Lockspire.Plug.RequireToken")
    assert v < e and e < r,
           "canonical pipeline in #{Path.relative_to_cwd(path)} must order Verify→Enforce→Require"
  end
end
```

## State of the Art / Reconciliation Analysis

> This section documents the verified resolution of CONTEXT.md's flagged behavior-change risk — the single most important planning input.

| Concern (CONTEXT.md) | Verified Reality | Impact |
|----------------------|------------------|--------|
| "Any pre-existing test that ran a bound token through `VerifyToken → RequireToken` *without* `EnforceSenderConstraints` will newly fail-closed." | The only such call sites are `verify_token_test.exs:947-1037` (the "challenge derivation from binding" block). **All** of them inject a deliberate VerifyToken failure (wrong `aud`/`scope`/`typ`), so the token carries `error != nil` at `RequireToken` and hits the error clauses, never the guarded pass-through. | **No existing test newly fail-closes** — provided the D-03 guard is gated on `error: nil`. Reconciliation is far smaller than feared. |
| Struct-shape tests | `access_token_test.exs:7-19` ("defaults all fields to nil") enumerates the 7 fields; D-01 adds an 8th defaulting to `false`. | **One additive test update** (add `binding_verified == false` assertion). Expected, planned, not a workaround. |
| Other `%AccessToken{}` construction sites | Only `verify_token.ex` constructs and `enforce_sender_constraints.ex` updates the pipeline struct; all literal constructions inherit the new default safely. (Other `AccessToken` grep hits are unrelated `InitialAccessToken`/`RegistrationAccessToken` modules.) | No silent breaks from the new field. |
| `require_token_test.exs` | Its only pass-through test (`:14-22`) uses `binding_requirements: nil` → guard does not fire. | **Unaffected.** |
| FAPI / device-flow e2e | Matched the `cnf` grep but do NOT use the RS plug pipeline (token-endpoint issuance only). | **Unaffected.** |

**Deprecated/outdated in CONTEXT.md (minor anchor drift — none material):**
- `confirmation_matches?/2` cited at `mtls_token_binding.ex:22-27`; actual `22-29` (fallthrough clause at 29).
- `require_token.ex:20-35` cited for call clauses; actual `19-36` (the `case` opens at 19).
- Otherwise every cited anchor matches.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The VerifyToken audience matcher accepts a **list** `aud` (the signer emits `["billing-api"]`, while phase81's hand-signed happy path used a string `aud`). | Pitfall 6, Pattern 1 | If the matcher only accepts a string, BIND-01/02 fail `invalid_audience`. Planner should add a Wave-0 assertion that a list-`aud` token passes the audience check; if not, mint with a string `aud` or pass `audiences:`. Phase 98 hardening makes list-aud acceptance very likely. |
| A2 | `AccessTokenSigner.issue/3` works in the integration test with `opts[:key_store]` defaulting to `Config.repo!()` (= `TestRepo`) and the published `:active` key, without a `server_policy_store` (format falls back to `:jwt`). | Pattern 1, D-09 | If `resolve_format` needs a server policy store present, the test must supply a `MockServerPolicyStore` (`access_token_signer_test.exs:48-52`). Low risk — `resolve_format(%Client{access_token_format: nil}, nil) -> :jwt` is the verified default (`access_token_signer.ex:98`). |
| A3 | D-03's required `403` status is achievable by adding a 403 path mirroring `handle_insufficient_scope/2` (which already sends 403), rather than the 401 of `handle_invalid_token/2`. | Pattern 3 | If the planner reuses `handle_invalid_token/2` verbatim, the guard emits 401 not 403. BIND-03 success criterion 3 accepts "403/401" so either is spec-acceptable, but D-03 says 403 — planner should make status explicit. |
| A4 | The `%Token{}` minimal fields needed by `issue/3` are `account_id` (→sub), `scopes`, `audience`, `cnf`, `issued_at` plus the no-default struct keys (`token_hash`, `token_type`, `client_id`, `expires_at`). | Pattern 1 | If `base_claims/3` reads a field not set, mint raises. Verified `base_claims/3` reads exactly `account_id`, `scopes`, `audience` (via caller), `cnf`, `issued_at` (`access_token_signer.ex:130-145`). Low risk. |

## Open Questions (RESOLVED)

> Both questions carry an evidence-backed recommendation and are wired into executable tasks; neither blocks planning. Resolutions actioned in the Phase 100 plans.

1. **List vs string `aud` acceptance in `VerifyToken` (A1).**
   - What we know: Signer emits list `aud`; phase81 happy path used string `aud`; RFC 9068/7519 allow both.
   - What's unclear: Whether the live audience matcher accepts a list without extra config.
   - Recommendation: Wave-0 quick check (one assertion minting a list-aud token through VerifyToken with `audience:` set). If it fails, the BIND-01/02 tokens use a single-element list that the matcher must unwrap — escalate to the planner as a tiny prerequisite, not a blocker.
   - **RESOLVED:** wired into Plan 100-02 Task 2 as a Wave-0 spike with explicit escalation-not-workaround handling; Plan 100-03 (BIND-01/02) depends on 100-02.

2. **403 vs 401 for the D-03 guard.**
   - What we know: D-03 says 403; success criterion 3 says "403/401".
   - What's unclear: Whether `handle_structured_error` should be extended with a 403 sender-constraint path or reuse the 401 path.
   - Recommendation: Follow D-03 (403); add a status-explicit path mirroring `handle_insufficient_scope/2`. Claude's-Discretion per CONTEXT.md.
   - **RESOLVED:** wired into Plan 100-01 Task 3 — an explicit 403 path modeled on `handle_insufficient_scope/2` (confirmed to emit 403), not inheriting the 401 of `handle_invalid_token/2`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All work | ✓ | 1.19.5 | — |
| Erlang/OTP | All work | ✓ | 28 (erts 16.3) | — |
| Postgres / `TestRepo` (Ecto SQL Sandbox) | Integration test (key publish, KeyCache) | ✓ (used by phase81 today) | via `ecto_sql ~> 3.13.5` | — |
| `mix test.setup` (`lockspire.test.setup`) | DB setup before integration tests | ✓ (alias in `mix.exs:67`) | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

**Test commands (verified against `mix.exs` aliases + `test_helper.exs` exclusion logic):**
- Integration tests are **excluded by default** (`ExUnit.start(exclude: [integration: true])`), included when: an explicit `.exs` target is given, `--include integration`, or `--only integration`.
- Run the new phase100 e2e: `mix test.setup && mix test --include integration test/integration/phase100_sender_constraint_e2e_test.exs` (or add a `test.phase100.e2e` alias mirroring the existing `test.phase30.e2e` pattern at `mix.exs:79-80`).
- Run the full integration suite: `mix test.integration`.
- Run the plug-unit + contract tests (default, non-integration): `mix test test/lockspire/plug/require_token_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/access_token_test.exs test/lockspire/release_readiness_contract_test.exs`.

## Validation Architecture

> nyquist_validation is **enabled** (`config.json: workflow.nyquist_validation = true`). This section gates VALIDATION.md / Nyquist Dimension 8.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 stdlib) |
| Config file | none — convention-based; `test/test_helper.exs` controls `:integration` exclusion |
| Quick run command (per task) | `mix test <changed test file(s)>` (e.g. `mix test test/lockspire/plug/require_token_test.exs`) |
| Full suite command (per wave / phase gate) | `mix test.setup && mix test --include integration` (full incl. integration) |

### Phase Requirements → Test Map
| Req ID | Observable signal that proves it | Test Type | Automated Command | File Exists? |
|--------|----------------------------------|-----------|-------------------|-------------|
| **BIND-01** | DPoP-bound `at+jwt` minted by `AccessTokenSigner.issue/3` → real 3-plug endpoint → nonce dance → `200` with `conn.assigns.access_token` populated AND `binding_type: "dpop"` AND `binding_requirements: %{dpop_jkt: jkt}` | integration | `mix test --include integration test/integration/phase100_sender_constraint_e2e_test.exs:<dpop_line>` | ❌ Wave 0 (new file) |
| **BIND-02** | mTLS-bound `at+jwt` minted by `issue/3` (cnf `x5t#S256`) → endpoint with `conn.private[:lockspire_mtls_cert]` matching cert → `200` with `binding_type: "mtls"` | integration | `mix test --include integration test/integration/phase100_sender_constraint_e2e_test.exs:<mtls_line>` | ❌ Wave 0 (new file) |
| **BIND-03 (runtime negative)** | Bound token (`binding_requirements != nil`, `binding_verified: false`, `error: nil`) → `RequireToken` → `403` halted, sender-constraint error | plug-unit | `mix test test/lockspire/plug/require_token_test.exs:<neg_line>` | ❌ Wave 0 (new test) |
| **BIND-03 (bearer-still-passes)** | Bearer token (`binding_requirements: nil`) → `RequireToken` → not halted, passes through (surprise-free guarantee) | plug-unit | `mix test test/lockspire/plug/require_token_test.exs:<bearer_line>` | ❌ Wave 0 (new test) |
| **BIND-03 (positive set)** | `EnforceSenderConstraints` success path → `access_token.binding_verified == true` | plug-unit | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs:<verified_line>` | ❌ Wave 0 (new assertions) |
| **BIND-03 (contract ordering)** | All four RECIPE-01 sites order Verify→Enforce→Require | contract | `mix test test/lockspire/release_readiness_contract_test.exs:<ordering_line>` | ❌ Wave 0 (new clause; satisfied by current content) |
| **BIND-03 (struct default)** | `%AccessToken{}.binding_verified == false` | unit | `mix test test/lockspire/access_token_test.exs` | ✅ (update existing defaults test) |

### Faithful-vs-Shallow proof criteria (the anti-cheat lens)
| Req | Shallow (rejected) | Faithful (required) |
|-----|--------------------|---------------------|
| BIND-01 | Hand-sign the JWT with `JOSE.JWT.sign` (proves only the plug chain) | Mint via `AccessTokenSigner.issue/3` from a `%Token{cnf: %{"jkt" => jkt}}` (D-07) so the proof exercises Phase 99's `maybe_put_cnf/2`; run the full nonce-retry dance against the real endpoint |
| BIND-01 | Skip the nonce dance / stub the replay store to bypass DPoP validation | Use the wired `ProtectedApiReplayStore` and perform the genuine `use_dpop_nonce` → retry → 200 sequence |
| BIND-02 | Assert only that the plug doesn't error | Assert `200` at the controller AND `binding_type: "mtls"`, with the token's `x5t#S256` derived from the SAME cert string presented via `conn.private` |
| BIND-03 negative | Assert the guard fires for ANY bound token | Assert it fires ONLY for `error: nil, binding_requirements != nil, binding_verified: false` (403) AND that a bearer token still passes (no false-positive surface) |
| BIND-03 contract | A regex that would pass even if order were wrong | Offset/regex assertion that genuinely fails if Enforce/Require are transposed in any of the four files |

### Sampling Rate
- **Per task commit:** the quick run for the file(s) touched by that task (e.g. `mix test test/lockspire/plug/require_token_test.exs`).
- **Per wave merge:** `mix test` (full default suite, non-integration) + the phase100 integration file via `--include integration`.
- **Phase gate:** `mix test.setup && mix test --include integration` fully green, plus `mix compile --warnings-as-errors` (project runs credo/dialyzer/sobelow in CI — keep clean) before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `test/integration/phase100_sender_constraint_e2e_test.exs` — NEW; covers BIND-01 + BIND-02 (lift phase81 harness + key-publish helper).
- [ ] `test/lockspire/plug/require_token_test.exs` — ADD bound-but-unverified→403 and bearer→pass clauses (BIND-03 runtime).
- [ ] `test/lockspire/plug/enforce_sender_constraints_test.exs` — ADD `binding_verified: true` assertions on the existing success-path tests (BIND-03 positive).
- [ ] `test/lockspire/access_token_test.exs` — UPDATE defaults test to assert `binding_verified == false` (D-01).
- [ ] `test/lockspire/release_readiness_contract_test.exs` — ADD ordering clause (D-05; passes against current content).
- [ ] (Optional) `mix.exs` — add `test.phase100.e2e` alias mirroring `test.phase30.e2e`.
- [ ] (Wave-0 spike, A1) Quick assertion that a list-`aud` token passes `VerifyToken` audience check.
- Framework install: none — ExUnit is built-in; `mix test.setup` already exists.

## Security Domain

> `security_enforcement` is not set in `config.json` → treated as **enabled**. Phase 100 is itself a security-hardening proof (closing a sender-constraint bypass class), so this section is load-bearing.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control (already in codebase) |
|---------------|---------|----------------------------------------|
| V2 Authentication | yes | RFC 9068 `at+jwt` bearer auth via `VerifyToken` (Phase 98-hardened). Phase 100 proves bound-token auth end-to-end. |
| V3 Session Management | no | Token-based, stateless RS; no server sessions on the protected route. |
| V4 Access Control | partial | Scope/audience checks in `VerifyToken`; host owns business authz (DOCS-02 non-goal). The D-03 guard is an access-control fail-closed gate. |
| V5 Input Validation | yes | JWT structural validation, DPoP proof claim validation, cert thumbprint matching — all via existing primitives. |
| V6 Cryptography | yes | RS256/ES256/PS256 signing via `jose` (`AccessTokenSigner`), SHA-256 thumbprints (`DPoP.thumbprint`, `MTLSTokenBinding.thumbprint`). Never hand-rolled. |
| V9 Communication / token binding | yes | **Core of the phase.** DPoP (RFC 9449) proof-of-possession + mTLS (RFC 8705) cert binding. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation | Phase 100 relevance |
|---------|--------|---------------------|---------------------|
| Sender-constrained token used as bearer (no proof) | Spoofing / Elevation | RFC 9449 §7.2 MUST-reject; `EnforceSenderConstraints` + the D-03 fail-closed guard | **The bypass BIND-03 closes.** CVE-2024-49755 (Duende IdentityServer) is this exact class — insufficient `cnf` enforcement. The runtime guard prevents shipping the precondition to adopters who misorder the pipeline. |
| DPoP proof replay | Tampering / Repudiation | `ath` binding + replay store + nonce | Exercised end-to-end in BIND-01 via `ProtectedResourceDPoP.validate_access` (nonce dance + `ProtectedApiReplayStore`). |
| DPoP proof for a different token (`ath` mismatch) | Tampering | `validate_ath` (`protected_resource_dpop.ex:96-109`) | The faithful BIND-01 proof must use `DPoP.access_token_ath(raw_at_jwt)` on the actual minted token. |
| Cross-API token reuse (wrong audience) | Elevation | `enforce_audience: true` + `audience:` (Phase 98 VERIFIER-06) | The pipeline already declares `audience: "billing-api"`; BIND-01/02 tokens must target it (Pitfall 6). |
| `alg: none` / client-controlled signing | Tampering | `AccessTokenSigner` takes `alg`/`kid` ONLY from the active key, never client input (`access_token_signer.ex:26-29,165-177`) | Issuance fixture inherits this guarantee. |

## Sources

### Primary (HIGH confidence — verified in this session against the live tree)
- `lib/lockspire/access_token.ex` (7-field struct, D-01 target) — read in full
- `lib/lockspire/plug/require_token.ex` (call clauses :19-36, structured-error path, D-03 target) — read in full
- `lib/lockspire/plug/enforce_sender_constraints.ex` (success paths :67-78,111-128; `fetch_mtls_cert/2` :178-189, D-02 target) — read in full
- `lib/lockspire/plug/verify_token.ex` (`binding_requirements/1` :528-537, `binding_type/1` :467-479, struct set :128-135, `fetch_key/1 → KeyCache` :576-577) — read relevant sections
- `lib/lockspire/protocol/access_token_signer.ex` (`issue/3` :55-66, `base_claims/3` + `maybe_put_cnf/2` :130-148, `fetch_signing_key` :196-216) — read in full
- `lib/lockspire/protocol/mtls_token_binding.ex` (`thumbprint/1` :7-17, `confirmation_matches?/2` :22-29) — read in full
- `lib/lockspire/protocol/protected_resource_dpop.ex` (`validate_access/2`, nonce path, `expected_jkt/1` :257-265) — read in full
- `lib/lockspire/protocol/dpop.ex` (`thumbprint`, `access_token_ath/1` :57-62) — read relevant sections
- `lib/lockspire/domain/token.ex` (`cnf` field :53, `audience`/`scopes` defaults) — read in full
- `lib/lockspire/storage/ecto/repository.ex` (`fetch_active_signing_key/1` :1064-1077) — read relevant sections
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` (the harness BIND-01 lifts; hand-signs today :285-303; nonce dance :150-215; key publish :257-283) — read in full
- `test/support/generated_host_app_web/router.ex` (canonical 3-plug chain :19-27) — read in full
- `test/support/generated_host_app_web/controllers/protected_api_controller.ex` (surfaces `binding_type`/`binding_requirements`; `ProtectedApiReplayStore`) — read in full
- `test/lockspire/plug/enforce_sender_constraints_test.exs` (`dpop_fixture/2` :279-311, mTLS `put_private` pattern :192-234) — read relevant sections
- `test/lockspire/plug/verify_token_test.exs` (KeyCache recipe :39-91; bound-token-through-RequireToken reconciliation block :947-1037,1133-1167) — read relevant sections
- `test/lockspire/plug/require_token_test.exs` (all clauses; pass-through is unbound) — read in full
- `test/lockspire/protocol/access_token_signer_test.exs` (`MockKeyStore` :21-31, cnf carry-through :247-256) — read relevant sections
- `test/lockspire/access_token_test.exs` (struct-defaults test :7-19, D-01 update target) — read in full
- `test/lockspire/release_readiness_contract_test.exs` (`extract_canonical_pipeline!/2` :140-157, audience clause template :761-791) — read relevant sections
- The four RECIPE-01 canonical blocks (`docs/protect-phoenix-api-routes.md:16-23`, `examples/adoption_demo/.../router.ex:23-30`, `priv/templates/lockspire.install/router.ex:11-18`, `scripts/demo/adoption_smoke.py:244-251`) — all verified ordered Verify→Enforce→Require
- `mix.exs` (deps, test aliases), `test/test_helper.exs` (integration exclusion) — read relevant sections
- `mix compile` — clean (green baseline confirmed)
- `.planning/100-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` — read in full

### Secondary (MEDIUM — cited standards / corpus, not re-verified online this session)
- RFC 9449 §7.1/§7.2 (DPoP at the RS; §7.2 MUST-reject) — the normative basis for the D-03 guard (per CONTEXT.md canonical_refs; consistent with the live `ProtectedResourceDPoP` behavior)
- RFC 8705 §3 (mTLS `x5t#S256` confirmation) — consistent with `MTLSTokenBinding`
- CVE-2024-49755 (Duende IdentityServer insufficient `cnf` enforcement) — cited in CONTEXT.md as the bypass-class precedent

### Tertiary (LOW — none)
- No unverified WebSearch claims were relied upon; this phase is fully grounded in the live codebase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all deps in `mix.exs`, no new packages, baseline compiles green.
- Architecture / anchors: HIGH — every cited `file:line` verified against the live tree; drift is cosmetic.
- Reconciliation risk (the key planning input): HIGH — exhaustive search of every `VerifyToken→RequireToken`-without-Enforce call site confirms no bound success-path test exists; only one additive struct-test update needed.
- Pitfalls: HIGH — derived from reading the actual DPoP/KeyCache/audience code paths, not training assumptions.
- Open questions (A1 list-aud, A3 403 status): MEDIUM — flagged for a tiny Wave-0 spike; neither blocks planning.

**Research date:** 2026-05-28
**Valid until:** 2026-06-27 (stable internal codebase; re-verify anchors only if `lib/lockspire/plug/*` or `access_token_signer.ex` change before execution)
