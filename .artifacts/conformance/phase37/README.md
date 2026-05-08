# Phase 37 Historical Conformance Artifact Bundle

This directory is preserved as historical audit trail for the original Phase 37 external-lane attempt.
It is not authoritative current proof of Lockspire conformance support.

## What This Bundle Contains

- `run-summary.json` from the historical Phase 37 harness run
- `artifact-files.txt` listing the files saved in this bundle
- `phase37-plan.json` with the historical external-suite module subset

## Why It Is Non-Authoritative

- `run-summary.json` explicitly records `LOCKSPIRE_PHASE37_SKIP_SUITE=true`
- the `skipped` field says the OIDF Docker suite was skipped
- `exported_files` is empty, so no real external-suite export artifacts were captured

Because of that, do not use this directory as current proof that `CONF-04` or broad OIDF conformance was completed.

## How To Read It

- Treat these files as preserved raw history only
- Use [37-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md) for the authoritative record of the unresolved Phase 37 gap
- Use the repo-native strictness proof, Phase 66 milestone-closure artifacts, and current support-contract documents for the present trust story

## Current-Proof Hierarchy

For current proof, prefer:

1. `docs/supported-surface.md` for the canonical support contract
2. repo-native strictness proof and release-contract tests referenced by the Phase 66 closure artifacts
3. Phase 66 milestone closure documents for requirement-to-proof traceability

This bundle remains in the repo so auditors and maintainers can inspect the historical skipped-lane output without mistaking it for active evidence.
