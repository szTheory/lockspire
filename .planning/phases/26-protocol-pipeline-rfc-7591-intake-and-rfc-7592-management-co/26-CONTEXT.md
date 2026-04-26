# Phase 26: Protocol Pipeline — RFC 7591 Intake and RFC 7592 Management Core - Context

**Gathered:** 2026-04-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement all RFC 7591/7592 protocol behavior — intake validation, RAT/IAT issuance, atomic IAT redemption, hash-at-rest, and DCR-flavored audit attribution — as `Plug.Conn`-free protocol modules with telemetry redaction proven by test, ready for thin HTTP adapters in Phase 27.

After this phase: a host application calling `Lockspire.Protocol.Registration.register/1` with valid RFC 7591 metadata receives a registered `Domain.Client` (with `pkce_required: true`, salted-hashed `client_secret`, hashed `registration_access_token`) plus the plaintext credentials returned exactly once; `Lockspire.Protocol.RegistrationManagement` exposes `read/2`, `update/2`, and `delete/2` for RFC 7592 management bound to the URL `client_id` + RAT pair; `Lockspire.Protocol.InitialAccessToken.redeem/1` is atomic and collapses all rejection axes to `:invalid_token`; `Lockspire.Admin.Clients.actor_from_attrs/1` no longer silently defaults to `:operator`; and a single-sweep redaction test proves no plaintext RAT/IAT/`client_secret` ever appears in DCR/IAT telemetry.

**Explicitly out of scope this phase:**
- HTTP routes, controllers, JSON view layer, error mapping (Phase 27)
- Admin LiveView surfaces — `PoliciesLive.Dcr`, `IatLive.{Index,New}`, ClientsLive provenance/RAT-rotate (Phase 28)
- Discovery `registration_endpoint` advertisement and 404-on-disabled contract (Phase 29)
- SECURITY.md / `docs/dynamic-registration.md` authoring (Phase 29)
- End-to-end scenario test that crosses HTTP boundaries (Phase 29)
- Schema migrations, `Domain.ServerPolicy` / `Domain.Client` / `Domain.InitialAccessToken` defstructs, `Lockspire.Protocol.DcrPolicy.resolve/3`, the public `Discovery.token_endpoint_auth_methods_supported/0` accessor (Phase 25)
- `jwks_uri` outbound fetch — rejected at intake; SSRF-guarded fetch deferred (DCR-FUT-01)
- Built-in rate limiting on intake — host-side Plug seam, documented in Phase 29 (DCR-FUT-04)
- Per-IAT `policy_overrides` admin UI — column + resolver consumption ship in Phase 25; UI deferred (DCR-FUT-03)
- `client_secret` rotation on `PUT /register/:client_id` — default off, opt-in deferred (DCR-FUT-02)

Requirements covered by this phase: **DCR-02, DCR-03, DCR-04, DCR-11, DCR-22, DCR-23**.
</domain>

<decisions>
## Implementation Decisions

### Module Layout & Naming

- **D-01:** Phase 26 ships **four sibling protocol modules**, each thin and focused:
  - `Lockspire.Protocol.Registration` at `lib/lockspire/protocol/registration.ex` — RFC 7591 intake orchestrator. Public entry: `register/1`. Returns `{:ok, %Success{}} | {:error, %Error{}}` substructs mirroring the `pushed_authorization_request.ex` shape.
  - `Lockspire.Protocol.RegistrationManagement` at `lib/lockspire/protocol/registration_management.ex` — RFC 7592 management. Public entries: `read/2`, `update/2`, `delete/2`, each accepting the URL `client_id` and the RAT-bearing client.
  - `Lockspire.Protocol.InitialAccessToken` at `lib/lockspire/protocol/initial_access_token.ex` — IAT lifecycle. Public entry: `redeem/1`. **Distinct namespace from `Lockspire.Domain.InitialAccessToken`** (the defstruct from Phase 25).
  - `Lockspire.Protocol.RegistrationAccessToken` at `lib/lockspire/protocol/registration_access_token.ex` — RAT generate/hash/verify/rotate primitives.
