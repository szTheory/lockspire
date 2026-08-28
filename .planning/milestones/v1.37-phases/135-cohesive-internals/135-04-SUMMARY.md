---
phase: 135-cohesive-internals
plan: 04
subsystem: storage
tags: [ecto, device-authorization, ciba, dpop, replay-security]
requires:
  - phase: 135-03
    provides: repo-explicit aggregate collaborator pattern
provides:
  - Locked device and CIBA state-machine aggregate owners
  - Durable DPoP and JTI replay-security aggregate owner
affects: [device-flow, ciba, dpop, token-exchange]
tech-stack:
  added: []
  patterns: [repo-explicit aggregate collaborator, locked transactional transition, durable unique insert]
key-files:
  created:
    - lib/lockspire/storage/ecto/repository/device_authorization_store.ex
    - lib/lockspire/storage/ecto/repository/ciba_authorization_store.ex
    - lib/lockspire/storage/ecto/repository/replay_store.ex
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/storage/ecto/repository_device_authorization_test.exs
    - test/lockspire/storage/ciba_authorization_repository_test.exs
    - test/lockspire/storage/ecto/repository_dpop_replay_test.exs
    - test/lockspire/storage/ecto/repository_used_jti_test.exs
key-decisions:
  - "Device and CIBA retain separate aggregate owners so their protocol state machines remain directly navigable."
  - "DPoP and JTI durable uniqueness share ReplayStore while preserving their distinct conflict targets."
requirements-completed: [COH-01, COH-02]
status: complete
---

# Phase 135 Plan 04: Asynchronous Authorization and Replay Storage Summary

Device and CIBA polling state machines plus durable DPoP/JTI replay protection now live in focused Ecto aggregate collaborators behind the stable Repository facade.

## Accomplishments

- Extracted device authorization issuance, sensitive lookups, locked polling, terminal transitions, and single-use consumption into `DeviceAuthorizationStore`.
- Extracted CIBA issuance, sensitive lookup, locked polling, and transitions into `CibaAuthorizationStore` without introducing a generic polling abstraction.
- Extracted DPoP expiry pruning/unique insert and used-JTI unique insert into `ReplayStore`, preserving silent sensitive queries and fail-closed duplicate outcomes.
- Added direct aggregate characterization assertions while retaining all existing Repository-facing behavior tests.

## Verification

- `mix compile --warnings-as-errors`
- `mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/storage/ciba_authorization_repository_test.exs test/lockspire/storage/ecto/repository_dpop_replay_test.exs test/lockspire/storage/ecto/repository_used_jti_test.exs`

Result: 35 tests, 0 failures.

## Task Commits

1. Task 1 RED: `3f9814da` — characterize polling aggregate delegates.
2. Task 1 GREEN: `22c5158d` — extract device and CIBA state machines.
3. Task 2 RED: `55ec94ad` — characterize replay-security aggregate.
4. Task 2 GREEN: `f50eaa62` — extract replay-security storage.

## Decisions Made

- Each polling protocol retains its own locked record/query/evaluation/update cluster, including the existing five-second slow-down increment and outcome map shape.
- `ReplayStore` owns durable uniqueness at the persistence boundary and uses `on_conflict: :nothing`, with DPoP expiry pruning remaining inside the same transaction.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- All three aggregate modules exist.
- All four TDD commits are present.
- No stub markers were introduced in plan-owned files.
