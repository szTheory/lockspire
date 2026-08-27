# Phase 134: Architecture Topology - Research

**Researched:** 2026-08-27  
**Domain:** Elixir/Mix dependency topology, compatibility-preserving internal extraction, OAuth/OIDC lifecycle correctness  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Splitting `Lockspire.Storage.Ecto.Repository` by aggregate, breaking out token issuance/polling collaborators, and broader dependency-bundle cleanup belong to Phase 135.
- Credo/Dialyzer/test-noise cleanup belongs to Phase 136.
- CI coverage, release artifact, and external conformance evidence belong to Phase 137.
- New OAuth/OIDC grants, hosted authorization, changes to host-owned product policy, and operator UI redesign remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | Maintainers can run an executable dependency check that reports zero Lockspire runtime/export dependency cycles while preserving existing public nested module names. | Mix cycle baseline, per-cycle inversion map, compatibility export checks, focused topology command. |
| ARCH-02 | Protocol modules depend only on neutral core/application and storage ports, never on Phoenix web delivery or operator-admin modules. | AST aliases/calls check over all protocol sources, neutral route and client service seams. |
| ARCH-03 | DCR and operator workflows share one neutral client metadata and lifecycle service while preserving their existing public result shapes and security behavior. | Recommended `ClientLifecycle` application service and characterization/atomicity map. |
| ARCH-04 | Architecture fitness tests fail when dependency direction, public/internal boundaries, or zero-cycle topology regress. | Deterministic AST/source checks plus captured `mix xref graph --format cycles` command contract. |
</phase_requirements>

## Summary

The executable baseline is five Mix xref cycles: a nine-module token-exchange cycle, discovery/controller/router, config/security/prefix, protected-resource DPoP/userinfo, and authorization-request/request-object. `mix xref graph --format cycles` reports them from the compiled project today. [VERIFIED: local `mix xref graph --format cycles`]

The safe approach is not a broad reorganization. Preserve public facade modules and their nested structs, move only shared data/operations below their callers, and characterize externally visible registration and endpoint behavior before each relocation. The current cycles are predominantly caused by public result struct references or mutual helper ownership; a neutral result/error module and narrow helper collaborators remove those edges without changing wire results. [VERIFIED: local xref DOT graph and `lib/lockspire/protocol/*.ex`]

**Primary recommendation:** implement topology in three ordered slices: first introduce neutral value/service seams and characterization tests, then make DCR and admin facades delegate to a single `Lockspire.ClientLifecycle` service, then remove each cycle and permanently enforce the resulting graph with Mix plus AST fitness tests. [VERIFIED: local source and existing fitness-test conventions]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public API compatibility | Public facade | Application service | Existing `Lockspire.Clients`, `Lockspire.Admin.Clients`, and protocol modules are caller-facing contracts; delegates must retain them. [VERIFIED: `docs/supported-surface.md`, public modules] |
| Client metadata normalization, validation, lifecycle writes, and audit composition | Neutral application service | Storage port | DCR and operator paths currently share rules but reach one another through the admin layer. [VERIFIED: `registration.ex`, `registration_management.ex`, `admin/clients.ex`] |
| DCR policy/RAT/IAT and RFC error translation | Protocol application service | Neutral client service | These are DCR-specific transport/protocol concerns and must retain RFC 7591/7592 results. [VERIFIED: `registration.ex`, `registration_management.ex`] |
| Route-derived discovery capability | Delivery/config edge | Protocol discovery | Phoenix route introspection is delivery knowledge; discovery consumes a route-capability input. [VERIFIED: `discovery.ex`, `web/router.ex`] |
| Prefix configuration | Configuration | Neutral prefix utility | Config reads runtime environment; the utility only validates/normalizes a supplied value. [VERIFIED: `config.ex`, `storage/ecto/prefix.ex`] |
| OAuth endpoint execution | Protocol application service | Explicit storage ports | Protocol already uses injectable stores in several paths, and must not reach Admin/Web. [VERIFIED: `architecture_fitness_test.exs`, protocol source] |
| HTTP/LiveView delivery | Web/Admin outer adapters | Public/application facades | Router/controllers and LiveViews are Phoenix-specific delivery code. [VERIFIED: `web/router.ex`, existing fitness test] |

