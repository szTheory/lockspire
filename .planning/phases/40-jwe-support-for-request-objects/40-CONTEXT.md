# Phase 40: JWE Support for Request Objects - Context

**Gathered:** 2026-04-29 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement nested JWT validation (Sign-then-Encrypt) in Protocol.Jar using JOSE.JWE and JOSE.JWS. Add RSA/EC encryption keypairs (`enc`) to Storage.KeyStore and JWKS endpoints.
</domain>

<decisions>
## Implementation Decisions

### Storage and Modeling of Encryption Keys
- **D-01:** Expand `Lockspire.Domain.SigningKey` and its associated `KeyStore` database schema to support `use: :enc` rather than creating a separate `EncryptionKey` domain model.

### Key Lifecycle Activation Logic
- **D-02:** Update `Lockspire.Storage.Ecto.Repository.activate_signing_key/2` to isolate its active key retirement logic by the `use` attribute (`:sig` vs `:enc`) so both can be active concurrently.

### JWE Decryption Pipeline Location
- **D-03:** Decrypt JWE in `Lockspire.Protocol.RequestObject` before passing the inner JWS to `Lockspire.Protocol.Jar.verify_signature/2`, keeping `Jar` stateless regarding server keys.

### JWE Algorithm Strictness
- **D-04:** Enforce strict allow-list for JWE algorithms. Allowed `alg`: `RSA-OAEP`, `RSA-OAEP-256`, `ECDH-ES`. Allowed `enc`: `A128CBC-HS256`, `A256CBC-HS512`, `A128GCM`, `A256GCM`. `RSA1_5` is explicitly rejected for FAPI compliance.

### JWE Parsing Strategy
- **D-05:** Manually pipe `JOSE.JWE.block_decrypt/2` binary output to `JOSE.JWT.verify` or `JOSE.JWS.verify` to handle nested JWT extraction, as `JOSE.JWT.decrypt/2` crashes on nested JWTs.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Codebase Structure
- `lib/lockspire/domain/signing_key.ex` — Model to expand for `use: :enc`
- `lib/lockspire/protocol/jwks.ex` — Dynamic mapping of keys to public JWKS
- `lib/lockspire/admin/keys.ex` — Key lifecycle admin API
- `lib/lockspire/storage/ecto/repository.ex` — Active key retirement logic
- `lib/lockspire/protocol/request_object.ex` — Request pipeline orchestration
- `lib/lockspire/protocol/jar.ex` — Pure verifier of JWS structures

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Domain.SigningKey` domain model already handles `use: :sig` and can easily be expanded.
- `Lockspire.Protocol.Jar` has an existing `@allowed_algorithms` allow-list pattern that should be replicated for JWE.

### Established Patterns
- Strict allowed algorithm lists (no `none`, no weak ciphers).
- `Protocol.Jar` is a pure verifier; server keys are kept out of it.
- `Repository` manages active keys by expecting at most one active key, which must be partitioned by `use`.

### Integration Points
- Key activation logic in `Repository.activate_signing_key/2`.
- Request object processing in `Protocol.RequestObject`.
- JWKS generation in `Protocol.Jwks`.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope
</deferred>