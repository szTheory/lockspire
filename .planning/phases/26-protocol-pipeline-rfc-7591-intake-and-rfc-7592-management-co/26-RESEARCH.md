# Phase 26: Protocol Pipeline — RFC 7591 Intake and RFC 7592 Management Core - Research

**Researched:** 2026-04-26
**Domain:** Elixir / Phoenix / Ecto — OAuth 2.0 Dynamic Client Registration (RFC 7591) intake + RFC 7592 management as `Plug.Conn`-free protocol modules
**Confidence:** HIGH

## Summary

Phase 26 implements the four DCR protocol modules (`Registration`, `RegistrationManagement`, `InitialAccessToken`, `RegistrationAccessToken`) and their persistence/audit/telemetry plumbing on top of the Phase 25 storage skeleton. CONTEXT.md has already locked the major design decisions (D-01..D-28); this research verifies those decisions against the actual code, identifies three concrete code-correctness issues the planner must address, and documents the standard patterns and call sites the implementer will use.

Verification status:

- All hash-at-rest, telemetry, redaction, and resolver primitives the CONTEXT.md decisions reference exist at the cited file paths and line numbers (with one off-by-one — `Clients.rotate_secret_hash/0` is at line 53, not 52).
- The `mark_authorization_code_redeemed/2` pattern at `repository.ex:534-557` is the canonical "find by hash, lock FOR UPDATE, freshness check, update in same tx" precedent. Phase 26's `redeem_initial_access_token/1` mirrors it exactly.
- Three code-correctness issues require planner attention (see "Open Questions"):
  1. **`Lockspire.Admin.Clients.disable_client_with_audit/4` is `defp` (private)** — `RegistrationManagement.delete/2` cannot call it directly. Must call the public `Admin.Clients.disable_client/2` or expose `disable_client_with_audit/4`.
  2. **`Lockspire.Clients.generate_client_id/0` is `defp` (private)** — must be promoted to public, or `RegistrationAccessToken`/`Registration` reproduce the 24-byte `"ls_" <> Base.url_encode64(...)` idiom inline.
  3. **`Repository.list_audit_events/1` does not exist.** D-24 references it for the regression test; the existing project pattern is to query `AuditEventRecord` directly via `Lockspire.TestRepo.all(from(...))` (see `test/lockspire/admin/clients_test.exs:232-240`).

**Primary recommendation:** Plan three "carve out a public helper" tasks at the start of Phase 26 (one each for the items above) before authoring the four protocol modules. Then build the protocol modules in dependency order: `RegistrationAccessToken` → `InitialAccessToken` → `Registration` → `RegistrationManagement`. Audit attribution tightening (D-22) and the telemetry redaction sweep test (D-27) come last because they exercise every other module.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DCR-02 | Intake validation rejects `jwks_uri`, `jwks ⊕ jwks_uri`, enforces RFC 7591 §2 grant/response coherence, routes redirect URIs through `Lockspire.Clients.validate_redirect_uris/1` | RFC 7591 §2.1 (grant/response coherence table, jwks vs jwks_uri mutual exclusion); CONTEXT.md D-14; `lib/lockspire/clients.ex:32` (validator already exists) |
| DCR-03 | Self-registered clients are PKCE-required by floor; intake refuses metadata that lowers PKCE; row stored with `pkce_required: true` | CONTEXT.md D-15; `Lockspire.Clients.normalize/1:108` already forces `pkce_required: true`; `lib/lockspire/clients.ex:271-281` rejects explicit `pkce_required: false` |
| DCR-04 | Successful registration issues `client_id`, fresh `client_secret`, fresh RAT; both secrets hashed at rest; plaintext returned exactly once | CONTEXT.md D-04, D-06, D-16, D-17; `Lockspire.Security.Policy.hash_client_secret/1` at `policy.ex:91-96`; `Lockspire.Security.Policy.hash_token/1` at `policy.ex:84-89`; `Lockspire.Clients.rotate_secret_hash/0` at `clients.ex:53-56` |
| DCR-11 | `Lockspire.Protocol.InitialAccessToken.redeem/1` is atomic; expired/revoked/used IATs return `{:error, :invalid_token}`; success marks IAT used in same tx | CONTEXT.md D-08, D-09, D-10, D-11; canonical pattern at `repository.ex:534-557`; `unique_index([:token_hash])` exists per Phase 25 migration |
| DCR-22 | `actor_from_attrs/1` attributes DCR codepaths as `:dcr`/`:self_registered_client`, never `:operator`; regression test fails on `:operator`-flavored DCR write | CONTEXT.md D-22, D-23, D-24; current silent fallbacks at `admin/clients.ex:407, 414, 419`; audit-row test pattern at `test/lockspire/admin/clients_test.exs:74-82, 232-240` |
| DCR-23 | RAT/IAT/`client_secret` plaintext never appear in `[:lockspire, :dcr, ...]` / `[:lockspire, :iat, ...]` event payload, audit row, or log line | CONTEXT.md D-25, D-26, D-27, D-28; `Observability.emit/3` at `observability.ex:15-29`; `Redaction.for_telemetry/1` drop list at `redaction.ex:8-53`; existing telemetry test pattern at `test/lockspire/admin/clients_test.exs:207-230` |
</phase_requirements>

<user_constraints>
## User Constraints (from CONTEXT.md)

CONTEXT.md was gathered in **assumptions mode** on 2026-04-26 with all five assumptions confirmed via "Yes, proceed". Decisions D-01..D-28 are locked and constrain this research.

### Locked Decisions (verbatim from CONTEXT.md ## Decisions)

**Module Layout & Naming**
- **D-01:** Phase 26 ships **four sibling protocol modules**, each thin and focused: `Lockspire.Protocol.Registration` at `lib/lockspire/protocol/registration.ex`; `Lockspire.Protocol.RegistrationManagement` at `lib/lockspire/protocol/registration_management.ex`; `Lockspire.Protocol.InitialAccessToken` at `lib/lockspire/protocol/initial_access_token.ex` (distinct namespace from `Lockspire.Domain.InitialAccessToken`); `Lockspire.Protocol.RegistrationAccessToken` at `lib/lockspire/protocol/registration_access_token.ex`.
- **D-02:** Validator logic for RFC 7591 metadata lives **inside `Registration` as private functions**, not a separate `Lockspire.Protocol.RegistrationIntakeValidator` module. The same private validator pipeline is called from `RegistrationManagement.update/2`. Extract to a shared private helper module only if a third caller emerges.
- **D-03:** Each protocol module is `Plug.Conn`-free (no `import Plug.Conn`, no conn parameters). Inputs are plain maps / Elixir terms; outputs are `{:ok, %Success{}}` / `{:error, %Error{}}` tuples or domain structs.

**Hash-at-Rest Primitive Reconciliation**
- **D-04:** `client_secret` for self-registered clients uses `Lockspire.Security.Policy.hash_client_secret/1` (salted SHA-256). Reuses the existing `Lockspire.Clients.rotate_secret_hash/0` helper.
- **D-05:** IAT token hash uses `Lockspire.Security.Policy.hash_token/1` (plain SHA-256 lowercase hex). Required because `lockspire_initial_access_tokens.token_hash` carries `unique_index([:token_hash])`.
- **D-06:** RAT (`registration_access_token`) hash uses `hash_token/1` (same primitive as IAT). Same rationale: deterministic hash required for hash-equality lookup at RFC 7592 management calls.
- **D-07:** Two primitives, two purposes — locked.

**Atomic IAT Redemption**
- **D-08:** `Lockspire.Protocol.InitialAccessToken.redeem/1` accepts a plaintext IAT string (caller does not hash). Function hashes via `Security.Policy.hash_token/1` internally, then delegates to a new `Repository.redeem_initial_access_token/1`.
- **D-09:** Repository implementation uses `Repository.transact/1` + `Ecto.Query.lock("FOR UPDATE")` plus freshness checks — the canonical pattern at `repository.ex:534-555` (`mark_authorization_code_redeemed/2`). No `Ecto.Multi`.
- **D-10:** Freshness checks performed inside the transaction (in order — first failure short-circuits): (1) row exists by `token_hash` else `:not_found`; (2) `revoked_at IS NULL` else `:revoked`; (3) `expires_at > now()` else `:expired`; (4) `single_use = false OR used_at IS NULL` else `:already_used`. Successful redemption sets `used_at = now()` in the same transaction.
- **D-11:** **Public return shape collapses all rejection axes to `{:error, :invalid_token}`** per Phase 26 SC 3. Discriminating reason emitted to telemetry only (defense against IAT-existence enumeration). On success: `{:ok, %Lockspire.Domain.InitialAccessToken{}}` with `used_at` populated.

**Registration Pipeline (Intake & Issuance)**
- **D-12:** `Registration.register/1` accepts a single map argument: `%{metadata: <inbound_rfc7591_map>, iat: <plaintext_iat | nil>, server_policy: %ServerPolicy{}, source: %{ip: ..., user_agent: ...}}`. Returns `{:ok, %Success{client: %Domain.Client{}, client_secret_plaintext: bin, registration_access_token_plaintext: bin}}` or `{:error, %Error{code: ..., field: atom() | nil, reason: atom() | nil, allowed: list() | nil}}`.
- **D-13:** Registration pipeline order: (1) IAT redemption if `iat` non-nil → produces `iat_record` with `policy_overrides`; (2) DcrPolicy resolution; (3) slice-specific intake validation (Phase-26-owned validator, applied AFTER policy resolution narrows the field set); (4) credential generation; (5) persistence in a single `Repository.transact/1`; (6) audit + telemetry emission outside the transaction (post-commit).
- **D-14:** Intake validator (private functions inside `Registration`) enforces, per DCR-02 verbatim: `jwks_uri` rejection (`{:error, %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice}}`); `jwks ⊕ jwks_uri` mutual exclusion; RFC 7591 §2 `grant_types` / `response_types` coherence (small lookup table); `redirect_uris` routed through `Lockspire.Clients.validate_redirect_uris/1`.
- **D-15:** PKCE floor (DCR-03) — validator refuses any inbound metadata that would produce a `Domain.Client` with `pkce_required: false`. Public clients (`token_endpoint_auth_method = "none"`) are accepted only when PKCE is also enforced; row constructed with `pkce_required: true` regardless. Explicit `pkce_required: false` returns `{:error, %Error{code: :invalid_client_metadata, field: :pkce_required, reason: :pkce_floor_required_for_dcr}}`. PKCE-disabling registrations are not silently coerced; they are rejected with a clear reason.

