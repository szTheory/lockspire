---
phase: 177-safe-verifier-maintenance-recovery
reviewed: 2026-10-26T04:08:27Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - docs/client-secret-jwt-host-guide.md
  - docs/client-secret-verifier-configuration.md
  - docs/supported-surface.md
  - lib/lockspire/admin/client_verifier_maintenance.ex
  - lib/lockspire/config.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/security/client_secret_verifier.ex
  - lib/lockspire/security/client_secret_verifier/operation_context.ex
  - lib/lockspire/storage/client_verifier_maintenance.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex
  - lib/mix/tasks/lockspire.clients.verifier.rewrap.ex
  - test/integration/client_secret_verifier_maintenance_concurrency_test.exs
  - test/integration/client_secret_verifier_maintenance_disclosure_test.exs
  - test/integration/client_secret_verifier_maintenance_issuance_test.exs
  - test/integration/client_secret_verifier_maintenance_recovery_test.exs
  - test/integration/client_secret_verifier_maintenance_test.exs
  - test/integration/install_generator_test.exs
  - test/lockspire/admin/client_verifier_maintenance_test.exs
  - test/lockspire/compatibility_baseline_contract_test.exs
  - test/lockspire/config_client_secret_verifier_test.exs
  - test/lockspire/quality/proof_quality_baseline_test.exs
  - test/lockspire/security/client_secret_verifier_inspection_test.exs
  - test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs
  - test/lockspire/security/client_secret_verifier_maintenance_test.exs
  - test/lockspire/storage/client_verifier_maintenance_test.exs
  - test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs
  - test/support/architecture/public_compatibility_manifest.ex
  - test/support/client_verifier_maintenance_concurrency.ex
  - test/support/delegated_verifier_maintenance_store.ex
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 177: Code Review Report

**Reviewed:** 2026-10-26T04:08:27Z  
**Depth:** standard  
**Files Reviewed:** 32  
**Status:** issues_found

## Summary

Reviewed the explicit 32-file Phase 177 scope, including the maintenance implementation, repository query and transaction boundaries, diagnostics, CLI, docs, fixtures, and tests. Authority preflight, ciphertext CAS, page completion checks, readiness handling, and normal-path redaction appear consistent with the phase contract. One audit input validation gap remains in the built-in compare-and-rewrap callback.

## Warnings

### WR-01: Audit allowlist does not constrain sensitive values

**File:** `lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex:225-235`  
**Issue:** `valid_audit_attrs?/1` only allowlists top-level keys, and `valid_audit_metadata?/1` only allowlists metadata keys. It does not validate `actor` or `resource` at all, nor constrain `old_key_id`, `new_key_id`, or `maintenance_at` values. A caller invoking `compare_and_rewrap/5` inside a transaction can therefore place a client secret, hash, verifier, ciphertext, or arbitrary diagnostic text in these fields; the function then persists those values through `append_audit_event/1`. The normal maintenance service currently constructs safe values, but the storage callback does not enforce its stated allowlisted-audit boundary.
**Fix:** Validate the exact required actor/resource maps and bind `resource.id` to `client_id`; require key IDs to match the bounded configured key-ID format and `maintenance_at` to be a `DateTime`. Reject missing, extra, or incorrectly typed fields before the row lock/update. Add a test that passes secret sentinels through each allowed value slot and proves the callback rejects them without changing ciphertext or writing an audit row.

---

_Reviewed: 2026-10-26T04:08:27Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
