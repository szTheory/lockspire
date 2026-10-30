# Phase 176: Dedicated Verifier Custody & Compatible Runtime - Research

**Researched:** 2026-10-25  
**Domain:** Elixir/OTP authenticated encryption, OAuth client-secret-JWT credential storage and rollout compatibility  
**Confidence:** HIGH for frozen behavior and in-repo seams; MEDIUM for crypto runtime guidance

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Implementation Decisions
- **D-01:** Implement the frozen purpose-specific setting `config :lockspire, Lockspire.Security.ClientSecretVerifier, ...` and its exact `:keys`, `:current`, `:write_mode`, `:legacy_read` grammar from `175-CONTRACT.md`. Use independent verifier keys; dedicated operations do not derive from or fall back to endpoint/session secrets or signing KEKs. Reject known configured cross-purpose byte reuse without claiming detection of remote, derived or unknown historical reuse.
- **D-02:** Preserve four explicit states: absent setting with declared legacy compatibility; staged readers with legacy writes/reads; dedicated writes with legacy reads; dedicated writes with legacy rejection. Staged keys and even a staged current ID never activate dedicated writes. Dedicated writes require a configured current key. Legacy-write plus legacy-reject is invalid.
- **D-03:** Resolve an immutable node context until restart/redeploy. Retain invalid-present state and expose safe diagnostic reason codes. Affected verifier reads and verifier-producing writes fail locally; existing unrelated supported hash authentication remains available. Preserve complete-context override validation and the frozen internal/public error mappings. Do not copy signing configuration's raising whole-boot path or partially merge overrides with ambient configuration.
- **D-04:** Use the exact `LSCV1.<key_id>.<base64url-unpadded(payload)>` envelope, authenticated plaintext age discriminator and AAD bytes from the frozen contract. AES-256-GCM uses a fresh 12-byte IV and exactly 16-byte tag; bind purpose/header/key ID and exact canonical persisted client-ID bytes. Enforce canonical encoding, encoded/decoded bounds and exact structural lengths. Reserve every `LSCV` prefix; malformed or unknown dedicated input never retries as legacy. Preserve existing signing-envelope bytes and behavior.

### Final identity and coherent credential creation
- **D-05:** Direct registration and DCR choose the final persisted client ID before verifier sealing; operator rotation retains the existing ID. Cover every existing shared-secret writer, including Basic/post clients that currently receive verifier material. Persist hash/verifier pairs coherently and preserve existing one-time plaintext handoff, configured lifetimes, selected store/transaction authority and audit behavior. No temporary identity, identity-free dedicated fallback or persisted plaintext.
- **D-06:** Preserve `Clients.rotate_secret_hash/0` as `{hash, plaintext}` without identity or verifier configuration requirements, and remove its discarded-verifier generation. Preserve `Clients.rotate_secret_material/1`'s three-key success map and existing legacy `Policy` helper arities, binary-secret-key-base overloads, accepted legacy inputs and unseal error. Dedicated material requires explicit final identity and produces a typed failure before persistence when identity/configuration is unavailable. Routine error plumbing must fit these frozen public contracts; a necessary breaking change returns through an explicit GSD revision.
- **D-07:** Keep legacy endpoint-secret selection at the integration boundary and existing compatibility wrappers; dedicated crypto does not scan application configuration for fallback secrets. Reuse existing OTP/Plug/Ecto primitives and narrow purpose-specific modules. Internal decomposition is discretionary, but this phase does not create a generic encryption framework or alter signing custody.

### Native and migrated lifetime compatibility
- **D-08:** Apply the owner-approved native age policy from `175-POLICY-REVISION.md`: newly written dedicated verifier material has no extra Plug storage-age timer and follows authoritative configured client-secret lifetime, with client-app expiry checked separately. Configured `nil`/`0` and v0-unlimited secret lifetimes may remain eligible beyond 24 hours. This policy is already approved; do not reopen it as an undecided preference.
- **D-09:** Dedicated readers must support the frozen migrated age representation and preserve original authenticated finite deadlines: `signed_at_ms + trunc(max_age_seconds * 1000)`, valid at equality and expired strictly afterward. Configured app/secret deadlines independently reject at equality. Preserve legacy compatibility reads only under the selected policy; do not use `max_age: :infinity`, rejuvenate credentials, or mutate on authentication. Actual rewrap tooling remains Phase 177.
- **D-10:** Future, malformed, tampered, wrong-key, unsupported-shape and nonpositive/infinite migration-age inputs remain unsupported and unchanged. Preserve qualified historical tuple-three, tuple-two and map metadata handling through authenticated public APIs and safe term decoding wherever migration preparation is required. Hash/verifier agreement is a migration/check readiness condition, not a new per-request hash comparison. Recovery remains authorized secret rotation/reprovision, with workflow proof in Phase 177.

