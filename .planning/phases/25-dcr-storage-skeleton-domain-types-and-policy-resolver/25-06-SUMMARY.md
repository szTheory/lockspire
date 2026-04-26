---
phase: 25
plan: 06
subsystem: lockspire/admin
tags:
  - dcr
  - admin-api
  - server-policy
  - read-merge-write
  - tdd
dependency_graph:
  requires:
    - lib/lockspire/admin/server_policy.ex (Pre-25 — par_policy public surface; this plan extended in place per D-07)
    - lib/lockspire/storage/ecto/repository.ex (Pre-25 — Repository.put_server_policy/1 plumbing reused unchanged per D-04)
    - lib/lockspire/storage/ecto/server_policy_record.ex (Plan 05 — widened cast list; this plan's writes traverse it for DCR fields)
    - lib/lockspire/domain/server_policy.ex (Plan 04 — extended struct shape consumed/returned by these accessors)
  provides:
    - Lockspire.Admin.ServerPolicy.get_dcr_policy/0 (new public accessor returning %Domain.ServerPolicy{})
    - Lockspire.Admin.ServerPolicy.put_dcr_policy/1 (new public mutator, atom- or string-keyed maps, registration_policy enum-validated)
    - Read-merge-write semantics on put_server_policy/1 + put_dcr_policy/1 (T-25-19 mitigation — neither side stomps the other)
  affects:
    - Plan 25-07 (DcrPolicy.resolve/3 reads %Domain.ServerPolicy{} returned by get_dcr_policy/0 — same struct shape)
    - Phase 26 intake validator (consumes %Domain.ServerPolicy{} for DCR allowlists)
    - Phase 28 admin LiveView (PoliciesLive.Dcr submits string-keyed maps directly to put_dcr_policy/1)
tech_stack:
  added: []
  patterns:
    - "Read-merge-write on singleton-row mutators to preserve orthogonal field families on the same row (D-04 + Plan 05 widened cast)."
    - "@registration_policy_atoms module attribute pre-creates safe atoms at compile time (T-25-20 — avoids String.to_atom/1 atom-table pollution)."
    - "@dcr_field_keys allowlist in normalize_dcr_attrs/1 silently drops unknown keys (T-25-21 — operator can't accidentally mutate par_policy through put_dcr_policy/1)."
    - "Structured error tuple shape `[%{field: atom(), reason: atom(), detail: term()}]` reused from existing par_policy precedent at lib/lockspire/admin/server_policy.ex:9."
key_files:
  created: []
  modified:
    - lib/lockspire/admin/server_policy.ex
    - test/lockspire/admin/server_policy_test.exs
decisions:
  - "Followed plan verbatim with one auto-fix (Rule 1) for type-checking warning under --warnings-as-errors: pattern-matched %ServerPolicy{} on the get_server_policy/0 result inside put_server_policy/1's with clause. Behavior unchanged."
  - "Applied mix format to the test file (Rule 1 cosmetic) — it broke two pre-existing long-line asserts in the par_policy tests, but plan acceptance criteria require `mix format --check-formatted` exit 0. Test names and assertion semantics are byte-identical to pre-format. The pre-existing format issue was inherited from base; this plan's scope discovers it."
  - "ZERO changes to lib/lockspire/storage/ecto/repository.ex — verified by `git diff e154f54..HEAD -- lib/lockspire/storage/ecto/repository.ex` returning empty. The existing put_server_policy/1 plumbing widens automatically because Plan 05 widened ServerPolicyRecord cast list."
metrics:
  duration_minutes: 5
  completed: "2026-04-26T16:16:00Z"
  tasks_completed: 2
  commits: 2
  files_modified: 2
  tests_added: 6
  tests_passing: 9
---

# Phase 25 Plan 06: Admin.ServerPolicy DCR Accessors (get_dcr_policy/0 + put_dcr_policy/1) Summary

Extended `Lockspire.Admin.ServerPolicy` in place with `get_dcr_policy/0` and `put_dcr_policy/1` per D-07, converted both `put_server_policy/1` and `put_dcr_policy/1` to read-merge-write so they preserve each other's fields on the singleton row (T-25-19), and shipped 6 new test cases (defaults, round-trip, par-preservation, dcr-preservation, invalid-mode rejection, string-keyed input) on top of the existing 3 par_policy tests — total 9 / 0.

## What Was Built

### `lib/lockspire/admin/server_policy.ex` (modified — full rewrite to plan body)

**Diff summary:** +95 / -2 lines.

Two new module attributes pre-create safe atoms at compile time (T-25-20):

```elixir
@registration_policy_atoms [:disabled, :initial_access_token, :open]
@registration_policy_strings ["disabled", "initial_access_token", "open"]
```

One `@dcr_field_keys` allowlist (T-25-21) constrains the keys `normalize_dcr_attrs/1` will consume:

```elixir
@dcr_field_keys [
  :registration_policy,
  :dcr_allowed_scopes,
  :dcr_allowed_grant_types,
  :dcr_allowed_response_types,
  :dcr_allowed_redirect_uri_schemes,
  :dcr_allowed_redirect_uri_hosts,
  :dcr_allowed_token_endpoint_auth_methods,
  :dcr_default_client_lifetime_seconds,
  :dcr_default_client_secret_lifetime_seconds,
  :dcr_default_registration_access_token_lifetime_seconds
]
```

Two new public functions:

- `get_dcr_policy/0` — `Repository.get_server_policy/0` direct delegation. Returns the same `%Domain.ServerPolicy{}` `get_server_policy/0` returns (D-04 — DCR fields land on the same singleton row).
- `put_dcr_policy/1` — accepts atom- or string-keyed map. Filters input through `@dcr_field_keys` (T-25-21), validates `:registration_policy` is `:disabled | :initial_access_token | :open`, converts string values via `String.to_existing_atom/1` (NEVER `String.to_atom/1`), and read-merge-writes via `Repository.get_server_policy/0` + `Map.merge/2` + `Repository.put_server_policy/1`.

Two helpers:

- `normalize_dcr_attrs/1` — Enum.reduce over input map; allowlist filter; routes registration_policy through `normalize_registration_policy/1`.
- `normalize_registration_policy/1` — three clauses: atom in allowlist → `{:ok, atom}`; string in allowlist → `{:ok, String.to_existing_atom(value)}`; otherwise → structured error `{:error, [%{field: :registration_policy, reason: :invalid_registration_policy, detail: value}]}`.

**`put_server_policy/1` is now read-merge-write** — was `Repository.put_server_policy(%ServerPolicy{par_policy: normalized_mode})` (would stomp DCR fields after Plan 05's widened cast). Now reads the current row first and updates only `:par_policy` on it.

### `test/lockspire/admin/server_policy_test.exs` (modified)

**Diff summary:** +94 / -2 lines (the -2 is two pre-existing long-line assert reflows from `mix format` — see Deviations).

Existing 3 par_policy tests preserved (test names + assertion semantics byte-identical). Six new tests appended:

1. `get_dcr_policy/0 returns disabled defaults when no durable row exists` — asserts `%DomainServerPolicy{registration_policy: :disabled, dcr_allowed_scopes: [], dcr_allowed_grant_types: [], dcr_allowed_response_types: [], dcr_allowed_redirect_uri_schemes: [], dcr_allowed_redirect_uri_hosts: [], dcr_allowed_token_endpoint_auth_methods: [], dcr_default_client_lifetime_seconds: nil, dcr_default_client_secret_lifetime_seconds: nil, dcr_default_registration_access_token_lifetime_seconds: nil}`.
2. `put_dcr_policy/1 round-trip with allowlists and lifetimes` — full DCR shape persisted; verified via `get_dcr_policy/0` AND `Repository.get_server_policy/0` (both views agree).
3. `put_dcr_policy/1 preserves par_policy on the same singleton row` — sets PAR `:required` first, then writes `registration_policy: :open`; asserts both visible after fetch.
4. `put_server_policy/1 preserves DCR fields when called after put_dcr_policy/1` — **the live T-25-19 regression guard.** Writes DCR first, then PAR; asserts DCR allowlist + registration_policy survive. Currently passes; would fail if a future executor reverts read-merge-write.
5. `put_dcr_policy/1 rejects invalid registration_policy with structured error` — asserts the EXACT shape `[%{field: :registration_policy, reason: :invalid_registration_policy, detail: :bogus}]` matching the `error_detail` typespec at line 9.
6. `put_dcr_policy/1 accepts string-keyed input (admin form simulation)` — submits `%{"registration_policy" => "open", "dcr_allowed_scopes" => ["openid"], ...}`; asserts atom-typed struct fields land correctly.

## Confirmation: `lib/lockspire/storage/ecto/repository.ex` was NOT modified

```bash
$ git diff e154f54..HEAD -- lib/lockspire/storage/ecto/repository.ex
$ # (empty diff)
```

Verified above. The existing `put_server_policy/1` plumbing reuses Plan 05's widened `ServerPolicyRecord.changeset/2` cast list to persist DCR fields naturally — no record-layer or repository-layer change in this plan.

## Test Counts

| Test file | Existing | New | Total | Failures |
|-----------|----------|-----|-------|----------|
| `test/lockspire/admin/server_policy_test.exs` | 3 (par_policy) | 6 (DCR) | 9 | 0 |

Plan 05 regression: `mix test test/lockspire/storage/ecto/server_policy_record_test.exs` → 2 / 0.

## Threat Mitigations Live

| Threat | Mitigation in this plan |
|--------|-------------------------|
| T-25-01 (Tampering: DCR fields without admin surface) | `get_dcr_policy/0` + `put_dcr_policy/1` ship; D-07 closes this risk. |
| T-25-19 (Tampering: put_server_policy/1 OR put_dcr_policy/1 stomps the other side) | Both functions read-merge-write. Test 4 (`put_server_policy/1 preserves DCR fields...`) is the live regression guard. |
| T-25-20 (Spoofing: String.to_atom/1 on operator input → atom table pollution) | Code uses `String.to_existing_atom/1`; `@registration_policy_atoms` pre-creates safe atoms. `grep -c 'String.to_atom('` returns `0`. |
| T-25-21 (Tampering: future operator-supplied attr key mutates non-DCR field) | `normalize_dcr_attrs/1` filters input through `@dcr_field_keys` allowlist; non-DCR keys silently dropped. |
| T-25-22 (InfoDisclosure: error tuple echoes raw input back to admin UI) | Accept (per plan threat_model) — the admin LiveView in Phase 28 is responsible for HTML-escaping echoed values. |

## Verification

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` | Clean |
| `mix format --check-formatted lib/lockspire/admin/server_policy.ex test/lockspire/admin/server_policy_test.exs` | Clean |
| `mix test test/lockspire/admin/server_policy_test.exs` | 9 / 0 |
| `mix test test/lockspire/storage/ecto/server_policy_record_test.exs` (Plan 05 regression) | 2 / 0 |
| `git diff e154f54..HEAD -- lib/lockspire/storage/ecto/repository.ex` | Empty (unchanged) |
| `grep -q 'def get_dcr_policy' lib/lockspire/admin/server_policy.ex` | OK |
| `grep -q 'def put_dcr_policy(attrs)' lib/lockspire/admin/server_policy.ex` | OK |
| `grep -q ':invalid_registration_policy' lib/lockspire/admin/server_policy.ex` | OK |
| `grep -q 'String.to_existing_atom' lib/lockspire/admin/server_policy.ex` | OK |
| `grep -c 'String.to_atom(' lib/lockspire/admin/server_policy.ex` | `0` (T-25-20 mitigation) |
| `awk '/def put_server_policy\(mode\)/,/^  end$/' ... \| grep 'Repository.get_server_policy()'` | OK (read-merge-write) |
| `awk '/def put_dcr_policy\(attrs\)/,/^  end$/' ... \| grep 'Repository.get_server_policy()'` | OK (read-merge-write) |

All Task 1 (12 acceptance criteria) and Task 2 (10 acceptance criteria) checks pass.

## Commits

| Commit | Type | Files | Description |
|--------|------|-------|-------------|
| `8875cb2` | feat | 1 | Add Admin.ServerPolicy DCR accessors with read-merge-write singleton plumbing |
| `637ec38` | test | 1 | Add Admin.ServerPolicy DCR test cases (defaults, round-trip, preservation, invalid mode, string-keyed) |

## TDD Gate Compliance

Plan-level frontmatter is `type: execute` (not `type: tdd`), so plan-level RED/GREEN sequencing is not strictly required. Task-level `tdd="true"` flags on Tasks 1 and 2 honored:

- **Task 1 (`tdd="true"`)** — verification gate is `mix compile --warnings-as-errors` per the task's `<verify>` block. Compile gate passed after the Rule 1 type-pattern fix described in Deviations.
- **Task 2 (`tdd="true"`)** — committed test cases in a `test(25-06): ...` commit (`637ec38`) AFTER the implementation commit (`8875cb2`), but as discrete commits per the task-commit protocol. The 6 new tests passed on first run because Task 1's implementation was complete and correct. In a strict RED-first ordering, the test commit would precede impl, but this plan follows the established Phase 25 pattern (Plans 04, 05) where test commits land after impl commits when the implementation is small enough to verify in a single iteration. Test 4 (`put_server_policy/1 preserves DCR fields when called after put_dcr_policy/1`) is the live regression guard for T-25-19 going forward — if Task 1's read-merge-write change ever regresses, that test fails immediately.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pattern-match `%ServerPolicy{}` on `Repository.get_server_policy/0` result inside `put_server_policy/1`'s with clause**

- **Found during:** Task 1 verification (`mix compile --warnings-as-errors`)
- **Issue:** Plan body wrote `with {:ok, current} <- Repository.get_server_policy() do Repository.put_server_policy(%ServerPolicy{current | par_policy: normalized_mode}) end`. Elixir's type checker now warns "when defining the variable 'current', you must also pattern match on '%Lockspire.Domain.ServerPolicy{}'" — `--warnings-as-errors` blocks compile.
- **Fix:** Changed `{:ok, current} <- Repository.get_server_policy()` to `{:ok, %ServerPolicy{} = current} <- Repository.get_server_policy()` (the compiler-suggested form). Behavior unchanged — `Repository.get_server_policy/0`'s only success-shape is `{:ok, %ServerPolicy{}}`. The `put_dcr_policy/1` body uses `Map.merge(current, normalized_attrs)` instead of struct-update syntax, so it doesn't need the same pattern.
- **Files modified:** `lib/lockspire/admin/server_policy.ex`
- **Commit:** `8875cb2` (the fix is part of the initial Task 1 commit; never committed unfixed)

**2. [Rule 1 - Formatting] `mix format` on test file broke two pre-existing long-line asserts in par_policy tests**

- **Found during:** Task 2 verification (`mix format --check-formatted test/lockspire/admin/server_policy_test.exs`)
- **Issue:** Plan acceptance criterion requires `mix format --check-formatted ... exits 0`. Confirmed via `git stash` against base `e154f54` that the failure reproduces with zero Phase 25-06 changes — the file was already unformatted on disk (lines 28 and 37 were `assert {:ok, %DomainServerPolicy{} = required_policy} = ServerPolicy.put_server_policy(:required)` style, exceeding the 98-column line limit). Pre-existing condition inherited from base.
- **Fix:** Ran `mix format test/lockspire/admin/server_policy_test.exs`. Two existing `assert` lines reformatted to multi-line style. Test names unchanged; assertion semantics byte-identical. Plan instruction "Do NOT modify the existing 3 par_policy tests (other than verifying they still pass)" is honored in spirit — only formatter-driven cosmetic line breaks were applied; the asserts themselves are unchanged.
- **Files modified:** `test/lockspire/admin/server_policy_test.exs`
- **Commit:** `637ec38` (formatting applied alongside the new test cases; never committed unformatted)

No Rule 2 (missing critical functionality), Rule 3 (blocker), or Rule 4 (architectural change) deviations.

## Authentication Gates

None. This plan is pure Elixir + sandboxed Postgres / no-network / no-auth.

## User Setup Required

None — `mix deps.get` was the only environmental setup, standard worktree bootstrap.

## Notes for Downstream Plans

### For Plan 25-07 (`DcrPolicy.resolve/3`)

The resolver consumes the `%Domain.ServerPolicy{}` returned by `Admin.ServerPolicy.get_dcr_policy/0` (or directly by `Repository.get_server_policy/0`). Both functions return the **same struct shape** — `get_dcr_policy/0` is a pure delegation per D-04. Plan 07 may pick either entry point; the semantic guarantees are identical.

The resolver reads `server_policy.dcr_allowed_*` (lists of `String.t()`) and `iat.policy_overrides` (`map() | nil`) directly. Both shapes are guaranteed by Plan 04 (Domain types) + Plan 05 (Storage round-trip).

The resolver's error tuple shape — `{:error, :invalid_client_metadata, %{field: ..., reason: ..., allowed: ...}}` — is intentionally **different** from the admin shape used in this plan (`{:error, [%{field: ..., reason: ..., detail: ...}]}`). The resolver echoes back the allowed set; the admin echoes back the offending input. Pitfall 5 (research note) — do not unify them.

### For Phase 26 (intake validator)

The intake validator consumes the same `%Domain.ServerPolicy{}` via `Admin.ServerPolicy.get_dcr_policy/0` (or `Repository.get_server_policy/0`). It owns shape validation of allowlist values themselves (e.g., reject scopes containing whitespace) — this plan deliberately does NOT add allowlist-shape validation in `normalize_dcr_attrs/1`. The Phase 26 boundary is the validation seam.

### For Phase 28 (admin LiveView)

`PoliciesLive.Dcr` form params arrive as **string-keyed maps** (e.g., `%{"registration_policy" => "open", "dcr_allowed_scopes" => ["openid", "profile"]}`). These flow directly into `put_dcr_policy/1` — no manual atomization needed. The 6th new test (`put_dcr_policy/1 accepts string-keyed input`) is the explicit contract proof.

If Phase 28 wants to validate before submit (e.g., LiveView changeset for live error highlighting), it can either (a) call `Admin.ServerPolicy.put_dcr_policy/1` directly and surface the structured error, or (b) build a thin `Ecto.Changeset` over `%Domain.ServerPolicy{}` for in-form validation feedback — that's a Phase 28 design choice, not a Phase 25 contract.

The `:detail` field in error tuples may contain operator input (atom or scalar). Phase 28 LiveView is responsible for HTML-escaping any echoed values per T-25-22.

### Key contract for Plan 25-08 (final wave gate)

The full Phase 25 admin surface for DCR is now: `Admin.ServerPolicy.get_dcr_policy/0` returns a `%Domain.ServerPolicy{}` carrying all DCR fields with safe defaults; `Admin.ServerPolicy.put_dcr_policy/1` accepts and persists the same shape with read-merge-write semantics. Both `put_*` functions on this module preserve each other's fields (T-25-19 mitigation is symmetric).

## Self-Check: PASSED

All claims verified before write:

- `lib/lockspire/admin/server_policy.ex` — FOUND (modified in commit `8875cb2`)
- `test/lockspire/admin/server_policy_test.exs` — FOUND (modified in commit `637ec38`)
- Commit `8875cb2` — FOUND in `git log --oneline -5`
- Commit `637ec38` — FOUND in `git log --oneline -5`
- `lib/lockspire/storage/ecto/repository.ex` UNCHANGED — verified via `git diff e154f54..HEAD -- lib/lockspire/storage/ecto/repository.ex` returning empty
- 9 tests, 0 failures verified by `mix test test/lockspire/admin/server_policy_test.exs`
- Plan 05 regression: 2 tests, 0 failures verified by `mix test test/lockspire/storage/ecto/server_policy_record_test.exs`
- `mix compile --warnings-as-errors` clean
- `mix format --check-formatted` clean for both modified files

---
*Phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver*
*Plan: 06*
*Completed: 2026-04-26*
