# Phase 33: dpop-proof-validation-and-replay-state - Research

**Researched:** 2026-04-28 [VERIFIED: system date]  
**Domain:** OAuth 2.0 DPoP proof validation, JWK thumbprint binding, and durable replay protection in an embedded Phoenix/Ecto authorization server [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [CITED: https://datatracker.ietf.org/doc/html/rfc7638] [VERIFIED: codebase grep]  
**Confidence:** MEDIUM [VERIFIED: research synthesis]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DPoP-01 | Lockspire validates DPoP proofs for supported endpoints against required JOSE header and claim semantics, including signature validity, `htm`, `htu`, `iat`, and `jti`. [VERIFIED: .planning/REQUIREMENTS.md] | Add a dedicated protocol validator that parses the `DPoP` header once, uses JOSE strict verification with an explicit asymmetric allowlist, and compares `htm`/`htu` against Lockspire-owned endpoint URIs derived from the configured issuer and mounted route paths. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] [CITED: https://hexdocs.pm/jose/JOSE.JWS.html] [VERIFIED: codebase grep] |
| DPoP-02 | Lockspire computes and persists the proof key thumbprint used to bind issued tokens. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing durable `Token.cnf` / `TokenRecord.cnf` map and compute `cnf["jkt"]` with `JOSE.JWK.thumbprint/1` over the public JWK extracted from the proof header. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [CITED: https://datatracker.ietf.org/doc/html/rfc7638] [CITED: https://hexdocs.pm/jose/JOSE.JWK.html] [VERIFIED: codebase grep] |
| DPoP-03 | Replayed DPoP proofs are rejected within the supported replay window with deterministic, RFC-shaped errors. [VERIFIED: .planning/REQUIREMENTS.md] | Add a repository-backed replay store with a unique proof fingerprint per `(htm, normalized_htu, jti)` context and return `invalid_dpop_proof` when the same proof is seen again inside the acceptance window. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: codebase grep] |
| DPoP-04 | DPoP enablement is explicit in policy or client state; existing bearer clients remain bearer by default. [VERIFIED: .planning/REQUIREMENTS.md] | Add explicit durable state on `ServerPolicy` and `Client` rather than using metadata blobs, with defaults that leave all existing clients on bearer mode. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 33 should land as a narrow extension of Lockspire’s existing token-side protocol stack, not as a generic protected-resource framework. The codebase already has the right ownership boundaries: `Lockspire.Web.TokenController` stays thin, `Lockspire.Protocol.TokenExchange` owns grant semantics and OAuth-safe error shaping, `Lockspire.Storage.Ecto.Repository` owns cross-node durability and row-locking, and `Token` persistence already has a durable `cnf` map ready for `jkt` binding. [VERIFIED: codebase grep]

RFC 9449’s DPoP core fits those seams directly. A receiving server must validate a single DPoP JWT header, require `typ=dpop+jwt`, reject `alg=none` and symmetric algorithms, verify the signature against the public `jwk` in the proof, confirm `htm`, `htu`, and `iat`, and reject replayed `jti` values within a short acceptance window. The same RFC also defines `dpop_bound_access_tokens` as client metadata defaulting to `false` and `dpop_signing_alg_values_supported` as truthful authorization-server metadata. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]

The repo-aligned implementation path is therefore: add one reusable DPoP validator module, add one dedicated durable replay store keyed to the RFC replay context, and add explicit opt-in policy/client fields that preserve bearer-by-default behavior. Do not bury DPoP mode in arbitrary metadata, do not rely on ETS/process state for replay detection, and do not widen Phase 33 into nonce orchestration or host-owned protected-resource helpers because both are explicitly deferred beyond v1.7. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]

