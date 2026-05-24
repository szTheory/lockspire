# Phase 72: JARM Encryption & Metadata - Research

**Researched:** 2026-05-07 [VERIFIED: repo read]  
**Domain:** JARM nested JWE authorization responses, guarded client-key resolution, and truthful discovery metadata in Lockspire's Phoenix/Elixir protocol layer. [VERIFIED: repo read]  
**Confidence:** HIGH [VERIFIED: repo read]

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/72-jarm-encryption-and-metadata/72-CONTEXT.md`. [VERIFIED: repo read]

### Locked Decisions

### Decisioning posture

- **D-01:** Downstream work for this phase should default to recommendation-heavy, coherent decisions rather than broad option menus. Shift this preference left within GSD for this project: escalate only when a choice materially changes public API shape, embedded-library boundaries, protocol/security guarantees, or long-lived support posture.

### Encryption key source

- **D-02:** Support both inline `jwks` and guarded remote `jwks_uri` for JARM encryption in Phase 72.
- **D-03:** Preserve Lockspire's existing xor client-metadata rule: a client may configure `jwks` or `jwks_uri`, never both.
- **D-04:** Keep remote key resolution Lockspire-owned by reusing the guarded `Lockspire.JwksFetcher` seam rather than pushing any fetch, cache, or SSRF policy onto the host app.
- **D-05:** Client encryption-key selection should stay explicit and unsurprising: prefer `use=enc` when present, respect matching `kid` when supplied, and require algorithm/key-shape compatibility for the requested JWE `alg`.

### Failure behavior

- **D-06:** When encrypted JARM is effectively requested, Lockspire may attempt a narrow bounded recovery path, but it must never silently downgrade to signed-only JARM or raw query/fragment parameters.
- **D-07:** The bounded recovery path may reuse safe local or cached key material and one guarded refresh attempt for `jwks_uri`, but it must not introduce retry loops or unbounded redirect-path network work.
- **D-08:** If no safe usable encryption key can be resolved, fail closed and surface an AS-side/browser-visible error rather than weakening the response contract.
- **D-09:** Detailed failure reasons belong to telemetry, tests, and internal reason taxonomy; the external behavior should remain least-surprising and non-leaky.

### Discovery metadata truth

- **D-10:** Publish JARM encryption metadata from one shared authorization-response capability source derived from the mounted authorization surface and effective issuer crypto posture.
- **D-11:** Do not hard-code JARM encryption metadata as compile-time feature marketing, and do not derive it from transient conditions such as current client registrations, remote JWKS reachability, or momentary key-fetch health.
- **D-12:** Discovery should advertise stable issuer-wide capability for properly configured clients, not per-client state and not operational-health state.
- **D-13:** Signing and encryption response metadata should stay coupled so clients see one coherent JARM capability story instead of split publication paths.

### Algorithm surface

- **D-14:** Keep the Phase 72 JARM encryption surface intentionally narrower than the broader inbound request-object JWE allow-list from Phase 40.
- **D-15:** Recommended JWE `alg` support for JARM encryption is `RSA-OAEP-256` and `ECDH-ES`.
- **D-16:** Recommended JWE `enc` support for JARM encryption is `A256GCM` and `A128GCM`.
- **D-17:** Do not silently inherit the JARM spec default `A128CBC-HS256`; require explicit encryption metadata and keep CBC modes out of the shipped Phase 72 response-encryption surface.
- **D-18:** Encrypted JARM remains nested JWT only: signing is mandatory first, encryption is opt-in second, and encryption configuration without a signing algorithm is invalid.

### Architecture and DX posture

- **D-19:** Keep the implementation centered on explicit protocol helpers and pure transformations, not magical Plugs that mutate redirect behavior invisibly.
- **D-20:** Preserve a single coherent client-crypto story across Lockspire surfaces where possible: registration metadata, guarded `jwks_uri` semantics, and discovery truth should work the same way for JARM as they already do for `private_key_jwt`.
- **D-21:** Great DX for this phase means operators and relying parties can reason about one simple rule set: explicit client metadata enables encrypted JARM, discovery tells the runtime truth, and failures are explicit rather than downgraded.

### Claude's Discretion

- Exact helper/module names for encryption-key resolution and JARM capability publication.
- Whether the bounded `jwks_uri` recovery path is expressed as a separate helper or an opt-in refresh flag on an existing resolution function.
- Exact internal reason-code taxonomy for encrypted-JARM failures, as long as external behavior stays fail-closed and non-leaky.

### Deferred Ideas (OUT OF SCOPE)

- Full algorithm parity with the broader Phase 40 request-object JWE surface, including CBC response-encryption modes
- Any second operator-configurable crypto-policy plane just for JARM encryption
- Discovery publication driven by transient health/readiness checks such as remote JWKS availability
- Silent downgrade from encrypted JARM to signed-only JARM
- FAPI 2.0 Message Signing strict enforcement, which remains Phase 74 scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JARM-03 | Support encrypting the signed authorization response (JWS nested in JWE). [VERIFIED: repo read] | Add durable client metadata for `authorization_encrypted_response_alg` / `authorization_encrypted_response_enc`, resolve client encryption keys from inline `jwks` or guarded `jwks_uri`, produce nested JWT only, fail closed on unusable keys, and publish one shared discovery capability source. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html] |
</phase_requirements>

## Summary

Phase 72 is not just a JOSE wrapper change. The repo already signs JARM responses in `Lockspire.Protocol.Jarm`, formats authorization redirects in `Lockspire.Protocol.AuthorizationFlow`, centralizes discovery truth in `Lockspire.Protocol.Discovery`, and proves one-bounded-refresh remote key resolution in `Lockspire.Protocol.ClientAuth.PrivateKeyJwt` plus `Lockspire.JwksFetcher`; however, the client domain, Ecto record, and registration/update plumbing do not yet carry `authorization_encrypted_response_alg` or `authorization_encrypted_response_enc`. [VERIFIED: repo read]

The implementation should therefore treat encrypted JARM as one coherent vertical slice: persist the client metadata, resolve a client public encryption key from inline `jwks` or guarded `jwks_uri`, sign first and then encrypt the compact JWS into a compact JWE, and fail closed if encryption was requested but no safe compatible key is usable. The JARM errata spec explicitly defines this as nested JWT behavior and introduces the exact discovery metadata names `authorization_encryption_alg_values_supported` and `authorization_encryption_enc_values_supported`. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]

The strongest repo-aligned shape is to collapse JARM response production behind one `Lockspire.Protocol.Jarm.encode/2` style entry point, reusing the existing `private_key_jwt` remote-JWKS resolution contract: cached lookup first, one guarded refresh on mismatch or stale `kid`, no retries beyond that, and no silent downgrade to signed-only or raw redirect parameters. Discovery should publish signing and encryption support from one authorization-response capability helper, just as prior phases centralized direct-client-auth truth in `Discovery`. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]

**Primary recommendation:** Plan this phase as three slices: `client metadata plumbing`, `nested-JARM encode + key resolution + failure taxonomy`, and `shared discovery capability publication + tests`. [VERIFIED: repo read]

## Recommended Plan Split

1. **Plan 72-01: Client metadata persistence and intake/update truth**. Add durable client/domain/Ecto support for `authorization_encrypted_response_alg` and `authorization_encrypted_response_enc`, enforce the locked coherence rules, and thread the fields through registration plus RFC 7592 update paths because the current repo persists `authorization_signed_response_alg` but not the encryption fields. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]
2. **Plan 72-02: Nested JARM encode path and client-key resolution**. Refactor `Lockspire.Protocol.Jarm` into the single encode boundary, resolve inline or guarded remote client encryption keys with one bounded refresh, enforce the narrow JWE allow-list, and return explicit fail-closed browser-safe errors when encryption was requested but cannot be completed. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html] [CITED: https://hexdocs.pm/jose/JOSE.JWT.html]
3. **Plan 72-03: Shared discovery capability source and verification**. Publish signing and encryption metadata from one shared helper tied to the mounted authorization surface and effective issuer posture, then extend JARM, discovery, JWKS fetcher, and authorization-flow coverage to prove no downgrade and no metadata/runtime drift. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persist JARM encryption client metadata | Database / Storage | API / Backend | The repo stores client cryptographic preferences in `Lockspire.Domain.Client` and `ClientRecord`, so the new encryption metadata belongs in durable client registration state rather than transient request logic. [VERIFIED: repo read] |
| Resolve client encryption keys (`jwks` / `jwks_uri`) | API / Backend | Database / Storage | The guarded remote fetcher, cache, and bounded refresh seam already live in Lockspire protocol/runtime code, while the registered metadata lives on the client record. [VERIFIED: repo read] |
| Produce nested JARM compact JWT/JWE | API / Backend | — | `AuthorizationFlow` already owns redirect shaping and `Jarm` already owns JARM signing, so the protocol layer should own sign-then-encrypt transformation before redirect formatting. [VERIFIED: repo read] |
| Publish authorization-response capability metadata | API / Backend | — | `Discovery` is the repo’s single truth publication seam for mounted capability and effective policy. [VERIFIED: repo read] |
| Browser-visible fail-closed behavior | API / Backend | Frontend Server (SSR) | Phoenix controllers and protocol structs already surface browser-safe OAuth/OIDC errors from backend protocol decisions; no host-side custom crypto UX should be required. [VERIFIED: repo read] |

## Standard Stack

Repo-pinned versions below are taken from `mix.lock` and `mix.exs`; they describe the stack this phase should extend, not a fresh “latest package” re-selection. [VERIFIED: repo read]

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `jose` | `1.11.12` | JWS/JWE signing, encryption, compaction, and strict verification primitives. [VERIFIED: repo read] | The repo already uses JOSE for request-object JWE, ID tokens, logout tokens, and JARM signing, so Phase 72 should stay on the same cryptographic primitive layer. [VERIFIED: repo read] [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] |
| `req` | `0.5.17` | Guarded remote `jwks_uri` HTTP retrieval. [VERIFIED: repo read] | `Lockspire.JwksFetcher` already enforces HTTPS, redirect refusal, timeouts, and body caps on top of `Req`, which matches the phase’s remote-key requirements. [VERIFIED: repo read] |
| `cachex` | `4.1.1` | JWKS caching and last-known-good reuse. [VERIFIED: repo read] | The existing fetcher already uses `Cachex.fetch/3` and `Cachex.put/4` to bound network work and preserve safe cached entries across refresh failures. [VERIFIED: repo read] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix` | `1.8.5` | Authorization redirect delivery and discovery endpoint mounting. [VERIFIED: repo read] | Use it only at the delivery seam; keep crypto and key-resolution policy in protocol modules, not controllers or Plugs. [VERIFIED: repo read] |
| `ecto_sql` | `3.13.5` | Durable client metadata persistence and test sandboxing. [VERIFIED: repo read] | Use it for the new client metadata fields and for repo-backed tests that prove end-to-end authorization behavior. [VERIFIED: repo read] |
| `ExUnit` via Elixir `~> 1.18` | repo runtime | Unit/integration verification lane. [VERIFIED: repo read] | Extend the existing targeted protocol tests and repo-backed sandbox tests instead of introducing a new test framework. [VERIFIED: repo read] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `JOSE.JWE.block_encrypt/3` over the compact JWS string | `JOSE.JWT.encrypt/3` on a JWT struct | `JOSE.JWT.encrypt/3` is fine for plain JWT input, but the repo already learned in request-object work that explicit block encrypt/decrypt over the nested compact value is the least surprising way to control nested JWT behavior. [VERIFIED: repo read] [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] |
| Shared `Lockspire.JwksFetcher` | Ad hoc Req calls in `AuthorizationFlow` or `Jarm` | Direct fetches would bypass the repo’s existing HTTPS, SSRF, redirect, timeout, and cache protections and would duplicate a solved boundary. [VERIFIED: repo read] |
| Shared authorization-response capability helper | Hard-coded discovery arrays | Static metadata would drift from mounted-surface truth, which prior discovery work explicitly treats as a bug. [VERIFIED: repo read] |

