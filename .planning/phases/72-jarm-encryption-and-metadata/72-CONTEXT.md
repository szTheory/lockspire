# Phase 72: JARM Encryption & Metadata - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 72 adds confidentiality to the Phase 71 JARM authorization-response surface by producing nested JWT authorization responses (sign, then encrypt) when a client registers authorization-response encryption metadata. It also extends discovery so the issuer truthfully advertises the signing and encryption capability it can actually produce on the mounted authorization surface.

This phase does not widen Lockspire into a generic outbound metadata platform, a second crypto-policy plane, hybrid or implicit flow support, or FAPI 2.0 Message Signing strict enforcement.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion

- Exact helper/module names for encryption-key resolution and JARM capability publication.
- Whether the bounded `jwks_uri` recovery path is expressed as a separate helper or an opt-in refresh flag on an existing resolution function.
- Exact internal reason-code taxonomy for encrypted-JARM failures, as long as external behavior stays fail-closed and non-leaky.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning artifacts
- `.planning/PROJECT.md` — embedded-library boundary, milestone goal, and DX/support posture
- `.planning/REQUIREMENTS.md` — `JARM-03`
- `.planning/ROADMAP.md` — Phase 72 goal and success criteria
- `.planning/STATE.md` — current milestone position

### Prior phase context
- `.planning/phases/40-jwe-support-for-request-objects/40-CONTEXT.md` — nested JWT and JWE allow-list precedent
- `.planning/phases/59-registration-policy-metadata-truth/59-CONTEXT.md` — one shared capability source and metadata-truth precedent
- `.planning/phases/60-guarded-remote-jwks-resolution/60-CONTEXT.md` — guarded `jwks_uri` fetch, cache, and refresh contract
- `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` — shared client-key resolution posture and fail-closed verifier expectations
- `.planning/phases/71-jarm-core/71-CONTEXT.md` — JARM contract, discovery truth, and no-second-policy-plane posture

### Phase-local artifacts
- `.planning/phases/72-jarm-encryption-and-metadata/ADVISOR.md` — phase-local architectural research notes

### Code and tests
- `lib/lockspire/domain/client.ex` — client metadata fields including `jwks` and `jwks_uri`
- `lib/lockspire/domain/signing_key.ex` — key modeling including `use: :enc`
- `lib/lockspire/jwks_fetcher.ex` — guarded remote `jwks_uri` resolution seam
- `lib/lockspire/protocol/authorization_flow.ex` — authorization redirect formatting and JARM response building
- `lib/lockspire/protocol/discovery.ex` — runtime discovery metadata publication
- `lib/lockspire/protocol/jar.ex` — existing nested JWT/JWE handling precedent
- `lib/lockspire/protocol/jarm.ex` — current JARM signer to extend into nested JWE response production
- `lib/lockspire/storage/ecto/repository.ex` — active signing-key fetch behavior and `use`-partitioned key activation
- `lib/lockspire/storage/key_store.ex` — persistence seam that may need explicit encryption-key lookup support
- `test/lockspire/jwks_fetcher_test.exs` — guarded remote JWKS behavior to reuse and extend
- `test/lockspire/protocol/discovery_test.exs` — discovery truth tests to extend
- `test/lockspire/protocol/jarm_test.exs` — JARM signing tests to extend to nested encryption
- `test/lockspire/protocol/request_object_test.exs` — existing JOSE nested JWE test precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.Jarm` already owns JARM signing and is the right place to encapsulate sign-then-encrypt response production.
- `Lockspire.Protocol.AuthorizationFlow` already owns authorization redirect assembly and is the correct integration point for encrypted JARM delivery behavior.
- `Lockspire.JwksFetcher` already provides the bounded, guarded `jwks_uri` fetch and refresh contract Phase 72 should consume rather than reimplement.
- `Lockspire.Protocol.Discovery` already centralizes mounted-surface metadata truth and should remain the sole publication point for JARM encryption capability.
- `Lockspire.Domain.SigningKey` already models `use: :enc`, and repo tests prove active-key lifecycle isolation by `use`.
- Existing request-object JWE tests show working JOSE nested-JWT patterns the response-encryption path can mirror.

### Established Patterns

- Lockspire prefers explicit allow-lists, fail-closed security behavior, and protocol correctness owned in protocol modules rather than controllers or host code.
- Discovery metadata is a runtime contract tied to mounted/effective capability, not a maximum-theoretical feature catalog.
- Remote-key handling is intentionally narrow and guarded; no broad outbound metadata machinery should be introduced.
- The repo favors one shared capability source per concern and treats metadata/runtime drift as a bug.

### Integration Points

- Phase 72 planning should focus on `jarm.ex`, `authorization_flow.ex`, `discovery.ex`, `jwks_fetcher.ex`, `client.ex`, and the key-store/repository seam for encryption-key lookup.
- Tests should extend existing JARM, discovery, request-object JWE, and JWKS fetcher coverage rather than inventing isolated one-off patterns.
- If a new helper is introduced for client encryption-key resolution, it should be reusable by future message-signing work without becoming a second policy plane.

</code_context>

<specifics>
## Specific Ideas

- Ecosystem lessons to carry forward:
  - Successful servers keep encrypted responses opt-in, per-client, and narrower than the full JOSE universe.
  - Silent downgrade from encrypted to merely signed is a long-term support footgun.
  - Discovery should expose issuer capability, not per-client state and not transient operational-health state.
  - Great library DX comes from one coherent crypto story across registration, runtime behavior, and metadata.
- Recommendation bundle for this phase:
  - support both `jwks` and guarded `jwks_uri`,
  - allow one bounded recovery attempt but never downgrade confidentiality,
  - publish encryption metadata from one shared runtime capability helper,
  - keep the response-encryption surface to `RSA-OAEP-256` / `ECDH-ES` plus `A256GCM` / `A128GCM`,
  - require explicit signing and encryption metadata when encrypted JARM is enabled.

</specifics>

<deferred>
## Deferred Ideas

- Full algorithm parity with the broader Phase 40 request-object JWE surface, including CBC response-encryption modes
- Any second operator-configurable crypto-policy plane just for JARM encryption
- Discovery publication driven by transient health/readiness checks such as remote JWKS availability
- Silent downgrade from encrypted JARM to signed-only JARM
- FAPI 2.0 Message Signing strict enforcement, which remains Phase 74 scope

</deferred>

---

*Phase: 72-jarm-encryption-and-metadata*
*Context gathered: 2026-05-07*