- **D-02:** Validator logic for RFC 7591 metadata lives **inside `Registration` as private functions**, not a separate `Lockspire.Protocol.RegistrationIntakeValidator` module. Mirrors the `validate_request/2` shape inside `pushed_authorization_request.ex:66`. The same private validator pipeline is called from `RegistrationManagement.update/2` (DCR-14 full-replace semantics) — extract to a shared private helper module only if a third caller emerges.
- **D-03:** Each protocol module is `Plug.Conn`-free (no `import Plug.Conn`, no conn parameters). Inputs are plain maps / Elixir terms; outputs are `{:ok, %Success{}}` / `{:error, %Error{}}` tuples or domain structs. The Phase 27 HTTP adapter is responsible for conn marshalling, JSON encoding, and HTTP status mapping.

### Hash-at-Rest Primitive Reconciliation

- **D-04:** **`client_secret` for self-registered clients uses `Lockspire.Security.Policy.hash_client_secret/1`** (salted SHA-256, `"sha256:salt:hash"` format at `lib/lockspire/security/policy.ex:91-96`). Reuses the existing `Lockspire.Clients.rotate_secret_hash/0` helper at `clients.ex:52-56` — parity with operator-created clients via `Admin.Clients.rotate_client_secret/2`. Verification on subsequent client authentication uses `Security.Policy.verify_client_secret/2` (already in place).
- **D-05:** **IAT token hash uses `Lockspire.Security.Policy.hash_token/1`** (plain SHA-256 lowercase hex at `lib/lockspire/security/policy.ex:84-89`), per Phase 25 D-14. Required because `lockspire_initial_access_tokens.token_hash` carries `unique_index([:token_hash])` (Phase 25 D-03) — a salted hash would force re-hashing-with-stored-salt for every lookup, scanning all rows.
- **D-06:** **RAT (`registration_access_token`) hash uses `hash_token/1`** (same primitive as IAT). Same rationale as D-05: `lockspire_clients.registration_access_token_hash` is looked up by RAT plaintext during RFC 7592 management calls (URL `client_id` + RAT-bearing client must match in a single query — Phase 27 SC 3); deterministic hash is required.
- **D-07:** Two primitives, two purposes — locked. Any future migration toward a single hash primitive is a separate decision that requires re-hashing existing operator `client_secret_hash` rows (out of scope for v1.5).

### Atomic IAT Redemption

- **D-08:** `Lockspire.Protocol.InitialAccessToken.redeem/1` accepts a **plaintext IAT string** (caller does not hash). Function hashes via `Security.Policy.hash_token/1` internally, then delegates to a new repository function `Lockspire.Storage.Ecto.Repository.redeem_initial_access_token/1`.
- **D-09:** Repository implementation uses **`Repository.transact/1` + `Ecto.Query.lock("FOR UPDATE")`** plus freshness checks — the canonical pattern at `lib/lockspire/storage/ecto/repository.ex:534-555` (`mark_authorization_code_redeemed/2`). No `Ecto.Multi` (the redemption is a single read+update with no other writes in the same transaction).
- **D-10:** Freshness checks performed inside the transaction (in the listed order — first failure short-circuits):
  1. Row exists by `token_hash` (else `:not_found`)
  2. `revoked_at IS NULL` (else `:revoked`)
  3. `expires_at > now()` (else `:expired`)
  4. `single_use = false OR used_at IS NULL` (else `:already_used`)
  Successful redemption sets `used_at = now()` in the same transaction.
- **D-11:** **Public return shape collapses all rejection axes to `{:error, :invalid_token}`** per Phase 26 SC 3. The discriminating reason (`:not_found | :expired | :revoked | :already_used`) is NEVER returned to callers — it is emitted to telemetry only, so the HTTP edge in Phase 27 cannot leak which axis failed (defense against IAT-existence enumeration). On success: `{:ok, %Lockspire.Domain.InitialAccessToken{}}` with `used_at` populated.

### Registration Pipeline (Intake & Issuance)

