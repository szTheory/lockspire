# Phase 178 Wave 4 gate record

Checked after Plan 08 metadata commit `80f0f58dd5475eeca92d1032f8f909c7e023f05a`, under the approved sequencing amendment. Plan 08 does not claim a successful fixed-wrapper process; Plan 10 owns that fresh verification.

- Independent real CLI validation with explicit runner and candidate-source pins accepted the original 26 receipts / 64 cases at runner `2da528fba3ca894cda4e5776b47eb6ccaf12f93c`, and locked 14 / 33 plus floor 12 / 31 at runner `90858f9fa1fecb3b5a6daa7ecc5946370e60303f`. All failed-case counts were zero. The correcting validator revision is `80f0f58d`, distinct from those tested runners.
- The original full inputs were read in place. Pair receipts were copied byte-for-byte to fresh owned validation directories; an origin-path/digest manifest records all 26 copies. Original attempt directories and raw bytes were unchanged. Outputs: `.artifacts/phase178/wave4-validation-1caa56b01477437ba23063ad58848987/`.
- Post-wave selected-runtime Python suite: 168 tests, zero failures, exit 0, under the configured 1,800-second timeout. Fixed failure messages emitted by negative contract tests were expected; no new installed package scenario ran in this check.
- Scoped build evidence: five changed Python files parsed successfully; wrapper `bash -n` and `bash scripts/ci/lint_workflows.sh` exited zero. No Elixir build command is supplied by native language sniffing. Canonical guarded contributor CI remains Plan 10's owner.
- Summary spot-check passed: declared first files exist, no failed self-check marker, and 20 Plan 08 commits resolve on this branch (60-commit bound).
- `verify.schema-drift 178`: exit 0, no block or detected drift, no ORM/schema files detected. This is not a separate schema audit.
- `verify.codebase-drift 178`: exit 0, skipped `no-structure-md`, no action required.
- `ui.safety-gate 178`: exit 0, no block and no UI files. No visual acceptance is claimed.
- No new wave failure was added. The historical Wave 2 tally and its documented correction remain unchanged.

No database-backed source command or remote action ran during this post-wave check. Future source tests and CI require `scripts/ci/run_owned_source_tests.py`. Both real Plan 08 wrapper exit-1 histories, original missing RED-record gap and newly labeled historical reproductions, historical secret/database incidents, and cleanup/timing limits remain preserved. Plan 10 must run both fixed wrappers successfully on authenticated frozen inputs and strictly compose those fresh 14 + 12 receipts, without a redundant third package producer.
