---
phase: 164-client-secret-expiry-atomic-rotation
reviewed: 2026-10-22T16:21:36Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - docs/upgrading/client-lifetimes.md
  - lib/lockspire/admin/clients.ex
  - lib/lockspire/client_lifecycle.ex
  - lib/lockspire/client_metadata.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/protocol/client_auth.ex
  - lib/lockspire/protocol/client_auth/client_secret_jwt.ex
  - lib/lockspire/protocol/dcr_policy.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
  - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
  - test/lockspire/protocol/rfc8693_exchange_test.exs
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
  - lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex
  - lib/lockspire/web/registration_json.ex
  - test/integration/client_secret_lifetime_code_refresh_test.exs
  - test/integration/client_secret_lifetime_existing_tokens_test.exs
  - test/integration/client_secret_lifetime_poll_exchange_test.exs
  - test/integration/client_secret_lifetime_registration_test.exs
  - test/integration/client_secret_lifetime_rotation_test.exs
  - test/lockspire/client_lifetime_guidance_test.exs
  - test/lockspire/protocol/client_secret_lifetime_auth_test.exs
  - test/lockspire/protocol/client_secret_lifetime_jwt_boundary_test.exs
  - test/lockspire/storage/client_lifetime_promotion_test.exs
  - test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
scope_status: degraded
scope_source: phase-range
scope_reason: no-task-commits-since
direct_reviewed: 26
reused_phase_164_review: 24
reused_phase_163_review: 20
reused_phase_166_review: 69
---

# Phase 164: Code Review Report

**Reviewed:** 2026-10-22T16:21:36Z
**Depth:** standard, bounded refresh
**Files Reviewed Directly:** 26
**Status:** clean

## Summary

The phase-scope resolver was degraded (`phase-range`, `no-task-commits-since`) and returned a milestone-wide set, so this was a bounded Phase 164 review rather than a fresh audit of that widened set. I directly examined the 26 paths listed above, focusing on secret eligibility after credential verification, secret-JWT claim and replay separation, final code/refresh/poll/exchange authority, registration metadata, current-row atomic rotation/promotion, audit/plaintext handling, and operator copy. The prior Phase 164 review enumerates 49 paths; a path comparison against its review commit shows 24 are unchanged and reused as historical review evidence. Paths that changed afterward are not treated as covered by that old report alone. I also reused unchanged cross-phase evidence from Phase 163 and Phase 166 as itemized below. The one finding from this bounded review, WR-01, is closed by the current clock-result guard and regression test described below.

The runtime candidate recorded by Phase 166 is `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`. The later documentation/test correction at `cecd4bdb` and the current RFC 8693 clock guard plus its test are post-candidate changes; therefore CI run 39776185275 and the packaged proof remain historical evidence for that candidate, not verification of the current tree. The guide paragraph and its existing assertions were directly reviewed and their recorded red/green and format/diff-check receipts checked. The focused current-tree red run reproduced WR-01 as a `FunctionClauseError` in `DateTime.compare/2`; after the fix, the recorded full RFC façade selection passed 27 tests with zero failures, covering no token issuance or audit append on the malformed final clock along with app RFC, secret/poll, and PostgreSQL grant-wait paths. The existing 28-test secret-lifetime/rotation and 47-test copy/guidance/compatibility receipts remain evidence for their recorded tree; this review did not rerun tests.

## Narrative Findings (AI reviewer)

## Historical Finding History

### Historical WR-01: RFC 8693 finalizer did not validate the clock result — WARNING, closed

**Historical file:** `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:118-121`
**Issue:** The final RFC 8693 clock helper accepted any callback return as a successful instant; the subsequent token-expiry comparison raised for a non-`DateTime` result.
**Fix and current evidence:** The helper now accepts only `%DateTime{}` and maps every other return to `server_error(:clock_unavailable)`. The regression calls the public `Rfc8693Exchange.exchange/2` façade with a valid initial clock and malformed final clock after the input-token lock, then asserts the controlled server error, unchanged token set, and no audit events. The red log reproduces the original exception; the corrected focused selection passes 27 tests, 0 failures. The two-file fix was rechecked directly; no finding remains open.

## Review Boundary and Reused Evidence

- The resolver result in `/tmp/phase164-review-scope.json` was degraded because no Phase 164 task-commit rows were available; its phase-range fallback contained 109 milestone paths. This report does not claim those 109 paths were freshly reviewed.
- The prior Phase 164 review enumerates 49 explicit paths. A comparison from its review commit (`afceb3992a33ea94edb9f25bf504be63267a8eaa`) to current HEAD finds 24 unchanged paths; those are reused as historical review evidence. The corrected guide and its contract-test path are direct rechecks here. The prior disposition records no Phase 164 findings requiring closure.
- Phase 163's bounded refresh directly reviewed 22 paths and reused Phase 166's review; 20 unchanged Phase 163 paths relevant to this review are reused as cross-phase evidence. Phase 163's historical CR-01 fractional-clock and WR-01 adapter-conformance findings remain closed, with their fix evidence in [163-REVIEW.md](../163-app-lifetime-compatible-host-storage/163-REVIEW.md).
- Phase 166's independent 71-path review is reused for its 69 unchanged paths. Its two post-review guide/test paths were separately rechecked in Phase 163; the Phase 166 single-prefix acceptance WR-01 was fixed and dispositioned, not treated as an open Phase 164 finding. See [166-REVIEW.md](../166-end-to-end-lifetime-security-guidance-proof/166-REVIEW.md), [166-REVIEW-FIX.md](../166-end-to-end-lifetime-security-guidance-proof/166-REVIEW-FIX.md), and [166-REVIEW-DISPOSITION.md](../166-end-to-end-lifetime-security-guidance-proof/166-REVIEW-DISPOSITION.md).
- Current-source security evidence at `cecd4bdb` reports all 24 Phase 164 mitigations verified with no open threat; that audit predates the WR-01 fix and is not claimed as a fresh audit of the exact current two-file state. The validation receipt reports 28 focused secret/rotation tests and 47 copy/guidance/compatibility tests passing; the separate 27-test red/green evidence above directly verifies the correction. These receipts supplement but do not replace this review.
- The clock-result guard and façade regression are later two-file changes relative to candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`; the review verified their current diff and retained red/green logs. No claim is made that the original seven-context CI run or packaged candidate includes this fix.
- Limits remain explicit: Phase 164's three source-audit probes (`EDGE-DCR-07`, `EDGE-DCR-08`, `EDGE-DCR-09`) are unresolved/unclassified. Phase 166's three undefined edge probes and two descriptor-less prohibitions remain unresolved/unverified, and historical TDD evidence caveats remain. No additional coverage predicate or inferred gate is claimed.

---

_Reviewed: 2026-10-22T16:21:36Z_
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard, bounded refresh_
