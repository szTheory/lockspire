# Phase 56: RAR Domain Validation & Storage - Research

**Researched:** 2026-05-06
**Domain:** OAuth 2.0 Rich Authorization Requests (RFC 9396) — host-extensible validation framework + durable storage
**Confidence:** HIGH

## Summary

Phase 56 turns Phase 55's RAR intake (parse + persist on PAR/Interaction with a 2048-byte length cap) into an enforceable framework. Three deliverables:

1. **Host-seam:** `Lockspire.Host.RarTypeValidator` behaviour, registered per-`type` via `config :lockspire, :rar_validators, %{...}`. Strict-reject unknown types.
2. **Validator-output normalization:** validators return a normalized map (typically `Ecto.Changeset.apply_changes/1` of a schemaless changeset) and that — not the raw decoded JSON — is what gets persisted everywhere.
3. **Durable RAR ↔ ConsentGrant binding:** new JSONB columns on `consent_grants` (`authorization_details`, `authorization_details_fingerprint`), new `consent_grant_id` FK on `tokens` with `on_delete: :nilify_all`, refresh exchange propagates the FK exactly the way `family_id` already does, and `ConsentPolicy.reusable_grant/3` extends with the fingerprint key so "same scopes / different RAR" forces re-consent.

The fingerprint is RFC 8785 JCS canonicalization → SHA-256, implemented via the `jcs` Hex package (v0.2.0, March 2025) — **not** plain `Jason.encode!/1`, because Elixir map iteration order is explicitly undefined post-1.14 and a non-canonical hash would cause spurious re-consent prompts (the ory/fosite RAR draft footgun the reuse-policy was designed against).

**Primary recommendation:** Mirror the existing `Lockspire.Host.TokenExchangeValidator` host-seam pattern verbatim for `RarTypeValidator` (single behaviour, runtime config, default impl shipped alongside, accessor on `Lockspire.Config`). Use the `jcs` Hex package for canonicalization. Extend `validate_authorization_details/2` at the existing dispatch point so Phase 55's `{:redirect_error, ...}` machinery composes for free. Phase 55 storage path (Interaction RAR copy) needs to be retrofitted to store **validator output**, not raw input — this is the most subtle behavior change in the phase.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| RAR type → validator dispatch | API / Backend (`Lockspire.RAR.Dispatcher`) | — | Pure protocol-tier logic; no UI, no persistence. |
| Host-defined RAR validation | Host App | API / Backend (behaviour contract) | Validation rules live in the host app; Lockspire defines the seam. |
| Strict-reject unknown types | API / Backend | — | Protocol-tier policy decision — no host call needed. |
| RFC 8785 canonicalization + SHA-256 | API / Backend (`Lockspire.RAR.Fingerprint`) | — | Deterministic content-addressing over normalized output. |
| RAR durable storage on grants | Database / Storage (`consent_grants.authorization_details`, JSONB) | API / Backend (write path) | ConsentGrant already plays the durable-consent role; extend it. |
| RAR propagation through token rotations | API / Backend (`RefreshExchange`) | Database / Storage (`tokens.consent_grant_id` FK) | Same pattern as `family_id`; FK reference, not embedded JWT. |
| Reuse-policy fingerprint match | API / Backend (`ConsentPolicy.reusable_grant/3`) | Database / Storage (partial index) | Pure decision logic + index-backed lookup. |
| Telemetry emission | API / Backend (`Lockspire.Observability.emit/4`) | — | Reuses existing telemetry surface (additive). |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Validator Registration Shape**
- **D-01:** Per-type config map. `config :lockspire, :rar_validators, %{"payment_initiation" => MyApp.RAR.PaymentInitiation, ...}`. Map keys are the **single source of truth** for what types Lockspire supports — the Phase 58 discovery list will be `Map.keys(rar_validators) |> Enum.sort()`. No second source of truth, no drift.
- **D-02:** `Lockspire.Host.RarTypeValidator` behaviour, one impl per type. Lives in `lib/lockspire/host/rar_type_validator.ex`. Mirrors the existing `Lockspire.Host.*` host-seam pattern (`TokenExchangeValidator`, `AccountResolver`, `BackchannelNotification`) — single behaviour, registered via `Application.get_env`. No macros, no compile-time auto-registration, no `:persistent_term`. Runtime config; overridable in tests.
- **D-03:** Two new accessors on `Lockspire.Config`: `rar_validators/0` (map, default `%{}`) and `rar_types_supported/0` (sorted keys list — Phase 58 will consume this).
- **D-04:** Behaviour callback signature: `@callback validate(detail :: map(), ctx :: map()) :: {:ok, map()} | {:error, Ecto.Changeset.t() | String.t()}`. Two-arity to mirror `TokenExchangeValidator(context)` precedent and let validators reach `client_id`, `account_id`, request metadata if needed. `ctx` shape to be designed in planning, but minimally includes `:client_id`, `:account_id`, `:request` (optional fields kept minimal).

