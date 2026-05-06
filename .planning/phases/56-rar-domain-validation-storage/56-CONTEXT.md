# Phase 56: RAR Domain Validation & Storage - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the host-extensible validation framework + durable storage that turns Phase 55's RAR intake (parse, persist on PAR/Interaction, length-cap) into actually-enforceable Rich Authorization Requests per RFC 9396. Three things in scope:

1. A public host-seam (`Lockspire.Host.RarTypeValidator`) that lets a host app register one validator module per RAR `type` and have unknown types strict-rejected with RFC-compliant errors.
2. Validator-output normalization: the validator's structured output (not raw decoded JSON) is what gets stored.
3. Durable RAR binding to the consent record: `authorization_details` + `authorization_details_fingerprint` on `ConsentGrant`, with `consent_grant_id` FK on `Token` so refresh exchange propagates RAR for free and Phase 57 introspection becomes a single join.

Explicitly **out of scope** (Phase 57 territory): JAR/Request-Object projection of `authorization_details`, consent-UI rendering of RAR, `/introspection` exposure of RAR, end-to-end FAPI 2.0 + RAR verification.

</domain>

<decisions>
## Implementation Decisions

### Validator Registration Shape
- **D-01:** Per-type config map. `config :lockspire, :rar_validators, %{"payment_initiation" => MyApp.RAR.PaymentInitiation, ...}`. Map keys are the **single source of truth** for what types Lockspire supports — the Phase 58 discovery list will be `Map.keys(rar_validators) |> Enum.sort()`. No second source of truth, no drift.
- **D-02:** `Lockspire.Host.RarTypeValidator` behaviour, one impl per type. Lives in `lib/lockspire/host/rar_type_validator.ex`. Mirrors the existing `Lockspire.Host.*` host-seam pattern (`TokenExchangeValidator`, `AccountResolver`, `BackchannelNotification`) — single behaviour, registered via `Application.get_env`. No macros, no compile-time auto-registration, no `:persistent_term`. Runtime config; overridable in tests.
- **D-03:** Two new accessors on `Lockspire.Config`: `rar_validators/0` (map, default `%{}`) and `rar_types_supported/0` (sorted keys list — Phase 58 will consume this).
- **D-04:** Behaviour callback signature: `@callback validate(detail :: map(), ctx :: map()) :: {:ok, map()} | {:error, Ecto.Changeset.t() | String.t()}`. Two-arity to mirror `TokenExchangeValidator(context)` precedent and let validators reach `client_id`, `account_id`, request metadata if needed. `ctx` shape to be designed in planning, but minimally includes `:client_id`, `:account_id`, `:request` (optional fields kept minimal).

### Validator API Shape (the "Ecto-based" semantic from SC#1)
- **D-05:** Behaviour contract is **plain map → result**, not "must be a changeset." This matches Phase 55's existing host-seam convention and lets hosts pick their validation idiom (Ecto / NimbleOptions / pattern-matching) without fighting the API. The "Ecto-based" SC#1 wording is satisfied because (a) the canonical generated example uses `Ecto.Changeset`, (b) Lockspire's error-formatter helper accepts a changeset, (c) host-supplied changesets are first-class on the error path.
- **D-06:** Lockspire ships a small `Lockspire.RAR.error_description/1` helper that formats `Ecto.Changeset.t()` errors via `traverse_errors/2` into a single RFC-compliant `error_description` string. Strings pass through unchanged. This keeps host validator bodies clean.
- **D-07:** Generated install template (the `mix lockspire.gen.rar_validator <type>` task — see deferred ideas below) emits a **schemaless changeset** body, not `embedded_schema`. Schemaless is the more honest fit for "validate one inbound JSON object that never persists as a top-level row" (Ecto guides recommend exactly this for inbound API payload validation). Hosts who prefer `embedded_schema` (Ash shops, etc.) remain free to use it.
- **D-08:** Validator output is **stored**, not raw input. Validators return `{:ok, normalized_map}` (typically the `apply_changes` of a changeset), and that normalized map is what Lockspire persists on PAR/Interaction/ConsentGrant. Unknown fields are dropped at validation time. This is a deliberate behavior change from Phase 55 (which stored raw decoded JSON) — security win because unsupported fields can't leak into introspection responses or refresh tokens. Phase 55 storage path needs to be retrofitted to use validator output.