**Credential Generation**
- **D-16:** Credential generation lives in `Lockspire.Protocol.RegistrationAccessToken` for the RAT and in `Registration` (private helper) for the `client_secret`. Both use `:crypto.strong_rand_bytes/1` followed by `Base.url_encode64/2` with `padding: false`. Lengths: `client_secret` 32 bytes pre-encode; `registration_access_token` 32 bytes pre-encode. `client_id` is generated via the existing `Lockspire.Clients.generate_client_id/0` helper.
- **D-17:** Plaintext `client_secret` and plaintext `registration_access_token` are returned to the caller exactly once on the `Success` substruct. NEVER persisted in plaintext.
- **D-18:** `client_secret_expires_at` computed at issuance from `Resolved.dcr_default_client_secret_lifetime_seconds`. `client_id_issued_at` set to `DateTime.utc_now/0` at insert time. Both persisted on the `Domain.Client` row.

**RFC 7592 Management Core**
- **D-19:** `RegistrationManagement.read/2`, `update/2`, `delete/2` each accept `(client_id_from_url, %Domain.Client{})` where the client is the row matched by `Repository.get_client_by_registration_access_token_hash/1` (a new repo function). The `client_id_from_url` and `client.client_id` are compared inside the function — mismatches return `{:error, :invalid_token}` (not a separate "wrong client" error) to prevent enumeration.
- **D-20:** `update/2` is full-replace via the same private validator pipeline as `register/1` (D-13 steps 2–4, skipping IAT redemption). On success: rotates `registration_access_token`, persists new hash, returns new plaintext exactly once. Prior RAT hash overwritten in the same transaction — invalidation is implicit.
- **D-21:** `delete/2` calls `Lockspire.Admin.Clients.disable_client_with_audit/4` with `disabled_by: "dcr_self_delete"` and `actor: %{type: :self_registered_client, id: client.client_id}`. Returns `:ok` on success.

**DCR Audit Actor Shape (DCR-22)**
- **D-22:** `Lockspire.Admin.Clients.actor_from_attrs/1` is tightened in place at `lib/lockspire/admin/clients.ex:397-419`. Three silent `:operator` fallback branches (lines 407, 414, 419) are changed: when no actor type can be derived from `attrs`, the function **raises `ArgumentError`**. Existing operator paths must explicitly set `attrs[:actor][:type]` — those callers are audited and updated as part of this phase. NOT a separate `actor_from_dcr_attrs/1`.
- **D-23:** Actor-type assignment for DCR codepaths: `Registration.register/1` constructs `attrs[:actor] = %{type: :dcr, id: <iat_id_or_"anonymous">, display: <source.ip>}`. `RegistrationManagement.{read,update,delete}/2` constructs `attrs[:actor] = %{type: :self_registered_client, id: client.client_id}`.
- **D-24:** Regression test (DCR-22 failing condition) lives at `test/lockspire/protocol/dcr_audit_attribution_test.exs`. Asserts via direct queries that NO row matches `action LIKE 'dcr_%' AND actor_type = 'operator'`. Audit-row assertion is deterministic; telemetry assertion would be flaky in CI.

**Telemetry Event Shape & Redaction (DCR-23)**
- **D-25:** Telemetry emits via the existing `Lockspire.Observability.emit/3` at `lib/lockspire/observability.ex:15-29` — NOT raw `:telemetry.execute/3`. Reuses the project-wide audit-mirror behavior and the `Lockspire.Redaction.for_telemetry/1` sieve.
- **D-26:** Event names are atom singletons in the `:dcr_*` and `:iat_*` family. No extension of `Observability.emit/3` to multi-segment paths. Concrete event names: DCR family — `:dcr_registration_succeeded`, `:dcr_registration_rejected`, `:dcr_management_read`, `:dcr_management_updated`, `:dcr_management_deleted`, `:dcr_management_unauthorized`, `:dcr_registration_access_token_rotated`. IAT family — `:iat_redeemed`, `:iat_redemption_failed` (`failure_reason` measurement carries the discriminating axis from D-11).
- **D-27:** Single-sweep redaction test at `test/lockspire/protocol/dcr_telemetry_redaction_test.exs`. Wires a `:telemetry` handler that captures every emitted `[:lockspire | _]` event during an exercise pass covering happy + every failure path. The assertion is a single sweep: `refute Enum.any?(captured_events, fn ev -> String.contains?(inspect(ev), plaintext_secret) or String.contains?(inspect(ev), plaintext_rat) or String.contains?(inspect(ev), plaintext_iat) end)`.
- **D-28:** Audit row redaction enforced at the `Audit.Event.normalize/1` boundary — same `Lockspire.Redaction` primitives flow through. The redaction test at D-27 reads back the `lockspire_audit_events` rows written during the sweep and applies the same `String.contains?` assertion against the persisted `payload` and `metadata` JSONB columns.

### Claude's Discretion (verbatim from CONTEXT.md)

- File-internal layout of `registration.ex`, `registration_management.ex`, `initial_access_token.ex`, `registration_access_token.ex` (private helper organization, doctest placement, internal struct field order) follows `pushed_authorization_request.ex` ergonomics.
- Test fixture additions (e.g., `test/support/fixtures/dcr_fixtures.ex` for inbound metadata maps, RAT plaintext) follow existing fixture naming.
- Exact Postgres advisory-lock behavior of `lock("FOR UPDATE")` on `lockspire_initial_access_tokens` is the database default — no custom lock mode.
- Whether `Registration.register/1` emits a single `:dcr_registration_rejected` event with a `reason` measurement vs separate event names per failure mode — single event with `reason` is the default unless test ergonomics demand otherwise.
- Exact `Error` struct field set beyond `{code, field, reason, allowed}` — additional fields may be added without further sign-off if downstream Phase 27 controllers need them.

### Deferred Ideas (OUT OF SCOPE)

- Multi-segment telemetry paths via `Observability.emit/3` extension — out of scope for Phase 26.
- Separate `Lockspire.Protocol.RegistrationIntakeValidator` module — only justified if a third caller emerges.
- `actor_from_dcr_attrs/1` separate function — rejected (D-22); tighten in place.
- `Ecto.Multi`-based IAT redemption — rejected (D-09).
- Differentiated public IAT error returns (`:expired | :revoked | :already_used`) — rejected (D-11); collapses to `:invalid_token`.
- `client_secret` rotation on `PUT /register/:client_id` — DCR-FUT-02; v1.6+.
- Per-IAT `policy_overrides` admin UI — DCR-FUT-03; UI in v1.6+.
- `jwks_uri` outbound fetch with SSRF protections — DCR-FUT-01; rejected at intake in this phase.
- Built-in rate limiting on `POST /register` — DCR-FUT-04; host-side Plug seam documented in Phase 29.
- Per-event explicit redaction assertions — rejected (D-27); single-sweep `String.contains?` test.

</user_constraints>

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` does not exist in the repo (verified by `Read` returning ENOENT). No CLAUDE.md directives apply. The project follows the conventions established by `mix.exs` (Elixir ~> 1.18, ecto_sql ~> 3.13.5, telemetry ~> 1.3) and the `qa` alias (`format --check-formatted`, `compile --warnings-as-errors`, `credo --strict`, `dialyzer`).

## Architectural Responsibility Map

Phase 26 is intentionally single-tier: every capability lives in the `lib/lockspire/protocol/` and `lib/lockspire/storage/ecto/` boundaries. There is no HTTP, no LiveView, no client-side code. The "tier" axis collapses; the meaningful axis is *module ownership*.

| Capability | Primary Module | Secondary Module | Rationale |
|------------|----------------|------------------|-----------|
| RFC 7591 intake orchestration | `Lockspire.Protocol.Registration` | `Lockspire.Protocol.DcrPolicy` (resolver), `Lockspire.Clients` (redirect URI validator) | D-01, D-02; mirrors `PushedAuthorizationRequest.push/1` shape |
| RFC 7592 management | `Lockspire.Protocol.RegistrationManagement` | `Lockspire.Admin.Clients.disable_client/2` (delete path) | D-19, D-20, D-21 |
| IAT lifecycle (redeem) | `Lockspire.Protocol.InitialAccessToken` | `Lockspire.Storage.Ecto.Repository.redeem_initial_access_token/1` (NEW) | D-08, D-09, D-10, D-11 |
| RAT primitives (generate / hash / verify) | `Lockspire.Protocol.RegistrationAccessToken` | `Lockspire.Security.Policy.hash_token/1` | D-06, D-16 |
| Hash-at-rest (`client_secret`) | `Lockspire.Security.Policy.hash_client_secret/1` | `Lockspire.Clients.rotate_secret_hash/0` (already wraps) | D-04 |
| Hash-at-rest (RAT, IAT) | `Lockspire.Security.Policy.hash_token/1` | — | D-05, D-06 |
| DcrPolicy resolution | `Lockspire.Protocol.DcrPolicy.resolve/3` (Phase 25) | — | already shipped |
| Audit attribution | `Lockspire.Admin.Clients.actor_from_attrs/1` | `Lockspire.Audit.Event.normalize/1` | D-22, D-23, D-28 |
| Telemetry emission | `Lockspire.Observability.emit/3` | `Lockspire.Redaction.for_telemetry/1` | D-25, D-26 |
| Persistence (transactional) | `Lockspire.Storage.Ecto.Repository.transact/1` | `Repository.transact_with_audit/2` | D-09, D-13 step 5 |
| Self-registered client lookup by RAT | `Lockspire.Storage.Ecto.Repository.get_client_by_registration_access_token_hash/1` (NEW) | — | D-19 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.18+ (1.19.5 in tooling) | Language | `mix.exs:9` declares `elixir: "~> 1.18"` [VERIFIED: `mix.exs`] |
| Erlang/OTP | 28 | Runtime | Verified via `elixir -v` [VERIFIED: shell output] |
| ecto_sql | ~> 3.13.5 | Postgres + transaction + `lock("FOR UPDATE")` | `mix.exs:39` [VERIFIED] |
| postgrex | >= 0.0.0 | PG driver | `mix.exs:40` [VERIFIED] |
| telemetry | ~> 1.3 | Event emission | `mix.exs:45` [VERIFIED]; used by `Lockspire.Observability.emit/3` |
| jason | ~> 1.4 | JSON | `mix.exs:43` [VERIFIED]; relevant for `metadata` JSONB and Phase 27 |
| plug_crypto | (transitive via phoenix) | `Plug.Crypto.secure_compare/2` | Used by `Security.Policy.verify_client_secret/2` [VERIFIED: `policy.ex:124`] |

### Supporting (project-internal modules)
| Module | Purpose | When to Use |
|--------|---------|-------------|
| `Lockspire.Security.Policy` | Hash primitives (`hash_token/1`, `hash_client_secret/1`, `verify_client_secret/2`) | Every credential generation and verification path |
| `Lockspire.Clients` | `validate_redirect_uris/1`, `rotate_secret_hash/0`, **private** `generate_client_id/0` | Intake validator (redirect URIs); credential gen |
| `Lockspire.Admin.Clients` | `actor_from_attrs/1` (tightened by D-22), `disable_client/2`, `client_audit_event/5` | Audit-emission boundary; delete path |
| `Lockspire.Protocol.DcrPolicy` | `resolve/3` intersection-only resolver | Pipeline step 2 (D-13) |
| `Lockspire.Storage.Ecto.Repository` | `transact/1`, `transact_with_audit/2`, `mark_authorization_code_redeemed/2` (precedent), `register_client/1`, `update_client/2` | Persistence + audit-event linking |
| `Lockspire.Observability` | `emit/3` two-segment telemetry helper | All Phase 26 telemetry |
| `Lockspire.Redaction` | `for_telemetry/1`, `for_audit/1` sieves | Drops `:client_secret`, `:token`, `:token_hash`, `:authorization` from event payloads |
| `Lockspire.Audit.Event` | `normalize/1` audit-row construction | Enforces field-required and applies `Redaction.for_audit/1` to metadata |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Repo.transact/1 + lock("FOR UPDATE")` | `Ecto.Multi` | Locked-out by D-09. Multi adds composition overhead; the IAT redemption is a single read+update with no other writes in the transaction, so the simpler pattern wins and matches the existing `mark_authorization_code_redeemed/2` precedent. |
| `Repo.transact/1 + lock("FOR UPDATE")` | `UPDATE ... WHERE used_at IS NULL RETURNING *` (compare-and-swap) | Equally atomic, Postgres-only. The project consistently uses `lock("FOR UPDATE")` for single-use lifecycle tokens (`mark_authorization_code_redeemed/2`, `consume_pushed_authorization_request_record`, `revoke_lifecycle_token`); deviating here would fragment the pattern. |
| `actor_from_attrs/1` raise on missing type | Return `{:error, :unknown_actor}` and force callers to handle | Locked-out by D-22. Raise is louder, but it's the only way to guarantee that no DCR codepath can silently emit `:operator`; a return-tuple still requires every caller's discipline, which is what got us into this situation. |
| Atom-singleton `:dcr_registration_succeeded` | List `[:dcr, :registration_succeeded]` | Locked-out by D-26. Switching `Observability.emit/3` to accept a list would fork the audit-mirror code path and ripple through every existing caller. Atom prefix carries the namespace. |

