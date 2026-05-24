# Phase 42: FAPI 2.0 Advanced Cryptography and OIDF Test Suite Prep - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn `security_profile: :fapi_2_0_security` into a trustworthy cryptographic contract for
Lockspire-owned JWT surfaces by enforcing `ES256`/`PS256` only where Lockspire creates,
verifies, selects, activates, publishes, or advertises signing algorithms. In the same phase,
pin the OpenID Foundation conformance workflow into the repo as executable maintainer wiring,
but defer full end-to-end FAPI proof and release-claim closure to Phase 43.

After this phase:
- A FAPI-effective Lockspire path does not silently accept, emit, or advertise `RS256`.
- Existing non-FAPI clients and legacy keys can still exist durably under explicit mixed-mode
  boundaries, but cannot leak into FAPI-effective runtime behavior.
- Maintainers have a repo-native OIDF harness/preflight lane that is wired, documented, and
  truth-checked, without overstating final conformance completion.

**Explicitly out of scope this phase:**
- Full milestone-close FAPI discovery/compliance claim closure from FAPI-06 (Phase 43)
- Broad new protocol surface beyond cryptographic tightening and conformance harness prep
- A new compatibility or quarantine state machine for legacy keys/clients
- Global GSD profile changes outside this project; capture the user preference locally for
  downstream planning behavior instead
</domain>

<decisions>
## Implementation Decisions

### Profile-Wide Cryptographic Contract

- **D-01:** Treat `security_profile: :fapi_2_0_security` as a Lockspire-wide cryptographic
  contract, not a boundary-only hint. Under a FAPI-effective resolved profile, Lockspire must
  use one canonical algorithm policy for every Lockspire-owned surface that creates, verifies,
  selects, activates, publishes, or advertises signing algorithms.
- **D-02:** The FAPI algorithm subset for this phase is exactly `["ES256", "PS256"]`. Even
  though broader ecosystems may permit more, Lockspire must advertise and enforce only the
  algorithms it is intentionally supporting in this milestone. `EdDSA` stays out until it is a
  deliberate supported surface.
- **D-03:** The canonical algorithm policy must be exported from one protocol-owned source and
  reused everywhere, following the existing DPoP truth-from-validator pattern. Planning may
  choose the exact module shape, but there must not be hand-maintained per-surface constants.
- **D-04:** The contract applies to both acceptance and emission surfaces. At minimum, planning
  must align JAR/request-object validation, DPoP proof validation/challenges, ID token signing,
  logout token signing, end-session `id_token_hint` verification, key generation defaults,
  signing-key activation/publishing, JWKS output, and discovery algorithm metadata with the same
  resolved-profile truth.
- **D-05:** Existing hardcoded `RS256` paths are bugs under FAPI-effective behavior, not
  acceptable exceptions. They must be either made profile-aware or explicitly scoped to non-FAPI
  behavior only.

### Mixed-Mode Key and Rejection Policy

- **D-06:** Use fail-fast rejection at write/activation boundaries for FAPI-effective state,
  with runtime checks retained as defense in depth. Lockspire should not allow a server policy,
  client update, key activation, key publication, or dynamic-registration intake result that it
  already knows will be unusable under the resolved FAPI profile.
- **D-07:** Preserve the existing mixed-mode model from Phase 41. Legacy non-FAPI clients and
  legacy durable keys may remain in storage when their effective profile is `:none`, but they
  must not be activatable, publishable, selectable, or discoverable for FAPI-effective use.
- **D-08:** Do not introduce a new quarantine lifecycle. Reuse existing durable state plus clear
  validation errors and operator messaging. The right model is "stored but not FAPI-eligible"
  for legacy rows, not a second policy system.
- **D-09:** Enabling global FAPI mode should fail clearly unless the server has a compliant
  signing posture ready for use. Similarly, opting a client into FAPI should fail clearly when
  its algorithm metadata or runtime dependencies would be incompatible.
- **D-10:** Operator/admin and DCR errors must explain the next fix, not just the violation.
  The UX should point maintainers toward rotating/generating a compliant key or changing the
  client/profile setting rather than forcing them to infer the remediation from a generic error.

