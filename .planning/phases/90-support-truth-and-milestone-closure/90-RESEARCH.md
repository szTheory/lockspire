# Phase 90: Support Truth And Milestone Closure - Research

**Researched:** 2026-05-25
**Domain:** documentation truth, release-contract proof, and milestone-close closure for the narrow `client_secret_jwt` slice
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Support contract architecture
- **D-01:** Keep `docs/supported-surface.md` as the single canonical public support contract. README, onboarding, DCR, and maintainer docs must defer to it rather than becoming parallel support matrices.
- **D-02:** Phase 90 should use a narrow-but-complete documentation closure: update the canonical contract, add one dedicated `docs/client-secret-jwt-host-guide.md` sibling guide, and make only targeted edits to adjacent docs whose current wording would otherwise be stale or misleading.
- **D-03:** Do not merge `client_secret_jwt` into the existing `private_key_jwt` guide and do not create a broad “JWT client auth” umbrella guide in this phase.
- **D-04:** The new guide should mirror the shape of the existing `private_key_jwt` guide: what this covers, registration shape, assertion requirements, shipped endpoint scope, FAPI denial, host-owned responsibilities, and explicit non-goals.

### Shipped slice wording and non-claims
- **D-05:** Public docs must describe `client_secret_jwt` as a narrow direct-client convenience method for confidential clients only, available only on the Lockspire-owned shared direct-client endpoints already proven in Phase 88.
- **D-06:** Public docs must state the exact runtime posture plainly: `HS256` only, issuer-string `aud`, `iss`/`sub` equal to `client_id`, bounded lifetime, required `jti`, replay prevention, no silent fallback to `client_secret_basic` or `client_secret_post`, and standard fail-closed `invalid_client` wire behavior.
- **D-07:** Public docs must state the exact non-claims plainly: no `client_secret_jwt` on `PAR`, no broader generic JWT client-auth support, no `HS384`/`HS512`, and no FAPI, mTLS, or stronger-trust equivalence claim.
- **D-08:** Discovery- and support-surface wording must stay route-truthful rather than issuer-marketing-oriented.

### DCR, onboarding, and operator truth
- **D-09:** `docs/dynamic-registration.md` should document the exact DCR/RFC 7592 metadata shape for the shipped slice: `token_endpoint_auth_method=client_secret_jwt` plus explicit `token_endpoint_auth_signing_alg=HS256`, confidential-client-only posture, and full-replace update semantics.
- **D-10:** `docs/install-and-onboard.md` should remain brief and link to the dedicated `client_secret_jwt` guide the same way existing onboarding points to the `private_key_jwt` guide.
- **D-11:** Operator and partner truth must remain aligned: admin surfaces show read-only `HS256` truth, DCR surfaces show explicit metadata requirements, and raw secrets or raw assertions never reappear after issuance.
- **D-12:** `docs/maintainer-release.md` may mention the new slice only in deferential release-truth language that points back to `docs/supported-surface.md` and the dedicated guide.

### Proof and release-contract strategy
- **D-13:** Preserve Lockspire’s existing proof architecture rather than inventing a new one: runtime proof stays in the current client-auth tests, discovery proof stays split across builder-level and mounted-route tests, and docs/release truth gets closed with targeted contract assertions.
- **D-14:** Add a small test-only semantic helper for the shipped `client_secret_jwt` support facts so docs-contract and release-contract tests reuse one checklist without creating a second runtime source of truth.
- **D-15:** Docs and release contract tests should assert semantic anchors, not large prose snapshots.
- **D-16:** Keep controller-level discovery proof in addition to pure metadata-builder proof so mounted-route truth remains pinned.
- **D-17:** Extend `test/lockspire/release_readiness_contract_test.exs` minimally: verify the canonical contract and adjacent docs tell one coherent story about `client_secret_jwt`, but do not duplicate the full support matrix there.

### Deferred Ideas (OUT OF SCOPE)
- `client_secret_jwt` on `PAR` or any endpoint outside the shipped shared direct-client surface
- Broader HMAC algorithm support such as `HS384` or `HS512`
- Any FAPI-compatible or higher-trust `client_secret_jwt` posture
- A broad “JWT client authentication” umbrella guide or generic JWT client-auth framework
- Secret escrow, recoverable secret storage, or richer secret-management UX
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| META-02 | Lockspire's public support contract and security posture remain truthful after the milestone: `client_secret_jwt` is documented as a narrow direct-client option and does not broaden FAPI, mTLS, or stronger-trust claims. | Requires canonical support-page correction, a narrow sibling host guide, and targeted wording sync in onboarding/DCR/release docs. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `docs/private-key-jwt-host-guide.md`] [VERIFIED: `docs/install-and-onboard.md`] [VERIFIED: `docs/dynamic-registration.md`] [VERIFIED: `docs/maintainer-release.md`] |
| PROOF-01 | Repo-native automated tests cover positive and negative `client_secret_jwt` runtime behavior plus registration, discovery, admin, and documentation truth for the shipped slice. | Existing runtime/discovery proof already exists from Phases 88-89; Phase 90 needs support-truth contract tests that tie those proofs to docs and release posture. [VERIFIED: `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`] [VERIFIED: `test/lockspire/protocol/discovery_test.exs`] [VERIFIED: `test/lockspire/web/discovery_controller_test.exs`] [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`] |
</phase_requirements>

## Summary

Phases 88 and 89 already shipped the runtime, metadata, discovery, and admin truth for the narrow `client_secret_jwt` slice. The remaining gap is support-truth drift: `docs/supported-surface.md` still lists `client_secret_jwt` as out of scope, onboarding still points confidential-client JWT users only to `private_key_jwt`, the DCR guide does not yet explain the explicit `client_secret_jwt` plus `HS256` metadata shape, and the release-readiness contract has no semantic assertions pinning those docs to the now-shipped runtime. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `docs/install-and-onboard.md`] [VERIFIED: `docs/dynamic-registration.md`] [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`]