- **D-12:** `Registration.register/1` accepts a single map argument: `%{metadata: <inbound_rfc7591_map>, iat: <plaintext_iat | nil>, server_policy: %ServerPolicy{}, source: %{ip: ..., user_agent: ...}}`. The `:source` field is plumbed through to the audit actor (D-22). Returns `{:ok, %Success{client: %Domain.Client{}, client_secret_plaintext: bin, registration_access_token_plaintext: bin}}` or `{:error, %Error{code: :invalid_client_metadata | :invalid_token | ..., field: atom() | nil, reason: atom() | nil, allowed: list() | nil}}`.
- **D-13:** Registration pipeline order:
  1. **IAT redemption** (if `iat` non-nil) via `Lockspire.Protocol.InitialAccessToken.redeem/1` → produces `iat_record` with `policy_overrides`.
  2. **DcrPolicy resolution** via `Lockspire.Protocol.DcrPolicy.resolve(server_policy, iat_record && iat_record.policy_overrides, metadata)` (Phase 25 module). Returns `%Resolved{}` or `{:error, :invalid_client_metadata, %{field, reason, allowed}}`.
  3. **Slice-specific intake validation** (D-14) — the Phase 26-owned validator, applied AFTER policy resolution narrows the field set.
  4. **Credential generation** — `client_id`, `client_secret` plaintext, `registration_access_token` plaintext (D-16).
  5. **Persistence** in a single `Repository.transact/1` — insert `Domain.Client` row with hashed credentials + provenance fields + IAT FK.
  6. **Audit + telemetry emission** (D-22, D-25) outside the transaction (post-commit).
- **D-14:** Intake validator (private functions inside `Registration`) enforces, per DCR-02 verbatim:
  - **`jwks_uri` rejection** — any inbound `jwks_uri` returns `{:error, %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice}}` with the message "not supported in this slice" (matches DCR-02 wording).
  - **`jwks` ⊕ `jwks_uri` mutual exclusion** — both present returns `{:error, %Error{code: :invalid_client_metadata, field: :jwks, reason: :mutually_exclusive_with_jwks_uri}}`. (Practically gated behind D-14a since `jwks_uri` is rejected first; kept explicit for spec compliance.)
  - **RFC 7591 §2 `grant_types` / `response_types` coherence** — implemented as a small lookup table covering the operator-supported pairings (`authorization_code` ↔ `code`, `refresh_token` requires `authorization_code`). Mismatches return `{:error, %Error{code: :invalid_client_metadata, field: :grant_types | :response_types, reason: :incoherent_pair}}`.
  - **`redirect_uris`** routed through `Lockspire.Clients.validate_redirect_uris/1` at `lib/lockspire/clients.ex:32` — exact-match parity with operator-created clients. No new redirect validator.
- **D-15:** **PKCE floor (DCR-03)** — the validator refuses any inbound metadata that would produce a `Domain.Client` with `pkce_required: false`. Public clients (`token_endpoint_auth_method = "none"`) are accepted only when PKCE is also enforced; the resulting row is constructed with `pkce_required: true` regardless of the inbound `pkce_required` value. The inbound metadata may not set `pkce_required: false` — explicit `pkce_required: false` returns `{:error, %Error{code: :invalid_client_metadata, field: :pkce_required, reason: :pkce_floor_required_for_dcr}}`. PKCE-disabling registrations are not silently coerced; they are rejected with a clear reason.

### Credential Generation

- **D-16:** Credential generation lives in `Lockspire.Protocol.RegistrationAccessToken` for the RAT and in `Registration` (private helper) for the `client_secret`. Both use `:crypto.strong_rand_bytes/1` followed by `Base.url_encode64/2` with `padding: false`. Lengths: `client_secret` is 32 bytes pre-encode (≈43 chars post-encode); `registration_access_token` is 32 bytes pre-encode (matches operator-token entropy floor in `lib/lockspire/security/policy.ex`). `client_id` is generated via the existing `Lockspire.Clients.generate_client_id/0` helper — no new ID minting primitive.
- **D-17:** **The plaintext `client_secret` and plaintext `registration_access_token` are returned to the caller exactly once** as fields on the `Success` substruct. They are NEVER persisted in plaintext. The `Domain.Client` row stores only `client_secret_hash` (salted) and `registration_access_token_hash` (unsalted). The `Success` substruct itself is short-lived; downstream callers (Phase 27 controllers) read the plaintext fields once for the JSON response and then drop the struct.
- **D-18:** `client_secret_expires_at` is computed at issuance from `Resolved.dcr_default_client_secret_lifetime_seconds`. `client_id_issued_at` is set to `DateTime.utc_now/0` at insert time. Both are persisted; the Phase 27 view layer reads them off the persisted `Domain.Client` row, NOT off the `Success` struct.

