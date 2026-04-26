---
phase: 25
plan: 07
subsystem: lockspire/protocol
tags:
  - dcr
  - resolver
  - mapset-intersection
  - rfc-7591
  - tdd
dependency_graph:
  requires:
    - lib/lockspire/domain/server_policy.ex (Plan 25-04 — DCR fields the resolver consumes)
  provides:
    - Lockspire.Protocol.DcrPolicy.resolve/3 (intersection-only resolver, arity-3 contract per D-16)
    - Lockspire.Protocol.DcrPolicy.Resolved (substruct with 6 list-valued allowed_* + 3 scalar default_*_seconds fields)
  affects:
    - Plan 25-08 (invariant test composes DcrPolicy.resolve/3 with Discovery.token_endpoint_auth_methods_supported/0 externally — no change required to either module)
    - Phase 26 (intake validator calls DcrPolicy.resolve/3 as the second seam after RFC 7591 §2 coherence checks)
    - Phase 27 (POST /register controller calls DcrPolicy.resolve/3 and translates the {:error, :invalid_client_metadata, %{...}} tuple into the RFC 7591 §3.2.2 HTTP 400 response)
tech_stack:
  added: []
  patterns:
    - "Intersection-only resolver via per-axis MapSet.intersection/2 (D-17) — provably never widens."
    - "Arity-3 contract (server_policy, iat_overrides_or_nil, inbound_metadata) returning {:ok, Resolved.t()} | {:error, :invalid_client_metadata, %{field, reason, allowed}}."
    - "Fail-fast `with` chain: first failing axis short-circuits with the structured error tuple naming the offending field."
    - "`Resolved` substruct mirrors the ParPolicy template (the only existing resolver precedent in the repo)."
key_files:
  created:
    - lib/lockspire/protocol/dcr_policy.ex
    - test/lockspire/protocol/dcr_policy_test.exs
  modified: []
decisions:
  - "Followed plan verbatim — D-16 arity-3, D-17 intersection-only, D-18 IAT-overrides-not-revalidated all honored."
  - "Removed the literal `jar_policy.ex` string from the resolver moduledoc to satisfy acceptance criterion `grep -c 'jar_policy' = 0` (Pitfall 1 explicit guard); the `ParPolicy` precedent reference remains."
  - "TDD task ordering: Task 1 ships the resolver, Task 2 ships the tests. The Plan 04 SUMMARY already established this pattern — the plan's own `<tasks>` block puts implementation before tests, so the task-level RED gate cannot truly fail. All 12 tests passed green on first run because the resolver matches the spec in Task 1's action block byte-for-byte."
metrics:
  duration_minutes: 5
  duration_seconds: 299
  started: "2026-04-26T15:59:16Z"
  completed: "2026-04-26T16:04:15Z"
  tasks_completed: 2
  commits: 2
  files_changed: 2
  tests_added: 12
  tests_passing: 12
requirements_completed:
  - DCR-07
  - DCR-08
---

# Phase 25 Plan 07: DCR Policy Resolver Summary

**`Lockspire.Protocol.DcrPolicy.resolve/3` — pure-function arity-3 intersection resolver across server allowlists × IAT overrides × RFC 7591 inbound metadata, returning `{:ok, %Resolved{}}` or `{:error, :invalid_client_metadata, %{field, reason, allowed}}`.**

## Performance

- **Duration:** 5 min (299 s)
- **Started:** 2026-04-26T15:59:16Z
- **Completed:** 2026-04-26T16:04:15Z
- **Tasks:** 2 (both `tdd="true"`)
- **Files created:** 2
- **Tests added:** 12 (all passing, async)

## Accomplishments

