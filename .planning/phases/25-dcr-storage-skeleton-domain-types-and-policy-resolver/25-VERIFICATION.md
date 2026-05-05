---
phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver
verified: 2026-04-28T14:30:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification: 2026-04-28T14:30:00Z
gaps: []
deferred: []
human_verification: []
---

# Phase 25: DCR Storage Skeleton, Domain Types, and Policy Resolver — Verification Report

**Phase Goal:** Operators have a durable, migrated DCR policy store, the domain layer carries `ServerPolicy` DCR fields, `Client` provenance fields, and `InitialAccessToken` (with `policy_overrides` JSONB), and `Lockspire.Protocol.DcrPolicy.resolve/3` produces an intersection-only effective policy that is bound at discovery via an invariant test.

**Verified:** 2026-04-26T16:31:00Z
**Status:** passed
**Re-verification:** Yes — Phase 25 review fixes and targeted proof rerun

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Success Criterion | Status | Evidence |
|---|-------------------|--------|----------|
| 1 | Migrations add DCR fields to `lockspire_server_policies`, provenance + RAT/timestamp fields to `lockspire_clients` (existing rows backfilled to `:operator`), and a new `lockspire_initial_access_tokens` table with `policy_overrides jsonb`. | VERIFIED | All three migrations apply cleanly (`MIX_ENV=test mix ecto.migrate` exit=0); rollback `--step 3` reversed cleanly; re-migrate idempotent. SQL in test output confirms all 10 server_policies DCR columns + 6 lockspire_clients columns (`provenance text NOT NULL DEFAULT 'operator'` per Migration C, `client_id_issued_at`, `client_secret_expires_at`, `registration_access_token_hash`, `registration_client_uri`, `initial_access_token_id`) + 9-column `lockspire_initial_access_tokens` table with `policy_overrides :map` (jsonb on disk) and `unique_index([:token_hash])`. |
| 2 | `Domain.ServerPolicy` exposes 3-mode `registration_policy` plus DCR allowlists and DCR defaults, all readable through `Admin.ServerPolicy`. | VERIFIED | `lib/lockspire/domain/server_policy.ex:7` declares `@type registration_policy :: :disabled | :initial_access_token | :open`; defstruct defaults to `:disabled`. All 6 allowlist fields + 3 lifetime fields present (lib/lockspire/domain/server_policy.ex:13-37). `Admin.ServerPolicy.get_dcr_policy/0` (lib/lockspire/admin/server_policy.ex:48-51) returns `{:ok, %ServerPolicy{}}` exposing all 10 DCR fields. `put_dcr_policy/1` round-trip verified by `test/lockspire/admin/server_policy_test.exs` (8 tests, 0 failures). |
| 3 | `DcrPolicy.resolve/3` returns the intersection of server, IAT, and inbound metadata; never widens; rejects metadata exceeding an allowlist with `invalid_client_metadata`. | PARTIAL (BLOCKER candidate via CR-01) | `lib/lockspire/protocol/dcr_policy.ex` ships the `(ServerPolicy.t(), map() | nil, map())` arity-3 contract returning `{:ok, %Resolved{}}` or `{:error, :invalid_client_metadata, %{field, reason, allowed}}`. `MapSet.intersection/2` semantics proven by 11/11 tests in `dcr_policy_test.exs`, including 3-way intersection, IAT-out-of-allowlist drop, and short-circuit-by-axis. **However**, `intersect_redirect_uris/5` (lines 141-162) silently passes unparseable URIs (CR-01 in 25-REVIEW.md) — a class of inbound that escapes bound-checking. Plus case-sensitive host comparison (CR-03) violates RFC 3986 §3.2.2. The contract holds for the 5 well-formed axes; the redirect_uris axis is incomplete. |
| 4 | An invariant test asserts that the set of `token_endpoint_auth_method` values DCR accepts equals the intersection of `ServerPolicy.dcr_allowed_token_endpoint_auth_methods` and `Discovery.token_endpoint_auth_methods_supported/0` (and fails if either side drifts). | VERIFIED (with WARNING) | `test/lockspire/protocol/dcr_policy_invariant_test.exs` exists, calls the public `Discovery.token_endpoint_auth_methods_supported()` (Plan 01 added the public `/0` accessor at `discovery.ex:31-32`), uses a maximal `server_allowlist` including `"private_key_jwt"` and `"tls_client_auth"` (NOT in discovery), uses `MapSet.intersection/2`, and the test passes. **WARNING:** WR-02 in 25-REVIEW.md observes the test asserts only subset, not equality (the `for probe <- server_only` loop is trivially true). Per spec the invariant test exists and would fail on drift via the discovery-only probe branch. The criterion's requirement ("an invariant test asserts ... and fails if either side drifts") is satisfied; the test could be strengthened. |