### RFC 7592 Management Core

- **D-19:** `RegistrationManagement.read/2`, `update/2`, `delete/2` each accept `(client_id_from_url, %Domain.Client{})` where the `Domain.Client` is the row matched by `Repository.get_client_by_registration_access_token_hash/1` (a new repo function — looks up by `registration_access_token_hash = hash_token(plaintext_rat)`). The `client_id_from_url` and `client.client_id` are compared inside the function — mismatches return `{:error, :invalid_token}` (NOT a separate "wrong client" error) to prevent enumeration.
- **D-20:** `update/2` is **full-replace via the same private validator pipeline as `register/1`** (D-13 steps 2–4, skipping IAT redemption). On success: rotates `registration_access_token` (generates new plaintext via `RegistrationAccessToken.generate/0`, persists new hash, returns new plaintext exactly once on the response struct). The prior RAT hash is overwritten in the same transaction — invalidation is implicit, not via a deny-list.
- **D-21:** `delete/2` calls `Lockspire.Admin.Clients.disable_client_with_audit/4` with `disabled_by: "dcr_self_delete"` and `actor: %{type: :self_registered_client, id: client.client_id}`. Returns `:ok` on success. The client row is soft-disabled (Phase 25 already established `disabled_at` semantics); the `client_id` cannot be reused — enforced by the existing unique constraint on `lockspire_clients.client_id`.

### DCR Audit Actor Shape (DCR-22)

- **D-22:** **`Lockspire.Admin.Clients.actor_from_attrs/1` is tightened in place** at `lib/lockspire/admin/clients.ex:397-419`. The three silent `:operator` fallback branches (lines 407, 414, 419) are changed: when no actor type can be derived from `attrs`, the function **raises `ArgumentError`** with a message naming the missing field. Existing operator paths must explicitly set `attrs[:actor][:type]` — those callers are audited and updated as part of this phase. NOT a separate `actor_from_dcr_attrs/1` function (Pitfall 10 in `.planning/research/PITFALLS.md:247` explicitly recommends "tighten in place").
- **D-23:** **Actor-type assignment for DCR codepaths:**
  - `Registration.register/1` constructs `attrs[:actor] = %{type: :dcr, id: <iat_id_or_"anonymous">, display: <source.ip>}`. The `id` is the redeemed IAT's `id` when present, the literal string `"anonymous"` when registration is `:open` mode.
  - `RegistrationManagement.{read,update,delete}/2` constructs `attrs[:actor] = %{type: :self_registered_client, id: client.client_id}`.
  - These are the only two new actor types added in v1.5. The existing `:operator | :system | :host_app` set continues unchanged.
- **D-24:** **Regression test (DCR-22 failing condition)** lives at `test/lockspire/protocol/dcr_audit_attribution_test.exs`. The test exercises every DCR write path (intake success, intake failure, RFC 7592 read/update/delete, RAT rotation, IAT redemption-failure paths) and asserts via direct `Repository.list_audit_events/1` queries that NO row matches `action LIKE 'dcr_%' AND actor_type = 'operator'`. Audit-row assertion is deterministic; telemetry assertion would be flaky in CI.

### Telemetry Event Shape & Redaction (DCR-23)

- **D-25:** Telemetry emits via the existing `Lockspire.Observability.emit/3` at `lib/lockspire/observability.ex:15-29` — NOT raw `:telemetry.execute/3`. Reuses the project-wide audit-mirror behavior (every `emit` produces both `[:lockspire, :audit, event]` and `[:lockspire, event]` paths) and the `Lockspire.Redaction.for_telemetry/1` sieve at `lib/lockspire/redaction.ex:8-53` (already drops `:client_secret`, `:token`, `:token_hash`, `:authorization`).
- **D-26:** **Event names are atom singletons in the `:dcr_*` and `:iat_*` family**, satisfying the `[:lockspire, :dcr, ...]` / `[:lockspire, :iat, ...]` namespace requirement of SC 5 via the established 2-segment `Observability.emit/3` shape. Event-name namespace inferred from atom prefix. **NO extension of `Observability.emit/3` to multi-segment paths** — this preserves project-wide telemetry convention and avoids forking the audit-mirror code path. Concrete event names:
  - **DCR family:** `:dcr_registration_succeeded`, `:dcr_registration_rejected`, `:dcr_management_read`, `:dcr_management_updated`, `:dcr_management_deleted`, `:dcr_management_unauthorized`, `:dcr_registration_access_token_rotated`.
  - **IAT family:** `:iat_redeemed`, `:iat_redemption_failed` (the `failure_reason` measurement carries the discriminating axis from D-11).
