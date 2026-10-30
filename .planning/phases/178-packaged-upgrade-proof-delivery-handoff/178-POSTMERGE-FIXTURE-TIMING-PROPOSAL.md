# Acceptance fixture timing correction — ready for approval

Status: approved by the user; approval observed 2026-10-30 at 15:27:24 UTC. Record authorization, push the exact correction, merge only after CI, then run actual exact-main acceptance.

Candidate: `5e524fd34919f38988e6142aaf1da0e5bff54a98` on `fix/v148-polling-fixtures`, based on merged main `3f64e1c6c1af19f0e5f074aff326fa04f7f6b642`. Production helper and library code are unchanged. Only `test/support/lockspire/release_proof/package_assertions.ex` changes.

The prior integration proposal authorized one branch push/PR/merge for source `9ffe69f1`; that operation is complete. This additional correction changes selected source bytes and needs its own authorization. Do not repoint the existing exact-candidate authorization without actual approval.

## What the correction does

Two identity-race fixtures previously gave the helper only two seconds to reach a second workflow observation. A controlled three-second first response makes the old main-advancement case reject at polling timeout instead of identity movement. The run-replacement case can incorrectly satisfy its broad block-label assertion merely by timing out. The corrected fixtures use the permitted longer helper budget while retaining their existing outer 180-second test timeout, deliberately delay the first response by three seconds, and require the specific replacement rejection message. They complete after two observations; the longer budget does not make successful fixtures wait an hour.

The full rejection contract passed in approximately122seconds with the delay, under its unchanged180second bound. Formatting and whitespace checks passed. No app/database or remote mutation was needed for that verification. The original intermittent failure's exact assertion remains unknown; the controlled experiment independently establishes the timing defect. An unmodified full source diagnostic on merged main also passed and independently cleaned its owned database; it is diagnostic evidence, not accepted main.

Evidence: [fixture timing verification](178-POSTMERGE-FIXTURE-TIMING-VERIFICATION.json). Earlier failed attempts and private data remain retained; protected root tar is unchanged. PARTIAL formal-coverage debt remains.

## Requested operation

Approve one non-force branch push, a PR for this exact fixture correction plus its truthful authorization/evidence metadata, merge only after required CI passes, synchronize main, then rerun actual exact-main acceptance and validate its emitted receipt/handoff. Record the actual new approval time and exact candidate in the canonical authorization file only after approval. Milestone archiving, release publication, and UI implementation are separate boundaries.

## Prepared PR title

test: let acceptance polling fixtures observe identity changes

## Prepared PR body

The exact-main rejection contract can expire its two-second fixture deadline before it observes main movement. A run-replacement fixture can also pass for timeout rather than the intended identity mismatch. Give these two synthetic fixtures a polling budget longer than their existing outer test timeout, inject a three-second first-response delay, and assert the specific replacement error. Production acceptance rules are unchanged.

Validation: controlled old-budget experiments time out before the intended check; the full corrected rejection contract passes with the deliberate delay under its existing timeout. Formatting and whitespace checks pass. Hosted CI and a fresh exact-main helper receipt remain required before acceptance. The exact assertion of the earlier intermittent run is unavailable; retained evidence states that limit.

### Merge Danger

**Door:** Two-way.

**Blast Radius:** Test fixtures for delivery acceptance.