**Installation:** [VERIFIED: repo read]
```bash
mix deps.get
```

**Version verification:** `mix.exs` constrains `jose ~> 1.11`, `req ~> 0.5`, and `cachex ~> 4.0`, and `mix.lock` currently resolves them to `1.11.12`, `0.5.17`, and `4.1.1`. [VERIFIED: repo read]

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  -> /authorize request with JARM-capable client_id and response_mode
AuthorizationRequest / AuthorizationFlow
  -> load Client durable metadata
  -> decide: signed-only JARM or nested JARM?
  -> if nested JARM requested:
       -> Jarm.ClientKeyResolver
            -> inline jwks? use local key set
            -> jwks_uri? use JwksFetcher cache
            -> key mismatch / stale kid? one guarded refresh
            -> no compatible key? fail closed
       -> Jarm.encode
            -> fetch issuer signing key
            -> compact JWS
            -> compact JWE over JWS string
  -> format redirect / form_post with response=<jwt>
Discovery
  -> authorization_response_capabilities()
  -> publish response modes + signing algs + encryption algs/encs
```

The flow above matches current repo ownership: `AuthorizationFlow` owns redirect assembly, `Jarm` owns JARM creation, `JwksFetcher` owns guarded remote-key I/O, and `Discovery` owns metadata truth. [VERIFIED: repo read]

### Recommended Project Structure
```text
lib/
├── lockspire/protocol/jarm.ex                    # Single nested-JARM encode boundary
├── lockspire/protocol/jarm/client_key_resolver.ex # Inline/remote client enc-key selection
├── lockspire/protocol/discovery.ex               # Shared authorization-response capability publication
├── lockspire/protocol/registration*.ex           # Intake/update of new client metadata
└── lockspire/storage/ecto/client_record.ex       # Durable fields for response encryption metadata
```

This structure preserves the repo’s existing strong boundaries between protocol code, storage, and delivery seams. [VERIFIED: repo read]

### Pattern 1: Single JARM Encode Pipeline
**What:** Replace the current split where `AuthorizationFlow` fetches signing keys and `Jarm.sign/2` signs only, with one `Jarm.encode/2` path that decides signed-only versus signed-then-encrypted and returns the final compact value. [VERIFIED: repo read]  
**When to use:** Every authorization success or error path that resolves to a JARM response mode. [VERIFIED: repo read]  
**Example:**
```elixir
# Source: repo pattern + JOSE docs
with {:ok, signing_key} <- fetch_signing_key(client, opts),
     {:ok, claims} <- build_claims(params, issuer, client.client_id),
     {_, jws} <- JOSE.JWT.sign(signing_key, %{"alg" => alg, "kid" => kid, "typ" => "JWT"}, claims)
                  |> JOSE.JWS.compact(),
     {:ok, output} <- maybe_encrypt_jarm(jws, client, opts) do
  {:ok, output}