- **D-27:** **Single-sweep redaction test** at `test/lockspire/protocol/dcr_telemetry_redaction_test.exs`. The test wires a `:telemetry` handler that captures every emitted `[:lockspire | _]` event during an exercise pass that covers `Registration.register/1` happy path, `Registration.register/1` invalid-metadata sad path, `RegistrationManagement.update/2` (with RAT rotation), `RegistrationManagement.delete/2`, and `InitialAccessToken.redeem/1` (success + every failure axis). The assertion is a single sweep: `refute Enum.any?(captured_events, fn ev -> String.contains?(inspect(ev), plaintext_secret) or String.contains?(inspect(ev), plaintext_rat) or String.contains?(inspect(ev), plaintext_iat) end)`. Survives event-name additions in future phases without losing coverage.
- **D-28:** Audit row redaction is enforced at the `Audit.Event.normalize/1` boundary — the same `Lockspire.Redaction` primitives flow through. The redaction test at D-27 reads back the `lockspire_audit_events` rows written during the sweep and applies the same `String.contains?` assertion against the persisted `payload` and `metadata` JSONB columns.

### Claude's Discretion

- File-internal layout of `registration.ex`, `registration_management.ex`, `initial_access_token.ex`, `registration_access_token.ex` (private helper organization, doctest placement, internal struct field order) follows `pushed_authorization_request.ex` ergonomics without further user sign-off.
- Test fixture additions (e.g., `test/support/fixtures/dcr_fixtures.ex` for inbound metadata maps, RAT plaintext) follow existing fixture naming.
- Exact Postgres advisory-lock behavior of `lock("FOR UPDATE")` on `lockspire_initial_access_tokens` is the database default — no custom lock mode.
- Whether `Registration.register/1` emits a single `:dcr_registration_rejected` event with a `reason` measurement vs separate event names per failure mode — single event with `reason` is the default unless test ergonomics demand otherwise.
- Exact `Error` struct field set beyond `{code, field, reason, allowed}` — additional fields may be added without further sign-off if downstream Phase 27 controllers need them.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 26 scope and requirements

- `.planning/ROADMAP.md` — Phase 26 entry (success criteria 1–5), dependency graph (Phase 26 depends on Phase 25 only)
- `.planning/REQUIREMENTS.md` — DCR-02, DCR-03, DCR-04, DCR-11, DCR-22, DCR-23 verbatim text and traceability matrix
- `.planning/PROJECT.md` — v1.5 milestone scope, Key Decisions on the DCR wedge, narrow-protocol-plus-operator-policy pattern
- `.planning/STATE.md` — accumulated v1.5 decisions (jwks_uri rejected at intake; no built-in rate limiting in v1.5; per-IAT policy_overrides admin UI deferred)

### Carry-forward from Phase 25

- `.planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/25-CONTEXT.md` — locked decisions Phase 26 depends on (D-01..D-20): hash primitives, IAT schema, provenance enum, resolver shape, discovery accessor
- `.planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/25-PATTERNS.md` — pattern map produced during Phase 25 planning

### Research corpus

- `.planning/research/SUMMARY.md` — DCR research summary
- `.planning/research/ARCHITECTURE.md` — Pattern 1 (resolver shape), §Module Layout (lines 124-129 enumerate the four-module sibling layout), §Build Order Level 2 (intake module precedence)
- `.planning/research/PITFALLS.md` — Pitfall 10 (audit-event vocabulary; "tighten `actor_from_attrs/1` in place"), Pitfall 12 (revoked vs used distinction enforced at redemption time)
- `.planning/research/STACK.md` — DCR-relevant library inventory
- `.planning/research/FEATURES.md` — partner-buildable use case shape
- **WARNING:** Research docs cite `lib/lockspire/protocol/jar_policy.ex` and a v1.4 JAR-policy migration as precedents — **neither exists**. Use `lib/lockspire/protocol/par_policy.ex` and the v1.3 PAR-policy migration as the structural precedents (per Phase 25 specifics §1).

