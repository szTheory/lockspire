# Phase 56: RAR Domain Validation & Storage - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-06
**Phase:** 56-rar-domain-validation-storage
**Areas discussed:** Validator registration shape, Validator API shape (Ecto-based), Unknown-type behavior, Durable storage location

---

## Discussion Mode

User requested **research-backed advisor mode**: spawn parallel subagents per gray area, return pros/cons/tradeoffs/idiomatic-fit/lessons-learned, then synthesize ONE coherent recommendation per area instead of presenting raw multiple-choice options. User also asked to shift this preference left in GSD where possible (saved to `~/.claude/projects/.../memory/feedback_advisor_default.md`).

Four parallel `gsd-advisor-researcher` agents dispatched. Each researched RFC 9396, FAPI 2.0, and prior-art OAuth servers (node-oidc-provider, OpenIddict, Doorkeeper, Curity, Connect2id, Authlete, Hydra/fosite, Rodauth-OAuth) plus idiomatic Elixir/Phoenix/Ecto patterns.

---

## Area 1: Validator Registration Shape

| Option | Description | Selected |
|--------|-------------|----------|
| A. Single dispatcher behaviour | Host implements one `RarValidator` module with `validate(type, details)` and routes by type internally. Mirrors `TokenExchangeValidator` 1:1. | |
| B. Per-type config map | `config :lockspire, :rar_validators, %{"payment_initiation" => MyApp.PaymentValidator}`; each module impls `RarTypeValidator` with `validate(map)`. | ✓ |
| C. Behaviour with `types/0` discovery callback | Single host module declares `types/0` + `validate/2`; Lockspire reads `types/0` on boot. | |
| D. Compile-time DSL / `use` macro | `use Lockspire.RarValidator, type: "payment_initiation"`; auto-collected via `:persistent_term` or compiled module attrs. | |

**Recommendation:** B — per-type config map.

**Rationale:** Production prior art converged independently — node-oidc-provider's `features.richAuthorizationRequests.types: { … }` and Connect2id's `op.rar.supportedTypes` are both string-keyed maps of validators. `Map.keys/1` becomes the single source of truth for `authorization_details_types_supported` discovery (Phase 58) — A/C/D all need a second source of truth which guarantees drift. Composes with Lockspire's existing `Host.*` single-behaviour-per-impl pattern (each per-type module is plain `@behaviour`); the multi-impl coordination lives at the runtime config edge. No compile-time magic; project explicitly prefers boring/explicit/runtime-config.

**Footguns flagged for planning:**
- Don't auto-register via macros / `:persistent_term` (Oban's compile-time-vs-runtime warning applies).
- Don't conflate "supported types" with "validator presence" (Connect2id 14.4 lesson — silent permissive behavior when supportedTypes drifted from actual validators).
- Reject unknown types with `invalid_authorization_details`, not `invalid_request` (RFC 9396 §6).

---

## Area 2: Validator API Shape (Ecto-based)

| Option | Description | Selected |
|--------|-------------|----------|
| A. `embedded_schema` + `cast/changeset` | Host defines a struct per type; Lockspire normalizes back to map. | |
| B. Schemaless changeset | `cast({%{}, types}, params, fields)`; validator returns `{:ok, normalized_map}` or `{:error, changeset}`. | |
| C. Plain callback | `@callback validate(map) :: {:ok, map} \| {:error, errors}`. Ecto-agnostic. | |
| D. `Ecto.Type` per RAR type | Host implements `Ecto.Type`; Lockspire calls `cast/1`. | |
| E. Hybrid: behaviour wraps schemaless changeset by convention | Contract is plain map → result; helper formats Ecto.Changeset errors; install template uses schemaless. | ✓ |

**Recommendation:** E — plain map I/O contract; schemaless changeset by convention; helper for changeset error formatting.

**Sub-decision: normalization stance** — yes-but-stripped. Validator output is what gets stored, not raw input. `apply_changes/1` returns only the cast subset; unknown fields are dropped at validation time. (Behavior change from Phase 55, which stored raw decoded JSON.)

**Rationale:** Behaviour contract stays plain Elixir maps to match `TokenExchangeValidator` precedent and let hosts pick Ecto / NimbleOptions / pattern-matching. SC#1's "Ecto-based" wording is satisfied because (a) generated install template uses schemaless changeset, (b) Lockspire ships `Lockspire.RAR.error_description/1` accepting `Ecto.Changeset.t()`, (c) host changesets are first-class on the error path. node-oidc-provider's canonical example uses Zod (not Mongoose); they kept the contract a plain `validate(ctx, detail, client)` for exactly this reason. `embedded_schema` is misleading for transient-validation-only objects; Ecto guides recommend schemaless for inbound API payload validation. Storing validator output (not raw) is the security win — RFC 9396 §2 lets unknown members exist but their semantics are type-defined; un-normalized storage leaks unsupported fields into refresh/introspection.

**Footguns flagged for planning:**
- Don't bake `embedded_schema` into the contract — host-side schema-library lock-in is the wrong shape.
- Don't store raw input after validation — RFC 9396 §2 allows unknown members but un-normalized storage is a leak.
- Don't use `Ecto.Type` (option D) — `:error` atom is unrecoverable for `error_description`.

---

## Area 3: Unknown-Type Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| A. Strict reject (default-deny) | `invalid_authorization_details` for any type without registered validator. RFC 9396 §5 normative MUST. | ✓ |
| B. Strict reject + opt-out (`:warn` migration knob, FAPI clamps strict) | Same as A by default, with a config softener for migration cutover. | |
| C. Allow-but-stripped passthrough | Pass through with only `type` preserved; log warning. | |
| D. Allow-if-no-validators-registered | Permissive when registry empty; strict when any registered. | |
| E. Per-client policy | Server-policy or client-metadata declares allowed types per client. | |

