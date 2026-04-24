# Phase 16: Verification and Release Runtime Hygiene - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.2 PAR milestone with explicit verification and traceability for the already-shipped PAR slice, and remove the known deprecated release runtime warning without changing Lockspire's embedded-library shape, preview posture, or protected publish-lane contract.

</domain>

<decisions>
## Implementation Decisions

### Scope Boundary
- **D-01:** Phase 16 closes only `PAR-04` and `RELS-04`.
- **D-02:** Missing `10-VALIDATION.md`, `12-VALIDATION.md`, and `13-VALIDATION.md` remain separate planning/process debt and are not part of Phase 16 scope unless a concrete closure blocker is discovered during execution.
- **D-03:** If Nyquist completeness is still desired after v1.2, capture it as a discrete follow-up item rather than blending it into PAR milestone closure.

### PAR Closure Proof Style
- **D-04:** Reuse the existing PAR proof stack instead of creating a new Phase 16-specific test pyramid.
- **D-05:** Phase 16 proof should be traceability-first: `16-VALIDATION.md` and `16-VERIFICATION.md` map requirements to existing commands, files, and observed behavior.
- **D-06:** New tests are allowed only for a demonstrable `PAR-04` gap uncovered by traceability work. Do not duplicate already-proven protocol, web, integration, or discovery/truth-surface coverage for optics.
- **D-07:** Treat `test/integration/phase15_par_authorization_e2e_test.exs` as the canonical end-to-end PAR proof for milestone closure rather than cloning or rebranding it.

### Release Runtime Hygiene
- **D-08:** Preserve the current release policy and trust boundaries: Release Please remains the review-only release-PR engine, and Hex publishing remains a protected `hex-publish` environment action after merge.
- **D-09:** Make the smallest implementation change that removes the deprecated runtime warning while preserving current maintainer behavior and evidence boundaries.
- **D-10:** As of 2026-04-24, a pin-only upgrade of `googleapis/release-please-action` is blocked because the latest published action still declares `runs: using: node20`; plan Phase 16 around replacing the action implementation, not around changing the release policy.
- **D-11:** Do not broaden Phase 16 into release-process redesign, extra branches, or policy changes around trusted publish proof.

### Release Docs And Contract Strictness
- **D-12:** Update maintainer docs and repo-truth tests only where the checked-in release contract actually changes.
- **D-13:** Keep release contract checks focused on durable behavioral invariants: review-only Release Please posture, recovery-only `workflow_dispatch`, protected `hex-publish` environment use, `mix ci` for contributors, and `mix release.preflight` plus `mix hex.publish --yes` inside the trusted lane.
- **D-14:** Avoid over-specifying incidental action internals or brittle literal wording when that wording is not itself part of the maintainer or support contract.
- **D-15:** Do not change README, SECURITY, or supported-surface posture unless the public release claim itself changes. Runtime hygiene must not imply broader product maturity.

### the agent's Discretion
- Downstream agents should prefer research-backed, one-shot recommendations that are coherent across planning artifacts and minimize user interruption.
- Only escalate a decision back to the user when it materially changes Lockspire's trust boundaries, supported surface, or milestone scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone And Scope
- `.planning/ROADMAP.md` — Phase 16 goal, requirements mapping, and success criteria.
- `.planning/REQUIREMENTS.md` — `PAR-04` and `RELS-04` closure target.
- `.planning/PROJECT.md` — milestone thesis, release posture, and active requirements.
- `.planning/STATE.md` — current blocker, pending todo, and phase handoff state.

### Prior Phase Verification Shape
- `.planning/phases/14-pushed-request-intake/14-VALIDATION.md` — earlier PAR validation format and Nyquist context.
- `.planning/phases/15-authorization-consumption-and-truthful-surface/15-VALIDATION.md` — canonical per-task verification mapping to reuse.
- `.planning/phases/15-authorization-consumption-and-truthful-surface/15-VERIFICATION.md` — proof style and evidence structure for milestone closure.

### Release Contract And Truth Surfaces
- `.github/workflows/release.yml` — current trusted release lane and publish boundary.
- `docs/maintainer-release.md` — maintainer contract and release evidence boundaries.
- `release-please-config.json` — Release Please policy configuration to preserve.
- `.release-please-manifest.json` — release manifest state to preserve.
- `test/lockspire/release_readiness_contract_test.exs` — repo-truth fence around release posture and docs.

### Existing PAR Proof Harnesses
- `test/lockspire/protocol/authorization_request_test.exs` — protocol proof for PAR consumption and negative paths.
- `test/lockspire/web/authorize_controller_test.exs` — browser-surface PAR proof.
- `test/integration/phase15_par_authorization_e2e_test.exs` — canonical PAR end-to-end proof.
- `test/lockspire/web/discovery_controller_test.exs` — discovery truth contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/lockspire/protocol/authorization_request_test.exs`: already covers PAR success, expiry, replay rejection, wrong-client burn, and mixed-input rejection.
- `test/lockspire/web/authorize_controller_test.exs`: already proves browser-facing PAR success and failure behavior.
- `test/integration/phase15_par_authorization_e2e_test.exs`: already proves the end-to-end `/par -> /authorize -> /token` path.
- `test/lockspire/web/discovery_controller_test.exs` and `test/lockspire/release_readiness_contract_test.exs`: already pin truth-surface and release-posture behavior.

### Established Patterns
- Lockspire phases prefer focused ExUnit entrypoints plus explicit validation/verification artifacts instead of broad, duplicative mega-suites.
- Repo-truth tests guard support posture and release policy at the documentation/workflow boundary.
- The release lane separates contributor proof (`mix ci`) from trusted publish proof (`mix release.preflight` and `mix hex.publish --yes` in `hex-publish`).

### Integration Points
- Phase 16 planning should connect new verification artifacts to the existing Phase 15 proof files, not create a competing proof surface.
- Release-runtime work should stay confined to `.github/workflows/release.yml`, Release Please configuration, maintainer docs, and release contract tests.

</code_context>

<specifics>
## Specific Ideas

- Favor a traceability-first closure package: write Phase 16 artifacts that explain why the current proof is enough, then add only genuinely missing evidence.
- Keep release-runtime hygiene narrow: replace the Node 20-bound Release Please action implementation only because upstream still ships on Node 20 as of 2026-04-24; do not reinterpret that as a policy or product-posture change.
- Discussion preference captured for downstream agents: research broadly, synthesize decisively, and interrupt the user only for truly high-impact tradeoffs.
- External ecosystem signals that informed these decisions:
  - `googleapis/release-please-action` still documents `@v4` usage while the published `v4.4.0` action metadata declares `runs: using: node20`.
  - GitHub's 2025-09-19 deprecation notice requires actions maintainers to move to Node 24 and asks action users to adopt versions that run on Node 24.
  - OpenIddict emphasizes modular protocol core plus host-specific integration layers and leaves end-user authentication to the host.
  - `oidc-provider` emphasizes mountable integration, optional feature enablement, events, and protocol seriousness without forcing a separate hosted service.
  - Doorkeeper's docs reinforce secure-by-default protocol features like PKCE and hashed secrets, but also show the maintenance cost of overly coupled test/setup guidance.

</specifics>

<deferred>
## Deferred Ideas

- Revisit missing `10-VALIDATION.md`, `12-VALIDATION.md`, and `13-VALIDATION.md` as separate planning debt after v1.2 if full Nyquist completeness remains a project goal.
- Any broader release-lane refactor beyond removing the runtime warning belongs in a separate phase.

</deferred>

---

*Phase: 16-verification-and-release-runtime-hygiene*
*Context gathered: 2026-04-24*
