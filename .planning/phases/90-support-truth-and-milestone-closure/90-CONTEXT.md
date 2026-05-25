# Phase 90: Support Truth And Milestone Closure - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close milestone `v1.24 client_secret_jwt` with documentation, release-truth proof, and explicit defer posture that describe the shipped symmetric-JWT slice truthfully and narrowly. This phase does not widen runtime endpoint scope, broaden algorithm support, add new support tooling, or reopen the product boundary beyond the shipped direct-client `client_secret_jwt` slice.

</domain>

<decisions>
## Implementation Decisions

### Support contract architecture
- **D-01:** Keep `docs/supported-surface.md` as the single canonical public support contract. README, onboarding, DCR, and maintainer docs must defer to it rather than becoming parallel support matrices.
- **D-02:** Phase 90 should use a narrow-but-complete documentation closure: update the canonical contract, add one dedicated `docs/client-secret-jwt-host-guide.md` sibling guide, and make only targeted edits to adjacent docs whose current wording would otherwise be stale or misleading.
- **D-03:** Do not merge `client_secret_jwt` into the existing `private_key_jwt` guide and do not create a broad “JWT client auth” umbrella guide in this phase. The symmetric and asymmetric slices have materially different trust posture, registration shape, and support claims.
- **D-04:** The new `client_secret_jwt` guide should mirror the shape of the existing `private_key_jwt` guide: what this covers, registration shape, assertion requirements, shipped endpoint scope, FAPI denial, host-owned responsibilities, and explicit non-goals.

### Shipped slice wording and non-claims
- **D-05:** Public docs must describe `client_secret_jwt` as a narrow direct-client convenience method for confidential clients only, available only on the Lockspire-owned shared direct-client endpoints already proven in Phase 88.
- **D-06:** Public docs must state the exact runtime posture plainly: `HS256` only, issuer-string `aud`, `iss`/`sub` equal to `client_id`, bounded lifetime, required `jti`, replay prevention, no silent fallback to `client_secret_basic` or `client_secret_post`, and standard fail-closed `invalid_client` wire behavior.
- **D-07:** Public docs must state the exact non-claims plainly: no `client_secret_jwt` on `PAR`, no broader generic JWT client-auth support, no `HS384`/`HS512`, and no FAPI, mTLS, or stronger-trust equivalence claim.
- **D-08:** Discovery- and support-surface wording must stay route-truthful rather than issuer-marketing-oriented. Do not describe `client_secret_jwt` as “supported everywhere” or as a generic JWT auth capability.

### DCR, onboarding, and operator truth
- **D-09:** `docs/dynamic-registration.md` should document the exact DCR/RFC 7592 metadata shape for the shipped slice: `token_endpoint_auth_method=client_secret_jwt` plus explicit `token_endpoint_auth_signing_alg=HS256`, confidential-client-only posture, and full-replace update semantics.
- **D-10:** `docs/install-and-onboard.md` should remain brief and link to the dedicated `client_secret_jwt` guide the same way existing onboarding points to the `private_key_jwt` guide. Do not duplicate the support contract or setup guide in onboarding.
- **D-11:** Operator and partner truth must remain aligned: admin surfaces show read-only `HS256` truth, DCR surfaces show explicit metadata requirements, and raw secrets or raw assertions never reappear after issuance.
- **D-12:** `docs/maintainer-release.md` may mention the new slice only in deferential release-truth language that points back to `docs/supported-surface.md` and the dedicated guide. It must not restate a second semantic matrix.

