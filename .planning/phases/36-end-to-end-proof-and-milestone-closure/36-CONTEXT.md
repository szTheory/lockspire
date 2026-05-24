# Phase 36: End-to-End Proof and Milestone Closure - Context

**Gathered:** 2026-04-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the shipped v1.7 DPoP slice end to end, expose the remaining runtime truth needed for
inspection, and synchronize milestone artifacts so the repo closes v1.7 from a stable,
truthful base. This phase is about executable proof, introspection visibility, and milestone
closure discipline. It is not a new protocol-surface expansion.

After this phase: the repo proves at least one browser-style authorization-code DPoP flow and
one CLI/device-oriented DPoP flow with the existing integration-test harness; introspection
reflects active DPoP token binding truth where appropriate; and the milestone planning docs
agree on what shipped and what should come next.

**Explicitly out of scope this phase:**
- New DPoP capabilities beyond the shipped v1.7 slice
- Generic host protected-resource middleware or broader resource-server claims
- A new acceptance harness, demo app, or proof path outside the repo-native integration suite
- Reframing the next milestone arc away from the existing real-integrator-readiness thesis

</domain>

<decisions>
## Implementation Decisions

### End-to-End Proof Strategy

- **D-01:** Phase 36 should extend Lockspire's existing repo-native integration-test style for
  DPoP proof rather than introduce a second acceptance harness or external demo-app layer.
- **D-02:** The browser-style proof should be an authorization-code DPoP flow that exercises the
  existing Phoenix/host-owned interaction path through real HTTP seams, not a protocol-only
  unit test.
- **D-03:** The CLI/device-oriented proof should build on the existing generated-host device-flow
  integration seam and keep device redemption proof in the same end-to-end style already used by
  Phase 32.
- **D-04:** Planner should prefer reuse and extension of the existing integration fixtures,
  helpers, and endpoint setup patterns before inventing new test scaffolding.

### Introspection Truth

- **D-05:** Introspection should expose durable DPoP binding truth for active DPoP-bound tokens by
  including `cnf` when present on the stored token.
- **D-06:** Introspection must preserve the current inactive-response collapse and confidential
  caller gate; Phase 36 extends the active-response truth only, not the authorization model or
  inactive semantics.
- **D-07:** The source of introspection DPoP truth remains the persisted token record, not client
  policy lookups or request-local assumptions.

### Public Surface Boundaries

- **D-08:** Phase 36 must keep the public DPoP support contract narrow: `/token` issuance,
  Lockspire-owned `userinfo`, and truthful introspection visibility for active bound tokens.
- **D-09:** Do not let docs, tests, or milestone-closure wording imply generic host
  protected-resource DPoP support or any broader sender-constrained surface than the repo proves.
- **D-10:** Release/support contract tests remain the enforcement backstop for public DPoP wording
  and should be extended only to reflect the shipped Phase 36 truth.

### Milestone Closure Discipline

- **D-11:** Phase 36 should treat `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`,
  `.planning/STATE.md`, `.planning/PROJECT.md`, and `.planning/EPIC.md` as the authoritative
  milestone-truth set that must close in sync.
- **D-12:** DPoP-12, DPoP-13, and DPoP-14 should not be marked complete until code proof, public
  docs, and planning artifacts all agree on the shipped slice and milestone outcome.
- **D-13:** `.planning/EPIC.md` should be updated as a milestone-boundary artifact that reflects
  what v1.7 delivered and preserves the current next-milestone selection logic grounded in repo
  truth.

### the agent's Discretion

- Exact file split for new integration tests may be chosen during planning as long as the proof
  stays in the repo-native integration suite and keeps browser/device coverage explicit.
- Exact active introspection response shape beyond adding `cnf` may be refined during planning if
  it remains standards-shaped and does not widen the public support claim.
- Exact milestone-close wording across docs and planning artifacts may evolve during planning so
  long as the narrow DPoP support contract remains truthful.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and closure targets

- `.planning/ROADMAP.md` — Phase 36 goal, requirements, and success criteria for browser/device
  proof, introspection truth, and milestone closure
