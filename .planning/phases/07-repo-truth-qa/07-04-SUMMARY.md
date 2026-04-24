---
phase: 07-repo-truth-qa
plan: 04
subsystem: qa
tags: [release-gates, ci, docs, workflows, contract-tests]
requires:
  - phase: 07-02
    provides: truthful green `mix qa` lane on the maintained development path
  - phase: 07-03
    provides: deterministic maintained integration and phase3 test lanes
provides:
  - machine-readable GATE-02 closure metadata for the gate-contract plan
  - a documented contributor-versus-maintainer gate split aligned to repo truth
affects: [release-hardening, contributor-gates, ci, workflows, docs]
tech-stack:
  added: []
  patterns:
    - one canonical `mix ci` contributor gate
    - additive maintainer-only `mix release.preflight` lane
key-files:
  created: []
  modified:
    - mix.exs
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - docs/maintainer-release.md
    - test/lockspire/release_readiness_contract_test.exs
key-decisions:
  - "The contributor-facing truth lane remains `mix ci`, while `mix release.preflight` stays additive and maintainer-only."
patterns-established:
  - "Gate-contract summaries in Phase 07 carry structured frontmatter so requirement closure remains machine-readable."
requirements-completed: [GATE-02]
completed: 2026-04-23
---

# 07-04 Summary

## Outcome

Closed the Phase 7 gate-story drift by aligning `mix ci`, maintainer docs, workflow expectations, and the release-readiness contract tests around one maintained contributor lane and one additive maintainer release lane.

## What Changed

- Updated `mix.exs` so the contributor gate is explicitly composed from the maintained repo-truth steps and the Hex-backed non-publish checks are run non-interactively inside the lane's shell-outs.
- Added a project Hex override so intentional `HEX_API_KEY` injection still wins, while repo-owned checks do not depend on a stale local API key value.
- Tightened `test/lockspire/release_readiness_contract_test.exs` to assert the canonical `mix ci` story, the additive `mix release.preflight` story, and the required workflow step equivalence.
- Updated `docs/maintainer-release.md` so contributor and maintainer responsibilities match the executable contract.
- Restored fast-lane truth by fixing `Lockspire.Protocol.AuthorizationFlow` transaction result normalization and by restoring expected admin token detail and telemetry fields in `Lockspire.Admin.Tokens`.

## Verification

- `mix test test/lockspire/release_readiness_contract_test.exs`
- `mix qa`
- `mix docs.verify`
- `MIX_ENV=test mix test.fast`
- `MIX_ENV=test mix test.integration`
- `MIX_ENV=test mix test.phase3`
- `env HEX_HOME=\"$tmpdir\" mix deps.audit`
- `env HEX_HOME=\"$tmpdir\" mix package.build`

## Notes

- In this shell, a stale global Hex auth cache can still prompt before bare `mix ci` reaches repo code. The repo-owned gate pieces were therefore revalidated directly, and the Hex-backed steps were rerun in an isolated `HEX_HOME` to prove repo truth without relying on machine-local credentials.