### Proof and release-contract strategy
- **D-13:** Phase 90 should preserve Lockspire’s existing proof architecture rather than inventing a new one: runtime proof stays in the current client-auth tests, discovery proof stays split across builder-level and mounted-route tests, and docs/release truth gets closed with targeted contract assertions.
- **D-14:** Add a small test-only semantic helper for the shipped `client_secret_jwt` support facts so docs-contract and release-contract tests reuse one checklist without creating a second runtime source of truth.
- **D-15:** Docs and release contract tests should assert semantic anchors, not large prose snapshots. Favor a few durable assertions for endpoint scope, `HS256`-only posture, issuer-string `aud`, FAPI denial, and `PAR` exclusion over full-paragraph string matching.
- **D-16:** Keep controller-level discovery proof in addition to pure metadata-builder proof so mounted-route truth remains pinned.
- **D-17:** Extend `test/lockspire/release_readiness_contract_test.exs` minimally: verify the canonical contract and adjacent docs tell one coherent story about `client_secret_jwt`, but do not duplicate the full support matrix there.

### Planning and escalation posture
- **D-18:** Shift medium-impact decision-making left inside GSD for this phase and similar documentation-truth phases: downstream agents should default to research-first, codebase-first, decisive recommendations instead of surfacing menus of medium-value choices.
- **D-19:** Escalate only if a proposed change would materially alter the public support contract, widen the product boundary, broaden trust claims, add new endpoint scope, relax the `HS256`-only / FAPI-denied posture, or create a hard-to-reverse information architecture change.

### the agent's Discretion
- Exact section titles, page ordering, and wording details inside the canonical contract and new host guide
- Exact helper/module location for the test-only support-truth checklist
- Exact distribution of semantic assertions across docs-contract vs release-contract tests, provided support truth remains centralized and duplicate truth stores are avoided
- Exact cross-link wording between onboarding, DCR, maintainer, and host-guide docs

</decisions>

<specifics>
## Specific Ideas

- Use the same documentation architecture pattern Lockspire already used successfully in Phase 87: one canonical support contract plus targeted workflow guides that defer back to it.
- The strongest recommendation bundle is intentionally cohesive:
  canonical contract in `docs/supported-surface.md` -> narrow dedicated `client_secret_jwt` guide -> targeted onboarding/DCR/maintainer updates -> semantic docs/release contract tests.
- Good ecosystem lessons to preserve:
  Doorkeeper-style host seam and install DX, `node-oidc-provider`-style explicit feature truth, OpenIddict/Spring-style typed client-auth metadata and endpoint-scoped publication, and Elixir/ExDoc-style separation between support docs and task guides.
- Footguns to avoid:
  capability-blur language like “JWT client authentication” without qualifiers, merging `private_key_jwt` and `client_secret_jwt` into one broad guide, prose snapshot tests, duplicating endpoint/auth matrices across many tests, and any copy that implies stronger trust or broader endpoint coverage than runtime proves.
- Downstream recommendation posture should stay one-shot and decisive unless a question is genuinely product-shaping, materially irreversible, or strategically sensitive.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase boundary
- `.planning/PROJECT.md` — current v1.24 milestone goal, embedded-library boundary, and support-truth posture
- `.planning/REQUIREMENTS.md` — `META-02`, `PROOF-01`, support-truth gate, and out-of-scope guardrails
- `.planning/ROADMAP.md` — Phase 90 scope, plans, and success criteria
- `.planning/STATE.md` — current milestone state and closure framing
- `.planning/MILESTONE-ARC.md` — near-done judgment, stop rules, and why `client_secret_jwt` should close narrowly rather than broaden
- `.planning/EPIC.md` — historical arc and explicit “do not overbuild” posture
- `.planning/METHODOLOGY.md` — assumption-first recommendation mode, research-first decisive defaults, least-surprise host seam, and high-threshold escalation

### Prior phase truth
- `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md` — runtime contract, endpoint scope, `HS256`-only posture, and FAPI denial
- `.planning/phases/89-registration-discovery-and-admin-truth/89-CONTEXT.md` — persisted metadata, discovery, admin, and route-truth decisions
- `.planning/phases/87-CONTEXT.md` — prior support-truth phase pattern: canonical support page plus targeted adjacent docs and deferential maintainer docs

