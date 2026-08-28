# Phase 134: Architecture Topology - Context

**Gathered:** 2026-08-27 (assumptions mode, autonomous)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Lockspire's actual module graph one-directional and executable without changing the public module names or the observable OAuth/OIDC, DCR, and operator contracts established through Phase 133. This phase removes the currently observed runtime/export cycles, prevents protocol code from depending on Phoenix delivery or operator-admin code, and gives DCR and operator client workflows one neutral metadata/lifecycle owner. It deliberately does not undertake the aggregate-level repository or token-orchestrator decomposition reserved for Phase 135.

</domain>

<decisions>
## Implementation Decisions

### Dependency Direction and Public Compatibility
- **D-01:** Establish and enforce a directional topology: public facades and delivery adapters may depend inward; protocol/application services may depend only on neutral domain/configuration/observability services and explicit storage ports; adapters implement those ports; Phoenix web and operator-admin code remain outer delivery layers.
- **D-02:** Keep existing public nested module names and public result/error shapes working throughout v1.x. Internal relocation must use compatible delegating/forwarding modules where a current public module name is retained as a facade; consumers must not need to know the new implementation layout.
- **D-03:** Treat `mix xref graph --format cycles` as the baseline graph fact: Phase 134 must remove all five current cycles (the token exchange group, discovery/web/router, config/security/prefix, protected-resource-DPoP/userinfo, and authorization-request/request-object) rather than merely adding new source conventions.
- **D-04:** Do not introduce an architectural analysis dependency for this phase. Use Mix's graph output plus deterministic AST/source fitness tests, which are already established in `test/lockspire/architecture_fitness_test.exs`, so the check runs in normal contributor and CI environments.

### Neutral Client Metadata and Lifecycle Service
- **D-05:** Create or extract one dependency-neutral client metadata/lifecycle service below both `Lockspire.Admin.Clients` and DCR orchestration. It owns shared metadata normalization/validation, lifecycle persistence/audit composition, and policy-readiness checks; outer facades translate only their own input/output/error contracts.
- **D-06:** Preserve the intentional boundary-specific differences while sharing the neutral service: direct/operator registration requires its documented required scope list and returns `Lockspire.Clients.RegistrationResult`; DCR may omit optional `scope`, resolves DCR policy first, returns `Lockspire.Protocol.Registration.Success`/`Error`, and retains its RAT/IAT semantics.
- **D-07:** Move protocol-to-admin calls out of `Lockspire.Protocol.Registration` and `Lockspire.Protocol.RegistrationManagement`. DCR must no longer call `Lockspire.Admin`/`Lockspire.Admin.Clients` for creation, metadata helpers, disabling, or FAPI readiness; the admin facade instead becomes another caller of the neutral service.
- **D-08:** Preserve all existing security behavior at the extraction boundary: immutable client fields stay protected, exact redirect URI and logout-origin rules remain intact, PKCE stays required, DCR audit attribution/RAT rotation stay atomic, and no plaintext secret/key material appears in errors or telemetry.

### Cycle-Specific Ownership Choices
- **D-09:** Remove protocol's default dependency on `Lockspire.Web.Router` in discovery by putting the concrete Phoenix router choice at the delivery/configuration edge and passing a neutral route capability/input into protocol discovery. The public `Lockspire.Protocol.Discovery` API remains available.
- **D-10:** Break the config/security/prefix loop by making prefix normalization a neutral utility that does not call `Lockspire.Config`; configuration owns reading config and passes values inward. Keep `Lockspire.Config.storage_prefix/0` and `oban_prefix/0` compatible.
- **D-11:** Break protocol-internal cycles by introducing narrow neutral collaborators/data inputs at the current mutually dependent seams, not by allowing cross-layer reach-through or by collapsing modules into a larger facade. Preserve the existing endpoint and public protocol outputs exactly.

### Fitness Evidence
- **D-12:** Expand architecture fitness proof to assert: no runtime/export cycles; no protocol-to-`Lockspire.Web` or `Lockspire.Admin` references; no delivery code reaches Ecto implementation except through its owning application/service boundary; public facade names remain exported; and DCR/admin delegate to the same neutral service instead of duplicating metadata/lifecycle logic.
- **D-13:** Characterize public registration, DCR management, and admin client behavior before/alongside the moves, including positive and negative security contracts. Graph-green alone is insufficient evidence for an architecture refactor in OAuth/OIDC code.

