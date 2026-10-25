# Phase 176: Dedicated Verifier Custody & Compatible Runtime - Context

**Gathered:** 2026-10-25 (assumptions mode)
**Status:** Ready for planning
**Owner disposition:** After the four-part recommendation bundle, the owner said: “what do u rec? let's do that”. Adopt the recommended bundle, including the existing-endpoint-support clarification below.

<domain>
## Phase Boundary

Implement independent verifier-key custody across existing credential creation, rotation and authentication paths, with deliberate legacy compatibility and a safe reader-first rollout. This phase owns SEC-01 through SEC-05, VUP-01 and VUP-02. Phase 175's accepted entry baseline, independently verified compatibility qualification and frozen contract are its prerequisites; candidate, entry-main and eventual integrated-main evidence remain distinct.

Phase 177 owns maintenance commands, verifier rewrap, inventory/status, key-loss recovery, PostgreSQL maintenance contention/rollback and comprehensive disclosure proof. Phase 178 owns packaged dependency-pair journeys, final reviews and delivery/main acceptance. No schema, dependency, signing-envelope, algorithm or protocol-support expansion is selected.
</domain>

<decisions>
## Implementation Decisions

### Dedicated custody and operation-local configuration
- **D-01:** Implement the frozen purpose-specific setting `config :lockspire, Lockspire.Security.ClientSecretVerifier, ...` and its exact `:keys`, `:current`, `:write_mode` and `:legacy_read` grammar from `175-CONTRACT.md`. Use independent verifier keys; dedicated operations do not derive from or fall back to endpoint/session secrets or signing KEKs. Reject known configured cross-purpose byte reuse without claiming detection of remote, derived or unknown historical reuse.
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

### Folded Todos
None; the Phase 176 todo match returned zero pending todos.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, policy and evidence
- `AGENTS.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md` — SEC-01 through SEC-05, VUP-01/VUP-02 and later proof ownership.
- `.planning/ROADMAP.md` — Phase 176 boundary and dependencies.
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/MILESTONE-GUIDE.txt`
- `.planning/DEVELOPMENT-TRAIN.md`
- `.planning/RELEASE-TRAIN.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTEXT.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTRACT.md` — exact config, error, envelope, size, helper and maintenance contracts.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-COMPATIBILITY.json` — stable finite acceptance IDs and proof owners.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md` — approved native/migrated lifetime distinction.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-QUALIFICATION.json`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-VERIFICATION.md` — passed prerequisites and three visible non-authoritative prohibition flags.
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-FINAL-SOURCE.json` — entry, candidate and eventual accepted-main distinction.
- `.planning/research/v1.48-client-auth-key-isolation/SUMMARY.md`
- `.planning/research/v1.48-client-auth-key-isolation/ARCHITECTURE.md`
- `.planning/research/v1.48-client-auth-key-isolation/STACK.md`
- `.planning/research/v1.48-client-auth-key-isolation/PITFALLS.md`

### Runtime and supported surface
- `docs/supported-surface.md` — existing direct-client JWT slice and PAR/FAPI exclusions.
- `docs/client-secret-jwt-host-guide.md`
- `lib/lockspire/config.ex`
- `lib/lockspire/application.ex`
- `lib/lockspire/security/policy.ex`
- `lib/lockspire/security/key_encryption.ex`
- `lib/lockspire/security/key_encryption/key_set.ex`
- `lib/lockspire/clients.ex`
- `lib/lockspire/protocol/registration.ex`
- `lib/lockspire/admin/clients.ex`
- `lib/lockspire/client_lifecycle.ex`
- `lib/lockspire/protocol/client_auth.ex`
- `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`
- `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex`
- `lib/lockspire/protocol/introspection.ex`
- `lib/lockspire/protocol/revocation.ex`
- `lib/lockspire/protocol/device_authorization.ex`
- `lib/lockspire/protocol/backchannel_authentication.ex`
- `lib/lockspire/protocol/pushed_authorization_request.ex`
- `lib/lockspire/storage/client_store.ex`
- `lib/lockspire/storage/transaction_store.ex`
- `lib/lockspire/storage/ecto/repository/client_store.ex`
- `lib/lockspire/storage/ecto/repository/support.ex`

### Executable precedents
- `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` — positive device/CIBA/introspection/revocation and negative PAR/FAPI cases.
- `test/lockspire/security/client_secret_verifier_contract_test.exs`
- `test/lockspire/security/client_secret_verifier_compatibility_test.exs`
- `test/integration/client_secret_jwt_legacy_age_test.exs`
- `test/support/client_secret_verifier_fixtures.ex` — qualified authenticated legacy metadata reader; not a production implementation.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Security.Policy` currently owns legacy Plug seal/unseal, hashing and compatibility overloads. Keep its legacy API while introducing the dedicated custody boundary.
- Signing `KeyEncryption`/`KeySet` demonstrate OTP AEAD, base64 key decoding and redacted contexts. The verifier needs separate policy/format and operation-local invalid state.
- Phase 175 fixtures and actual-caller tests distinguish Plug wall-clock age, assertion time and configured lifecycle time, including equality/future/aged cases.
- Existing direct-client tests already exercise device authorization and CIBA success and PAR/FAPI rejection. Reuse their realistic endpoint outcomes.

### Established Patterns
- `Clients.rotate_secret_hash/0` currently calls the material generator and discards its verifier; the approved change removes that dependency.
- Direct registration and DCR currently generate material before choosing client ID; operator rotation calls the material helper without passing its existing ID. All three need coherent identity plumbing.
- `Config` resolves/caches signing keys and `Application` raises for invalid signing configuration. Verifier startup must retain a diagnosable invalid context while preserving unrelated hash authentication.
- `TokenExchange.Internal.ClientAuthentication` includes verifier ciphertext in the verified-identity fingerprint. Keep that concurrency/security invariant intact.

### Integration Points
- Final-ID selection and fallible material generation connect to direct/DCR/rotation persistence and existing store/transaction/audit seams.
- The shared JWT verifier reads a persisted client record and maps legacy failures to an allowlisted unavailable reason. Pass canonical client identity and the complete resolved context without disclosing crypto details.
- Device authorization, CIBA, introspection and revocation explicitly enable `client_secret_jwt`; PAR retains the narrower default method set. Test the actual boundary rather than inferring support from a generic reader inventory.
</code_context>

<specifics>
## Specific Ideas

- Owner accepted the complete recommendation bundle with “what do u rec? let's do that”; no additional product choice remains open in this discussion.
- The endpoint wording clarification preserves shipped behavior. It neither adds JWT support to PAR nor removes it from device authorization/CIBA. Record positive and negative endpoint cases explicitly.
- Apply the methodology's assumption-first, research-first, least-surprise host seam and one-shot recommendation lenses: reuse qualified decisions, keep host controls explicit, and avoid another menu of routine technical preferences.
</specifics>

<deferred>
## Deferred Ideas

- Phase 177: maintenance capability implementation, preview/apply/check, complete inventory, key rewrap/retirement, recovery workflows, PostgreSQL contention/rollback and comprehensive success/failure disclosure proof.
- Phase 178: package-installed journeys across both existing dependency pairs, configured-store integration proof, final review/audit and accepted-main delivery. Publication remains separate.
- UI quality retains its completed interview as the next substantial candidate; KMS/Vault, fleet coordination/hot reload, a generic secrets framework, new dependencies/schema/algorithms and expanded protocol support remain outside this phase.

### Reviewed Todos (not folded)
None; no pending todo matched.
</deferred>