### Source file precedents (must read before authoring)

- `lib/lockspire/protocol/pushed_authorization_request.ex` — **the** structural precedent for `registration.ex` and `registration_management.ex` (`Plug.Conn`-free orchestrator with `Success`/`Error` substructs at lines 13-39, `validate_request/2` private validator pattern at line 66, `wrap_jar_error/1` error-collapsing pattern at line 177)
- `lib/lockspire/protocol/par_policy.ex` — resolver precedent already established in Phase 25 D-16; relevant here as the source of the `{:error, :invalid_client_metadata, %{field, reason, allowed}}` shape that `DcrPolicy.resolve/3` returns and `Registration.register/1` consumes
- `lib/lockspire/clients.ex` — `validate_redirect_uris/1` at line 32 (DCR-02 redirect-URI validator), `rotate_secret_hash/0` at line 52 (`client_secret` hashing helper), `generate_client_id/0` (client_id minting)
- `lib/lockspire/admin/clients.ex` — `actor_from_attrs/1` at lines 397-419 (the function tightened by D-22), `disable_client_with_audit/4` (called from `RegistrationManagement.delete/2`), `client_audit_event/5` at lines 386-395 (audit-emission boundary)
- `lib/lockspire/admin/tokens.ex` — `actor_from_attrs/1` at line 339, `emit/4` at lines 276-292 (established hash-bound-ID emission pattern with `restore_unredacted_ids/2`)
- `lib/lockspire/security/policy.ex` — `hash_token/1` at lines 84-89 (IAT/RAT hash), `hash_client_secret/1` at lines 91-96 (`client_secret` salted hash), `verify_client_secret/2` at lines 99-114
- `lib/lockspire/storage/ecto/repository.ex` — `transact/1`, `mark_authorization_code_redeemed/2` at lines 534-555 (the canonical "find by hash + lock + check + update in same tx" pattern that `redeem_initial_access_token/1` mirrors), `revoke_lifecycle_token` at line 521, `redeem_authorization_code` at line 702
- `lib/lockspire/observability.ex` — `emit/3` at lines 15-29 (the telemetry helper Phase 26 uses; produces both `[:lockspire, :audit, event]` and `[:lockspire, event]` paths)
- `lib/lockspire/redaction.ex` — `for_telemetry/1` at lines 8-53 (drops `:client_secret`, `:token`, `:token_hash`, `:authorization` from event payloads)
- `lib/lockspire/audit/event.ex` — `normalize/1` at lines 55-77 (audit-row construction; downstream of `Admin.Clients.client_audit_event/5`)
- `lib/lockspire/storage/ecto/audit_event_record.ex` — `actor_type` field at line 16 (the column the D-24 regression test queries)

### Test precedents

- `test/lockspire/protocol/par_policy_test.exs` — protocol module test shape
- `test/lockspire/protocol/pushed_authorization_request_test.exs` — `Plug.Conn`-free protocol orchestrator test shape; closest analog for `Registration` and `RegistrationManagement` tests

### RFCs (specification authority)

