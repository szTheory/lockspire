# Phase 164: Client-Secret Expiry & Atomic Rotation - Research

**Researched:** 2026-10-20  
**Domain:** OAuth dynamic client registration, Elixir/Ecto credential lifecycle  
**Confidence:** HIGH for repository seams and selected behavior; MEDIUM for standards interpretation

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Nil and zero secret duration mean unlimited; a positive integer means seconds from secret issuance. Store finite UTC whole-second deadlines and nil for unlimited. Use current policy for issuance/replacement only; never recompute existing credentials on policy edits or reads.
- **D-02:** Validate nil or integer 0..2_147_483_647 consistently at supported secret-policy write/use boundaries. Malformed policy or unsupported durable lifetime state is a configuration/server error, never unlimited or a misleading invalid credential response.
- **D-03:** Apply DCR secret defaults only to self-registered clients and their replacements. Direct/operator registrations retain their existing policy boundary. Use current registration provenance, not assumptions based on a shared struct.
- **D-04:** Registration and management responses report the effective current secret deadline as Unix seconds or 0 for unlimited, including legacy v0. Omit client_secret_expires_at for non-secret authentication methods; confidential does not imply shared-secret authentication. Preserve plaintext omission on reads/updates. Do not echo raw advisory dates as enforced deadlines.
- **D-05:** Share strict secret eligibility across client_secret_basic, client_secret_post and client_secret_jwt. A finite secret is eligible only while now < deadline; equality is expired, with no assertion-skew allowance. Preserve existing endpoint invalid_client/challenge mapping and non-disclosure of expiry details.
- **D-06:** Revalidate secret authority at final guarded issuance using current locked client state, verified credential identity and a fresh decision time after every required blocking client/grant/token lock. A request verified before expiry or committed rotation must not consume a code, rotate a refresh token or issue tokens afterward under stale authority. Preserve consistent lock ordering and rollback semantics.
- **D-07:** Secret-JWT algorithm, assertion expiry/claims and replay controls remain independently effective. Final guarded issuance rechecks credential eligibility/identity, not the already-consumed assertion JTI. Keep remote operations and response encoding outside locks.
- **D-08:** Secret expiry alone does not revoke or cap issued access/refresh tokens. Confidential refresh still requires current valid credentials. Do not gate exchange subject/actor token validity, online target-token checks or queued CIBA push solely on issuing-client secret expiry; distinguish requester authentication from issuing-app eligibility.
- **D-09:** Public/private-key/mTLS authentication does not acquire a secret-expiry gate, even if a direct confidential registration has dormant shared-secret material. No new authentication method or verifier encryption-key design is included.
- **D-10:** Replacement hash, secret-JWT verifier, issuance timestamp, deadline, lifetime version and audit commit or roll back together against the current row. Establish the replacement deadline and audit time after blocking locks. No old-secret overlap after commit; a failed write/audit must not return successful plaintext delivery or leave partial credential state.
- **D-11:** V0 secret dates remain advisory until explicit replacement. Under the current-row lock, canonicalize all legacy deadlines to nil, set only the replacement secret deadline under current applicable policy, then promote to v1. V1 replacement preserves authoritative app and management-token deadlines. Never flip version alone, extend the app, restore a stale row, or revive old dates.
- **D-12:** Preserve host-authorized rotation behavior: no old-secret proof is required, and an expired secret can be replaced. Rotation never enables a disabled app or renews an expired app. Concurrent authorized operator commands serialize; only the last committed replacement remains current. Do not invent a new stale-command/CAS error contract or promise both returned secrets remain current.
- **D-13:** Preserve the existing public behavior around rotating dormant material for confidential non-secret methods, while keeping lifetime applicability and wire metadata method-aware. Changing that operator API policy is unnecessary for this phase.
- **D-14:** Extend the existing declared lifetime-aware adapter/shared transaction contract and its conformance tests. No new schema migration, general capability framework, expiry worker or runtime dependency is needed. Unsupported adapters must not silently discard replacement lifecycle fields or separate audit authority.
- **D-15:** Prove nil/zero/positive issuance, strict boundary equality, microsecond/default-clock handling, policy edits, provenance, no-secret omission, legacy dates/promotion, all three secret-auth methods, independent JWT timing/replay and preservation of existing token validity. Focused tests accompany each implementation slice.
- **D-16:** Use deterministic independent PostgreSQL sessions with observable lock blockers and injected clocks for preverified-secret rotation races, expiry during client/later-grant waits, competing operator rotations, and audit/write rollback. Assert durable final state and no unintended code/token consumption; sleeps are not expiry proof.
- **D-17:** Exercise actual finite-secret rotation/authentication events in redaction checks; do not claim coverage from zero observed events. Preserve hashed storage and existing verifier protection, and never emit plaintext/hash/verifier material in audit, logs, telemetry or operator errors.
- **D-18:** Keep guidance accurate for changed behavior now; final cross-phase guidance remains Phase 166. Read PRODUCT.md before changing admin text and follow vocabulary/retired wording contracts. No admin redesign, new recovery credential, dependency or host responsibility is added.

