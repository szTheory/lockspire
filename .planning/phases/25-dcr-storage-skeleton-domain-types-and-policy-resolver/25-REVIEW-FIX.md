---
phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver
fixed_at: 2026-04-26T13:00:00Z
review_path: .planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/25-REVIEW.md
iteration: 1
findings_in_scope: 12
fixed: 12
skipped: 0
status: all_fixed
---

# Phase 25: Code Review Fix Report

**Fixed at:** 2026-04-26T13:00:00Z
**Source review:** `.planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/25-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 12 (3 Critical + 9 Warning; Info findings were not in scope for this iteration)
- Fixed: 12
- Skipped: 0

CR-02 and WR-02 are flagged below as `fixed: requires human verification`. Both are logic-level changes that pass syntax checks but can only be confirmed correct by running the test suite (deps not available in the isolated worktree) and by reading the diff carefully.

## Fixed Issues

### CR-01: DcrPolicy silently accepts malformed inbound `redirect_uris`

**Files modified:** `lib/lockspire/protocol/dcr_policy.ex`, `test/lockspire/protocol/dcr_policy_test.exs`
**Commit:** 51e69ff
**Status:** fixed
**Applied fix:** `intersect_redirect_uris/5` now uses `Enum.find/2` to detect any parsed `%URI{}` whose `:scheme` or `:host` is `nil`. When found, it returns `{:error, :invalid_client_metadata, %{field: :redirect_uris, reason: :unparseable, allowed: []}}` rather than silently filtering the offender out of the requested set. Adds four regression tests covering relative paths (`"/callback"`), empty strings, free text, and `"javascript:alert(1)"` (scheme-only, host nil).

### CR-02: `Admin.ServerPolicy.put_dcr_policy/1` lost-update race

**Files modified:** `lib/lockspire/storage/server_policy_store.ex`, `lib/lockspire/storage/ecto/repository.ex`, `lib/lockspire/admin/server_policy.ex`, `test/lockspire/admin/server_policy_test.exs`
**Commit:** 4d550da
**Status:** fixed: requires human verification
**Applied fix:** Added `update_server_policy/1` to the `ServerPolicyStore` behaviour, taking a mutator function. `Repository.update_server_policy/1` runs the mutator inside the existing `FOR UPDATE` transaction so the read-merge-write happens atomically. `Admin.ServerPolicy.put_server_policy/1` and `put_dcr_policy/1` now funnel through the new function instead of doing a non-atomic two-step. The original `Repository.put_server_policy/1` is now a thin wrapper that overwrites unconditionally (still an implementation of the existing `put_server_policy` callback).

Adds a concurrency regression test that drives 16 interleaved tasks across both setters and asserts neither field reverts. Note: the test uses `Ecto.Adapters.SQL.Sandbox.allow/3` to share the parent's checkout — operators should confirm the sandbox-allow pattern works against the project's `TestRepo` setup; if not, the test may need `:async, false` plus a different sharing strategy. Logic correctness depends on the runtime behaviour of `transact/1` + `lock("FOR UPDATE")` against Postgres, which cannot be verified with `Code.string_to_quoted!` alone.

### CR-03: `DcrPolicy` host comparison is case-sensitive

**Files modified:** `lib/lockspire/protocol/dcr_policy.ex`, `test/lockspire/protocol/dcr_policy_test.exs`
**Commit:** 81343cf
**Status:** fixed
**Applied fix:** `intersect_redirect_uris/5` now downcases both sides of the intersection: inbound URIs via `String.downcase/1` on `uri.scheme` and `uri.host`, and the operator and IAT allowlists via a new `downcase_list/1` helper. RFC 3986 §3.1 (scheme) and §3.2.2 (host) declare both case-insensitive. Adds three regression tests: mixed-case inbound host, mixed-case inbound scheme, and a mixed-case operator allowlist accepting lowercased inbound.

### WR-01: `intersect_axis/4` truthy-check on `iat_override_list`

**Files modified:** `lib/lockspire/protocol/dcr_policy.ex`
**Commit:** 797161d
**Status:** fixed
**Applied fix:** Replaced the `if iat_override_list` truthy guard with an explicit `case` that matches `nil -> server_set` and `list when is_list(list) -> MapSet.new(list)`. Encodes the contract at the call site so a future change to `override_for/2` that returns `[]` for "absent" cannot silently flip "no override" into "narrow to nothing."

### WR-02: `DcrPolicyInvariantTest` overclaims subset, not equality

**Files modified:** `test/lockspire/protocol/dcr_policy_invariant_test.exs`
**Commit:** 588938c
**Status:** fixed: requires human verification
**Applied fix:** Replaced the `List.first/1`-then-subset assertion with a `for method <- expected_set` loop that asserts `accepted_for_inbound == MapSet.new([method])` for every member of the expected set. The previously-trivial `server_only` loop now asserts both that the resolver DOES accept the probe (proving Phase 27's discovery filter is load-bearing) AND that `MapSet.intersection(probe_accepted, discovery_set) == MapSet.new()` (proving the filter discards it). Logic correctness depends on the resolver continuing to behave as documented — please run `mix test test/lockspire/protocol/dcr_policy_invariant_test.exs` to confirm the new assertions pass against the current resolver implementation.

### WR-03: `InitialAccessTokenRecord.changeset/2` casts `:id`

**Files modified:** `lib/lockspire/storage/ecto/initial_access_token_record.ex`
**Commit:** 2fc106d
**Status:** fixed
**Applied fix:** Removed `:id` from the `cast/3` field list. `lockspire_initial_access_tokens` uses Postgres autoincrement IDs, unlike the singleton `lockspire_server_policies` row that ServerPolicyRecord must cast `:id` for. Added a comment explaining the divergence so future maintainers do not re-add `:id` while mirroring ServerPolicyRecord.

### WR-04: `DcrPolicy.resolve/3` accepts struct-shaped `iat_overrides`

**Files modified:** `lib/lockspire/protocol/dcr_policy.ex`, `test/lockspire/protocol/dcr_policy_test.exs`
**Commit:** 178ee24
**Status:** fixed
**Applied fix:** Tightened the guard on `resolve/3` from `is_map(iat_overrides) or is_nil(iat_overrides)` to `is_nil(iat_overrides) or (is_map(iat_overrides) and not is_struct(iat_overrides))`. Added a regression test that asserts `FunctionClauseError` when the `%InitialAccessToken{}` struct is passed directly. Also aliases `Lockspire.Domain.InitialAccessToken` in the test module.

### WR-05: `Admin.ServerPolicy.normalize_dcr_attrs/1` silently drops unknown atom keys

**Files modified:** `lib/lockspire/admin/server_policy.ex`
**Commit:** 6ca59b7
**Status:** fixed
**Applied fix:** Refactored the `Enum.reduce/3` accumulator to `{atomized_map, unknown_keys}`. Unknown atom keys (not in `@dcr_field_keys`) and unknown string keys (where `atomize_dcr_key/1` returns `nil`) are now collected; if the list is non-empty, a single `Logger.warning/2` is emitted at the boundary listing all dropped keys. The function still returns `{:ok, atomized}` to preserve current API shape; a future iteration may upgrade to a structured error return once Phase 28's admin LiveView lands.

### WR-06: `Discovery.token_endpoint_auth_methods_supported/0` decoupled from mounted-route truth

**Files modified:** `lib/lockspire/protocol/discovery.ex`
**Commit:** a719fe0
**Status:** fixed
**Applied fix:** Added `Discovery.published_token_endpoint_auth_methods_supported/0` that mirrors the mounted-route logic from `openid_configuration/0` and returns `[]` when the `token_endpoint` route is not mounted. Phase 27's HTTP DCR surface should call this accessor instead of the static one for the discovery-side filter. The static `token_endpoint_auth_methods_supported/0` remains for the Phase 25 invariant test (which must stay pure / async / no router) and now documents the upper-bound semantics explicitly. Extracted `mounted_endpoint_metadata/0` to share between `openid_configuration/0` and the new accessor.

### WR-07: `ClientRecord.update_changeset/2` cast list omits new DCR fields with no documentation

**Files modified:** `lib/lockspire/storage/ecto/client_record.ex`
**Commit:** 805d2ec
**Status:** fixed
**Applied fix:** Added a comment block above `update_changeset/2` enumerating the deliberately-excluded fields (`provenance`, `registration_access_token_hash`, `registration_client_uri`, `initial_access_token_id`, `client_id_issued_at`, `client_secret_expires_at`) and noting that Phase 26 will introduce a separate `dcr_management_changeset/2` for RFC 7592 mutation paths. The cast list itself is unchanged — the issue was documentation gap, not the exclusions.

### WR-08: Migration default `[]` for `{:array, :text}` columns

**Files modified:** `lib/lockspire/protocol/dcr_policy.ex`
**Commit:** 9fb540a
**Status:** fixed
**Applied fix:** Documentation-only. Added an "Empty allowlist semantics (operator UX hazard)" section to the `DcrPolicy` moduledoc flagging the secure-by-default behaviour where every DCR request returns `:not_in_allowlist` with `allowed: []` when the operator has not populated allowlists. Notes that Phase 26's intake validator should distinguish `:dcr_unconfigured` from per-axis `:not_in_allowlist`. The migration default `[]` itself is not changed (the secure-by-default stance is correct per D-06).

### WR-09: `InitialAccessToken.t()` `policy_overrides` typespec is too permissive

**Files modified:** `lib/lockspire/domain/initial_access_token.ex`
**Commit:** f84e021
**Status:** fixed
**Applied fix:** Added `@type policy_overrides :: %{optional(String.t()) => [String.t()]}` and updated the `@type t` definition to use `policy_overrides() | nil`. Documented the contract via `@typedoc`, enumerating the six known keys (`"allowed_scopes"` etc.) and noting that pinning the shape lets Dialyzer catch drift between admin-mint (Phase 28) and resolve-time (Phase 25 `DcrPolicy.resolve/3`).

## Skipped Issues

None — all 12 in-scope findings were fixed.

---

_Fixed: 2026-04-26T13:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
