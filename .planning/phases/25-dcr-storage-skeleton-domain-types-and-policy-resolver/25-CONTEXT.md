# Phase 25: DCR Storage Skeleton, Domain Types, and Policy Resolver - Context

**Gathered:** 2026-04-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Land additive migrations, domain types for `ServerPolicy` / `Client` / `InitialAccessToken`, and the intersection-only `Lockspire.Protocol.DcrPolicy.resolve/3` resolver with its discovery-binding invariant test.

After this phase: a v1.4 database migrates cleanly to v1.5; `Domain.ServerPolicy` carries DCR fields and is operator-readable through `Admin.ServerPolicy`; `Domain.Client` carries DCR provenance + RAT/timestamp fields with all existing rows backfilled to `:operator`; `lockspire_initial_access_tokens` exists with `policy_overrides jsonb`; and `Lockspire.Protocol.DcrPolicy.resolve/3` is intersection-only and bound to `Discovery.token_endpoint_auth_methods_supported/0` by an invariant test that fails if either side drifts.

**Explicitly out of scope this phase:**
- Intake validator behavior (Phase 26)
- IAT redemption / atomicity / hash-comparison (Phase 26)
- HTTP routes and controllers (Phase 27)
- Admin LiveView surfaces (Phase 28)
- Discovery `registration_endpoint` advertisement and 404-on-disabled contract (Phase 29)
- `jwks_uri` outbound fetch (deferred — DCR-FUT-01)
- Built-in rate limiting (deferred — DCR-FUT-04)
- Per-IAT `policy_overrides` admin UI (column ships now; UI deferred — DCR-FUT-03)

Requirements covered by this phase: **DCR-06, DCR-07, DCR-08, DCR-09, DCR-10**.
</domain>

<decisions>
## Implementation Decisions

### Migration Shape & Ordering

- **D-01:** Phase 25 ships **three additive Ecto migrations** in `priv/repo/migrations/`, in this order: (a) extend `lockspire_server_policies` with DCR fields, (b) extend `lockspire_clients` with provenance + RAT/timestamp fields and backfill `provenance = 'operator'` in the same migration, (c) create `lockspire_initial_access_tokens`. New columns use `null: false, default: '<atom-as-string>'` for enums and `{:array, :text}` for allowlists, mirroring the v1.3 PAR-policy additive migration at `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs`.
- **D-02:** Existing `lockspire_clients` rows backfill via the `default: 'operator'` column default at `ADD COLUMN` time — no separate data-migration step. Postgres `ADD COLUMN ... NOT NULL DEFAULT` is atomic.
- **D-03:** `lockspire_initial_access_tokens` carries `unique_index(:lockspire_initial_access_tokens, [:token_hash])` from this phase. Phase 26's atomic single-use redemption depends on this index existing.

### ServerPolicy Field Shape and Admin Surface

- **D-04:** DCR fields land as **top-level columns** on `lockspire_server_policies` — not as an embedded `:dcr` map or a separate `lockspire_dcr_policy` table. Mirrors the established PAR pattern at `lib/lockspire/storage/ecto/server_policy_record.ex:14`.
- **D-05:** `registration_policy` is a `text` column cast to `Ecto.Enum` with values `:disabled | :initial_access_token | :open` and default `:disabled`. Tri-state, not split into two booleans.
- **D-06:** Allowlists are `{:array, :text}` columns: `dcr_allowed_scopes`, `dcr_allowed_grant_types`, `dcr_allowed_response_types`, `dcr_allowed_redirect_uri_schemes`, `dcr_allowed_redirect_uri_hosts`, `dcr_allowed_token_endpoint_auth_methods`. Lifetimes are `:integer` second-counts: `dcr_default_client_lifetime_seconds`, `dcr_default_client_secret_lifetime_seconds`, `dcr_default_registration_access_token_lifetime_seconds`.
- **D-07:** `Admin.ServerPolicy` is **extended in place** with `get_dcr_policy/0` and `put_dcr_policy/1` returning/accepting a `%DcrPolicy{}` substruct view; the existing `get_server_policy/0` / `put_server_policy/1` shape at `lib/lockspire/admin/server_policy.ex:11-22` is the template.

### Client Provenance Fields and Backfill

