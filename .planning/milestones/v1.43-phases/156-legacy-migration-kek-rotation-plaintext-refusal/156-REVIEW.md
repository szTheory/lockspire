---
phase: 156-legacy-migration-kek-rotation-plaintext-refusal
reviewed: 2026-10-16T00:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - lib/lockspire/admin.ex
  - lib/lockspire/admin/keys.ex
  - lib/lockspire/admin/keys/encryption_status.ex
  - lib/lockspire/admin/keys/reencrypt.ex
  - lib/lockspire/install/repo_runner.ex
  - lib/lockspire/install/verify.ex
  - lib/lockspire/protocol/private_jwk.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/storage/ecto/repository/signing_key_store.ex
  - lib/lockspire/storage/key_store.ex
  - lib/mix/tasks/lockspire.doctor.key_encryption.ex
  - lib/mix/tasks/lockspire.keys.reencrypt.ex
  - test/lockspire/admin/keys_encryption_status_test.exs
  - test/lockspire/admin/keys_reencrypt_test.exs
  - test/lockspire/architecture_fitness_test.exs
  - test/lockspire/install/repo_runner_test.exs
  - test/lockspire/install/verify_test.exs
  - test/lockspire/protocol/envelope_signing_consumers_test.exs
  - test/lockspire/protocol/private_jwk_test.exs
  - test/lockspire/security/key_encryption_telemetry_test.exs
  - test/lockspire/security/key_material_leak_test.exs
  - test/lockspire/storage/reencrypt_concurrency_test.exs
  - test/mix/tasks/lockspire_doctor_key_encryption_test.exs
  - test/mix/tasks/lockspire_keys_reencrypt_test.exs
  - test/support/key_encryption_helpers.ex
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 156: Code Review Report

**Reviewed:** 2026-10-16
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

The engine design holds up. Each row gets one transaction and one `FOR UPDATE` lock, classification happens after the lock, and there is a compare-and-swap guard. The refusal path in `PrivateJwk` runs before any parser. Telemetry metadata is built from allowlisted fields. The CLI prints only kids, KEK ids and counts, and `KeySet`, `SigningKey` and `SigningKeyRecord` all have redacting `Inspect` implementations. I found no deadlock, double-wrap or refusal-bypass path.

The main defect is a plaintext leak. The sensitive-read protection is only half applied, and the leak test cannot see the remaining channel.

## Critical Issues

### CR-01: Row lock SELECT (and the listing reads) leak stored private key bytes through Ecto query telemetry

**File:** `lib/lockspire/storage/ecto/repository/signing_key_store.ex:245-250` (also `:35-44`, used by `Reencrypt.dry_run/2` and `Keys.encryption_status/0`)
**Issue:** `sensitive_locked_key/2` passes `sensitive: true`, and `Support.repo_options/1` turns that into `log: false`. That only silences the Logger line. `ecto_sql` (`deps/ecto_sql/lib/ecto/adapters/sql.ex:1297-1306`) still runs `:telemetry.execute(event_name, ..., %{result: result, params: ...})` for every query unless `telemetry_event: nil` is passed. `result` holds the selected rows. The locked row is read by the SELECT, so for every legacy row the `[:my_app, :repo, :query]` event carries the full plaintext JWK, including `d`. For envelope rows it carries the sealed bytes.

The author knew about this channel. `replace_material/5` passes `telemetry_event: nil` on the `update_all`, and its comment says "query logging and the repo query telemetry event are both turned off". The lock SELECT is the call that actually returns the plaintext, and it does not pass `telemetry_event: nil`.

Any host handler attached to the repo query event leaks the key. Typical handlers are a LiveDashboard metrics reporter, an Ecto OpenTelemetry instrumenter, or a debug logger that inspects metadata. The same exposure applies to `list_signing_keys/2`. It runs in `--dry-run`, `--check`, doctor and `Install.Verify`, and it does not use `sensitive` at all. That makes the plaintext also visible in the Logger query line when `log` is on only for params, and in telemetry `result`.

`key_material_leak_test.exs:168-172` only inspects `md[:params]` and `md[:cast_params]` of repo events. It never looks at `md[:result]`, so the test passes while the leak exists.

**Fix:**
```elixir
# signing_key_store.ex
defp sensitive_locked_key(repo, id),
  do:
    SigningKeyRecord
    |> where([key], key.id == ^id)
    |> lock("FOR UPDATE")
    |> then(&Support.one(repo, &1, sensitive: true, telemetry_event: nil))
```
Make `Support.repo_options/1` apply `telemetry_event: nil` whenever `sensitive: true` is set, so the two protections cannot be applied separately. Pass `sensitive: true` from the reencrypt listing paths (`list_signing_keys` when called by status or dry-run). Alternatively, add a `list_signing_keys_for_status` that selects only what `assess/2` needs and still redacts its result. Extend the leak test to include `inspect(md[:result])` in `repo_param_text`, and assert it contains no `d` value and no `LSK`.

