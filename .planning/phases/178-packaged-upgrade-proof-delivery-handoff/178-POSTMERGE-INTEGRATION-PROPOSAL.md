# Postmerge checker correction — ready for integration approval

Status: **proposed; no remote changes performed**.

Source: `9ffe69f122f9a1d2fd3821ee0bf0bcbf5635094a` on local branch `fix/v148-squash-acceptance`, based on squash main `b55eaafc6b01273aad6b72dc6d6301c76cf7fd4f`. Later proposal/evidence commits retain identical selected source bytes. The current canonical authorization record and main-acceptance receipt are absent.

The requested approval covers one non-force branch push, creation of a reviewed correction PR with the body below, and merging that correction after all required CI passes. It also covers recording that actual user approval in the exact Phase 178 authorization file, synchronizing main after the merge, and running fresh exact-main acceptance. A successful exact-main receipt is required before milestone archiving. Release publication and UI implementation remain separate work.

After approval, add `.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-INTEGRATION-AUTHORIZATION.json` with schema `lockspire-phase178-integration-authorization-v1`, status `authorized`, candidate_sha `9ffe69f122f9a1d2fd3821ee0bf0bcbf5635094a`, authorized_by identifying the actual approving user, and authorized_at set to the actual approval time in UTC `YYYY-MM-DDTHH:MM:SSZ`. This proposal itself grants no authority. The authorization addition is metadata; the selected source must remain byte-identical to the revision above.

For exact-main acceptance, use a fresh private clone synchronized with authoritative GitHub main, the pinned Elixir 1.19.5, OTP 28.5, and Hex 2.6.0 builder, and a fresh owned PostgreSQL target on an explicit private port. Use the existing helper with `--accept-sha`, the exact authorization-record path, `--format json`, matching push-CI/Release identities and observed warning dispositions. Copy only required retained evidence with verified digests and owner-only manifest modes. Keep the protected root tar and earlier private data untouched; retain actual helper output and owned-source manifest. Revalidate the accepted handoff before archiving v1.48. Historical candidate validation remains separate from this fresh main gate.

## Proposed PR title

fix: accept reviewed squash history and preserve postmerge evidence

## Proposed PR body

### Summary

Fix v1.48 main acceptance after PR #141's squash merge. The checker now authenticates squash integration and closed-PR checkout ownership while keeping historical source/package proof separate from the fresh main gate. Both future proof jobs provision their exact checkout as new job-owned source.

```text
squash integration -> merged origin PR + identical full tree + containment in main
closed candidate  -> original attempt/jobs + seven authenticated checkout logs
historical proof  -> original checkout, source/package bytes, and receipt owners
future CI         -> package and frozen manifest from exact github.sha
accepted main     -> fresh owned gate + exact push CI/Release + approval custody
```

### Evidence

- Before: reviewed head `4a90525c` and squash `b55eaafc` have the same full Git tree and 1,079 selected input hashes, but ordinary ancestry is false. GitHub also removed the old run's PR association and temporary merge ref.
- After: the final native Python suite passed **300 tests**, zero failures/errors/skips/unexpected successes; source hashes stayed unchanged. Both complete ordinary-merge and postmerge-squash handoff chains passed adversarial provenance/log/attempt/source mutations. Actionlint and whitespace checks passed; hygiene passed18/0/0.
- Live historical candidate revalidation passed all seven original jobs and both exact attempt 2 artifacts: **26 receipts/64 cases**. E7AD / c465 / 3c7bd remain their original execution identities. Raw job logs stay in memory.
- Native exact-checkout provisioning at `9ffe69f1` passed 1,079 selected inputs with clean source afterward. Archive `eea947dd` and tree `01285ffc` match the original qualified package. No app/database started; protected root package stayed unchanged.
- PR #141's actual postmerge CI `40987320716` and no-publish Release `40987320718` succeeded at `b55eaafc`. The correction needs its own hosted CI and fresh exact-main acceptance. Formal coverage remains PARTIAL; earlier failures, unknowns and custody limits remain recorded.

Verification records are `178-POSTMERGE-DEBUG-TESTS-CHECKOUT-PINS.json`, `178-POSTMERGE-CANDIDATE-VALIDATION.json`, `178-POSTMERGE-NATIVE-PROVISION.json`, and `.planning/debug/v148-postmerge-acceptance.md`.

### Merge Danger

**Door:** Two-way.

**Blast Radius:** Delivery.

The change affects acceptance provenance and CI source selection. Exact-main acceptance remains required after integration.
