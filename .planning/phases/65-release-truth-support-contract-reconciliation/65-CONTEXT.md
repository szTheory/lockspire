# Phase 65: Release Truth & Support Contract Reconciliation - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 65 reconciles Lockspire's package metadata, changelog posture, release automation, public support docs, and release-contract tests so they describe one truthful release story for the embedded Phoenix library surface.

This phase does not broaden Lockspire's supported feature set, create a second product shape, or turn release posture into a heavyweight compliance program. It narrows and aligns claims around what the repo and the protected publish lane can already prove.

</domain>

<decisions>
## Implementation Decisions

### Release Posture Baseline

- **D-01:** Converge the repo on a strict artifact-first `1.0.0` GA baseline for the embedded Phoenix library wedge.
- **D-02:** The next trusted publish from the protected release lane should be the first authoritative `1.0.0` artifact. Do not keep a long-lived mismatch where package metadata says `0.x` while support docs and tests claim `1.0.0`.
- **D-03:** Do not introduce a transitional `1.0.0-rc`, “GA-ready”, or similar limbo posture. It adds ambiguity without reducing real risk.
- **D-04:** If planning reveals a materially missing proof gap that would make `1.0.0` dishonest, the fallback is to align docs and tests back down to truthful `0.x` posture immediately rather than carry contradictory claims forward.

### Canonical Support Contract Shape

- **D-05:** `docs/supported-surface.md` is the single authoritative public support contract.
- **D-06:** `README.md` remains the public entrypoint and orientation layer only. It should summarize what Lockspire is, who it is for, and point readers to the canonical support contract rather than restating it in full.
- **D-07:** `SECURITY.md` remains subordinate to the canonical support contract. It should cover disclosure workflow and security-surface boundaries without broadening product claims.
- **D-08:** `docs/maintainer-release.md` is maintainer-facing release operations guidance, not a second public support contract.
- **D-09:** Other docs may explain install, Sigra companion use, or feature slices, but they must not independently redefine what Lockspire publicly supports.

### Changelog And Version History

- **D-10:** Preserve the published `0.1.x` and `0.2.0` history as factual release history. Do not rewrite tags, manifests, or changelog chronology to pretend earlier releases were already `1.0`.
- **D-11:** The coordinated `1.0.0` release should include an explicit changelog or release-note explanation that the public GA contract becomes authoritative with that release, rather than relying on earlier overstated doc language.
- **D-12:** Release communication should prefer truthful continuity over narrative cleanup. No retroactive history smoothing.

### Proof Boundary For Release Claims

- **D-13:** Public release and support claims should depend first on checked-in repo proof:
  - package version metadata
  - changelog posture
  - canonical support docs
  - checked-in release workflow and release config
  - executable release-contract tests
- **D-14:** GitHub protected-environment settings, secret placement, bypass posture, and successful trusted publish runs remain maintainer evidence. They support the release story but should not become a broad public support promise that depends on live operational state outside git.
- **D-15:** A narrow per-release proof artifact is acceptable if it strengthens least-surprise release truth, but it must stay supplemental:
  - it must not become a second public support contract
  - it must not claim live environment guarantees it cannot itself prove
  - it should be schema-testable and tightly scoped to release-lane execution facts
- **D-16:** Release-contract tests should enforce the hierarchy directly: canonical support contract first, maintainer evidence second, no contradictory version or posture language across docs, metadata, and workflow contracts.

### Workflow Preference

- **D-17:** For Phase 65 and adjacent adoption-truth work, shift medium-impact decision pressure left inside GSD researcher/planner flows. Default to decisive recommendation bundles rather than surfacing option menus for documentation structure, test shape, or release-automation details.
- **D-18:** Escalate to the user only for decisions that materially change product boundary, security posture, release posture, or public API/support guarantees.

### the agent's Discretion

- Exact wording for GA, support, and non-claim language across README, SECURITY, and maintainer docs.
- Exact shape of any supplemental per-release proof artifact, if one is added.
- Exact contract-test structure, file organization, and assertion granularity.
- Exact changelog phrasing for the `1.0.0` transition note, provided it preserves factual `0.x` history and makes the release-truth shift explicit.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle is:
  - one canonical public support contract in `docs/supported-surface.md`
  - README as entrypoint, not second contract
  - SECURITY as disclosure and security-boundary policy, not broad product posture
  - maintainer release docs as operational guidance only
  - honest preservation of `0.x` history
  - next protected release as the first real `1.0.0`
  - contract tests that assert cross-file version and posture consistency
  - optional narrow release-proof artifact only if it improves clarity without becoming a parallel truth source