### Truthful Publication and Discovery

- **D-11:** Existing algorithm publication surfaces must remain truthful to runtime support. If
  Lockspire publishes signing or proof algorithms in discovery, JWKS, or challenges, those
  values must come from the same canonical resolved-profile policy that runtime enforcement uses.
- **D-12:** Phase 42 should tighten the truth of algorithm-related metadata already published
  today; Phase 43 remains the place to add the broader FAPI compliance metadata and final
  milestone closure story.

### OIDF Harness Depth

- **D-13:** Phase 42 should add repo-native OIDF harness wiring now, but stop short of claiming
  full end-to-end validation completion. This means checked-in maintainer docs, deterministic
  env-var contracts, a `mix`/script entrypoint, artifact output expectations, and release-truth
  tests that pin the documented workflow.
- **D-14:** Phase 43 should consume that harness as the proof lane rather than building it from
  scratch. The planning goal for Phase 42 is to make Phase 43 about behavior validation, not
  tooling assembly.
- **D-15:** Do not collapse all external-suite pass/fail responsibility into Phase 42. That
  would blur the roadmap boundary and increase the chance of making premature support claims.

### Developer Ergonomics and Planning Style

- **D-16:** Downstream agents should default to opinionated, cohesive recommendations that align
  with Lockspire’s product and architecture values, and only escalate choices that materially
  change product posture, support claims, or migration risk. Use the principle of least surprise
  and calm operator UX as the tie-breakers.

### the agent's Discretion

- The exact module name for the canonical algorithm-policy export may be chosen during planning if
  it stays protocol-owned and is reused by every Lockspire-owned signing/verification surface.
- The exact split between Ecto changeset validation, admin-boundary validation, and runtime
  guards may be chosen during planning so long as write-boundary fail-fast behavior remains true
  for FAPI-effective state.
- The exact `mix` alias and script naming for the OIDF harness can follow existing conformance
  conventions if the workflow stays deterministic and artifact-backed.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and current milestone state

- `.planning/ROADMAP.md` — Phase 42 goal/success criteria and Phase 43 boundary
- `.planning/REQUIREMENTS.md` — FAPI-04 and adjacent milestone requirements
- `.planning/PROJECT.md` — embedded-library boundaries, truthful posture, and operator/DX values
- `.planning/STATE.md` — Phase 41 completion notes and current FAPI milestone state

### Prior phase decisions that constrain this phase

- `.planning/phases/41-fapi-2-0-profile-configuration/41-CONTEXT.md` — FAPI profile model,
  mixed-mode semantics, and boundary enforcement decisions already locked
- `.planning/phases/40-jwe-support-for-request-objects/40-CONTEXT.md` — signing-key expansion,
  JAR/JWE algorithm allow-list precedent, and key-store seams
- `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md` — single
  source of truth for advertised algorithms and truthful discovery/support-surface pattern

### Existing implementation surfaces to extend

- `lib/lockspire/protocol/security_profile.ex` — current resolved-profile model and algorithm list
- `lib/lockspire/protocol/dpop.ex` — current validator-owned algorithm truth pattern
- `lib/lockspire/protocol/discovery.ex` — truth-based metadata builder with current `RS256`
  default publication
- `lib/lockspire/protocol/id_token.ex` — profile-aware ID token signing path
- `lib/lockspire/protocol/jar.ex` — request-object verification seam
- `lib/lockspire/protocol/logout_token.ex` — currently hardcoded `RS256` logout signing path
- `lib/lockspire/protocol/end_session.ex` — currently hardcoded `RS256` `id_token_hint`
  verification path
- `lib/lockspire/web/controllers/userinfo_controller.ex` — DPoP challenge algorithm publication
- `lib/lockspire/admin/keys.ex` — key generation/activation operator seam
- `lib/lockspire/security/policy.ex` — key compliance and boot/runtime invariant helper
- `lib/lockspire/storage/key_store.ex` — key-store contract
- `lib/lockspire/storage/ecto/repository.ex` — durable signing-key persistence and activation
- `lib/lockspire/storage/ecto/client_record.ex` — client algorithm enum/storage boundary