**Primary recommendation:** Plan Phase 33 around three concrete slices: `DpopProof` validation, repository-backed replay persistence, and explicit server/client opt-in state, all threaded through the existing `TokenExchange` request shape and repository transaction patterns. [VERIFIED: research synthesis]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Parse and validate inbound `DPoP` headers on `/token` | API / Backend | Frontend Server (SSR) | The Phoenix controller should only pass request context through; proof parsing, JOSE validation, and OAuth error mapping belong in protocol code next to `TokenExchange`. [VERIFIED: codebase grep] |
| Canonicalize Lockspire-owned endpoint URIs for `htu` comparison | API / Backend | — | Discovery already builds truthful endpoint URIs from `Config.issuer!/0` plus mounted paths, so the same internal seam should own the canonical `htu` target instead of ad hoc controller string handling. [VERIFIED: codebase grep] |
| Enforce replay single-use within the accepted proof window | Database / Storage | API / Backend | RFC 9449 explicitly calls out shared-state replay tracking, and Lockspire’s existing device polling and token redemption patterns already rely on Postgres/Ecto rather than process-local state. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep] |
| Persist key-binding state for later token and userinfo use | Database / Storage | API / Backend | The `Token` domain and `TokenRecord` schema already persist `cnf`, which is the natural durable carrier for `cnf.jkt`. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep] |
| Expose DPoP opt-in as durable operator/client configuration | Database / Storage | API / Backend | Current server policy and client configuration are modeled as explicit fields and enums on durable records, not runtime-only toggles. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` (published 2026-03-05) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Mounted `/token` entrypoint and thin-controller request adaptation. [VERIFIED: codebase grep] | Phase 33 extends the existing controller/router surface; no new HTTP stack is needed. [VERIFIED: codebase grep] |
| Ecto SQL | `3.13.5` (published 2026-03-03) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Durable replay state, transactions, row locks, and conflict-safe inserts. [VERIFIED: codebase grep] | Current repository patterns already use transactions and `FOR UPDATE` locking for single-winner lifecycle transitions. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| PostgreSQL | `14+` [VERIFIED: AGENTS.md] | Node-safe replay tracking and durable policy/client state. [VERIFIED: runtime probe] | Replay protection is explicitly required to avoid process-local assumptions, and Postgres is the project’s default durable truth layer. [VERIFIED: .planning/PROJECT.md] |
| JOSE | `1.11.12` (published 2025-11-20) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | JWT verification, JOSE header inspection, JWK parsing, public-key extraction, and RFC 7638 thumbprints. [CITED: https://hexdocs.pm/jose/JOSE.JWK.html] [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] [CITED: https://hexdocs.pm/jose/JOSE.JWS.html] | The installed JOSE dependency already exposes the exact APIs this phase needs, so Phase 33 should not add a second JOSE/JWT library. [VERIFIED: codebase grep] [VERIFIED: deps grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveView | `1.1.28` (published 2026-03-27) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Future operator/client DPoP configuration surfaces. [VERIFIED: codebase grep] | Relevant when Phase 35 surfaces client DPoP mode in admin UI, but not required to validate proofs in Phase 33. [VERIFIED: roadmap grep] |
| OpenTelemetry API | `1.5.0` (published 2025-10-17) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Existing observability seam for proof-validation failures and replay rejections. [VERIFIED: mix.lock] [VERIFIED: codebase grep] | Use when Phase 33 adds `invalid_dpop_proof` telemetry and private reason codes without widening the public error contract. [VERIFIED: research synthesis] |
| Oban | `2.21.1` (published 2026-03-26) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Optional future replay-row pruning if ad hoc cleanup becomes insufficient. [VERIFIED: mix.lock] | Do not make Oban a Phase 33 dependency path because there is no existing worker pattern in the repo and opportunistic expiry pruning is sufficient for the narrow replay window. [VERIFIED: codebase grep] [ASSUMED] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JOSE `verify_strict/3` with an explicit allowlist | Generic JWT parsing plus manual signature dispatch | Rejected because the installed JOSE docs explicitly recommend strict verification and already provide `peek_protected/1`, `from_map/1`, `to_public/1`, and `thumbprint/1`. [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] [CITED: https://hexdocs.pm/jose/JOSE.JWS.html] [CITED: https://hexdocs.pm/jose/JOSE.JWK.html] |
| Dedicated Postgres replay table | ETS/Agent/process-local replay cache | Rejected because RFC 9449 calls out shared-state replay tracking, and Phase 33 explicitly requires node-safe behavior across restarts and nodes. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: .planning/ROADMAP.md] |
| Explicit `Client` / `ServerPolicy` fields | `metadata` blobs or config-only toggles | Rejected because the repo already models support-contract behavior as explicit durable fields and keeps metadata for ancillary client data, not protocol-critical mode switches. [VERIFIED: codebase grep] |

**Installation:** No new dependency is required for Phase 33; use the installed Phoenix/Ecto/JOSE stack already pinned in `mix.exs` and `mix.lock`. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

**Version verification:** Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, JOSE `1.11.12`, OpenTelemetry API `1.5.0`, and Oban `2.21.1` were verified in this session from `mix.lock` and the Hex package API. [VERIFIED: mix.lock] [VERIFIED: hex.pm API]

## Architecture Patterns

### System Architecture Diagram

```text
Client
  |
  | POST /token
  | Authorization: client auth
  | DPoP: <compact JWT>
  v