**Installation:** No new deps. All needed primitives exist.

**Version verification:**
```bash
mix deps | grep -E "ecto_sql|telemetry|postgrex|jason"
```
Verified at `mix.exs:37-50` against the in-repo lock — no new dependencies required for Phase 26.

## Architecture Patterns

### System Architecture Diagram

```
                            ┌──────────────────────────────────────┐
                            │ Phase 27 HTTP layer (out of scope)   │
                            │ POST /register, GET/PUT/DELETE       │
                            │ /register/:client_id                 │
                            └───────────────┬──────────────────────┘
                                            │ inbound: %{metadata, iat,
                                            │ server_policy, source}
                                            │ outbound: {:ok, %Success{}} | {:error, %Error{}}
                                            ▼
                       ┌────────────────────────────────────────────┐
                       │ Lockspire.Protocol.Registration.register/1 │
                       │ (Phase 26 — orchestrator, Plug.Conn-free)  │
                       └────────────────────────────────────────────┘
                                            │
                  ┌─────────────────────────┼───────────────────────────┐
                  │                         │                           │
                  ▼                         ▼                           ▼
   ┌──────────────────────────┐  ┌──────────────────────┐  ┌──────────────────────────┐
   │ InitialAccessToken.       │  │ DcrPolicy.resolve/3  │  │ Private intake validator │
   │ redeem/1 (Phase 26)       │  │ (Phase 25)           │  │ (Phase 26 — D-14, D-15)  │
   │  ↓                        │  │ intersection-only    │  │  - jwks_uri reject       │
   │ Repository.redeem_iat/1   │  │  ServerPolicy ∩      │  │  - jwks ⊕ jwks_uri       │
   │  ↓                        │  │  IAT overrides ∩     │  │  - grant/response        │
   │ transact + FOR UPDATE     │  │  inbound metadata    │  │    coherence (RFC 7591)  │
   │  ↓                        │  └──────────────────────┘  │  - redirect_uris via     │
   │ {:ok, %IAT{used_at:...}}  │                            │    Clients.validate_*    │
   │ | {:error, :invalid_token}│                            │  - PKCE floor            │
   └──────────────────────────┘                            └──────────────────────────┘
                                            │
                                            ▼
                  ┌─────────────────────────────────────────────────────┐
                  │ Credential generation (D-16):                       │
                  │  - client_id     ← Clients.generate_client_id/0     │
                  │  - client_secret ← Clients.rotate_secret_hash/0     │
                  │  - RAT           ← RegistrationAccessToken.generate │
                  └─────────────────────────────────────────────────────┘
                                            │
                                            ▼
                  ┌─────────────────────────────────────────────────────┐
                  │ Repository.transact/1: persist %Domain.Client{}     │
                  │  - client_secret_hash (salted)                      │
                  │  - registration_access_token_hash (unsalted)        │
                  │  - provenance: :self_registered                     │
                  │  - initial_access_token_id                          │
                  │  - client_id_issued_at, client_secret_expires_at    │
                  └─────────────────────────────────────────────────────┘
                                            │
                                            ▼
                  ┌─────────────────────────────────────────────────────┐
                  │ Post-commit (D-13 step 6):                          │
                  │  - Observability.emit(:dcr_registration_succeeded,  │
                  │       measurements, redacted_metadata)              │
                  │  - actor: {type: :dcr, id: iat_id_or_"anonymous"}   │
                  └─────────────────────────────────────────────────────┘

                  ┌─────────────────────────────────────────────────────┐
                  │ RegistrationManagement.read/2, update/2, delete/2   │
                  │ (Phase 26 — RFC 7592)                               │
                  │  arg: (client_id_from_url, %Domain.Client{})        │
                  │  - read:   no DB write, emits :dcr_management_read  │
                  │  - update: same private validator → rotate RAT      │
                  │  - delete: Admin.Clients.disable_client_with_audit  │
                  │           (actor: :self_registered_client)          │
                  └─────────────────────────────────────────────────────┘
```

### Recommended File Layout (deltas only — Phase 26 owned)
```
lib/lockspire/protocol/
├── registration.ex                        # NEW — D-01
├── registration_management.ex             # NEW — D-01
├── initial_access_token.ex                # NEW — D-01 (distinct from Domain.InitialAccessToken)
└── registration_access_token.ex           # NEW — D-01

lib/lockspire/storage/ecto/repository.ex   # EXTEND — add redeem_initial_access_token/1,
                                            #          get_client_by_registration_access_token_hash/1
lib/lockspire/admin/clients.ex             # EDIT — D-22: tighten actor_from_attrs/1
                                            #        + audit and update existing :operator callers
lib/lockspire/clients.ex                   # MAYBE EDIT — see Open Question 2 (generate_client_id/0
                                            #             is private; needs promotion or duplication)

test/support/fixtures/
└── dcr_fixtures.ex                        # NEW — inbound RFC 7591 metadata fixtures + RAT plaintext

test/lockspire/protocol/
├── registration_test.exs                  # NEW — happy path + D-14/D-15 sad paths
├── registration_management_test.exs       # NEW — read/update/delete + RAT rotation invalidation
├── initial_access_token_test.exs          # NEW — D-10 freshness ladder + collapse to :invalid_token
├── registration_access_token_test.exs     # NEW — generate/hash/verify primitives
├── dcr_audit_attribution_test.exs         # NEW — D-24 regression test
└── dcr_telemetry_redaction_test.exs       # NEW — D-27 single-sweep redaction test
```

### Pattern 1: `Plug.Conn`-free protocol orchestrator
**What:** A protocol module exposes a single public entry function (`push/1`, `register/1`, etc.) that takes plain Elixir terms and returns `{:ok, %Success{}}` / `{:error, %Error{}}`. The module owns its `Success` and `Error` substructs.

**When to use:** Every Phase 26 protocol module. Locked by D-03.

**Example (verbatim precedent at `lib/lockspire/protocol/pushed_authorization_request.ex:13-39, 43-64`):**
```elixir
defmodule Lockspire.Protocol.Registration do
  defmodule Success do
    @type t :: %__MODULE__{
            client: Lockspire.Domain.Client.t(),
            client_secret_plaintext: String.t() | nil,
            registration_access_token_plaintext: String.t()
          }
    defstruct [:client, :client_secret_plaintext, :registration_access_token_plaintext]
  end

  defmodule Error do
    @type t :: %__MODULE__{
            code: atom(),
            field: atom() | nil,
            reason: atom() | nil,
            allowed: list() | nil
          }
    defstruct [:code, :field, :reason, :allowed]
  end

  @type result :: {:ok, Success.t()} | {:error, Error.t()}

  @spec register(map()) :: result()
  def register(request) when is_map(request) do
    with {:ok, iat_record} <- maybe_redeem_iat(request),
         {:ok, %Resolved{} = resolved} <- DcrPolicy.resolve(request.server_policy, iat_record_overrides(iat_record), request.metadata),
         :ok <- validate_intake(request.metadata),
         {:ok, credentials} <- generate_credentials(),
         {:ok, %Client{} = client} <- persist_client(request, resolved, iat_record, credentials) do
      emit_dcr_registration_succeeded(client, iat_record, request.source)
      {:ok, %Success{client: client, client_secret_plaintext: credentials.client_secret, registration_access_token_plaintext: credentials.rat}}
    else
      {:error, %Error{} = error} -> emit_dcr_registration_rejected(error, request.source); {:error, error}
    end
  end

  # ... private validate_intake/1, persist_client/4, emit_*/n, etc.
end
```

### Pattern 2: Find-by-hash + lock + freshness check + update in one transaction
**What:** Atomic single-use token redemption. The lock prevents two concurrent processes from observing the same `used_at IS NULL` row.

**When to use:** `Repository.redeem_initial_access_token/1`. Locked by D-09.

**Example (verbatim from `lib/lockspire/storage/ecto/repository.ex:534-557`):**
```elixir
@impl TokenStore
def mark_authorization_code_redeemed(token_hash, redeemed_at)
    when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
  transact(fn ->
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> lock("FOR UPDATE")
    |> repo_one(sensitive: true)
    |> case do
      nil ->
        repo().rollback(:not_found)
      %TokenRecord{redeemed_at: %DateTime{}} ->
        repo().rollback(:already_redeemed)
      %TokenRecord{} = record ->
        record
        |> Ecto.Changeset.change(redeemed_at: redeemed_at, updated_at: DateTime.utc_now())
        |> repo_update(sensitive: true)
        |> map_one(&TokenRecord.to_domain/1)
        |> unwrap_or_rollback()
    end
  end)
end
```