### Existing protocol support and reader-first rollout
- **D-11:** Preserve existing `client_secret_jwt` support on token exchange, introspection, revocation, device authorization and backchannel authentication/CIBA. Both device authorization and CIBA already opt into the shared verifier in production code and have positive tests. Preserve PAR rejection and the current FAPI exclusions. Interpret the frozen ledger phrase “do not add JWT support to PAR/device/CIBA” as a prohibition on expanding support, not an instruction to remove existing device/CIBA support. Use this explicit endpoint matrix in downstream research/plans and preserve the historical Phase 175 records. If a concrete implementation requirement still contradicts the frozen contract, resolve it explicitly rather than silently changing support.
- **D-12:** Route dedicated and permitted legacy reads through the same verifier policy while preserving HS256-only assertions, issuer-string audience, issuer/subject matching, bounded assertion lifetime, required JTI and replay behavior, endpoint authorization and client/secret lifecycle enforcement. Keep missing-verifier versus unavailable-verifier behavior and public `invalid_client` redaction. Dedicated custody does not add methods or algorithms.
- **D-13:** Preserve the ciphertext-sensitive verified-credential fingerprint in guarded issuance. A ciphertext change after authentication invalidates that identity; no successful token/grant side effects may follow. A consumed JTI stays consumed and retry needs a fresh assertion/JTI. Phase 176 preserves and regresses this behavior; the actual PostgreSQL maintenance race/fresh-retry proof remains Phase 177.
- **D-14:** Prove the finite staged rollout: deploy compatible readers and required read keys throughout the fleet while retaining legacy writes; activate dedicated writes explicitly only after reader readiness. Before any dedicated write, old-code rollback remains bounded by the proven legacy state. After any dedicated write, switching write mode back does not make old code safe; supported rollback retains compatible readers and keys. Local configuration/tests do not certify fleet parity, quiescence, backups or rollback safety. Rewrap/retirement tooling remains Phase 177 and full package journeys remain Phase 178.
- **D-15:** Build executable acceptance around the existing stable Phase 175 case IDs and these seven owned requirements. Keep qualification evidence immutable and future maintenance/package rows pending until their proof owners execute them. New runtime code/errors must be redacted from introduction; Phase 177's comprehensive disclosure ownership is not permission to introduce unsafe diagnostics now.

### Agent's Discretion
- Choose small, idiomatic module boundaries, fixture organization, scoped test grouping and plan decomposition within the frozen contract. No task count is prescribed.
- Reuse `KeySet` validation/Inspect and signing AEAD patterns selectively; their current-key requirements, duplicate-option behavior, binary signing format and raising boot semantics are not automatically suitable for this verifier contract.
- Resolve routine implementation choices without another preference interview. Escalate only demonstrated changes to the frozen security/public API/support contract or approved scope.