TokenController
  |
  | passes params + auth + request_method + endpoint_uri
  v
TokenExchange / grant validator
  |
  +--> ClientAuth.authenticate(...)
  |
  +--> DpopProof.validate(...)
         |
         +--> JOSE.JWS/JWT strict verification
         +--> typ/alg/jwk checks
         +--> htm/htu/iat checks
         +--> JOSE.JWK.thumbprint(...) => jkt
         +--> ReplayStore.record_use(...)
                    |
                    +--> delete expired matching proof context
                    +--> insert unique proof fingerprint
                    +--> conflict => replay
         |
         v
      %ValidatedProof{jwk, jkt, jti, htm, htu, iat}
  |
  +--> effective DPoP policy resolution
         |
         +--> ServerPolicy.dpop_policy
         +--> Client.dpop_bound_access_tokens
  |
  v
Grant outcome
  |
  +--> Phase 34: persist Token.cnf["jkt"] and return token_type="DPoP"
  |
  +--> Phase 33: return RFC-shaped proof errors with private reason codes
```

### Recommended Project Structure

```text
lib/
├── lockspire/protocol/
│   ├── dpop_proof.ex                 # parse/validate proof header + claims
│   ├── endpoint_uri.ex               # canonical Lockspire-owned endpoint URIs [ASSUMED]
│   ├── token_exchange.ex             # invoke proof validator on token grants
│   └── discovery.ex                  # later publishes dpop_signing_alg_values_supported
├── lockspire/storage/
│   ├── dpop_replay_store.ex          # replay-store behaviour [ASSUMED]
│   └── ecto/
│       ├── dpop_proof_replay_record.ex
│       ├── repository.ex
│       ├── client_record.ex
│       └── server_policy_record.ex
└── lockspire/domain/
    ├── client.ex
    ├── server_policy.ex
    └── token.ex

priv/repo/migrations/
├── *_create_lockspire_dpop_proof_replays.exs
└── *_add_dpop_policy_fields.exs

