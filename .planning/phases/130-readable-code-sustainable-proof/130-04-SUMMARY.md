---
phase: 130-readable-code-sustainable-proof
plan: 04
status: complete
requirements: [TEST-02]
---

# Phase 130 Plan 04: Release Contract Split Summary

Split the 1,467-line release-readiness contract into three capability suites backed by shared parsing and path helpers. The concise umbrella suite now enforces the complete test-name inventory, rejects wrapper `Code.require_file` indirection, and holds the pre-split 588-assertion floor.

## Inventory

- Before: 1 file, 1,467 lines, 45 tests, 588 explicit `assert`/`refute`/`flunk` lines.
- After: 3 capability files (316, 220, and 713 lines), 45 moved tests, 588 moved assertion lines, plus 1 inventory test in an 86-line umbrella file and a 243-line shared helper.

## Old-to-new test mapping

Every original test moved exactly once. The executable copy of this mapping lives in `test/lockspire/release_readiness_contract_test.exs`.

### `release/release_automation_contract_test.exs` (9)

- maintainer guide keeps the review-only release pr posture and separate evidence buckets
- release workflow has one exact-CI-evidence publish lane
- ci and release cache restore keys stay scoped to the active beam pair
- release please automerge workflow only merges guarded bot release prs after green main ci
- repo-controlled release please action stays on a supported runtime and keeps root release outputs
- release metadata and workflow contracts agree on one checked-in version story
- release truth hierarchy stays canonical across metadata and docs
- release prep docs keep evidence buckets separate and avoid checked-in publish-proof claims
- workflow files keep contributor proof separate from the protected publish lane

### `release/repository_hygiene_contract_test.exs` (10)

- phase 115 hygiene separates local Docker checks from deterministic CI source checks
- phase 115 hygiene resolves the active Docker project like lifecycle helpers
- phase 115 local hygiene classifies Docker state with calm exact remediation
- phase 115 generated artifact hygiene is allowlisted and preserves admin UI evidence
- Hex package inputs stay slim and exclude local build artifacts
- phase 115 CI keeps Python smoke proof and avoids full Docker Compose smoke
- phase 115 CI and docs keep deterministic Docker validation only
- phase 115 repo hygiene stays repo-local and does not broaden public support surface
- phase 115 adoption demo docs stay repo-local without production Docker claims
- phase 115 CI source contracts prove lifecycle allowlists and public surface boundaries

### `release/support_surface_contract_test.exs` (26)

- adopter docs keep host account and operator boundaries explicit
- GA docs keep the embedded Phoenix wedge explicit and pin the narrow protected-route surface
- security and release posture stay inside the supported GA surface
- advanced-setup support contract stays pinned semantically across canonical and derived docs
- canonical lockspire_protected_api pipeline is byte-identical across the four RECIPE-01 sites
- mix lockspire.install never prompts for or branches on access-token format (SCAFFOLD-02, D-02 #1)
- install-template canonical lockspire_protected_api block stays fully commented (SCAFFOLD-01, D-02 #2)
- v1.27 migration guide pins the honest runtime opt-out and nil-inherit naming (MIGRATE-01, D-09/D-10)
- canonical lockspire_protected_api pipeline declares a non-empty audience: across all four RECIPE-01 sites (D-07)
- docs/saas-adoption-recipe.md cross-links to the canonical pipeline rather than restating plug names
- docs/protect-phoenix-api-routes.md carries the canonical pipeline declaration exactly once (D-15)
- maintainer and security docs defer to the canonical advanced-setup contract
- device-flow host guide keeps the verification seam abuse-control contract explicit
- private_key_jwt host guide teaches bounded reactive rollover diagnosis and fallback posture
- phase 31 onboarding and supported surface point to the verification seam truthfully
- sigra companion docs keep the host seam narrow and topology guidance truthful
- phase 58 docs and release contract pin the rar consent seam and discovery claims
- planning metadata and repo truth keep PAR scoped to the narrow v1.3 slice
- operator workflow docs keep PAR policy and effective requirement explicit
- supported surface and security docs distinguish capability from policy-resolved requirement
- phase 37 conformance docs and wiring stay tied to executable proof
- phase 42 preparatory lane docs stay truthful about certification and feature support
- phase 43 FAPI 2.0 milestone claims stay truthful and bounded (D-12, D-19, D-20)
- phase 73 JWT introspection support contract stays narrow and truthful
- phase 74 message-signing support contract distinguishes optional capability from strict enforcement
- all four RECIPE-01 sites order VerifyToken → EnforceSenderConstraints → RequireToken (BIND-03/D-05)

## Verification

- `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/release`
- `mix format --check-formatted test/support/release_contract_helpers.ex test/lockspire/release_readiness_contract_test.exs test/lockspire/release/*.exs`
- `MIX_ENV=test mix compile --warnings-as-errors`
- `mix credo --strict` on all five changed Elixir test/support files
