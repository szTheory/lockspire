---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "02"
subsystem: acceptance
tags: [python, package-identity, lifetime-upgrade, provenance]
requires:
  - phase: 166-end-to-end-lifetime-security-guidance-proof
    provides: Packaged tracer, bounded receipt interface, and evidence map from plan 01
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Fixed lifetime semantics and migration compatibility contract
provides:
  - Pre-use verification for candidate archive, extracted tree, vendor copy, resolved dependency, and compiled Lockspire output
  - One candidate identity shared by public and tenant_auth upgrade legs
  - Focused stale-input and receipt-agreement regression tests
affects: [166-03, 166-08, 166-09, 166-10, 166-12]
tech-stack:
  added: []
  patterns: [content-digested package trees, pre-use resolver verification, compiled-candidate binding]
key-files:
  created:
    - test/acceptance/client_lifetime_package_identity_test.py
  modified:
    - scripts/acceptance/clean_room/package_input.py
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room/client_lifetime_upgrade.py
    - scripts/acceptance/clean_room/lifetime_receipts.py
decisions:
  - Build one Hex archive and extract that exact artifact for checkout candidates so the archive and unpacked bytes have a direct content relationship.
  - Reject work-root package, vendor, resolver, or compiled-state drift before scenario commands; do not accept an identity sampled after execution.
  - Keep the pinned legacy package identity distinct from the current candidate identity in upgrade receipts.
metrics:
  duration: 13min
  completed: 2026-10-21
  commits: 2
  plan_head_before: 6d5c4fd2493ba22192a25de7776647f675044a8c
  plan_head_after: 1679db6fcce037dc66bc454f5a997ae325cf3d95
status: complete
actuals:
  tokens: 9278
  tasks: 2
  commits: 2
---

# Phase 166 Plan 02: Candidate-Bound Lifetime Upgrade Proof Summary

**Reusable package proof hosts now verify archive, extracted, vendored, resolved, and compiled candidate identity before use, and both upgrade prefixes consume one candidate.**

## Accomplishments

- Added stable SHA-256 digests over sorted relative package paths and file bytes, and build checkout packages from one retained Hex archive before extraction.
- Reuse now verifies the retained archive against a fresh extraction, checks the extracted and vendor trees, confirms the Mix-resolved dependency path, and binds the compiled Lockspire app content to candidate metadata.
- The upgrade runner accepts an optional shared tarball, checksum, and source revision, prepares one candidate outside the prefix loop, and records matching archive/tree/source identities plus per-host provenance for both prefixes.
- Prepared legacy package trees are revalidated against the pinned archive and checksum. Legacy and candidate receipts remain separately identified.
- Fixed local tar symlink validation to inspect the input path before resolving it.

## Verification

- `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_package_identity_test.py' -v` — **8 tests passed, 0 failed**. Evidence includes one matching-candidate control; negatives for changed archive bytes, stale extracted bytes, stale vendor bytes, stale compiled output, a mismatched resolved dependency, and changed identity before scenario commands; and receipt identity agreement/rejection across legs.
- Python bytecode compilation for the four acceptance modules and the new test file — **passed**.
- `git diff --check` — **passed**.
- A local Hex package smoke check built and unpacked the actual checkout archive, verified stable identity on repeated work-root preparation, then rejected a corrupt archive at the same filename before provider setup.

The targeted Python checks do not prove the full PostgreSQL upgrade journeys, custom adapter leg, live CI, or independent security review. Those remain assigned to later Phase 166 plans; no full runtime journey is claimed here.

## Task Commits

1. **166-02-01: Reject stale archive, extracted, vendor and compiled input before execution** — `6fc4eacf`.
2. **166-02-02: Feed one verified candidate through every reusable upgrade host** — `1679db6f`.

## Deviations from Plan

**1. [Rule 2 - Missing security check] Reject symlinked package tar inputs before resolving paths**
- **Found during:** Task 2.
- **Issue:** The existing symlink check ran after `Path.resolve()`, which erased the symlink identity and could let a symlink pass as a regular tar file.
- **Fix:** Check the caller-supplied path for a symlink before resolving and validating its target.
- **Files modified:** `scripts/acceptance/clean_room/package_input.py`.
- **Commit:** `1679db6f`.

## Self-Check: PASSED

- All declared files exist.
- Task commits `6fc4eacf` and `1679db6f` are ancestors of the plan head.
- The task verification command passed again before close-out.
- Plan commit count measured from `6d5c4fd2493ba22192a25de7776647f675044a8c` to `1679db6fcce037dc66bc454f5a997ae325cf3d95`: **2**.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-21*