### the agent's Discretion

Helper names, callback transport, explicit clock plumbing and focused test organization are implementation choices within these decisions. Prefer ordinary Elixir functions and existing transaction seams. Preserve public APIs unless a minimal additive change is necessary and explicitly checked against compatibility contracts.

### Deferred Ideas (OUT OF SCOPE)

Management-token finite enforcement/recovery is Phase 165. Final cross-phase clean-room, security, CI and complete guidance proof is Phase 166. Dedicated secret-JWT encryption key SEC-01, secret overlap, app renewal, zero-downtime bridge, new operator concurrency APIs and new non-secret rotation prohibitions are outside this phase.

### Folded Todos

The audit-dcr-default-lifetime-semantics todo is already milestone scope. Its shared-secret portion informs this phase; keep it pending with resolves_phase: 166. Do not close the umbrella todo or implement management-token lifecycle here.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DCR-07 | An app receiving a shared secret gets stored and advertised secret expiry that matches its effective policy, including unlimited and non-secret cases. | DCR issuance, lifetime-field validation, response shaping, legacy normalization and provenance seams below. |
| DCR-08 | A client using Basic, post or secret-JWT authentication is accepted or rejected consistently according to secret expiry, while independent JWT assertion timing and replay protection remain enforced. | Shared authentication eligibility and the existing preverified identity/final-issuance guard; JWT checks remain separate. |
| DCR-09 | An operator can rotate a shared secret with its replacement expiry committed atomically, with prior-credential and changed-policy behavior matching the selected contract. | Locked client-store rotation, transaction/audit wrapping, current policy read, post-lock clock, and concurrency/rollback test patterns. |
</phase_requirements>

## Summary

Implement secret expiry as a credential-lifecycle extension of the Phase 163 client lifetime contract. Current code already carries `client_secret_expires_at`, `lifetime_version`, adapter declaration, current-client row locking and transaction authority. The gaps are concentrated: DCR construction currently computes secret deadlines with direct addition and a zero-to-now behavior; policy validation checks the app duration only; response serialization emits raw stored dates for every client; shared-secret authentication checks material but no shared deadline; final token issuance checks the verified credential fingerprint but not its current secret eligibility; and operator rotation captures its timestamp before lookup and lock. [VERIFIED: `lib/lockspire/client_metadata.ex:41-109,283-291`; `lib/lockspire/protocol/dcr_policy.ex:87-153`; `lib/lockspire/storage/ecto/server_policy_record.ex:54-99`; `lib/lockspire/web/registration_json.ex:41-66`; `lib/lockspire/protocol/client_auth.ex:40-52,289-340`; `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:228-339`; `lib/lockspire/admin/clients.ex:167-190`]