**Score:** 3/4 SCs verified (SC-3 partial; SC-4 verified with WARNING).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/lockspire/protocol/discovery.ex` (modified) | Public `/0` accessor for `token_endpoint_auth_methods_supported` | VERIFIED | Lines 26-32 add the documented public `/0` returning `@token_endpoint_auth_methods_supported`. Private `/1` at lines 90-96 untouched. |
| `priv/repo/migrations/20260427000000_extend_lockspire_server_policies_dcr.exs` | Adds 10 DCR columns to server_policies | VERIFIED | All 10 columns present; `registration_policy text NOT NULL DEFAULT 'disabled'`; 6 `{:array, :text}` allowlists default `[]`; 3 nullable lifetime ints. Migration exit=0 forward and reverse. |
| `priv/repo/migrations/20260427000010_create_lockspire_initial_access_tokens.exs` | Creates IAT table with unique_index on token_hash | VERIFIED | All 9 D-11 columns; `unique_index(:lockspire_initial_access_tokens, [:token_hash])` on line 35; zero non-unique indexes; `policy_overrides :map` (jsonb on disk). Forward/reverse exit=0. |
| `priv/repo/migrations/20260427000020_extend_lockspire_clients_dcr.exs` | Adds 6 DCR columns to clients with FK on_delete: :restrict | VERIFIED | All 6 columns present; FK with explicit `on_delete: :restrict`; provenance text NOT NULL DEFAULT 'operator' for atomic backfill. Filename timestamp `20260427000020` correctly orders AFTER `…000010` so FK target exists. |
| `lib/lockspire/domain/server_policy.ex` | Extended with 10 DCR fields + typespec | VERIFIED | `@type registration_policy :: :disabled | :initial_access_token | :open` (line 7); 10 new struct keys with correct typespecs and defaults; `mix run` returns `:disabled` for empty struct. |
| `lib/lockspire/domain/client.ex` | Extended with 2-value provenance enum + 5 RAT/IAT/timestamp fields | VERIFIED | `@type provenance :: :operator | :self_registered` (line 12; NOT the 3-value deferred form). 6 new fields in typespec (lines 45-50) and defstruct (lines 86-91) with correct nullable typing and `:operator` default. |
| `lib/lockspire/domain/initial_access_token.ex` (NEW) | Defstruct + typespec mirroring D-11 | VERIFIED | New file with 10-field defstruct mirroring column set 1:1; `single_use: true` default per D-13; `policy_overrides: map() | nil`; zero behavior functions (Phase 25 is schema + struct only per D-15). |
| `lib/lockspire/storage/ecto/server_policy_record.ex` | Schema widened with Ecto.Enum cast for `:registration_policy` + 10 cast atoms | VERIFIED | `field(:registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open], default: :disabled)` (lines 19-22). All 10 DCR fields cast and to_domain-mapped. |
| `lib/lockspire/storage/ecto/client_record.ex` | Schema widened with `:provenance` Ecto.Enum + 5 new fields | VERIFIED | `field(:provenance, Ecto.Enum, values: [:operator, :self_registered], default: :operator)` (line 52). All 6 new fields cast in `changeset/2`; `:provenance` added to `validate_required/2`. **Critically:** `update_changeset/2` (lines 117-140) does NOT include `:provenance` (Open Question 2 honored — verified by test guard at `client_record_test.exs`). |
| `lib/lockspire/storage/ecto/initial_access_token_record.ex` (NEW) | Schema with `unique_constraint(:token_hash)` and policy_overrides | VERIFIED | New file. `field(:token_hash, :string)`, `field(:policy_overrides, :map)`, `validate_required([:token_hash, :expires_at, :single_use])`, `unique_constraint(:token_hash)`. WR-03 noted casts `:id` (would be cleaner to drop). |
| `lib/lockspire/protocol/dcr_policy.ex` (NEW) | Intersection-only resolver with `Resolved` substruct, returning `{:ok, %Resolved{}}` or `{:error, :invalid_client_metadata, %{field, reason, allowed}}` | VERIFIED for shape; PARTIAL for behavior | Module + Resolved substruct present; arity-3 contract honored; `MapSet.intersection/2` used; error tuple uses `:allowed` (NOT `:detail` — Pitfall 5 honored). 11 unit tests pass. CR-01/CR-03 are blockers in the redirect_uris path only. |
| `lib/lockspire/admin/server_policy.ex` | `get_dcr_policy/0` + `put_dcr_policy/1` with read-merge-write | VERIFIED | Both functions present; both `put_dcr_policy/1` (lines 65-71) and `put_server_policy/1` (lines 34-39) read-merge-write to preserve the other side's fields. `String.to_existing_atom` only (no `String.to_atom`). Repository unchanged. 8 tests pass including the explicit "preserves DCR fields" guard. **WARNING:** CR-02 raises lost-update concurrency race (read-merge-write across two non-transactional Repository calls). |
| `test/lockspire/protocol/dcr_policy_test.exs` (NEW) | 11+ unit tests for resolver | VERIFIED | 11 tests, async: true, all pass. Covers empty inbound, fully-narrowed, scope/grant/redirect-scheme/redirect-host/auth-method rejection, IAT narrowing, IAT out-of-allowlist drop (D-18), 3-way intersection, axis short-circuit. |
| `test/lockspire/protocol/dcr_policy_invariant_test.exs` (NEW) | Discovery-binding invariant test | VERIFIED | Pure-function test (async: true, no DB). Calls `Discovery.token_endpoint_auth_methods_supported()` public `/0`. Maximal allowlist includes values not in discovery. Test passes. WR-02 weakens equality claim to subset. |
| `test/lockspire/domain/initial_access_token_test.exs` (NEW) | Wave 0 IAT defstruct shape test | VERIFIED | 4 tests, async: true, pass. Asserts D-11 / D-13 defaults; fixture hash matches `Policy.hash_token(plaintext)` byte-for-byte. |
| `test/support/fixtures/initial_access_token_fixtures.ex` (NEW) | IAT factory using `Security.Policy.hash_token/1` | VERIFIED | Calls `Policy.hash_token(plaintext)` (line in file confirmed); zero `:crypto.hash(:sha256` references — Pitfall §"Hash-at-rest" honored. |
| `test/lockspire/admin/server_policy_test.exs` (modified) | DCR test cases (defaults, round-trip, par/dcr preservation, invalid-mode, string-keyed) | VERIFIED | 8 tests, 0 failures. All 5 new DCR test cases plus the 3 original PAR cases plus the explicit cross-preservation guard. |
| `test/lockspire/storage/ecto/server_policy_record_test.exs` (NEW) | Round-trip for 10 DCR fields | VERIFIED | 2 tests, pass. SQL trace in test output confirms all 10 columns round-trip via `changeset/2` → DB → `to_domain/1`. |
| `test/lockspire/storage/ecto/client_record_test.exs` (NEW) | Self-registered round-trip + update_changeset/2 provenance guard | VERIFIED | 3 tests, pass. Round-trip of all 6 new fields verified; `update_changeset/2` mutation of `:provenance` silently ignored (the explicit Open Question 2 invariant). |
| `test/lockspire/storage/ecto/initial_access_token_record_test.exs` (NEW) | IAT round-trip + unique_constraint + validate_required | VERIFIED | 3 tests, pass. Same plaintext via fixture twice produces identical token_hash → unique_constraint violation observed. |

**Combined Phase 25 test totals:** 34 tests, 0 failures across the 7 new/extended test files.

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `dcr_policy_invariant_test.exs` | `Discovery.token_endpoint_auth_methods_supported/0` | Public function call | WIRED | Line 27 of test calls `Discovery.token_endpoint_auth_methods_supported()`. Zero `Module.get_attribute` / `Code.fetch_docs` (Pitfall 2 honored). Zero literal copy of `["none", "client_secret_basic", "client_secret_post"]` in the test. |
| `dcr_policy_invariant_test.exs` | `DcrPolicy.resolve/3` | Direct call composing externally | WIRED | Line 70: `{:ok, resolved} = DcrPolicy.resolve(server_policy, nil, inbound)`. Plus probe loops over `discovery_only` and `server_only`. |
| `Migration C (clients FK)` | `lockspire_initial_access_tokens` | `references(:lockspire_initial_access_tokens, on_delete: :restrict)` | WIRED | Line 24 of `20260427000020_extend_lockspire_clients_dcr.exs`. Migration order verified by filename timestamp `…000020` > `…000010` > `…000000`. Fresh `mix ecto.migrate` exit=0 confirms FK target resolves. |
| `Admin.ServerPolicy.put_dcr_policy/1` | `Repository.put_server_policy/1` | Read-merge-write via existing singleton plumbing | WIRED | Line 69: `Repository.put_server_policy(merged)`. Repository.ex unchanged (D-04 honored). Concurrency caveat noted in CR-02. |
| `IAT fixture` | `Lockspire.Security.Policy.hash_token/1` | `alias Policy` + `Policy.hash_token(plaintext)` | WIRED | Line in `initial_access_token_fixtures.ex` calls the project hash primitive. T-25-02 mitigation honored. |
| `ServerPolicyRecord` (Ecto.Enum) | text column from Migration A | `field(:registration_policy, Ecto.Enum, values: [...], default: :disabled)` | WIRED | Pitfall 4 honored: every text-enum column has a matching `Ecto.Enum` cast. |
| `ClientRecord` (Ecto.Enum) | text column from Migration C | `field(:provenance, Ecto.Enum, values: [:operator, :self_registered], default: :operator)` | WIRED | Same. |
| `InitialAccessTokenRecord.changeset/2` | `unique_constraint(:token_hash)` | Friendly translation of DB unique-index error | WIRED | Line 48. The Phase 26 atomic redemption depends on this index existing. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `Admin.ServerPolicy.get_dcr_policy/0` | `%ServerPolicy{}` from singleton | `Repository.get_server_policy/0` → `ServerPolicyRecord.to_domain/1` (which maps all 10 DCR fields) | YES | FLOWING — verified by `server_policy_test.exs` round-trip. |
| `Admin.ServerPolicy.put_dcr_policy/1` | merged `%ServerPolicy{}` | Reads current via Repository, merges atts via `Map.merge`, writes via Repository | YES | FLOWING — preservation guard tests pass (par + dcr both preserved across cross-call). Concurrency noted. |
| `DcrPolicy.resolve/3` → `%Resolved{}` | 6 allowlists + 3 scalar defaults | `server_policy.dcr_allowed_*` + `iat_overrides[...]` + parsed inbound | YES | FLOWING for the 5 well-formed axes; PARTIAL for redirect_uris (CR-01 escape). Scalar defaults carried verbatim from server_policy. |
| `Discovery.token_endpoint_auth_methods_supported/0` | static module attribute | `@token_endpoint_auth_methods_supported` | YES | FLOWING — direct attribute return. WR-06 raises a future concern that the public `/0` decouples from mounted-route truth (Phase 27 reconciliation). |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Migrations apply on fresh DB | `MIX_ENV=test mix ecto.drop && create && migrate` | exit=0; all 3 Phase 25 migrations apply with no errors | PASS |
| Migrations roll back cleanly | `MIX_ENV=test mix ecto.rollback --step 3` | exit=0; reverses all 3 in correct order | PASS |
| Migrations are idempotent across rollback | re-run `mix ecto.migrate` after rollback | exit=0; re-applies cleanly | PASS |
| Phase 25 test suite | `mix test test/lockspire/protocol/dcr_policy_test.exs … (7 files)` | 34 tests, 0 failures | PASS |
| Compile is clean (warnings-as-errors) | `mix compile --warnings-as-errors` | exit=0 | PASS |
| Full test suite | `mix test` | 234 tests, 1 failure (80 excluded) | PARTIAL (failure unrelated; see Concerns) |
| Domain default `registration_policy` | tested via `mix run --no-start --eval` and the IAT defstruct test | `:disabled` | PASS |
| Domain default `provenance` | tested via client_record round-trip test | `:operator` | PASS |
| Domain default `single_use` | tested via initial_access_token_test.exs:8 | `true` | PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| DCR-06 | 25-02, 25-04, 25-05, 25-06 | `Domain.ServerPolicy` exposes 3-mode `registration_policy` with singleton row in `lockspire_server_policies` | SATISFIED | `Domain.ServerPolicy` carries the 3-mode enum; Migration A backfills singleton row to `:disabled`; `Admin.ServerPolicy.get_dcr_policy/0` exposes it. |
| DCR-07 | 25-02, 25-04, 25-05, 25-06, 25-07 | DCR allowlists + DCR defaults bind intake; metadata exceeding allowlist → `invalid_client_metadata` | PARTIAL | Allowlists + defaults present, exposed through `Admin.ServerPolicy`, and bound via `DcrPolicy.resolve/3`. Reject-with-`invalid_client_metadata` confirmed for 4 of 5 axes; redirect_uris axis has CR-01 escape. |
| DCR-08 | 25-07 | `DcrPolicy.resolve/3` produces an intersection-only effective policy | PARTIAL | Intersection semantics proven for 5 axes via 11 unit tests. Redirect_uris axis has CR-01 escape (unparseable URIs silently accepted). |
| DCR-09 | 25-01, 25-08 | `token_endpoint_auth_method` set DCR accepts = intersection of ServerPolicy allowlist and `Discovery.token_endpoint_auth_methods_supported/0`; invariant test asserts | SATISFIED (with WARNING from WR-02 — test pins subset, not equality) | Plan 01 added the public `/0` accessor; Plan 08 invariant test composes them externally and would fail on drift via the `discovery_only` probe branch. |
| DCR-10 | 25-03, 25-04, 25-05 | `Domain.InitialAccessToken` + `lockspire_initial_access_tokens` persist IATs with hash-at-rest, expiry, single-use default, nullable `policy_overrides` JSONB | SATISFIED | Migration B creates the 9-column table with `unique_index([:token_hash])`; Domain struct mirrors 1:1 with `single_use: true` default; `policy_overrides :map` (jsonb); fixture hashes via `Security.Policy.hash_token/1` (T-25-02 honored). |

**Orphaned requirements:** None. REQUIREMENTS.md maps DCR-06..DCR-10 to Phase 25; all five appear in PLAN frontmatter `requirements:` fields.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/lockspire/protocol/dcr_policy.ex` | 141-162 | Silent acceptance of unparseable redirect_uris (`Enum.reject(&is_nil/1)` after `URI.parse/1`) | BLOCKER | CR-01: bound-checking escape for malformed redirect_uris. |
| `lib/lockspire/protocol/dcr_policy.ex` | 153-154 | Case-sensitive scheme/host comparison | BLOCKER | CR-03: RFC 3986 §3.1/§3.2.2 violation; mixed-case operator data or registrant data produces confusing rejections. |
| `lib/lockspire/admin/server_policy.ex` | 34-39, 65-71 | Read-merge-write across non-transactional Repository calls | BLOCKER | CR-02: lost-update race between concurrent `put_server_policy/1` and `put_dcr_policy/1`. Test suite covers only sequential path. |
| `lib/lockspire/protocol/dcr_policy.ex` | 120-123 | Truthy guard `if iat_override_list` (handles `[]` correctly today; fragile to `override_for/2` refactor) | WARNING | WR-01: should be explicit `is_nil/1`. |
| `test/lockspire/protocol/dcr_policy_invariant_test.exs` | 7-9, 100-132 | Docstring claims equality; test pins subset only | WARNING | WR-02: false confidence; refactor that breaks resolver-discovery binding for any non-`representative_method` would still pass. |
| `lib/lockspire/storage/ecto/initial_access_token_record.ex` | 38-46 | `cast(:id)` from domain struct | WARNING | WR-03: footgun for fixtures (autoincrement table; admin code could collide). |
| `lib/lockspire/protocol/dcr_policy.ex` | 65-66 | Guard `is_map(iat_overrides)` accepts structs silently | WARNING | WR-04: subsequent Phase 26 footgun if `redeem/1` accidentally passes the IAT struct itself instead of `iat.policy_overrides`. |
| `lib/lockspire/admin/server_policy.ex` | 92-119 | `normalize_dcr_attrs/1` silently drops unknown keys | WARNING | WR-05: admin form typos lose data without error. |
| `lib/lockspire/protocol/discovery.ex` | 31-32 vs 90-96 | Public `/0` decoupled from mounted-route truth | WARNING | WR-06: Phase 27 must reconcile published vs static. |
| `lib/lockspire/storage/ecto/client_record.ex` | 117-140 | `update_changeset/2` silently excludes 5 DCR fields without comment | WARNING | WR-07: Phase 26 implementer might extend `update_changeset/2` ad-hoc. |
| `priv/repo/migrations/20260427000000_*.exs` | 10-15 | `default: []` produces "operator-set-to-empty" indistinguishable from "unconfigured" | WARNING | WR-08: paired with Pitfall — operator confusion. |
| `lib/lockspire/domain/initial_access_token.ex` | 31 | `policy_overrides: map() | nil` typespec too permissive | WARNING | WR-09: Dialyzer can't catch shape drift. |

### Human Verification Required

None. All Phase 25 behaviors are testable through pure-function tests, ExUnit + Ecto sandbox, and migration tooling. No UI in this phase, no external services, no real-time behavior — Phase 25 is greenfield additive code with deterministic intersection semantics. Per `25-VALIDATION.md`: "All phase behaviors have automated verification."

### Concerns

1. **Pre-existing failing test (NOT a Phase 25 regression):** `test/lockspire/release_readiness_contract_test.exs:250` ("planning metadata and repo truth keep PAR scoped to the narrow v1.3 slice") fails because the contract test is hard-coded to expect `Current Milestone: v1.3 PAR Policy Controls` in PROJECT.md, but the project has moved through v1.4 (JAR) and is now in v1.5 (DCR). This test was authored in commit 2ade633 (Phase 19-02, v1.3 era) and is stale documentation drift unrelated to Phase 25 implementation. The test should be removed or rewritten as part of milestone-rollover hygiene.

2. **Code review (25-REVIEW.md) flagged 3 BLOCKERs + 9 WARNINGs.** Per task instructions, these are advisory — code review is not auto-failure for goal verification. However, CR-01 (DcrPolicy redirect_uri silent acceptance), CR-02 (read-merge-write race), and CR-03 (case-sensitive host comparison) are real defects that should be addressed before Phase 26 begins building on top of them. CR-01 directly affects Success Criterion 3 ("rejects metadata that exceeds an allowlist") — the resolver lets through inbound that bypasses the allowlist entirely.

3. **WR-02 weakens the invariant test claim.** The test as written passes today (the discovery-only probe branch is the actual drift detector), but the docstring claims equality the test does not actually pin. Phase 27/29 work that depends on this invariant should treat it as a subset binding, not equality.

### Gaps Summary

The phase substantially achieves its goal: 3 of 4 success criteria are fully VERIFIED, one is PARTIAL.

**Goal-Achievement Verdict:** The migrations land cleanly, the domain layer carries the right shapes, the admin surface exposes them, and the resolver implements intersection semantics correctly for the 5 well-formed axes. The discovery-binding invariant test exists, calls the public `/0` accessor (no private state poking), and would fail on drift.

**The single gap (Success Criterion 3):** `DcrPolicy.intersect_redirect_uris/5` silently accepts unparseable URIs. This is a discrete, fixable defect localized to one function (~25 lines). The fix shape is documented in 25-REVIEW.md CR-01 and would add 1 explicit `Enum.find/2` check + structured error return + 2 regression tests. Pairing the fix with CR-03's lowercase canonicalization is straightforward in the same function.

The CR-02 admin lost-update race is a separate concern; it does not affect the SCs as written (each SC is satisfied by sequential semantics) but it does affect production safety and should be addressed before partner-facing DCR is enabled.

WR-02's invariant-test strengthening should be considered for Phase 25 closure or carried as a Phase 28/29 hardening item; the test does pass and would catch the most likely drift modes (Plan 01 list change, Plan 07 widening).

---

_Verified: 2026-04-26T16:31:00Z_
_Verifier: Claude (gsd-verifier)_