- `.planning/REQUIREMENTS.md` — DPoP-12, DPoP-13, and DPoP-14 traceability targets
- `.planning/PROJECT.md` — embedded-library boundaries, truthful preview posture, and milestone
  update rules
- `.planning/STATE.md` — current milestone position and Phase 36 readiness
- `.planning/EPIC.md` — current long-range milestone arc that must stay synchronized with v1.7
  outcomes

### Prior phase decisions that constrain Phase 36

- `.planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md` — durable `cnf`
  truth, truthful `token_type: "DPoP"`, and shared issuance-path constraints
- `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md` — narrow
  DPoP support contract, Lockspire-owned `userinfo` scope, and explicit no-broader-resource
  boundary

### Existing code and proof seams to extend

- `lib/lockspire/protocol/introspection.ex` — active token response shape and current omission of
  `cnf`
- `lib/lockspire/protocol/token_exchange.ex` — shared auth-code and device token issuance path
- `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` — canonical auth-code end-to-end
  proof style
- `test/integration/phase15_par_authorization_e2e_test.exs` — browser-style hosted interaction and
  auth-code proof precedent
- `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` — existing device-flow and
  DPoP token-redemption end-to-end proof seam
- `test/lockspire/protocol/introspection_test.exs` — protocol-level introspection truth contract
- `test/lockspire/web/introspection_controller_test.exs` — HTTP introspection contract
- `docs/supported-surface.md` — canonical preview support wording for the shipped DPoP slice
- `test/lockspire/release_readiness_contract_test.exs` — release/docs contract enforcement backstop

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` already proves the canonical
  browser-style auth-code flow and can be extended or mirrored for DPoP coverage.
- `test/integration/phase15_par_authorization_e2e_test.exs` already exercises a fuller browser
  interaction path through authorize, consent, and token exchange using the repo-native harness.
- `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` already proves generated-host
  device verification plus DPoP token redemption and is the natural base for the CLI/device slice.
- `lib/lockspire/protocol/introspection.ex` already centralizes token introspection response
  shaping, so `cnf` exposure belongs there rather than in the controller.

### Established Patterns

- Lockspire uses repo-native integration tests as its end-to-end proof surface rather than external
  demo apps or parallel acceptance harnesses.
- Thin Phoenix controllers feed protocol-owned correctness and response shaping.
- Durable token truth lives on the stored token record, including `cnf`, rather than on mutable
  client policy or transport-only state.
- Public support wording is pinned by executable contract tests so docs cannot drift ahead of the
  repo-proven surface.

### Integration Points

- Browser-style DPoP proof should connect existing authorize/consent/token seams to a DPoP-mode
  public client and real proof headers on `/token`.
- Device/CLI proof should connect the generated-host `/verify` seam to DPoP device redemption and
  likely to introspection verification for the issued access token.
- Introspection changes belong in `lib/lockspire/protocol/introspection.ex` and must flow through
  both protocol and controller tests.
- Milestone closure work must update planning artifacts and release/support docs in tandem with the
  executable proof.

</code_context>

<specifics>
## Specific Ideas

- The cleanest Phase 36 shape is to prove the browser and device DPoP slices the same way Lockspire
  already proves earlier milestone truths: real HTTP integration tests inside the repo.
- Introspection should surface binding truth narrowly by exposing `cnf` for active DPoP-bound
  tokens, not by creating a broader token-inspection feature family.
- The phase should reinforce, not relax, the current claim that Lockspire proves DPoP only on
  `/token`, Lockspire-owned `userinfo`, and the related inspection/documentation surfaces already in
  repo scope.

</specifics>

<deferred>
## Deferred Ideas

- Generic host protected-resource middleware or Plug helpers for DPoP enforcement outside
  Lockspire-owned endpoints
- DPoP nonce support or broader sender-constrained protocol breadth beyond the v1.7 core
- New acceptance infrastructure separate from the repo-native integration suite
- Reprioritizing the next milestone away from the current adoption-hardening vs protocol-depth
  selection logic before v1.7 closes

</deferred>

---

*Phase: 36-end-to-end-proof-and-milestone-closure*
*Context gathered: 2026-04-28*