end
```
[VERIFIED: repo read] [CITED: https://hexdocs.pm/jose/JOSE.JWT.html]

### Pattern 2: Shared Client Encryption-Key Resolver
**What:** Mirror the proven `ClientAuth.PrivateKeyJwt` contract: inline `jwks` first, remote `jwks_uri` through `JwksFetcher`, one refresh on compatible failure, and stable reason mapping. [VERIFIED: repo read]  
**When to use:** Only when `authorization_encrypted_response_alg` and `authorization_encrypted_response_enc` are both effectively set. [CITED: https://openid.net/specs/oauth-v2-jarm.html]  
**Example:**
```elixir
# Source: repo key-resolution pattern
case resolve_client_enc_key(client, header_kid, requested_alg, opts) do
  {:ok, jwk, :inline_jwks} -> {:ok, jwk}
  {:ok, jwk, :jwks_uri} -> {:ok, jwk}
  {:error, :no_matching_key} -> {:error, :jarm_encryption_key_unavailable}
  {:error, :client_jwks_fetch_failed} -> {:error, :jarm_encryption_key_fetch_failed}
end
```
[VERIFIED: repo read]

### Pattern 3: One Shared Authorization-Response Capability Helper
**What:** Add a helper in `Discovery` that returns response modes plus signing and encryption metadata from the mounted authorization surface and effective issuer crypto posture. [VERIFIED: repo read]  
**When to use:** For both discovery publication and any future policy checks that need the same truth source. [VERIFIED: repo read]  
**Example:**
```elixir
# Source: repo discovery truth pattern
defp authorization_response_capabilities(endpoint_metadata) do
  if authorization_code_surface_mounted?(endpoint_metadata) do
    %{
      response_modes_supported: ["query", "fragment", "form_post", "jwt", "query.jwt", "fragment.jwt", "form_post.jwt"],
      authorization_signing_alg_values_supported: SecurityProfile.allowed_signing_algorithms(global_security_profile()),
      authorization_encryption_alg_values_supported: ["RSA-OAEP-256", "ECDH-ES"],
      authorization_encryption_enc_values_supported: ["A256GCM", "A128GCM"]
    }
  else
    %{}
  end