## Project Constraints (from AGENTS.md)

- Keep Lockspire an embedded companion library; do not require a standalone service. [VERIFIED: `AGENTS.md`]
- Preserve boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: `AGENTS.md`]
- Keep host seams explicit and narrow: account resolution, claims, login redirects, branding, and product policy stay host-owned. [VERIFIED: `AGENTS.md`]
- Do not add SAML, LDAP/AD, hosted auth, or CIAM scope. [VERIFIED: `AGENTS.md`]
- Preserve PKCE S256, exact redirect matching, hashed secrets, single-use short-lived codes, refresh-family reuse revocation, no implicit flow/`alg=none`, and redaction. [VERIFIED: `AGENTS.md`]

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| Elixir Mix xref | bundled with the project Elixir runtime | Produce runtime/export graph and cycles | Already available in contributors' normal toolchain; locked decision prohibits adding an analyzer. [VERIFIED: local `mix xref graph --format cycles`; D-04] |
| `Code.string_to_quoted!/1` + `Macro.prewalk/3` | Elixir standard library | Deterministic source fitness checks | This is the exact pattern in the existing architecture fitness test. [VERIFIED: `test/lockspire/architecture_fitness_test.exs`] |
| ExUnit | project-native | Characterization and fitness tests | Existing test suite and aliases already run ExUnit. [VERIFIED: `test/lockspire/architecture_fitness_test.exs`, `mix.exs`] |

### Supporting

| Library/tool | Purpose | When to Use |
|-------------|---------|-------------|
| `function_exported?/3` | Verify retained facade functions/nested public structs remain callable | Public compatibility fitness tests. [VERIFIED: existing fitness test] |
| `System.cmd/3` | Invoke `mix xref graph --format cycles` from an ExUnit test or Mix task | Topology proof with exact failure output; use an explicit timeout/error diagnostic. [ASSUMED] |

**Installation:** none. This phase must add no external package or architectural-analysis dependency. [VERIFIED: D-04]

## Package Legitimacy Audit

No external packages are installed in this phase. [VERIFIED: D-04]

## Architecture Patterns

### System Architecture Diagram

```text
host config / Phoenix router                  operator UI / DCR HTTP
            |                                         |
            v                                         v
     Lockspire.Config --------> route capability   public facades
            |                                         |
            v                                         v
   neutral Prefix utility                  ClientLifecycle application service
                                                      |
                                      +---------------+----------------+
                                      v                                v
                           metadata / policy readiness        storage + audit port
                                      |
                                      v
                                Domain.Client

Phoenix controllers / router ---> Protocol services ---> neutral helpers + storage ports
                                      ^
                                      |  (no Lockspire.Web / Lockspire.Admin edge)
                              stable public result/error facade
```

### Recommended Project Structure

```text
lib/lockspire/
├── client_lifecycle.ex                 # neutral application service; not an advertised surface
├── client_lifecycle/
│   ├── metadata.ex                     # DCR/operator metadata projection and logout normalization
│   └── persistence.ex                  # transaction/audit composition over Repository port
├── protocol/
│   ├── token_exchange/result.ex        # neutral Success/Error structs shared by facade and grants
│   ├── authorization_errors.ex         # shared browser/redirect error value construction
│   └── protected_resource_access.ex    # DPoP common validation independent of Userinfo
├── storage/ecto/
│   └── prefix.ex                       # pure prefix functions only; no Config calls
└── web/
    └── discovery_routes.ex             # Phoenix-side route capability provider
```

Names are discretionary; the invariant is inward ownership and retained public facade modules. [VERIFIED: D-01 through D-12]

### Pattern 1: Retain public module, move shared result structs below it

**What:** define token exchange `Success` and `Error` in a neutral child/sibling module, then have `Lockspire.Protocol.TokenExchange` alias or delegate to the retained public type/function surface. Grant implementations and access-token/DPoP helpers reference the neutral module, never the orchestration facade. [VERIFIED: xref cycle shows `AccessTokenSigner`, `TokenEndpointDPoP`, grants, and `GrantSupport` depend on exported `TokenExchange.Success`/`Error`]

**When to use:** when a facade's nested struct is used by internal collaborators and creates an export edge back into that facade. [VERIFIED: local xref DOT graph]

