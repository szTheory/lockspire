---
phase: 137-ci-conformance-and-release-proof
plan: "05"
subsystem: conformance-inputs
tags: [oidf, supply-chain, checksums, oci]
requires:
  - phase: 137-ci-conformance-and-release-proof
    provides: CI policy baseline
provides:
  - immutable OIDF suite source, helper, archive, and image identities
  - checksum-verified preparation seam with digest-normalized compose
affects: [137-06, 137-07]
tech-stack:
  added: []
  patterns: [strict JSON lock validation, private verified preparation]
key-files:
  created:
    - scripts/conformance/oidf-suite-lock.json
    - scripts/conformance/oidf_inputs.py
    - scripts/conformance/prepare_oidf_suite.sh
    - test/lockspire/conformance_immutable_inputs_contract_test.exs
key-decisions:
  - "The OIDF tag is documentary; every fetched source URL uses the full verified commit."
  - "The fetched upstream compose is normalized only after checksum verification and accepts exactly three known image templates."
metrics:
  completed: 2026-08-27
status: complete
---

# Phase 137 Plan 05: Immutable OIDF Inputs Summary

**OIDF conformance preparation now starts from one complete, machine-validated source and OCI identity lock.**

## Accomplishments

- Pinned `release-v5.1.43`, commit `16ad152b1b2c0baacd3d2519128340d95deb2b8c`, archive checksum, four helper checksums, and exact server/nginx/Mongo OCI digests.
- Added a standard-library-only validator that rejects duplicate JSON keys, mutable references, malformed hashes, incomplete schema, unverified downloads, path escape, and compose image drift.
- Added a private-output preparation command that validates before download, verifies every downloaded byte, and writes digest-qualified compose and image environment data without a source-build substitution.
- Added contract coverage for immutable identity values, malicious lock categories, and preparation ordering/bypass resistance.

## Task Commits

1. **Task 1: Validate the complete immutable suite lock** — `4d494e8a` (RED), `7d898ebe` (GREEN)
2. **Task 2: Prepare checksum-verified files and digest-qualified compose** — `bc24dce7`

## Verification

- `MIX_ENV=test mix test test/lockspire/conformance_immutable_inputs_contract_test.exs` — 3 tests, 0 failures.
- `python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only` — passed.
- `bash -n scripts/conformance/prepare_oidf_suite.sh` — passed.
- Real preparation downloaded and verified the pinned archive/helpers, then emitted compose with exactly locked Mongo, nginx, and server digest references.

## Deviations from Plan

None - plan executed as specified. The repository uses `oidf_inputs.py` (the task ownership name) as the validator entrypoint.

## Known Stubs

None.

## Self-Check: PASSED

- Lock, validator, preparation script, and hostile-input contract all exist.
- Commits `4d494e8a`, `7d898ebe`, and `bc24dce7` are present in git history.