Preserve the existing transaction and adapter shape: derive the replacement deadline from current provenance and policy only after the current row is locked; atomically persist hash, verifier, rotation time, deadline, lifetime version and audit; return plaintext only after commit. At issuance, apply one shared strict secret gate at initial auth and again at the final guarded boundary using the current row and freshly sampled time after client and later grant/token locks. Do not re-check a JWT JTI already recorded during assertion verification. [VERIFIED: `lib/lockspire/storage/client_store.ex:10-45`; `lib/lockspire/storage/ecto/repository/client_store.ex:169-202`; `lib/lockspire/client_lifecycle.ex:52-72,99-109`; `lib/lockspire/protocol/client_auth/client_secret_jwt.ex:19-33,163-182`; `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:228-339`]

**Primary recommendation:** Add one domain-level secret eligibility function and one provenance-aware deadline calculation, then thread them through the existing `ClientAuth`, guarded token issuance and adapter rotation callbacks. Keep legacy-v0 dates advisory until rotation canonicalizes them; keep non-secret auth methods outside secret gating and omit their secret expiry metadata.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Secret policy validation and deadline selection | API / Backend | Database / Storage | Policy is Lockspire domain state; finite dates and version must round-trip with the client row. [VERIFIED: `lib/lockspire/protocol/dcr_policy.ex:87-153`; `lib/lockspire/storage/ecto/server_policy_record.ex:43-99`; `lib/lockspire/storage/ecto/client_record.ex:84-99,380-394`] |
| Initial secret authentication | API / Backend | — | Token endpoint auth owns method/material validation and protocol error mapping. [VERIFIED: `lib/lockspire/protocol/client_auth.ex:40-52,289-340`] |
| Final issuance authority | API / Backend | Database / Storage | Guarded issuance locks/reloads the client and later grant/token rows, then makes the final decision and writes atomically. [VERIFIED: `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:228-339`] |
| Operator secret rotation and audit | API / Backend | Database / Storage | Host-authorized Admin flow delegates to ClientLifecycle and the repository's locked replacement callback inside shared transaction authority. [VERIFIED: `lib/lockspire/admin/clients.ex:157-197`; `lib/lockspire/client_lifecycle.ex:52-72,99-109`; `lib/lockspire/storage/ecto/repository/client_store.ex:169-202`] |
| Registration and management wire metadata | API / Backend | — | RegistrationJSON is the shared serializer for success, read and update payloads. [VERIFIED: `lib/lockspire/web/registration_json.ex:8-28,41-66`] |

## Standard Stack

### Core

| Library / runtime | Version | Purpose | Why Standard |
|-------------------|---------|---------|--------------|
| Elixir / OTP | Elixir 1.18.4 / OTP 27.3.4.15 in the supplied validation environment | Domain policy, authentication, transaction orchestration | Repository declares Elixir `~> 1.18`; supplied asdf environment resolves the concrete versions. [VERIFIED: `mix.exs:10-16`; environment probe 2026-10-20] |
| Ecto SQL / PostgreSQL | Ecto SQL 3.13.5; PostgreSQL 14+ | Locked client replacement and atomic audit/storage | Project stack pins Ecto SQL 3.13.5 and PostgreSQL 14+; no schema change is selected for this phase. [VERIFIED: `AGENTS.md:17-24`; `lib/lockspire/storage/ecto/repository/client_store.ex:169-202`] |
| ExUnit | Bundled with Elixir | Focused unit, storage and protocol tests | Existing test modules use `ExUnit.Case`; integration tests use `Lockspire.TokenExchangeCase`. [VERIFIED: `test/lockspire/protocol/client_auth_test.exs:1-2`; `test/lockspire/storage/client_lifetime_client_wait_test.exs:1-16`] |

### Supporting