**Phase 26 application (D-08, D-10):**
```elixir
def redeem_initial_access_token(token_hash, redeemed_at)
    when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
  transact(fn ->
    InitialAccessTokenRecord
    |> where([iat], iat.token_hash == ^token_hash)
    |> lock("FOR UPDATE")
    |> repo_one(sensitive: true)
    |> case do
      nil -> repo().rollback(:not_found)
      %InitialAccessTokenRecord{revoked_at: %DateTime{}} -> repo().rollback(:revoked)
      %InitialAccessTokenRecord{expires_at: expires_at} when expires_at <= redeemed_at -> repo().rollback(:expired)
      %InitialAccessTokenRecord{single_use: true, used_at: %DateTime{}} -> repo().rollback(:already_used)
      %InitialAccessTokenRecord{} = record ->
        record
        |> Ecto.Changeset.change(used_at: redeemed_at, updated_at: DateTime.utc_now())
        |> repo_update(sensitive: true)
        |> map_one(&InitialAccessTokenRecord.to_domain/1)
        |> unwrap_or_rollback()
    end
  end)
end
```

The public `Lockspire.Protocol.InitialAccessToken.redeem/1` then collapses the discriminator (D-11):
```elixir
def redeem(plaintext) when is_binary(plaintext) do
  hash = Lockspire.Security.Policy.hash_token(plaintext)
  case Repository.redeem_initial_access_token(hash, DateTime.utc_now()) do
    {:ok, %Lockspire.Domain.InitialAccessToken{} = iat} ->
      Observability.emit(:iat_redeemed, %{count: 1}, %{iat_id: iat.id})
      {:ok, iat}
    {:error, reason} when reason in [:not_found, :revoked, :expired, :already_used] ->
      Observability.emit(:iat_redemption_failed, %{count: 1, failure_reason: reason}, %{})
      {:error, :invalid_token}
    {:error, other} ->
      Observability.emit(:iat_redemption_failed, %{count: 1, failure_reason: :unexpected}, %{detail: inspect(other)})
      {:error, :invalid_token}
  end
end
```

### Pattern 3: Observability emit with automatic redaction + audit mirror
**What:** Telemetry emission that fans out to both `[:lockspire, :audit, event]` (durable audit handler subscribes) and `[:lockspire, event]` (live telemetry handler subscribes), with metadata passed through `Redaction.for_telemetry/1`.

**When to use:** Every Phase 26 telemetry call. Locked by D-25, D-26.

**Example (verbatim from `lib/lockspire/observability.ex:15-29`):**
```elixir
@spec emit(event_name(), measurements(), metadata()) :: :ok
def emit(event_name, measurements \\ %{}, metadata \\ %{}) when is_atom(event_name) do
  redacted_metadata = redact(metadata)
  normalized_measurements = Map.put_new(measurements, :count, 1)

  :telemetry.execute([:lockspire, :audit] ++ [event_name], normalized_measurements, redacted_metadata)
  :telemetry.execute([:lockspire] ++ [event_name], normalized_measurements, redacted_metadata)
  :ok
end
```

**Phase 26 caller:**
```elixir
Observability.emit(:dcr_registration_succeeded, %{}, %{
  actor_type: :dcr,
  actor_id: iat_id_or_anonymous,
  client_id: client.client_id,
  iat_id: iat_record && iat_record.id,
  source_ip: source.ip,
  reason_code: :dcr_registration_succeeded
})
```

### Anti-Patterns to Avoid
- **Returning `:expired | :revoked | :already_used` from `redeem/1` public API** — leaks IAT existence (Pitfall 12 in `.planning/research/PITFALLS.md`). Always collapse to `:invalid_token` (D-11). The discriminator may go to telemetry (`failure_reason` measurement) but never out the public boundary.
- **Calling `:telemetry.execute/3` directly from Phase 26 modules** — bypasses `Redaction.for_telemetry/1` and the audit-mirror path. Always go through `Observability.emit/3` (D-25). The one existing exception (`Lockspire.Admin.Tokens.emit/4` at `tokens.ex:276-292`) does so to *restore* unredacted IDs for telemetry; Phase 26 has no such requirement.
- **Putting plaintext under unredacted keys** — `Redaction.for_telemetry/1` is a key-allowlist sieve. Keys like `:client_secret`, `:token`, `:token_hash`, `:authorization` are dropped (`redaction.ex:8-53`); other keys pass through. **The sieve does NOT include `:registration_access_token`, `:initial_access_token`, `:rat`, `:iat`** — Phase 26 must either (a) only ever emit these as `*_id`/`*_hash` fields (not plaintext), which D-17/D-25 already require, or (b) extend `redaction.ex:8-53` to add these key names. Recommendation: option (a) — never put plaintext into telemetry metadata in the first place; the D-27 redaction test will catch any accidental leak.
- **Hand-rolling SHA-256 hashing** — use `Lockspire.Security.Policy.hash_token/1` and `hash_client_secret/1`. Fixture drift caught Phase 25 (Pitfall: shared pattern §"Hash-at-rest via `Lockspire.Security.Policy.hash_token/1`" in `25-PATTERNS.md`).
- **A separate `Lockspire.Protocol.RegistrationIntakeValidator` module** — locked-out by D-02. Validator is private functions inside `Registration`. Same private validator is reused by `RegistrationManagement.update/2`; if a third caller emerges, then refactor to a shared module.
- **Persisting plaintext credentials anywhere** — D-17. The `Success` substruct's `*_plaintext` fields are short-lived and intended only for the Phase 27 controller's JSON view. They never enter the database, the audit row, or the telemetry payload.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Generate a `client_id` | New random-bytes-+-prefix function | `Lockspire.Clients.generate_client_id/0` (`clients.ex:384-386`) — **but see Open Question 2: it is currently `defp`** | Operator-created clients use this exact format; DCR-created clients must match for audit/admin parity |
| Hash `client_secret` | New `:crypto.hash` call | `Lockspire.Security.Policy.hash_client_secret/1` (`policy.ex:91-96`) — already wrapped by `Lockspire.Clients.rotate_secret_hash/0` (`clients.ex:53-56`) | Salt format `"sha256:salt:hash"` must match `verify_client_secret/2` (`policy.ex:98-114`) for subsequent client auth |
| Hash IAT or RAT | New `:crypto.hash` call | `Lockspire.Security.Policy.hash_token/1` (`policy.ex:84-89`) | Deterministic SHA-256 lowercase hex required for hash-equality lookup against `unique_index([:token_hash])` and `registration_access_token_hash` |
| Compare hashes | New `==` (vulnerable to timing) | `Plug.Crypto.secure_compare/2` (already used by `Security.Policy.verify_client_secret/2`) | Timing-safe comparison is non-negotiable for credential verification |
| Validate redirect URIs | New URI parsing + scheme/host/fragment checks | `Lockspire.Clients.validate_redirect_uris/1` (`clients.ex:32-39`) | DCR-02 requires exact-match parity with operator-created clients — locked by D-14 |
| Atomic single-use redemption | New `Ecto.Multi` or `SELECT ... FOR UPDATE NOWAIT` | `Repository.transact/1` + `lock("FOR UPDATE")` mirroring `mark_authorization_code_redeemed/2` (`repository.ex:534-557`) | Single-pattern consistency for every single-use lifecycle token in the codebase |
| Soft-disable a client | New SQL UPDATE | `Lockspire.Admin.Clients.disable_client/2` (public, `admin/clients.ex:127-148`) which calls private `disable_client_with_audit/4` | Must emit the `:client_disabled` audit event with the right actor; reusing the public function preserves all surrounding invariants |
| Append a DCR audit event | New `AuditEventRecord` insert | `Repository.append_audit_event/1` (`repository.ex:280-294`) or `Repository.transact_with_audit/2` (`repository.ex:296-312`) | `Audit.Event.normalize/1` enforces required fields and applies `Redaction.for_audit/1` to metadata; bypassing it leaks plaintext to durable rows |
| Drop secrets from telemetry | New filter in caller | `Lockspire.Observability.emit/3` (which calls `Redaction.for_telemetry/1`) | Project-wide single-source-of-truth for redaction. Adding a parallel filter creates drift. |

**Key insight:** Every primitive Phase 26 needs already exists in the repo. The risk surface is *misuse* (calling a private function, building a parallel filter, returning a discriminator that should be collapsed) — not building too much. Plan tasks to compose existing primitives, not to author new ones.

## Common Pitfalls

### Pitfall 1: Calling `Lockspire.Admin.Clients.disable_client_with_audit/4` from `RegistrationManagement.delete/2`
**What goes wrong:** D-21 says `RegistrationManagement.delete/2` calls `Lockspire.Admin.Clients.disable_client_with_audit/4`. But that function is `defp` (private) at `admin/clients.ex:348`. The compile will fail with `(UndefinedFunctionError) function Lockspire.Admin.Clients.disable_client_with_audit/4 is undefined or private`.
**Why it happens:** CONTEXT.md was authored from research notes; the assumption that the function was public was not verified against the actual `defp` at `admin/clients.ex:348`.
**How to avoid:** Pick one of:
1. Promote `disable_client_with_audit/4` to public (`def`) in `admin/clients.ex:348` — minimal change, surfaces a tested transactional helper for protocol callers.
2. Have `RegistrationManagement.delete/2` call the public `Admin.Clients.disable_client/2` (`admin/clients.ex:127-148`) which already wraps `disable_client_with_audit/4`. The public function takes `(client_id, attrs)` where `attrs` carries `:disabled_by`, `:disabled_at`, and `:actor`. This requires no changes to `admin/clients.ex` beyond D-22.
**Recommendation:** Option 2 — `disable_client/2` already does the right thing, including audit + telemetry; passing `actor: %{type: :self_registered_client, id: client.client_id}` flows correctly through `actor_from_attrs/1` (post-D-22 tightening).
**Warning signs:** Compile error at first build of `registration_management.ex`.

### Pitfall 2: Calling `Lockspire.Clients.generate_client_id/0` from `Registration.register/1`
**What goes wrong:** D-16 says `client_id` is generated via `Lockspire.Clients.generate_client_id/0`. But that function is `defp` at `clients.ex:384-386`. Compile failure.
**Why it happens:** Same as Pitfall 1.
**How to avoid:** Promote `generate_client_id/0` to public in `clients.ex:384`. Currently it's private because `Lockspire.Clients.register_client/1` is the only existing caller; Phase 26 makes `Registration` a second caller, which justifies promotion.
**Recommendation:** Promote to public with explicit `@spec`. Alternative — duplicate the 2-line idiom (`"ls_" <> Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)`) inline in `Registration` — but this fragments the format and risks drift if the prefix or length ever changes.
**Warning signs:** Compile error at first build of `registration.ex`.

