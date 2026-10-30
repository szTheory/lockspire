---
phase: 175-accepted-baseline-verifier-compatibility-contract
reviewed: 2026-10-25T19:58:03Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - test/integration/client_secret_jwt_legacy_age_test.exs
  - test/lockspire/security/client_secret_verifier_compatibility_test.exs
  - test/lockspire/security/client_secret_verifier_contract_test.exs
  - test/support/client_secret_verifier_fixtures.ex
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
snapshot_sha: fae04f99b2f85c2fb1a9b301932c8d1c98d5fd5d
source_sha256:
  test/integration/client_secret_jwt_legacy_age_test.exs: 9cc57a31ebc5ed189a1fe41618aaa122447c8332758a96c5f7a58087b94f91c6
  test/lockspire/security/client_secret_verifier_compatibility_test.exs: 8e037f91eeebc18766f492d88f3d7e000649556131e2f3103160ea053408f3ea
  test/lockspire/security/client_secret_verifier_contract_test.exs: 534972a4119a76684c48f3a2ef31b8bbbd846dcceaec3cdf0273036286cbf573
  test/support/client_secret_verifier_fixtures.ex: 47cf37d4e6cd482ff554511da50f22b09847128a53f41ab66c03ce9c448fcb37
---

# Phase 175: Code Review Report

**Reviewed:** 2026-10-25T19:58:03Z  
**Depth:** standard  
**Files Reviewed:** 4  
**Status:** issues_found

## Summary

Reviewed the four frozen source files against the Phase 175 qualification and contract. Persisted-caller tests cover the named authentication and lifecycle cases, and the metadata fixtures authenticate ciphertext before safe term decoding. The contract validator has a false-green path when qualification input hashes are removed; the future-age migration decision also lacks a direct assertion through the metadata-reader path.

## Critical Issues

### CR-01 [BLOCKER]: Validator accepts qualification evidence with no hashed source files

**File:** `test/lockspire/security/client_secret_verifier_contract_test.exs:383-387`
**Issue:** `Enum.all?/2` returns true for an empty collection. As a result, removing all entries from `qualification["compatibility_tests"]["tested_files_sha256"]` leaves the SHA string equality checks intact and lets `valid_qualified_inputs?/2` return true without checking that any source file matches the qualified metadata-reader source. Removing only one required entry also passes because the validator never requires the complete expected file set. This can make the semantic contract validator report `:ok` for qualification evidence that is no longer bound to its tested source inputs.
**Fix:** Require the exact expected path set (at minimum the compatibility test and fixture files) before checking digests, and reject missing, extra, or empty maps. Add mutation tests that delete one entry and all entries and assert validation fails.

## Warnings

### WR-01 [WARNING]: Future-dated metadata is not rejected by the migration-decision helper

**File:** `test/support/client_secret_verifier_fixtures.ex:133-149`
**Issue:** `metadata_deadline/1` derives a future deadline from an authenticated future `signed_at_ms`, and `expired_at?/2` returns `false` while that deadline is ahead of `now_ms`. The separate future-age test at `client_secret_verifier_compatibility_test.exs:159-200` proves that `Plug.Crypto.decrypt/4` rejects future timestamps, but it does not prove rejection on the custom authenticated-metadata path used to retain migration metadata. A migration implementation following this helper's apparent decision semantics could treat a future-dated row as ready. The persisted authentication case verifies the normal Plug caller rejects it; it does not close this migration qualification gap.
**Fix:** Add a migration-readiness function that rejects `signed_at_ms > now_ms` before deadline comparison, and test an authenticated future-dated payload through `authenticated_metadata/1` plus that readiness decision. Keep the existing direct Plug caller test as separate evidence.

---

_Reviewed: 2026-10-25T19:58:03Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