## Warnings

### WR-01: `mix lockspire.doctor key_encryption` exits 0 when `:reject` is set and legacy rows remain (signing is broken)

**File:** `lib/mix/tasks/lockspire.doctor.key_encryption.ex:91`
**Issue:** `report_rows/0` treats only `unknown_kek` and `undecryptable` as `:broken`. With `legacy_plaintext: :reject` and `status.legacy > 0`, every request that needs those keys fails with `:plaintext_key_refused`. `Install.Verify.key_storage_result/1` correctly reports this case as an error, so doctor and verify disagree. That contradicts the single-source-of-truth rule (D-19) and the doctor's own "something is broken now" contract. The help text also tells operators that legacy rows exit zero.
**Fix:**
```elixir
broken? =
  status.unknown_kek != %{} or status.undecryptable > 0 or
    (status.legacy_plaintext == :reject and status.legacy > 0)
if broken?, do: :broken, else: :ok
```
Update the help text and the moduledoc, and add a doctor test for `:reject` with a legacy row.

### WR-02: Leak test does not cover the telemetry `result` field or the dry-run and status read paths

**File:** `test/lockspire/security/key_material_leak_test.exs:107-180`
**Issue:** The test attaches a repo query handler but only examines `params` and `cast_params`. Neither `dry_run: true` nor `encryption_status/0` is run inside the captured window, so the listing reads are not checked. It also pins `legacy` and `sealed_sentinel_row` fixtures but never asserts on the SELECT result. This is why CR-01 is invisible.
**Fix:** Include `inspect(md[:result], limit: :infinity)` in the repo surface text. Add `Keys.reencrypt(dry_run: true)` and `Keys.encryption_status()` to the captured block, and refute `@sentinel_d` and `"LSK"` in all of it.

### WR-03: A stranded retired row makes the real run exit 1 forever while the message says "rerunning is safe"

**File:** `lib/mix/tasks/lockspire.keys.reencrypt.ex:172-199` (and `:314-317`)
**Issue:** Per D-11a, a retired row the engine cannot seal is stranded and "does not block readiness". `report_run/2` still counts it in `failed`, prints "fix: already retired; does not block readiness", then raises "1 key was not re-encrypted. All other keys were saved; rerunning is safe." A rerun can never clear it, so any deploy script or CI step that runs `mix lockspire.keys.reencrypt` will fail permanently once such a row exists. `--dry-run` has the same behavior. The operator has to use `--check` to learn the install is actually ready.
**Fix:** Either do not count failures whose `status == :retired` and whose reason is in `@unsealable_reasons` toward the exit code, or change the raise text to say "run `--check`; retired keys listed as stranded do not block readiness". Add a task test for this combination.

## Info

### IN-01: Test-only options are reachable from the public `Keys.reencrypt/1`

**File:** `lib/lockspire/admin/keys/reencrypt.ex:39-40`, `lib/lockspire/storage/ecto/repository/signing_key_store.ex:200-204`
**Issue:** `after_lock` and `page_size` are accepted from any caller of `Admin.Keys.reencrypt/1`. The hook runs inside the row transaction and receives the full `SigningKey`, including `private_jwk_encrypted`. This is only a local call, so it is not a security boundary, but the hook widens the surface where key bytes can be handed to arbitrary code. `page_size` is not validated, so `0` or a negative value reaches `list_signing_key_refs`, fails its `limit > 0` guard, and surfaces as a misleading `storage_error`.
**Fix:** Validate `page_size` as a positive integer, falling back to the default. Document `after_lock` as test-only, or gate it on `Mix.env() == :test`.

### IN-02: `Verify.safely/1` now rescues `MatchError` and returns `Exception.message/1`

**File:** `lib/lockspire/install/verify.ex` (the `safely/1` rescue list)
**Issue:** `Exception.message(%MatchError{})` inspects the unmatched term. The old `{:ok, statuses, _} = with_repo(...)` match that motivated adding it is gone, because `RepoRunner` now returns tagged results. The remaining reason to keep `MatchError` is weak. Any future match failure on a term containing connection options or key rows would be printed into the verify output.
**Fix:** Drop `MatchError` from the rescue list. If it is kept, replace the message with a fixed string such as "unexpected result".

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
