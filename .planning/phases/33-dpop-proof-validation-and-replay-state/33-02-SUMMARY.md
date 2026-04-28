---
phase: 33
plan: 02
subsystem: auth
tags: [dpop, oauth, replay, ecto, postgres]
requires:
  - phase: 33
    provides: protocol-owned DPoP proof validation and thumbprint derivation
provides:
  - durable DPoP replay-state schema and repository contract
  - deterministic accepted-vs-replay outcomes across fresh repository calls
  - token-endpoint DPoP preflight seam that rejects replayed proofs as invalid_dpop_proof
affects: [phase-34-token-issuance, phase-35-userinfo, dpop-policy]
tech-stack:
  added: []
  patterns: [typed replay-store contract, TTL-bounded replay pruning, protocol preflight enforcement]
key-files:
  created:
    - lib/lockspire/domain/dpop_replay.ex
    - lib/lockspire/storage/dpop_replay_store.ex
    - lib/lockspire/storage/ecto/dpop_replay_record.ex
    - priv/repo/migrations/20260428150000_add_lockspire_dpop_replay_state.exs
    - test/lockspire/storage/ecto/repository_dpop_replay_test.exs
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/protocol/token_exchange.ex
    - test/lockspire/protocol/token_exchange_test.exs
key-decisions:
  - "Model replay state explicitly with replay_key, jti, htm, htu, jkt, seen_at, and expires_at instead of hiding it in ad hoc maps."
  - "Use a repository-owned unique replay key plus TTL pruning to classify first use vs replay without process-local memory."
  - "Wire replay enforcement into TokenExchange as a narrow DPoP preflight seam and keep bearer issuance semantics unchanged otherwise."
patterns-established:
  - "Protocol code hands normalized replay identity to storage and consumes typed accepted/replay outcomes."
  - "Expired replay rows are pruned at write time so correctness depends on expires_at, not background jobs."
requirements-completed: [DPoP-02, DPoP-03]
duration: 18min
completed: 2026-04-28
---

# Phase 33 Plan 02: DPoP Replay State Summary

**Durable DPoP replay detection with repository-backed conflict semantics and token-endpoint preflight enforcement**

## Performance

- **Duration:** 18 min
- **Completed:** 2026-04-28T15:15:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `Lockspire.Domain.DpopReplay`, `Lockspire.Storage.DpopReplayStore`, and `Lockspire.Storage.Ecto.DpopReplayRecord` as the first-class durable replay-state seam.
- Added an additive migration for `lockspire_dpop_replay` with a unique replay key and expiry index.
- Implemented repository-backed `record_dpop_proof/1` behavior with deterministic `:accepted` and `:replay` outcomes plus expiry-window behavior.
- Wired validated DPoP proofs into `Lockspire.Protocol.TokenExchange` preflight so missing or replayed proofs become public `invalid_dpop_proof` errors when DPoP is required.

## Task Commits

1. **Task 1: Add a first-class DPoP replay domain, store contract, and schema**
   - `46950a5` `test(33-02): add failing replay state storage tests`
   - `d76a978` `feat(33-02): add durable DPoP replay state model`
2. **Task 2: Implement repository-backed replay acceptance, rejection, and TTL-window proof**
   - `166c203` `test(33-02): add failing replay enforcement tests`
   - `d64c555` `feat(33-02): enforce durable DPoP replay detection`

## Files Created/Modified

- `lib/lockspire/domain/dpop_replay.ex` - explicit durable replay-state shape.
- `lib/lockspire/storage/dpop_replay_store.ex` - typed replay persistence contract.
- `lib/lockspire/storage/ecto/dpop_replay_record.ex` - Ecto schema and mapping for replay rows.
- `priv/repo/migrations/20260428150000_add_lockspire_dpop_replay_state.exs` - additive replay-state table and indexes.
- `lib/lockspire/storage/ecto/repository.ex` - durable replay recording and expiry pruning.
- `lib/lockspire/protocol/token_exchange.ex` - DPoP replay preflight enforcement.
- `test/lockspire/storage/ecto/repository_dpop_replay_test.exs` - repository proof for accepted, replay, and expiry-window behavior.
- `test/lockspire/protocol/token_exchange_test.exs` - token-endpoint proof for missing and replayed DPoP enforcement.

## Decisions Made

- Replay identity is computed from validated proof material and normalized request context rather than raw JWT bytes.
- Storage owns the replay classification boundary so multi-node and process-restart behavior remains truthful.
- Phase 33 stops at replay preflight; it does not yet add token binding, `cnf` issuance, or DPoP token-type responses.

## Deviations from Plan

None.

## Issues Encountered

- The executor completed the implementation and verification but did not write this summary automatically, so the orchestrator finalized the docs step locally without changing the code path.

## User Setup Required

None.

## Next Phase Readiness

- Phase 34 can build token issuance and refresh binding on top of durable replay detection.
- Phase 33 Plan 03 can add explicit client/server DPoP policy state against a real replay-enforced protocol seam.

## Self-Check: PASSED

- Durable replay-state modules and migration exist in the repo.
- Commits `46950a5`, `d76a978`, `166c203`, and `d64c555` are present in git history.
- `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_dpop_replay_test.exs test/lockspire/protocol/token_exchange_test.exs` passed after execution.
