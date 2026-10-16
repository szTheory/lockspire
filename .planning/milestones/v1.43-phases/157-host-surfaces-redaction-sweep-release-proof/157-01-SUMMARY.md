---
phase: 157-host-surfaces-redaction-sweep-release-proof
plan: 01
subsystem: security
tags: [redaction, signing-keys, ecto, telemetry, leak-sweep]
status: complete
requires:
  - phase: 156-legacy-migration-kek-rotation-plaintext-refusal
    provides: sealed key envelopes, KeySet, Admin.Keys.reencrypt/encryption_status
provides:
  - KeyMaterialMatcher single leak proof point (refute_leak!/3)
  - sensitive repo reads for every key-column path, column-free JWKS reads
  - redacted schema field, params-free changeset, Redaction key drop sets and envelope value guard
  - full canary sweep across admin, consumers, operator tasks and admin LiveViews
affects: [157-05, 157-06]
tech-stack:
  added: []
  patterns:
    - "struct(key, ^public_fields) select keeps a column out of SQL and result"
    - "sensitive: true on every query that selects or binds a secret column"
key-files:
  created:
    - test/support/key_material_matcher.ex
    - test/lockspire/storage/ecto/signing_key_record_test.exs
  modified:
    - lib/lockspire/storage/ecto/repository/signing_key_store.ex
    - lib/lockspire/storage/ecto/signing_key_record.ex
    - lib/lockspire/redaction.ex
    - test/lockspire/security/key_material_leak_test.exs
    - test/lockspire/redaction/redaction_test.exs
key-decisions:
  - "D-18 held: list_active_keys and list_publishable_keys select every field except private_jwk_encrypted (no sensitive fallback needed); they keep Ecto logs and telemetry"
  - "Private column removed from the map handed to cast (not just from the permit list) because Ecto keeps all raw params in changeset.params"
requirements-completed: [RED-01, SAFE-01]
commits: 4
plan_head_before: e585bf2ccc22bfc500f891945704d012f4bcb22e
plan_head_after: d77f2748de11092032307b950509c44b369e01ea
actuals:
  tokens: 36000
  tasks: 3
  commits: 4
duration: 25 min
completed: 2026-10-16
---

# Phase 157 Plan 01: Storage and Metadata Key Redaction Summary

**Every signing-key column read is silent at the repo boundary or never selects the column, the schema and Redaction hide the bytes, and one structural matcher proves a full admin/consumer/operator sweep leaks nothing.**

## What Was Built

- `Lockspire.TestSupport.KeyMaterialMatcher` (`test/support/key_material_matcher.ex`).
- Store: `sensitive: true` on `publish_key` insert, `fetch_active_signing_key`, `fetch_signing_key_by_id`, `list_decryption_keys`, `locked_key`, `active_keys_for_update`; `list_signing_keys` defaults to sensitive (explicit `sensitive: false` still honoured). JWKS reads (`list_active_keys`, `list_publishable_keys`) use a column-omitting `struct/2` select.
- Schema: `redact: true`, derive kept, column applied with `put_change` and removed from the cast params.
- Redaction: nine new drop names (atom and string) in both sets plus an `LSK` header value clause; `kid`, `kek_id`, `previous_kek_id`, `key_id` untouched.
- Sweep: matcher canary tests, tracer (sealed key by id signs an ID token), store-path test, and a full sweep over generate/publish/activate/list, six consumers, `encryption_status`, `reencrypt`, doctor `key_encryption`, a changeset error, a rescued error, `KeysLive` (index and show) and `OverviewLive` HTML and assigns.

## Matcher public API (for 157-05 and 157-06)

- `KeyMaterialMatcher.refute_leak!(label, subject, secrets)` where `secrets` is a list of binaries; raises `ExUnit.AssertionError` naming the label and match kind (never the secret).
- `forms/1`, `markers/0`, `needles/1` are exposed for reuse.
- Structural walks read real struct fields; to check what `inspect` shows for a struct, pass `inspect(struct)`. A changeset's `changes` legitimately holds the bytes, so check `params`, `errors` and `inspect(changeset)` instead.

## TDD Gate Compliance

- RED (`038d2567`): 6 failing tests across signing_key_record_test, redaction_test and the store-path sweep, all on the planned assertions (changeset params leaked the envelope; Redaction kept key names and envelope values; fetch/list repo events carried the key column). Semantic assessment: targets executed and failed for the intended reasons.
- GREEN (`3f8acbe4`): all pass. No REFACTOR commit.
- Task 1 (tracer) was also proven RED before its store change: the tracer failed with "matched envelope_header" until `fetch_signing_key_by_id` became sensitive.
- Mutation check: removing `sensitive: true` from `list_decryption_keys` made two sweep tests fail, so the sweep is not vacuous (change reverted).

## Leaks fixed (D-26)

None beyond the planned changes. The sweep found no leak in the admin, LiveView, audit, telemetry or operator-task surfaces. The one finding during development (changeset `params` carried the envelope) was fixed inside the planned schema change, with `signing_key_record_test.exs` as the regression test.

## Deviations from Plan

**1. [Rule 1 - Bug] cast params still carried the key bytes**
- **Found during:** Task 2 GREEN
- **Issue:** removing the column from the `cast` permit list is not enough; Ecto stores every raw param in `changeset.params`.
- **Fix:** `Map.delete(Map.from_struct(key), :private_jwk_encrypted)` before `cast`, with `put_change` applied afterwards.
- **Files modified:** `lib/lockspire/storage/ecto/signing_key_record.ex`
- **Commit:** 3f8acbe4

**2. [Plan wording] put_change acceptance grep**
- The conditional is a small private helper (`put_private_material/2`), so `grep -c "put_change(:private_jwk_encrypted"` matches the call as `put_change(changeset, :private_jwk_encrypted, bytes)`. Behavior matches the plan (applied only for binaries, nil leaves no change).

**3. [Test adjustment] store-path event assertion**
- The plan's "zero `[:repo, :query]` events" is refined to "zero events whose query text names the key column, and zero matcher hits in any event": transaction BEGIN/COMMIT and status UPDATEs legitimately still emit repo events and never bind the column.

**Total deviations:** 3 (1 bug fix, 2 clarifications). **Impact:** none on scope.

## Known Stubs

None.

## Threat Flags

None. T-157-SC: no dependency added (`mix.exs` and `mix.lock` untouched).

## Verification

- `mix format --check-formatted`, `mix compile --warnings-as-errors --force`, `mix test.fast` (1758 tests, 0 failures) on 1.19.5-otp-28.
- No change to `PRODUCT.md`, `lib/lockspire/web`, protocol consumers or `PrivateJwk`.

## Self-Check: PASSED