### Pitfall 3: D-24 regression test queries non-existent `Repository.list_audit_events/1`
**What goes wrong:** D-24 says the regression test "queries `Repository.list_audit_events/1`". That function does not exist — `grep -n "list_audit_events" lib/lockspire/storage/ecto/repository.ex` returns no matches; the only `AuditEventRecord` references are at `repository.ex:19, 282-285`.
**Why it happens:** The function name was extrapolated from convention rather than verified.
**How to avoid:** Use the existing project pattern at `test/lockspire/admin/clients_test.exs:232-240`:
```elixir
defp dcr_audit_rows do
  import Ecto.Query
  alias Lockspire.Storage.Ecto.AuditEventRecord
  Lockspire.TestRepo.all(
    from(audit in AuditEventRecord,
      where: like(audit.action, "dcr_%"),
      order_by: [desc: audit.id])
  )
end
```
The regression assertion then becomes:
```elixir
assert Enum.all?(dcr_audit_rows(), fn row -> row.actor_type != "operator" end)
```
**Note:** `actor_type` is persisted as a **string** (Audit.Event.normalize/1 converts atom to string via `Atom.to_string/1` at `audit/event.ex:94`). The assertion compares against `"operator"` not `:operator`.
**Warning signs:** Function-undefined error at test load.

### Pitfall 4: Atom-singleton telemetry path may not satisfy a strict reading of DCR-23
**What goes wrong:** DCR-23 requires events under `[:lockspire, :dcr, ...]` and `[:lockspire, :iat, ...]`. `Observability.emit/3` produces 2-segment paths: `[:lockspire, :dcr_registration_succeeded]`. The atom prefix carries the namespace, but a strict reader of the spec might object that the path is not literally 3 segments.
**Why it happens:** D-26 acknowledges this and locks the atom-singleton choice; CONTEXT.md ## Specifics §1 documents the user's confirmation.
**How to avoid:** Document in code (module-level moduledoc on `Registration`) that the project-convention 2-segment shape is the chosen interpretation of the namespace requirement, with the deferred-ideas escape hatch noted (extend `Observability.emit/3` to multi-segment paths if a future audit requires).
**Warning signs:** Audit feedback or third-party telemetry consumer reports that they cannot subscribe to `[:lockspire, :dcr | _]` as a wildcard.
**Mitigation:** `:telemetry.attach_many/4` accepts an explicit list of event paths; subscribers attach to `[:lockspire, :dcr_registration_succeeded]`, `[:lockspire, :dcr_registration_rejected]`, etc., explicitly. This is the same pattern used at `test/lockspire/admin/clients_test.exs:215-227`.

### Pitfall 5: Plaintext IAT/RAT/secret leaks via unredacted metadata key
**What goes wrong:** A future caller writes `Observability.emit(:dcr_registration_succeeded, %{}, %{registration_access_token: rat_plaintext})`. `Redaction.for_telemetry/1` does NOT include `:registration_access_token` in its drop list (`redaction.ex:8-53`); the plaintext flows through to the audit row and to telemetry consumers.
**Why it happens:** `Redaction.for_telemetry/1` is a key-allowlist sieve — it drops listed keys, but anything not listed passes through. The drop list includes `:client_secret`, `:token`, `:token_hash`, `:authorization`, `:code`, `:code_challenge`, etc., but NOT `:registration_access_token`, `:initial_access_token`, `:rat`, `:iat`, `:plaintext`.
**How to avoid:** Two layers of defense:
1. **Discipline:** Phase 26 callers MUST emit ID/hash fields only (`iat_id`, `client_id`, `rat_hash`), never the plaintext. D-17 already requires plaintext live only on the `Success` substruct.
2. **Test:** D-27's single-sweep test catches any accidental leak by `String.contains?` against `inspect(captured_event)` — this is the safety net. Make this test a Wave 0 deliverable so it fails loudly the instant plaintext leaks.
**Optional belt-and-braces:** Add `:registration_access_token`, `:initial_access_token`, `:rat`, `:iat`, `:client_secret_plaintext`, `:registration_access_token_plaintext` to the drop list at `redaction.ex:8-53` (both atom and string forms). This is a 12-line change. Discuss with the planner whether it's worth doing as part of Phase 26 or whether the D-27 test alone is sufficient.

### Pitfall 6: Tightening `actor_from_attrs/1` breaks existing operator callers
**What goes wrong:** D-22 changes the three silent `:operator` fallbacks (lines 407, 414, 419) to raise. Existing tests and runtime callers that depend on the silent default break.
**Why it happens:** `Admin.Clients.create_client/1`, `update_client/2`, `rotate_client_secret/2`, `disable_client/2`, `enable_client/2` all pass `attrs` that may or may not contain `:actor`; the silent default has been masking missing-actor bugs.
**How to avoid:** Audit pass:
1. `grep -rn "Admin.Clients\.\(create_client\|update_client\|rotate_client_secret\|disable_client\|enable_client\)" lib test` — enumerate every callsite.
2. For each, verify `attrs[:actor][:type]` is set explicitly; if not, add it.
3. Confirm `test/lockspire/admin/clients_test.exs` already passes `actor: %{type: :operator, ...}` explicitly (it does: see `:73-83`).
4. Run `mix test` after the tightening; any failures with `(ArgumentError) actor type required` are missed callsites.
**Warning signs:** Test failures in unrelated specs after `actor_from_attrs/1` is tightened. The error message must name the offending field (D-22) so the failing callsite is obvious.
**Plan ordering:** Do the audit BEFORE tightening the function. Audit + tighten + run tests should be a single task to keep `mix test` always green between commits.

### Pitfall 7: `Lockspire.Domain.InitialAccessToken` vs `Lockspire.Protocol.InitialAccessToken` namespace confusion
**What goes wrong:** Two modules with very similar names — the Phase 25 `Lockspire.Domain.InitialAccessToken` is the defstruct; the Phase 26 `Lockspire.Protocol.InitialAccessToken` is the protocol module. A developer might `alias Lockspire.Domain.InitialAccessToken` at the top of `registration.ex` and then call `InitialAccessToken.redeem/1` — which doesn't exist on the domain struct.
**Why it happens:** D-01 names are sibling-namespaced (`Lockspire.Domain.X` vs `Lockspire.Protocol.X`), reusing an established axis from Phase 25 D-15.
**How to avoid:** When `Lockspire.Protocol.Registration` aliases both, alias the protocol module under a distinct name:
```elixir
alias Lockspire.Domain.InitialAccessToken, as: InitialAccessTokenStruct
alias Lockspire.Protocol.InitialAccessToken
```
or import without `alias`, qualifying the module path inline.
**Warning signs:** `(UndefinedFunctionError) function Lockspire.Domain.InitialAccessToken.redeem/1 is undefined`.

### Pitfall 8: Telemetry handler test using `assert_received` blocks the runner
**What goes wrong:** D-27 test wires a `:telemetry.attach` handler that sends to `self()`. If the test path emits N events, the test must `assert_received` (or accumulate via `receive`) all N before the timeout — otherwise the test passes spuriously.
**Why it happens:** `assert_received` only checks one message. The single-sweep approach in D-27 needs accumulation, not single-message assertion.
**How to avoid:** Use the existing pattern at `test/lockspire/admin/clients_test.exs:207-227` — the handler sends `{:telemetry_event, event, metadata}` to the test pid; the test then drains the mailbox via `flush/0` or a `receive` loop and folds into a list, which becomes the input to the single `String.contains?` sweep:
```elixir
defp drain_events(acc \\ []) do
  receive do
    {:telemetry_event, event, metadata} -> drain_events([{event, metadata} | acc])
  after
    100 -> Enum.reverse(acc)
  end
end
```
**Warning signs:** Test passes locally but flakes on CI when emission order varies. Use `Enum.sort/1` on the captured list before assertion if order-independence matters; or just rely on `String.contains?(inspect(events), plaintext)` — order does not affect substring search.

## Runtime State Inventory

Phase 26 is greenfield (new code, new tests) — there is no rename, refactor, migration, or string replacement of an existing identifier. CONTEXT.md ## Domain explicitly excludes schema migrations (Phase 25 territory). The runtime state to consider:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by inspection of `priv/repo/migrations/`. The `lockspire_initial_access_tokens` table (Phase 25 migration `20260427000010`) and the DCR fields on `lockspire_clients` (Phase 25 migration `20260427000020`) are already in place. Phase 26 only writes/reads them; it does not migrate them. | None |
| Live service config | None — no external services involved. The Lockspire library is embedded in the host Phoenix app. | None |
| OS-registered state | None — no scheduled jobs, system services, or daemons reference Phase 26 modules. | None |
| Secrets / env vars | None — Phase 26 does not introduce or rename any env var. The IAT plaintext and RAT plaintext are runtime-generated, never stored. The salt for `hash_client_secret/1` is per-secret-random (generated at hash time at `policy.ex:93`). | None |
| Build artifacts | None — Phase 26 does not change `mix.exs`, package metadata, or build output shape. | None |

**The canonical question** ("After every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?") does not apply: nothing is being renamed.

## Code Examples