No new library is needed. Reuse `Lockspire.Storage.ClientLifetime` for adapter declaration/state validation, `ClientAuthentication.VerifiedIdentity` for current credential identity, `TransactionStore` for rollback semantics, and `ClientLifetimeRaceHelpers` for independent PostgreSQL sessions and observable blockers. [VERIFIED: `lib/lockspire/storage/client_lifetime.ex:1-89`; `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex:9-56`; `lib/lockspire/storage/ecto/repository/transaction_store.ex:4-23`; `test/support/client_lifetime_race_helpers.ex:9-107`]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing single-row serialized operator replacement | CAS versioning or a stale-command conflict response | A CAS/API contract would alter locked operator behavior; context explicitly selects last-committed-winner serialization. [VERIFIED: `.planning/phases/164-client-secret-expiry-atomic-rotation/164-CONTEXT.md` — D-12] |
| Explicit deadline persisted on the client row | Recompute expiry during reads/authentication from current server policy | Recomputing would retroactively change already-issued credentials when policy changes; context locks issuance-time snapshots. [VERIFIED: `.planning/phases/164-client-secret-expiry-atomic-rotation/164-CONTEXT.md` — D-01] |

## Project Constraints (from AGENTS.md)

- Preserve Lockspire as an embedded companion library with a narrow host seam; host ownership includes accounts, login UX, branding and product policy. [VERIFIED: `AGENTS.md:7-19`]
- Keep protocol, storage, generators, Plug/Phoenix integration and LiveView/admin boundaries separate. [VERIFIED: `AGENTS.md:15-19`]
- Preserve existing security defaults, including hashed client secrets, single-use short-lived authorization codes and strong credential redaction. [VERIFIED: `AGENTS.md:31-40`]
- Do not introduce a new runtime dependency or widen into unrelated auth capabilities. [VERIFIED: `AGENTS.md:15-19,31-40`; Phase 164 CONTEXT D-14, D-18]
- If admin copy changes, read PRODUCT personas/vocabulary; use the UI-facing wording and update retired wording and its contract test. [VERIFIED: `AGENTS.md:42-48`; `PRODUCT.md:24-90`; `test/lockspire/web/live/admin/vocabulary_contract_test.exs`]

## Architecture Patterns

### Credential issuance and strict eligibility

**What:** Keep method/material authentication separate from application eligibility. Add secret eligibility alongside the existing app eligibility API, with malformed authoritative state mapped to a server/configuration error and expired credentials mapped through the existing endpoint-specific `invalid_client` handling. Use strict `<` against a whole-second UTC deadline; do not apply JWT assertion skew to the secret's deadline. [VERIFIED: `lib/lockspire/domain/client.ex:159-202`; `lib/lockspire/protocol/client_auth.ex:40-52,208-268,289-340`]

**Where:** Apply the same domain predicate to Basic, post and client-secret JWT after material/claim checks, and apply it again inside guarded issuance after locks. Leave `private_key_jwt`, TLS-auth and `none` methods outside this gate. [VERIFIED: `lib/lockspire/protocol/client_auth.ex:11-21,289-340`; `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex:58-82`]

**Final guard:** `validate_current_client/3` already validates the explicit lifetime state and matches the current locked client against a `VerifiedIdentity`; code redemption then acquires the grant row, and its decision callback calls the injected clock only after those waits. Extend this exact boundary with secret eligibility so a preverified request cannot use stale authority after a secret expires or rotates. Search every token-producing finalizer (code, refresh, poll/device/CIBA, and RFC 8693 requester) and gate only the authenticated requester; do not gate subject/actor token validity or queued CIBA push on issuer-secret expiry. [VERIFIED: `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:228-339,465-517`; `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex:113-211`; CONTEXT D-06–D-09]

### Operator rotation transaction

**What:** Keep the outer shared transaction/audit wrapper and repository's current-row `FOR UPDATE` callback. Move policy lookup/deadline calculation and final rotation/audit timestamps after row lock acquisition. Merge only secret lifecycle fields into the current row so concurrent operator commands serialize and the final committed row wins. V0 promotion uses `Client.credential_lifetime_changes/3` semantics: clear all legacy deadlines, set only the new secret deadline, and set v1; v1 retains unrelated authoritative deadlines. [VERIFIED: `lib/lockspire/client_lifecycle.ex:52-72,99-109`; `lib/lockspire/storage/ecto/repository/client_store.ex:169-202`; `lib/lockspire/domain/client.ex:204-240`]

