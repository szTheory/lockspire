---
phase: 160-admin-key-protection-missing-kek-copy
reviewed: 2026-10-19T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/lockspire/web/live/admin/keys_live/protection.ex
  - lib/lockspire/web/live/admin/keys_live/index.ex
  - lib/lockspire/admin.ex
  - test/lockspire/web/live/admin/keys_live/protection_test.exs
  - test/lockspire/web/live/admin/keys_live_test.exs
  - PRODUCT.md
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-10-19
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Read-only review. Tests were not run. The implementation is mostly sound. The `:key_encryption_not_configured` clause is inserted before the catch-all `{:error, _reason}`, so every other generation error behaves as before. The `rescue`/`catch` in `load_key_protection/0` fails toward "Unknown" and never toward healthy. No KEK material, KEK id list or env var name reaches the page. Only `current_kek_id` is interpolated, and HEEx escapes it. The `{:invalid_config, message}` message is discarded in `summarize/1`.

The 7-state precedence has real gaps against the `EncryptionStatus` field semantics (WR-01, WR-02).

## Warnings

### WR-01: Unreadable legacy rows are reported as "unencrypted" with a fix that cannot work

**File:** `lib/lockspire/web/live/admin/keys_live/protection.ex:45-46`
**Issue:** `EncryptionStatus.classify_unsealable/4` bumps `:legacy` for `:unreadable_legacy` and `:kid_mismatch` rows with a nil kek id. This covers corrupt bytes and a mismatched kid. `Reencrypt.assess` marks these rows unsealable, so `mix lockspire.keys.reencrypt` cannot encrypt them. `classify/1` only looks at `legacy > 0`, so it shows the warning-tone "Some keys are stored unencrypted ... run reencrypt". The operator is sent to a command that will not resolve it. The `:unreadable` copy ("Do not delete them") is lost for those rows. `status.pending` carries `state: :unsealable_legacy` for exactly these rows, but the summarizer ignores it.
**Fix:** In `classify/1`, check `Enum.any?(status.pending, &(&1.state == :unsealable_legacy))` and map it to `:unreadable`, before the `legacy` check. Alternatively treat `legacy > sealable_legacy_count` as unreadable.

### WR-02: Unconfigured key set hides existing encrypted or unreadable keys

**File:** `lib/lockspire/web/live/admin/keys_live/protection.ex:29`
**Issue:** `{:ok, %{configured: false}}` returns `:not_set_up` unconditionally. With a nil keyset, `EncryptionStatus` still counts envelope rows as `unknown_kek` and unreadable rows as `undecryptable`. If the KEK was removed from config while encrypted keys exist, the page says only "Not set up ... create one with mix lockspire.gen.kek". A new key will not open the existing envelopes. Signing and decryption with those keys fails, and the "Do not delete them" and doctor guidance never appears.
**Fix:** In the `configured: false` clause, return `:unreadable` (or a dedicated state) when `unknown_kek != %{}` or `undecryptable > 0`. Otherwise return `:not_set_up`. Alternatively, extend the `:not_set_up` copy to mention existing keys.

### WR-03: Invalid KEK config still crashes the LiveView on key generation

**File:** `lib/lockspire/web/live/admin/keys_live/index.ex:221-259` (via `lib/lockspire/admin/keys.ex:85`)
**Issue:** `Admin.generate_key/1` calls `Config.key_encryption_keyset/0`. On a persistent_term cache miss this falls through to `key_encryption!()`, which raises `ArgumentError` for invalid config. The page now shows "Setup needs attention" for that same condition, but clicking Generate crashes the LiveView process (a remount loop or error page). The new `:key_encryption_not_configured` clause covers only the nil case, so the invalid-config path is inconsistent.
**Fix:** In `Keys.generate_key/1`, rescue `ArgumentError` and return `{:error, {:invalid_config, msg}}`, as `fresh_keyset/0` does. Then add a LiveView clause with fixed copy that points to `mix lockspire.doctor.key_encryption`, without echoing the message.

### WR-04: Reject-mode legacy keys show only a warning

**File:** `lib/lockspire/web/live/admin/keys_live/protection.ex:45-46, 82-91`
**Issue:** `EncryptionStatus.broken_now?/1` treats `legacy_plaintext: :reject` with `legacy > 0` as broken now, because those keys are unreadable at runtime. The summarizer deliberately ignores `legacy_plaintext`, so this case shows `:unencrypted` with a warning tone and the copy "usually because an older Lockspire version created them". Doctor and `Install.Verify` gate on the same predicate and report a failure. The admin page therefore disagrees with them, which is the disagreement `EncryptionStatus` was designed to prevent.
**Fix:** If `legacy_plaintext == :reject and legacy > 0`, classify as `:unreadable`. Update the "legacy_plaintext do not change the state" test at `protection_test.exs:120` accordingly.

## Info

### IN-01: Bare `rescue _exception` hides bugs in the summarizer

**File:** `lib/lockspire/web/live/admin/keys_live/index.ex:192-198`
**Issue:** The rescue wraps `Protection.summarize/1` as well as the status call. A programming error in `summarize` or `classify` (for example a `FunctionClauseError`) silently becomes "Unknown" with no log. The intent is not to log config text, but this also hides defects. It fails safe, so this is not a blocker.
**Fix:** Rescue only around `Admin.encryption_status()`. Optionally emit a telemetry event or log `inspect(exception.__struct__)` (the module name only) so defects stay visible.

### IN-02: Private-key decryption on every page load and retry

**File:** `lib/lockspire/web/live/admin/keys_live/index.ex:186, 193`
**Issue:** `Admin.encryption_status/0` loads all rows with `sensitive: true` and decrypts each in `read_stored`. It runs on every `handle_params`, retry and successful generate. This is an extra exposure of plaintext key material in a web process and a cost on the request path. It is not a leak: only counts and ids are returned.
**Fix:** Acceptable for v1. Consider a non-decrypting status variant, or caching the result.

---

_Reviewed: 2026-10-19_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