### Deferred Ideas (OUT OF SCOPE)
- Phase 177: maintenance capability implementation, preview/apply/check, complete inventory, key rewrap/retirement, recovery workflows, PostgreSQL contention/rollback and comprehensive success/failure disclosure proof.
- Phase 178: package-installed journeys across both existing dependency pairs, configured-store integration proof, final reviews/audit and delivery/main acceptance. Publication remains separate.
- UI quality retains its completed interview as the next substantial candidate; KMS/Vault, fleet coordination/hot reload, a generic secrets framework, new dependencies/schema/algorithms and expanded protocol support remain outside this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEC-01 | Host can encrypt newly persisted client-secret-JWT verifier material with dedicated rotatable keys independent of endpoint/session secrets and signing-key KEKs. | Verifier-only config and AEAD module; envelope and key grammar below. |
| SEC-02 | Host can explicitly select current/read keys and compatibility/write mode; malformed or missing required key configuration fails clearly without silently falling back or unexpectedly breaking unrelated host authentication at boot. | Immutable operation-local config context; explicit state/error matrix and safe diagnostics. |
| SEC-03 | Host can reject tampered, malformed, unknown-key/version and cross-client/purpose verifier envelopes through authenticated, text-safe storage and redacted fail-closed errors. | Strict bounded parser, AEAD/AAD binding, reserved-prefix routing and public error mapping. |
| SEC-04 | Operator and registration callers can create or rotate credentials through every existing shared-secret writer with a coherent persisted hash/verifier pair, preserving one-time secret handoff and configured client/secret lifetimes. | Final-ID-first writer integration map and public helper compatibility details. |
| SEC-05 | Integrator can authenticate with dedicated-key verifiers across all existing supported direct-client endpoints while retaining HS256, issuer audience, required JTI/replay protection and the current PAR/FAPI exclusions. | Shared verifier reader integration plus precise endpoint matrix and existing endpoint tests. |
| VUP-01 | Existing hosts can read usable legacy Plug.Crypto verifier rows during explicit compatibility and deliberately reject them afterward; aged/unreadable rows have a qualified disposition, with no silent age bypass or change to configured credential expiry. | Phase 175 metadata/age qualification and native-versus-migrated lifetime policy. |
| VUP-02 | Host operator can follow and verify a reader-first rolling deployment with explicit writer activation and truthful code/config rollback limits, so old nodes never encounter an unsupported write format in the supported sequence. | Finite rollout state machine; tests prove local transitions while fleet parity remains host-owned. |
</phase_requirements>

## Summary

Implement a narrowly scoped `Lockspire.Security.ClientSecretVerifier` custody and policy boundary using existing OTP crypto, while keeping `Security.Policy`'s legacy Plug.Crypto wrapper behavior intact. Resolve a complete immutable verifier context at startup/redeploy; preserve an invalid-present context as diagnosable and make only verifier-dependent operations fail. Bind a dedicated `LSCV1` envelope to the purpose, version, key id and final persisted client id, and route every `LSCV`-prefixed input to the dedicated parser so malformed ciphertext cannot downgrade to legacy. [VERIFIED: 175-CONTRACT.md:42-120; quote: `:write_mode` is `:legacy` or `:dedicated`; `:legacy_read` is `:allow` or `:reject`; `LSCV1.<key_id>.<base64url-unpadded(payload)>`; `LSCV1.` is the only supported version.]

The implementation crosses configuration, helper compatibility, three writer paths and the shared client-auth reader. The critical compatibility seam is preserving the exact existing helper outputs and legacy overloads while making dedicated sealing require final identity and return typed errors before persistence. Keep existing protocol boundaries: token exchange, introspection, revocation, device authorization and CIBA already support `client_secret_jwt`; PAR remains excluded and the current FAPI exclusions remain. [VERIFIED: 175-CONTRACT.md:142-183; quote: `Clients.rotate_secret_hash/0`; `Clients.rotate_secret_material/1`; `{hash, plaintext}`; `client_secret_jwt_verifier_encrypted`.]

