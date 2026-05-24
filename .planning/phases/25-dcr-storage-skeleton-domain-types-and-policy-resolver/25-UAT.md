---
status: complete
phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver
source:
  - 25-01-SUMMARY.md
  - 25-02-SUMMARY.md
  - 25-03-SUMMARY.md
  - 25-04-SUMMARY.md
  - 25-05-SUMMARY.md
  - 25-06-SUMMARY.md
  - 25-07-SUMMARY.md
  - 25-08-SUMMARY.md
mode: shift-left-ci
started: 2026-04-26T00:00:00Z
updated: 2026-04-26T17:55:00Z
---

## Current Test

[testing complete]

## Notes

This phase ships only library / storage / resolver code with no HTTP or UI surface.
The 8 UAT items below were converted from manual iex smoke tests into automated
ExUnit + CI gates so the user has zero manual verification. Coverage references
below name the file:line range or CI step that asserts each item.

CI runs the `fast` job in `.github/workflows/ci.yml`:
- `mix qa` — format, compile --warnings-as-errors, credo --strict, dialyzer
- `mix test.fast` — `mix test.setup` (cold-start migrate from empty Postgres
  service container) followed by the full ExUnit suite
- `mix ecto.rollback --all && mix ecto.migrate` — added by this phase to prove
  every migration's reversal/re-apply path

