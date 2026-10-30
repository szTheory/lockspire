# Plan 178-08 Checkpoint (Superseded)

The root-approved sequencing amendment superseded this checkpoint on 2026-10-27. Plan08 is now complete under the amended local evidence boundary recorded in `178-08-PLAN.md` and `178-08-SUMMARY.md`. This file remains as the exact checkpoint originally reported; it does not claim a fixed-wrapper green run.

## Implemented and verified

- Closed 26-cell aggregate validation and pair projection validation, including two disclosure receipt siblings, old rollout/public schemas, explicit runner and candidate-source pins, and separate validator revision reporting.
- Pair CI wrapper, fail-closed process-group cleanup, 1,500-second overall deadline, safe receipt upload wiring, and existing workflow job timeout updates are committed.
- Full acceptance Python suite: 168 tests passed. Workflow lint, shell syntax, and `git diff --check` passed. Seven existing Plan08 TDD records classify `RED_EVIDENCE_OK`; historical reproductions do not claim recovery of missing original evidence.
- At validator commit `3d8f99cc8cca9df15d4e0338b660391cea49f30d`, read-only retained validation passed using raw runner/source identities and distinct validator identity:
  - Full matrix: runner/source `2da528fba3ca894cda4e5776b47eb6ccaf12f93c`, 26 receipts, 64 cases, 0 failed.
  - Locked: runner/source `90858f9fa1fecb3b5a6daa7ecc5946370e60303f`, 14 receipts, 33 cases, 0 failed.
  - Floor: same runner/source, 12 receipts, 31 cases, 0 failed.
- The full aggregate is `.artifacts/phase178/aggregate-revalidated-3d8f99cc/aggregate.json`; pair raw receipts were copied byte-for-byte to fresh `retained-pairs-3d8f99cc` inputs before validation.

## Blocking acceptance gap

The required real wrapper commands were run before the selected-pair CLI import fix. Both completed their package groups and emitted all expected raw receipts, then exited 1 during receipt validation because `validate_matrix_links` was not imported:

- Locked: 14 raw receipt files, 33 executed cases, wrapper exit 1 at `validate/locked`.
- Floor: 12 raw receipt files, 31 executed cases, wrapper exit 1 at `validate/floor`.

The import fix is committed as `952e4e3b`; the immutable raw receipts pass the corrected CLI at `3d8f99cc`. The wrapper itself has not been rerun through a zero-exit real package execution because the orchestrator directed that the full pair matrix not be repeated solely for validator/deadline corrections. Thus the plan's requested successful real wrapper command remains unverified; fake-mode tests and retained receipt validation are not represented as a successful wrapper run.

## Preserved operational limitations

- Original wrapper failures remain exit 1; raw receipt bytes and runner revisions were not restamped.
- Earlier process-group `EACCES` refusal cannot establish descendant cleanup; direct-child termination is not counted as group cleanup. The implementation fails closed with cleanup-unconfirmed status and does not accept receipts.
- No hosted workflow run, remote dispatch, publication, merge, or requirement completion is claimed.
- Source database tests were not run outside the owned-source runner. No shared/development database repair or cleanup was performed.

## Relevant commits

- Matrix, wrapper, workflow, deadline, ownership, and validation changes are recorded between `d77a44b8` and `3d8f99cc`; the last pin-separation commit is `3d8f99cc`.
- The raw matrix runner identities remain `2da528...` and `90858f...`, separate from validator commit `3d8f99cc`.