**Plaintext boundary:** The admin function currently returns secret plaintext only after lifecycle returns success; preserve that boundary so write or audit rollback cannot yield a successful secret handoff. Do not add overlap or old-secret proof. [VERIFIED: `lib/lockspire/admin/clients.ex:167-192`; CONTEXT D-10, D-12]

### Adapter compatibility

Extend the existing `ClientStore.rotate_client_secret` callback and conformance fixture with an explicit replacement deadline and fresh decision time, or a narrow typed replacement input. Keep adapter declaration and shared `transaction_authority` validation in `ClientLifetime.adapt/2`; do not add capability probing inside token internals. Verify that the custom adapter round-trips deadline/version and rolls back secret hash, encrypted verifier, version, deadline, audit together. [VERIFIED: `lib/lockspire/storage/client_store.ex:10-45`; `lib/lockspire/storage/client_lifetime.ex:20-57`; `test/lockspire/storage/client_lifetime_conformance_test.exs:13-31`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Current credential authority | A second custom auth fingerprint or snapshot comparison | `ClientAuthentication.verified_identity/1` and `verified_identity_matches?/2` at the locked boundary | Existing identity fingerprints bind method and secret/verifier configuration. [VERIFIED: `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex:36-56,58-82`] |
| Transaction/audit rollback | Manual compensating writes after a partial replacement | `ClientLifecycle.transact_with_audit/2`, repository `TransactionStore.transact/2`, and explicit rollback | The repository wrapper turns error tuples into actual repo rollback. [VERIFIED: `lib/lockspire/client_lifecycle.ex:99-109`; `lib/lockspire/storage/ecto/repository/transaction_store.ex:4-23`] |
| PostgreSQL race proof | Sleeps, shared sandbox sessions, or a global waiter count | Independent sandbox sessions, backend PIDs, `pg_blocking_pids`, and barrier clocks | Existing helper proves the expected session is blocking before advancing the injected decision time. [VERIFIED: `test/support/client_lifetime_race_helpers.ex:9-107`] |
| JWT assertion replay | Re-recording or rechecking JTI during the final token transaction | Existing `ClientSecretJwt.verify/3` replay write before issuance, once per assertion | Context requires final guard to revalidate credential identity/eligibility but not the consumed JTI; RFC 7523 describes JTI replay as a separate assertion control. [VERIFIED: `lib/lockspire/protocol/client_auth/client_secret_jwt.ex:19-33,163-182`]; [CITED: https://www.rfc-editor.org/rfc/rfc7523.html](https://www.rfc-editor.org/rfc/rfc7523.html) |

## Common Pitfalls

1. **Treating zero as “expires now.”** Current `ClientMetadata.client_secret_expires_at/3` adds a `0` fallback to `now`, while contract says nil/zero mean unlimited. Return nil for both values. [VERIFIED: `lib/lockspire/client_metadata.ex:283-291`; CONTEXT D-01]
2. **Applying DCR policy based on confidentiality alone.** DCR defaults belong to self-registration provenance, and direct/operator registrations retain their existing policy boundary. Dormant secret material for non-secret methods does not imply secret authentication. [VERIFIED: `lib/lockspire/client_metadata.ex:83-106`; `lib/lockspire/clients.ex:145-170`; CONTEXT D-03, D-09, D-13]
3. **Exposing stale v0 dates as enforced expiry.** Wire serialization must use validated effective lifetime state: legacy-v0 reports 0, and non-secret auth methods omit the field. Do not copy the raw stored timestamp. [VERIFIED: `lib/lockspire/web/registration_json.ex:41-66`; `lib/lockspire/storage/client_lifetime.ex:59-89`; CONTEXT D-04, D-11]
4. **Checking expiry only at endpoint authentication.** A valid secret may expire or rotate while the request waits for client/grant/token locks. Re-check current identity and secret eligibility with fresh time after the last blocking lock; keep all writes and audit under the same rollback authority. [VERIFIED: `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:228-339`; `test/lockspire/storage/client_lifetime_grant_wait_test.exs:32-119`; CONTEXT D-06]
5. **Revalidating JTI at final issuance.** JTI replay is recorded before grant persistence; trying to consume it again would reject the same legitimate request. Preserve the assertion check once and recheck only current secret identity/expiry at final authority. [VERIFIED: `lib/lockspire/protocol/client_auth/client_secret_jwt.ex:19-33,163-182`; CONTEXT D-07]
6. **Sampling rotation time before row locking.** `Admin.Clients.rotate_client_secret/2` currently binds `rotated_at` before client lookup and repository locking. Derive the authoritative timestamp and deadline after the lock wait, from current row and current applicable policy. [VERIFIED: `lib/lockspire/admin/clients.ex:167-185`; `lib/lockspire/storage/ecto/repository/client_store.ex:174-190`]
7. **Dropping lifecycle fields in a custom adapter.** Missing or malformed authoritative lifetime state must be a server/configuration error; adapter conformance should fail if replacement fields or audit are outside the shared transaction. [VERIFIED: `lib/lockspire/storage/client_lifetime.ex:20-57,59-89`; CONTEXT D-14]
8. **Making secret expiry revoke extant tokens.** Secret expiry controls client authentication. Preserve issued token validity absent its own lifetime or revocation event; confidential refresh still needs a currently eligible secret. [CITED: https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1); [VERIFIED: CONTEXT D-08]

## Code Examples

The published auth-method values are `:none`, `:client_secret_basic`, `:client_secret_post`, `:client_secret_jwt`, `:private_key_jwt`, `:tls_client_auth`, and `:self_signed_tls_client_auth`. Source: [VERIFIED: `lib/lockspire/protocol/client_auth.ex:11-21`] — “`:none`, `:client_secret_basic`, `:client_secret_post`, `:client_secret_jwt`, `:private_key_jwt`, `:tls_client_auth`, `:self_signed_tls_client_auth`”. Apply the secret gate only to the three secret methods. [VERIFIED: `lib/lockspire/protocol/client_auth.ex:11-21,289-340`]

The established final-issuance pattern is a current-row check followed by a fresh time sample inside the grant callback. Add the shared secret check beside the app check and retain the same sampled instant for all guarded decisions. [VERIFIED: `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:290-323`]

```elixir
now = dependencies.now.()

with :ok <- Client.app_eligibility(current_client, now, :guarded_token_redemption),
     :ok <- secret_eligibility(current_client, now, verified_identity),
     ... do
  # Existing grant/token/audit transaction continues.
end
```

The current lifetime-version union and legacy replacement kinds are `0 | 1 | nil`, `:secret`, and `:management`. Source: [VERIFIED: `lib/lockspire/domain/client.ex:81,211-239`] — “`lifetime_version: 0 | 1 | nil`”; “`:secret | :management`”.

The existing exact app-check source line is:

> `with :ok <- Client.app_eligibility(current_client, now, :guarded_token_redemption),`

Deadline calculation should follow the already-used whole-second construction at DCR issuance, except nil/zero must resolve to nil and invalid values must return a server/configuration error instead of arithmetic fallback. [VERIFIED: `lib/lockspire/client_metadata.ex:44-47,283-297`; `lib/lockspire/protocol/dcr_policy.ex:146-153`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, on Elixir 1.18.4 / OTP 27.3.4.15 in supplied environment |
| Config file | `config/test.exs`; repo uses `Lockspire.TestRepo` and PostgreSQL sandbox |
| Quick run command | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home MIX_ENV=test mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/web/registration_json_test.exs test/lockspire/protocol/dcr_policy_test.exs` |
| Integration command | First run `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation MIX_ENV=test mix test.setup`; then run `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation MIX_ENV=test mix test --include integration test/lockspire/storage/client_lifetime_client_wait_test.exs test/lockspire/storage/client_lifetime_grant_wait_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs` |
| Full suite | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation MIX_ENV=test mix test.fast` (the project alias runs test setup and includes lockspire, mix and integration test trees) |

These commands use the supplied runtime variables: `ASDF_ELIXIR_VERSION=1.18.4-otp-27`, `ASDF_ERLANG_VERSION=27.3.4.15`, `MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home`, `HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home`. [VERIFIED: project-provided environment; `config/test.exs:1-22`; `mix.exs:10-16,90-98`]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DCR-07 | Nil/zero/positive dates, strict whole-second metadata, policy change snapshots, provenance, no-secret omission, and legacy-v0 canonical response | unit + integration | `MIX_ENV=test mix test test/lockspire/protocol/dcr_policy_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/web/registration_json_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs` | Existing files; add focused cases |
| DCR-08 | Basic, post, secret-JWT strict expiry; all non-secret auth modes unaffected; JWT timing, algorithm and one-time JTI replay remain effective; stale preverified request fails after client or grant wait with no code/token consumption | unit + integration | `MIX_ENV=test mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/storage/client_lifetime_client_wait_test.exs test/lockspire/storage/client_lifetime_grant_wait_test.exs` | Existing files; extend race coverage |
| DCR-09 | Concurrent operator rotations serialize, final winner is stored, deadline uses post-lock current policy, audit/write failure rolls all lifecycle fields back and returns no success plaintext | integration | `MIX_ENV=test mix test test/lockspire/admin/clients_test.exs test/lockspire/client_lifecycle_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs test/lockspire/storage/client_lifetime_conformance_test.exs` | Existing files; add independent-session rotation test |
| DCR-07/08/09 | Finite expiry/rotation events do not leak plaintext, hash or verifier into audit/telemetry/logs/errors | integration | `MIX_ENV=test mix test test/lockspire/protocol/dcr_telemetry_redaction_test.exs test/lockspire/redaction/redaction_test.exs` | Existing; add exercised secret rotation/auth events and assert captured events are nonempty |

### Sampling Rate

- Per implementation slice: run the quick focused unit command for touched auth, metadata or policy code.
- Per race/transaction slice: run only the corresponding PostgreSQL integration tests against independent sessions.
- Phase gate: run the project suite using the dedicated `lockspire_phase164_validation` database before phase verification.

### Wave 0 Gaps

- None for framework/config/shared fixtures. Existing ExUnit, PostgreSQL test repo, barrier-clock helper, independent sandbox-session helper, client-wait and grant-wait tests, transaction rollback tests, and adapter conformance tests already exist. Add only Phase 164 behavior cases to those fixtures. [VERIFIED: `test/support/client_lifetime_race_helpers.ex:1-107`; `test/lockspire/storage/client_lifetime_client_wait_test.exs:15-100`; `test/lockspire/storage/client_lifetime_grant_wait_test.exs:32-119`; `test/lockspire/storage/client_lifetime_conformance_test.exs:13-31`]

## Security Domain

Relevant OWASP ASVS 5.0.0 chapters for this Elixir/Phoenix protocol and storage change are Authentication, Authorization, Input validation and business logic, Cryptography, Logging and error handling, and API and web services. [CITED: https://asvs.owasp.org/](https://asvs.owasp.org/)

| ASVS area | Applies | Phase control |
|------------|---------|---------------|
| Authentication | Yes | Enforce one secret eligibility policy at initial auth and final issuance for Basic/post/secret-JWT; keep non-secret methods ungated. |
| Authorization | Yes | Validate current credential identity against current locked client state; only existing host authorization can rotate through admin. |
| Input validation and business logic | Yes | Reject malformed durations at all supported write/use boundaries; zero and nil mean unlimited, not immediate expiry. |
| Cryptography | Yes | Preserve password-hash storage and existing encrypted secret-JWT verifier; no raw secret or verifier in audit/log/telemetry. |
| Logging and error handling | Yes | Keep existing generic `invalid_client` endpoint behavior and prevent expiry detail from exposing credential state. |
| API and web services | Yes | Serialize RFC metadata as Unix seconds/zero for shared-secret clients, omit it for no-secret auth methods, and preserve endpoint-specific errors. |

## Known Threat Patterns

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Secret expires or rotates after authentication but before issuance | Elevation of privilege / replay | Recheck current locked credential identity and strict deadline after all blocking locks; roll grant/token writes back on failure. |
| Malformed policy interpreted as unlimited | Tampering | Validate in admin form, server-policy changeset, DCR policy use, and replacement path; map invalid durable state to server error. |
| Stale v0 timestamp accidentally activates expiry | Tampering / denial of service | Treat v0 as advisory and canonicalize every old deadline to nil only during explicit credential replacement. |
| Audit or telemetry contains plaintext/hash/verifier | Information disclosure | Keep secret material out of audit attributes, events and error descriptions; test with real rotation/auth events. |
| Assertion replay control conflated with secret validity | Replay | Preserve independent signature/claim/algorithm/JTI checks; do not re-consume JTI in final issuance guard. [CITED: https://www.rfc-editor.org/rfc/rfc7523.html](https://www.rfc-editor.org/rfc/rfc7523.html) |

## Standards Findings

- RFC 7591 §3.2.1 says `client_secret_expires_at` is required when `client_secret` is issued, represents UTC Unix seconds, and uses zero when the secret does not expire. This provides the wire format; Lockspire's issuance duration and eligibility policy remain local design choices. [CITED: https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1)
- RFC 7523 requires the client-authentication assertion to identify the client, target the authorization server, carry `exp`, and pass signature/MAC and JWT validity checks. The profile makes `jti` optional and permits replay prevention; Lockspire's existing required JTI/replay behavior is stricter local policy and must stay effective independently of secret expiry. [CITED: https://www.rfc-editor.org/rfc/rfc7523.html](https://www.rfc-editor.org/rfc/rfc7523.html)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Erlang | Compile and ExUnit | ✓ | Elixir 1.18.4 / OTP 27.3.4.15 | — |
| PostgreSQL server | Locking, transaction, rollback tests | ✓ | Server accepts connections on `/tmp:5432` | — |
| `lockspire_phase164_validation` database | Isolated Phase 164 integration run | ✗ | — | Create/use the dedicated validation DB through existing test setup; do not use the default shared database. |

The supplied environment probe found the PostgreSQL server available but the named fresh database not yet present. The project test config reads `LOCKSPIRE_TEST_DB_NAME`, defaulting to `lockspire_test`. [VERIFIED: `config/test.exs:1-22`; environment probe 2026-10-20]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No unresolved research assumptions. | — | — |

## Open Questions

1. **Secret policy write/use boundary list:** Phase 164 should verify every public policy path reaches validation. Current evidence shows an admin form validator and an Ecto server-policy changeset that currently validates the app lifetime only; the planner should include parity cases for secret and management duration fields. [VERIFIED: `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex:56-68`; `lib/lockspire/storage/ecto/server_policy_record.ex:54-99`]

## Sources

### Primary (HIGH confidence)

- Current repository source, cited inline with file and line numbers.
- Phase 162 contract, Phase 163 context/verification, and Phase 164 CONTEXT decisions, cited inline.
- Existing client wait, grant wait, rollback, adapter conformance and redaction tests, cited inline.

### Secondary (MEDIUM confidence)

- [RFC 7591 §3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1) — standard secret-expiry metadata semantics.
- [RFC 7523](https://www.rfc-editor.org/rfc/rfc7523.html) — independent JWT assertion and replay behavior.
- [OWASP ASVS 5.0.0](https://asvs.owasp.org/) — security verification categories relevant to auth, policy, storage, logging and API response behavior.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read project constraints and probed supplied Elixir/PostgreSQL runtime; no new package is proposed.
- Architecture: HIGH — source seams and Phase 163 contract were read directly.
- Pitfalls: HIGH — each gap is tied to current source and existing regression patterns.
- Protocol standards: MEDIUM — official RFC Editor and OWASP sources were consulted.

**Research date:** 2026-10-20  
**Valid until:** 2026-11-19 (repository architecture and RFC wire semantics are stable)
