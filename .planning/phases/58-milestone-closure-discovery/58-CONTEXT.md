# Phase 58: Milestone Closure & Discovery - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.14 by making Lockspire truthfully advertise the shipped Resource Indicators and RAR surface in discovery, and by giving integrators an executable, host-owned path for custom RAR consent UX. This phase is about truthful metadata, executable docs, and claim-bearing repo stabilization. It is not a new protocol phase, not a vertical product showcase, and not a Lockspire-owned semantic consent renderer.

</domain>

<decisions>
## Implementation Decisions

### Decisioning posture
- **D-01:** Downstream Phase 58 agents should default to **strong, coherent recommendations** rather than surfacing broad menus of options. Escalate back to the user only for decisions that materially affect public API, security posture, or project/product shape.
- **D-02:** Phase 58 should optimize for **least surprise** across machine metadata, human docs, and repo proof. If discovery says a capability exists, the mounted host surface and docs must make it usable without hidden caveats.

### Discovery metadata truth
- **D-03:** Use a **hybrid capability-truth** rule for new discovery fields. Do not publish keys merely because the library contains the code path, and do not reduce truth to route presence alone.
- **D-04:** `resource_indicators_supported` should be published only when the effective authorization/token surface that processes `resource` parameters is actually usable in the mounted host deployment. Planning should define the exact predicate from mounted routes and current policy truth, but the intent is: no claim when the host cannot really use the feature.
- **D-05:** `authorization_details_types_supported` should be published only when the RAR surface is actually usable **and** `Lockspire.Config.rar_types_supported/0` is non-empty. The sorted config keys remain the single source of truth for supported RAR types.
- **D-06:** When no supported RAR types are configured, **omit** `authorization_details_types_supported`; do not publish `[]`. Empty-list discovery is a DX footgun for this embedded-library shape because it advertises a conceptual feature without a usable host contract.
- **D-07:** Discovery predicates for these new keys should be shared internally so code, tests, and docs all describe the same truth model. Avoid one-off branching in the controller/tests/docs that can drift later.

### Executable documentation shape
- **D-08:** Phase 58 should ship a **focused custom-RAR-consent walkthrough**, not a broad vertical guide and not a standalone sample app. This best matches `DOC-01`, the embedded-library boundary, and Phoenix’s generator-first documentation style.
- **D-09:** The docs should anchor directly to the **generated host seam** and the existing consent/interactions flow, showing where a host Phoenix app customizes UX after `mix lockspire.install`. The guide should read like “open these host-owned files, add this rendering logic, verify with these tests,” not like a conceptual essay.
- **D-10:** The walkthrough should be **executable by repo standards**: copy-pasteable snippets, explicit file targets, and at least one repo-owned proof hook (doc contract assertion, integration assertion, or both) that prevents the guide from silently drifting away from the shipped seam.
- **D-11:** Do not introduce a full example app or a broader “payment integrations” track in this phase. That would widen maintenance cost, imply vertical support, and dilute the milestone-closure objective.

### Consent UX example posture
- **D-12:** Keep Lockspire’s contract and main guidance **structural and host-owned**, consistent with Phase 57. Lockspire still owns protocol validity and redirect integrity; hosts own wording, brand, and product semantics.
- **D-13:** Include **one lightly opinionated `payment_initiation` example** inside the guide as an illustrative host-owned rendering pattern. This should be clearly labeled as an example, not a standardized built-in renderer and not a claim that Lockspire owns payment semantics.
- **D-14:** The example should show how a host turns normalized `authorization_details` into human-facing copy using ordinary Phoenix/LiveView patterns such as a small host component/helper and HEEx rendering, rather than introducing a renderer registry, DSL, or new Lockspire behavior.
- **D-15:** The example should stay adjacent to explicit boundary language: “illustrative only,” “host-owned,” and “adapt fields/policy/copy to your domain.” The docs must help users succeed without implying a new supported product surface.

### Closure breadth
- **D-16:** Phase 58 should follow a **contract-coupled closure** path: update discovery code/tests, the focused RAR consent guide, and the claim-bearing support contract surfaces in the same pass.
- **D-17:** The minimum claim-bearing surfaces to update alongside the discovery/doc changes are: `README.md`, `docs/supported-surface.md`, and `test/lockspire/release_readiness_contract_test.exs`.
- **D-18:** `SECURITY.md` should be updated only if the supported security boundary or negative-claim wording materially changes. Do not broaden it unnecessarily just because a new feature guide exists.
- **D-19:** Avoid a repo-wide editorial sweep in this phase. Update only the docs/tests that materially define or enforce the supported surface, so review stays crisp and the milestone closes without opportunistic churn.

### Ecosystem lessons to carry into planning
- **D-20:** Follow the pattern successful auth libraries use when they get this right: protocol core stays narrow, discovery stays truthful to enabled deployment state, and docs show the exact host extension seam with runnable proof.
- **D-21:** Avoid the footguns common in adjacent ecosystems:
  - abstract docs that explain the seam but never show a usable consent rendering,
  - sample apps that silently become the de facto contract and then drift,
  - discovery keys that overclaim because “the code supports it” while the host cannot actually use it,
  - empty metadata lists that confuse integrators about what is really configured.

