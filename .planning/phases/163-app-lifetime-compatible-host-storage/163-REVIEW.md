---
phase: 163-app-lifetime-compatible-host-storage
reviewed: 2026-10-22T16:06:33Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/lockspire/domain/client.ex
  - lib/lockspire/storage/client_lifetime.ex
  - lib/lockspire/storage/client_store.ex
  - lib/lockspire/storage/transaction_store.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/storage/ecto/repository/transaction_store.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/client_lifecycle.ex
  - lib/lockspire/protocol/client_auth.ex
  - lib/lockspire/protocol/token_lifetime.ex
  - lib/lockspire/protocol/token_exchange/internal/client_authentication.ex
  - lib/lockspire/protocol/token_exchange/internal/dependencies.ex
  - lib/lockspire/protocol/token_exchange/internal/legacy_options.ex
  - lib/lockspire/protocol/device_authorization.ex
  - lib/lockspire/protocol/backchannel_authentication.ex
  - lib/lockspire/protocol/device_verification.ex
  - lib/lockspire/protocol/registration_access_token.ex
  - lib/lockspire/workers/ciba_notification_worker.ex
  - priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs
  - docs/upgrading/client-lifetimes.md
  - test/lockspire/client_lifetime_guidance_test.exs
reused_review:
  phase: 166-end-to-end-lifetime-security-guidance-proof
  reviewed: 2026-10-22T10:52:16Z
  files: 71
  unchanged_files_reused: 69
  directly_rechecked_after_correction: 2
  followup_files: 2
  source_commit: 0bd4070d862c53cb3e8dfc4d1cf25535b232aaed
  file_list: .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-REVIEW.md
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 163: Code Review Report

**Reviewed:** 2026-10-22T16:06:33Z
**Depth:** standard, bounded refresh
**Files Reviewed Directly:** 22
**Reused Review:** 71 Phase 166 files, plus its 2-file follow-up
**Status:** clean

## Summary

The bounded current-source review found no new open correctness, security, or quality findings in the client lifetime decision, current-row guards, selected client/transaction-store composition, issuance, legacy promotion, migration, and online consumer paths examined. Existing Phase 163 findings CR-01 and WR-01 remain closed; their history and fix evidence are retained below.

This refresh does not claim a fresh 81-file review. The phase scope resolver was degraded (`phase-range`, `no-task-commit-rows`) and returned a broad range. The review therefore used the supplied 81-path Phase 163 boundary, directly examined the 20 paths in the frontmatter, and reused the independent Phase 166 review at the same source commit. Phase 166's exact 71-path scope is listed in [166-REVIEW.md](../166-end-to-end-lifetime-security-guidance-proof/166-REVIEW.md); 23 of those paths overlap the supplied Phase 163 boundary. Those overlapping paths are `docs/architecture.md`, `docs/dynamic-registration.md`, `docs/upgrading/client-lifetimes.md`, `lib/lockspire/client_lifecycle.ex`, `lib/lockspire/domain/client.ex`, `lib/lockspire/protocol/authorization_flow.ex`, `lib/lockspire/protocol/authorization_request.ex`, `lib/lockspire/protocol/introspection.ex`, `lib/lockspire/protocol/registration.ex`, `lib/lockspire/protocol/registration_management.ex`, `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex`, `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex`, `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex`, `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex`, `lib/lockspire/protocol/userinfo.ex`, `lib/lockspire/storage/client_lifetime.ex`, `lib/lockspire/web/controllers/registration_controller.ex`, `scripts/acceptance/clean_room/build_provider.py`, `scripts/acceptance/clean_room/client_lifetime_upgrade.py`, `test/clean_room/lifetime_upgrade_scenarios.exs`, `test/integration/app_lifetime_packaged_upgrade_test.exs`, `test/lockspire/client_lifetime_guidance_test.exs`, and `test/lockspire/storage/client_lifetime_grant_wait_test.exs`.

