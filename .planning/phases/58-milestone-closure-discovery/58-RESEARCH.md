# Phase 58: Milestone Closure & Discovery - Research

**Researched:** 2026-05-06
**Domain:** OIDC discovery metadata truth, RAR consent-seam documentation, and milestone support-contract closure
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- Full vertical payment-integration walkthrough or sample host app.
- Built-in Lockspire semantic consent renderer or per-type rendering registry.
- Broader documentation sweep across every adjacent guide, unless planning finds a concrete claim-bearing mismatch that blocks truthful closure.
- Publishing per-type schemas or richer metadata beyond `authorization_details_types_supported`.
- Generalizing the “strong recommendations unless high-impact” preference into broader project-wide GSD workflow settings beyond what Phase 58 planning/execution will inherit from this context.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| META-01 | Advertise `resource_indicators_supported: true` in Discovery | Extend the existing route/policy-based discovery model in `Lockspire.Protocol.Discovery` with one shared predicate tied to usable authorization + token `resource` handling, then pin it in protocol/controller/release-contract tests. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/integration/phase54_resource_indicators_e2e_test.exs] |
| META-02 | Advertise `authorization_details_types_supported` based on host configuration in Discovery | Reuse `Lockspire.Config.rar_types_supported/0` as the sole type source, publish only when the RAR surface is usable and the list is non-empty, and omit the key entirely otherwise. [VERIFIED: lib/lockspire/config.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9396] |
| DOC-01 | Provide executable documentation for implementing a custom RAR consent screen | Anchor the guide to the generated `mix lockspire.install` consent file (`lockspire_consent_live.ex`) and the existing consent/interactions path, then enforce it through release-contract assertions and, if needed, one narrow generated-host integration proof. [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: priv/templates/lockspire.install/consent_live.ex] [VERIFIED: docs/install-and-onboard.md] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Lockspire must remain a separate embedded companion library; this phase must not turn discovery/docs work into a hosted auth-service shape. [VERIFIED: AGENTS.md]
- The host seam stays explicit and narrow: accounts, login UX, branding, and product policy remain host-owned; protocol correctness and library-owned interaction validity remain in Lockspire. [VERIFIED: AGENTS.md]
- Strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces must be preserved. [VERIFIED: AGENTS.md]
- Security defaults to preserve in this phase include PKCE S256 by default, exact redirect URI matching, hashed client secrets, short-lived single-use authorization codes, refresh rotation with reuse revocation, no implicit flow, no `alg=none`, and strong redaction in logs/operator surfaces. [VERIFIED: AGENTS.md]
- The checked-in project stack is Phoenix `~> 1.8.5`, Phoenix LiveView `~> 1.1.28`, Ecto SQL `~> 3.13.5`, Bandit `~> 1.6`, Oban `~> 2.21`, and OpenTelemetry API `~> 1.5`; Phase 58 should not widen scope into a dependency-upgrade phase. [VERIFIED: AGENTS.md] [VERIFIED: mix.exs]

## Summary

Lockspire already has the core implementation seams needed for Phase 58: discovery metadata is centralized in `Lockspire.Protocol.Discovery`, RAR type truth is already exposed as `Lockspire.Config.rar_types_supported/0`, the consent surface already receives normalized `authorization_details` plus derived type names, and `mix lockspire.install` already generates a host-owned consent LiveView file that the docs can target directly. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/config.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: lib/lockspire/generators/templates.ex]

The planning shape should therefore be narrow and contract-coupled: add shared discovery predicates in `Lockspire.Protocol.Discovery`, extend existing discovery tests and the release-readiness contract, add one focused host guide for custom RAR consent rendering against the generated consent seam, and update only the claim-bearing docs (`README.md`, `docs/supported-surface.md`, and the new guide). [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: README.md] [VERIFIED: docs/supported-surface.md]

