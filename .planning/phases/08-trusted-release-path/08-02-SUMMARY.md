---
phase: 08-trusted-release-path
plan: 02
subsystem: trusted-release-path
tags: [release, release-please, docs, config]
requires:
  - phase: 08
    plan: 01
    provides: canonical protected publish lane and review-only Release Please posture
provides:
  - checked-in Release Please manifest policy
  - explicit preview versioning policy for pre-1.0 releases
  - maintainer guidance aligned to a solo-maintainer protected-environment workflow
affects: [release-please-config.json, .release-please-manifest.json, .github/workflows/release.yml, docs/maintainer-release.md]
tech-stack:
  added: []
  patterns:
    - manifest-driven release-please
    - environment-scoped publish secret
    - reviewable release automation policy
key-files:
  created:
    - .planning/phases/08-trusted-release-path/08-02-SUMMARY.md
    - release-please-config.json
    - .release-please-manifest.json
  modified:
    - .github/workflows/release.yml
    - docs/maintainer-release.md
decisions:
  - Keep `mix.exs` as the human-edited package truth and move only Release Please automation policy into checked-in config files.
  - Treat `hex-publish` as a solo-maintainer secret and branch boundary instead of a second-person approval gate.
  - Keep `workflow_dispatch` recovery-only while normal publish intent still flows through Release Please on `main`.
requirements-completed: [RELS-02, RELS-03]
metrics:
  completed_date: 2026-04-23
---

# Phase 08 Plan 02 Summary

Lockspire now uses checked-in Release Please manifest configuration so preview release policy is reviewable in git rather than hidden in action inputs.

## Completed Work

- Added `release-please-config.json` and `.release-please-manifest.json` to encode the root package release strategy and explicit pre-`1.0` minor bump behavior.
- Updated `.github/workflows/release.yml` to use manifest mode via `config-file` and `manifest-file`.
- Rewrote `docs/maintainer-release.md` around the solo-maintainer protected-environment lane and explicit release policy evidence.

## Verification

- `mix package.build`
- `mix docs.verify`

## Deviations from Plan

- Solo-maintainer repo reality required replacing the earlier reviewer-approval assumption with an environment-scoped secret and branch-boundary model.

## Self-Check: PASSED