**Compatibility rule:** if `%Lockspire.Protocol.TokenExchange.Success{}` is public or used in downstream test/client code, do not replace it with a differently named struct. Put the canonical struct in a module which preserves that fully-qualified name, or preserve the struct at the facade and move only dispatch into a neutral `Dispatcher`/`Result` collaborator that does not refer back to the facade. [ASSUMED]

### Pattern 2: Boundary translators over one neutral client service

**What:** `ClientLifecycle` accepts normalized intent plus explicit actor/audit context and returns neutral outcomes (`{:ok, %Client{}} | {:error, reason}`). DCR translates its metadata/RAT/IAT and RFC errors at the protocol edge; direct registration translates required scope errors into `RegistrationResult`; Admin translates operator form inputs/errors. [VERIFIED: D-05 through D-08; current distinct result modules]

**Required service operations:**

| Neutral operation | Callers | Atomic operation that must remain inside it |
|-------------------|---------|---------------------------------------------|
| `create_self_registered/…` | DCR registration | client insert + DCR creation audit, with IAT redemption transaction ownership unchanged or explicitly composed. [VERIFIED: `Admin.Clients.create_dcr_client/1`, `Registration.register/1`] |
| `replace_self_registered/…` | DCR management update | metadata projection + client replacement + RAT hash rotation + audit in the repository transaction. [VERIFIED: `Repository.replace_client_registration/4`, `RegistrationManagement.persist_update/3`] |
| `disable/…` | DCR delete, Admin | active flag + disable audit in one transaction. [VERIFIED: `Admin.Clients.disable_client/2`, `disable_client_with_audit/4`] |
| `create_operator/…`, `update_operator/…`, `rotate_secret/…`, `enable/…` | Admin/direct facade | preserve existing Admin and direct contracts; do not make DCR inherit direct required-scope behavior. [VERIFIED: `Clients.register_client/1`, `Admin.Clients` public functions] |

**Do not place DCR policy resolution in the neutral service.** It is DCR-specific and must happen before DCR metadata projection, because scope omission and policy allowlists are boundary-specific. [VERIFIED: D-06, `DcrPolicy.resolve/3` call sites]

### Pattern 3: Inject route capability into discovery

**What:** make `Discovery.openid_configuration/0` obtain a neutral list/set of mounted paths from config, and let the Phoenix delivery/configuration edge supply the default `Lockspire.Web.Router` route list. A useful narrow capability is `:discovery_route_paths` (a list, zero-arity function, or module with one `paths/0` function); `Discovery` turns that input into endpoint metadata. [VERIFIED: `Discovery.mounted_route_paths/0` currently calls a configured/default router and then `Phoenix.Router.routes/1`]

**Compatibility requirement:** retain `openid_configuration/0` and `published_token_endpoint_auth_methods_supported/0` unchanged, preserve current override tests that set `:discovery_router`, and migrate their setup to the neutral capability/config key only when an alias-compatible fallback keeps existing host configuration working. [VERIFIED: `test/lockspire/protocol/discovery_test.exs`, `test/lockspire/web/discovery_controller_test.exs`; compatibility fallback recommendation is ASSUMED]

### Pattern 4: Pure prefix utility

**What:** `Prefix.normalize/1`, `prefix_opts/1`, and `oban_opts/1` take prefix values explicitly. `Config.storage_prefix/0` and `Config.oban_prefix/0` remain public wrappers which read application config and pass it to Prefix. Callers requiring runtime configuration call Config; callers with a supplied prefix call Prefix. [VERIFIED: `Config` currently calls `Prefix.normalize/1`; `Prefix.prefix_opts/0` and `oban_opts/0` call Config, forming the cycle]

### Per-cycle inversion map