**Validator API Shape (the "Ecto-based" semantic from SC#1)**
- **D-05:** Behaviour contract is **plain map → result**, not "must be a changeset." This matches Phase 55's existing host-seam convention and lets hosts pick their validation idiom (Ecto / NimbleOptions / pattern-matching) without fighting the API. The "Ecto-based" SC#1 wording is satisfied because (a) the canonical generated example uses `Ecto.Changeset`, (b) Lockspire's error-formatter helper accepts a changeset, (c) host-supplied changesets are first-class on the error path.
- **D-06:** Lockspire ships a small `Lockspire.RAR.error_description/1` helper that formats `Ecto.Changeset.t()` errors via `traverse_errors/2` into a single RFC-compliant `error_description` string. Strings pass through unchanged. This keeps host validator bodies clean.
- **D-07:** Generated install template (the `mix lockspire.gen.rar_validator <type>` task — see deferred ideas below) emits a **schemaless changeset** body, not `embedded_schema`. Schemaless is the more honest fit for "validate one inbound JSON object that never persists as a top-level row" (Ecto guides recommend exactly this for inbound API payload validation). Hosts who prefer `embedded_schema` (Ash shops, etc.) remain free to use it.
- **D-08:** Validator output is **stored**, not raw input. Validators return `{:ok, normalized_map}` (typically the `apply_changes` of a changeset), and that normalized map is what Lockspire persists on PAR/Interaction/ConsentGrant. Unknown fields are dropped at validation time. This is a deliberate behavior change from Phase 55 (which stored raw decoded JSON) — security win because unsupported fields can't leak into introspection responses or refresh tokens. Phase 55 storage path needs to be retrofitted to use validator output.

**Unknown-Type Behavior (SC#2 anchor)**
- **D-09:** **Strict reject from day 1.** When an RAR `type` has no registered validator, Lockspire returns `error: "invalid_authorization_details"` per RFC 9396 §5 (normative MUST). No `:warn` migration knob — Lockspire is pre-1.0 (`0.2.0` in `mix.exs`), Phase 55 shipped today (2026-05-06), there's no installed base to soften the cutover for. Strict-from-day-1 keeps the design clean.
- **D-10:** **Per-client unknown-type policy override is deferred.** Tempting (`Client.metadata[:rar_unknown_type_policy]`), but adding a per-client softener before the global behavior is locked invites the secure-default-bypass-by-omission footgun (forgetting to set it on a new client). If pain emerges, add it in a later milestone.
- **D-11:** **`error_description` deliberately omits the offending type name in the redirect.** RFC 9396 §6 permits including it, but exposing the host's exact validator inventory to unauthenticated probes is a small information-disclosure footgun. The offending type **does** land in telemetry + structured logs (see D-15) so operators can debug. At the token endpoint (post-client-auth), inclusion is OK — planning can decide whether to differentiate the two surfaces.
- **D-12:** **FAPI 2.0 alignment** — strict reject is the global default already; no per-profile branching needed. If a future per-client softener is ever added (D-10), `security_profile: :fapi_2_0_security` MUST clamp it back to strict.

**Durable Storage (SC#3 anchor)**
- **D-13:** Add `authorization_details: {:array, :map}` (default `[]`) and `authorization_details_fingerprint: :binary` (32-byte SHA-256, nil when RAR absent) to `consent_grants`. `Lockspire.Domain.ConsentGrant` and `Lockspire.Storage.Ecto.ConsentGrantRecord` get the new fields. **No new domain/store seam** — `ConsentGrant` already plays the durable-consent role and a parallel `AuthorizationGrant` would duplicate it.
- **D-14:** Add `consent_grant_id` FK to `tokens` (`references(:consent_grants, on_delete: :nilify_all)`). `:nilify_all` not `:delete_all` — revoking a ConsentGrant must leave token rows for revocation/audit (Doorkeeper rationale). `Lockspire.Domain.Token` and `Lockspire.Storage.Ecto.TokenRecord` gain the field. `Lockspire.Protocol.AuthorizationFlow.issue_authorization_code/3` and `Lockspire.Protocol.RefreshExchange` propagate it through token rotations exactly the way `family_id` already rides along.
- **D-15:** **Phase 55's `Interaction.authorization_details` field stays.** It's the pre-validation snapshot at `/authorize` time; ConsentGrant carries the post-grant truth. Two different concepts (request vs grant — RFC 9396 §3.1 explicitly contemplates user granting a subset of requested details). Both rows persist their own copy. Interaction's lifecycle remains tied to authorization-code TTL; ConsentGrant survives refresh rotations.
- **D-16:** **Reuse-policy fingerprint.** `Lockspire.Protocol.ConsentPolicy.reusable_grant/3` extends from `(account_id, client_id, scopes)` to `(account_id, client_id, scopes, authorization_details_fingerprint)`. Same scopes + different RAR ⇒ re-consent (RFC 9396 §7).
- **D-17:** **Fingerprint algorithm:** RFC 8785 JCS-style canonicalization, then SHA-256. New module `Lockspire.RAR.Fingerprint`: recursive sort of map keys, deterministic list ordering, normalized number encoding, then `Jason.encode!/1`, then `:crypto.hash(:sha256, ...)`. **Not** `Jason.encode!/1` directly — Elixir/Jason map iteration order is not guaranteed deterministic, and that footgun bit early `ory/fosite` RAR drafts (semantically-equal RAR sets producing different hashes ⇒ spurious re-consent prompts).
- **D-18:** **JSONB column** for `authorization_details` (`{:array, :map}` resolves to JSONB array in Postgres — same idiom Phase 55 uses on `pushed_authorization_requests` and `interactions`). No GIN index in Phase 56 (queryability is Phase 57's territory if needed); fingerprint index covers reuse-policy lookup.
- **D-19:** **Index strategy.** New partial index `consent_grants_reuse_idx` on `(account_id, client_id, authorization_details_fingerprint) WHERE status = 'active'`. New plain index on `tokens(consent_grant_id)` for refresh + introspection lookups.

**Telemetry & Operability**
- **D-20:** New telemetry events:
  - `[:lockspire, :rar, :validation, :start | :stop | :exception]` — span events around `validator.validate(detail, ctx)`. Measurements: `:duration`. Metadata: `:type`, `:client_id`, `:outcome` (`:ok | :error`).
  - `[:lockspire, :rar, :unknown_type]` — emitted at strict-reject. Measurements: `%{count: 1}`. Metadata: `:type`, `:client_id`. Operators monitor this to spot misconfigured hosts.
  These are additive; Phase 55's existing authorization-flow telemetry stays unchanged.
- **D-21:** Logger-level for unknown-type rejection: `Logger.warning` with structured fields. Hosts can crank logger-level higher to suppress in tests.

**Module Layout (planning input)**
- **D-22:** New Lockspire modules introduced by this phase:
  - `Lockspire.Host.RarTypeValidator` — public behaviour (host-facing).
  - `Lockspire.RAR.Dispatcher` (working name) — internal dispatch from `type` → registered validator + telemetry + unknown-type policy. Single entrypoint called from `Lockspire.Protocol.AuthorizationRequest.validate_authorization_details/2` (which today only does shape/length checks).
  - `Lockspire.RAR.Fingerprint` — canonicalization + hashing.
  - `Lockspire.RAR` — small public helper: `error_description/1`.
- **D-23:** Phase 55's `validate_authorization_details/2` in `lib/lockspire/protocol/authorization_request.ex` (lines 570-590) is the integration point. Phase 56 extends it: after the existing shape check, dispatch each detail to its registered validator; on success, replace the raw detail with the normalized output; on failure, return `{:redirect_error, :invalid_authorization_details, ...}` exactly as Phase 55 already does for shape failures (so Phase 55's existing redirect-error machinery composes).

### Claude's Discretion

- Naming of `Lockspire.RAR.Dispatcher` (could be `.Validation`, `.Coordinator`, etc.) — let planning pick.
- Exact shape of `ctx` map passed to validators — planning will derive from concrete validator-call sites in `AuthorizationRequest.validate/1` and PAR re-entry path. Minimum: `:client_id`. Likely additions: `:account_id` (when known), `:scopes_requested`, `:resources_requested`, `:request` (the raw params map for advanced cases).
- Whether to reuse Phase 55's `byte_size > 2048` length cap as-is or pre-validate per-detail size — planning judgment based on real RAR-size profiles.
- Whether to emit a `mix lockspire.gen.rar_validator <type>` generator in this phase or defer it (see deferred ideas).
- Whether to add a `Lockspire.Host.PermissiveRarValidator` default-impl convenience module (mirror of `DefaultDelegationValidator` / `DefaultDenyTokenExchangeValidator`) — likely yes for symmetry and tests, but planning's call.

### Deferred Ideas (OUT OF SCOPE)

- **`mix lockspire.gen.rar_validator <type>` generator** — Phoenix-style generator that scaffolds a host validator module from a schemaless-changeset template. Nice DX, but not required for SC#1/#2/#3. Defer to a follow-up phase or fold into install-DX work; planning has discretion to include if it's a small wave.
- **Per-client unknown-type policy** (`Client.metadata[:rar_unknown_type_policy]`) — see D-10. Adds operator flexibility; adds secure-default-bypass risk. Defer until real demand surfaces.
- **`rar_unknown_type_policy: [:reject | :warn]` migration knob** — see D-09. Useful only if there's an installed Phase-55 base that needs a soft cutover. Currently there isn't.
- **GIN index on `consent_grants.authorization_details`** — for querying "all grants with type X." Phase 57 introspection might want this; defer until query patterns are concrete.
- **Per-type discovery metadata schemas** (e.g., publishing JSON Schema for each `authorization_details_types_supported` entry) — RFC 9396 doesn't require this, but production servers like Curity ship it. Defer to a milestone-closure phase if integrators ask.
- **JAR projection of `authorization_details`** — Phase 57 (V-02 FAPI 2.0 + RAR), not Phase 56.
- **Consent UI rendering of `authorization_details`** — Phase 57 (SC #3).
- **`/introspection` exposure of RAR** — Phase 57 (RAR-04).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RAR-02 | Provide Ecto-based validation framework for host-defined RAR types | Standard Stack §"Validation framework", Code Examples §"Schemaless changeset validator (canonical generated body)", §"Lockspire.Host.RarTypeValidator behaviour", §"Lockspire.RAR.Dispatcher", §"Lockspire.RAR.error_description/1" |
| RAR-03 | Store approved RAR details in `Lockspire.Storage` and associate with minted tokens | Architecture Patterns §"Domain → Record → Store extension", Code Examples §"Migration concretes", §"ConsentGrant FK propagation through RefreshExchange", §"Reuse-policy fingerprint key" |

Both requirements are addressed by the same set of new modules and the same migration; planning may interleave them across waves but they ship as one architectural unit.
</phase_requirements>

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` does not exist in this repository. No project-level overrides.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `jcs` | 0.2.0 | RFC 8785 JSON Canonicalization Scheme | The only pure-Elixir JCS implementation on Hex; published 2025-03-31; resolves Elixir map-iteration-order non-determinism. [VERIFIED: hex.pm/packages/jcs] |
| `jason` | 1.4.4 | JSON parsing of `authorization_details` (already wired in Phase 55) | Standard Elixir JSON library; **inadequate alone** for fingerprinting because map iteration order is undefined. [VERIFIED: mix.lock] |
| `ecto_sql` | 3.13.5 | Schemaless changesets for the canonical validator template; JSONB columns | Existing dep; supports `cast/4` schemaless via `{data, types}` tuple. [VERIFIED: mix.lock] |
| `:telemetry` | 1.3 | `:telemetry.span/3` for `[:lockspire, :rar, :validation, ...]` events | Existing dep; `:telemetry.span/3` is the canonical wrapper for `:start/:stop/:exception` triplets. [VERIFIED: mix.lock] |
| `:crypto` (OTP) | n/a | `:crypto.hash(:sha256, ...)` for fingerprint hash | Erlang stdlib. [VERIFIED] |

**Version verification:** Confirmed against hex.pm on 2026-05-06.
- `jcs` v0.2.0, published 2025-03-31, license Apache-2.0, publisher pzingg, requires Elixir 1.14+ / OTP 25+ for Ryu float_to_binary. Lockspire's `mix.exs` declares `elixir: "~> 1.18"` (line 11) so the OTP/Elixir floor is comfortably met. [VERIFIED: hex.pm/packages/jcs, hexdocs.pm/jcs/0.2.0]

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Logger` | OTP | `Logger.warning` for unknown-type rejections (D-21) | Already used throughout Lockspire. |
| `Ecto.Migration` | 3.13.5 | New migration for ConsentGrant + Token columns | Standard. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `jcs` Hex package | Hand-rolled recursive map-sort + Jason | More code, more tests, more drift risk. The jcs package is small (single dep), Apache-2.0, and authored against the RFC. Use it. [CITED: hex.pm/packages/jcs] |
| `jcs` Hex package | `stable_jason` v2.0.0 | StableJason is "deterministic JSON" but **not** RFC 8785 JCS — number encoding rules differ. Use jcs for spec compliance. [CITED: elixirforum.com StableJason thread] |
| Schemaless changeset (D-07 template) | `Ecto.Schema` `embedded_schema` | Embedded schemas are heavier; schemaless is the idiomatic Ecto pattern for "validate one inbound API object that never persists as a top-level row." Hosts can opt into embedded if they prefer. [CITED: hexdocs.pm/ecto/data-mapping-and-validation.html] |
| `:telemetry.span/3` for D-20 | Manual `:start` / `:stop` `:telemetry.execute/3` calls + try/rescue | `:telemetry.span/3` handles the duration measurement, exception metadata merge, and `:start/:stop/:exception` event-name suffixes correctly. Roll-your-own is bug-prone. [CITED: hexdocs.pm/telemetry/telemetry.html] |
| New `Lockspire.RAR.Dispatcher` module | Inline dispatch in `validate_authorization_details/2` | Keeps `AuthorizationRequest` from sprawling; isolates the seam-touching logic in one testable module. |

**Installation:**
```elixir
# In mix.exs deps/0
{:jcs, "~> 0.2"},
```
No new test-only deps required; `Application.put_env` + `on_exit` is the established Lockspire pattern for swapping host behaviours in tests (no Mox needed).

## Architecture Patterns

### System Architecture Diagram

```
                          /authorize OR /par request
                                     │
                                     ▼
                  ┌──────────────────────────────────────┐
                  │ AuthorizationRequest.validate/1      │  (existing — Phase 55)
                  │   ↓                                   │
                  │ validate_authorization_details/2     │  ← integration point (D-23)
                  │   1. shape check (existing)          │
                  │   2. length cap (existing)           │
                  │   3. NEW: dispatch each detail       │
                  └─────────────────┬────────────────────┘
                                    │
                                    ▼
                  ┌──────────────────────────────────────┐
                  │ Lockspire.RAR.Dispatcher             │  ← NEW module
                  │  ─ look up validator by type         │
                  │  ─ if missing: emit :unknown_type    │
                  │      → {:redirect_error, ...}        │
                  │  ─ if present: :telemetry.span/3     │
                  │      → validator.validate(detail,ctx)│
                  └─────────┬────────────┬───────────────┘
                            │            │
                  ┌─────────▼─────┐  ┌───▼──────────────┐
                  │  HOST APP     │  │ {:error, %CS{} \ │
                  │  RarType-     │  │   String}         │
                  │  Validator    │  │  → error_         │
                  │  impl         │  │  description/1    │
                  └─────────┬─────┘  └──────────────────┘
                            │
                            ▼
                  {:ok, normalized_detail :: map()}
                            │
                            ▼
                  Validated.authorization_details =
                    [normalized_1, normalized_2, ...]   ← stored downstream (D-08)
                            │
       ┌────────────────────┼─────────────────────┐
       ▼                    ▼                     ▼
  PAR persist          Interaction         Authorization-code
  (re-entry via        durable copy         issuance
  pushed_request_      (Phase 55 path,         │
   to_params           now stores                ▼
   re-validates)       validator output)   maybe_store_consent/3
                                                 │
                                                 ▼
                  ┌──────────────────────────────────────┐
                  │ ConsentGrant (NEW columns)           │
                  │  authorization_details (jsonb[])     │
                  │  authorization_details_fingerprint   │
                  │      (bytea, 32 bytes)               │
                  │  ← Lockspire.RAR.Fingerprint.compute │
                  └─────────┬────────────────────────────┘
                            │
                            ▼
                  ┌──────────────────────────────────────┐
                  │ Token rows (NEW column)              │
                  │  consent_grant_id  →  consent_grants │
                  │      (FK, on_delete: :nilify_all)    │
                  │  Set on issue_authorization_code/3   │
                  │  Propagated by RefreshExchange       │
                  │  (mirrors family_id)                 │
                  └──────────────────────────────────────┘

                  Reuse-policy lookup (existing flow, NEW key):
                    list_reusable_consents(account, client)
                    + ConsentPolicy.reusable_grant(grants, scopes,
                                                    prompt, fingerprint)
                          ↓ partial index hit
                    consent_grants_reuse_idx
                    (account_id, client_id, fingerprint)
                    WHERE status = 'active'
```

### Component Responsibilities

| File | Type | Responsibility |
|------|------|----------------|
| `lib/lockspire/host/rar_type_validator.ex` | NEW | Public `@behaviour` — `validate(detail, ctx) :: {:ok, map()} \| {:error, Changeset.t() \| String.t()}` |
| `lib/lockspire/rar/dispatcher.ex` | NEW | Internal: lookup → telemetry-span → validator call → normalize result. Single entrypoint. |
| `lib/lockspire/rar/fingerprint.ex` | NEW | `compute(authorization_details :: [map()]) :: binary()` — JCS canonicalization + SHA-256. |
| `lib/lockspire/rar.ex` | NEW | Public helper: `error_description(Ecto.Changeset.t() \| String.t()) :: String.t()` |
| `lib/lockspire/host/permissive_rar_validator.ex` | NEW (planning's call) | Default impl for tests / ergonomic stubs. Returns `{:ok, detail}`. |
| `lib/lockspire/config.ex` | EXTEND | Add `rar_validators/0` (default `%{}`) and `rar_types_supported/0` (sorted keys). |
| `lib/lockspire/protocol/authorization_request.ex` | EXTEND | `validate_authorization_details/2` calls Dispatcher; `Validated.authorization_details` now holds normalized output (no struct shape change). |
| `lib/lockspire/protocol/authorization_flow.ex` | EXTEND | `maybe_store_consent/3` populates `authorization_details` + fingerprint; `issue_authorization_code/3` sets `consent_grant_id` on Token. |
| `lib/lockspire/protocol/refresh_exchange.ex` | EXTEND | `build_rotated_access_token/4` and `build_rotated_refresh_token/4` carry `consent_grant_id` like `family_id`. |
| `lib/lockspire/protocol/consent_policy.ex` | EXTEND | `reusable_grant/4` (or `/3` with keyword) accepts fingerprint; reuse requires fingerprint match. |
| `lib/lockspire/domain/consent_grant.ex` | EXTEND | New struct fields: `:authorization_details`, `:authorization_details_fingerprint`. |
| `lib/lockspire/domain/token.ex` | EXTEND | New struct field: `:consent_grant_id`. |
| `lib/lockspire/storage/ecto/consent_grant_record.ex` | EXTEND | Schema field, cast list, `to_domain/1` projection. |
| `lib/lockspire/storage/ecto/token_record.ex` | EXTEND | Schema field, cast list, `to_domain/1` projection. |
| `lib/lockspire/storage/ecto/repository.ex` | EXTEND | `list_reusable_consents/2` filter (or new `/3`) accepts fingerprint key; rotation paths preserve `consent_grant_id`. |
| `priv/repo/migrations/<ts>_add_rar_durable_storage.exs` | NEW | Adds `consent_grants.authorization_details {:array, :map} default []`, `consent_grants.authorization_details_fingerprint :binary`, `tokens.consent_grant_id :integer`, FK constraint, partial index, plain index. |

### Pattern 1: Host-seam mirror (`Lockspire.Host.TokenExchangeValidator` template)

**What:** Single behaviour module, runtime registration via `Application.get_env`, default impl shipped alongside, accessor on `Lockspire.Config`. No macros, no compile-time auto-registration.

**When to use:** Always for host extensions. This is Lockspire's discipline (see `.planning/PROJECT.md` "host-seam discipline" constraint).

**Verified template — `Lockspire.Host.TokenExchangeValidator`:**
```elixir
# lib/lockspire/host/token_exchange_validator.ex (verbatim from codebase)
defmodule Lockspire.Host.TokenExchangeValidator do
  @moduledoc "Behaviour for validating token exchange requests..."
  alias Lockspire.Host.TokenExchangeContext

  @callback validate(context :: TokenExchangeContext.t()) ::
              :ok | {:ok, %{claims: map()}} | {:error, term()}
end
```

**Companion default impl** (`lib/lockspire/host/default_delegation_validator.ex`):
```elixir
defmodule Lockspire.Host.DefaultDelegationValidator do
  @behaviour Lockspire.Host.TokenExchangeValidator
  alias Lockspire.Host.TokenExchangeContext

  @impl true
  def validate(%TokenExchangeContext{actor_token: nil}), do: :ok
  # ... handles act-claim shaping ...
end
```

**Companion accessor on `Lockspire.Config`** (lines 37-44):
```elixir
@spec token_exchange_validator() :: module()
def token_exchange_validator do
  Application.get_env(
    :lockspire,
    :token_exchange_validator,
    Lockspire.Host.DefaultDelegationValidator
  )
end
```

**Companion call site** (`lib/lockspire/protocol/rfc8693_exchange.ex:267-271`):
```elixir
defp token_exchange_validator(request) do
  request
  |> Map.get(:opts, [])
  |> Keyword.get_lazy(:token_exchange_validator, fn -> Config.token_exchange_validator() end)
end
```

**Phase 56 application** — replicate the exact shape:
```elixir
# lib/lockspire/host/rar_type_validator.ex (NEW)
defmodule Lockspire.Host.RarTypeValidator do
  @moduledoc """
  Behaviour for validating a single Rich Authorization Request detail object
  for one specific `type` value.
  """

  @callback validate(detail :: map(), ctx :: map()) ::
              {:ok, map()} | {:error, Ecto.Changeset.t() | String.t()}
end
```

```elixir
# lib/lockspire/config.ex (EXTEND)
@spec rar_validators() :: %{String.t() => module()}
def rar_validators do
  Application.get_env(:lockspire, :rar_validators, %{})
end

@spec rar_types_supported() :: [String.t()]
def rar_types_supported do
  rar_validators() |> Map.keys() |> Enum.sort()
end
```

### Pattern 2: Schemaless changeset for inbound payload validation (D-07 template)

**What:** Use `Ecto.Changeset.cast({data, types}, params, allowed_keys)` for one-shot validation of inbound JSON objects without an associated schema row.

**When to use:** Validating request-shape data that never persists as a top-level Ecto row. RFC 9396 details are exactly this — they live inside the `consent_grants.authorization_details` JSONB array, not as their own table. [CITED: hexdocs.pm/ecto/data-mapping-and-validation.html]

**Canonical generated body for `mix lockspire.gen.rar_validator payment_initiation`:**
```elixir
# Example host validator — what a generated template emits
defmodule MyApp.RAR.PaymentInitiation do
  @behaviour Lockspire.Host.RarTypeValidator

  import Ecto.Changeset

  @types %{
    type: :string,
    actions: {:array, :string},
    locations: {:array, :string},
    instructed_amount: :map,  # nested object — see D-17 fingerprint note
    creditor_name: :string,
    creditor_account: :map,
    remittance_information: {:array, :string}
  }
  @required ~w(type actions instructed_amount creditor_name)a
  @allowed_actions ~w(initiate maintain)

  @impl true
  def validate(detail, _ctx) when is_map(detail) do
    {%{}, @types}
    |> cast(detail, Map.keys(@types))
    |> validate_required(@required)
    |> validate_inclusion(:type, ["payment_initiation"])
    |> validate_subset(:actions, @allowed_actions)
    |> validate_instructed_amount()
    |> case do
      %Ecto.Changeset{valid?: true} = cs -> {:ok, apply_changes(cs)}
      %Ecto.Changeset{} = cs -> {:error, cs}
    end
  end

  defp validate_instructed_amount(cs) do
    case get_change(cs, :instructed_amount) do
      %{"amount" => amount, "currency" => ccy}
      when is_binary(amount) and is_binary(ccy) -> cs
      nil -> cs
      _other -> add_error(cs, :instructed_amount, "must include amount and currency")
    end
  end
end
```

**Why this shape:**
- `apply_changes/1` returns a clean `map()` whose keys are exactly the casted ones — unknown fields are dropped (D-08 enforcement is automatic).
- Casting through `:map` for nested objects keeps the host honest: explicit nested validation, not blind passthrough.
- The error path returns the changeset directly; `Lockspire.RAR.error_description/1` formats it via `traverse_errors/2`.

### Pattern 3: `:telemetry.span/3` wrapper for D-20

**What:** Wrap the `validator.validate(detail, ctx)` call with `:telemetry.span/3` so `:start`, `:stop`, and `:exception` events are emitted with consistent measurements (`:duration` from `monotonic_time`) and metadata.

**When to use:** Whenever you wrap a host-callback boundary. [CITED: hexdocs.pm/telemetry/telemetry.html]

**Canonical span pattern:**
```elixir
# Inside Lockspire.RAR.Dispatcher
defp span_validate(validator, type, detail, ctx) do
  start_metadata = %{type: type, client_id: ctx[:client_id]}

  :telemetry.span(
    [:lockspire, :rar, :validation],
    start_metadata,
    fn ->
      result = validator.validate(detail, ctx)
      stop_metadata = Map.put(start_metadata, :outcome, outcome_atom(result))
      {result, stop_metadata}
    end
  )
end

defp outcome_atom({:ok, _}), do: :ok
defp outcome_atom({:error, _}), do: :error
```

**Important:** `:telemetry.span/3` automatically merges `start_metadata` into `:exception` events when the wrapped function raises. Do **not** wrap in your own try/rescue — let the host validator's exception bubble through `span/3`'s exception handling, then convert it to `{:redirect_error, ...}` at a higher layer (otherwise you lose the span exception event).

### Pattern 4: Domain → Record → Store extension (no new triple)

**What:** Extend the existing `Lockspire.Domain.ConsentGrant` / `ConsentGrantRecord` triple rather than introduce a new `AuthorizationGrant`. Same for `Token` / `TokenRecord`.

**Why:** Phase 55-VERIFICATION.md and CONTEXT.md D-13 explicitly call out that `ConsentGrant` already plays the durable-consent role. Adding a parallel `AuthorizationGrant` would duplicate state and force two-row writes.

### Pattern 5: FK propagation through token rotations (mirror `family_id`)

**What:** Once a Token row carries `consent_grant_id` on the authorization-code → access-token → refresh-token → rotated-refresh-token chain, refresh exchange just copies the FK forward at rotation time, exactly the way `family_id` is carried. Verified template at `lib/lockspire/protocol/refresh_exchange.ex:296-327` (the `build_rotated_access_token/6` and `build_rotated_refresh_token/5` helpers).

**Verified template — current `build_rotated_access_token/6`:**
```elixir
defp build_rotated_access_token(
       %Client{} = client,
       formatted_access_token,
       rotated_at,
       context,
       %Token{} = source_token,
       requested_resources
     ) do
  %Token{
    token_hash: formatted_access_token.token_hash,
    token_type: :access_token,
    client_id: client.client_id,
    account_id: nil,
    sid: source_token.sid,
    audience: requested_resources,
    cnf: context.cnf,
    expires_at: DateTime.add(rotated_at, @access_token_ttl, :second)
  }
end
```

**Phase 56 extension** — single new line:
```elixir
%Token{
  ...,
  sid: source_token.sid,
  consent_grant_id: source_token.consent_grant_id,  # NEW — carries forward
  audience: requested_resources,
  ...
}
```

`family_id` is **not** passed in the struct here because the storage layer derives it from `parent_token_id` via `store_rotated_*` helpers — repository.ex:1820-1844. `consent_grant_id`, by contrast, is set on the **domain struct** at rotation time because the storage layer does not derive it. Planning should mirror the explicit-pass approach.

### Anti-Patterns to Avoid

- **`Jason.encode!/1` directly for fingerprinting.** Elixir map iteration order is explicitly undefined post-1.14 ("Different functions that take maps can also iterate over the map in different orders!"). Two structurally-identical RAR payloads can produce different JSON byte sequences → different SHA-256 hashes → spurious re-consent prompts. [CITED: jonathanychan.com, github.com/michalmuskala/jason#69] Use `jcs` Hex package.
- **`String.to_atom/1` on RAR `type` values.** Atoms are not garbage-collected; allowing user input to mint atoms is a DoS vector. Always keep `type` as a binary string when used as a map key.
- **`embedded_schema` for D-07 generator template.** It works, but it's heavier than schemaless and obscures the "this never persists as a top-level row" intent. Schemaless is the Ecto-recommended idiom for inbound API validation. [CITED: elixirfocus.com schemaless changesets]
- **Wrapping `:telemetry.span/3` in your own try/rescue.** Drops `:exception` events and breaks the contract. Let exceptions bubble through `span/3`.
- **`on_delete: :delete_all` on `tokens.consent_grant_id`.** D-14 specifies `:nilify_all`. A revoked ConsentGrant must leave token rows so revocation/audit history survives (Doorkeeper's rationale: don't silently delete audit-trail data on parent deletion).
- **Per-detail `apply_changes` without `:valid?` check.** `apply_changes/1` returns the *applied* changeset data even on invalid changesets. Always pattern-match on `%Ecto.Changeset{valid?: true}` first, otherwise you'll silently store invalid normalized output.
- **Hand-rolled `traverse_errors/2` formatter.** Lockspire ships `Lockspire.RAR.error_description/1` (D-06). Use it; don't duplicate.
- **Macro-based / compile-time validator registration.** Explicitly forbidden by D-02. Lockspire's host-seam discipline is runtime-config only.
- **Mutating Phase 55's `Interaction.authorization_details` semantics.** D-15 says it stays. Two columns, two concepts. Do not collapse them.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| RFC 8785 JCS canonicalization | Recursive map sort + Jason + custom number formatter | `jcs` Hex package v0.2.0 | RFC 8785 number rules (Ryu float, exponent normalization, `-0` handling) are subtle. The `jcs` package is purpose-built and 1 dep. [CITED: hex.pm/packages/jcs] |
| Inbound RAR payload validation | Bespoke `Map.fetch/2` + `is_binary/1` chains | `Ecto.Changeset` schemaless via `cast/4` | Type coercion, `validate_required`, `validate_format`, `validate_inclusion`, error formatting are all built-in. [CITED: hexdocs.pm/ecto/data-mapping-and-validation.html] |
| Telemetry span wrapping | Manual `:telemetry.execute` with try/rescue | `:telemetry.span/3` | Handles duration, exception metadata, event-name suffixing per the OTel-aligned spec. [CITED: hexdocs.pm/telemetry/telemetry.html] |
| Changeset error formatting | Ad-hoc string interpolation | `Ecto.Changeset.traverse_errors/2` (inside `Lockspire.RAR.error_description/1`) | Handles interpolation tokens (`%{count}` etc.) and nested errors. |
| Host-validator behaviour boilerplate | New macro / `use` mechanism | Plain `@behaviour` + `Application.get_env` | Already the Lockspire convention; consistency wins. |
| Test-time validator swap | Mox / Meck | `Application.put_env` + `on_exit` | Established Lockspire pattern; no new test deps needed. [CITED: phase48 integration test, line 21] |

**Key insight:** Every "hand-roll" temptation in this phase has a 1-dep or stdlib answer. The behaviour pattern is already in the codebase three times over (`AccountResolver`, `BackchannelNotification`, `TokenExchangeValidator`). Replicate it.

## Runtime State Inventory

> Phase 56 is a feature-add, not a rename/refactor. There is no installed-base of Phase-56-shaped data in production (CONTEXT.md D-09: "Lockspire is pre-1.0 (`0.2.0` in `mix.exs`), Phase 55 shipped today (2026-05-06), there's no installed base"). However, Phase 55 *did* ship today, which means Phase 55's existing `Interaction.authorization_details` rows already exist in any test/staging databases that have had Phase 55 traffic. Most of those rows are empty arrays — but planning must handle the case where a Phase-55-era integration test created Interaction rows with non-empty raw RAR.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Phase 55's `lockspire_pushed_authorization_requests.authorization_details` and `lockspire_interactions.authorization_details` JSONB arrays — populated by Phase 55 storage path with **raw decoded JSON** (not validator output). After Phase 56, the contract is "validator output." Existing Phase 55 rows will still hold raw input until they expire (PAR TTL ~60s, Interaction TTL ~5min). No backfill needed because both are short-lived; new rows after deploy will hold validator output. | Document in MIGRATION_NOTES section of phase summary that a deploy boundary exists; in-flight PAR/Interaction rows will round-trip raw JSON if a client used Phase 55 before deploy and consumed after. Acceptable because the worst case is one extra round-trip. No data migration script needed. |
| Live service config | None — Lockspire is a library, not a deployed service. Host apps will pick up the new `:rar_validators` config when they upgrade, with default `%{}` ⇒ strict-reject of any RAR (intentional secure-by-default). | None. Document in CHANGELOG that a host upgrading from Phase 55 to Phase 56 must set `:rar_validators` if they were sending RAR. |
| OS-registered state | None — Lockspire is a library. | None. |
| Secrets/env vars | None — no new secret material. | None. |
| Build artifacts | None — no installed-package state outside `mix deps.compile`. Adding `{:jcs, "~> 0.2"}` to `mix.exs` will require host apps to re-run `mix deps.get`. | Document in CHANGELOG. |

**Nothing found in category:** Stated explicitly above.

## Common Pitfalls

### Pitfall 1: Non-deterministic JSON encoding for fingerprint

**What goes wrong:** `Jason.encode!(%{"a" => 1, "b" => 2})` and `Jason.encode!(%{"b" => 2, "a" => 1})` produce different byte sequences depending on map iteration order. Two semantically-equal RAR sets hash to different values. Reuse-policy fails to match a returning user with the same RAR. User sees a re-consent prompt. Worst case: every refresh-token rotation triggers re-consent because the fingerprint flips between runs.
**Why it happens:** Elixir map iteration order is explicitly undefined since Elixir 1.14 — and is undefined per-call, not just per-process. [CITED: jonathanychan.com elixir-map-iteration-order]
**How to avoid:** Use the `jcs` Hex package (v0.2.0). It implements RFC 8785 deterministically: recursive map-key sort by UTF-16 code points, deterministic list ordering preserved, normalized number encoding via Ryu float-to-binary.
**Warning signs:** Property-based test on `Fingerprint.compute/1` that randomizes input map construction order should produce a constant hash. If the test fails ~50% of the time on small inputs, you've hand-rolled the canonicalization wrong.

### Pitfall 2: Validator output not stored, raw input persisted instead

**What goes wrong:** Phase 55's storage path writes `validated.authorization_details` to ConsentGrant — but `validated.authorization_details` is the *raw* decoded list. Unknown fields leak through. Phase 57 introspection eventually exposes them. Security-by-omission failure.
**Why it happens:** D-08 is a behavior change from Phase 55. The temptation is to wire the new dispatch into the validation path but forget that the **same field** must now hold normalized output everywhere downstream (PAR record, Interaction record, ConsentGrant, every test fixture).
**How to avoid:** After Dispatcher returns `{:ok, normalized_list}`, replace `Validated.authorization_details` with `normalized_list` *inside* `validate_authorization_details/2`. Then every downstream copy (`pushed_authorization_request.ex:113`, `authorization_flow.ex:260`, the new `maybe_store_consent/3` extension) automatically writes the normalized form.
**Warning signs:** A property test asserting `validator.validate(input).{:ok, output}` and `output != input` (i.e., normalization actually transformed something — e.g., a number coerced from string "100" to integer 100) followed by a downstream assertion `consent_grant.authorization_details == [output]` (not `[input]`).

### Pitfall 3: PAR re-validation double-runs the dispatcher

**What goes wrong:** `pushed_request_to_params/1` (authorization_request.ex:723) re-feeds `request.authorization_details` (which is **already** the normalized output, persisted by Phase 55's PAR path which Phase 56 retrofits) back through `validate_with_client/3` which calls `validate_authorization_details/2` which now calls Dispatcher again. Validator runs twice. If the validator is deterministic and idempotent on its own output: no harm except wasted CPU + double telemetry events. If not (e.g., timestamps, random IDs, server-time stamps): different normalized output the second time → fingerprint drift → spurious re-consent.
**Why it happens:** This is Phase 55's WR-04 "pushed_request_to_params re-validation coupling" deferred item, now in scope. Phase 55 gets away with it because today validation is shape-only (idempotent). Phase 56 introduces stateful validation.
**How to avoid:** Two viable approaches; planning should pick:
1. **Bypass on PAR consume:** Add a flag (e.g., `pre_validated?: true`) to the dispatcher, set when entering through the PAR-consume path. Validator is not called. Trust the persisted PAR row.
2. **Idempotency contract:** Document that `validator.validate(validator.validate(detail, ctx).output, ctx) == validator.validate(detail, ctx)` (validators must be idempotent on their own normalized output). Cheap to enforce in tests. Lets the simple double-call stand.
Recommendation: option 1. PAR was already the trusted-pre-validated state for Phase 55; making that explicit beats trusting host-impl idempotency.
**Warning signs:** Integration test where the validator deliberately differs on second call (e.g., adds `"validated_at" => DateTime.utc_now()`) — the PAR consume path should produce the **same** Interaction RAR the PAR push did, byte-for-byte.

### Pitfall 4: `consent_grant_id` not set on first access token after issuance

**What goes wrong:** `issue_authorization_code/3` (authorization_flow.ex:283) stores the authorization code. Later, the token endpoint exchanges the code for an access+refresh pair via `Lockspire.Protocol.AuthorizationCodeExchange` (or whatever the equivalent module is called) — and that exchange path doesn't carry `consent_grant_id` from the auth code to the access/refresh tokens. Now the first access/refresh pair has `consent_grant_id = nil`, but rotated refresh tokens (later) might pick it up correctly. The reuse-policy works, but tokens issued at the boundary are unbound from their grant. Phase 57 introspection joins return null.
**Why it happens:** Three-way wiring: code → exchange → access/refresh + ConsentGrant → code → access/refresh. It's easy to wire ConsentGrant → code (in `maybe_store_consent`) and refresh-rotation forward propagation, while missing the code → first access/refresh boundary.
**How to avoid:** Put `consent_grant_id` on the `Token` row when the authorization code is issued (extend `issue_authorization_code/3`). At code redemption, read it off the auth-code Token row and copy it onto the new access + refresh Token rows. Plan the four data-flow checkpoints explicitly: (1) ConsentGrant insert → has FK; (2) auth-code Token insert → has FK; (3) access+refresh issuance from code → has FK; (4) refresh rotation → has FK.
**Warning signs:** Integration test that issues a fresh end-to-end auth flow, redeems the code, checks `access_token.consent_grant_id != nil`, then refresh-rotates twice and confirms each rotation still has the same `consent_grant_id`.

### Pitfall 5: Strict-reject error_description leaks the validator inventory

**What goes wrong:** A naive `error_description` says "no validator registered for type 'sigra_internal'" at the redirect surface. Now an unauthenticated probe can enumerate which `type` values are/aren't supported by the host, and infer the host's validator inventory.
**Why it happens:** Default helpfulness — telling the integrator what went wrong is the developer-friendly choice. But the redirect surface is unauthenticated.
**How to avoid:** D-11 — generic `error_description = "authorization_details type is not supported"` at the redirect. Offending type goes into telemetry + structured logs (`Logger.warning` with `type:` field, D-21) for operator visibility. At the token endpoint (post-client-auth), the type name **may** be included in the JSON error body — planning's call.
**Warning signs:** A grep test asserting that no error message at the `/authorize` redirect surface contains the literal string of any registered RAR type.

### Pitfall 6: Empty-array `authorization_details: []` slips through validation

**What goes wrong:** RFC 9396 §2 says the array MUST contain at least one element. Phase 55 accepts `[]` because `Enum.all?([], &is_map/1) == true` (verified at authorization_request.ex:615-621). Phase 56's dispatcher only iterates the array — empty array means no validators run, no errors, but no RAR was actually granted.
**Why it happens:** This is Phase 55's WR-03 deferred item, now in scope (per phase requirements). The shape-check function is permissive on the empty case; the dispatcher inherits the permissiveness.
**How to avoid:** Add an explicit `[]` check before dispatch in `validate_authorization_details/2` (or in the dispatcher), returning `{:redirect_error, :invalid_authorization_details, "authorization_details must contain at least one element", :empty_authorization_details}`.
**Warning signs:** Unit test that posts `authorization_details: "[]"` to `/authorize` and asserts a redirect with `error=invalid_authorization_details`.

### Pitfall 7: Large-payload DoS via deeply-nested validators

**What goes wrong:** A malicious client posts a 2047-byte (under the cap) `authorization_details` containing 100 entries each with deeply-nested objects. Validator recursion blows the stack or burns CPU. Per-host validators are arbitrary code; they can be slow.
**Why it happens:** Phase 55's 2048-byte cap was sized for "single reasonable RAR detail" but doesn't bound iteration cost.
**How to avoid:** (a) Optionally apply a per-detail size budget inside the dispatcher (CONTEXT.md "Claude's Discretion"). (b) Wrap each validator call in `:telemetry.span/3`, then attach a slow-validator alert in monitoring (`duration > 100ms` on the `:lockspire, :rar, :validation, :stop` event). (c) Document host-side responsibility: validators MUST bound their own recursion depth.
**Warning signs:** Property test with deeply-nested input (depth 50+) — validator should reject with a bounded error, not crash the BEAM scheduler.

### Pitfall 8: Test-time `Application.put_env` leaks across async tests

**What goes wrong:** A test sets `Application.put_env(:lockspire, :rar_validators, %{...})`. Another async test on the same node reads that env. Test pollution; non-deterministic failures.
**Why it happens:** `Application.env` is process-wide. ExUnit's `async: true` runs tests concurrently, so env changes propagate.
**How to avoid:** Use `async: false` for any test that mutates `:rar_validators` at runtime, paired with `setup` block that captures the prior value and `on_exit` restores it. This is the established Lockspire pattern (verified at `test/integration/phase48_token_exchange_e2e_test.exs:16-23` and `test/integration/phase55_rar_intake_e2e_test.exs:44-61`). [CITED: elixirforum.com Application.put_env in tests]
**Warning signs:** A "normal" test failing only when run alongside the new RAR tests — classic env-leak signature.

## Code Examples

### Example 1: `Lockspire.Host.RarTypeValidator` behaviour

```elixir
# lib/lockspire/host/rar_type_validator.ex
# Mirrors lib/lockspire/host/token_exchange_validator.ex verbatim.
defmodule Lockspire.Host.RarTypeValidator do
  @moduledoc """
  Behaviour for validating a single Rich Authorization Request detail object
  for one specific `type` value.

  Hosts register validators via:

      config :lockspire, :rar_validators, %{
        "payment_initiation" => MyApp.RAR.PaymentInitiation,
        "account_information" => MyApp.RAR.AccountInformation
      }

  See `Lockspire.RAR` for the canonical error-formatting helper.
  """

  @callback validate(detail :: map(), ctx :: map()) ::
              {:ok, map()} | {:error, Ecto.Changeset.t() | String.t()}
end
```

### Example 2: `Lockspire.RAR.Dispatcher` (working-name)

```elixir
# lib/lockspire/rar/dispatcher.ex
defmodule Lockspire.RAR.Dispatcher do
  @moduledoc false
  # Internal — not part of the public host-facing API.
  # Single entrypoint called from
  # Lockspire.Protocol.AuthorizationRequest.validate_authorization_details/2.

  alias Lockspire.Config
  alias Lockspire.Observability

  require Logger

  @typep ctx :: %{
           required(:client_id) => String.t(),
           optional(:account_id) => String.t() | nil,
           optional(:scopes_requested) => [String.t()],
           optional(:resources_requested) => [String.t()],
           optional(:request) => map()
         }

  @spec dispatch_each([map()], ctx()) :: {:ok, [map()]} | {:error, atom(), String.t(), map()}
  def dispatch_each(details, ctx) when is_list(details) and is_map(ctx) do
    do_dispatch_each(details, ctx, [])
  end

  defp do_dispatch_each([], _ctx, acc), do: {:ok, Enum.reverse(acc)}

  defp do_dispatch_each([detail | rest], ctx, acc) when is_map(detail) do
    case dispatch_one(detail, ctx) do
      {:ok, normalized} -> do_dispatch_each(rest, ctx, [normalized | acc])
      {:error, _, _, _} = err -> err
    end
  end

  defp dispatch_one(%{"type" => type} = detail, ctx) when is_binary(type) do
    case Map.fetch(Config.rar_validators(), type) do
      {:ok, validator} ->
        run_validator(validator, type, detail, ctx)

      :error ->
        emit_unknown(type, ctx)
        {:error, :invalid_authorization_details,
         "authorization_details type is not supported", %{type: type}}
    end
  end

  defp dispatch_one(_detail, _ctx) do
    {:error, :invalid_authorization_details,
     "authorization_details entries must include a string `type`", %{}}
  end

  defp run_validator(validator, type, detail, ctx) do
    start_metadata = %{type: type, client_id: Map.get(ctx, :client_id)}

    :telemetry.span(
      [:lockspire, :rar, :validation],
      start_metadata,
      fn ->
        case validator.validate(detail, ctx) do
          {:ok, normalized} when is_map(normalized) ->
            {{:ok, normalized}, Map.put(start_metadata, :outcome, :ok)}

          {:error, %Ecto.Changeset{} = cs} ->
            description = Lockspire.RAR.error_description(cs)
            result = {:error, :invalid_authorization_details, description, %{type: type}}
            {result, Map.put(start_metadata, :outcome, :error)}

          {:error, description} when is_binary(description) ->
            result = {:error, :invalid_authorization_details, description, %{type: type}}
            {result, Map.put(start_metadata, :outcome, :error)}
        end
      end
    )
  end

  defp emit_unknown(type, ctx) do
    Logger.warning("RAR validator missing for type",
      type: type,
      client_id: Map.get(ctx, :client_id)
    )

    Observability.emit(:rar, :unknown_type, %{count: 1}, %{
      type: type,
      client_id: Map.get(ctx, :client_id)
    })
  end
end
```

**Note on the unknown-type telemetry event:** The base `Observability.emit/4` helper publishes under `[:lockspire, :rar, :unknown_type]` (D-20). For the `[:lockspire, :rar, :validation, :start|:stop|:exception]` triplet, `:telemetry.span/3` emits directly because `Observability.emit/4` doesn't take a 3-element event-name path. Planning should consider whether to extend `Observability` with a span helper or call `:telemetry.span/3` directly inside the dispatcher (recommended — keep `Observability.emit/4` 2-element-name-only).

### Example 3: `Lockspire.RAR.Fingerprint`

```elixir
# lib/lockspire/rar/fingerprint.ex
defmodule Lockspire.RAR.Fingerprint do
  @moduledoc """
  RFC 8785 JCS canonicalization + SHA-256 hashing of normalized
  authorization_details, used for ConsentGrant reuse-policy lookup.
  """

  @doc """
  Computes a 32-byte SHA-256 fingerprint of the JCS canonicalization of the
  given `authorization_details` list.

  Returns `nil` for an empty list (RAR absent ⇒ no fingerprint binding).
  """
  @spec compute([map()]) :: binary() | nil
  def compute([]), do: nil

  def compute(authorization_details) when is_list(authorization_details) do
    authorization_details
    |> Jcs.encode()
    |> then(&:crypto.hash(:sha256, &1))
  end
end
```

**Property-test scaffold (planning input):**
```elixir
# test/lockspire/rar/fingerprint_property_test.exs (Wave 0 — see Validation Architecture)
property "fingerprint is invariant under map-key construction order" do
  check all keys <- list_of(string(:alphanumeric, min_length: 1, max_length: 8), min_length: 1, max_length: 8) |> nonempty(),
            values <- list_of(integer(), length: length(keys)) do
    pairs = Enum.zip(keys, values)
    a = pairs |> Enum.shuffle() |> Map.new() |> then(&[Map.put(&1, "type", "test")])
    b = pairs |> Enum.shuffle() |> Map.new() |> then(&[Map.put(&1, "type", "test")])
    assert Lockspire.RAR.Fingerprint.compute(a) == Lockspire.RAR.Fingerprint.compute(b)
  end
end
```

**Note on `:erlang.float_to_binary/2` OTP-version sensitivity:** the `jcs` package documentation [CITED: hexdocs.pm/jcs/0.2.0/Jcs.html] flags that float encoding "seems to have differing results depending on the OTP release." Lockspire pins OTP via the Elixir floor (`~> 1.18` ⇒ OTP 25+); CI must run on a single OTP version per environment to avoid hash drift between dev and prod. Document this in the phase summary.

### Example 4: `Lockspire.RAR.error_description/1`

```elixir
# lib/lockspire/rar.ex
defmodule Lockspire.RAR do
  @moduledoc """
  Public helpers for host RAR validator implementations.
  """

  @doc """
  Formats an `Ecto.Changeset` validation error into a single
  RFC 9396 §6-compliant `error_description` string.

  Strings are passed through unchanged.

  ## Examples

      iex> cs = {%{}, %{name: :string}}
      ...>      |> Ecto.Changeset.cast(%{}, [:name])
      ...>      |> Ecto.Changeset.validate_required([:name])
      iex> Lockspire.RAR.error_description(cs)
      "name: can't be blank"

      iex> Lockspire.RAR.error_description("custom message")
      "custom message"
  """
  @spec error_description(Ecto.Changeset.t() | String.t()) :: String.t()
  def error_description(%Ecto.Changeset{} = cs) do
    cs
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end

  def error_description(description) when is_binary(description), do: description
end
```

### Example 5: Migration

```elixir
# priv/repo/migrations/<timestamp>_add_rar_durable_storage.exs
defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddRarDurableStorage do
  use Ecto.Migration

  def change do
    alter table(:lockspire_consent_grants) do
      add(:authorization_details, {:array, :map}, default: [])
      add(:authorization_details_fingerprint, :binary)
    end

    alter table(:lockspire_tokens) do
      add(:consent_grant_id, references(:lockspire_consent_grants, on_delete: :nilify_all))
    end

    create_if_not_exists(
      index(:lockspire_consent_grants, [:account_id, :client_id, :authorization_details_fingerprint],
        name: :consent_grants_reuse_idx,
        where: "status = 'active'"
      )
    )

    create_if_not_exists(index(:lockspire_tokens, [:consent_grant_id]))
  end
end
```

**Notes:**
- `references/2` with `on_delete: :nilify_all` produces Postgres `ON DELETE SET NULL` — verified D-14 mapping.
- The partial index uses `where: "status = 'active'"` (string literal, Postgres-evaluated). Ecto's `create index` `:where` option accepts a raw SQL string. Verify in dev: `\d+ lockspire_consent_grants` shows the partial index correctly.
- `{:array, :map}` resolves to JSONB[] in Postgres (Ecto 3.x default for `:map`). Same idiom as Phase 55's `interactions.authorization_details` — verified at `priv/repo/migrations/20260506020000_add_rar_intake_state.exs`.
- Default for `:authorization_details` is `[]` to match Phase 55's `Validated.authorization_details` default and avoid `nil` checks downstream.
- No default for `:authorization_details_fingerprint` — `nil` semantically means "no RAR" (matches `Fingerprint.compute([])` returning `nil`).
- No default for `:consent_grant_id` on tokens — `nil` semantically means "no consent grant association" (e.g., client-credentials tokens, or pre-Phase-56 tokens during the deploy window).

### Example 6: ConsentPolicy fingerprint extension

```elixir
# lib/lockspire/protocol/consent_policy.ex (EXTEND)
@spec reusable_grant([ConsentGrant.t()], [String.t()], [String.t()], binary() | nil) ::
        {:reuse, ConsentGrant.t()} | :consent_required
def reusable_grant(grants, requested_scopes, prompt, fingerprint)
    when is_list(grants) and is_list(requested_scopes) and is_list(prompt) do
  if "consent" in prompt do
    :consent_required
  else
    requested = MapSet.new(requested_scopes)

    case Enum.find(grants, &reusable_grant?(&1, requested, fingerprint)) do
      nil -> :consent_required
      grant -> {:reuse, grant}
    end
  end
end

defp reusable_grant?(
       %ConsentGrant{
         status: :active,
         kind: :remembered,
         revoked_at: nil,
         scopes: granted_scopes,
         authorization_details_fingerprint: grant_fp
       },
       requested,
       requested_fp
     ) do
  MapSet.subset?(requested, MapSet.new(granted_scopes)) and grant_fp == requested_fp
end

defp reusable_grant?(_grant, _requested, _fp), do: false
```

**Note on the equality check `grant_fp == requested_fp`:** This handles the three cases correctly:
- Both `nil` (RAR-less request reusing RAR-less grant): match. ✓
- Both same binary (RAR request reusing matching RAR grant): match. ✓
- One `nil`, other set (RAR-less request, RAR grant — or vice versa): no match → re-consent. ✓
- Both set, different bytes: no match → re-consent. ✓

### Example 7: Test-time validator swap pattern

```elixir
# test/lockspire/rar/dispatcher_test.exs (illustrative)
defmodule Lockspire.RAR.DispatcherTest do
  use ExUnit.Case, async: false  # Application.put_env mutates global state

  defmodule FakePaymentValidator do
    @behaviour Lockspire.Host.RarTypeValidator
    @impl true
    def validate(%{"type" => "payment_initiation", "amount" => amount}, _ctx)
        when is_integer(amount) and amount > 0 do
      {:ok, %{"type" => "payment_initiation", "amount" => amount, "validated" => true}}
    end

    def validate(detail, _ctx) when is_map(detail) do
      {:error, "amount must be a positive integer"}
    end
  end

  setup do
    prior = Application.get_env(:lockspire, :rar_validators)
    Application.put_env(:lockspire, :rar_validators, %{"payment_initiation" => FakePaymentValidator})
    on_exit(fn ->
      if prior, do: Application.put_env(:lockspire, :rar_validators, prior),
                else: Application.delete_env(:lockspire, :rar_validators)
    end)
    :ok
  end

  # ... tests ...
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Embed full RAR in JWT access tokens | Reference RAR by `consent_grant_id` FK; bloat-free access tokens, full RAR via introspection | RFC 9396 §10 (introspection-first) + node-oidc-provider's `Grant` model design | Phase 56 stores by reference (D-13/D-14); Phase 57 exposes via introspection. [CITED: github.com/panva/node-oidc-provider features.richAuthorizationRequests] |
| Hand-rolled JSON canonicalization for hashing | RFC 8785 JCS via `jcs` Hex package | RFC 8785 published 2020; `jcs` Elixir port published 2025-03-31 | Avoids the `Jason.encode!/1` map-iteration-order footgun (the ory/fosite RAR draft trap referenced in D-17). [VERIFIED: hex.pm/packages/jcs] |
| `embedded_schema` for inbound API validation | Schemaless changesets (`{data, types}` tuple form) | Ecto 3.x guides | Less ceremony; explicit "this never persists as a top-level row" intent. [CITED: hexdocs.pm/ecto/data-mapping-and-validation.html] |
| Manual `:telemetry.execute/3` `:start`/`:stop` pairs | `:telemetry.span/3` (telemetry ≥ 1.0) | telemetry 1.0+ | Handles duration measurement, exception metadata merge, event-name suffixing. [CITED: hexdocs.pm/telemetry/telemetry.html] |

**Deprecated/outdated:**
- Treating `Jason.encode!/1` as canonical JSON: explicitly not canonical. Use `jcs`. [CITED: github.com/michalmuskala/jason#69]
- StableJason as a JCS substitute: similar but **not** RFC 8785. Use `jcs` for spec compliance. [CITED: hexdocs.pm/stable_jason/readme.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `jcs` Hex package v0.2.0 handles nested maps + nested lists correctly per RFC 8785 | Standard Stack, Pitfall 1 | If wrong, fingerprints drift on nested RAR details. **Mitigation:** Wave 0 includes a property test that builds a 3-level nested map with shuffled construction order and asserts hash invariance. [VERIFIED: hexdocs.pm/jcs/0.2.0 — "canonicalizes nested object entries and sorts them by their names"] |
| A2 | `:erlang.float_to_binary/2` produces identical output across OTP 25, 26, 27 | Pitfall 1, Code Examples §3 note | If wrong, hash drift between hosts running different OTP minor versions. **Mitigation:** Phase 56 should not allow floats in RAR data unless the host validator coerces to integers/strings first; document this in the validator template. The `jcs` package itself flags this OTP-version sensitivity. [CITED: hexdocs.pm/jcs/0.2.0/Jcs.html — "differing results depending on the OTP release"] |
| A3 | `references(..., on_delete: :nilify_all)` on Postgres produces `ON DELETE SET NULL` | Code Examples §5 | Ecto migration docs confirm this mapping; if wrong, FK semantics break. **Mitigation:** Verify with `\d+ lockspire_tokens` after migration. |
| A4 | `Application.put_env` + `on_exit` test pattern is stable for `:rar_validators` swap | Pitfall 8, Code Examples §7 | If wrong, tests pollute each other. **Mitigation:** `async: false` on every test that mutates the env (verified in existing Phase 55 integration test). |
| A5 | The exchange path that converts authorization-code → access+refresh tokens currently exists in a specific module that planning will identify and extend (Pitfall 4) | Pitfall 4 | I did not pinpoint the exact module name in research. **Mitigation:** First planning task is "audit auth-code redemption call site." Likely candidates: `Lockspire.Protocol.AuthorizationCodeExchange` or inside `Lockspire.Protocol.TokenExchange`. |
| A6 | The PAR re-validation coupling (Pitfall 3) is best resolved with a `pre_validated?` flag rather than an idempotency contract | Pitfall 3 | This is a planning-judgment call; CONTEXT.md leaves it open. **Mitigation:** Both options listed; planning picks. |
| A7 | The reuse-policy fingerprint key extension (D-16) should add a 4th positional arg to `reusable_grant/3`, not a keyword option | Code Examples §6 | Pure ergonomic call. CONTEXT.md says "by adding a 4th positional or keyword arg." Positional is simpler. **Mitigation:** Planning's call. |

**Risk-tier summary:** Two HIGH-risk assumptions (A1 nested-map JCS correctness, A2 OTP float stability) — both have Wave-0 property tests as mitigation. Other assumptions are LOW-risk planning judgment calls.

## Open Questions

1. **Should `[]` (empty `authorization_details` array) be rejected or accepted?**
   - What we know: RFC 9396 §2 says the array MUST contain at least one element. Phase 55 currently accepts `[]` (verified shape check at authorization_request.ex:615-621). Phase 55 verification flagged this (deferred item 3) and CONTEXT.md notes it ("becomes implicit in D-08 if validators reject empty input").
   - What's unclear: D-08 does **not** auto-reject `[]` because the dispatcher iterates the empty list and returns `{:ok, []}` without ever calling a validator. Empty-array rejection needs an explicit guard.
   - Recommendation: Add an explicit `[]` rejection in `validate_authorization_details/2` (returns `{:redirect_error, :invalid_authorization_details, "authorization_details must contain at least one element", :empty_authorization_details}`). This is Pitfall 6 above.

2. **What is `ctx`'s exact key set at the PAR push call site?**
   - What we know: `ctx` minimally includes `:client_id`. `:account_id` is unknown at PAR push time (the user hasn't authenticated yet), but is known at `/authorize` re-entry (after PAR consume + login).
   - What's unclear: Does the validator need a way to know whether it's being called at PAR push or `/authorize` re-entry time? Some validators may want to defer expensive checks to the re-entry path (when the account is known).
   - Recommendation: Pass `:account_id` as `nil` at PAR push; pass actual subject-id at `/authorize` re-entry. Document in the behaviour `@callback` doc that `ctx[:account_id]` is `nil` until login completes. Optional `:phase` key (`:par_push | :authorize | :par_consume`) could let validators dispatch on context — planning's call.

3. **Should the dispatcher run on PAR consume re-entry (Pitfall 3)?**
   - What we know: Phase 55's `pushed_request_to_params/1` re-feeds the persisted RAR through `validate_with_client/3`, which calls `validate_authorization_details/2`. After Phase 56, that same path calls Dispatcher again.
   - What's unclear: Whether to bypass via `pre_validated?: true` flag (the Phase 56 surface trusts the PAR row's persisted normalized output) or document an idempotency contract for host validators.
   - Recommendation: Bypass. PAR was already the trusted-pre-validated state in Phase 55; making that explicit beats trusting host-impl idempotency. Set `pre_validated?: true` in the call from PAR-consume path.

4. **Should `Lockspire.Host.PermissiveRarValidator` ship as a default impl?**
   - What we know: CONTEXT.md "Claude's Discretion" notes "likely yes for symmetry and tests, but planning's call."
   - What's unclear: Whether ergonomic value exceeds the "footgun: hosts forget to swap it out and accept-all in production" risk.
   - Recommendation: Ship it, but **only** as a test-support module under `lib/lockspire/host/` (so it's compiled into prod), with a moduledoc warning. Do **not** make it the default in `Lockspire.Config.rar_validators/0` — default `%{}` (strict-reject) is safer than default-accept-all.

5. **Should `mix lockspire.gen.rar_validator <type>` ship in this phase?**
   - What we know: CONTEXT.md "Claude's Discretion" — defer or include if small.
   - Recommendation: Defer to a follow-up DX phase. Phase 56 already ships 4 new modules + 1 migration + 1 schema extension + 5 protocol-tier integrations. Adding a Mix task expands surface without buying SC#1/#2/#3 evidence.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | 1.18 (per `mix.exs`) | — |
| Erlang/OTP | All (esp. `jcs` Ryu float) | ✓ | OTP 25+ (implied by Elixir 1.18 floor) | — |
| PostgreSQL | Migration, JSONB, partial index | ✓ | 16.x (per Phase 55 research) | — |
| `jcs` Hex package | `Lockspire.RAR.Fingerprint` | ✗ (not yet in mix.lock) | 0.2.0 (latest) | None — must add to deps |
| `:telemetry` | Dispatcher span | ✓ | 1.3 (per `mix.lock`) | — |
| `Ecto.Changeset` | Schemaless validators | ✓ | 3.13.5 (per `mix.lock`) | — |
| `:crypto` (OTP) | SHA-256 in Fingerprint | ✓ | OTP-bundled | — |

**Missing dependencies with no fallback:** `jcs` Hex package — first task in Plan #1 should be `mix.exs` deps update + `mix deps.get`.

**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command (per task commit) | `mix test test/lockspire/rar/ test/lockspire/host/rar_type_validator_test.exs` |
| Per-module unit run (dispatcher) | `mix test test/lockspire/rar/dispatcher_test.exs --trace` |
| Per-module unit run (fingerprint) | `mix test test/lockspire/rar/fingerprint_test.exs test/lockspire/rar/fingerprint_property_test.exs` |
| Phase-55 retrofit run | `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/protocol/authorization_flow_test.exs` |
| Full suite (per wave merge) | `MIX_ENV=test mix test --include integration` |
| Phase gate (before `/gsd-verify-work`) | `mix qa && MIX_ENV=test mix test --include integration` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RAR-02 | Host can register a validator and receive `validate(detail, ctx)` callback | Unit | `mix test test/lockspire/rar/dispatcher_test.exs::test_host_validator_called -x` | ❌ Wave 0 |
| RAR-02 | Validator return `{:ok, normalized_map}` replaces raw input in `Validated.authorization_details` | Unit | `mix test test/lockspire/protocol/authorization_request_test.exs::test_validated_holds_normalized_output -x` | ❌ Wave 0 (extend existing file) |
| RAR-02 | Validator return `{:error, %Ecto.Changeset{}}` produces `{:redirect_error, :invalid_authorization_details, ...}` | Unit | `mix test test/lockspire/rar/dispatcher_test.exs::test_changeset_error_path -x` | ❌ Wave 0 |
| RAR-02 | Validator return `{:error, "string message"}` is passed through to `error_description` | Unit | `mix test test/lockspire/rar/dispatcher_test.exs::test_string_error_path -x` | ❌ Wave 0 |
| RAR-02 (SC#2) | Unknown `type` is strict-rejected with redirect error AND telemetry event AND log line | Unit + telemetry | `mix test test/lockspire/rar/dispatcher_test.exs::test_unknown_type_strict_reject -x` | ❌ Wave 0 |
| RAR-02 (SC#2) | Empty array `[]` is rejected (Pitfall 6) | Unit | `mix test test/lockspire/protocol/authorization_request_test.exs::test_empty_array_rejected -x` | ❌ Wave 0 (extend existing file) |
| RAR-02 (SC#2) | Redirect-surface `error_description` does not contain offending type name (D-11) | Unit | `mix test test/lockspire/rar/dispatcher_test.exs::test_redirect_error_no_type_leak -x` | ❌ Wave 0 |
| RAR-02 (telemetry) | `[:lockspire, :rar, :validation, :start \| :stop]` events emitted around validator call (D-20) | Telemetry assertion | `mix test test/lockspire/rar/dispatcher_test.exs::test_validation_span_emits -x` | ❌ Wave 0 |
| RAR-02 (telemetry) | `[:lockspire, :rar, :validation, :exception]` event emitted when validator raises | Telemetry assertion | `mix test test/lockspire/rar/dispatcher_test.exs::test_validation_exception_event -x` | ❌ Wave 0 |
| RAR-02 (telemetry) | `[:lockspire, :rar, :unknown_type]` event emitted on strict-reject | Telemetry assertion | `mix test test/lockspire/rar/dispatcher_test.exs::test_unknown_type_telemetry -x` | ❌ Wave 0 |
| RAR-03 | Migration adds 2 columns to `consent_grants`, 1 column to `tokens`, 1 partial index, 1 plain index | Migration smoke | `MIX_ENV=test mix ecto.migrations \| grep add_rar_durable_storage` | ❌ Wave 0 |
| RAR-03 (SC#3) | ConsentGrant inserted with `authorization_details` (validator output) and fingerprint | Repository round-trip | `mix test test/lockspire/storage/repository_test.exs::test_consent_grant_authorization_details_roundtrip -x` | ❌ Wave 0 (extend existing file) |
| RAR-03 (SC#3) | Token issued from authorization-code carries `consent_grant_id` FK | Integration | `mix test test/integration/phase56_rar_validation_storage_e2e_test.exs::test_token_consent_grant_fk -x --include integration` | ❌ Wave 0 (new file) |
| RAR-03 (SC#3) | Refresh-rotated tokens preserve `consent_grant_id` | Integration | `mix test test/integration/phase56_rar_validation_storage_e2e_test.exs::test_refresh_preserves_consent_grant_id -x --include integration` | ❌ Wave 0 (new file) |
| RAR-03 (SC#3) | `ConsentPolicy.reusable_grant/4` re-prompts for consent on fingerprint mismatch | Unit | `mix test test/lockspire/protocol/consent_policy_test.exs::test_fingerprint_mismatch_forces_reconsent -x` | ❌ Wave 0 (extend existing file) |
| RAR-03 (SC#3) | `ConsentPolicy.reusable_grant/4` reuses on fingerprint match | Unit | `mix test test/lockspire/protocol/consent_policy_test.exs::test_fingerprint_match_reuses -x` | ❌ Wave 0 (extend existing file) |
| RAR-03 (SC#3) | `Fingerprint.compute/1` is invariant under map-key construction order | Property | `mix test test/lockspire/rar/fingerprint_property_test.exs -x` | ❌ Wave 0 |
| RAR-03 (SC#3) | `Fingerprint.compute([])` returns `nil` (no fingerprint when RAR absent) | Unit | `mix test test/lockspire/rar/fingerprint_test.exs::test_empty_returns_nil -x` | ❌ Wave 0 |
| RAR-03 (SC#3) | Two RAR sets with semantically-equal but structurally-shuffled details produce identical fingerprints | Property | `mix test test/lockspire/rar/fingerprint_property_test.exs::test_shuffle_invariance -x` | ❌ Wave 0 |
| RAR-03 (cascade) | Deleting a ConsentGrant nilifies `tokens.consent_grant_id`, does not delete tokens | Repository | `mix test test/lockspire/storage/repository_test.exs::test_consent_grant_cascade_nilifies_tokens -x` | ❌ Wave 0 |
| Phase-55 retrofit | Existing PAR/Interaction tests now expect normalized output, not raw input (D-08 inventory) | Unit | `mix test test/lockspire/protocol/authorization_request_test.exs test/integration/phase55_rar_intake_e2e_test.exs --include integration` | ⚠ Existing — must update assertions |
| Phase-55 deferred | PAR re-consume path uses `pre_validated?: true` (Pitfall 3) | Integration | `mix test test/integration/phase56_rar_validation_storage_e2e_test.exs::test_par_consume_does_not_double_validate -x --include integration` | ❌ Wave 0 (new file) |

### Sampling Rate
- **Per task commit:** Quick run command above (touches the new modules under `lib/lockspire/rar/` and `lib/lockspire/host/rar_type_validator.ex`).
- **Per wave merge:** `mix qa && MIX_ENV=test mix test`. The `qa` alias (mix.exs:88-94) runs `format --check-formatted`, `compile --warnings-as-errors`, `credo --strict`, `sobelow --config`, `dialyzer` — all should be green.
- **Phase gate:** `MIX_ENV=test mix test --include integration` (full suite green) before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `test/lockspire/host/rar_type_validator_test.exs` — Behaviour exists/loads, callback present
- [ ] `test/lockspire/rar/dispatcher_test.exs` — All dispatcher behaviors (RAR-02 row block above)
- [ ] `test/lockspire/rar/fingerprint_test.exs` — Empty list, single item, basic SHA-256 byte length
- [ ] `test/lockspire/rar/fingerprint_property_test.exs` — Shuffle invariance, nested-map invariance, list-order preservation
- [ ] `test/lockspire/rar_test.exs` — `error_description/1` for changeset and string inputs
- [ ] `test/integration/phase56_rar_validation_storage_e2e_test.exs` — End-to-end: PAR push → consume → consent → token issue → refresh-rotate, asserting `consent_grant_id` and reuse-policy
- [ ] Extend `test/lockspire/protocol/authorization_request_test.exs` — empty-array rejection, normalized-output replacement, redirect-error type-leak guard
- [ ] Extend `test/lockspire/protocol/consent_policy_test.exs` — fingerprint-aware reuse decisions
- [ ] Extend `test/lockspire/storage/repository_test.exs` — `:nilify_all` cascade, ConsentGrant fingerprint round-trip
- [ ] Add `{:stream_data, "~> 1.0", only: :test}` to `mix.exs` for property tests **OR** confirm an existing property-test framework is wired (verified absence in `mix.lock` — `stream_data` not currently a dep).
- [ ] Framework install: `mix deps.get` after adding `{:jcs, "~> 0.2"}` and `{:stream_data, "~> 1.0", only: :test}` to `mix.exs`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | indirect | RAR validation runs after client authentication (token endpoint) or before subject login (`/authorize`); no new auth surface added by Phase 56. |
| V3 Session Management | no | No session changes. |
| V4 Access Control | yes | RAR is fine-grained authorization data; D-09 strict-reject is the V4 control. |
| V5 Input Validation | yes | The whole phase is V5. Schemaless changesets per host validator (D-07); strict-reject unknown types (D-09); empty-array rejection (Pitfall 6); shape-then-dispatch ordering preserves Phase 55's defense-in-depth. |
| V6 Cryptography | yes | SHA-256 fingerprint via `:crypto.hash/2` — never hand-roll. RFC 8785 JCS for canonicalization — use `jcs` package, do not roll-your-own. |
| V7 Error Handling | yes | D-11: redirect-surface `error_description` deliberately omits offending type name to prevent validator-inventory enumeration. |
| V8 Data Protection | yes (indirect) | Validator output (D-08) drops unknown fields → reduces blast-radius if host accidentally leaks Interaction or ConsentGrant rows via observability. |
| V10 Malicious Code | no | No code-fetch, no eval. |
| V12 Communications | yes (indirect) | Phase 55's 2048-byte length cap remains; Phase 56 inherits. |
| V13 API & Web Service | yes | RFC 9396 §5/§6 compliance is a V13 surface. |

### Known Threat Patterns for OAuth/OIDC + RAR

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| **Validator-inventory enumeration** via `error_description` | Information Disclosure | D-11: generic `error_description` at redirect surface; offending type only in telemetry/logs. |
| **Type-name injection** (e.g., type with ` `, `..`, SQL-shaped strings) | Tampering / Injection | `Map.fetch/2` on the `rar_validators` map keys is structural lookup — never builds SQL or atoms. Avoid `String.to_atom/1` on `type` (atoms aren't GC'd ⇒ DoS). |
| **Fingerprint collision** (semantically-equal RAR sets producing different hashes) | Repudiation / DoS (spurious re-consent) | RFC 8785 JCS via `jcs` package (D-17, Pitfall 1). |
| **Large-payload DoS** via deeply nested validators | Denial of Service | Phase 55's 2048-byte cap; per-detail validator timeout (operator alert via `:rar, :validation, :stop` duration metric). Documented host-side responsibility for recursion bounds (Pitfall 7). |
| **Validator authoring bypass** (host's `validate/2` returns `{:ok, raw_input}` accidentally) | Tampering | Host-side concern, but Lockspire's strict-reject of unknown types and per-type registration discipline limits blast radius to that one type. Document in validator template docs. |
| **Information leakage via stored raw input** | Information Disclosure | D-08: validator-output normalization drops unknown fields before persistence. |
| **`consent_grant_id` cascade-delete data loss** | Repudiation (audit trail) | D-14: `on_delete: :nilify_all` (NOT `:delete_all`). Doorkeeper rationale. |
| **PAR re-validation drift** (Pitfall 3) | Tampering / Repudiation | `pre_validated?: true` on PAR-consume path; persistent fingerprint anchored to first validation. |
| **Empty-array bypass** (`authorization_details: []` slipping through as "no RAR but client thinks they sent some") | Elevation of Privilege (subtle) | Pitfall 6: explicit `[]` rejection. RFC 9396 §2 MUST. |
| **Test-time env leak** (rar_validators bleeds across tests) | Repudiation (false test pass) | Pitfall 8: `async: false` + `on_exit` env-restore. |

### FAPI 2.0 Alignment

D-12 confirms strict-reject is the global default ⇒ no per-profile branching needed. Phase 56's surface is FAPI-2.0-clean by construction. Phase 57 will verify (V-02 success criterion).

## Sources

### Primary (HIGH confidence)
- **RFC 9396** — `https://datatracker.ietf.org/doc/html/rfc9396` — §2 (request/grant element), §3.1 (subset granting), §5 (unknown-type MUST reject), §6 (error reporting), §7 (refresh + reuse).
- **RFC 8785** — `https://datatracker.ietf.org/doc/html/rfc8785` — JCS canonicalization (D-17 anchor).
- **`jcs` Hex package v0.2.0** — `https://hex.pm/packages/jcs`, `https://hexdocs.pm/jcs/0.2.0/Jcs.html` — verified version, publish date 2025-03-31, function set, OTP/Elixir floor.
- **Lockspire codebase** — read directly:
  - `lib/lockspire/host/token_exchange_validator.ex` — host-seam template (verbatim quoted above)
  - `lib/lockspire/host/default_delegation_validator.ex` — default-impl pattern
  - `lib/lockspire/config.ex:37-44` — accessor pattern
  - `lib/lockspire/protocol/authorization_request.ex:570-633` — Phase 55 integration point + redirect-error helpers
  - `lib/lockspire/protocol/refresh_exchange.ex:291-327` — token-rotation helper template
  - `lib/lockspire/protocol/consent_policy.ex` — reuse-policy seed
  - `lib/lockspire/protocol/authorization_flow.ex:252-316` — interaction build + maybe_store_consent
  - `lib/lockspire/storage/ecto/consent_grant_record.ex` + `token_record.ex` — schema/cast/to_domain pattern
  - `lib/lockspire/observability.ex` — telemetry helper signatures
  - `priv/repo/migrations/20260506020000_add_rar_intake_state.exs` — `{:array, :map}` migration template
  - `test/integration/phase55_rar_intake_e2e_test.exs:44-61` — `Application.put_env` test pattern
  - `test/integration/phase48_token_exchange_e2e_test.exs:16-23` — same pattern, second instance
- **Lockspire planning artifacts (HIGH confidence — direct reads)**:
  - `.planning/phases/56-rar-domain-validation-storage/56-CONTEXT.md` — D-01 through D-23 (locked)
  - `.planning/phases/55-rar-protocol-intake/55-VERIFICATION.md` — deferred items 3 & 4 (now in scope)
  - `.planning/phases/55-rar-protocol-intake/55-RESEARCH.md` — Phase 55 framing
  - `.planning/REQUIREMENTS.md` — RAR-02, RAR-03
  - `.planning/ROADMAP.md` — Phase 56 success criteria

### Secondary (MEDIUM confidence — WebSearch verified against authoritative sources)
- **Ecto schemaless changesets** — `https://hexdocs.pm/ecto/data-mapping-and-validation.html`, `https://hexdocs.pm/ecto/Ecto.Changeset.html`, `https://elixirforum.com/t/how-to-validate-json-and-especially-nested-json-objects-with-schemaless-ecto-changesets/56619`, `https://elixirfocus.com/posts/ecto-schemaless-changesets/` — verified `cast/4` schemaless `{data, types}` pattern.
- **Telemetry span pattern** — `https://hexdocs.pm/telemetry/telemetry.html` — `:telemetry.span/3` semantics, exception event behaviour.
- **node-oidc-provider Grant model + `rarForCodeResponse` / `rarForRefreshTokenResponse`** — `https://github.com/panva/node-oidc-provider/blob/main/docs/README.md` — prior-art for "RAR by reference, not embed."
- **Application.put_env + on_exit testing pattern** — `https://elixirforum.com/t/using-application-get-env-application-put-env-in-exunit-tests/8019` — established Lockspire idiom independently confirmed.

### Tertiary (LOW confidence — WebSearch only, flagged for validation)
- **ory/fosite issue #822** — `https://github.com/ory/fosite/issues/822` — referenced in CONTEXT.md as the canonicalization-footgun anchor; my fetch of the issue surfaced design-discussion content but **did not** explicitly mention the fingerprint collision footgun in the Markdown body. CONTEXT.md treats this as locked context; downstream agents should treat the *footgun itself* (semantically-equal RAR sets hashing differently with naive Jason) as well-established (verified independently by `https://www.jonathanychan.com/blog/elixir-map-iteration-order-is-very-undefined/` and `https://github.com/michalmuskala/jason/issues/69`) even though the specific fosite-issue attribution was not directly verifiable in the issue body I fetched.
- **StableJason vs JCS** — `https://hexdocs.pm/stable_jason/readme.html` — StableJason is "deterministic JSON" but not RFC 8785 compliant; treat as alternative-considered, not primary.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `jcs` v0.2.0 verified at hex.pm; Ecto/telemetry/jason versions verified in mix.lock; behaviour template verified verbatim from codebase.
- Architecture: HIGH — Existing host-seam pattern is replicable; integration points cited line-by-line in 55-VERIFICATION.md and re-verified in code reads. The new module layout follows established Lockspire conventions.
- Pitfalls: HIGH — Pitfalls 1, 2, 3, 4 are derived from CONTEXT.md decisions and directly verifiable in code; Pitfalls 5-8 are derived from RFC 9396 §5/§6, OTP behaviour, and existing Lockspire test patterns.
- Telemetry/observability: MEDIUM — `:telemetry.span/3` recommended over manual emit pairs; exact integration with `Lockspire.Observability` (which today only takes 2-element event names) is a planning-call. Recommendation made, but planning may extend `Observability` instead.
- Storage migration: HIGH — Phase 55's migration template is verbatim, and Postgres `on_delete: :nilify_all` semantics are well-defined.
- Phase-55 retrofit scope (D-08 inventory): MEDIUM — I did not enumerate every test that asserts raw-input round-trip on Interaction/PAR; planning's first task should be a `grep -r "interaction.authorization_details ==" test/` audit.

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 (stable infrastructure; only `jcs` package and Elixir/OTP versions could meaningfully drift)
