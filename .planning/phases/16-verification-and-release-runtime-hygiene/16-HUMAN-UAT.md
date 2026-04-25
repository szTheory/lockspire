---
status: complete
phase: 16-verification-and-release-runtime-hygiene
source:
  - 16-VERIFICATION.md
started: 2026-04-24T15:40:00Z
updated: 2026-04-24T16:01:16Z
---

## Current Test

Live GitHub Actions recovery verification for the `Release` workflow completed.

## Tests

### 1. Recovery ref enforcement and warning-free runtime
expected: Invalid branch refs such as `main` fail before publish, valid immutable refs (40-character SHA or existing tag) proceed through the protected `hex-publish` lane, and the run shows no deprecated Node 20 runtime warning.
result: passed
evidence:
- Invalid branch ref proof: GitHub Actions run `24898764939` failed in `Validate Recovery Ref` with `workflow_dispatch is recovery-only and recovery_ref must be an exact 40-character commit SHA or an existing tag.`, and `Publish to Hex` was skipped.
- Valid immutable ref proof: GitHub Actions run `24898785416` accepted the exact SHA `781d7189b1e9893a252cfca3e70153dc4a95ca79`, completed `Validate Recovery Ref`, and advanced to `Publish to Hex`, where it is waiting at the protected `hex-publish` environment gate.
- No deprecated Node 20 runtime warning appeared in the completed recovery-validation jobs for either run.

## Summary

total: 1
passed: 1
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
None.