| Baseline cycle | Observed offending direction | Recommended inversion | Compatibility/behavior guard |
|----------------|-----------------------------|------------------------|------------------------------|
| Token exchange (9) | Helpers/grants import `TokenExchange.Success/Error`; facade dispatches helpers | Move dispatch into a neutral dispatcher or relocate shared structs/errors to a dependency-free owner, keeping facade exports/types compatible | All grant success/error HTTP JSON and refresh/token-exchange tests. [VERIFIED: xref DOT edges 175–290] |
| Discovery/web/router (3) | `Discovery -> Web.Router -> DiscoveryController -> Discovery` | Web/config owns `Phoenix.Router.routes`; protocol takes route path capability | Discovery mounted/unmounted endpoint truth, DCR discovery invariant. [VERIFIED: xref DOT edges 592–602] |
| Config/security/prefix (3) | Config calls Policy and Prefix; both call Config | Prefix becomes argument-only; independently move any `Policy -> Config` runtime access to Config-fed input or a pure `Policy` helper | Keep `Config.issuer!/0`, `storage_prefix/0`, `oban_prefix/0` behavior exactly. [VERIFIED: xref DOT edges 9–15; source] |
| Protected resource DPoP/userinfo (2) | DPoP returns `Userinfo.Error`; Userinfo calls DPoP | Put common endpoint error struct/factory in neutral protocol module, or make DPoP return a neutral error translated by Userinfo | DPoP nonce/error status/header behavior on `/userinfo` and resource plug. [VERIFIED: xref DOT edges 708–725; source] |
| Authorization request/request object (2) | RequestObject returns `AuthorizationRequest.Error`; AuthorizationRequest invokes RequestObject | Put browser/redirect error value/factory in neutral module; both callers consume it | JAR outer-conflict, signature/decryption, redirect-safe error behavior. [VERIFIED: xref DOT edges 531–545; source] |

### Anti-Patterns to Avoid

- **Changing a nested public struct's module name:** creates a source-compatible-looking refactor that breaks pattern matching or type consumers. Keep the exact public struct where required. [VERIFIED: D-02]
- **Making `Lockspire.Protocol.Registration` call an “Admin-independent” facade that itself calls Admin:** the AST rule becomes cosmetic and DCR remains transitively coupled. Make the shared owner neutral. [VERIFIED: D-05 through D-07]
- **Splitting a lifecycle operation across caller and service transactions:** can persist a client, RAT, IAT redemption, or audit event independently. Preserve repository transaction boundaries as a single service operation. [VERIFIED: `Repository.replace_client_registration/4`, `Repository.transact_with_audit/2`]
- **Testing only aliases/imports:** remote calls and dynamically composed module atoms can evade simplistic checks. Fitness must inspect aliases and remote call AST nodes, and xref must be the authoritative cycle check. [ASSUMED]
- **Hard-coding a new web router in protocol:** replaces one default web dependency with another. The protocol receives paths/capability; web owns Phoenix reflection. [VERIFIED: D-09]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dependency graph/cycle detection | Custom parser of Elixir `alias`/call syntax | `mix xref graph --format cycles` | Mix captures actual compile/runtime/export dependency semantics. [VERIFIED: D-03, local baseline] |
| Source boundary regression checks | New static-analysis dependency | Existing ExUnit AST parsing with `Code.string_to_quoted!/1` + `Macro.prewalk/3` | Deterministic, project-native, already established. [VERIFIED: D-04, existing fitness test] |
| Client registration validation | A second DCR/operator validator | Extend/reuse `Lockspire.ClientRegistration.Shape` and neutral client metadata service | Current Shape is the dependency-light validation precedent and duplicate behavior is the ARCH-03 defect. [VERIFIED: `client_registration/shape.ex`, D-05] |
| Transaction composition | New hand-rolled Ecto transaction wrapper | Existing `Repository.transact_with_audit/2`, `replace_client_registration/4`, and repository methods | Existing methods encode audited atomic writes; preserve them until Phase 135 decomposition. [VERIFIED: repository and Admin sources; deferred Phase 135] |

## Common Pitfalls

### Pitfall 1: “Cycle free” but public pattern matching breaks

**What goes wrong:** moving `%TokenExchange.Success{}` or `%AuthorizationRequest.Error{}` to a new module removes an xref edge but changes externally observable Elixir values.  
**Why it happens:** a struct's module name is part of its runtime shape.  
**How to avoid:** introduce neutral collaborators for construction/dispatch first; use retained facade structs/types at the boundary and assert `function_exported?` plus representative pattern/result tests. [VERIFIED: D-02; existing struct references]

### Pitfall 2: DCR gets direct-registration semantics