### Unknown-Type Behavior (SC#2 anchor)
- **D-09:** **Strict reject from day 1.** When an RAR `type` has no registered validator, Lockspire returns `error: "invalid_authorization_details"` per RFC 9396 §5 (normative MUST). No `:warn` migration knob — Lockspire is pre-1.0 (`0.2.0` in `mix.exs`), Phase 55 shipped today (2026-05-06), there's no installed base to soften the cutover for. Strict-from-day-1 keeps the design clean.
- **D-10:** **Per-client unknown-type policy override is deferred.** Tempting (`Client.metadata[:rar_unknown_type_policy]`), but adding a per-client softener before the global behavior is locked invites the secure-default-bypass-by-omission footgun (forgetting to set it on a new client). If pain emerges, add it in a later milestone.
- **D-11:** **`error_description` deliberately omits the offending type name in the redirect.** RFC 9396 §6 permits including it, but exposing the host's exact validator inventory to unauthenticated probes is a small information-disclosure footgun. The offending type **does** land in telemetry + structured logs (see D-15) so operators can debug. At the token endpoint (post-client-auth), inclusion is OK — planning can decide whether to differentiate the two surfaces.
- **D-12:** **FAPI 2.0 alignment** — strict reject is the global default already; no per-profile branching needed. If a future per-client softener is ever added (D-10), `security_profile: :fapi_2_0_security` MUST clamp it back to strict.