The narrowest safe Phase 90 design is the same doc architecture Lockspire already used successfully in Phase 87: correct the canonical support page first, add one dedicated `client_secret_jwt` host guide as a sibling to `private_key_jwt`, then make only the adjacent doc edits needed to keep onboarding, DCR, and maintainer release wording truthful. Proof should stay semantic and repo-native: one small test-only helper can define the support facts to assert across docs and release-contract tests without becoming a runtime truth store. [VERIFIED: `.planning/phases/87-RESEARCH.md`] [VERIFIED: `docs/private-key-jwt-host-guide.md`] [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`]

**Primary recommendation:** Split Phase 90 into three slices: canonical support-contract plus host-guide updates first, semantic support-truth contract tests second, and milestone-close alignment/deferred capture third. Plan 1 should establish the public wording and new guide IA. Plan 2 should add the automated proof layer that ties docs, discovery, and runtime together. Plan 3 should close the remaining adjacent docs and planning artifacts so milestone closure can happen without ambiguity. [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`]

## Current Shipped Truth And Exact Gaps

### 1. Canonical support truth is still stale

- `docs/supported-surface.md` still lists `client_secret_jwt` as explicitly out of scope even though Phases 88 and 89 shipped the runtime, discovery, and admin slice. [VERIFIED: `docs/supported-surface.md`]
- The same page already has the right information architecture for this fix: terse capability bullets in “Supported in scope,” terse denials in “Explicitly out of scope,” and a “GA bar” section that calls out narrow auth-method support. [VERIFIED: `docs/supported-surface.md`]
- The page must describe `client_secret_jwt` as direct-client-only, `HS256`-only, issuer-string `aud`, and FAPI-denied without restating the entire guide there. [VERIFIED: `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`]

### 2. The sibling-guide pattern already exists and should be mirrored

- `docs/private-key-jwt-host-guide.md` already has the right narrow structure for a companion guide: scope, registration shape, assertion requirements, endpoint scope, and host responsibilities. [VERIFIED: `docs/private-key-jwt-host-guide.md`]
- Phase 90 should mirror that shape for `docs/client-secret-jwt-host-guide.md` rather than broadening into a generic “JWT client auth” guide. [VERIFIED: `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`]
- The guide must explicitly say no `PAR`, no `HS384`/`HS512`, no FAPI or mTLS equivalence, and no broader trust claim. [VERIFIED: `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`]

### 3. Adjacent docs still point at the older truth

- `docs/install-and-onboard.md` currently tells confidential-client JWT users to read only the `private_key_jwt` guide. [VERIFIED: `docs/install-and-onboard.md`]
- `docs/dynamic-registration.md` still has generic DCR examples and no `client_secret_jwt` metadata example or explicit `HS256` requirement wording. [VERIFIED: `docs/dynamic-registration.md`]
- `docs/maintainer-release.md` correctly defers to `docs/supported-surface.md`, but its release-posture section still names `private_key_jwt` specifically and should be adjusted carefully so it remains truthful without becoming a second support matrix. [VERIFIED: `docs/maintainer-release.md`]

### 4. Repo-native proof needs one more layer: support-truth contract assertions

- Runtime proof already exists in `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` and related client-auth tests. [VERIFIED: `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`] [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`]
- Discovery proof already exists at both builder and controller levels and now covers the published `client_secret_jwt` slice. [VERIFIED: `test/lockspire/protocol/discovery_test.exs`] [VERIFIED: `test/lockspire/web/discovery_controller_test.exs`]
- Release-truth proof exists structurally in `test/lockspire/release_readiness_contract_test.exs`, but there are no semantic anchors yet for the newly shipped `client_secret_jwt` support story. [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`]
- A small helper module under `test/support/` is the cleanest place to centralize the semantic assertions reused by release-contract and any new doc-truth test without creating a runtime source of truth. [INFERRED from current ExUnit structure and locked decision D-14]

## Recommended Support-Truth Architecture

### Canonical page plus sibling guide