The runtime implementation and package inputs still match Phase 166's final runtime candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`; the direct runtime comparison passed. The guide paragraph and its contract assertions were corrected afterward, so those two paths no longer match the CI candidate and were directly re-reviewed here. Phase 166's canonical CI evidence binds run 39776185275 and all seven required contexts to the exact runtime candidate SHA. The maintainer evidence-map path in the guide resolves at commit `49ec3c7c727c3234992e929d0e194015a901083c`. The red log shows the old guide caused the expected assertion failure; the corrected guide passed 8 tests with zero failures, and the recorded format and diff checks passed. CI run 39776185275 did not include this later documentation/test correction. The Phase 166 single-prefix acceptance finding is closed by its recorded follow-up review. The fresh Phase 163 validation receipt reports 52 focused tests with zero failures; this review did not execute tests.

## Narrative Findings (AI reviewer)

No new open findings identified in the directly reviewed bounded paths or the reused Phase 166 paths. The two-file guidance correction was also directly rechecked against its recorded regression evidence.

## Historical Finding History

### Historical CR-01: Fractional decision instants reject eligible finite-lifetime clients — BLOCKER, closed

**Historical file:** `lib/lockspire/domain/client.ex:184-199`
**Issue:** The original app eligibility comparison used a subsecond decision instant against a whole-second persisted deadline and could reject a still-eligible client.
**Fix and current evidence:** `decision_instant/1` normalizes the instant to a UTC whole second before the strict deadline comparison; equality remains expired. The original authentication regression covered before-deadline and equality instants, including default-clock behavior. Current source matches the reviewed Phase 166 source commit.

### Historical WR-01: Dropped-field conformance fixtures failed before persistence comparisons — WARNING, closed

**Historical file:** `test/lockspire/storage/client_lifetime_conformance_test.exs`
**Issue:** The original negative fixtures declared an invalid transaction authority, so adapter registration/fetch was never reached and dropped version/deadline fields were not actually tested.
**Fix and current evidence:** The fixtures now declare valid adapter-owned authorities, record registration and fetch, and assert the specific missing version or dropped deadlines in the fetched client. The fix summary records the prior red check and focused test evidence.

### Phase 163 guidance proof correction — no open finding

**Files:** `docs/upgrading/client-lifetimes.md:214-225`, `test/lockspire/client_lifetime_guidance_test.exs:74-86` and `150-173`

The guide now attributes seven passing CI contexts to the final runtime candidate, links the canonical evidence-map commit, preserves the three unresolved probes and two unverified descriptor-less prohibitions, and says the correction postdates that CI run. The contract test was updated to assert those claims. The recorded red run fails on the old CI-pending wording; the corrected guide passes 8 tests with zero failures. This fixes a documentation/test contract mismatch without changing runtime code or retroactively including the correction in CI run 39776185275.

## Review Boundary and Evidence

- Directly reviewed current paths: the 22 paths in `files_reviewed_list` above. This includes the shared eligibility and deadline helpers, adapter validation, transaction participant matching, Ecto client locking and mapping, legacy-promotion deltas, device/CIBA final guards, the CIBA push issuance boundary, and the corrected guide/test pair.
- Reused independent review: the 71 files enumerated by [166-REVIEW.md](../166-end-to-end-lifetime-security-guidance-proof/166-REVIEW.md), with its two separate changed follow-up files and closed finding documented in [166-REVIEW-FIX.md](../166-end-to-end-lifetime-security-guidance-proof/166-REVIEW-FIX.md) and [166-REVIEW-DISPOSITION.md](../166-end-to-end-lifetime-security-guidance-proof/166-REVIEW-DISPOSITION.md). Of those 71 Phase 166 files, 69 remain unchanged since that review; `docs/upgrading/client-lifetimes.md` and `test/lockspire/client_lifetime_guidance_test.exs` were directly rechecked after correction.
- Fresh validation receipt: `163-VALIDATION.md` reports 52 focused tests, zero failures, a plan-artifact audit, and current-source/package parity. Test execution remains validation evidence, not a substitute for this review.
- Existing security refresh: `163-SECURITY.md` reports all 38 planned mitigations verified against current source, with zero open. This is mitigation-presence evidence, not a code-review substitute.
- Limits retained and checked against the current Phase 166 evidence map: A-EDGE-16/17/19 remain unresolved, prohibition-1 and prohibition-2 remain flagged-unverified, and the existing TDD-mode caveat remains. No additional coverage gate or probe was inferred from those documented limits.

---

_Reviewed: 2026-10-22T16:06:33Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard, bounded refresh_