end
```
[VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]

### Anti-Patterns to Avoid
- **Silent downgrade:** If encryption metadata is configured but no usable key is found, returning signed-only JARM or raw query parameters would violate the locked phase decisions and weaken confidentiality unexpectedly. [VERIFIED: repo read]
- **Second crypto-policy plane:** Do not add separate operator toggles or discovery-only switches for JARM encryption; the repo consistently derives crypto truth from effective runtime posture. [VERIFIED: repo read]
- **Key-use ambiguity:** Do not pick the first JWK that can technically encrypt; prefer `use=enc`, honor matching `kid`, and require key-shape compatibility for `RSA-OAEP-256` versus `ECDH-ES`. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]
- **Redirect-path network loops:** Repeated JWKS retries or background-policy branches inside the authorization response path would contradict the existing bounded `JwksFetcher` contract. [VERIFIED: repo read]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Nested JWS/JWE crypto | Custom JWT serialization or manual JOSE segment assembly | `JOSE.JWT.sign/3`, `JOSE.JWS.compact/1`, and `JOSE.JWE.block_encrypt/3` | JOSE already handles compact serialization and algorithm-specific primitives; homegrown JWT/JWE code is protocol-risky. [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] |
| Remote client-key fetch/cache | New Req calls or custom ETS cache | `Lockspire.JwksFetcher` | The existing fetcher already enforces HTTPS, SSRF target checks, redirect refusal, body caps, timeouts, caching, and last-known-good preservation. [VERIFIED: repo read] |
| Discovery truth stitching | Per-key hard-coded metadata publication | One `authorization_response_capabilities` helper in `Discovery` | The repo already treats shared capability sources as the way to prevent runtime/metadata drift. [VERIFIED: repo read] |
| Failure visibility | Publicly detailed browser/OAuth errors | Internal `reason_code` taxonomy plus telemetry/audit | Existing sensitive auth work keeps external behavior generic while recording actionable internal reasons. [VERIFIED: repo read] |

**Key insight:** Phase 72 succeeds by reusing the repo’s existing narrow seams, not by inventing a new JARM-specific transport, cache, or policy subsystem. [VERIFIED: repo read]

## Common Pitfalls

### Pitfall 1: Missing Durable Metadata Fields
**What goes wrong:** Encryption behavior is wired only in runtime code, but clients cannot persist or update `authorization_encrypted_response_alg` / `authorization_encrypted_response_enc`. [VERIFIED: repo read]  
**Why it happens:** Those fields do not exist today in `Client`, `ClientRecord`, or registration/update plumbing. [VERIFIED: repo read]  
**How to avoid:** Make durable metadata support the first slice so runtime behavior has one source of truth. [VERIFIED: repo read]  
**Warning signs:** Grep finds the encryption metadata only in requirements, not in `lib/` or `test/`. [VERIFIED: repo read]

### Pitfall 2: Reusing the Broader Phase 40 JWE Allow-List
**What goes wrong:** Outbound JARM encryption accidentally exposes CBC modes or `RSA-OAEP` just because inbound request-object JWE supports them. [VERIFIED: repo read]  
**Why it happens:** Phase 40 solved inbound decryption with a broader allow-list, but Phase 72 has a narrower locked outbound surface. [VERIFIED: repo read]  
**How to avoid:** Keep dedicated outbound allow-lists for `RSA-OAEP-256`, `ECDH-ES`, `A256GCM`, and `A128GCM`. [VERIFIED: repo read]  
**Warning signs:** Discovery publishes CBC values or tests allow `A128CBC-HS256` for authorization responses. [VERIFIED: repo read]

### Pitfall 3: Remote-Key Resolution That Ignores `kid` and `use`
**What goes wrong:** Encryption succeeds against the wrong key or refreshes unnecessarily because selection is “any encryptable JWK” instead of explicit matching. [VERIFIED: repo read]  
**Why it happens:** JWKS sets can contain multiple keys and mixed uses, and the current repo precedent already relies on `kid`-aware refresh behavior for remote signing keys. [VERIFIED: repo read]  
**How to avoid:** Prefer `use=enc`, use `kid` when present, and require key-shape compatibility before considering refresh. [VERIFIED: repo read]  
**Warning signs:** Tests pass with mixed-use JWKS sets that should have been rejected. [VERIFIED: repo read]

### Pitfall 4: Metadata/Runtime Drift
**What goes wrong:** Discovery advertises encryption support even when the authorization surface or effective issuer posture cannot truthfully produce it. [VERIFIED: repo read]  
**Why it happens:** Static arrays are easier than sharing one capability helper. [VERIFIED: repo read]  
**How to avoid:** Publish signing and encryption metadata from one helper tied to mounted authorization capability, not client state or transient fetch health. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]  
**Warning signs:** Discovery tests need independent expectations for response modes, signing algs, and encryption algs. [VERIFIED: repo read]

## Code Examples

Verified patterns from official and repo sources:

### Nested JARM Construction
```elixir
# Source: https://hexdocs.pm/jose/JOSE.JWT.html + repo nested-JWT pattern
claims = %{"iss" => issuer, "aud" => client.client_id, "exp" => exp, "code" => code, "state" => state}