One standards wrinkle matters for planning: RFC 9396 clearly expects authorization servers to advertise supported authorization-details types in server metadata, but the current IANA OAuth Authorization Server Metadata registry does not list `resource_indicators_supported`, and the current registry entry for `authorization_details_types_supported` appears under OAuth Protected Resource Metadata as well. The phase can still satisfy the locked milestone requirement, but planning should explicitly treat `resource_indicators_supported` as a project-specific discovery extension claim that must be documented carefully and guarded by a strict truth predicate. [CITED: https://www.rfc-editor.org/rfc/rfc9396] [CITED: https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml]

**Primary recommendation:** Extend the existing discovery truth model with shared helper predicates, publish `authorization_details_types_supported` only from non-empty `rar_types_supported/0`, publish `resource_indicators_supported` only as a strictly-gated extension claim, and ship a dedicated `docs/rar-consent-host-guide.md` anchored to the generated `lockspire_consent_live.ex` seam. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/config.ex] [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Discovery capability truth for `resource_indicators_supported` | API / Backend | Frontend Server | The predicate depends on mounted endpoints, server policy, and protocol behavior in `Lockspire.Protocol.Discovery`; clients only consume the JSON document. [VERIFIED: lib/lockspire/protocol/discovery.ex] |
| Discovery capability truth for `authorization_details_types_supported` | API / Backend | Frontend Server | The published value is derived from runtime config (`rar_types_supported/0`) plus actual RAR surface usability, not from UI code. [VERIFIED: lib/lockspire/config.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| Custom RAR consent rendering example | Frontend Server (SSR/LiveView) | API / Backend | The host-owned Phoenix LiveView/HEEx seam owns wording and rendering, while Lockspire keeps interaction validity and final redirect integrity. [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: priv/templates/lockspire.install/consent_live.ex] [VERIFIED: AGENTS.md] |
| Claim-bearing support-contract closure | API / Backend | Frontend Server | Repo-owned tests and docs assert backend truth about supported behavior; the host UX example is documentation, not a new protocol capability. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: docs/supported-surface.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | Repo lock `1.8.5`; current Hex release `1.8.7` published 2026-05-06. [VERIFIED: mix.exs] [VERIFIED: mix hex.info phoenix] | Router/controller/discovery endpoint surface. [VERIFIED: lib/lockspire/web/router.ex] | Phase 58 extends the existing Phoenix discovery and install-doc surfaces; do not turn milestone closure into a framework-upgrade phase. [VERIFIED: mix.exs] [VERIFIED: .planning/ROADMAP.md] |
| Phoenix LiveView | Repo lock `1.1.28`; current stable Hex release `1.1.30` published 2026-05-05. [VERIFIED: mix.exs] [VERIFIED: mix hex.info phoenix_live_view] | Existing consent seam and generated host customization target. [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: priv/templates/lockspire.install/consent_live.ex] | The doc example should reuse the shipped LiveView seam rather than inventing another rendering framework. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] |
| Ecto SQL | Repo lock `3.13.5`; current Hex release `3.13.5` published 2026-03-03. [VERIFIED: mix.exs] [VERIFIED: mix hex.info ecto_sql] | Existing durable interaction/grant/token truth used by discovery tests and consent proof. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] | No new storage abstraction is needed; Phase 58 only consumes already-shipped durable state. [VERIFIED: test/integration/phase57_rar_introspection_verification_e2e_test.exs] |
| ExUnit | Bundled with Elixir `1.19.5` in the current environment. [VERIFIED: elixir --version] | Protocol, controller, integration, and release-contract verification. [VERIFIED: mix.exs] | The repo already closes milestones through ExUnit plus mix aliases; Phase 58 should extend that lane. [VERIFIED: mix.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExDoc | Repo constraint `~> 0.38`; docs are verified through `mix docs.verify`. [VERIFIED: mix.exs] | Keep the new guide inside the checked-in executable docs lane. [VERIFIED: mix.exs] | Use when adding `docs/rar-consent-host-guide.md` and wiring it into docs extras/groups. [VERIFIED: mix.exs] |
| Jason | Repo constraint `~> 1.4`; existing consent/debug displays and tests already render JSON payloads with Jason. [VERIFIED: mix.exs] [VERIFIED: lib/lockspire/web/live/consent_live.ex] | Encode normalized `authorization_details` in example snippets and tests. [VERIFIED: lib/lockspire/web/live/consent_live.ex] | Use for structural display snippets in the guide; do not introduce another JSON library. [VERIFIED: lib/lockspire/web/live/consent_live.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated host guide against generated `lockspire_consent_live.ex` | Broad install-guide section only | Easier to add quickly, but harder to discover and harder to pin with claim-bearing doc assertions. The context explicitly recommends a narrow, findable guide. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] |
| Shared discovery predicates in `Lockspire.Protocol.Discovery` | One-off controller/test/doc branching | Faster locally, but it breaks the repo’s existing truth-based discovery pattern and invites drift across docs/tests/code. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs] |
| Host-owned helper/component example for RAR rendering | Lockspire-owned renderer registry or DSL | A registry would widen public API and violate the phase boundary; RFC 9396 only says deployments should support customization, not that the library must own semantic rendering. [CITED: https://www.rfc-editor.org/rfc/rfc9396] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] |

**Installation:**
```bash
# No new dependencies are recommended for Phase 58.
mix deps.get
```

**Version verification:** Package versions above were verified with `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, and `mix hex.info ecto_sql` on 2026-05-06. [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto_sql]

## Architecture Patterns

### System Architecture Diagram

```text
Client/RP
  -> GET /.well-known/openid-configuration
  -> Phoenix router/controller
  -> Lockspire.Protocol.Discovery
      -> mounted_route_paths()
      -> server policy / effective protocol truth
      -> Lockspire.Config.rar_types_supported()
  -> filtered metadata JSON

Host integrator
  -> mix lockspire.install
  -> generated host file: lib/<app>_web/live/lockspire_consent_live.ex
  -> host helper/component renders normalized authorization_details
  -> POST /lockspire/interactions/:interaction_id/complete
  -> Lockspire.Protocol.AuthorizationFlow finalizes consent + redirect

Repo proof lane
  -> protocol/controller tests
  -> release_readiness_contract_test.exs
  -> docs.verify
```

The primary data-flow split for this phase is backend truth for discovery metadata and frontend-server host customization for consent rendering; the planner should keep those tasks separate but coupled by shared predicates and doc-proof. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Recommended Project Structure
```text
lib/
├── lockspire/protocol/discovery.ex          # Shared discovery truth predicates and metadata assembly
├── lockspire/config.ex                      # RAR type source of truth
└── lockspire/generators/templates.ex        # Generated host consent seam inventory

docs/
├── install-and-onboard.md                   # Existing generator-first entrypoint
├── supported-surface.md                     # Claim-bearing support contract
└── rar-consent-host-guide.md                # New focused host guide for Phase 58

test/
├── lockspire/protocol/discovery_test.exs    # Predicate and metadata truth tests
├── lockspire/web/discovery_controller_test.exs
├── lockspire/release_readiness_contract_test.exs
└── integration/phase57_rar_introspection_verification_e2e_test.exs
```

### Pattern 1: Shared Discovery Predicate Helper
**What:** Centralize “is this feature truthfully usable?” checks inside `Lockspire.Protocol.Discovery` and have both metadata assembly and tests call the same helpers. [VERIFIED: lib/lockspire/protocol/discovery.ex]

**When to use:** For both new fields in Phase 58 and for any later discovery claim that depends on more than static code presence. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

**Example:**
```elixir
# Source: lib/lockspire/protocol/discovery.ex
def openid_configuration do
  issuer = Config.issuer!()
  endpoint_metadata = mounted_endpoint_metadata()

  %{
    "issuer" => issuer,
    "grant_types_supported" => grant_types_supported(endpoint_metadata)
  }
  |> Map.merge(endpoint_metadata)
  |> maybe_put_par_required_metadata()
end
```
[VERIFIED: lib/lockspire/protocol/discovery.ex]

### Pattern 2: Generated Host Seam Documentation
**What:** Point documentation at the concrete files emitted by `mix lockspire.install`, not at a conceptual sample app. [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: docs/install-and-onboard.md]

**When to use:** For the new RAR consent guide and any host-owned extension walkthrough that must survive repo evolution. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

**Example:**
```elixir
# Source: priv/templates/lockspire.install/consent_live.ex
<%= if @authorization_details != [] do %>
  <section class="lockspire-consent-rar">
    <h2>authorization_details</h2>
  </section>
<% end %>
```
[VERIFIED: priv/templates/lockspire.install/consent_live.ex] [ASSUMED]

### Anti-Patterns to Avoid
- **Route-only truth:** Publishing support because `/authorize` or `/token` exists, without checking the effective mounted/configured surface, would violate the existing discovery model and the locked hybrid-truth decision. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]
- **Empty RAR type metadata:** Publishing `authorization_details_types_supported: []` advertises a conceptual feature without a usable host contract; the context explicitly forbids it. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]
- **Semantic renderer ownership:** Adding a Lockspire-owned payment consent renderer or registry would widen public API and contradict the host-owned boundary set in AGENTS and the phase context. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]
- **Doc-only truth without repo proof:** A guide that is not pinned by docs extras and contract tests will drift. The repo already uses release-contract tests to gate claim-bearing surfaces. [VERIFIED: mix.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| RAR type inventory | A second registry/list for docs or discovery | `Lockspire.Config.rar_types_supported/0` | It already returns sorted keys from `:rar_validators`, which Phase 56 locked as the single source of truth. [VERIFIED: lib/lockspire/config.ex] [VERIFIED: .planning/phases/56-rar-domain-validation-storage/56-CONTEXT.md] |
| Consent example surface | A standalone example app | The generated `lockspire_consent_live.ex` host seam plus the existing consent/interactions route flow | The generator output is the actual contract hosts receive; a sample app would drift and become a shadow API. [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: priv/templates/lockspire.install/consent_live.ex] |
| Discovery truth computation | Ad hoc booleans spread across controller/tests/docs | Shared helper predicates in `Lockspire.Protocol.Discovery` | The current discovery module already follows this pattern for token auth methods, DPoP metadata, registration visibility, and PAR-required truth. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs] |
| Custom RAR consent rendering | A Lockspire DSL/registry for semantic copy | Small host helper/component plus HEEx branching inside the generated host LiveView | RFC 9396 calls for customizable presentation, and the phase context keeps semantics host-owned. [CITED: https://www.rfc-editor.org/rfc/rfc9396] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] |

**Key insight:** Phase 58 is a closure phase, not an extensibility phase. The correct plan reuses repo-proven truth sources and generated seams instead of creating new abstractions. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Overclaiming Discovery from Library Potential
**What goes wrong:** Discovery publishes feature claims because the code path exists somewhere in the library, even when the mounted host deployment cannot use the feature end to end. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

**Why it happens:** It is easier to test static code presence than effective mounted/configured behavior. [VERIFIED: lib/lockspire/protocol/discovery.ex]

**How to avoid:** Reuse a single helper predicate that checks the mounted authorization/token/RAR surface and keep controller/tests/docs pinned to that helper. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs]

**Warning signs:** Assertions only check for hard-coded map keys, or docs mention a discovery field without a matching predicate test. [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Pitfall 2: Treating Empty RAR Configuration as Support
**What goes wrong:** Publishing `authorization_details_types_supported: []` confuses integrators into believing RAR is ready when the host has configured no usable types. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

**Why it happens:** Teams conflate “RAR parser exists” with “deployment has at least one supported host type.” [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/config.ex]

**How to avoid:** Gate publication on both RAR surface usability and a non-empty `Lockspire.Config.rar_types_supported/0`; omit the key entirely otherwise. [VERIFIED: lib/lockspire/config.ex] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

**Warning signs:** Discovery tests assert `[]`, or docs talk about custom RAR consent before showing host validator configuration. [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: docs/install-and-onboard.md]

### Pitfall 3: Letting the Guide Become a Product Surface
**What goes wrong:** The new guide drifts into a vertical payment showcase or a Lockspire-owned renderer contract. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

**Why it happens:** RAR examples naturally invite semantic copy, and payment initiation is the easiest concrete demo. [CITED: https://www.rfc-editor.org/rfc/rfc9396]

**How to avoid:** Keep example copy explicitly labeled as illustrative, keep rendering logic inside host-owned files, and restate that Lockspire owns validity/final redirect only. [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

**Warning signs:** New behaviors, registries, or callbacks appear in `lib/lockspire/` instead of in docs/templates/tests. [VERIFIED: lib/lockspire/generators/templates.ex]

### Pitfall 4: Docs Drift from the Generated Seam
**What goes wrong:** The guide references files or assigns that the install generator no longer creates. [VERIFIED: lib/lockspire/generators/templates.ex]

**Why it happens:** Docs are updated manually while generators evolve independently. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: lib/lockspire/generators/templates.ex]

**How to avoid:** Reference the exact generated filenames from `Templates.all/0`, add the guide to ExDoc extras, and pin key strings in `release_readiness_contract_test.exs`. [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: mix.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**Warning signs:** The guide mentions `consent_live.ex` paths that are absent from generator inventory, or docs build excludes the new file. [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: mix.exs]

## Code Examples

Verified patterns from repo and standards:

### Truth-Based Discovery Assembly
```elixir
# Source: lib/lockspire/protocol/discovery.ex
defp token_endpoint_auth_methods_supported(endpoint_metadata) do
  if Map.has_key?(endpoint_metadata, "token_endpoint") do
    @token_endpoint_auth_methods_supported
  else
    []
  end
end
```
[VERIFIED: lib/lockspire/protocol/discovery.ex]

### Generated Host Consent Seam
```elixir
# Source: priv/templates/lockspire.install/consent_live.ex
<section class="host-consent-shell">
  <header>
    <p>Brand, copy, and product framing stay in the host app.</p>
  </header>
</section>
```
[VERIFIED: priv/templates/lockspire.install/consent_live.ex]

### Standards Guidance for Host-Customized Consent
```text
# Source: RFC 9396 §11.2
Support advertisement of supported authorization details types in OAuth server metadata
...
determine presentation of the authorization details
```
[CITED: https://www.rfc-editor.org/rfc/rfc9396]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Discovery claims derived from static code presence | Discovery claims derived from effective mounted/configured behavior | Current repo pattern already used for DCR, DPoP, and PAR-required truth. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs] | Phase 58 should extend the existing helper style, not add a separate metadata path. [VERIFIED: lib/lockspire/protocol/discovery.ex] |
| Conceptual extension docs or sample apps | Generator-targeted, host-owned executable docs | Current repo onboarding and generator inventory. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: lib/lockspire/generators/templates.ex] | The new RAR guide should target generated files and repo proof, not a demo application. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] |
| AS metadata only as the discovery discussion point for RAR | Current registries also define `authorization_details_types_supported` for OAuth Protected Resource Metadata | Current IANA registry checked 2026-05-06. [CITED: https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml] | Phase 58 should stay scoped to AS/OIDC discovery and avoid broadening into protected-resource metadata work. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] |

**Deprecated/outdated:**
- Treating empty `authorization_details_types_supported` as helpful metadata is outdated for this embedded-library shape; the locked context now requires omitting the key when no types are configured. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The generated consent template will need to be extended with `authorization_details` examples in the new guide, because the current template does not include them. [VERIFIED: priv/templates/lockspire.install/consent_live.ex] | Architecture Patterns / Wave 0 | Low; if the planner chooses guide-only snippets without template edits, the guide can still target the same host file. |

## Open Questions

1. **How should Lockspire frame `resource_indicators_supported` in public docs?**
   - What we know: Phase requirements and roadmap explicitly ask for the field in discovery, and Resource Indicators are already implemented across authorize/token/refresh flows. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: test/integration/phase54_resource_indicators_e2e_test.exs]
   - What's unclear: The current IANA OAuth Authorization Server Metadata registry does not list `resource_indicators_supported`, so clients should not assume it is a registered standard metadata parameter. [CITED: https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml]
   - Recommendation: Implement it because the requirement is locked, but describe it in docs/tests as a Lockspire-published extension claim guarded by a strict usability predicate. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

2. **Should the guide live in its own file or inside `install-and-onboard.md`?**
   - What we know: The phase context explicitly favors a dedicated narrow guide and the repo already uses dedicated host guides such as `docs/device-flow-host-guide.md`. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] [VERIFIED: docs/device-flow-host-guide.md]
   - What's unclear: Whether the planner wants one more docs extra or a smaller edit footprint in onboarding docs. [VERIFIED: mix.exs]
   - Recommendation: Use a dedicated `docs/rar-consent-host-guide.md`, then link it from `README.md`, `docs/install-and-onboard.md`, and `docs/supported-surface.md`. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All repo tests and docs verification | ✓ [VERIFIED: elixir --version] | Elixir `1.19.5`, Mix `1.19.5`. [VERIFIED: elixir --version] | — |
| PostgreSQL toolchain | Local DB-backed ExUnit/integration runs | ✓ [VERIFIED: psql --version] | PostgreSQL CLI/server binaries `14.17`. [VERIFIED: psql --version] | None for full integration coverage. |
| Node / npm | Existing release-contract/runtime tooling in the repo | ✓ [VERIFIED: node --version] | Node `22.14.0`, npm `11.1.0`. [VERIFIED: node --version] | — |

**Missing dependencies with no fallback:**
- None detected in the local toolchain audit. [VERIFIED: elixir --version] [VERIFIED: psql --version] [VERIFIED: node --version]

**Missing dependencies with fallback:**
- None. [VERIFIED: elixir --version]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: elixir --version] |
| Config file | none; repo uses Mix aliases in `mix.exs`. [VERIFIED: mix.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs -x` [VERIFIED: mix.exs] |
| Full suite command | `mix ci` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| META-01 | Discovery truthfully claims Resource Indicators only when the usable `resource` surface is present | unit + endpoint + integration | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/integration/phase54_resource_indicators_e2e_test.exs -x` | ✅ [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: test/integration/phase54_resource_indicators_e2e_test.exs] |
| META-02 | Discovery truthfully claims supported RAR types from non-empty host config | unit + endpoint | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs -x` | ✅ [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] |
| DOC-01 | The custom RAR consent guide stays aligned with the generated host seam and public support contract | contract (+ optional integration) | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs -x` | ✅ [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/release_readiness_contract_test.exs -x` [VERIFIED: mix.exs]
- **Per wave merge:** `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs test/integration/phase57_rar_introspection_verification_e2e_test.exs -x` [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: test/integration/phase57_rar_introspection_verification_e2e_test.exs]
- **Phase gate:** `mix ci` plus the new guide/assertion coverage green before `/gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps
- [ ] `docs/rar-consent-host-guide.md` — new focused guide file to satisfy `DOC-01`. [VERIFIED: docs/install-and-onboard.md]
- [ ] `mix.exs` docs extras/groups — add the new guide so `mix docs.verify` covers it. [VERIFIED: mix.exs]
- [ ] `test/lockspire/release_readiness_contract_test.exs` — add pinned Phase 58 strings for discovery keys, RAR host guide, and supported-surface wording. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- [ ] `test/lockspire/protocol/discovery_test.exs` and `test/lockspire/web/discovery_controller_test.exs` — add truth-table cases for mounted/unmounted surfaces and empty/non-empty RAR config. [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs]
- [ ] `test/integration/phase58_milestone_closure_discovery_e2e_test.exs` — optional only if the planner wants stronger doc-proof than contract assertions. [ASSUMED]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase does not introduce a new authentication mechanism. [VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | no | The guide must remain host-owned, but Phase 58 does not change session machinery. [VERIFIED: AGENTS.md] [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | yes | Discovery and consent docs must not overclaim capabilities the mounted host cannot actually authorize. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] |
| V5 Input Validation | yes | Existing `resource` URI validation and RAR validator/type enforcement remain the control base for truthful metadata and example code. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/rar/dispatcher.ex] |
| V6 Cryptography | no | No new cryptographic primitive is introduced in this phase. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Discovery overclaim advertises unsupported capability | Spoofing / Tampering | Shared truth predicates tied to effective mounted/configured behavior, plus protocol/controller/release-contract tests. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs] |
| Consent guide exposes raw sensitive fields or encourages semantic over-ownership | Information Disclosure | Keep example structural, host-owned, and adjacent to boundary language; do not add built-in semantic renderers. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] [VERIFIED: AGENTS.md] |
| Unsupported RAR types leak exact validator inventory through UX | Information Disclosure | Keep error descriptions generic on browser surfaces and let operators debug through telemetry/logs instead. [VERIFIED: lib/lockspire/rar/dispatcher.ex] [VERIFIED: .planning/phases/56-rar-domain-validation-storage/56-CONTEXT.md] |
| Doc drift causes release claims to outpace shipped code | Repudiation / Tampering | Pin claim-bearing strings in `release_readiness_contract_test.exs` and include the guide in `docs.verify`. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: mix.exs] |

## Sources

### Primary (HIGH confidence)
- `lib/lockspire/protocol/discovery.ex` - current truth-based discovery assembly and mounted-route helpers. [VERIFIED: lib/lockspire/protocol/discovery.ex]
- `lib/lockspire/config.ex` - `rar_validators/0` and `rar_types_supported/0`. [VERIFIED: lib/lockspire/config.ex]
- `lib/lockspire/web/live/consent_live.ex` - current structural consent surface and assigns. [VERIFIED: lib/lockspire/web/live/consent_live.ex]
- `lib/lockspire/generators/templates.ex` and `priv/templates/lockspire.install/consent_live.ex` - generated host-owned consent seam. [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: priv/templates/lockspire.install/consent_live.ex]
- `test/lockspire/protocol/discovery_test.exs`, `test/lockspire/release_readiness_contract_test.exs`, `test/integration/phase54_resource_indicators_e2e_test.exs`, `test/integration/phase57_rar_introspection_verification_e2e_test.exs` - existing proof surfaces and extension points. [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: test/integration/phase54_resource_indicators_e2e_test.exs] [VERIFIED: test/integration/phase57_rar_introspection_verification_e2e_test.exs]
- `https://www.rfc-editor.org/rfc/rfc9396` - metadata and implementation/customization guidance for RAR. [CITED: https://www.rfc-editor.org/rfc/rfc9396]
- `https://www.rfc-editor.org/rfc/rfc8707` - `resource` parameter and `invalid_target` registration. [CITED: https://www.rfc-editor.org/rfc/rfc8707]
- `https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml` - current OAuth Authorization Server Metadata and Protected Resource Metadata registries. [CITED: https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml]
- `https://openid.net/specs/openid-connect-discovery-1_0.html` - OIDC provider metadata document model. [CITED: https://openid.net/specs/openid-connect-discovery-1_0.html]
- `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto_sql` - current package releases and publish dates. [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto_sql]

### Secondary (MEDIUM confidence)
- None. All material recommendations above are grounded in repo files, official specs, the IANA registry, or direct package-registry queries. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo-locked dependencies and current registry releases were verified directly. [VERIFIED: mix.exs] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto_sql]
- Architecture: HIGH - discovery, consent, generator, and contract-test seams were read directly in the codebase. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/web/live/consent_live.ex] [VERIFIED: lib/lockspire/generators/templates.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- Pitfalls: HIGH - they are explicitly supported by locked phase context plus existing repo patterns and standards guidance. [VERIFIED: .planning/phases/58-milestone-closure-discovery/58-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc9396]

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 for repo-structure guidance; re-check package and metadata registry currency after that date. [VERIFIED: mix hex.info phoenix] [CITED: https://www.iana.org/assignments/oauth-parameters/oauth-parameters.xhtml]