- **D-08:** `lockspire_clients` gains seven additive columns: `provenance` (`text`, NOT NULL, default `'operator'`), `registration_access_token_hash` (`text`, nullable), `registration_client_uri` (`text`, nullable), `initial_access_token_id` (`bigint`, nullable, FK to `lockspire_initial_access_tokens(id)` `on_delete: :restrict`), `client_id_issued_at` (`utc_datetime_usec`, nullable), `client_secret_expires_at` (`utc_datetime_usec`, nullable). Timestamp types mirror existing fields at `lib/lockspire/domain/client.ex:38-46`.
- **D-09:** **Two-value provenance enum**: `:operator | :self_registered`. Not three. The IAT-vs-open distinction at registration time is recoverable via `initial_access_token_id IS NOT NULL` and is a Phase 26/28 concern, not a column shape decision. Aligns with the Phase 28 filter requirement (`:operator_created` vs `:self_registered`) in `.planning/ROADMAP.md` Phase 28 success criterion 3.
- **D-10:** The IAT FK uses `on_delete: :restrict` — operators cannot delete an IAT that minted a still-existing client. This preserves the audit trail; soft-delete (`revoked_at`) is the supported way to retire an IAT.

### InitialAccessToken Schema

- **D-11:** `lockspire_initial_access_tokens` columns: `id` (bigserial), `token_hash` (`text`, NOT NULL, unique), `expires_at` (`utc_datetime_usec`, NOT NULL), `single_use` (`boolean`, NOT NULL, default `true`), `used_at` (`utc_datetime_usec`, nullable), `revoked_at` (`utc_datetime_usec`, nullable), `policy_overrides` (`jsonb`, nullable), `created_by` (`text`, nullable — operator id), `timestamps(type: :utc_datetime_usec)`.
- **D-12:** Soft-delete-only via `revoked_at IS NOT NULL` in Phase 25. No hard-delete pathway.
- **D-13:** `single_use` is a boolean (default `true`), not a `uses_remaining` integer. The v1.5 admin UI mints single-use IATs only; an N-use extension is a future schema migration.
- **D-14:** Hash-at-rest reuses `Lockspire.Security.Policy.hash_token/1` at `lib/lockspire/security/policy.ex:84-89` (sha256, lowercase hex) — no new hash primitive. Phase 26 redemption compares against this same function.
- **D-15:** `Lockspire.Domain.InitialAccessToken` is a defstruct that mirrors the column set one-to-one. Phase 25 ships **schema + struct only** — `Lockspire.Protocol.InitialAccessToken.redeem/1` is Phase 26 (DCR-11).

### DcrPolicy Resolver Shape and Discovery Binding

- **D-16:** `Lockspire.Protocol.DcrPolicy` is a new module at `lib/lockspire/protocol/dcr_policy.ex` that exposes:
  ```
  resolve(server_policy, iat_overrides_or_nil, inbound_metadata) ::
    {:ok, %Resolved{}} |
    {:error, :invalid_client_metadata, %{field: atom(), reason: atom(), allowed: list()}}
  ```
  Arity-3 is locked by DCR-08 verbatim. The signature mirrors the `Resolved` substruct shape at `lib/lockspire/protocol/par_policy.ex:1-52` (which is the **only existing resolver precedent in the repo** — see Specifics §1).
- **D-17:** Resolution semantics: per-allowlist `MapSet.intersection/2` between server-allowlist, IAT-overrides (when non-nil), and inbound metadata. Any inbound value not in the server-allowlist returns `{:error, :invalid_client_metadata, %{field: ..., reason: ..., allowed: ...}}` naming the offending field.
- **D-18:** **IAT overrides are assumed already-narrowed to ⊆ server allowlist at IAT-mint time** (Phase 28 admin path) and are *not* re-validated for widening at `resolve/3` time. The resolver's job is intersection, not widening detection. If an IAT somehow carries an out-of-allowlist override (e.g. policy was tightened after IAT mint), the intersection naturally drops it — never widens.
- **D-19:** The discovery-binding invariant test lives at `test/lockspire/protocol/dcr_policy_invariant_test.exs` and asserts `MapSet.equal?(MapSet.intersection(server_allowlist, discovery_supported_set), accepted_dcr_set)` — failing if either side drifts. The error message names which side drifted.
- **D-20:** **Add a public `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` accessor** in this phase (does not exist today — only a private `/1` plus a module attribute at `discovery.ex:21,82`). The invariant test depends on a stable public accessor, not on poking a module attribute. This is a small extraction, in-phase.