{_, signed} =
  JOSE.JWT.sign(signing_jwk, %{"alg" => signing_alg, "kid" => signing_kid, "typ" => "JWT"}, claims)
  |> JOSE.JWS.compact()

{_, encrypted} =
  JOSE.JWE.block_encrypt(client_enc_jwk, signed, %{"alg" => "RSA-OAEP-256", "enc" => "A256GCM", "cty" => "JWT"})
  |> JOSE.JWE.compact()
```
[CITED: https://hexdocs.pm/jose/JOSE.JWT.html] [VERIFIED: repo read]

### Bounded Remote JWKS Recovery
```elixir
# Source: repo JWKS fetcher + private_key_jwt refresh pattern
with {:ok, jwk_set} <- fetcher.get_keys(jwks_uri, jwks_fetcher_opts(opts)),
     {:ok, key} <- select_key(jwk_set, requested_kid, requested_alg) do
  {:ok, key}
else
  {:error, :no_matching_key} ->
    with {:ok, fresh_set} <- fetcher.refresh_keys(jwks_uri, jwks_fetcher_opts(opts)),
         {:ok, key} <- select_key(fresh_set, requested_kid, requested_alg) do
      {:ok, key}
    else
      _ -> {:error, :jarm_encryption_key_unavailable}
    end

  _ ->
    {:error, :jarm_encryption_key_fetch_failed}