**Recommendation:** A — strict reject from day 1. **No `:warn` migration knob.** Per-client override deferred.

**Rationale:** RFC 9396 §5 is a normative MUST. Phase 55's threat model already pre-committed Phase 56 to whitelisting. FAPI 2.0 mandates strict input validation — non-strict default is unshippable when `security_profile: :fapi_2_0_security` is on. Curity ships strict-reject; Authlete's silent-ignore-of-unknown-scopes is the cautionary footgun (caused field confusion where ops believed scopes were enforced but were dropped). The migration-window `:warn` knob (researcher's option B) is over-engineering — Lockspire is `0.2.0`, Phase 55 shipped today, no installed base to soften the cutover for. Per-client override (E) deferred because adding it before global behavior is locked invites the secure-default-bypass-by-omission footgun.

**Override decision:** `error_description` deliberately omits the offending type name in the user-redirect; it lands in telemetry + structured logs only. Avoids exposing the host's exact validator inventory to unauthenticated probes. RFC 9396 §6 permits inclusion; Lockspire chooses tighter posture for unauth surface.

**Footguns flagged for planning:**
- Silent-ignore (Authlete pattern for unknown scopes) — never both quiet and lenient.
- Per-type `error_description` leaking registry contents — keep generic for unauth flows; offending type lands in telemetry.
- Migration-window flags ossifying into prod (Curity experimental-flag pattern) — this is why no `:warn` knob.

---

## Area 4: Durable Storage Location

| Option | Description | Selected |
|--------|-------------|----------|
| A. RAR on `ConsentGrant` | Add `authorization_details` to existing durable consent record; Token gets `consent_grant_id` FK. | |
| B. RAR on `Token` | Every issued AT/RT/code carries copy. Refresh duplicates per rotation. | |
| C. New `AuthorizationGrant` table referenced by `grant_id` | Separate domain/store seam. node-oidc-provider's `Grant` model. | |
| D. Keep on `Interaction` only, lengthen TTL | Minimum schema change. Inverts Interaction's transient lifecycle. | |
| E. Hybrid: ConsentGrant (durable) + Interaction (Phase 55 invariant) | Same as A but explicitly preserves Phase 55's Interaction copy as the pre-validation snapshot. | ✓ |

**Recommendation:** E — RAR on `ConsentGrant` (durable, post-grant truth) + `Token.consent_grant_id` FK (refresh propagation) + Interaction copy retained (Phase 55 invariant; pre-validation snapshot at `/authorize`).

**Rationale:** `ConsentGrant` already plays Lockspire's durable-consent-across-rotations role; option C's parallel `AuthorizationGrant` would duplicate the seam without adding value. Token JWT stays compact (Phase 57 SC#2) since RAR is by reference. Phase 57 introspection becomes a single join. Mirrors OpenIddict (`OpenIddictAuthorization` separate from token table) and Doorkeeper (`oauth_access_grants` separate from `oauth_access_tokens`) — both production servers split durable authorization from transient tokens. Refresh propagates `consent_grant_id` exactly the way `family_id` already does. Reuse-policy gets a new fingerprint key for "same scopes + different RAR ⇒ re-consent" per RFC 9396 §7.

**Critical detail:** Fingerprint algorithm = RFC 8785 JCS-style canonicalization + SHA-256, NOT `Jason.encode!/1` directly. Map iteration order is non-deterministic in Elixir/Jason; this footgun bit early ory/fosite RAR drafts.

**FK cascade:** `:nilify_all` not `:delete_all` (Doorkeeper rationale — revoking a ConsentGrant must leave token rows for revocation/audit).

**Footguns flagged for planning:**
- Don't embed RAR JSON in access-token JWT (Phase 57 SC#2; node-oidc-provider's Grant decision was driven by JWT-bloat pain).
- Don't fingerprint with `Jason.encode!/1` directly — non-deterministic across runtimes; spurious re-consent prompts.
- Don't make `consent_grant_id` `on_delete: :delete_all` — leave token rows for audit.

---

## Confirmation

User confirmed: "Lock all 4 + 3 overrides as-is" (no `:warn` knob, normalize-on-store, generic `error_description` in redirects). All four recommendations locked into CONTEXT.md.

## Claude's Discretion

Items left to planning:
- Naming of internal dispatcher module (`Lockspire.RAR.Dispatcher` vs `.Validation` vs `.Coordinator`).
- Exact shape of `ctx :: map()` passed to validators (minimum `:client_id`; planning derives the rest from concrete call sites).
- Whether to ship a `Lockspire.Host.PermissiveRarValidator` default-impl convenience module (mirror of `DefaultDelegationValidator`).
- Whether to keep Phase 55's 2048-byte length cap as-is or pre-validate per-detail size.
- Whether to include the `mix lockspire.gen.rar_validator` generator in this phase or defer.

## Deferred Ideas

- `mix lockspire.gen.rar_validator <type>` Phoenix-style scaffolding generator.
- Per-client unknown-type policy (`Client.metadata[:rar_unknown_type_policy]`).
- `rar_unknown_type_policy: [:reject | :warn]` migration knob (skipped because pre-1.0).
- GIN index on `consent_grants.authorization_details` (defer to Phase 57 if query patterns demand).
- Per-type discovery metadata schemas (Curity-style JSON Schema publication).
- Phase 55 deferred items now in scope: empty-array `[]` rejection (becomes implicit via validator path), `pushed_request_to_params` re-validation coupling.
- Token-endpoint-vs-redirect split for `error_description` verbosity (D-11 in CONTEXT.md).