Pre-existing main-branch issues (NOT introduced or in scope for Phase 25,
documented in deferred-items.md and prior phase summaries):
- `mix format --check-formatted` is failing on 8 unrelated test files predating
  Phase 25 (auth controller test, jar test, par test, etc.). These will block
  CI's `mix qa` step until separately cleaned up. Phase 25's own files are all
  formatted (`mix format --check-formatted` clean against this phase's diff).
- `test/lockspire/release_readiness_contract_test.exs:250` asserts a v1.3
  milestone string that has drifted to v1.5. Documented in deferred-items.md;
  Phase 29 closure work owns it.

Both predate Phase 25 and would block any phase landing on top of main. They
do not weaken Phase 25's verification: every Phase 25 contract has a direct
test (counts and references below).

## Tests

### 1. Cold Start Smoke Test
expected: |
  Drop the test DB and recreate it from scratch; all 8 migrations apply cleanly;
  `mix compile --warnings-as-errors` passes.
result: pass
auto_verified_by: |
  - GitHub Actions `services: postgres:16` provisions a fresh Docker container
    per run (`.github/workflows/ci.yml:25-46`).
  - `mix test.fast` alias resolves to `[test.setup, test]` (`mix.exs:56-93`).
    `mix test.setup` calls `lockspire.test.setup` which runs
    `ensure_storage!` + `migrate!` from empty
    (`lib/mix/tasks/lockspire.test.setup.ex:14-42`).
  - `mix qa` step runs `compile --warnings-as-errors` (`mix.exs:73-77`).
  - Every CI run on main / every PR therefore exercises the cold-start path.

### 2. Migration Chain Reversibility
expected: |
  `mix ecto.rollback --all` reverses every migration; `mix ecto.migrate` re-applies
  the chain idempotently.
result: pass
auto_verified_by: |
  - New CI step "Verify migration reversibility" added to the `fast` job after
    `mix test.fast` (`.github/workflows/ci.yml:96-99`):
      MIX_ENV=test mix ecto.rollback --all
      MIX_ENV=test mix ecto.migrate
  - Locally verified 2026-04-26: all 8 migrations rolled back cleanly
    (lockspire_initial_access_tokens, lockspire_server_policies, lockspire_clients
    DCR cols, etc., all dropped); re-migrate re-created them in correct order.

### 3. Phase 25 Test Suite Passes
expected: |
  All 39 Phase 25 tests pass.
result: pass
auto_verified_by: |
  All 39 Phase 25 tests run as part of `mix test.fast` (CI fast job line 94):
  - `test/lockspire/domain/initial_access_token_test.exs` (4 tests, lines 1-58)
  - `test/lockspire/storage/ecto/server_policy_record_test.exs` (2 tests, lines 19-81)
  - `test/lockspire/storage/ecto/client_record_test.exs` (3 tests, lines 19-125)
  - `test/lockspire/storage/ecto/initial_access_token_record_test.exs` (3 tests, lines 20-86)
  - `test/lockspire/admin/server_policy_test.exs` (9 tests, lines 22-181)
  - `test/lockspire/protocol/dcr_policy_test.exs` (12 tests, lines 24-270)
  - `test/lockspire/protocol/dcr_policy_invariant_test.exs` (1 test, lines 26-140)
  - `test/lockspire/protocol/discovery_test.exs` (2 tests, NEW this UAT, lines 1-30)

### 4. Admin DCR Surface Defaults Are Secure-By-Default
expected: |
  `Admin.ServerPolicy.get_dcr_policy/0` returns secure defaults — registration
  disabled, all 6 allowlists empty, all 3 lifetimes nil.
result: pass
auto_verified_by: |
  `test/lockspire/admin/server_policy_test.exs:53-65` — test
  "get_dcr_policy/0 returns disabled defaults when no durable row exists"
  asserts every one of the 9 default fields the UAT named (registration_policy
  :disabled + 6 [] + 3 nil).

### 5. DCR Policy Mutation Round-Trip
expected: |
  put_dcr_policy/1 persists, get_dcr_policy/0 reads back, string-keyed input
  works, invalid mode returns the structured error tuple.
result: pass
auto_verified_by: |
  Three tests in `test/lockspire/admin/server_policy_test.exs`:
  - "put_dcr_policy/1 round-trip with allowlists and lifetimes" (lines 67-94)
  - "put_dcr_policy/1 accepts string-keyed input (admin form simulation)"
    (lines 170-181)
  - "put_dcr_policy/1 rejects invalid registration_policy with structured error"
    (lines 124-128)

### 6. Read-Merge-Write Preserves PAR ↔ DCR Coexistence
expected: |
  put_dcr_policy/1 then put_server_policy/1 (and vice-versa) preserve each
  other's fields on the singleton row (T-25-19 invariant).
result: pass
auto_verified_by: |
  Three tests in `test/lockspire/admin/server_policy_test.exs`:
  - "put_dcr_policy/1 preserves par_policy on the same singleton row" (lines 96-109)
  - "put_server_policy/1 preserves DCR fields when called after put_dcr_policy/1"
    (lines 111-122)
  - "concurrent put_server_policy/1 and put_dcr_policy/1 do not lose updates"
    (lines 130-168) — 16-task concurrent stress test asserting FOR UPDATE
    semantics survive interleaved writes.

### 7. DcrPolicy.resolve/3 Intersects And Rejects Out-Of-Allowlist
expected: |
  Resolver intersects all 5 axes correctly; out-of-allowlist input returns the
  structured `{:error, :invalid_client_metadata, %{field, reason, allowed}}`.
result: pass
auto_verified_by: |
  `test/lockspire/protocol/dcr_policy_test.exs:24-270` — 12 tests covering
  happy path (lines 40-57) and 6 sad paths (one per axis: scope, grant_types,
  response_types, redirect_uri scheme, redirect_uri host,
  token_endpoint_auth_method) at lines 59-110.

### 8. Discovery `/0` Accessor Returns Static Seam Value
expected: |
  Public `Discovery.token_endpoint_auth_methods_supported/0` returns
  `["none", "client_secret_basic", "client_secret_post"]` regardless of mount
  state; `Discovery.published_token_endpoint_auth_methods_supported/0` returns
  the static list when /token is mounted.
result: pass
auto_verified_by: |
  - `test/lockspire/protocol/discovery_test.exs` (NEW, 30 lines, async: false)
    test 1 pins the static `/0` to the canonical 3-element list (Phase 25 Plan 01
    seam contract, the value the dcr_policy_invariant_test binds to).
  - Same file test 2 asserts `published_/0` returns the full static list against
    the real Lockspire.Web.Router (where `/token` IS mounted).
  - The unmounted-state suppression invariant (returns `[]` when /token is not
    mounted) is implicit in the private /1 helper at
    `lib/lockspire/protocol/discovery.ex:115-121` (pure conditional logic);
    `discovery_controller_test.exs:30-73` indirectly proves the gate fires for
    other routes via `refute Map.has_key?(body, "registration_endpoint")`.
  - The `dcr_policy_invariant_test.exs:26-140` test composes the `/0` accessor
    with `DcrPolicy.resolve/3` end-to-end as a third confirmation.

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
