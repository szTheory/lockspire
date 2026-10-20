---
phase: 159-key-encryption-key-setup-dx
reviewed: 2026-10-19T00:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - docs/install-and-onboard.md
  - docs/upgrading/signing-key-encryption.md
  - lib/lockspire/application.ex
  - lib/lockspire/config.ex
  - lib/lockspire/generators/install.ex
  - lib/lockspire/generators/kek_snippet.ex
  - lib/lockspire/install/verify.ex
  - lib/lockspire/security/key_encryption/key_set.ex
  - lib/mix/tasks/lockspire.doctor.key_encryption.ex
  - lib/mix/tasks/lockspire.gen.kek.ex
  - lib/mix/tasks/lockspire.keys.reencrypt.ex
  - scripts/acceptance/clean_room/build_provider.py
  - test/integration/install_generator_test.exs
  - test/integration/phase133_provider_install_test.exs
  - test/lockspire/config_key_encryption_test.exs
  - test/lockspire/install/verify_test.exs
  - test/lockspire/kek_guidance_contract_test.exs
  - test/lockspire/upgrade_guide_contract_test.exs
  - test/mix/tasks/lockspire_gen_kek_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-10-19
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

I reviewed the diff against 6d6653fd. I found no key material leaking into logs, errors or output. The `{:system, var}` error path names only the variable, and `gen.kek` prints only its own generated value. `KeySet.valid_id?` is shared correctly, and the `prod_block` id check blocks injection through `--id`. The findings below are robustness and quality issues. I read the test files only lightly, so the Warnings and Info items cover the lib, docs and script changes only.

## Warnings

### WR-01: Clean-room boundary audit silently weakened for the non-install path

**File:** `scripts/acceptance/clean_room/build_provider.py:257-261`
**Issue:** `audit_boundary(child, package_root)` is replaced by an inline vendor inventory comparison. This drops the `assert_below(vendor, child, ...)` check, which guards against a vendor path that escapes the child. It also drops the host-source audit. The comment says the overlay audit does not apply without the installer. The `assert_below` check does not depend on the overlay, though, so a real guard was removed for the `install=False` path used by `check_gen_kek`.
**Fix:** Keep the path guard. Either split `audit_boundary` into a vendor part and an overlay part and call the vendor part here, or add `assert_below(vendor, child, "provider vendor dependency")` after the inventory check.

### WR-02: `{:system, var}` values are not normalised, so a stray newline or space fails with a misleading error

**File:** `lib/lockspire/config.ex:279-283`
**Issue:** The env value is only checked for `!= ""`. A value that is only whitespace passes the check, then fails in `KeySet` with a generic base64 error (for example `invalid_base64`) that does not name the environment variable. A common secret-manager mistake (a trailing newline) therefore produces an error that does not point at the variable. The docs warn about this, but the runtime error does not help the operator find the cause. This is also a divergence from the `missing_env` path, which does name the variable.
**Fix:** Pass the variable name through for decode failures on `{:system, var}` entries. Alternatively, treat a whitespace-only value as `:missing_env`. The docs already say not to trim, so trimming is not recommended.

## Info

### IN-01: `gen.kek --id` for rotation prints a block that does not match the rotation guide

**File:** `lib/mix/tasks/lockspire.gen.kek.ex:84-97`, `docs/upgrading/signing-key-encryption.md` (rotation step 1)
**Issue:** The upgrade guide tells operators to run `mix lockspire.gen.kek --id 2026-07` to get the new rotation key. The task prints `LOCKSPIRE_KEY_ENCRYPTION_KEY=...` and a full `:prod` block using that same variable name. The guide says the new key belongs in `LOCKSPIRE_KEY_ENCRYPTION_KEY_NEXT`. Copying the output as-is would overwrite the current key's variable.
**Fix:** Either add a `--env VAR` option, or note in the guide that only the generated value should be used, for example with `--raw`.

### IN-02: `--raw` silently ignores `--id`, and the default output has a double trailing blank line

**File:** `lib/mix/tasks/lockspire.gen.kek.ex:29-31`
**Issue:** `--raw --id X` validates the id and then discards it. `prod_block/2` ends with a newline, and `Mix.shell().info` adds another.
**Fix:** Reject `--raw` combined with `--id`, or document that `--raw` ignores `--id`. Trim the trailing newline of the block before printing.

---

_Reviewed: 2026-10-19_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