- RFC 7591 (Dynamic Client Registration Protocol) — §2 (client metadata coherence), §3.2.1 (registration response shape)
- RFC 7592 (Dynamic Client Registration Management Protocol) — §2 (read), §2.1 (update full-replace), §2.2 (delete), §3 (error codes)
- RFC 6749 §5.2 — `invalid_token` error semantics (basis for D-11 collapsing)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.PushedAuthorizationRequest` — the closest existing analog for the new `Registration` module: `Plug.Conn`-free, `Success`/`Error` substructs, private validator, error-collapsing for security (`wrap_jar_error/1`).
- `Lockspire.Protocol.DcrPolicy.resolve/3` (Phase 25) — consumed by `Registration.register/1` in pipeline step 2 (D-13). Returns `%Resolved{}` or `{:error, :invalid_client_metadata, %{...}}`.
- `Lockspire.Clients.validate_redirect_uris/1` — DCR-02 redirect-URI validator. Used as-is, no fork. Exact-match parity with operator-created clients is the explicit requirement.
- `Lockspire.Clients.rotate_secret_hash/0` — `client_secret` hashing helper. Reused by `Registration.register/1` for credential generation.
- `Lockspire.Security.Policy.hash_token/1` — IAT/RAT hash primitive. Same function used in Phase 25 for IAT writes; Phase 26 uses it for IAT lookup-on-redeem and RAT generation/lookup.
- `Lockspire.Security.Policy.hash_client_secret/1` + `verify_client_secret/2` — salted-hash + verifier; mirrors operator path.
- `Lockspire.Admin.Clients.disable_client_with_audit/4` — soft-disable primitive used by `RegistrationManagement.delete/2`.
- `Lockspire.Storage.Ecto.Repository.transact/1` + `mark_authorization_code_redeemed/2` — the canonical lock-and-update transaction pattern; `redeem_initial_access_token/1` mirrors it 1:1.
- `Lockspire.Observability.emit/3` — telemetry helper; emits to both `[:lockspire, :audit, event]` and `[:lockspire, event]` paths.
- `Lockspire.Redaction.for_telemetry/1` — already-shipped redaction sieve covering `:client_secret`, `:token`, `:token_hash`, `:authorization`.
- `Lockspire.Domain.InitialAccessToken` (Phase 25) — defstruct mirroring the IAT row 1:1; consumed by `Lockspire.Protocol.InitialAccessToken.redeem/1` as the success-tuple payload.

### Established Patterns

- **`Plug.Conn`-free protocol modules** with `Success`/`Error` substructs and a single public entry function (`PushedAuthorizationRequest.push/1` is the precedent).
- **Private validator pipeline inside the orchestrator module** rather than a separate `*Validator` sibling (only justified by a third caller).
- **Find-by-hash + lock("FOR UPDATE") + freshness check + update in one transaction** for single-use lifecycle tokens (`mark_authorization_code_redeemed/2` at `repository.ex:534-555`).
- **Error-axis collapsing for security** (PAR's `wrap_jar_error/1` collapses multiple JAR-decode failures to a single `:invalid_request_object`; Phase 26's IAT redemption collapses four axes to `:invalid_token`).
- **Hash-at-rest only** for secrets/tokens; plaintext returned exactly once on the success struct, never re-readable.
- **Telemetry via `Observability.emit/3`** — automatic redaction via `Redaction.for_telemetry/1`, automatic audit mirror to `[:lockspire, :audit, event]`.
- **Audit attribution via `actor_from_attrs/1`** — DCR-22 tightens this in place rather than forking a parallel function.
- **Two-value provenance enum `:operator | :self_registered`** (Phase 25 D-09) — Phase 26 inserts produce `:self_registered` rows.

### Integration Points

- `Lockspire.Protocol.Registration` is consumed by Phase 27's `POST /register` controller. The `Success` substruct's plaintext fields (`client_secret_plaintext`, `registration_access_token_plaintext`) are the source of truth for the RFC 7591 §3.2.1 JSON response body fields the controller serializes.
- `Lockspire.Protocol.RegistrationManagement` is consumed by Phase 27's `GET/PUT/DELETE /register/:client_id` controllers. The `(client_id_from_url, %Domain.Client{})` signature lets the controller do RAT-bearer lookup in its own code, then pass both arguments to the management function.
- `Lockspire.Protocol.InitialAccessToken.redeem/1` is consumed by `Registration.register/1` (pipeline step 1). Its `{:error, :invalid_token}` return surfaces unchanged to Phase 27, where the controller maps it to HTTP 401.
- `Lockspire.Admin.Clients` is the audit-write boundary — every DCR persistence path goes through one of its functions (`create_client/1` for intake, `update_client/1` for RFC 7592 update, `disable_client_with_audit/4` for RFC 7592 delete). Tightening `actor_from_attrs/1` (D-22) catches every codepath at one chokepoint.
- The new `Repository.redeem_initial_access_token/1` and `Repository.get_client_by_registration_access_token_hash/1` repository functions are Phase 26-owned and live at `lib/lockspire/storage/ecto/repository.ex` alongside the existing single-use-token redemption helpers.
- `Lockspire.Observability` and `Lockspire.Redaction` are reused without modification — D-26 explicitly does NOT extend `emit/3` to multi-segment paths. Future phases may revisit if needed.
</code_context>

<specifics>
## Specific Ideas

1. **The success criterion's `[:lockspire, :dcr, ...]` and `[:lockspire, :iat, ...]` shape is satisfied via atom-singleton event names**, NOT multi-segment paths (D-26). Event namespace is inferred from the `:dcr_*` / `:iat_*` atom prefix. This was the one genuinely Unclear assumption from the analyzer pass; user confirmed the project-convention path. If a future phase audits this and finds it doesn't satisfy a stricter reading of "namespace," the fix is one-shot: extend `Observability.emit/3` to accept a list event name.

2. **IAT redemption's four failure axes (`:not_found | :expired | :revoked | :already_used`) collapse to `{:error, :invalid_token}` in the public return** but the discriminator is preserved in telemetry as a `failure_reason` measurement (D-11, D-26). This is the IAT-enumeration defense — operators still see the diagnostic via telemetry; attackers don't.

3. **`actor_from_attrs/1` is tightened in place by changing silent fallbacks to raise** (D-22). This is louder than a `:unknown` return + caller refusal, but it's the only way to guarantee the regression-prevention property. Existing operator callers must be audited and updated to pass explicit `actor.type`.

4. **PKCE-disabling registrations are rejected with a clear reason, not silently coerced** (D-15). DCR-03 says "the validator refuses any metadata that would lower PKCE for a DCR client" — that refusal is explicit, not a silent override.

5. **`registration_access_token` rotation on `PUT /register/:client_id` (D-20) overwrites the prior hash in the same transaction**. No deny-list. Implicit invalidation. Subsequent calls with the prior RAT find no matching `registration_access_token_hash` row and get the same `{:error, :invalid_token}` collapsed return as IAT redemption (D-19 — defense against RAT enumeration).

6. **The four-module split (`Registration` + `RegistrationManagement` + `InitialAccessToken` + `RegistrationAccessToken`) is justified by distinct actor types and distinct response shapes**, not by file size. A single `DynamicRegistration` module would mix `:dcr` and `:self_registered_client` audit actors and would carry two response substructs (intake includes `client_secret`/`RAT`; management read does not). Splitting keeps each module's public surface single-purpose.
</specifics>

<deferred>
## Deferred Ideas

- **Multi-segment telemetry paths via `Observability.emit/3` extension** — if a future audit deems atom-singleton paths insufficient for the `[:lockspire, :dcr, ...]` namespace requirement, extending `emit/3` to accept a list event name is a one-shot fix. Out of scope for Phase 26.
- **Separate `Lockspire.Protocol.RegistrationIntakeValidator` module** — only justified if a third caller emerges (today: `Registration.register/1` and `RegistrationManagement.update/2`). Out of scope until needed.
- **`actor_from_dcr_attrs/1` separate function** — rejected (D-22); tighten in place is the regression-prevention path.
- **`Ecto.Multi`-based IAT redemption** — rejected (D-09); single read+update with no other writes in the transaction makes `transact/1 + FOR UPDATE` simpler.
- **Differentiated public IAT error returns (`:expired | :revoked | :already_used`)** — rejected (D-11); collapses to `:invalid_token` for enumeration defense.
- **`client_secret` rotation on `PUT /register/:client_id`** — DCR-FUT-02; default off, opt-in via DcrPolicy in v1.6+.
- **Per-IAT `policy_overrides` admin UI** — DCR-FUT-03; column + resolver consumption ship in Phase 25, UI in v1.6+.
- **`jwks_uri` outbound fetch with SSRF protections** — DCR-FUT-01; rejected at intake in this phase.
- **Built-in rate limiting on `POST /register`** — DCR-FUT-04; host-side Plug seam documented in Phase 29.
- **Per-event explicit redaction assertions** — rejected (D-27); single-sweep `String.contains?` test survives event-name additions in future phases.

### Reviewed Todos (not folded)

None — no pending todos matched this phase scope at gather time.
</deferred>

---

*Phase: 26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co*
*Context gathered: 2026-04-26 (assumptions mode)*