**What goes wrong:** routing DCR through `Clients.register_client/1` accidentally makes `scope` mandatory or strips DCR provenance/RAT/IAT fields.  
**Why it happens:** direct `Clients` normalizes `allowed_scopes` through required-list input while DCR intentionally invokes Shape with `require_scopes: false`.  
**How to avoid:** give `ClientLifecycle` separate neutral intents/projections for direct and self-registered clients; make DCR policy resolve first and keep its translator at the edge. [VERIFIED: `Clients.normalize_client_attrs/1`, `Registration.validate_registration_shape/2`, D-06]

### Pitfall 3: audit/credential atomicity is weakened by extraction

**What goes wrong:** client mutation succeeds but RAT rotation/audit or IAT-related state is absent after a partial failure.  
**Why it happens:** current code uses repository audited transaction helpers, but movement can turn a single call into sequential calls.  
**How to avoid:** the neutral service owns the existing repository call and audit event construction together; add failure-injection/transaction regression tests around create/update/delete. [VERIFIED: `Admin.Clients.create_dcr_client/1`, `RegistrationManagement.persist_update/3`, repository methods]

### Pitfall 4: discovery becomes static rather than mount-truthful

**What goes wrong:** discovery publishes endpoints not mounted by a host, or loses test-configurable alternate routers.  
**Why it happens:** the default web router edge is removed without preserving supplied route truth.  
**How to avoid:** normalize a route-path capability at the configuration/delivery edge; preserve an alias-compatible `:discovery_router` fallback during v1.x. [VERIFIED: discovery tests and D-09; fallback detail ASSUMED]

### Pitfall 5: fitness tests pass while Mix cycles remain

**What goes wrong:** source restrictions have no prohibited aliases yet exported type dependencies still form cycles.  
**Why it happens:** the token cycle and two protocol cycles include `export` edges.  
**How to avoid:** execute `mix xref graph --format cycles` as an assertion and surface the full output if nonempty; AST rules are complementary. [VERIFIED: local cycle output]

## Code Examples

### Focused zero-cycle command contract

```elixir
# Test helper; keep the captured output in the assertion so the exact
# remaining cycle path is visible to the maintainer.
{output, exit_status} =
  System.cmd("mix", ["xref", "graph", "--format", "cycles"],
    stderr_to_stdout: true,
    env: [{"MIX_ENV", "test"}]
  )

assert exit_status == 0
refute output =~ "Cycle of length", output
```

This uses only a project runtime tool and makes the diagnostic actionable; deciding whether it belongs in ExUnit or a dedicated Mix alias is implementation discretion. [ASSUMED]

### AST rule for protocol outer-layer reach-through

```elixir
defp forbidden_protocol_reference?({:__aliases__, _, [:Lockspire, layer | _]})
     when layer in [:Web, :Admin],
     do: true

defp forbidden_protocol_reference?(_node), do: false

Enum.each(production_files(@protocol_root), fn path ->
  refute ast_contains?(parse!(path), &forbidden_protocol_reference?/1),
         "#{path} reaches into an outer delivery layer"
end)
```

This follows the exact parser/prewalk design already used for Ecto and host-repo fitness checks. [VERIFIED: `test/lockspire/architecture_fitness_test.exs`]

### Boundary translation sketch

```elixir
# Protocol edge: policy and RFC translation remain here.
with {:ok, resolved} <- DcrPolicy.resolve(server_policy, iat_overrides, metadata),
     {:ok, intent} <- ClientLifecycle.Metadata.from_dcr(metadata, resolved, current_client),
     {:ok, client} <- ClientLifecycle.replace_self_registered(intent, rat_hash, audit_context) do
  {:ok, %RegistrationManagement.UpdateSuccess{
    client: client,
    registration_access_token_plaintext: rat_plaintext
  }}
end

# Admin edge: presentation/result contract remains here.
with {:ok, intent} <- ClientLifecycle.Metadata.from_operator(attrs, client),
     {:ok, updated} <- ClientLifecycle.update_operator(intent, actor) do
  {:ok, updated}
end
```

This is a prescriptive shape, not an existing API. The neutral service must not accept HTTP/Plug data or return protocol-specific structs. [ASSUMED]

## State of the Art