- Put one narrow support bullet in `docs/supported-surface.md` that names confidential-client `client_secret_jwt` on Lockspire-owned direct-client endpoints and pairs it with `HS256`-only plus FAPI denial language.
- Remove the stale “`client_secret_jwt`” bullet from “Explicitly out of scope,” but keep the broader out-of-scope bullet for generic JWT client-auth outside the shipped direct-client surfaces.
- Add `docs/client-secret-jwt-host-guide.md` as the sibling implementation guide and have adjacent docs link to it rather than duplicate its content. [VERIFIED: `docs/private-key-jwt-host-guide.md`] [VERIFIED: `docs/supported-surface.md`]

### Semantic proof instead of snapshot proof

- Add a helper that checks for semantic anchors such as:
  - `client_secret_jwt`
  - `HS256`
  - issuer-string `aud`
  - direct-client endpoint scope
  - `POST /par` exclusion
  - FAPI denial / non-equivalence
- Reuse that helper from `test/lockspire/release_readiness_contract_test.exs` and any phase-local support-truth test module, avoiding brittle full-paragraph snapshots. [VERIFIED: `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`] [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`]

## Validation Architecture

- **Framework:** ExUnit plus `mix docs.verify`
- **Quick docs/proof run:** `mix docs.verify && mix test test/lockspire/release_readiness_contract_test.exs`
- **Targeted runtime-truth run:** `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`
- **Full suite:** `mix test`
- **Why this is sufficient:** Phase 90 is documentation and contract-proof closure only; the runtime and discovery seams are already shipped and can be revalidated hermetically with repo-native tests. [VERIFIED: current test layout]

## Risks And Pitfalls

### Canonical-doc drift

- The highest risk is fixing only the new guide while leaving `docs/supported-surface.md` stale, which would preserve contradictory public claims. The canonical support page must change first. [VERIFIED: `docs/supported-surface.md`]

### Over-broad wording

- Phrases like “JWT client authentication” or “supported everywhere” would overstate the shipped slice and blur it with `private_key_jwt`, mTLS, or broader trust claims. [VERIFIED: `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`]

### Proof duplication

- Hard-coding the same semantic truth separately in release tests, doc tests, and prose snapshots would create another drift vector. One helper plus a few focused assertions is the safer contract pattern. [VERIFIED: `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`]

### Milestone-close ambiguity

- If deferred follow-on support work is not captured explicitly, the milestone could close while leaving the repo ambiguous about whether advanced diagnostics or broader auth-method support are still in-scope now. The closeout plan should record those items as deferred, not implied. [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/MILESTONE-ARC.md`]

## Recommended Plan Split

1. **Canonical support truth and host guide**: update `docs/supported-surface.md`, add `docs/client-secret-jwt-host-guide.md`, and link it from onboarding/DCR surfaces without duplicating the support matrix. [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `docs/private-key-jwt-host-guide.md`] [VERIFIED: `docs/install-and-onboard.md`] [VERIFIED: `docs/dynamic-registration.md`]
2. **Repo-native support-truth proof**: add a small semantic helper and extend release/docs contract tests to pin docs, discovery, and runtime truth together. [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`] [VERIFIED: `test/lockspire/protocol/discovery_test.exs`] [VERIFIED: `test/lockspire/web/discovery_controller_test.exs`] [VERIFIED: `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`]
3. **Milestone-close alignment and deferred capture**: update maintainer wording and any remaining adjacent guidance, then record deferred follow-on support work explicitly in the phase artifacts so milestone closure is crisp. [VERIFIED: `docs/maintainer-release.md`] [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/REQUIREMENTS.md`]

## Key Files For Planning

- `.planning/phases/90-support-truth-and-milestone-closure/90-CONTEXT.md`
- `docs/supported-surface.md`
- `docs/private-key-jwt-host-guide.md`
- `docs/install-and-onboard.md`
- `docs/dynamic-registration.md`
- `docs/maintainer-release.md`
- `test/lockspire/release_readiness_contract_test.exs`
- `test/lockspire/protocol/client_auth_test.exs`
- `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`
- `test/lockspire/protocol/discovery_test.exs`
- `test/lockspire/web/discovery_controller_test.exs`

## Metadata

**Confidence breakdown:**
- Documentation architecture: HIGH - the repo already uses the canonical-page plus sibling-guide pattern and Phase 87 proved it works for support-truth closure. [VERIFIED: `.planning/phases/87-RESEARCH.md`] [VERIFIED: `docs/private-key-jwt-host-guide.md`]
- Contract-test strategy: HIGH - the release-readiness contract already exists and just needs targeted semantic extensions. [VERIFIED: `test/lockspire/release_readiness_contract_test.exs`]
- Milestone-close posture: HIGH - the remaining risks are explicit wording drift and deferred-scope ambiguity, both directly visible in repo-local artifacts. [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/REQUIREMENTS.md`] [VERIFIED: `.planning/MILESTONE-ARC.md`]

## RESEARCH COMPLETE