### Existing tests and docs to preserve/extend

- `test/lockspire/protocol/security_profile_test.exs` — current profile algorithm expectations
- `test/lockspire/protocol/dpop_test.exs` — proof validation behavior
- `test/lockspire/protocol/jar_test.exs` — request-object signing validation behavior
- `test/lockspire/protocol/id_token_test.exs` — ID token signing expectations
- `test/lockspire/protocol/logout_token_test.exs` — logout token signing expectations
- `test/lockspire/web/discovery_controller_test.exs` — published algorithm truth assertions
- `test/integration/phase41_fapi_2_0_e2e_test.exs` — current FAPI enforcement proof lane
- `test/lockspire/release_readiness_contract_test.exs` — truth-in-docs/release-contract guardrail
- `docs/maintainer-conformance.md` — existing maintainer workflow to evolve
- `scripts/conformance/fapi2-check.sh` — existing local FAPI probe script
- `.github/workflows/oidf-conformance.yml` — existing repo-native conformance workflow pattern

### Specification authority and external ecosystem signals

- `FAPI 2.0 Security Profile` — allowed JWT algorithms and profile-wide cryptographic posture
- `RFC 8725` — JWT BCP for explicit algorithm allow-lists and key/alg binding
- `RFC 7591` — reject inconsistent dynamic client metadata early
- `OpenID Connect Discovery 1.0` — discovery algorithm metadata must reflect actual support

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `SecurityProfile.Resolved` already gives Lockspire a durable resolved-profile carrier that can
  drive algorithm policy consistently across runtime and admin seams.
- `DPoP.signing_alg_values_supported/1` already demonstrates the right pattern: advertise the
  same list the validator enforces.
- `IdToken.sign/1` is already profile-aware, so it is a useful precedent for making other owned
  JWT surfaces profile-aware instead of hardcoding `RS256`.
- `Admin.Keys.activate_key/2` already consults `Policy.validate_key_compliance/2`, which gives
  Phase 42 a natural write-boundary enforcement seam.
- `docs/maintainer-conformance.md`, `scripts/conformance/*`, and the release-contract tests
  already form the repo’s preferred executable-docs pattern.

### Established Patterns

- Thin Phoenix/Plug adapters over protocol-owned correctness
- Truthful metadata sourced from the same code that enforces behavior
- Durable Ecto-backed policy state with explicit global/client overrides
- Narrow, calm admin surfaces rather than generalized control planes
- Release/support wording protected by executable tests

### Important Drift to Fix

- `SecurityProfile.allowed_signing_algorithms/1` and `Policy.validate_key_compliance/2` currently
  still allow `EdDSA` under FAPI; this phase should narrow the supported subset to `ES256` and
  `PS256` only.
- `Discovery`, `LogoutToken`, `EndSession`, and several tests still encode `RS256` assumptions
  that are incompatible with a trustworthy FAPI-effective profile.

</code_context>

<specifics>
## Specific Ideas

- Prefer one shared resolved-profile algorithm policy that answers both "what can we verify?" and
  "what can we emit/advertise?" rather than separate allow-lists that drift.
- Keep migration ergonomics soft in storage but hard at activation/publication/use boundaries:
  legacy rows may exist, but FAPI-effective behavior must never depend on them.
- Make operator remediation explicit in admin UX: tell them to generate/activate a compliant key,
  rotate away from `RS256`, or change the client/profile setting.
- Use Phase 42 to pin the OIDF lane into code with deterministic workflow plumbing; let Phase 43
  spend its budget on real validation through that lane.
- Carry forward the user preference for decisive, cohesive recommendations by default; only
  escalate questions that would materially change Lockspire’s public posture or migration risk.
</specifics>

<deferred>
## Deferred Ideas

- Broader FAPI metadata/public-claim closure beyond algorithm truth and harness wiring
- Additional FAPI algorithm families such as `EdDSA`
- A general legacy-compatibility/quarantine subsystem for non-compliant keys or clients
- Global GSD/USER-PROFILE reconfiguration outside this repo-scoped planning context
</deferred>

---

*Phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep*
*Context gathered: 2026-05-01*