| Old Approach | Current Phase Approach | Impact |
|--------------|------------------------|--------|
| One-time convention that protocol “should not” reach outer layers | Executable xref + AST fitness invariant | Direction regressions fail locally and in CI. [VERIFIED: D-04, D-12] |
| DCR reaches `Admin.Clients` for shared metadata/lifecycle behavior | Both boundaries invoke a neutral client lifecycle owner | Removes outer-layer dependency and duplication while preserving contracts. [VERIFIED: D-05 through D-07] |
| Protocol discovers mounted endpoints by defaulting to Web Router | Delivery/config provides paths; protocol interprets them | Keeps protocol delivery-neutral and mount-truthful. [VERIFIED: D-09] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `System.cmd/3` can be used reliably from the selected ExUnit topology contract with the stated `MIX_ENV` behavior. | Standard Stack / code example | Use a dedicated checked script or Mix alias if recursive Mix invocation is unsuitable. |
| A2 | Existing v1.x consumers pattern-match the named nested public structs, so moving their module name is breaking. | Pattern 1 | Conservative retained-module strategy may preserve more than strictly necessary, but avoids compatibility risk. |
| A3 | A temporary `:discovery_router` compatibility fallback is required for host configuration beyond tests. | Pattern 3 / Pitfall 4 | If config is explicitly private, migration can be stricter after verifying docs/support surface. |
| A4 | The proposed service names and precise result shapes are appropriate. | Project structure / code sketch | Names are discretionary; implementation must retain only current advertised APIs. |

## Open Questions

1. **Where should the executable Mix cycle assertion live?**
   - What we know: `mix xref graph --format cycles` produces the needed definitive baseline and normal test code already parses AST. [VERIFIED: local command; existing fitness test]
   - What's unclear: whether invoking Mix from the ExUnit process is accepted by this project's test execution topology.
   - Recommendation: first add a direct script/alias that exits nonzero and call it from CI/`mix qa`; only embed `System.cmd` in ExUnit after a focused test proves no recursive-Mix issue. [ASSUMED]

2. **Which public nested structs are documented APIs versus implementation-visible structs?**
   - What we know: D-02 requires all existing nested public module names/result shapes to work, and current tests use `TokenExchange.Success/Error`, `Registration.Success/Error`, `RegistrationManagement.UpdateSuccess`, and `AuthorizationRequest.Error`. [VERIFIED: D-02; test/source references]
   - What's unclear: the exact supported-surface documentation scope for `TokenExchange` internals.
   - Recommendation: treat every currently exported nested module in the five cycles as compatibility-sensitive; add exports/result characterization before moving it. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir Mix | xref graph and ExUnit validation | ✓ | project runtime (command completed) | none needed. [VERIFIED: local `mix xref graph --format cycles`] |
| PostgreSQL/test database | client lifecycle transaction characterization | ✓ through existing test suite setup | project-managed | Existing repository test setup. [VERIFIED: existing Ecto tests; exact server version not probed] |

**Missing dependencies with no fallback:** none. [VERIFIED: phase uses project-native tools]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, project-native. [VERIFIED: `test/lockspire/architecture_fitness_test.exs`] |
| Config file | `test/test_helper.exs`. [VERIFIED: repository test layout] |
| Quick run command | `mix test test/lockspire/architecture_fitness_test.exs`. [VERIFIED: existing test file] |
| Full suite command | `mix test.fast`, `mix test.integration`, `mix qa`, and `mix docs.verify`. [VERIFIED: milestone Phase 133 final gates] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ARCH-01 | Exactly zero runtime/export cycles and retained public facades | focused topology + compatibility | dedicated topology alias/script; `mix test ...architecture_fitness...` | ❌ Wave 0 |
| ARCH-02 | No protocol source references `Lockspire.Web`/`Lockspire.Admin` | deterministic AST | `mix test test/lockspire/architecture_fitness_test.exs` | ✅ extend |
| ARCH-03 | Direct/DCR/admin paths retain intended distinct contracts but share lifecycle owner | unit + repository integration characterization | focused `clients`, `admin/clients`, `protocol/registration*` tests | ✅ extend |
| ARCH-04 | Fitness fails for cycles, wrong dependency direction, delivery→Ecto reach-through, removed facade, duplicated service ownership | deterministic source/AST plus xref command | topology alias/script and architecture fitness test | ✅ extend |