- `Lockspire.Protocol.DcrPolicy` module shipped with the locked arity-3 contract per D-16 verbatim.
- `Resolved` substruct with the 6 list-valued allowlist fields and 3 scalar default-lifetime fields, matching the spec.
- Per-axis intersection via `MapSet.intersection/2` per D-17 — provably never widens.
- D-18 invariant honored: IAT overrides are NOT re-validated for widening; out-of-allowlist override values are naturally dropped by intersection.
- Fail-fast `with` chain returns the first offending axis via the `{:error, :invalid_client_metadata, %{field, reason, allowed}}` tuple (`:allowed` not `:detail` per Pitfall 5).
- 12 unit tests cover every Wave 0 branch: empty inbound, fully-narrowed inbound, exceeded server allowlist (each of 5 axes), IAT narrowing, IAT widening attempt naturally dropped, three-way intersection, deterministic short-circuit axis order, and unknown-key ignore.
- Pure-function: zero `Telemetry`, zero `Logger`, zero `Repo.*`, zero `use Ecto` references in the resolver module.

## What Was Built

### `lib/lockspire/protocol/dcr_policy.ex` (NEW)

Public API:

```elixir
@spec resolve(ServerPolicy.t(), map() | nil, map()) ::
        {:ok, Resolved.t()} | {:error, :invalid_client_metadata, error_detail()}
def resolve(%ServerPolicy{} = server_policy, iat_overrides, inbound_metadata)
    when (is_map(iat_overrides) or is_nil(iat_overrides)) and is_map(inbound_metadata)
```

`Resolved` substruct (9 fields):

- 6 list-valued `allowed_*` fields: `allowed_scopes`, `allowed_grant_types`, `allowed_response_types`, `allowed_redirect_uri_schemes`, `allowed_redirect_uri_hosts`, `allowed_token_endpoint_auth_methods`.
- 3 scalar `default_*_seconds` fields: `default_client_lifetime_seconds`, `default_client_secret_lifetime_seconds`, `default_registration_access_token_lifetime_seconds`.

Internal layout:

- `intersect_axis/4` — generic per-axis intersection helper. Computes `requested |> MapSet.difference(server_set) |> MapSet.to_list()` first; if non-empty, returns the structured error. Otherwise `MapSet.intersection/2` is applied across all three sets and returned as a list.
- `intersect_redirect_uris/5` — parses each `redirect_uris` string via `URI.parse/1`, drops nil schemes/hosts, and delegates to `intersect_axis/4` with `:redirect_uri_scheme` and `:redirect_uri_host` field names.
- `scope_inbound/1` — parses RFC 7591 §2 space-separated `"scope"` string into a list (`String.split(" ", trim: true)`).
- `token_endpoint_auth_method_inbound/1` — wraps the inbound single-string into a 1-element list.
- `list_inbound/2` — defensive read of array-valued inbound keys; treats nil/string/list/other gracefully.
- `override_for/2` — defensive read of IAT override keys (returns `nil` for nil/missing, the list for list values, `nil` otherwise).

The validated `redirect_uris` list itself is intentionally NOT carried on `Resolved.t()` — Phase 26's intake validator and Phase 27's controller take the original `inbound["redirect_uris"]` list directly once the resolver returns `:ok`. The moduledoc documents this contract.

### `test/lockspire/protocol/dcr_policy_test.exs` (NEW)

`use ExUnit.Case, async: true` — pure-function tests, no DB sandbox. 12 tests:

1. Empty inbound returns `Resolved` with empty allowlists and the scalar defaults carried verbatim.
2. Fully-narrowed inbound (`scope`, `grant_types`, `response_types`, `redirect_uris`, `token_endpoint_auth_method` all in-allowlist) intersects to itself.
3. Out-of-allowlist `scope` returns `{:error, :invalid_client_metadata, %{field: :scope, ...}}`.
4. Out-of-allowlist `grant_types` returns the same error shape with `field: :grant_types`.
5. Out-of-allowlist redirect URI scheme returns `field: :redirect_uri_scheme`.
6. Out-of-allowlist redirect URI host returns `field: :redirect_uri_host`.
7. Out-of-allowlist `token_endpoint_auth_method` returns `field: :token_endpoint_auth_method`.
8. IAT overrides further narrow below server allowlist (D-17 keystone for IAT participation).
9. IAT override carrying a value NOT in server allowlist is naturally dropped (D-18 explicit guard).
10. Three-way intersection (server × IAT × inbound) returns the smallest set (DCR-08 + D-17 keystone).
11. Short-circuits at the first failing axis (deterministic axis order: scope → grant_types → response_types → redirect_uris → token_endpoint_auth_method).
12. Ignores unknown inbound keys and missing optional keys.