### Claude's Discretion

- File-internal layout of `dcr_policy.ex` (helpers, internal struct fields, doctests) may follow `par_policy.ex` ergonomics without further user sign-off.
- Test fixture factories for IAT (e.g., `test/support/fixtures/initial_access_token_fixtures.ex` if one is added) follow existing fixture naming and may be added without further sign-off.
- Migration filenames follow the standard timestamped Ecto convention; no naming negotiation required.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 25 entry, success criteria 1–4, dependency graph (Phase 25 has no in-milestone dependencies)
- `.planning/REQUIREMENTS.md` — DCR-06, DCR-07, DCR-08, DCR-09, DCR-10 verbatim text
- `.planning/PROJECT.md` — v1.5 milestone scope, Key Decisions on the DCR wedge
- `.planning/STATE.md` — accumulated v1.5 decisions (per-IAT `policy_overrides` ships schema-only; no rate limiting; `jwks_uri` rejected at intake in Phase 26)
- `.planning/research/SUMMARY.md` — DCR research summary
- `.planning/research/ARCHITECTURE.md` — Pattern 1 (resolver shape), §State Management (column lists), §Build Order Level 1 (three-migration split)
- `.planning/research/PITFALLS.md` — Pitfall 4 (provenance enum tradeoffs), Pitfall 10 (audit-event vocabulary), Pitfall 12 (revoked vs used distinction)
- `.planning/research/STACK.md` — DCR-relevant library inventory
- `lib/lockspire/protocol/par_policy.ex` — **the** structural precedent for `dcr_policy.ex` (resolver + `Resolved` substruct shape)
- `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs` — additive-migration template (text-column-as-Ecto.Enum, in-place backfill via column default)
- `lib/lockspire/storage/ecto/server_policy_record.ex` — singleton record pattern; `:par_policy` field at line 14
- `lib/lockspire/domain/server_policy.ex` — current defstruct shape to extend
- `lib/lockspire/domain/client.ex` — schema and timestamp conventions (lines 38–46) for the seven new columns
- `lib/lockspire/admin/server_policy.ex` — public surface to extend with `get_dcr_policy/0` / `put_dcr_policy/1`; `error_detail` shape at line 9
- `lib/lockspire/security/policy.ex` — `hash_token/1` at lines 84–89 (the hash-at-rest primitive IAT reuses)
- `lib/lockspire/protocol/discovery.ex` — `@token_endpoint_auth_methods_supported` at line 21 and the private `/1` helper at line 82 (extract a public `/0`)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.ParPolicy` — full resolver template including a `Resolved` substruct, intersection helpers, and `:invalid_client_metadata`-style error shape. Mirror its file layout 1:1.
- `Lockspire.Storage.Ecto.ServerPolicyRecord` — singleton record pattern with text-column-as-`Ecto.Enum` casts (PAR uses this; DCR follows).
- `Lockspire.Admin.ServerPolicy` — public accessor / mutator shape to extend (`get_server_policy/0` / `put_server_policy/1`); already uses `{:error, atom, %{field, reason, detail}}` returns.
- `Lockspire.Security.Policy.hash_token/1` — sha256 lowercase hex hash-at-rest primitive. IAT writes go through it. No new hash primitive.
- `Lockspire.Domain.Client` defstruct — established `:utc_datetime_usec` timestamp idiom (`disabled_at`, `last_secret_rotated_at`, `created_at`); the new RFC 7591 §3.2.1 timestamps mirror it.
- v1.3 PAR-policy additive migration — concrete blueprint for "extend singleton + extend clients in one file" with in-place backfill via column defaults.

### Established Patterns

- **Singleton policy on a single row** (PAR): no normalization, no foreign-keyed config table. DCR follows.
- **Text columns cast to `Ecto.Enum`** for tri-state fields with string-atom defaults. DCR `registration_policy` follows.
- **Intersection-only resolvers**: PAR's `Resolved` substruct shape and `{:error, :invalid_client_metadata, %{field, reason, ...}}` rejection idiom is now the project's official protocol-resolver shape.
- **Hash-at-rest only**: secrets and tokens never persist in plaintext. `Security.Policy.hash_token/1` is the single sink.
- **Additive migrations with in-place defaults**: existing rows backfill at `ADD COLUMN` time; no separate data-migration step on small tables.

### Integration Points

- `Lockspire.Admin.ServerPolicy` gains DCR accessors. The Phase 28 LiveView (`PoliciesLive.Dcr`) will consume `get_dcr_policy/0`. Phase 26's intake validator and `Lockspire.Protocol.DcrPolicy.resolve/3` both consume the same struct.
- `lib/lockspire/protocol/dcr_policy.ex` (new) is the seam Phase 26's intake validator and Phase 27's `POST /register` controller call into. Phase 29's discovery contract test cross-references it.
- The new `Discovery.token_endpoint_auth_methods_supported/0` public accessor is consumed by (a) the Phase 25 invariant test and (b) the Phase 29 discovery contract test.
- The IAT FK on `lockspire_clients(initial_access_token_id)` is the join point for Phase 28 provenance UI ("which IAT minted this client?") and Phase 26's audit attribution.
</code_context>

<specifics>
## Specific Ideas

1. **PAR is the only existing resolver precedent in the repo.** The DCR research corpus (`.planning/research/ARCHITECTURE.md` and elsewhere) repeatedly cites `lib/lockspire/protocol/jar_policy.ex` and a v1.4 JAR-policy migration as precedents — neither exists. The actual v1.4 JAR slice did not ship a separate policy resolver module; only `par_policy.ex` and the v1.3 PAR migration are real. Plan and research agents must cite **`par_policy.ex`** when modeling `dcr_policy.ex`, not `jar_policy.ex`.

2. **`Discovery.token_endpoint_auth_methods_supported/0` does not exist as a public function today.** Only a private `/1`-arity helper plus the `@token_endpoint_auth_methods_supported` module attribute at `lib/lockspire/protocol/discovery.ex:21,82`. The Phase 25 invariant test depends on a public `/0` accessor; treat this as a small in-phase task (extract the module attribute through a public function), not an external blocker.

3. **Provenance is two-valued, not three.** `:operator | :self_registered`. Even though PITFALLS.md Pitfall 4 contemplates a 3-value enum (`:operator | :dcr_initial_access_token | :dcr_open`), the v1.5 phase 28 filter UI is two-valued and the IAT-vs-open distinction is recoverable via `initial_access_token_id IS NOT NULL`. Locked.

4. **IAT overrides are narrowing-at-mint, not narrowing-at-resolve.** The resolver assumes IAT overrides are already ⊆ server allowlist; it does **not** re-validate them for widening. Mint-time validation is a Phase 28 (operator UI) concern. If an out-of-allowlist override slips through (e.g., policy tightened after mint), `MapSet.intersection/2` naturally drops it — never widens. Document this invariant in the resolver moduledoc.

5. **`single_use boolean` is the right shape for v1.5, not `uses_remaining int`.** v1.5 admin mints single-use IATs only; the boolean keeps Phase 26's atomic redemption simpler (`UPDATE ... WHERE used_at IS NULL`) without a decrement-and-check pattern.
</specifics>

<deferred>
## Deferred Ideas

- **3-value provenance enum** (`:operator | :dcr_initial_access_token | :dcr_open`) — future-proofs audit-event vocabulary. Recoverable later via a column type widening; for v1.5 the two-value form satisfies all phase-28 / phase-29 requirements.
- **`uses_remaining` N-use IATs** — would require a schema migration; out of scope for v1.5. Re-evaluate if a DCR-FUT requirement names multi-use IATs.
- **Per-IAT `policy_overrides` admin UI** — column lands now (DCR-10); UI is DCR-FUT-03.
- **`jwks_uri` outbound fetch** — DCR-FUT-01; rejected at intake in Phase 26.
- **Built-in rate limiting on `POST /register`** — DCR-FUT-04; host-side Plug seam documented in Phase 29.
- **Embedded `:dcr` substruct on `Domain.ServerPolicy`** — cleaner reads (`dcr.allowed_scopes` vs `dcr_allowed_scopes`) but adds a serialization layer that breaks symmetry with PAR.
- **Separate `lockspire_dcr_policy` table** — premature normalization for a row count of 1.
- **Combined `consumed_at` field on IAT** (instead of `revoked_at` + `used_at`) — loses operator-revoked vs registrant-consumed distinction; rejected.

### Reviewed Todos (not folded)

None — no pending todos matched this phase scope at gather time.
</deferred>