test/
├── lockspire/protocol/dpop_proof_test.exs
├── lockspire/storage/ecto/repository_dpop_replay_test.exs
├── lockspire/protocol/token_exchange_test.exs
└── lockspire/web/token_controller_test.exs
```

### Pattern 1: Validate Proofs in a Reusable Protocol Module
**What:** Add one validator that turns a raw `DPoP` header plus request context into either `%ValidatedProof{}` or an RFC-shaped protocol error. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep]  
**When to use:** Token endpoint now; `userinfo` and other Lockspire-owned DPoP surfaces later. [VERIFIED: .planning/ROADMAP.md]  
**Recommendation:** Keep the validator grant-agnostic so Phase 34 can call it from authorization-code, refresh-token, and device-code paths without re-parsing the proof. [VERIFIED: roadmap grep]

**Example:**
```elixir
# Source: https://hexdocs.pm/jose/JOSE.JWT.html
# Source: https://hexdocs.pm/jose/JOSE.JWK.html
protected = JOSE.JWT.peek_protected(compact_proof)
jwk = JOSE.JWK.from_map(protected.fields["jwk"])
public_jwk = JOSE.JWK.to_public(jwk)
{true, jwt, _jws} = JOSE.JWT.verify_strict(public_jwk, ["ES256", "RS256", "EdDSA"], compact_proof)
jkt = JOSE.JWK.thumbprint(public_jwk)
claims = jwt.fields
```

### Pattern 2: Compute `htu` from the Same Canonical Issuer Base Used by Discovery
**What:** Compare the proof’s `htu` against a canonical Lockspire-owned endpoint URI, not a raw host header string. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep]  
**When to use:** `/token` now; `/userinfo` in Phase 35. [VERIFIED: .planning/ROADMAP.md]  
**Recommendation:** Extract a reusable internal helper from the `Discovery` URI-building pattern so the published discovery endpoint and the proof validator agree on the same external URI shape. [VERIFIED: codebase grep] [ASSUMED]

### Pattern 3: Use a Dedicated Replay Store with Conflict-as-Replay Semantics
**What:** Persist a short-lived proof-use record per replay context and let the database decide the winner. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]  
**When to use:** Every DPoP proof acceptance on Lockspire-owned endpoints. [VERIFIED: research synthesis]  
**Recommendation:** Fingerprint `htm + normalized_htu + jti`, store only hashes for untrusted proof identifiers, opportunistically delete expired matching rows before insert, and treat a uniqueness conflict as deterministic replay. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [ASSUMED]

**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
Repo.transaction(fn ->
  from(replay in DpopProofReplayRecord,
    where:
      replay.proof_fingerprint_hash == ^proof_fingerprint_hash and
        replay.expires_at <= ^now
  )
  |> Repo.delete_all()

  case Repo.insert(%DpopProofReplayRecord{
         proof_fingerprint_hash: proof_fingerprint_hash,
         jti_hash: jti_hash,
         htm: htm,
         htu: htu,
         jkt: jkt,
         expires_at: expires_at
       }, on_conflict: :nothing, conflict_target: [:proof_fingerprint_hash]) do
    {:ok, _record} -> :ok
    {:error, _changeset} -> Repo.rollback(:replayed)
  end
end)
```

### Pattern 4: Keep DPoP Mode as Explicit Durable State
**What:** Add DPoP mode to the same durable records that already hold PAR and DCR policy, instead of scattering it across runtime config and metadata. [VERIFIED: codebase grep]  
**When to use:** Server-wide enablement and per-client opt-in. [VERIFIED: .planning/REQUIREMENTS.md]  
**Recommendation:** Add `ServerPolicy.dpop_policy` with a bearer-preserving default and `Client.dpop_bound_access_tokens` with a default of `false`, because RFC 9449 already defines the client-side boolean that DCR will need later. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [ASSUMED]