## TDD Gate Compliance

Plan-level frontmatter is `type: execute` (not `type: tdd`), so no plan-level RED/GREEN gate is strictly required.

Both tasks are flagged `tdd="true"` at task level, but the plan's own task ordering puts the implementation in Task 1 and the tests in Task 2. This is the same situation as Plan 25-04's Task 1 (the resolver-vs-test bootstrap pattern). The task-level "RED" can't fail because by the time tests are written, the implementation exists. All 12 tests passed green on first run.

Commit log shows the canonical `feat → test` ordering for this plan:

| Order | Hash | Type | Description |
|-------|------|------|-------------|
| 1 | `40569d8` | feat(25-07) | resolver module |
| 2 | `4f6e638` | test(25-07) | resolver tests |

A future contributor extending this resolver should follow the standard `test → feat → refactor` cycle.

## Verification

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` | Clean |
| `mix test test/lockspire/protocol/dcr_policy_test.exs` | 12 tests, 0 failures |
| `mix test test/lockspire/protocol/par_policy_test.exs` (regression) | 6 tests, 0 failures |
| `mix format --check-formatted` (both new files) | Clean |
| `iex -S mix` smoke test (`DcrPolicy.resolve(%ServerPolicy{...}, nil, %{"scope" => "openid"})`) | `{:ok, %Resolved{allowed_scopes: ["openid"], ...}}` |
| Pure-function: `grep -c 'Telemetry\|Logger\|Repo\.\|use Ecto' lib/.../dcr_policy.ex` | 0 |
| `grep -c 'MapSet.intersection' lib/.../dcr_policy.ex` | 3 (D-17 invariant) |
| `grep -c 'jar_policy' lib/.../dcr_policy.ex` | 0 (Pitfall 1) |
| `grep -c ':detail =>' lib/.../dcr_policy.ex` | 0 (Pitfall 5 — uses `:allowed` not `:detail`) |
| `grep -q 'def resolve(%ServerPolicy{} = server_policy, iat_overrides, inbound_metadata)' lib/.../dcr_policy.ex` | PASS (D-16 arity-3 contract) |

All 11 Task 1 acceptance criteria and all 11 Task 2 acceptance criteria pass.

## Commits

| Commit | Type | Files | Description |
|--------|------|-------|-------------|
| `40569d8` | feat | 1 | `lib/lockspire/protocol/dcr_policy.ex` — intersection-only resolver + `Resolved` substruct |
| `4f6e638` | test | 1 | `test/lockspire/protocol/dcr_policy_test.exs` — 12 unit tests covering all Wave 0 branches |

Per-task commits used `--no-verify` (parallel executor in worktree, per orchestrator convention).

## Decisions Made

- **Resolver moduledoc reference to `jar_policy.ex` removed.** The plan's action block included a moduledoc line stating "there is no `jar_policy.ex`" (a Pitfall-1 denial), but the same plan's acceptance criterion required `grep -c 'jar_policy' = 0`. I resolved the contradiction in favor of the acceptance criterion: the moduledoc still references `Lockspire.Protocol.ParPolicy` as the precedent, just without the literal denial string. Semantic intent (no false reference to a non-existent module) is preserved.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Applied `mix format` after initial write**

- **Found during:** Task 1 (resolver module verification).
- **Issue:** The `intersect_redirect_uris/5` definition exceeded the 98-column line limit; `mix format --check-formatted` exited 1.
- **Fix:** Ran `mix format lib/lockspire/protocol/dcr_policy.ex`, which reformatted the function head to multi-line.
- **Files modified:** `lib/lockspire/protocol/dcr_policy.ex` (one function head reformatted).
- **Verification:** `mix format --check-formatted lib/lockspire/protocol/dcr_policy.ex` exits 0.
- **Committed in:** `40569d8` (part of Task 1 commit).

**2. [Rule 3 — Blocking] Removed `jar_policy.ex` literal from moduledoc**

- **Found during:** Task 1 (acceptance criterion `grep -c 'jar_policy' lib/.../dcr_policy.ex` returns `0`).
- **Issue:** The plan's action block included the literal text "the only existing resolver precedent in the repo — there is no `jar_policy.ex`" inside the moduledoc, which would fail `grep -c 'jar_policy' = 0`. The acceptance criterion (Pitfall 1) is the binding contract; the moduledoc's denial-of-existence string is a self-defeating pattern.
- **Fix:** Edited the moduledoc to read "Mirrors `Lockspire.Protocol.ParPolicy` shape (the only existing resolver precedent in the repo)." The `ParPolicy` precedent reference remains; the `jar_policy.ex` literal is gone.
- **Files modified:** `lib/lockspire/protocol/dcr_policy.ex` (one moduledoc line).
- **Verification:** `grep -c 'jar_policy' lib/lockspire/protocol/dcr_policy.ex` returns `0`.
- **Committed in:** `40569d8` (part of Task 1 commit).

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking).
**Impact on plan:** No scope creep. Both fixes were necessary to pass the plan's own acceptance criteria; the resolver behavior is unchanged.

## Issues Encountered

- Worktree dependencies were not installed at start; `mix deps.get` was run to install Hex packages before compile (transient infrastructure step, not a deviation).

## Authentication Gates

None — pure-Elixir / no-DB / no-network plan.

## Next Phase Readiness

### For Plan 25-08 (Wave 3 — discovery-binding invariant test)

The invariant test (per D-19, D-20) lives at `test/lockspire/protocol/dcr_policy_invariant_test.exs` and will compose `DcrPolicy.resolve/3` (this plan) with `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` (Plan 25-01) externally — no change is required to either module from Plan 25-08.

The keystone composition the invariant test pins is:

```elixir
MapSet.equal?(
  MapSet.intersection(
    MapSet.new(server_policy.dcr_allowed_token_endpoint_auth_methods),
    MapSet.new(Discovery.token_endpoint_auth_methods_supported())
  ),
  MapSet.new(resolved.allowed_token_endpoint_auth_methods)
)
```

If either side drifts (server allowlist widens beyond Discovery, or Discovery shrinks below server allowlist), the invariant test fails loudly and names which side drifted.

### For Phase 26 (intake validator + IAT redemption)

- The intake validator calls `DcrPolicy.resolve/3` as the **second** validation seam (after RFC 7591 §2 coherence checks for required-field presence and JSON shape).
- Phase 26 must translate the `{:error, :invalid_client_metadata, %{field, reason, allowed}}` tuple into an RFC 7591 §3.2.2 HTTP 400 response with `error: "invalid_client_metadata"` and a description naming the offending field. The `:allowed` list is operator-public information (per the threat-model T-25-24 disposition) and may be included in the response.
- The `iat_overrides_or_nil` argument is whatever the IAT redemption returns: `nil` when no IAT was redeemed (open registration mode), or the `policy_overrides` map from the redeemed `%InitialAccessToken{}` struct.

### For Phase 27 (POST /register controller)

- The controller calls into the Phase 26 intake validator, which calls into this resolver. The resolver is never called directly from the controller — Phase 26's validator owns the seam.
- The validated `inbound["redirect_uris"]` list (NOT carried on `Resolved.t()` per the moduledoc note) is taken directly from the request body once the resolver returns `:ok`.

## Self-Check: PASSED

All claims verified before write:

- `lib/lockspire/protocol/dcr_policy.ex` — FOUND
- `test/lockspire/protocol/dcr_policy_test.exs` — FOUND
- Commit `40569d8` — FOUND in `git log`
- Commit `4f6e638` — FOUND in `git log`
- `mix test test/lockspire/protocol/dcr_policy_test.exs` — 12 tests, 0 failures
- `mix compile --warnings-as-errors` — clean
- `mix format --check-formatted` (both new files) — clean

---
*Phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver*
*Plan: 07*
*Completed: 2026-04-26*