end
```
[VERIFIED: repo read]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| JARM signed-only in `Lockspire.Protocol.Jarm` with discovery publishing only signing algorithms | Nested sign-then-encrypt JARM plus shared signing/encryption metadata publication | v1.19 Phase 72 target. [VERIFIED: repo read] | Adds confidentiality for authorization codes without changing the embedded-library shape. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html] |
| Ad hoc direct-client remote-key handling would have been duplicated per feature | Shared guarded `JwksFetcher` plus bounded refresh pattern reused across surfaces | v1.15 Phases 60-61 delivered the guarded path. [VERIFIED: repo read] | Phase 72 can stay narrow and safe by reusing the existing fetch/cache contract. [VERIFIED: repo read] |
| Broad inbound JWE support influenced by request-object decryption needs | Narrow outbound JARM encryption allow-list driven by explicit phase decisions | Phase 40 established the broader inbound precedent; Phase 72 deliberately narrows outbound support. [VERIFIED: repo read] | Prevents response-surface sprawl and avoids CBC modes for this feature. [VERIFIED: repo read] |

**Deprecated/outdated:** Publishing JARM encryption metadata from static arrays would be outdated for this repo because Phase 59 and Phase 71 already established shared runtime-truth publication as the standard pattern. [VERIFIED: repo read]

## Assumptions Log

All material claims in this research were verified against the repo or cited from official documentation. [VERIFIED: repo read]

## Open Questions (RESOLVED)

1. **No blocker-level open question remains if metadata persistence is included in Phase 72.** [VERIFIED: repo read]
   - What we know: Runtime encryption support depends on client metadata fields that are not yet modeled or persisted. [VERIFIED: repo read]
   - What's unclear: Nothing protocol-level; the only planning choice is whether to split the metadata plumbing into its own first plan. [VERIFIED: repo read]
   - Recommendation: Yes, split it out first so later plans do not invent temporary config paths or test-only metadata injection. [VERIFIED: repo read]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ExUnit` with `Phoenix.ConnTest` and `Ecto.Adapters.SQL.Sandbox`. [VERIFIED: repo read] |
