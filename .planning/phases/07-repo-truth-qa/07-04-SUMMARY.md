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