### Durable Storage (SC#3 anchor)
- **D-13:** Add `authorization_details: {:array, :map}` (default `[]`) and `authorization_details_fingerprint: :binary` (32-byte SHA-256, nil when RAR absent) to `consent_grants`. `Lockspire.Domain.ConsentGrant` and `Lockspire.Storage.Ecto.ConsentGrantRecord` get the new fields. **No new domain/store seam** — `ConsentGrant` already plays the durable-consent role and a parallel `AuthorizationGrant` would duplicate it.
- **D-14:** Add `consent_grant_id` FK to `tokens` (`references(:consent_grants, on_delete: :nilify_all)`). `:nilify_all` not `:delete_all` — revoking a ConsentGrant must leave token rows for revocation/audit (Doorkeeper rationale). `Lockspire.Domain.Token` and `Lockspire.Storage.Ecto.TokenRecord` gain the field. `Lockspire.Protocol.AuthorizationFlow.issue_authorization_code/3` and `Lockspire.Protocol.RefreshExchange` propagate it through token rotations exactly the way `family_id` already rides along.
- **D-15:** **Phase 55's `Interaction.authorization_details` field stays.** It's the pre-validation snapshot at `/authorize` time; ConsentGrant carries the post-grant truth. Two different concepts (request vs grant — RFC 9396 §3.1 explicitly contemplates user granting a subset of requested details). Both rows persist their own copy. Interaction's lifecycle remains tied to authorization-code TTL; ConsentGrant survives refresh rotations.
- **D-16:** **Reuse-policy fingerprint.** `Lockspire.Protocol.ConsentPolicy.reusable_grant/3` extends from `(account_id, client_id, scopes)` to `(account_id, client_id, scopes, authorization_details_fingerprint)`. Same scopes + different RAR ⇒ re-consent (RFC 9396 §7).
- **D-17:** **Fingerprint algorithm:** RFC 8785 JCS-style canonicalization, then SHA-256. New module `Lockspire.RAR.Fingerprint`: recursive sort of map keys, deterministic list ordering, normalized number encoding, then `Jason.encode!/1`, then `:crypto.hash(:sha256, ...)`. **Not** `Jason.encode!/1` directly — Elixir/Jason map iteration order is not guaranteed deterministic, and that footgun bit early `ory/fosite` RAR drafts (semantically-equal RAR sets producing different hashes ⇒ spurious re-consent prompts).
- **D-18:** **JSONB column** for `authorization_details` (`{:array, :map}` resolves to JSONB array in Postgres — same idiom Phase 55 uses on `pushed_authorization_requests` and `interactions`). No GIN index in Phase 56 (queryability is Phase 57's territory if needed); fingerprint index covers reuse-policy lookup.
- **D-19:** **Index strategy.** New partial index `consent_grants_reuse_idx` on `(account_id, client_id, authorization_details_fingerprint) WHERE status = 'active'`. New plain index on `tokens(consent_grant_id)` for refresh + introspection lookups.

### Telemetry & Operability
- **D-20:** New telemetry events:
  - `[:lockspire, :rar, :validation, :start | :stop | :exception]` — span events around `validator.validate(detail, ctx)`. Measurements: `:duration`. Metadata: `:type`, `:client_id`, `:outcome` (`:ok | :error`).
  - `[:lockspire, :rar, :unknown_type]` — emitted at strict-reject. Measurements: `%{count: 1}`. Metadata: `:type`, `:client_id`. Operators monitor this to spot misconfigured hosts.
  These are additive; Phase 55's existing authorization-flow telemetry stays unchanged.
- **D-21:** Logger-level for unknown-type rejection: `Logger.warning` with structured fields. Hosts can crank logger-level higher to suppress in tests.

### Module Layout (planning input)
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Specs / Standards (normative)
- [RFC 9396 — OAuth 2.0 Rich Authorization Requests](https://datatracker.ietf.org/doc/html/rfc9396) — §2 (`type` and additional members), §3.1 (request vs grant subset), §5 (unknown-type rejection MUST), §6 (error reporting), §7 (relationship to refresh and consent), §10 (introspection — Phase 57).
- [RFC 8785 — JSON Canonicalization Scheme (JCS)](https://datatracker.ietf.org/doc/html/rfc8785) — fingerprint canonicalization (D-17).
- [FAPI 2.0 Security Profile (final)](https://openid.net/specs/fapi-security-profile-2_0-final.html) — strict-input-validation alignment (D-12).

### Lockspire planning artifacts
- `.planning/ROADMAP.md` §"Phase 56: RAR Domain Validation & Storage" — phase goal + 3 success criteria.
- `.planning/REQUIREMENTS.md` — RAR-02 (Ecto-based validation framework), RAR-03 (storage + token association).
- `.planning/PROJECT.md` — Lockspire core value, constraints (Ecto/Postgres default, secure-by-default, host-seam discipline), Key Decisions table.
- `.planning/phases/55-rar-protocol-intake/55-RESEARCH.md` — Phase 55 research; §"Common Pitfalls" calls out Phase 56's responsibilities; §"Known Threat Patterns for RAR" pre-commits to type whitelisting.
- `.planning/phases/55-rar-protocol-intake/55-VERIFICATION.md` — explicit deferred items addressed in Phase 56: empty-array `[]` rejection (deferred item 3), `pushed_request_to_params` re-validation coupling (deferred item 4).

### Lockspire codebase (integration points)
- `lib/lockspire/protocol/authorization_request.ex` — `validate_authorization_details/2` (lines 570-590), `validate_authorization_details_length/3` (592-606), `ensure_authorization_details_shape/2` (615-621), `invalid_authorization_details/1` (625-633), `pushed_request_to_params/1` (730), `Validated` struct (33, 54), `build_validated/9` (789-815). Phase 56 extends these.
- `lib/lockspire/protocol/authorization_flow.ex` — `build_interaction/5` (260) currently sets `authorization_details: validated.authorization_details`; needs to pair with new `consent_grant_id` propagation. `issue_authorization_code/3` (lines around 283-303) issues the code — Phase 56 extends to thread `consent_grant_id`. `maybe_store_consent/3` (305-316) is where ConsentGrant gets created — extend to populate RAR + fingerprint.
- `lib/lockspire/protocol/pushed_authorization_request.ex` — `persist_pushed_request/3` (line ~113) threads `validated.authorization_details`; integrates with new dispatcher.
- `lib/lockspire/protocol/refresh_exchange.ex` — must propagate `consent_grant_id` on token rotation (mirrors existing `family_id` propagation).
- `lib/lockspire/protocol/consent_policy.ex` — `reusable_grant/3` extends with fingerprint key (D-16).
- `lib/lockspire/host/token_exchange_validator.ex` — **the canonical host-seam pattern to mirror**.
- `lib/lockspire/host/default_delegation_validator.ex`, `lib/lockspire/host/default_deny_token_exchange_validator.ex` — pattern for shipping a default impl alongside a behaviour.
- `lib/lockspire/config.ex` — `token_exchange_validator/0` (lines 37-44) is the accessor pattern to mirror for `rar_validators/0` and `rar_types_supported/0`.
- `lib/lockspire/domain/consent_grant.ex` — schema target for D-13.
- `lib/lockspire/domain/token.ex` — schema target for D-14 (`consent_grant_id`).
- `lib/lockspire/storage/ecto/consent_grant_record.ex`, `lib/lockspire/storage/ecto/token_record.ex` — Ecto record updates.
- `priv/repo/migrations/20260506020000_add_rar_intake_state.exs` — Phase 55's RAR migration; new Phase 56 migration adds the consent-grant + token columns alongside.

### Prior-art references (planning may consult)
- node-oidc-provider — `features.richAuthorizationRequests` config, `Grant` model (`lib/models/grant.js`), `rarForCodeResponse` / `rarForRefreshTokenResponse` / `rarForIntrospectionResponse` helpers.
- OpenIddict (`OpenIddictAuthorization`) — durable-authorization vs token split.
- Doorkeeper (`oauth_access_grants` vs `oauth_access_tokens`) — same split, Rails-flavored.
- Connect2id — `op.rar.supportedTypes` server config (discovery integration).
- ory/fosite issue #822 — RAR canonicalization footgun (D-17 anchor).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Lockspire.Host.TokenExchangeValidator`** — exact host-seam template for `RarTypeValidator`. Same `@behaviour` shape, same `Application.get_env` registration, same default-impl-alongside pattern.
- **`Lockspire.Config`** — established accessor pattern (`token_exchange_validator/0`, `account_resolver!/0`); add `rar_validators/0` + `rar_types_supported/0` here.
- **Phase 55's `validate_authorization_details/2`** in `authorization_request.ex` — already returns `{:ok, decoded_list}` or the standard `{:redirect_error, ...}` tuple. Phase 56 extends the success path: dispatch each entry through the registered validator, replace with normalized output. The redirect-error machinery composes for free.
- **`{:array, :map}` Ecto type** — Phase 55 already uses this on `pushed_authorization_requests` and `interactions`; same column type for `consent_grants.authorization_details`.
- **`family_id` propagation in `RefreshExchange`** — pattern to mirror exactly for `consent_grant_id` propagation through refresh rotations.
- **`ConsentPolicy.reusable_grant/3`** — extension target for fingerprint-aware reuse (D-16). Existing 3-key signature stays compatible by adding a 4th positional or keyword arg.
- **`Lockspire.Telemetry`** — span and event emitters already exist; new `[:lockspire, :rar, ...]` events plug in trivially.

### Established Patterns
- **Domain → Record → Store layering** — `Lockspire.Domain.X` (struct) → `Lockspire.Storage.Ecto.XRecord` (schema) → `Lockspire.Storage.XStore` (behaviour). Phase 56 *extends* `ConsentGrant` and `Token` rather than introducing a new triple, so this layering is preserved without a new domain.
- **Single-behaviour host seam, runtime config** — `Application.get_env(:lockspire, :token_exchange_validator, Default*)` pattern. Lockspire explicitly avoids compile-time auto-registration; Phase 56 follows suit.
- **Telemetry-everywhere** — every protocol decision point emits a `[:lockspire, ...]` event; D-20 is just adding to that surface.
- **JSONB-on-Postgres** — `{:array, :map}` for unstructured-but-known-shape data; same idiom for `consent_grants.authorization_details`.
- **`{:redirect_error, ...}` + `{:browser_error, ...}` tuples** — established error shapes from `Lockspire.Protocol.AuthorizationRequest`. Phase 56's strict-reject + validator errors funnel through `:invalid_authorization_details` redirect-error exactly as Phase 55 already does for shape errors.

### Integration Points
- `lib/lockspire/protocol/authorization_request.ex` — `validate_authorization_details/2` is the single dispatch point (called from `validate/1` at line 295 and via `pushed_request_to_params` re-entry at line 730).
- `lib/lockspire/protocol/authorization_flow.ex` — `build_interaction/5` (Interaction RAR copy stays for Phase 55 compat) and `maybe_store_consent/3` (ConsentGrant gets RAR + fingerprint).
- `lib/lockspire/protocol/refresh_exchange.ex` — `consent_grant_id` propagation (mirrors `family_id`).
- `lib/lockspire/protocol/consent_policy.ex` — reuse-policy fingerprint key.
- New file: `lib/lockspire/rar.ex` (helpers — `error_description/1`).
- New file: `lib/lockspire/rar/dispatcher.ex` (working name — internal lookup + telemetry).
- New file: `lib/lockspire/rar/fingerprint.ex`.
- New file: `lib/lockspire/host/rar_type_validator.ex` (behaviour).
- New file: `priv/repo/migrations/<timestamp>_add_rar_durable_storage.exs`.

</code_context>

<specifics>
## Specific Ideas

- **node-oidc-provider's `Grant` model is the prior-art anchor** for the storage decision (D-13/D-14). Phase 56 doesn't introduce a parallel `Grant` (Lockspire's `ConsentGrant` already plays that role), but the *shape* — RAR by reference, not by JWT-embed; durable across token rotations; refresh propagates the FK — is the right target.
- **Pre-1.0 freedom matters here.** Lockspire is `0.2.0`; Phase 55 shipped today. We deliberately skip the `:warn` migration knob and the per-client unknown-type override because there's no installed base to soften the cutover for and because every "soft default" deferred to a config flag is one more thing to remove later. Strict-from-day-1, deferred per-client toggle.
- **Validator output is what gets stored** (D-08). This is a behavior change from Phase 55 and the most subtle decision in this phase. Stop-gap: Phase 55 integration tests that asserted `interaction.authorization_details == raw_input` will need updating to `interaction.authorization_details == validator_output_normalized`. Planning should inventory and update those tests.
- **Fingerprint canonicalization (D-17) is non-negotiable.** Plain `Jason.encode!/1` would produce non-deterministic output across BEAM versions; use explicit recursive key-sort + list normalization. RFC 8785 JCS is the reference.
- **`error_description` token-vs-redirect surface** (D-11). At the `/authorize` redirect (unauthenticated probe surface), keep generic. At the token endpoint (post-client-auth), full type name is OK. Planning can split if it lands cleanly.

</specifics>

<deferred>
## Deferred Ideas

- **`mix lockspire.gen.rar_validator <type>` generator** — Phoenix-style generator that scaffolds a host validator module from a schemaless-changeset template. Nice DX, but not required for SC#1/#2/#3. Defer to a follow-up phase or fold into install-DX work; planning has discretion to include if it's a small wave.
- **Per-client unknown-type policy** (`Client.metadata[:rar_unknown_type_policy]`) — see D-10. Adds operator flexibility; adds secure-default-bypass risk. Defer until real demand surfaces.
- **`rar_unknown_type_policy: [:reject | :warn]` migration knob** — see D-09. Useful only if there's an installed Phase-55 base that needs a soft cutover. Currently there isn't.
- **GIN index on `consent_grants.authorization_details`** — for querying "all grants with type X." Phase 57 introspection might want this; defer until query patterns are concrete.
- **Per-type discovery metadata schemas** (e.g., publishing JSON Schema for each `authorization_details_types_supported` entry) — RFC 9396 doesn't require this, but production servers like Curity ship it. Defer to a milestone-closure phase if integrators ask.
- **Phase 55 deferred items: empty-array `[]` rejection, `pushed_request_to_params` re-validation coupling** — both flagged in `55-VERIFICATION.md` as Phase 56 territory. Empty-array rejection becomes implicit in D-08 if validators reject empty input; the re-validation coupling needs explicit handling once the dispatcher runs on PAR re-entry. Planning should include both as concrete tasks under SC#2.
- **Information-disclosure surface for `error_description` at token endpoint** (D-11 split) — planning's call.

</deferred>

---

*Phase: 56-rar-domain-validation-storage*
*Context gathered: 2026-05-06*