**Primary recommendation:** Build the operation-local configuration/context and dedicated envelope first, then route legacy and dedicated verifier reads through one typed internal policy; update final-ID-first writers and endpoint caller tests without changing schema, dependencies, signing bytes, helper success shapes or supported auth methods.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Verifier key configuration and safe diagnostics | API / Backend | — | Library runtime configuration resolves once into node-local state; no operator UI or external service is in this phase. |
| Envelope seal/open, parsing and age classification | API / Backend | — | Protocol verifier material is encrypted/decrypted within Lockspire's security boundary. |
| Credential creation and persistence | API / Backend | Database / Storage | Registration/rotation callers generate paired credentials; selected stores persist them atomically with existing lifecycle authority. |
| Client authentication | API / Backend | Database / Storage | Shared verifier read feeds endpoint authentication and lifecycle enforcement. |
| Deployment sequencing and rollback | Host Operations | API / Backend | Lockspire provides explicit modes; operators deploy compatible readers and keys before enabling writes. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Erlang/OTP `:crypto` | OTP 28.5 in the qualification environment | AES-256-GCM seal/open with AAD | Already part of the supported Elixir runtime; official docs define one-shot AEAD semantics and tag handling. [CITED: https://www.erlang.org/doc/apps/crypto/crypto.html] |
| Plug.Crypto | 2.2.1 locked | Preserve and read existing legacy verifier rows | Existing wrapper and Phase 175 authenticated-reader qualification use this package; it must remain the legacy path. [VERIFIED: mix.lock:43-44; quote: `"plug_crypto": {:hex, :plug_crypto, "2.2.1"`; 175-CONTRACT.md:1-40] |
| Elixir `Application` runtime config | Elixir 1.19.5 / OTP 28 in qualification | Resolve host-supplied verifier settings | Existing Lockspire configuration and startup conventions; official Elixir guidance reserves `runtime.exs` for runtime config. [CITED: https://hexdocs.pm/elixir/config-and-distribution.html] |
| Existing Ecto client stores | ecto_sql 3.13.5 locked | Store the text envelope alongside existing credential hash | The phase explicitly keeps storage shape and selected transaction authority; no schema addition is selected. [VERIFIED: mix.lock:11; quote: `"ecto_sql": {:hex, :ecto_sql, "3.13.5"`; 175-CONTRACT.md:156-183] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing `KeySet` | In-repo | Reuse key-id/base64 validation conventions selectively | For verifier key parsing only; do not inherit signing key's required-current or boot-failure semantics. [VERIFIED: 175-CONTRACT.md:48-53; quote: `Use the existing KeySet base64/base64url conventions`; context D-03] |
| Plug.Crypto safe term APIs | 2.2.1 locked | Authenticated legacy metadata read followed by safe decode | Only for the legacy migration-age representation; never decode before successful public authenticated decrypt. [CITED: https://plug-crypto.hexdocs.pm/2.2.0/Plug.Crypto.html; 175-CONTRACT.md:24-40] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Purpose-specific verifier context/envelope | Reuse signing KEK or existing `LSK` envelope | Rejected by locked custody decision: it couples key purpose and binds the wrong context; signing format and behavior must remain byte-for-byte stable. [VERIFIED: 175-CONTRACT.md:55-60,107-120; quote: `It is separate from endpoint/session secrets and signing KEKs`; `The legacy signing envelope is unchanged.`] |
| Existing OTP AEAD | Add a crypto dependency or generic cipher framework | Unneeded scope and new dependency/security surface; phase decision requires existing primitives and a narrow module. [VERIFIED: 176-CONTEXT.md, D-07; quote: `Reuse existing OTP/Plug/Ecto primitives and narrow purpose-specific modules.`] |
| Phase 176 local state proof | Claiming fleet-wide readiness from local tests | Local configuration cannot attest node parity, quiescence, backups or rollback safety; only test the documented sequence and state its host-side preconditions. [VERIFIED: 176-CONTEXT.md, D-14; quote: `Local configuration/tests do not certify fleet parity, quiescence, backups or rollback safety.`] |

**Installation:** None. No package additions, schema changes or algorithm changes are in scope. [VERIFIED: 176-CONTEXT.md, Phase Boundary; quote: `No schema, dependency, signing-envelope, algorithm or protocol-support expansion is selected.`]

## Project Constraints (from AGENTS.md)

- Preserve Lockspire as an embedded companion library, separate from Sigra; do not turn it into a required standalone auth service.
- Keep protocol core, storage, generators, Plug/Phoenix integration and admin surfaces bounded; host owns account resolution, claims, redirects, branding and product policy.
- Preserve security defaults including PKCE S256, exact redirect matching, hashed client secrets, single-use short-lived auth codes, refresh rotation/family revocation, no implicit flow, no `alg=none`, and strong redaction.
- No admin UI copy changes are needed for this phase.

## Architecture Patterns

### Recommended Project Structure

Add one purpose-specific security module and its tests; update existing config, helper, writer and reader seams rather than creating a generic encryption subsystem. Keep fixtures in separate new test support files so Phase 175's frozen qualification artifacts remain immutable. [VERIFIED: 176-CONTEXT.md D-07,D-15; quote: `this phase does not create a generic encryption framework`; `Keep qualification evidence immutable`.]

### Pattern 1: Immutable validated context, operation-local failures

**What:** Resolve absent/valid/invalid-present states once at app startup, store a nonsecret diagnostic summary and resolved key bytes in immutable node-local state, and pass complete explicit context overrides through verifier operations. A verifier caller receives typed internal failure; application start must not be made contingent on optional verifier configuration. [VERIFIED: 175-CONTRACT.md:55-86; quote: `immutable node context through restart/redeploy`; `Present-but-invalid configuration remains diagnosable as invalid`; `unrelated supported hash authentication stays available`.]

**When to use:** All dedicated seal/open paths and the shared legacy/dedicated read router.

### Pattern 2: Strict authenticated envelope

**What:** Parse exact bounded ASCII structure and canonical unpadded base64url before decryption; enforce IV/tag lengths before calling OTP crypto; use AAD that binds purpose/header/key id/canonical ID; validate decrypted version, secret length, age discriminator and exact payload consumption. Keep legacy and dedicated read branches disjoint by reserved prefix.

```elixir
# Shape only; exact constants and lengths are the frozen contract values.
{ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, 16, true)
plaintext = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, aad, tag, false)
```

OTP documents encryption as `{CipherText, Tag}` and notes decryption does not validate supplied tag length, so reject any tag length other than the frozen 16 bytes before calling it. The frozen envelope requires a fresh 12-byte IV and exactly 16-byte tag. [CITED: https://www.erlang.org/doc/apps/crypto/crypto.html; VERIFIED: 175-CONTRACT.md:96-120; quote: `AES-256-GCM uses a fresh 12-byte IV and exactly 16-byte tag`; `LSCV1.` is the only supported version.]

### Pattern 3: Final identity before credential material

**What:** Choose direct-registration and DCR IDs before generating/sealing verifier material; use the existing client ID for rotation. Persist secret hash and verifier through their existing transaction/store boundary and return plaintext once only after successful write. Generation/configuration failures must be represented before the store write.

**Current evidence:** `Clients.rotate_secret_hash/0` currently calls the material generator then discards the verifier, and `rotate_secret_material/1` returns the three existing fields. [VERIFIED: lib/lockspire/clients.ex:86-105; quote: `def rotate_secret_hash do`; `material = rotate_secret_material()`; `client_secret_jwt_verifier_encrypted:`.]

### Pattern 4: Shared reader policy, unchanged endpoint gates

**What:** Keep `ClientAuth.authenticate/3` and each endpoint's method gate, replacing the storage opening implementation behind one verifier policy. Map missing verifier separately from malformed/unavailable and preserve external `invalid_client` redaction.

**Existing endpoint matrix:** token exchange, introspection and revocation accept JWT; device authorization and backchannel/CIBA also accept JWT today; PAR rejects JWT; current FAPI posture excludes it. Phase 175 wording “do not add ... device/CIBA” means do not expand that current matrix; do not remove shipped device/CIBA support. [VERIFIED: docs/supported-surface.md:96-107,170-172; quote: `client_secret_jwt on POST /par`; test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs:54-133,179-200; quote: `representative direct-client surfaces accept verified client_secret_jwt callers`; `PAR remains outside the shipped client_secret_jwt surface`.]

### Anti-Patterns to Avoid

- Falling back to endpoint/session secret or signing KEK when verifier config is absent/invalid.
- Silently treating invalid-present config as absent, throwing a whole-app boot failure, or partially merging incomplete overrides with ambient config.
- Retrying malformed/unknown `LSCV` data as legacy Plug ciphertext.
- Sealing before final `client_id` selection, generating verifier material in hash-only helper, or persisting plaintext.
- Reworking authenticated legacy timestamps to a fresh deadline, accepting future timestamps, or using an infinite-age bypass.
- Changing CIBA/device/PAR/FAPI authentication support or signing envelope bytes.
- Modifying frozen Phase 175 ledger/qualification files or claiming Phase 177/178 evidence from Phase 176 tests.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Authenticated encryption | Custom AES/GCM or tag comparison | OTP `:crypto.crypto_one_time_aead/7` | OTP provides the AEAD primitive and AAD; the caller must enforce exact nonce/tag format and treat `error` as a closed failure. [CITED: https://www.erlang.org/doc/apps/crypto/crypto.html] |
| Legacy authenticated metadata | Custom Plug token parser / raw `binary_to_term` | Plug.Crypto public decrypt, then `Plug.Crypto.non_executable_binary_to_term/2` | Must authenticate first and safely decode only qualified historical shapes. [CITED: https://plug-crypto.hexdocs.pm/2.2.0/Plug.Crypto.html; VERIFIED: 175-CONTRACT.md:24-40; quote: `Decode only after public authenticated decrypt and safe term decoding.`] |
| Key format validation | New ad-hoc key parser | Reuse `KeySet` conventions and adapt purpose-specific constraints | Avoid drift in supported base64/base64url handling while respecting verifier's reader-only staging and non-raising context rules. [VERIFIED: 175-CONTRACT.md:48-53; quote: `Use the existing KeySet base64/base64url conventions`.]

**Key insight:** Security is mostly in boundary discipline: a correct AEAD operation is not enough if config fallback, identity choice, malformed-input downgrade, deadline rejuvenation or public error mapping weakens the surrounding contract.

## Common Pitfalls

### Pitfall 1: Current key accidentally activates writes
**What goes wrong:** A rolling deployment can write new ciphertext while older code still serves requests.  
**Why it happens:** Treating a staged `:current` key as implicit activation.  
**How to avoid:** Gate write format only on explicit `:write_mode`; stage readers/keys fleet-wide before changing it.  
**Warning signs:** Any mode-derived default or one-step deployment instructions.

### Pitfall 2: Breaking public success shapes to return typed errors
**What goes wrong:** Existing host integrations destructure a tuple/map or pass the legacy binary key overload and break.  
**Why it happens:** Retrofitting identity/config arguments into public helper success paths.  
**How to avoid:** Preserve frozen success contract and introduce an explicit fallible internal/dedicated material operation; let existing helpers keep the legacy wrapper where required.  
**Warning signs:** Changes to map keys, tuple order, arity or accepted legacy binary inputs.

### Pitfall 3: Wrong identity gets authenticated
**What goes wrong:** A generated ID differs from the one in AAD and the persisted verifier cannot be opened, or can be substituted across client rows.  
**Why it happens:** Existing direct/DCR paths generate secret material before choosing IDs.  
**How to avoid:** Finalize canonical client ID first and bind exact persisted UTF-8 bytes; rotation uses its current ID.  
**Warning signs:** Temporary/generated-later IDs or normalization before AAD construction.

### Pitfall 4: AEAD accepts a truncated supplied tag
**What goes wrong:** Short tags can be accepted depending on matching prefix.  
**Why it happens:** OTP docs explicitly place tag-length validation responsibility on the caller.  
**How to avoid:** Require total payload structure and 16-byte tag before decrypt; reject malformed lengths without exception leakage. [CITED: https://www.erlang.org/doc/apps/crypto/crypto.html]

### Pitfall 5: Legacy age logic changes authority
**What goes wrong:** Migration inadvertently revives expired/future legacy verifier rows or makes new native rows expire after Plug's default day.  
**Why it happens:** Treating Plug storage age and configured client/secret lifetime as one clock.  
**How to avoid:** Native dedicated data uses configured secret lifetime; migrated data preserves authenticated original finite deadline; client-app expiry stays independent.  
**Warning signs:** `:infinity`, age reset on seal, or tests that omit equality/future/lifecycle boundaries. [VERIFIED: 175-POLICY-REVISION.md:15-25; quote: `valid at exact equality, expired only after it`; `no additional Plug storage-age timer`.]

### Pitfall 6: Protocol support inferred from the shared reader
**What goes wrong:** Changing a shared verifier accidentally widens PAR/FAPI support or removes existing device/CIBA support.  
**Why it happens:** Endpoint method allowlists are separate from the shared ciphertext reader.  
**How to avoid:** Regress positive token/introspection/revocation/device/CIBA and negative PAR/FAPI cases at real caller boundaries.

## Code Examples

The envelope is deliberately represented here as a structural sketch; production acceptance should use exact frozen bytes and adversarial fixtures rather than an alternate example encoding.

```elixir
# Dedicated writes require the final persisted identity and complete context.
# Contract values: client_id is canonical persisted UTF-8; no normalization.
case ClientSecretVerifier.seal(secret, client_id, verifier_context) do
  {:ok, encrypted} -> persist_hash_and_verifier(hash, encrypted)
  {:error, reason} -> {:error, reason}
end
```

The helper names above are illustrative only; do not treat them as frozen public API. Contract discrete values are quoted verbatim: `:current` is an optional key ID in `:keys`; `:write_mode` is required enum `:legacy` or `:dedicated`; `:legacy_read` is required enum `:allow` or `:reject`; dedicated material requires explicit final client ID. [VERIFIED: 175-CONTRACT.md:48-53,152-154; quote: the listed keys and enum values above.]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plug.Crypto verifier encryption derived from endpoint `secret_key_base` | Dedicated purpose-specific key set and authenticated text envelope; legacy path retained by explicit read policy | Phase 176 target, not yet implemented | Enables independent verifier rotation without changing signing custody or legacy overloads. [VERIFIED: lib/lockspire/security/policy.ex:178-212; quote: `Plug.Crypto.encrypt`; `Plug.Crypto.decrypt`; 175-CONTRACT.md:44-60] |
| Sealing based only on secret and secret salt | Bind envelope AAD to purpose/version/key ID/final client ID | Phase 176 target, not yet implemented | Prevents cross-client/purpose substitution; requires choosing final client ID before all verifier-producing writes. [VERIFIED: 175-CONTRACT.md:107-120,156-183; quote: AAD structure; `Direct registration, DCR, and operator rotation all choose or retain the final persisted client ID before sealing.`] |

**Deprecated/outdated:** No phase-176 implementation exists yet, so describe the current legacy route as retained compatibility behavior rather than claim it is already deprecated. No algorithm/dependency changes are authorized.

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json` (`workflow.nyquist_validation: true`). Existing project commands are defined in `mix.exs`; use the focused tests during tasks and the established CI suite at phase gate. Commands are inventory recommendations; no tests were run during this research.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, project Elixir 1.19.5 / OTP 28.5 selected in this environment |
| Config file | `test/test_helper.exs`, `mix.exs` aliases |
| Quick run command | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` |
| Full suite command | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix ci` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SEC-01/02 | Key grammar, config state matrix, independent-key behavior, invalid-present local errors and hash-auth availability | unit | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` | No — Wave 0 |
| SEC-03 | Strict parse bounds, canonical encoding, AAD identity/purpose binding, key/version/tag/tamper rejection and redaction | unit/property | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` | No — Wave 0 |
| SEC-04 | Direct/DCR/operator writers persist coherent pairs under final client ID and preserve one-time plaintext/lifetimes | integration | `MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_writers_test.exs` | No — Wave 0 |
| SEC-05 | Supported endpoint matrix, HS256/audience/JTI/replay/lifecycle/fingerprint invariants; PAR/FAPI still reject | integration | `MIX_ENV=test mix test test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/client_auth_test.exs` | Yes — existing caller coverage, extend for dedicated verifier behavior |
| VUP-01 | Legacy allow/reject, authenticated metadata shapes, original deadline equality/future/aged/unreadable and no authority extension | integration | `MIX_ENV=test mix test --include integration test/integration/client_secret_jwt_legacy_age_test.exs` | Yes — Phase 175 qualified baseline; add implementation-level cases in a new test module |
| VUP-02 | Staged readers, explicit activation, pre-write rollback and post-write incompatibility boundary | contract/integration | `MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_rollout_test.exs` | No — Wave 0 |

### Sampling Rate

- **Per task commit:** relevant new focused ExUnit file plus affected helper/caller tests.
- **Per wave merge:** focused verifier + writer + endpoint tests, including `--include integration` where persistence is used.
- **Phase gate:** `mix ci` on the intended candidate, in the project's selected supported runtime pair.

### Wave 0 Gaps

- [ ] `test/lockspire/security/client_secret_verifier_test.exs` — config grammar/state, envelope parser/AEAD, strict downgrade rejection, context override, typed error and redaction semantics.
- [ ] `test/lockspire/security/client_secret_verifier_rollout_test.exs` — reader-first activation/rollback state contract.
- [ ] `test/integration/client_secret_verifier_writers_test.exs` — direct registration, DCR and operator rotation with final IDs and stored hash/verifier agreement.
- [ ] Add new assertions to existing endpoint caller suites for dedicated reads and invalid/missing verifier behavior; preserve frozen Phase 175 qualification source files unchanged.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve client-secret-JWT `HS256`, issuer-string audience, client identity, assertion-age limit and required replay-protected JTI. |
| V3 Session Management | no | No browser session or user-session behavior changes. |
| V4 Access Control | yes | Preserve each endpoint's existing auth-method allowlist, client lifecycle checks, PAR exclusion and FAPI policy. |
| V5 Input Validation | yes | Strict bounded ASCII envelope parser, exact grammar/length checks and no dedicated-to-legacy fallback. |
| V6 Cryptography | yes | OTP AES-256-GCM with fresh 12-byte IV, exactly 16-byte tag, authenticated purpose/version/key/client AAD; no custom crypto. [CITED: https://www.erlang.org/doc/apps/crypto/crypto.html; VERIFIED: 175-CONTRACT.md:96-120; quote: exact lengths and AAD.] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Ciphertext copied between clients or purposes | Tampering / Elevation | Bind exact client ID and purpose/version/key ID in AAD; mutation tests. |
| Truncated/forged tag or noncanonical envelope | Tampering | Check exact structure and 16-byte tag before crypto; authenticated decryption failures map to safe unavailable reason. |
| Config downgrade / old-node exposure | Tampering / Elevation | Invalid-present state never falls back; explicit reader-first deploy then writer activation; truthful post-write rollback boundary. |
| Verifier, key or ciphertext leaks through diagnostics | Information disclosure | Allowlist reason codes/metadata, avoid raw values in exceptions/log contexts, assert sentinels absent in protocol and observability surfaces. |
| Legacy deadline rejuvenation | Elevation | Preserve authenticated finite migration deadline with equality-valid/strictly-after expiry; apply independent configured client/secret deadlines. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Compile and ExUnit | ✓ | Elixir 1.19.5 / Mix 1.19.5 | Use repo-supported asdf pair |
| Erlang/OTP | `:crypto` AEAD | ✓ | OTP 28.5 | None for phase runtime proof |
| PostgreSQL | Existing integration tests and persisted writer proof | ✓ | `pg_isready`: `/tmp:5432 - accepting connections` | None for persistence acceptance |
| Plug.Crypto | Legacy compatibility reads | ✓ | 2.2.1 in `mix.lock` | None; dependency is already locked |

**Missing dependencies with no fallback:** None observed.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Invalidation diagnostics can use existing startup validation hooks without exposing key material; exact internal module/context split is left to planning. | Architecture Patterns | A poor boundary could either break unrelated authentication or produce unsafe diagnostics. |
| A2 | New unit/integration test paths listed above are recommendations, not frozen public API or mandated filenames. | Validation Architecture | Planner may select different files; acceptance behavior must remain covered. |

## Open Questions

1. The frozen contract provides exact internal error atoms but says they should not be added to the currently exported API until the owning implementation plan. Planner should keep them internal and map through existing public `invalid_client` behavior; only a demonstrated need for a breaking public error contract should trigger GSD revision.
2. Phase 176 can prove local state transitions but cannot verify a host fleet has identical key distribution, mode, backups or quiescence. Deployment instructions must state these host-owned preconditions; no local test should assert fleet readiness.

## Sources

### Primary / project source of truth

- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTRACT.md` — exact key grammar, error mapping, envelope bounds, helper API and writer/reader inventory.
- `.planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-CONTEXT.md` — owner-accepted decisions D-01 through D-15, discretion and explicit deferred scope.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-COMPATIBILITY.json` — frozen semantic acceptance case IDs and future proof ownership.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md` and `175-VERIFICATION.md` — qualified native/migrated age behavior and prerequisite status.
- `lib/lockspire/security/policy.ex`, `lib/lockspire/config.ex`, `lib/lockspire/application.ex`, `lib/lockspire/clients.ex`, `lib/lockspire/client_lifecycle.ex`, `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` — current production seams.
- `test/lockspire/security/client_secret_verifier_compatibility_test.exs`, `test/integration/client_secret_jwt_legacy_age_test.exs`, `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` — compatibility and actual endpoint regression precedents.

### Official external documentation

- [Erlang/OTP 28 crypto API](https://www.erlang.org/doc/apps/crypto/crypto.html) — AEAD encryption/decryption return shape and caller responsibility to check tag length.
- [Plug.Crypto 2.2.0 API documentation](https://plug-crypto.hexdocs.pm/2.2.0/Plug.Crypto.html) — public decrypt and authenticated age options; version 2.2.1 is pinned locally.
- [Elixir runtime configuration guide](https://hexdocs.pm/elixir/config-and-distribution.html) — runtime configuration belongs in runtime configuration path.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing locked Elixir/OTP/Plug.Crypto dependencies and no new package decision.
- Architecture: HIGH — writer/reader paths and public helper contracts are explicit in the frozen contract and source.
- Pitfalls: HIGH — owner decisions and qualified tests define the main failure modes; AEAD tag caveat is corroborated by official OTP docs.

**Research date:** 2026-10-25  
**Valid until:** 2026-11-24 (phase contract is frozen; runtime guidance should be rechecked if OTP support changes)