### Product and ecosystem guidance
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — embedded-library thesis, ecosystem comparisons, and scope-discipline lessons
- `prompts/lockspire-oauth-oidc-implementation-playbook.md` — intended package shape, host seam, and design lineage
- `prompts/lockspire-host-app-integration-seam.md` — explicit host/library ownership boundary
- `prompts/lockspire-market-gap-and-positioning.md` — narrow positioning and strategic guardrails against CIAM/hosted-auth drift
- `prompts/lockspire-release-readiness-and-conformance.md` — docs-as-contract and release-truth expectations
- `prompts/lockspire-security-posture-and-threat-model.md` — overclaiming and secret-handling boundaries relevant to client-auth wording
- `prompts/lockspire-elixir-oss-library-practices.md` — Elixir-native OSS docs, API, and release ergonomics
- `prompts/lockspire-operator-admin-ia-and-workflows.md` — operator workflow tone and information architecture expectations
- `prompts/lockspire-operator-ux-liveview.md` — calm operator UX and least-surprise copy principles

### Docs and proof surfaces to update against
- `docs/supported-surface.md` — canonical public support contract
- `docs/private-key-jwt-host-guide.md` — sibling narrow auth-method guide to mirror structurally
- `docs/install-and-onboard.md` — canonical onboarding path that should link to the new guide without duplicating it
- `docs/dynamic-registration.md` — DCR/RFC 7592 workflow guide that must describe the shipped metadata shape truthfully
- `docs/maintainer-release.md` — maintainer-only release truth that must defer to canonical support truth
- `test/lockspire/protocol/client_auth_test.exs` — runtime proof for valid/invalid `client_secret_jwt` behavior and redaction
- `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` — representative cross-endpoint runtime proof and `PAR` exclusion
- `test/lockspire/protocol/discovery_test.exs` — discovery metadata contract proof
- `test/lockspire/web/discovery_controller_test.exs` — mounted-route discovery truth proof
- `test/lockspire/release_readiness_contract_test.exs` — release/docs contract proof surface

### Research inputs for this phase
- `.planning/research/FEATURES.md` — v1.24 table-stakes, differentiators, anti-features, and non-claims
- `.planning/research/PITFALLS.md` — implementation and support-truth footguns to preserve in final docs/proof

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docs/private-key-jwt-host-guide.md`: existing narrow auth-method guide structure that the new `client_secret_jwt` guide should mirror
- `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`: already proves the representative direct-client surface and `PAR` exclusion
- `test/lockspire/protocol/discovery_test.exs` and `test/lockspire/web/discovery_controller_test.exs`: established split between builder-level and mounted-route discovery truth
- `test/lockspire/release_readiness_contract_test.exs`: existing contract-test home for canonical-doc and release-truth assertions

### Established Patterns
- Lockspire already centralizes public support truth in `docs/supported-surface.md` and expects adjacent docs to defer to it
- Prior milestone closures favor repo-native semantic proof over broad prose assertions or external/manual truth
- The repo already treats direct-client auth support as endpoint-local and profile-aware rather than globally advertised

### Integration Points
- Phase 90 should connect existing runtime proof, existing discovery proof, and updated docs/release wording without adding new runtime behavior
- The new host guide must integrate into the existing doc IA as a sibling to `docs/private-key-jwt-host-guide.md`, not as a new umbrella taxonomy
- Any test helper introduced for support truth must remain test-only and must not become a runtime truth source

</code_context>

<deferred>
## Deferred Ideas

- `client_secret_jwt` on `PAR` or any endpoint outside the shipped shared direct-client surface
- Broader HMAC algorithm support such as `HS384` or `HS512`
- Any FAPI-compatible or higher-trust `client_secret_jwt` posture
- A broad “JWT client authentication” umbrella guide or generic JWT client-auth framework
- Secret escrow, recoverable secret storage, or richer secret-management UX
- Expanded support tooling, diagnostics, or operator doctor work unless real adopter pain proves it is the next highest-leverage milestone

</deferred>

---

*Phase: 90-support-truth-and-milestone-closure*
*Context gathered: 2026-05-25*