### RFC 7591 §2.1 grant_types / response_types coherence (D-14)
**Source:** RFC 7591 §2.1 verbatim correlation table [CITED: https://datatracker.ietf.org/doc/html/rfc7591#section-2.1]:
```
grant_types value             response_types value
-----------------------------------------------------
authorization_code            code
implicit                      token
password                      (none)
client_credentials            (none)
refresh_token                 (none)
urn:...:jwt-bearer            (none)
urn:...:saml2-bearer          (none)
```

The "(none)" entry means the grant type does not require a corresponding `response_types` entry. Per Phase 26 scope (CONTEXT.md ## Domain `client_credentials` and bearer assertions are out of scope for v1.5; CONTEXT.md ## Specifics §6 also notes implicit is not supported), the validator must enforce:
- `grant_types: ["authorization_code"]` requires `response_types: ["code"]` (or `response_types` absent — RFC 7591 §2 default is `["code"]`).
- `grant_types: ["refresh_token"]` requires `grant_types` ALSO contain `"authorization_code"` (refresh tokens are issued by the authorization-code flow).
- Other grant types are out of scope; reject with `:invalid_client_metadata`.

**Implementation sketch (private function inside `Registration`):**
```elixir
@allowed_grant_types MapSet.new(["authorization_code", "refresh_token"])
@allowed_response_types MapSet.new(["code"])

defp validate_grant_response_coherence(metadata) do
  grant_types = metadata |> Map.get("grant_types", ["authorization_code"]) |> MapSet.new()
  response_types = metadata |> Map.get("response_types", ["code"]) |> MapSet.new()

  cond do
    not MapSet.subset?(grant_types, @allowed_grant_types) ->
      {:error, %Error{code: :invalid_client_metadata, field: :grant_types, reason: :unsupported_grant_type, allowed: MapSet.to_list(@allowed_grant_types)}}

    not MapSet.subset?(response_types, @allowed_response_types) ->
      {:error, %Error{code: :invalid_client_metadata, field: :response_types, reason: :unsupported_response_type, allowed: MapSet.to_list(@allowed_response_types)}}

    MapSet.member?(grant_types, "refresh_token") and not MapSet.member?(grant_types, "authorization_code") ->
      {:error, %Error{code: :invalid_client_metadata, field: :grant_types, reason: :refresh_token_requires_authorization_code, allowed: nil}}

    MapSet.member?(grant_types, "authorization_code") and not MapSet.member?(response_types, "code") ->
      {:error, %Error{code: :invalid_client_metadata, field: :response_types, reason: :authorization_code_requires_response_type_code, allowed: ["code"]}}

    true ->
      :ok
  end
end
```

### `jwks_uri` rejection (D-14, DCR-02)
**Source:** RFC 7591 §2 verbatim [CITED: https://datatracker.ietf.org/doc/html/rfc7591#section-2]: *"The 'jwks_uri' and 'jwks' parameters MUST NOT both be present in the same request or response."*
```elixir
defp validate_jwks(metadata) do
  has_jwks_uri = Map.has_key?(metadata, "jwks_uri")
  has_jwks = Map.has_key?(metadata, "jwks")

  cond do
    has_jwks_uri ->
      {:error, %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice, allowed: nil}}
    # (D-14 explicitly notes this branch is reached only if jwks_uri were not rejected above; kept for spec compliance.)
    has_jwks_uri and has_jwks ->
      {:error, %Error{code: :invalid_client_metadata, field: :jwks, reason: :mutually_exclusive_with_jwks_uri, allowed: nil}}
    true ->
      :ok
  end
end
```

### Audit attribution tightening (D-22)
**Before (`lib/lockspire/admin/clients.ex:407, 414, 419`):**
```elixir
defp normalize_actor_type(nil), do: :operator
defp normalize_actor_type(value) when is_atom(value), do: value
defp normalize_actor_type(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> :operator
    normalized -> normalized
  end
end
defp normalize_actor_type(_value), do: :operator
```

**After (D-22):**
```elixir
defp normalize_actor_type(nil),
  do: raise(ArgumentError, "actor.type is required; pass attrs[:actor][:type] explicitly. " <>
                            "Allowed: :operator | :system | :host_app | :dcr | :self_registered_client")
defp normalize_actor_type(value) when is_atom(value), do: value
defp normalize_actor_type(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> raise(ArgumentError, "actor.type cannot be blank")
    normalized -> normalized
  end
end
defp normalize_actor_type(other),
  do: raise(ArgumentError, "actor.type must be an atom or non-blank string, got: #{inspect(other)}")
```

### Telemetry redaction sweep test (D-27)
**Source:** combination of `test/lockspire/admin/clients_test.exs:207-230` (handler shape) + D-27 single-sweep assertion.
```elixir
defmodule Lockspire.Protocol.DcrTelemetryRedactionTest do
  use ExUnit.Case, async: false

  alias Lockspire.Protocol.{Registration, RegistrationManagement, InitialAccessToken}
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    handler_id = "dcr-redaction-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      [
        [:lockspire, :dcr_registration_succeeded],
        [:lockspire, :audit, :dcr_registration_succeeded],
        [:lockspire, :dcr_registration_rejected],
        [:lockspire, :audit, :dcr_registration_rejected],
        [:lockspire, :dcr_management_read],
        [:lockspire, :audit, :dcr_management_read],
        [:lockspire, :dcr_management_updated],
        [:lockspire, :audit, :dcr_management_updated],
        [:lockspire, :dcr_management_deleted],
        [:lockspire, :audit, :dcr_management_deleted],
        [:lockspire, :dcr_registration_access_token_rotated],
        [:lockspire, :audit, :dcr_registration_access_token_rotated],
        [:lockspire, :iat_redeemed],
        [:lockspire, :audit, :iat_redeemed],
        [:lockspire, :iat_redemption_failed],
        [:lockspire, :audit, :iat_redemption_failed]
      ],
      &__MODULE__.handle_event/4,
      self()
    )
    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  def handle_event(event, measurements, metadata, pid),
    do: send(pid, {:telemetry_event, event, measurements, metadata})

  defp drain_events(acc \\ []) do
    receive do
      {:telemetry_event, e, m, md} -> drain_events([{e, m, md} | acc])
    after
      50 -> Enum.reverse(acc)
    end
  end

  test "no plaintext RAT/IAT/client_secret in any DCR/IAT telemetry event or audit row" do
    iat_plaintext = "iat_test_#{:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}"
    {:ok, _iat_record} = Lockspire.Test.Fixtures.InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})
    server_policy = %Lockspire.Domain.ServerPolicy{registration_policy: :initial_access_token, ...}

    # Happy path — exercises register, RAT generation, secret hashing
    {:ok, %Registration.Success{client_secret_plaintext: secret_plain, registration_access_token_plaintext: rat_plain} = success} =
      Registration.register(%{metadata: valid_metadata(), iat: iat_plaintext, server_policy: server_policy, source: %{ip: "1.2.3.4"}})

    # Sad path — exercises rejected paths
    {:error, _} = Registration.register(%{metadata: invalid_metadata(), iat: iat_plaintext, server_policy: server_policy, source: %{ip: "1.2.3.4"}})

    # Management — exercises read/update/delete + RAT rotation
    {:ok, _} = RegistrationManagement.read(success.client.client_id, success.client)
    {:ok, _} = RegistrationManagement.update(success.client.client_id, success.client, valid_update_metadata())
    {:ok, _} = RegistrationManagement.delete(success.client.client_id, success.client)

    # IAT failure axes — minted, used (already_used), revoked, expired
    exercise_iat_failure_paths()

    captured_events = drain_events()
    audit_rows = Lockspire.TestRepo.all(from(a in AuditEventRecord, where: like(a.action, "dcr_%") or like(a.action, "iat_%")))

    plaintexts = [secret_plain, rat_plain, iat_plaintext]
    blob = inspect({captured_events, audit_rows})

    for plaintext <- plaintexts do
      refute String.contains?(blob, plaintext),
             "plaintext leaked into telemetry or audit; offending plaintext: #{plaintext}"
    end
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Ecto.Multi` for single-step transactions | `Repository.transact/1` + `lock("FOR UPDATE")` | v1.0 (`mark_authorization_code_redeemed/2`) | Phase 26 inherits — D-09 |
| Telemetry via raw `:telemetry.execute/3` | `Lockspire.Observability.emit/3` + `Lockspire.Redaction.for_telemetry/1` | v1.0 (Lockspire shipped with this from day one) | Phase 26 inherits — D-25 |
| Hand-rolled hash + compare | `Lockspire.Security.Policy.hash_*` + `Plug.Crypto.secure_compare` | v1.0 | Phase 26 inherits — D-04..D-07 |
| Atom-keyed metadata in audit rows | String-keyed (after `Audit.Event.normalize/1`) | v1.0 (`audit/event.ex:94`) | Phase 26 audit assertions compare against strings, not atoms — see Pitfall 3 |

**Deprecated/outdated:**
- The `.planning/research/ARCHITECTURE.md` "Module Layout" section (lines 124-129) lists `dcr_audit.ex` and proposes file paths that pre-date Phase 25 D-15's `Lockspire.Domain.X` vs `Lockspire.Protocol.X` namespace axis. CONTEXT.md D-01 supersedes the research doc; trust D-01.
- `.planning/research/PITFALLS.md:243` references "lines 450-472" for `actor_from_attrs/1`. Current code is at lines 397-419. Trust the file, not the research doc.
- CONTEXT.md ## Canonical References notes that older research docs cite `lib/lockspire/protocol/jar_policy.ex` — that file does not exist; use `lib/lockspire/protocol/par_policy.ex` as the resolver structural precedent (verified: `par_policy.ex` exists, no `jar_policy.ex` file in the protocol directory).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `disable_client_with_audit/4` will be promoted to public OR `disable_client/2` will be used instead | Pitfall 1, Open Question 1 | If neither happens, `RegistrationManagement.delete/2` won't compile |
| A2 | `generate_client_id/0` will be promoted to public OR the idiom is duplicated inline | Pitfall 2, Open Question 2 | If neither happens, `Registration.register/1` won't compile |
| A3 | The D-24 regression test queries `AuditEventRecord` directly, not a (non-existent) `Repository.list_audit_events/1` | Pitfall 3, Open Question 3 | Test won't compile until corrected |
| A4 | Atom-singleton telemetry path satisfies the project-internal interpretation of DCR-23's `[:lockspire, :dcr, ...]` namespace | Pitfall 4 (also CONTEXT.md ## Specifics §1) | If a Phase 29 audit reads DCR-23 strictly, may need to extend `Observability.emit/3` (deferred) |
| A5 | RFC 7591 §2.1 grant/response coherence rules above are accurate | Code Examples §1 | Verified against RFC text via WebFetch — but spec interpretation can drift; planner should re-read §2.1 if any test fails on a coherence assertion |

If any A1/A2/A3 turn out to require a different resolution, the planner should fold the resolution into the early "carve out helpers" tasks before authoring protocol modules.

## Open Questions

1. **`disable_client_with_audit/4` is currently `defp` (private) at `admin/clients.ex:348` — D-21 calls it from `RegistrationManagement.delete/2`.**
   - What we know: D-21 specifies the call. The function is private. The public `Admin.Clients.disable_client/2` (line 127) wraps it.
   - What's unclear: Whether to (a) promote the private function or (b) use `disable_client/2` instead.
   - Recommendation: Use `Admin.Clients.disable_client/2`. It already takes `(client_id, attrs)` where `attrs` carries `:disabled_by`, `:disabled_at`, and `:actor`. After D-22 tightens `actor_from_attrs/1`, passing `actor: %{type: :self_registered_client, id: client.client_id}` flows correctly. No changes to `admin/clients.ex` required beyond D-22.

2. **`Lockspire.Clients.generate_client_id/0` is currently `defp` (private) at `clients.ex:384-386` — D-16 calls it from `Registration.register/1`.**
   - What we know: D-16 specifies the call. The function is private.
   - What's unclear: Whether to promote it to public (smaller diff, single source of truth) or duplicate the 2-line idiom (`"ls_" <> Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)`) in `Registration`.
   - Recommendation: Promote to public. The format is operator-affecting (every operator-created and DCR-created client uses this prefix); keeping it in one place avoids drift.

3. **D-24 regression test queries `Repository.list_audit_events/1`, which does not exist.**
   - What we know: `grep` returns no matches for `list_audit_events` in `repository.ex`. Existing pattern at `test/lockspire/admin/clients_test.exs:232-240` queries `AuditEventRecord` directly via `Lockspire.TestRepo.all(from(...))`.
   - What's unclear: Whether to add `Repository.list_audit_events/1` to `repository.ex` (consistent with `register_client/1`, `list_clients/1` shape) or stay with the in-test direct-query pattern.
   - Recommendation: Stay with the in-test direct-query pattern. Phase 26's regression test is the only Phase 26 caller; adding a public Repository helper for one test is over-investment.

4. **Should `:registration_access_token`, `:initial_access_token`, `:rat`, `:iat` be added to the `Redaction.for_telemetry/1` and `Redaction.for_audit/1` drop lists at `redaction.ex:8-53`?**
   - What we know: Currently the drop list covers `:client_secret`, `:token`, `:token_hash`, `:authorization`, `:code`, `:code_verifier`, etc. — but NOT the named credential keys.
   - What's unclear: Whether D-27's single-sweep test is enough (defense via discipline + test) or whether the drop list itself should be extended (defense via filter).
   - Recommendation: Belt-and-braces — extend the drop list. 12-line addition. Reduces the blast radius if a future caller accidentally puts plaintext under one of these keys.

5. **What does `Registration.register/1` do when no `iat` is provided AND `server_policy.registration_policy = :initial_access_token`?**
   - What we know: D-12 says `iat: <plaintext_iat | nil>`. D-13 step 1 says "IAT redemption (if `iat` non-nil)".
   - What's unclear: When `iat` is nil but server policy requires one, where is that gating enforced?
   - Recommendation: Phase 26 enforces it before pipeline step 1: when `server_policy.registration_policy == :initial_access_token` and `iat == nil`, return `{:error, %Error{code: :invalid_token, field: :iat, reason: :missing}}` immediately. This keeps the protocol module self-sufficient and lets Phase 27's controller stay thin (the controller maps `:invalid_token` to `401`, which is the RFC 7592 default).

6. **What happens to old `Domain.Client` rows that were created before Phase 25's provenance backfill?**
   - What we know: Phase 25 migration `20260427000020_extend_lockspire_clients_dcr.exs` backfills existing rows to `:operator` (per ROADMAP.md SC 1).
   - What's unclear: None — verified.
   - Status: Resolved.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | language | yes | 1.19.5 | none — required |
| Erlang/OTP | runtime | yes | 28 | none — required |
| ecto_sql | persistence | yes | ~> 3.13.5 | none — required |
| postgrex | DB driver | yes | latest | none — required |
| Postgres | DB | assumed yes (project uses `Lockspire.TestRepo` with `Ecto.Adapters.SQL.Sandbox`) | latest with `FOR UPDATE` (any modern PG) | none — required |
| telemetry | event emission | yes | ~> 1.3 | none — required |
| jason | JSON encoding | yes | ~> 1.4 | none — required |
| plug_crypto | `secure_compare/2` | yes (transitive via phoenix) | latest | none — required |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

All Phase 26 work can proceed with the existing toolchain.

## Validation Architecture

`workflow.nyquist_validation = true` per `.planning/config.json`. This section is required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir 1.19.5) |
| Config file | `test/test_helper.exs` (excludes `:integration` tag by default; includes when `--include integration` passed) |
| Quick run command | `mix test test/lockspire/protocol/<file>_test.exs --max-failures 1` |
| Full suite command | `MIX_ENV=test mix test.fast` (alias: `mix lockspire.test.setup && mix test`) |
| Sandbox mode | `Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)` per setup_all (`pushed_authorization_request_test.exs:13-18`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DCR-02 | `jwks_uri` rejected with `invalid_client_metadata` "not supported in this slice" | unit | `mix test test/lockspire/protocol/registration_test.exs:test_jwks_uri_rejected -x` | ❌ Wave 0 |
| DCR-02 | `jwks` and `jwks_uri` cannot both be present | unit | `mix test test/lockspire/protocol/registration_test.exs:test_jwks_mutual_exclusion -x` | ❌ Wave 0 |
| DCR-02 | RFC 7591 §2 `grant_types`/`response_types` coherence — parametric (one test per pairing) | unit (parametric) | `mix test test/lockspire/protocol/registration_test.exs:test_grant_response_coherence -x` | ❌ Wave 0 |
| DCR-02 | `redirect_uris` routed through `Lockspire.Clients.validate_redirect_uris/1` (parity test) | unit | `mix test test/lockspire/protocol/registration_test.exs:test_redirect_uris_parity -x` | ❌ Wave 0 |
| DCR-03 | PKCE floor — explicit `pkce_required: false` rejected with clear reason | unit | `mix test test/lockspire/protocol/registration_test.exs:test_pkce_floor_explicit_false -x` | ❌ Wave 0 |
| DCR-03 | PKCE floor — `Domain.Client` row stored with `pkce_required: true` | unit | `mix test test/lockspire/protocol/registration_test.exs:test_persisted_pkce_required -x` | ❌ Wave 0 |
| DCR-04 | `client_secret` SHA-256-with-salt hashed at rest | unit | `mix test test/lockspire/protocol/registration_test.exs:test_client_secret_hashed_at_rest -x` | ❌ Wave 0 |
| DCR-04 | `registration_access_token` SHA-256 hashed at rest | unit | `mix test test/lockspire/protocol/registration_test.exs:test_rat_hashed_at_rest -x` | ❌ Wave 0 |
| DCR-04 | Plaintext returned exactly once on `Success` substruct | unit | `mix test test/lockspire/protocol/registration_test.exs:test_plaintext_returned_once -x` | ❌ Wave 0 |
| DCR-11 | `redeem/1` rejects expired IAT with `:invalid_token` | unit | `mix test test/lockspire/protocol/initial_access_token_test.exs:test_expired_returns_invalid_token -x` | ❌ Wave 0 |
| DCR-11 | `redeem/1` rejects revoked IAT with `:invalid_token` | unit | `mix test test/lockspire/protocol/initial_access_token_test.exs:test_revoked_returns_invalid_token -x` | ❌ Wave 0 |
| DCR-11 | `redeem/1` rejects already-used IAT with `:invalid_token` | unit | `mix test test/lockspire/protocol/initial_access_token_test.exs:test_already_used_returns_invalid_token -x` | ❌ Wave 0 |
| DCR-11 | Successful redemption marks `used_at` in same transaction | unit | `mix test test/lockspire/protocol/initial_access_token_test.exs:test_used_at_set_in_same_tx -x` | ❌ Wave 0 |
| DCR-11 | Atomicity — concurrent redemption attempts produce exactly one success | concurrent (Task.async-many) | `mix test test/lockspire/protocol/initial_access_token_test.exs:test_concurrent_redemption_atomicity -x` | ❌ Wave 0 |
| DCR-22 | `actor_from_attrs/1` raises `ArgumentError` on missing actor type | unit | `mix test test/lockspire/admin/clients_test.exs:test_actor_from_attrs_raises_on_missing -x` | ❌ Wave 0 (extension to existing test) |
| DCR-22 | DCR write paths attribute `:dcr` for intake; `:self_registered_client` for management | unit | `mix test test/lockspire/protocol/dcr_audit_attribution_test.exs:test_dcr_actor_types -x` | ❌ Wave 0 |
| DCR-22 | Regression — no `dcr_*` audit row has `actor_type = "operator"` | regression | `mix test test/lockspire/protocol/dcr_audit_attribution_test.exs:test_no_operator_dcr_attribution -x` | ❌ Wave 0 |
| DCR-23 | Single-sweep — RAT/IAT/`client_secret` plaintext absent from telemetry events | unit (sweep) | `mix test test/lockspire/protocol/dcr_telemetry_redaction_test.exs:test_no_plaintext_in_telemetry -x` | ❌ Wave 0 |
| DCR-23 | Single-sweep — RAT/IAT/`client_secret` plaintext absent from audit rows | unit (sweep) | `mix test test/lockspire/protocol/dcr_telemetry_redaction_test.exs:test_no_plaintext_in_audit_rows -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/lockspire/protocol/<the_file_being_changed>_test.exs --max-failures 1` (typically <5s).
- **Per wave merge:** `mix test test/lockspire/protocol/ test/lockspire/admin/clients_test.exs --max-failures 3` (Phase 26 file scope).
- **Phase gate:** `mix test.fast` (full unit suite) green; `mix qa` (`format`, `compile --warnings-as-errors`, `credo --strict`, `dialyzer`) green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/support/fixtures/dcr_fixtures.ex` — inbound RFC 7591 metadata fixtures (valid intake map, invalid `jwks_uri` map, invalid grant/response coherence map, invalid redirect URI map, etc.); RAT plaintext helpers; `Registration` request-tuple builder.
- [ ] `test/support/fixtures/initial_access_token_fixtures.ex` — extend with `persist/1` helper that inserts the IAT row and returns the plaintext (current fixture builds the struct only; redemption tests need a row present).
- [ ] `test/lockspire/protocol/registration_test.exs` — covers DCR-02, DCR-03, DCR-04 happy + sad paths.
- [ ] `test/lockspire/protocol/registration_management_test.exs` — covers RFC 7592 `read/2`, `update/2` (full-replace + RAT rotation invalidation), `delete/2` (soft-disable + reuse prevention).
- [ ] `test/lockspire/protocol/initial_access_token_test.exs` — covers DCR-11 freshness ladder + atomicity (Task.async concurrent test).
- [ ] `test/lockspire/protocol/registration_access_token_test.exs` — covers RAT generate/hash primitives.
- [ ] `test/lockspire/protocol/dcr_audit_attribution_test.exs` — covers DCR-22 regression assertion.
- [ ] `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` — covers DCR-23 single-sweep redaction.
- [ ] `test/lockspire/admin/clients_test.exs` — extend with the `actor_from_attrs/1`-raises tests; audit existing tests pass `:actor` explicitly (verified at line 57-61 they do, but a sweep through `update_client`, `rotate_client_secret`, `disable_client`, `enable_client` callers in tests is needed).

### Concurrency Test Pattern (DCR-11 atomicity)
```elixir
test "concurrent redemption — exactly one task wins, the rest get :invalid_token" do
  iat_plaintext = "iat_concurrent_test"
  {:ok, _row} = Lockspire.Test.Fixtures.InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})

  # Each task needs its own DB connection in sandbox mode — share via parent allowance
  parent = self()
  tasks =
    for _ <- 1..10 do
      Task.async(fn ->
        Ecto.Adapters.SQL.Sandbox.allow(Lockspire.TestRepo, parent, self())
        Lockspire.Protocol.InitialAccessToken.redeem(iat_plaintext)
      end)
    end

  results = Task.await_many(tasks, 5_000)

  successes = Enum.count(results, &match?({:ok, _}, &1))
  failures = Enum.count(results, &match?({:error, :invalid_token}, &1))
  assert successes == 1, "expected exactly one redemption success, got #{successes}"
  assert failures == 9, "expected nine :invalid_token failures, got #{failures}"
end
```

## Security Domain

`security_enforcement` is not explicitly disabled in `.planning/config.json`; treat as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | RAT-bearing auth for RFC 7592; comparison via `Plug.Crypto.secure_compare` (timing-safe) |
| V3 Session Management | no | DCR is stateless (request → response); no session |
| V4 Access Control | yes | URL `client_id` MUST match RAT-bound `client.client_id` (D-19); mismatch → `:invalid_token` (no enumeration leak) |
| V5 Input Validation | yes | RFC 7591 §2 metadata validation — `Lockspire.Clients.validate_redirect_uris/1`, private intake validator (D-14), `DcrPolicy.resolve/3` (Phase 25) |
| V6 Cryptography | yes | `Lockspire.Security.Policy.hash_token/1` (SHA-256), `hash_client_secret/1` (salted SHA-256). Never hand-roll. |
| V7 Error Handling | yes | Error-axis collapsing (D-11) — never return discriminating reasons that enable enumeration |
| V9 Communications | n/a | Phase 27 territory (TLS, host responsibility) |
| V11 Business Logic | yes | Atomic single-use redemption (D-09, D-10) — race conditions would defeat the single-use guarantee |
| V14 Configuration | yes | Empty allowlist semantics (`dcr_policy.ex:32-46` documents the operator UX hazard) |

### Known Threat Patterns for Elixir/Phoenix + Postgres + DCR

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| IAT enumeration via timing or error-discriminator | Information Disclosure | Collapse all redemption rejections to `:invalid_token` (D-11); use `Plug.Crypto.secure_compare` for hash equality |
| RAT enumeration via differentiated error returns | Information Disclosure | `RegistrationManagement` returns `:invalid_token` for both "no row found by RAT hash" and "URL `client_id` doesn't match RAT-bound client" (D-19) |
| Race condition — two concurrent IAT redemptions both succeed | Tampering | `Repo.transact/1` + `lock("FOR UPDATE")` (D-09) |
| Plaintext RAT/IAT/secret in telemetry, audit row, or log | Information Disclosure | `Lockspire.Redaction.for_telemetry/1` + `for_audit/1` drop lists; D-27 single-sweep test catches accidental leaks |
| Operator-flavored audit attribution for DCR writes | Repudiation / forensic confusion | D-22: `actor_from_attrs/1` raises on missing type; D-24 regression test enforces |
| `jwks_uri` SSRF | Tampering / SSRF | Reject `jwks_uri` at intake (D-14); SSRF-guarded fetch deferred to DCR-FUT-01 |
| Open registration abuse (no rate limit) | DoS | v1.5 documents host-Plug seam responsibility (Phase 29 SECURITY.md); built-in rate limit deferred to DCR-FUT-04 |
| Public client default with PKCE-disabled | Tampering / token theft | D-15 PKCE floor: explicit `pkce_required: false` rejected; `Domain.Client` row always `pkce_required: true` for self-registered clients |
| Software statement (RFC 7591 §2.3) trust-root confusion | Tampering | Out of scope for v1.5 (REQUIREMENTS.md ## Out of Scope); not parsed, not stored, not validated. Inbound `software_statement` field is ignored — see Pitfall 9 below |

### Additional Pitfall — Software Statement (out of scope, but inbound field must be ignored gracefully)
**What goes wrong:** A registrant POSTs metadata containing `software_statement: <jwt>` (RFC 7591 §2.3). v1.5 does not support software statements. If `Registration.register/1` rejects the entire request because of an unknown field, registrants with software-statement-aware clients see a hard failure and cannot register at all.
**Why it happens:** REQUIREMENTS.md ## Out of Scope explicitly excludes software statements. RFC 7591 §2 is permissive about unknown fields ("Extensions and profiles of this specification MAY define new metadata members for use in client registration").
**How to avoid:** The intake validator MUST silently ignore unknown fields, including `software_statement`. The validator's allowlist is "the fields we explicitly handle"; everything else is dropped before persistence. Test: register with `software_statement: "eyJ..."` and assert the persisted `Domain.Client` row does not contain a software-statement field, AND the registration succeeds normally.
**Warning signs:** Registration test fails when registrant includes any RFC 7591 extension field.

## Sources

### Primary (HIGH confidence)
- `/Users/jon/projects/lockspire/lib/lockspire/protocol/pushed_authorization_request.ex` — full read; the structural precedent for D-01 modules
- `/Users/jon/projects/lockspire/lib/lockspire/security/policy.ex` — full read; verifies `hash_token/1`:84-89, `hash_client_secret/1`:91-96, `verify_client_secret/2`:99-114
- `/Users/jon/projects/lockspire/lib/lockspire/clients.ex` — full read; verifies `validate_redirect_uris/1`:32, `rotate_secret_hash/0`:53, `generate_client_id/0`:384 (PRIVATE)
- `/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex` — full read; verifies `actor_from_attrs/1`:397-419 with three silent fallbacks at 407, 414, 419, `disable_client_with_audit/4`:348 (PRIVATE), `disable_client/2`:127 (public), `client_audit_event/5`:386-395
- `/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex` — selective read of lines 1-120, 220-340, 500-620, 700-920; verifies `transact/1`:223, `transact_with_audit/2`:296-312, `mark_authorization_code_redeemed/2`:534-557 pattern, `register_client/1`:44, `update_client/2`:74, lock pattern usage at 80, 79, 267, 527, 540, 708, 748, 910, 917
- `/Users/jon/projects/lockspire/lib/lockspire/observability.ex` — full read; verifies `emit/3`:15-29 produces 2-segment paths
- `/Users/jon/projects/lockspire/lib/lockspire/redaction.ex` — full read; verifies `for_telemetry/1` drop list at lines 8-53; confirms `:registration_access_token`/`:initial_access_token` are NOT in drop list
- `/Users/jon/projects/lockspire/lib/lockspire/audit/event.ex` — full read; verifies `normalize/1` converts atom→string at line 94, applies `Redaction.for_audit/1` to metadata
- `/Users/jon/projects/lockspire/lib/lockspire/protocol/dcr_policy.ex` — full read; verifies `Resolved` substruct fields (D-13 step 2 input)
- `/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/initial_access_token_record.ex` — full read; verifies schema, `to_domain/1` shape
- `/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/audit_event_record.ex` — full read; verifies `actor_type` field at line 16 (string)
- `/Users/jon/projects/lockspire/lib/lockspire/domain/initial_access_token.ex` — full read
- `/Users/jon/projects/lockspire/lib/lockspire/domain/client.ex` — full read; verifies DCR field set (`provenance`, `registration_access_token_hash`, `initial_access_token_id`, `client_id_issued_at`, `client_secret_expires_at`)
- `/Users/jon/projects/lockspire/test/lockspire/admin/clients_test.exs` — selective read; verifies test pattern for telemetry capture (lines 207-230) and audit-row query (lines 232-240)
- `/Users/jon/projects/lockspire/test/lockspire/protocol/pushed_authorization_request_test.exs` — selective read; verifies test setup pattern (`Lockspire.TestRepo`, `Ecto.Adapters.SQL.Sandbox`, `mode :manual`)
- `/Users/jon/projects/lockspire/test/support/fixtures/initial_access_token_fixtures.ex` — full read; existing fixture, can be extended for `persist/1`
- `/Users/jon/projects/lockspire/priv/repo/migrations/20260427000010_create_lockspire_initial_access_tokens.exs` — full read; verifies `unique_index([:token_hash])` shipped
- `/Users/jon/projects/lockspire/mix.exs` — full read; verifies dependency versions
- `/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md`, `/Users/jon/projects/lockspire/.planning/STATE.md`, `/Users/jon/projects/lockspire/.planning/ROADMAP.md`, `/Users/jon/projects/lockspire/.planning/phases/26-*/26-CONTEXT.md`, `/Users/jon/projects/lockspire/.planning/phases/26-*/26-DISCUSSION-LOG.md` — full reads

### Authoritative External (HIGH confidence)
- RFC 7591 — Dynamic Client Registration Protocol — verified via WebFetch [CITED: https://datatracker.ietf.org/doc/html/rfc7591]: §2 (client metadata), §2.1 (grant_types/response_types correlation table + jwks_uri/jwks mutual exclusion), §3.2.1 (client information response), §3.2.2 (client registration error response — `invalid_client_metadata` error code)
- RFC 7592 — Dynamic Client Registration Management Protocol [CITED: https://datatracker.ietf.org/doc/html/rfc7592]: referenced for §2 (read), §2.1 (update — full-replace), §2.2 (delete — soft-disable), §3 (error codes)
- RFC 6749 §5.2 — `invalid_token` error semantics [CITED: https://datatracker.ietf.org/doc/html/rfc6749#section-5.2]: basis for D-11 collapsing

### Secondary (MEDIUM confidence)
- `.planning/research/ARCHITECTURE.md` — directional but contains stale references (`jar_policy.ex` and module path conventions superseded by Phase 25 D-15). Trust the file evidence above where it conflicts.
- `.planning/research/PITFALLS.md` — Pitfall 10 (audit attribution) and Pitfall 12 (revoked vs used) referenced by CONTEXT.md. Line numbers cited (`450-472`) are stale.

### Tertiary (LOW confidence)
- None — every claim in this research is backed by a concrete file:line or an authoritative spec section.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every dependency verified in `mix.exs`, every helper verified at file:line.
- Architecture: HIGH — patterns are direct from existing code; `mark_authorization_code_redeemed/2` and `PushedAuthorizationRequest.push/1` are verbatim precedents.
- Pitfalls: HIGH — three of the eight pitfalls (Pitfalls 1, 2, 3) are concrete code-correctness issues found by direct codebase inspection; the others are documented design considerations from CONTEXT.md.
- RFC interpretation: HIGH for §2 and §2.1 (verified via WebFetch); MEDIUM for §3 corner cases — planner should re-verify §3 boundary conditions when authoring `RegistrationManagement` tests.
- Open Questions: HIGH that the questions exist; recommendation rationale is opinion-with-evidence.

**Research date:** 2026-04-26
**Valid until:** 2026-05-26 (30 days; codebase is internally stable, but RFC interpretation is locked, so this research stays valid as long as `mix.exs` deps and the cited line numbers don't move significantly)

---

*Phase: 26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co*
*Research conducted: 2026-04-26*