### Anti-Patterns to Avoid
- **Process-local replay cache:** It breaks the phase’s node-safe requirement and diverges from the repo’s durable token/device patterns. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: codebase grep]
- **Manual JWK thumbprint serialization:** RFC 7638 canonicalization is easy to get subtly wrong; use JOSE’s built-in thumbprint functions instead. [CITED: https://datatracker.ietf.org/doc/html/rfc7638] [CITED: https://hexdocs.pm/jose/JOSE.JWK.html]
- **String-equality `htu` checks against raw request URLs:** RFC 9449 calls for ignoring query/fragment and recommends URI normalization before comparing `htu`. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
- **Metadata-blob DPoP mode:** It makes later DCR/admin surfaces harder to keep truthful and bypasses the repo’s explicit-field pattern for protocol support state. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DPoP JWT signature verification | Manual compact JWT splitting and custom JWS dispatch | `JOSE.JWT.verify_strict/3` plus `JOSE.JWT.peek_protected/1` / `JOSE.JWK.from_map/1` [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] [CITED: https://hexdocs.pm/jose/JOSE.JWK.html] | JOSE already exposes strict alg allowlisting and header inspection; custom verification would invite `alg` and key-handling bugs. [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| RFC 7638 thumbprints | Hand-built canonical JSON and SHA-256 calls | `JOSE.JWK.thumbprint/1` on `JOSE.JWK.to_public/1` [CITED: https://hexdocs.pm/jose/JOSE.JWK.html] [CITED: https://datatracker.ietf.org/doc/html/rfc7638] | The spec requires canonical member selection and ordering; JOSE already implements it correctly. [CITED: https://datatracker.ietf.org/doc/html/rfc7638] |
| Replay deduplication | ETS map keyed by raw `jti` | Postgres uniqueness plus Ecto transaction/repository contract [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | Shared-state replay protection is the point of the phase, and the repo already trusts Postgres for race-safe lifecycle transitions. [VERIFIED: codebase grep] |
| Client/server mode toggles | Free-form `metadata` keys or environment flags | Explicit fields on `Client` and `ServerPolicy` [VERIFIED: codebase grep] | DPoP mode affects public behavior and future DCR/admin truth, so it belongs in typed durable state. [VERIFIED: codebase grep] |

**Key insight:** Phase 33 is mostly about using the installed JOSE/Ecto stack and existing Lockspire seams correctly; nearly every “small custom shortcut” here weakens protocol truth or cross-node correctness. [VERIFIED: research synthesis]

## Common Pitfalls

### Pitfall 1: Accepting Any Signed JWT with the Right Claims
**What goes wrong:** A proof with the wrong `typ`, a symmetric `alg`, or an unexpected algorithm family is accepted because the validator only checks the claims after generic JWT verification. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]  
**Why it happens:** It is tempting to call non-strict verification helpers and trust whatever the JOSE header says. [CITED: https://hexdocs.pm/jose/JOSE.JWT.html]  
**How to avoid:** Require `typ=dpop+jwt`, reject `none`, reject MAC/symmetric algorithms, and use JOSE strict verification with a local allowlist. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [CITED: https://hexdocs.pm/jose/JOSE.JWS.html]  
**Warning signs:** Tests pass for valid proofs but there is no failing test for `alg=HS256`, `alg=none`, or a missing/incorrect `typ`. [VERIFIED: research synthesis]

### Pitfall 2: Comparing `htu` Against Raw Request Strings
**What goes wrong:** Legitimate proofs fail behind proxies or mounted paths because the server compares the claim to a non-canonical request URL. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]  
**Why it happens:** The validator uses `conn.host` or a path-only string instead of the same canonical endpoint URI shape the issuer publishes. [VERIFIED: codebase grep]  
**How to avoid:** Derive Lockspire-owned endpoint URIs from the configured issuer plus known route path, strip query/fragment, and normalize before comparing. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep]  
**Warning signs:** Discovery says one token endpoint URI but DPoP tests build proofs for another. [VERIFIED: research synthesis]

### Pitfall 3: Replay Detection that Dies with the Process
**What goes wrong:** Replayed proofs slip through after deploys, node failover, or multi-node routing. [VERIFIED: .planning/ROADMAP.md]  
**Why it happens:** Replay state lives in ETS, an Agent, or request-local memory. [VERIFIED: research synthesis]  
**How to avoid:** Persist proof-use state in Postgres with uniqueness and a bounded expiry window, using the same repository discipline already applied to device polling and token redemption. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep]  
**Warning signs:** The design has no migration, no repository contract, or no conflict path that returns replay deterministically. [VERIFIED: research synthesis]

### Pitfall 4: Hiding DPoP Opt-In in Metadata
**What goes wrong:** Bearer-default behavior becomes ambiguous, DCR cannot map cleanly to internal state, and operator surfaces drift from repo truth. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]  
**Why it happens:** Metadata maps seem faster than adding real schema fields. [VERIFIED: codebase grep]  
**How to avoid:** Use explicit typed fields with defaults that preserve bearer clients and a clear effective-policy rule. [VERIFIED: codebase grep] [ASSUMED]  
**Warning signs:** Planner tasks mention “just store a key in `metadata`” or do not add migrations for client/policy state. [VERIFIED: research synthesis]