| Config file | `test/test_helper.exs`. [VERIFIED: repo read] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/jarm_test.exs test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/protocol/authorization_flow_test.exs`. [VERIFIED: repo read] |
| Full suite command | `MIX_ENV=test mix test.fast`. [VERIFIED: repo read] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| JARM-03 | Durable client metadata accepts encryption settings and rejects incoherent combinations. [VERIFIED: repo read] | unit | `MIX_ENV=test mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs` | ✅ extend existing files. [VERIFIED: repo read] |
| JARM-03 | Authorization response is nested JWS-in-JWE when encryption metadata is configured. [CITED: https://openid.net/specs/oauth-v2-jarm.html] | unit | `MIX_ENV=test mix test test/lockspire/protocol/jarm_test.exs` | ✅ extend existing file. [VERIFIED: repo read] |
| JARM-03 | Inline `jwks` and guarded remote `jwks_uri` key resolution use one bounded refresh and never silently downgrade. [VERIFIED: repo read] | unit | `MIX_ENV=test mix test test/lockspire/protocol/jarm_test.exs test/lockspire/jwks_fetcher_test.exs` | ✅ extend existing files. [VERIFIED: repo read] |
| JARM-03 | Authorization redirect/error behavior stays browser-safe and fail-closed when encrypted JARM cannot be produced. [VERIFIED: repo read] | integration | `MIX_ENV=test mix test test/lockspire/protocol/authorization_flow_test.exs test/lockspire/web/authorize_controller_test.exs` | ✅ extend existing files. [VERIFIED: repo read] |
| JARM-03 | Discovery publishes coherent signing and encryption metadata from one shared source. [CITED: https://openid.net/specs/oauth-v2-jarm.html] | unit | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | ✅ extend existing files. [VERIFIED: repo read] |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/lockspire/protocol/jarm_test.exs test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/discovery_test.exs`. [VERIFIED: repo read]
- **Per wave merge:** `MIX_ENV=test mix test.fast`. [VERIFIED: repo read]
- **Phase gate:** Full non-integration suite green before `/gsd-verify-work`. [VERIFIED: repo read]

