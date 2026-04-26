---
phase: 26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
plan: 03
subsystem: protocol
tags: [dcr, initial-access-token, rfc7591, iat, telemetry]
dependency_graph:
  requires: [26-01]
  provides: [atomic-iat-redemption]
  affects: [protocol-pipeline, repository]
tech_stack:
  added: []
  patterns: [ecto-for-update, atomic-redemption]
key_files:
  created:
    - lib/lockspire/protocol/initial_access_token.ex
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/protocol/initial_access_token_test.exs
    - test/support/fixtures/initial_access_token_fixtures.ex
key_decisions:
  - Collapsed all 4 rejection axes to `{:error, :invalid_token}` in public protocol entry point (DCR-11) while preserving discriminators in telemetry only.
  - Mirrored `mark_authorization_code_redeemed/2` pattern using DB-level `lock("FOR UPDATE")` for atomic IAT redemption.
metrics:
  tasks_completed: 2
  files_modified: 4
  duration: 120s
---

# Phase 26 Plan 03: Atomic IAT Redemption End-to-End Summary

Atomic Initial Access Token (IAT) redemption using `lock("FOR UPDATE")` with axis-collapsed telemetry.

## Completed Tasks

1. **Task 1: Add Repository.redeem_initial_access_token/2 (RED → GREEN)**
   - Created the transactional redeemer for IATs mirroring the authorization code redeemer.
   - Checked the four freshness axes (`:not_found`, `:revoked`, `:expired`, `:already_used`) inside the transaction lock.

2. **Task 2: Extend InitialAccessTokenFixtures with persist/1, replace Wave-0 stub with full redemption tests (RED), author Lockspire.Protocol.InitialAccessToken (GREEN)**
   - Implemented `Lockspire.Protocol.InitialAccessToken.redeem/1` collapsing all rejection axes to `{:error, :invalid_token}`.
   - Added telemetry emission with `:iat_id` and `:failure_reason` while preventing plaintext leaking into metadata.
   - Wrote concurrent `Task.async` test proving only 1 of 10 tasks successfully redeems the IAT.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None found. The execution specifically adhered to mitigations for T-26-IAT-RACE, T-26-IAT-LEAK, and T-26-IAT-ENUM as defined in the plan's threat register.

## Self-Check: PASSED
- `lib/lockspire/storage/ecto/repository.ex` was successfully modified.
- `lib/lockspire/protocol/initial_access_token.ex` was created and exists.
- `test/lockspire/protocol/initial_access_token_test.exs` contains passing tests including concurrent redemption.
- Commits `30b67f4` and `d93fb92` capture the work.