### the agent's Discretion
- Exact names for any new discovery helper predicates or guide filenames.
- Whether the new guide lives as a dedicated doc (recommended) or as a tightly scoped section inside an existing install/onboarding doc, provided the final shape is easy to find and easy to keep truthful.
- Exact test layering for doc-proof (contract test only vs contract + integration assertion), as long as the walkthrough cannot drift without a repo-owned signal.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation set is:
  - hybrid discovery truth,
  - focused generated-seam walkthrough,
  - structural docs plus one host-owned `payment_initiation` example,
  - contract-coupled closure of the claim-bearing docs/tests.
- `payment_initiation` is already the repo’s canonical RAR example type, so reusing it in the docs is less surprising than inventing a new example for Phase 58.
- The right UX tone for the guide is “here is how to customize the host seam you already own,” not “here is the Lockspire-approved consent UI.”
- A good documentation target is a dedicated host guide such as `docs/rar-consent-host-guide.md` or equivalent narrow location, referenced from onboarding/support docs rather than buried.
- The docs should explicitly show the difference between:
  - generic structural display (`type`, normalized fields, raw shape awareness),
  - host-specific semantic copy (“Pay $12.34 to Example Store”),
  - Lockspire-owned responsibilities (interaction validity, redirect finalization).
- Shift-left preference for GSD downstream work:
  - planning/execution agents should proactively choose the standard path above,
  - only escalate if they would otherwise change public surface area, security claims, or embedded-library boundaries.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Normative specs
- `RFC 8707` — Resource Indicators for OAuth 2.0; discovery/capability truth for resource targeting.
- `RFC 9396` §6, §9, §10, §11.2 — RAR error handling, consent/introspection shape, and `authorization_details_types_supported`.
- `OpenID Connect Discovery 1.0` — truthfulness expectations for provider metadata.

### Lockspire planning artifacts
- `.planning/ROADMAP.md` — Phase 58 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `META-01`, `META-02`, `DOC-01`.
- `.planning/PROJECT.md` — embedded-library boundary, host-owned seams, truthful support posture.
- `.planning/STATE.md` — Phase 58 is the milestone-close pass.
- `.planning/phases/56-rar-domain-validation-storage/56-CONTEXT.md` — `rar_validators` keys as single source of truth for supported RAR types.
- `.planning/phases/57-rar-introspection-and-verification/57-CONTEXT.md` — structural consent proof boundary and recommendation-heavy downstream decisioning.

### Claim-bearing docs and repo proof surfaces
- `README.md` — top-level supported-surface summary.
- `docs/supported-surface.md` — canonical public support contract.
- `docs/install-and-onboard.md` — generator-first host seam and onboarding posture.
- `docs/maintainer-release.md` — release claims must stay inside repo truth.
- `SECURITY.md` — supported security surface and exclusions.
- `test/lockspire/release_readiness_contract_test.exs` — contract enforcement for docs/support truth.

### Lockspire codebase and tests
- `lib/lockspire/protocol/discovery.ex` — current truth-based discovery implementation and extension point for new metadata.
- `test/lockspire/protocol/discovery_test.exs` — discovery truth tests to extend.
- `lib/lockspire/config.ex` — `rar_types_supported/0` and config-truth seam.
- `lib/lockspire/host/rar_type_validator.ex` — host registration shape and type-truth contract.
- `lib/lockspire/web/live/consent_live.ex` — current structural consent surface to reference, not to over-own.
- `test/integration/phase57_rar_introspection_verification_e2e_test.exs` — proof that normalized `authorization_details` already reach the consent surface.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Protocol.Discovery` already has route- and policy-truth helpers; Phase 58 should extend that pattern rather than invent a parallel metadata path.
- `Lockspire.Config.rar_types_supported/0` already provides the correctly sorted list derived from `:rar_validators`; reuse it directly for discovery/docs/tests.
- `Lockspire.Web.ConsentLive` already shows the structural consent seam and assigns both `authorization_details` and `authorization_detail_types`; the guide can build on this shape when explaining host customization.
- `test/lockspire/release_readiness_contract_test.exs` already acts as the docs/support contract gate and should remain the place where public-claim drift is caught early.

### Established Patterns
- Lockspire prefers truthful metadata derived from effective mounted/configured behavior, not marketing claims derived from library potential.
- Lockspire’s install/onboarding docs are generator-first and explicit about host-owned files. Phase 58 docs should match that style.
- The repo uses narrow, claim-bearing docs plus tests to enforce support boundaries. New claims belong in that same contract system.

### Integration Points
- Discovery implementation and tests: `lib/lockspire/protocol/discovery.ex`, `test/lockspire/protocol/discovery_test.exs`.
- Public support contract: `README.md`, `docs/supported-surface.md`, `SECURITY.md` if needed, `docs/maintainer-release.md` only if wording must reference the new supported slice.
- Host RAR consent guidance should connect to the generated install seam and the current consent surface rather than introducing a new architectural seam.
- Release truth enforcement remains `test/lockspire/release_readiness_contract_test.exs`; planning should add or adjust assertions there as part of the same closure pass.

</code_context>

<deferred>
## Deferred Ideas

- Full vertical payment-integration walkthrough or sample host app.
- Built-in Lockspire semantic consent renderer or per-type rendering registry.
- Broader documentation sweep across every adjacent guide, unless planning finds a concrete claim-bearing mismatch that blocks truthful closure.
- Publishing per-type schemas or richer metadata beyond `authorization_details_types_supported`.
- Generalizing the “strong recommendations unless high-impact” preference into broader project-wide GSD workflow settings beyond what Phase 58 planning/execution will inherit from this context.

</deferred>

---

*Phase: 58-milestone-closure-discovery*
*Context gathered: 2026-05-06*