### Wave 0 Gaps
- None — existing ExUnit, sandbox, JOSE, and discovery test infrastructure already cover the needed seams; this phase needs file extensions, not new framework setup. [VERIFIED: repo read]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase does not add end-user authentication. [VERIFIED: repo read] |
| V3 Session Management | no | This phase does not change session lifecycle. [VERIFIED: repo read] |
| V4 Access Control | no | This phase protects authorization responses but does not introduce new authorization-policy decisions. [VERIFIED: repo read] |
| V5 Input Validation | yes | Validate client metadata coherence, JWE algorithm allow-lists, `kid` shape, and JWKS key compatibility before encryption. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html] |
| V6 Cryptography | yes | Use JOSE primitives only, require sign-then-encrypt nested JWT, and keep the outbound JWE allow-list explicit. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html] [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `jwks_uri` SSRF or slow-remote abuse | Tampering / DoS | Reuse `JwksFetcher` HTTPS-only, safe-target resolution, redirect refusal, strict timeout, body cap, and cache-first behavior. [VERIFIED: repo read] |
| Confidentiality downgrade from encrypted JARM to signed-only/raw redirect | Information Disclosure | Treat requested encryption as fail-closed and return browser-safe error behavior instead of weaker output. [VERIFIED: repo read] |
| Algorithm confusion or over-broad JOSE acceptance | Tampering | Enforce explicit outbound allow-lists for `alg` and `enc`, and reject missing/incoherent encryption metadata. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html] |
| Wrong-key encryption inside mixed JWKS sets | Information Disclosure | Prefer `use=enc`, honor `kid`, and require key-shape compatibility for the configured JWE `alg`. [VERIFIED: repo read] |
| Sensitive operational leakage in browser-visible errors | Information Disclosure | Keep detailed `reason_code` values in telemetry/audit/tests only; surface least-surprising non-leaky external errors. [VERIFIED: repo read] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/72-jarm-encryption-and-metadata/72-CONTEXT.md` - locked decisions, scope, and canonical repo references. [VERIFIED: repo read]
- `lib/lockspire/protocol/jarm.ex` - current JARM signing boundary. [VERIFIED: repo read]
- `lib/lockspire/protocol/authorization_flow.ex` - current JARM redirect assembly seam. [VERIFIED: repo read]
- `lib/lockspire/protocol/discovery.ex` - current discovery truth model and JARM signing metadata publication. [VERIFIED: repo read]
- `lib/lockspire/jwks_fetcher.ex` - guarded remote JWKS fetch/cache/refresh contract. [VERIFIED: repo read]
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex` - proven inline/remote key resolution and one-refresh retry pattern. [VERIFIED: repo read]
- `lib/lockspire/domain/client.ex`, `lib/lockspire/storage/ecto/client_record.ex`, `lib/lockspire/protocol/registration.ex`, `lib/lockspire/protocol/registration_management.ex` - current client metadata shape and missing encryption fields. [VERIFIED: repo read]
- `https://openid.net/specs/oauth-v2-jarm.html` - final JARM errata spec for nested JWT and discovery metadata names. [CITED: https://openid.net/specs/oauth-v2-jarm.html]
- `https://hexdocs.pm/jose/JOSE.JWT.html` - JOSE Elixir API documentation for signing, encrypting, and verification primitives. [CITED: https://hexdocs.pm/jose/JOSE.JWT.html]

### Secondary (MEDIUM confidence)
- `mix.exs` and `mix.lock` - repo-pinned dependency versions for JOSE, Req, Cachex, Phoenix, and Ecto. [VERIFIED: repo read]
- `test/lockspire/protocol/jarm_test.exs`, `test/lockspire/protocol/discovery_test.exs`, `test/lockspire/jwks_fetcher_test.exs`, `test/lockspire/protocol/request_object_test.exs`, `test/lockspire/protocol/client_auth_test.exs` - existing proof patterns to extend. [VERIFIED: repo read]

### Tertiary (LOW confidence)
- None. [VERIFIED: repo read]

## Metadata

**Confidence breakdown:** [VERIFIED: repo read]
- Standard stack: HIGH - the phase extends existing repo-pinned JOSE/Req/Cachex/Phoenix seams rather than introducing uncertain new dependencies. [VERIFIED: repo read]
- Architecture: HIGH - the repo already demonstrates the needed boundaries for redirect formatting, guarded JWKS resolution, and discovery truth. [VERIFIED: repo read]
- Pitfalls: HIGH - the major risks are directly visible from current repo shape plus the final JARM spec’s nested-JWT and metadata requirements. [VERIFIED: repo read] [CITED: https://openid.net/specs/oauth-v2-jarm.html]

**Research date:** 2026-05-07 [VERIFIED: repo read]  
**Valid until:** 2026-06-06 for repo-shape guidance; re-check official JARM/JOSE docs sooner only if dependency versions or scope decisions move. [VERIFIED: repo read]
