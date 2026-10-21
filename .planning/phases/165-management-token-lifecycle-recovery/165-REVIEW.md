---
phase: 165-management-token-lifecycle-recovery
reviewed: 2026-10-21T19:36:13Z
depth: standard
files_reviewed: 46
files_reviewed_list:
  - PRODUCT.md
  - docs/dynamic-registration.md
  - docs/operator-admin.md
  - docs/supported-surface.md
  - docs/upgrading/client-lifetimes.md
  - lib/lockspire/client_lifecycle.ex
  - lib/lockspire/client_metadata.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/protocol/dcr_policy.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/registration_management.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/storage/ecto/server_policy_record.ex
  - lib/lockspire/web/controllers/registration_controller.ex
  - lib/lockspire/web/live/admin/clients_live/show.ex
  - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
  - lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex
  - lib/lockspire/web/registration_json.ex
  - test/integration/app_lifetime_management_test.exs
  - test/integration/management_token_lifetime_access_test.exs
  - test/integration/management_token_lifetime_recovery_test.exs
  - test/integration/management_token_lifetime_registration_test.exs
  - test/integration/management_token_lifetime_update_test.exs
  - test/lockspire/client_lifecycle_test.exs
  - test/lockspire/client_lifetime_guidance_test.exs
  - test/lockspire/compatibility_baseline_contract_test.exs
  - test/lockspire/protocol/dcr_audit_attribution_test.exs
  - test/lockspire/protocol/dcr_telemetry_redaction_test.exs
  - test/lockspire/protocol/management_token_lifetime_policy_test.exs
  - test/lockspire/protocol/management_token_request_contract_test.exs
  - test/lockspire/protocol/registration_management_test.exs
  - test/lockspire/storage/client_lifetime_conformance_test.exs
  - test/lockspire/storage/client_lifetime_promotion_test.exs
  - test/lockspire/storage/ecto/server_policy_record_test.exs
  - test/lockspire/storage/management_token_client_wait_test.exs
  - test/lockspire/storage/management_token_mutation_race_test.exs
  - test/lockspire/storage/management_token_replacement_race_test.exs
  - test/lockspire/storage/management_token_rollback_test.exs
  - test/lockspire/web/controllers/registration_controller_test.exs
  - test/lockspire/web/discovery_controller_test.exs
  - test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs
  - test/lockspire/web/live/admin/clients_live_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr_test.exs
  - test/lockspire/web/registration_json_test.exs
  - test/support/architecture/public_compatibility_manifest.ex
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 165: Code Review Report

**Reviewed:** 2026-10-21T19:36:13Z  
**Depth:** standard  
**Files Reviewed:** 46  
**Status:** issues_found

## Summary

Reviewed the full explicit Phase 165 file scope against DCR-10/11/12, the Phase 162 lifecycle decisions, and project guidance. The locking, current-token checks, final-clock expiry decisions, recovery preservation, response redaction, and atomic write/audit paths are consistent with the stated contracts. One error-precedence defect remains: an expired app can receive a PUT metadata error instead of the required `registration_expired` response. Supplied validation evidence was reviewed but not rerun as part of this code review.

## Critical Issues

### CR-01 [BLOCKER]: Expired-app PUT validation can bypass the required expiry response

**File:** `lib/lockspire/protocol/registration_management.ex:450`
**Issue:** `with_prepared_current/5` returns a preparation error at lines 450-451 before it checks `Client.app_eligibility/3` at lines 432-447. With a valid management token for an expired app, a PUT containing a missing/mismatched `client_id` or another invalid field therefore returns HTTP 400 `invalid_client_metadata` rather than the contractually required HTTP 403 `registration_expired`. This makes the PUT result depend on body validity even though DCR-11 requires PUT to be blocked for an expired app.
**Fix:** Keep the management-token eligibility check first so expired management credentials still receive the non-disclosing 401 response. Then check app eligibility before returning a deferred preparation error: return `registration_expired` for expired-app PUTs, allow the expired-app GET/DELETE exceptions, and only surface prepared metadata errors when the operation is app-eligible.

---

_Reviewed: 2026-10-21T19:36:13Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