### Sampling Rate

- **Per task commit:** focused relevant ExUnit files plus the topology command. [VERIFIED: existing phase quality practice]
- **Per wave merge:** `mix test.fast`. [VERIFIED: milestone final gate]
- **Phase gate:** `mix compile --warnings-as-errors`, `mix test.fast`, `mix test.integration`, `mix qa`, and `mix docs.verify`. [VERIFIED: milestone final gate]

### Wave 0 Gaps

- [ ] Extend `test/lockspire/architecture_fitness_test.exs` with protocol outer-layer, delivery/Ecto boundary, retained public exports, and neutral-service delegation rules.
- [ ] Add a deterministic topology command/test which captures and fails on any `mix xref graph --format cycles` output.
- [ ] Add characterization tests that pin direct required scopes; DCR optional scope/policy-first/RAT/IAT; immutable fields; exact URI/logout validation; PKCE floor; audit attribution; atomic update/delete/secret paths.
- [ ] Add focused regression tests for each cycle-specific endpoint/error seam before moving it.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve client-auth metadata, PKCE, DCR IAT/RAT, and no secret leakage through boundary translators. [VERIFIED: AGENTS.md, D-08] |
| V3 Session Management | yes | Preserve logout URI/origin and session-required validation. [VERIFIED: `Admin.Clients.validate_logout_metadata/3`, D-08] |
| V4 Access Control | yes | Preserve immutable-client protections, active state, and DCR URL/RAT match behavior. [VERIFIED: `Admin.Clients.reject_immutable_changes/1`, `RegistrationManagement`] |
| V5 Input Validation | yes | Reuse `ClientRegistration.Shape` and current DCR validation/translation rather than duplicate validators. [VERIFIED: `client_registration/shape.ex`, D-05] |
| V6 Cryptography | yes | Retain hashed client secrets, sealed verifier material, DPoP/replay behavior, and no plaintext telemetry/errors. [VERIFIED: AGENTS.md, D-08] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Registration validation drift between DCR/admin | Tampering / Elevation | One neutral validation/lifecycle owner plus contract tests for intentional differences. [VERIFIED: D-05 through D-08] |
| Partial client/RAT/audit write | Repudiation / Tampering | Preserve repository audited transaction operations as one service call. [VERIFIED: repository lifecycle APIs] |
| Secret/key material escapes through new neutral errors | Information disclosure | Neutral outcomes carry safe reason atoms/records only; protocol/admin own redacted rendering; test telemetry/error payloads. [VERIFIED: D-08] |
| New cross-layer back edge reintroduces coupling | Elevation / Tampering | AST directional test plus Mix cycle gate. [VERIFIED: D-12] |
| Discovery over-advertises unmounted endpoint | Spoofing | Route capability originates at delivery/config edge and preserves mount-aware tests. [VERIFIED: D-09; discovery tests] |

## Sources

### Primary (HIGH confidence)
- Local `mix xref graph --format cycles` and generated local Mix xref DOT graph — exact five-cycle baseline and edge direction.
- `lib/lockspire/protocol/{registration,registration_management,discovery,protected_resource_dpop,userinfo,authorization_request,request_object}.ex` — current boundary/cycle ownership.
- `lib/lockspire/{clients,admin/clients,config,security/policy,storage/ecto/prefix}.ex` — lifecycle duplication, current transactions, configuration cycle.
- `test/lockspire/architecture_fitness_test.exs` — project-established deterministic AST test style.
- `.planning/phases/134-architecture-topology/134-CONTEXT.md` — locked scope and compatibility/security decisions.

### Secondary (MEDIUM confidence)
- None; research is repository-local and phase-specific.

### Tertiary (LOW confidence)
- None beyond items enumerated in the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all required tools are already in the repository/runtime and the phase forbids new dependencies.
- Architecture: HIGH — each required cycle and current coupling was inspected in local xref/source; exact module naming remains discretionary.
- Pitfalls: HIGH — derived from concrete current transaction/result/configuration seams, with implementation-specific fallbacks marked assumed.

**Research date:** 2026-08-27  
**Valid until:** Phase 134 implementation begins or the baseline xref graph changes.
