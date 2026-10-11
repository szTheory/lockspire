# Phase 143 Release Result

## Outcome

Lockspire 1.5.1 was published and independently verified. Phase 143's plan work is complete; the formal GSD verification report and v1.39 milestone closeout remain pending.

## Verified Publication

- Published source SHA: `0b56503859b69531ff86d8e4a465a0e75f963594`
- Matching canonical source CI [run 37788996197](https://github.com/szTheory/lockspire/actions/runs/37788996197) passed all seven required jobs on that exact SHA before dispatch; the current `main` is now `ef6e33be2d8bc8ac438390495990b231b475466c`.
- Protected release workflow: [run 37795671282](https://github.com/szTheory/lockspire/actions/runs/37795671282)
- Package: `lockspire` 1.5.1; public Hex SHA-256: `c13dabddef307dcb5d89490642272571e91d12bdf3fd14756e820600121df0b3`
- HexDocs, [lockspire-v1.5.1](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.1), and clean-room install were independently verified. The terminal receipt records `release_verified: true` and no blocker.
- Main CI [run 37800419349](https://github.com/szTheory/lockspire/actions/runs/37800419349) and Release push [run 37800419385](https://github.com/szTheory/lockspire/actions/runs/37800419385) passed on current `main`.
- PR #119 fixed the unsupported pinned GitHub App token input; PR #120 fixed evidence retention's receipt-schema mismatch.
- The one-use publication SHA was cleared and Release Please auto-merge was restored after publication proof.

The protected publish run's overall status was failure only because bounded evidence retention failed after publication and public verification. This did not invalidate the terminal receipt or public release proof.

## Earlier Failed Attempt

The first authorized attempt, run `37689835922`, failed before Hex upload at release-freeze token setup. Contemporaneous public queries correctly showed no 1.5.1 release. Its terminal receipt was also not retained because the docs-stage value did not match the receipt schema. Those observations describe that attempt and were superseded by the later verified publication above; see the details below.

## First Attempt Candidate (Historical)

- Source SHA: `e9e44667d0ee04e8978d14e007d6bc23666d29eb`
- Canonical CI: [run 37686090036](https://github.com/szTheory/lockspire/actions/runs/37686090036), all seven required jobs passed
- Protected release workflow: [run 37689835922](https://github.com/szTheory/lockspire/actions/runs/37689835922), authorized by the user and approved at `hex-publish`
- Staged package: `lockspire-1.5.1.tar`, 419,840 bytes, SHA-256 `c13dabddef307dcb5d89490642272571e91d12bdf3fd14756e820600121df0b3`
- Manifest SHA-256: `28264966e92da13a2629ed5513ed888d298897082dccb3ab3fd66ac6586ef80b`
- Prepublish proof: passed for Hex 2.5.1; the expected publish API export and exact-byte fixture both passed

## Public State at First Attempt (Historical)

Observed at 2026-10-07 21:59 UTC:

- Hex latest version is `1.5.0`; the exact Hex 1.5.1 release query returned HTTP 404, so no public checksum is available.
- The 1.5.1 HexDocs URL resolved to HTTP 404.
- GitHub release `lockspire-v1.5.1` and tag refs `lockspire-v1.5.1` / `v1.5.1` are absent (HTTP 404).
- Public install verification did not run because publication did not succeed.

These are fresh independent public queries; the missing workflow receipt is not being used as evidence of package absence.

## First Attempt Blockers (Resolved)

1. The publish job failed at **Mint scoped release freeze token**. `LOCKSPIRE_RELEASE_FREEZE_APP_ID` and `LOCKSPIRE_RELEASE_FREEZE_APP_PRIVATE_KEY` are absent from both repository and `hex-publish` environment configuration. The Hex upload, tag creation, GitHub release, and install-verification steps were skipped.
2. The terminal receipt job observed the docs endpoint as absent, then failed validation because the workflow supplied the presence value `absent` where the receipt schema requires `passed`, `failed`, `not_run`, or `unknown`. No `lockspire-release-terminal-receipt-37689835922` artifact was uploaded; the candidate records this handoff as unknown.

## First Attempt Cleanup (Completed)

- The one-use `LOCKSPIRE_PHASE143_AUTHORIZED_SHA` variable was deleted and verified absent.
- Release Please auto-merge was disabled after this first attempt; it was restored only after the later publication and verification succeeded.
- The missing GitHub App configuration was supplied, the pinned action input was corrected in PR #119, and receipt retention was corrected in PR #120. A replacement run was explicitly authorized and independently verified; approval for run `37689835922` was not reused.