## Code Examples

Verified patterns from official sources:

### Parse Public JWK and Compute a JWK Thumbprint
```elixir
# Source: https://hexdocs.pm/jose/JOSE.JWK.html
header_jwk = JOSE.JWK.from_map(%{"kty" => "EC", "crv" => "P-256", "x" => x, "y" => y})
public_jwk = JOSE.JWK.to_public(header_jwk)
jkt = JOSE.JWK.thumbprint(public_jwk)
```

### Verify a JWT with an Explicit Algorithm Allowlist
```elixir
# Source: https://hexdocs.pm/jose/JOSE.JWT.html
{true, jwt, _jws} = JOSE.JWT.verify_strict(public_jwk, ["ES256", "RS256", "EdDSA"], compact_jwt)
claims = jwt.fields
```

### Serialize Replay Protection Through the Repository
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
# Source: https://hexdocs.pm/ecto/Ecto.Query.html
Repo.transaction(fn ->
  proof =
    DpopProof.validate!(header, method: "POST", htu: token_endpoint_uri, now: now)

  case ReplayStore.record_use(proof, now) do
    :ok -> proof
    {:error, :replayed} -> Repo.rollback(:invalid_dpop_proof)
  end
end)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic bearer-only token request validation | Sender-constrained proof validation per RFC 9449 with `DPoP` header, `cnf.jkt`, and replay checks [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | RFC 9449 published September 2023 [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | Lockspire can improve public/CLI client trust without adding mTLS or hosted infrastructure. [VERIFIED: .planning/PROJECT.md] |
| JOSE verification without an algorithm allowlist | `verify_strict/3` with an explicit allowlist [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] [CITED: https://hexdocs.pm/jose/JOSE.JWS.html] | Present in JOSE `1.11.12` docs [CITED: https://hexdocs.pm/jose/JOSE.JWT.html] | Prevents proof validation from silently widening to unsupported algorithms. [CITED: https://hexdocs.pm/jose/JOSE.JWS.html] |
| Process-local replay caches in single-node examples | Shared-state replay tracking keyed to `jti` in the proof’s request context [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | RFC 9449 replay guidance [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | Matches the phase’s node-safe requirement and Lockspire’s Postgres-first architecture. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md] |

**Deprecated/outdated:**
- Accepting `alg=none` or symmetric JOSE algorithms for DPoP proofs is explicitly forbidden. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
- Using `JOSE.JWT.verify/2` without an allowlist is weaker than the installed JOSE docs recommend for untrusted proof input. [CITED: https://hexdocs.pm/jose/JOSE.JWT.html]
- Nonce enforcement is part of RFC 9449, but Lockspire has explicitly deferred DPoP nonce support beyond v1.7. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Recommended proof-age defaults are `120` seconds max age with up to `5` seconds future skew. [ASSUMED] | Summary; Common Pitfalls; Validation guidance | Too short hurts legitimate clients; too long weakens replay resistance and can distort later token lifetime decisions. |
| A2 | Recommended server-wide enablement shape is `ServerPolicy.dpop_policy` with values like `:disabled | :optional`, defaulting to `:disabled`. [ASSUMED] | Architecture Patterns; Don't Hand-Roll | If the team prefers a boolean or different enum naming, migration and admin/DCR task breakdown will change. |
| A3 | Recommended per-client shape is `Client.dpop_bound_access_tokens :: boolean`, default `false`, mapped directly to RFC 9449 client metadata. [ASSUMED] | Architecture Patterns; Standard Stack | If the team prefers an internal token-mode enum, DCR/admin mapping tasks change even though bearer-default intent remains the same. |
| A4 | Recommended helper module names are `Lockspire.Protocol.DpopProof`, `Lockspire.Protocol.EndpointUri`, and `Lockspire.Storage.DpopReplayStore`. [ASSUMED] | Recommended Project Structure | Naming drift is low-risk, but plan tasks and file targets will need minor adjustment. |

## Open Questions

1. **What exact proof-age window should Lockspire ship first?**
   - What we know: RFC 9449 requires a limited proof lifetime and suggests seconds or minutes, and the phase requires bounded `iat` checking plus durable replay protection. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: .planning/ROADMAP.md]
   - What's unclear: The milestone docs do not lock a specific `iat` age/skew constant. [VERIFIED: roadmap grep]
   - Recommendation: Plan with a fixed constant in Phase 33 rather than a new operator setting; `120s` max age and `5s` future skew is a coherent first default, but treat it as a confirmable assumption until the phase is discussed or implemented. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix compile/test and JOSE/Ecto runtime | ✓ [VERIFIED: runtime probe] | `1.19.5` [VERIFIED: runtime probe] | — |
| Mix | Test execution and dependency tasks | ✓ [VERIFIED: runtime probe] | `1.19.5` [VERIFIED: runtime probe] | — |
| PostgreSQL | Durable replay-state verification and repository tests | ✓ [VERIFIED: runtime probe] | running on local `:5432` [VERIFIED: runtime probe] | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: runtime probe]

**Missing dependencies with fallback:**
- None. [VERIFIED: runtime probe]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox [VERIFIED: test/test_helper.exs] [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/dpop_proof_test.exs test/lockspire/storage/ecto/repository_dpop_replay_test.exs -x` [ASSUMED] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DPoP-01 | Valid proof parses and invalid proof variants fail with deterministic private reason codes and public `invalid_dpop_proof` errors. [VERIFIED: .planning/REQUIREMENTS.md] | unit + protocol integration | `MIX_ENV=test mix test test/lockspire/protocol/dpop_proof_test.exs test/lockspire/protocol/token_exchange_test.exs -x` [ASSUMED] | ❌ Wave 0 |
| DPoP-02 | Proof JWK thumbprint is computed from the public JWK and prepared for later `Token.cnf["jkt"]` persistence. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `MIX_ENV=test mix test test/lockspire/protocol/dpop_proof_test.exs -x` [ASSUMED] | ❌ Wave 0 |
| DPoP-03 | Same proof context replay is rejected durably within the acceptance window and accepted again after expiry pruning. [VERIFIED: .planning/REQUIREMENTS.md] | repository integration | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_dpop_replay_test.exs -x` [ASSUMED] | ❌ Wave 0 |
| DPoP-04 | Effective DPoP mode is explicit and bearer clients remain unchanged by default. [VERIFIED: .planning/REQUIREMENTS.md] | repository + protocol integration | `MIX_ENV=test mix test test/lockspire/storage/repository_test.exs test/lockspire/protocol/token_exchange_test.exs -x` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/lockspire/protocol/dpop_proof_test.exs test/lockspire/storage/ecto/repository_dpop_replay_test.exs -x` [ASSUMED]
- **Per wave merge:** `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/PROJECT.md]

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/dpop_proof_test.exs` — valid proof, bad `typ`, bad `alg`, bad signature, bad `htm`, bad `htu`, stale `iat`, missing `jti`, private-key-in-header rejection. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
- [ ] `test/lockspire/storage/ecto/repository_dpop_replay_test.exs` — first-use success, conflict-as-replay, expiry-prune reuse, hash-only storage proof. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
- [ ] Extend `test/lockspire/protocol/token_exchange_test.exs` — bearer-default path unchanged, DPoP-required client without header rejected, DPoP replay mapped to public `invalid_dpop_proof`. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
- [ ] Extend `test/lockspire/web/token_controller_test.exs` — `DPoP` request header plumbing and JSON error contract. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: research synthesis] | Existing `ClientAuth` plus DPoP proof verification on token requests. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| V3 Session Management | no [VERIFIED: research synthesis] | This phase does not add browser session ownership; host auth/session remain outside Lockspire. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes [VERIFIED: research synthesis] | Effective DPoP mode gates whether a client may use bearer-only or proof-bound token requests. [VERIFIED: .planning/REQUIREMENTS.md] [ASSUMED] |
| V5 Input Validation | yes [VERIFIED: research synthesis] | Strict JOSE header/claim validation, URI normalization, and bounded `jti` / `iat` handling. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| V6 Cryptography | yes [VERIFIED: research synthesis] | JOSE asymmetric signature verification and RFC 7638 SHA-256 JWK thumbprints; never hand-roll. [CITED: https://datatracker.ietf.org/doc/html/rfc7638] [CITED: https://hexdocs.pm/jose/JOSE.JWK.html] |

### Known Threat Patterns for Lockspire’s DPoP Slice

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replayed proof on the same endpoint | Tampering | Limited proof lifetime, durable `jti` replay tracking in request context, and deterministic replay rejection. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| JWT swapping from another purpose | Spoofing | Require `typ=dpop+jwt` and verify with the embedded public JWK only. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| Algorithm confusion / `alg=none` | Tampering | Asymmetric allowlist plus JOSE strict verification; do not enable unsecured signing. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [CITED: https://hexdocs.pm/jose/JOSE.JWS.html] |
| Oversized or attacker-controlled replay identifiers | Denial of Service | Store only hashes of proof identifiers and reject unreasonably large `jti` inputs before persistence. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [ASSUMED] |
| Proxy/path mismatch causing false negatives | Denial of Service | Canonicalize `htu` against the published issuer + mounted route pattern rather than raw local request strings. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- https://datatracker.ietf.org/doc/html/rfc9449 - DPoP proof syntax, validation rules, replay guidance, server metadata, client metadata, `invalid_dpop_proof`, and nonce semantics.
- https://datatracker.ietf.org/doc/html/rfc7638 - JWK thumbprint computation requirements.
- https://hexdocs.pm/jose/JOSE.JWK.html - `from_map/1`, `to_public/1`, `thumbprint/1`, and public-JWK handling.
- https://hexdocs.pm/jose/JOSE.JWT.html - `peek_protected/1` and `verify_strict/3` guidance.
- https://hexdocs.pm/jose/JOSE.JWS.html - strict verification recommendation and algorithm allowlist behavior.
- https://hexdocs.pm/ecto/Ecto.Repo.html - transaction and conflict-handling semantics.
- https://hexdocs.pm/ecto/Ecto.Query.html - row locking and query composition.
- Local codebase files listed in the phase prompt - current Lockspire seams and patterns. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- https://hex.pm/api/packages/phoenix/releases/1.8.5 - Phoenix release date verification.
- https://hex.pm/api/packages/phoenix_live_view/releases/1.1.28 - LiveView release date verification.
- https://hex.pm/api/packages/ecto_sql/releases/3.13.5 - Ecto SQL release date verification.
- https://hex.pm/api/packages/jose/releases/1.11.12 - JOSE release date verification.
- https://hex.pm/api/packages/opentelemetry_api - OpenTelemetry API release verification.
- https://hex.pm/api/packages/oban/releases/2.21.1 - Oban release verification.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo dependencies and release versions were verified directly from `mix.lock`, `mix.exs`, and Hex package metadata. [VERIFIED: mix.lock] [VERIFIED: mix.exs] [VERIFIED: hex.pm API]
- Architecture: MEDIUM - local seams are clear, but exact DPoP mode field names and proof-age constants are still recommendations rather than locked decisions. [VERIFIED: codebase grep] [ASSUMED]
- Pitfalls: HIGH - RFC 9449 is explicit about validation and replay failure modes, and the codebase already shows the durable-vs-local design boundary. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: codebase grep]

**Research date:** 2026-04-28 [VERIFIED: system date]  
**Valid until:** 2026-05-28 [ASSUMED]