### the agent's Discretion
- Exact names and file layout of neutral core/application services, provided they do not become new advertised public product APIs by accident and preserve the existing public facades.
- Whether a compatible module forwards to an implementation module or remains the small facade itself, provided nested public modules remain callable and documented contracts stay stable.
- Which individual cycle edge is inverted, provided the final graph has no cycles and the directional rules above hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` and `.planning/ROADMAP.md` — embedded-library boundary, Phase 134 goal, and Phase 135 separation.
- `.planning/phases/132-public-api-and-resource-server-truth/132-CONTEXT.md` and `132-02-SUMMARY.md` — shared `ClientRegistration.Shape` provenance and intentionally distinct direct/DCR contracts.
- `.planning/phases/133-clean-room-saas-journey/133-CONTEXT.md` and `133-VERIFICATION.md` — externally observed behavior that structural work must retain.
- `test/lockspire/architecture_fitness_test.exs` — existing AST fitness-test style and current partial boundaries.
- `lib/lockspire/protocol/registration.ex` and `lib/lockspire/protocol/registration_management.ex` — current protocol-to-admin dependencies and DCR lifecycle seams.
- `lib/lockspire/admin/clients.ex` and `lib/lockspire/clients.ex` — current operator/direct metadata and lifecycle implementations.
- `lib/lockspire/client_registration/shape.ex` — dependency-light shared validation precedent.
- `lib/lockspire/protocol/discovery.ex`, `lib/lockspire/web/controllers/discovery_controller.ex`, and `lib/lockspire/web/router.ex` — current protocol/web/router cycle.
- `lib/lockspire/config.ex`, `lib/lockspire/security/policy.ex`, and `lib/lockspire/storage/ecto/prefix.ex` — current configuration/security/prefix cycle.
- `docs/supported-surface.md` — public names and behavior that cannot silently drift.

</canonical_refs>

<code_context>
## Existing Code Insights

### Observed Graph Baseline
- `mix xref graph --format stats` reports 226 tracked files, 478 runtime edges, 233 export edges, and five cycles.
- `mix xref graph --format cycles` identifies the five concrete cycles named in D-03. The largest is a nine-node token-exchange cycle; the remaining cycles are discovery/web/router, config/security/prefix, protected-resource-DPoP/userinfo, and authorization-request/request-object.
- The existing fitness test only rejects protocol Ecto-record/direct-host-Repo reach-through and selected LiveView-to-repository reach-through. It does not yet reject protocol-to-admin/web dependencies or graph cycles.

### Client-Service Duplication
- `Lockspire.Protocol.Registration` currently aliases `Lockspire.Admin`, calls `Admin.Clients.validate_logout_metadata/3`, `normalize_logout_metadata/1`, `create_dcr_client/1`, and `check_fapi_signing_readiness/2`.
- `Lockspire.Protocol.RegistrationManagement` likewise calls `Admin.Clients.disable_client/2` and `normalize_logout_metadata/1` while separately retaining DCR policy, RAT, and replacement persistence work.
- `Lockspire.Admin.Clients` directly owns operator update/disable/secret lifecycle and audits, while `Lockspire.Clients` owns direct registration and shares only `ClientRegistration.Shape` with DCR today. This is precisely the duplication/cross-layer coupling ARCH-03 targets.

### Established Patterns
- `Lockspire.ClientRegistration.Shape` is an existing neutral, dependency-light validator that returns field/reason issues and lets direct/DCR boundaries adapt them to their stable errors.
- `Lockspire.Admin` is an operator-facing facade over focused admin modules; LiveViews call it rather than the Ecto repository in the existing fitness contract.
- The public support contract explicitly names direct/DCR behavior, `Lockspire.Web.AdminRouter`, and the Phoenix plug pipeline, so internal moves cannot silently remove these nested public modules or change their result shapes.

</code_context>

<specifics>
## Specific Ideas

- Make the graph check report the exact violating edge/path on failure, so a maintainer can repair a directional regression without interpreting a large DOT graph.
- Keep topology proof in its own focused test/command and run it in the standard verification aliases; this makes cycle freedom a maintained invariant instead of a one-time cleanup claim.
- Treat the neutral client service as the single owner of common invariants and atomic lifecycle composition, while keeping DCR policy resolution and transport mapping at the DCR edge and operator presentation at the admin edge.

</specifics>

<deferred>
## Deferred Ideas

- Splitting `Lockspire.Storage.Ecto.Repository` by aggregate, breaking out token issuance/polling collaborators, and broader dependency-bundle cleanup belong to Phase 135.
- Credo/Dialyzer/test-noise cleanup belongs to Phase 136.
- CI coverage, release artifact, and external conformance evidence belong to Phase 137.
- New OAuth/OIDC grants, hosted authorization, changes to host-owned product policy, and operator UI redesign remain out of scope.

</deferred>