- Ecosystem lessons worth carrying forward:
  - Ecto/Phoenix/Plug style favors README-as-orientation plus deeper versioned docs.
  - Successful auth libraries keep host/product boundaries narrow and explicit rather than relying on folklore or example-app implication.
  - The major footguns are duplicate support contracts, retroactive release-history cleanup, and public claims that depend on mutable operational state outside git.
- Principle of least surprise for Lockspire here means:
  - Hex version, changelog, docs, and tests all tell the same story
  - no “GA in docs, preview in package metadata” split
  - no support language that outruns repo proof

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone direction
- `.planning/ROADMAP.md` — Phase 65 goal, requirements, and success criteria
- `.planning/REQUIREMENTS.md` — `TRUTH-01` and `TRUTH-02`
- `.planning/PROJECT.md` — embedded-library thesis, release-quality posture, and v1.16 intent
- `.planning/STATE.md` — current milestone status and Phase 65 sequencing
- `.planning/METHODOLOGY.md` — decisive-defaults and least-surprise guidance for recommendation quality

### Prior phase decisions that constrain this phase
- `.planning/phases/63-canonical-install-path-host-diagnostics/63-CONTEXT.md` — one canonical path, host-boundary clarity, and shift-left workflow preference
- `.planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md` — canonical generated-host proof, support-truth guardrails, and no second topology
- `.planning/phases/47-1.0-ga-release-readiness/47-01-SUMMARY.md` — prior GA-posture milestone context and earlier `1.0.0` intent

### Public support and release posture surfaces
- `README.md` — public entrypoint and current release-positioning language
- `docs/supported-surface.md` — canonical support contract and current `1.0.0` GA wording
- `SECURITY.md` — supported security surface and disclosure posture
- `docs/maintainer-release.md` — maintainer release contract and evidence-bucket policy
- `CHANGELOG.md` — published release chronology and current `0.2.0` history

### Release metadata, workflow, and executable proof
- `mix.exs` — package version metadata and release aliases
- `release-please-config.json` — release policy
- `.release-please-manifest.json` — current published-line state
- `.github/workflows/release.yml` — protected publish lane and recovery-only dispatch contract
- `.github/actions/release-please/action.yml` — repo-controlled release-please boundary
- `test/lockspire/release_readiness_contract_test.exs` — current executable docs and release-truth guardrails

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/lockspire/release_readiness_contract_test.exs` already provides the main enforcement point for cross-file release-truth assertions.
- `docs/supported-surface.md` already exists in the right role conceptually; the phase should tighten authority and consistency rather than invent a new support-contract artifact.
- `.github/workflows/release.yml` and `.github/actions/release-please/action.yml` already model the protected publish lane and repo-controlled release automation boundary.
- `mix.exs`, `release-please-config.json`, and `.release-please-manifest.json` already centralize the package-version and release-policy truth that docs must follow.

### Established Patterns

- Lockspire prefers repo-owned executable proof over prose-only claims.
- Public product claims are meant to stay narrow and tied to the embedded Phoenix library wedge.
- Maintainer operational truth and user-facing support truth are intentionally separate concerns.
- Prior phases already locked a least-surprise, one-canonical-path posture that Phase 65 should mirror in release/support messaging.

### Integration Points

- Phase 65 planning should likely center around:
  - version and release-manifest alignment
  - support-doc hierarchy cleanup
  - changelog transition wording
  - release-workflow and proof-boundary tightening
  - release-contract test expansion for cross-file posture consistency

</code_context>

<deferred>
## Deferred Ideas

- Turning Lockspire’s release posture into a broader audited compliance or attestation program
- Creating a machine-generated schema as the primary human-facing support contract
- Broad enterprise marketing or certification language beyond the repo-proven embedded Phoenix surface

</deferred>

---

*Phase: 65-release-truth-support-contract-reconciliation*
*Context gathered: 2026-05-07*
