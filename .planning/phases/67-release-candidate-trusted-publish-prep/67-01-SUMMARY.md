---
phase: 67
plan: 67-01
subsystem: release-candidate
tags:
  - release
  - metadata
  - changelog
  - release-please
key-files:
  modified:
    - mix.exs
    - release-please-config.json
    - CHANGELOG.md
metrics:
  tasks_completed: 2
  tasks_total: 2
  completed_at: 2026-05-07
---

# Phase 67 Plan 01 Summary

Explicit `1.0.0` release-candidate contract for the root `lockspire` package and expected `lockspire-v1.0.0` tag target, kept strictly pre-publish.

## Execution Results

- Tightened `mix.exs` package posture so the Hex-facing description clearly stays on the embedded-library shape and package links now point readers at the canonical supported surface.
- Made `release-please-config.json` explicitly preserve the root release tag shape with `include-v-in-tag`, `component`, and `include-component-in-tag` aligned to the existing `lockspire-v...` changelog history and root package name.
- Reworded the `1.0.0` changelog entry so it describes a checked-in release-candidate contract rather than implying authenticated publish proof already happened.

## Verification

- `VERSION=$(perl -ne 'print "$1\n" if /version:\s+"([0-9][0-9.]*)"/' mix.exs | head -1) && MANIFEST=$(perl -ne 'print "$1\n" if /"\."\s*:\s*"([0-9][0-9.]*)"/' .release-please-manifest.json | head -1) && test -n "$VERSION" && test "$VERSION" = "$MANIFEST" && rg "^## \[$VERSION\]" CHANGELOG.md && ! rg '1\.0\.0-rc|GA-ready|preview release candidate' CHANGELOG.md`
- `rg '"package-name": "lockspire"|"\.": "1\.0\.0"|release-type": "elixir"' release-please-config.json .release-please-manifest.json && rg '^## \[1\.0\.0\]' CHANGELOG.md && ! rg '1\.0\.0-rc|component tag|alternate package' CHANGELOG.md release-please-config.json .release-please-manifest.json`
- `mix test test/lockspire/release_readiness_contract_test.exs`

## Deviations from Plan

None.

## Known Stubs

None.

## Self-Check: PASSED
