# Phase 135: Cohesive Internals - Research

**Researched:** 2026-08-27  
**Domain:** Compatibility-preserving Ecto aggregate extraction and OAuth/OIDC token-grant orchestration  
**Confidence:** HIGH

## User Constraints

### Locked Decisions

No Phase 135 CONTEXT.md existed when research began. The roadmap and requirements therefore define the binding scope: retain the existing `Lockspire.Storage.Ecto.Repository` and `Lockspire.Protocol.TokenExchange` public facades while splitting their internals, preserve transaction/concurrency guarantees, replace capability sniffing/runtime environment branching with explicit dependencies, and characterize all five grant paths. [VERIFIED: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`]

### the agent's Discretion

- Exact internal module names and aggregate grouping.
- Exact dependency-bundle struct/map layout, provided existing keyword-option injection remains compatible.
- The smallest set of focused tests that proves the listed wire, audit, telemetry, rollback, and concurrency contracts.

### Deferred Ideas (OUT OF SCOPE)

- Credo/Dialyzer/test-noise cleanup belongs to Phase 136.
- CI coverage, release artifacts, and external conformance evidence belong to Phase 137.
- New OAuth/OIDC grants, hosted authorization, host-product policy changes, and an operator UI redesign remain out of scope. [VERIFIED: Phase 134 deferred scope, `.planning/ROADMAP.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COH-01 | Aggregate-specific Ecto implementations are navigable behind the existing repository facade. | Aggregate map and facade-delegation structure below. |
| COH-02 | Code redemption, refresh reuse, DCR-plus-audit, and key transitions stay atomic under rollback and concurrency. | Transaction ownership map and DB-backed characterization requirements. |
| COH-03 | Token grants separate authentication, resources, issuance, persistence, polling, and observability behind the stable facade. | Token collaborator responsibility map and ordered extraction plan. |
| COH-04 | Explicit dependency bundles replace capability sniffing/runtime `Mix.env()` behavior while injection stays compatible. | Bundle/adaptation pattern and source fitness checks. |
| COH-05 | Characterization preserves endpoint responses/errors/tokens/audits/telemetry across five grants. | Flow-by-flow test map. |
</phase_requirements>

## Summary

`Lockspire.Storage.Ecto.Repository` is a 2,362-line adapter implementing fifteen storage behaviours. It already exposes a stable port-shaped API, but aggregate operations, Ecto queries, transaction helpers, audit composition, and shared low-level repository calls coexist in one module. Its critical operations use Ecto transactions and `FOR UPDATE` locks: DCR registration replacement/RAT rotation, authorization-code redemption, refresh rotation and reuse-family revocation, and signing-key transitions. [VERIFIED: `lib/lockspire/storage/ecto/repository.ex`]

The public `Lockspire.Protocol.TokenExchange` facade is deliberately small and stable, but its internal `GrantSupport` is 1,741 lines. It currently owns client authentication, resource validation, authorization-code/device/CIBA polling, token and ID-token construction, persistence, and audit/telemetry emission. The internal code also uses `function_exported?/3` to branch between persistence capabilities. [VERIFIED: `lib/lockspire/protocol/token_exchange.ex`, `lib/lockspire/protocol/token_exchange/internal/grant_support.ex`, `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex`]

**Primary recommendation:** characterize transaction and endpoint contracts first; then retain both public facades as thin delegates over aggregate/grant collaborators with explicit `Dependencies` bundles. Keep each multi-record operation in exactly one Ecto transaction-owning aggregate module and provide a compatibility adapter that converts legacy request `:opts` to the bundle before any collaborator runs. [VERIFIED: local storage/token source and existing `TokenExchangeCase` injection convention]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stable repository public API | Storage facade | Aggregate adapters | Existing storage behaviours and callers retain `Repository`; only Ecto implementation moves inward. [VERIFIED: repository behaviour declarations and architecture fitness test] |
| Record queries, locks, changesets, and atomic updates | Ecto aggregate adapter | Ecto repo boundary | The aggregate that mutates locked records must own its transaction; callers must not compose partial writes. [VERIFIED: repository redemption/rotation/key operations] |
| Token endpoint routing/result compatibility | Protocol public facade | Grant coordinator | `TokenExchange` selects grant type and exposes nested public result structs. [VERIFIED: `token_exchange.ex`] |
| Client authentication and security binding | Token collaborator | Explicit stores/policy dependencies | Shared across code, refresh, device, CIBA, and exchange paths but independent of issuing tokens. [VERIFIED: `grant_support.ex`] |
| Grant-specific polling and redemption | Grant collaborator | Aggregate storage adapters | Device/CIBA state and authorization-code single-use rules are distinct state machines. [VERIFIED: `grant_support.ex`, repository polling functions] |
| Token issuance and signing | Issuance collaborator | key/policy/config dependencies | Signing/format decisions are independent from grant persistence. [VERIFIED: `access_token_signer.ex`] |
| Audit and telemetry | Observability collaborator | explicit audit/telemetry dependencies | Must observe the same success/failure contract after extraction. [VERIFIED: `grant_support.ex`, `refresh_exchange.ex`] |

## Project Constraints (from AGENTS.md)

- Keep Lockspire an embedded companion library; do not require a standalone service.
- Preserve boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces.
- Keep host seams explicit and narrow: account resolution, claims, login redirects, branding, and product policy stay host-owned.
- Do not add SAML, LDAP/AD, hosted auth, or CIAM scope.
- Preserve PKCE S256, exact redirect matching, hashed secrets, single-use short-lived codes, refresh-family reuse revocation, no implicit flow/`alg=none`, and redaction. [VERIFIED: `AGENTS.md`]

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| Elixir/Erlang | Elixir 1.19.5 / OTP 28 | Module delegation, explicit dependency structs/maps, ExUnit | Project runtime already installed; no new runtime dependency is needed. [VERIFIED: local runtime] |
| Ecto SQL | 3.13.5 | Transactions, row locks, changesets, rollback | Locked project stack and current repository implementation. [VERIFIED: `AGENTS.md`, repository source] |
| PostgreSQL | 14.17 available | Concurrency/rollback characterization | Required because transaction and `FOR UPDATE` semantics cannot be proved by mocks alone. [VERIFIED: local `psql --version`, `pg_isready`] |
| ExUnit | project-native | Contract, DB, and source-fitness tests | Existing `test.fast` and `test.integration` aliases. [VERIFIED: `mix.exs`] |

**Installation:** none. This is a code/configuration refactor and must add no packages. [VERIFIED: phase scope]

## Package Legitimacy Audit

No external packages are installed. [VERIFIED: phase scope]

## Architecture Patterns

### System Architecture Diagram

```text
legacy callers / public protocols
          |
          v
 Repository facade -----------------------> TokenExchange facade
          |                                         |
          v                                         v
 aggregate delegates                       LegacyOpts -> Dependencies adapter
  clients | interactions | tokens                    |
  device  | ciba | keys | audit                       v
          |                              auth | resources | polling | issuance
          |                                   persistence | observability
          v                                         |
     Ecto Repo + rows + locks <---------------------+
          |
          v
 PostgreSQL transaction / rollback boundary
```

### Recommended Project Structure

```text
lib/lockspire/
├── storage/ecto/repository.ex                 # retained facade: behaviour declarations + delegates
├── storage/ecto/repository/
│   ├── client_store.ex                         # clients, DCR atomic replace/RAT/audit
│   ├── token_store.ex                          # code redemption, refresh family rotation/reuse
│   ├── device_authorization_store.ex           # polling/consume state machine
│   ├── ciba_authorization_store.ex             # polling/state machine
│   ├── signing_key_store.ex                    # publish/activate/retire transaction state machine
│   ├── audit_store.ex                          # audited transaction composition
│   └── support.ex                              # injected Ecto repo + private query/mapper helpers
└── protocol/token_exchange/
    ├── dependencies.ex                         # explicit typed runtime dependencies
    ├── legacy_options.ex                       # only compatibility conversion from request opts
    ├── client_authentication.ex
    ├── resource_selection.ex
    ├── grant_persistence.ex
    ├── grant_observability.ex
    ├── authorization_code_grant.ex
    ├── device_code_grant.ex
    ├── ciba_grant.ex
    ├── refresh_exchange.ex
    └── rfc8693_exchange.ex
```

Names are discretionary; the hard boundary is that the public facade remains and each aggregate/grant has one obvious owner. [VERIFIED: requirements and existing facade modules]

### Pattern 1: Thin facade over behaviour-complete aggregate delegates

**What:** retain `Lockspire.Storage.Ecto.Repository` as the sole advertised module and continue declaring all current `@behaviour`/`@impl` contracts there. Each function delegates to an internal aggregate module, supplying a repository dependency explicitly. Internal modules own records, changesets, query helpers, and transaction boundaries.

**Why:** it preserves source compatibility and existing injected module references while making code location match the aggregate. [VERIFIED: repository public function/behaviour inventory, architecture fitness compatibility checks]

**Atomicity rule:** never extract half of a multi-record operation into separate delegate calls. `replace_client_registration/4`, `redeem_authorization_code/3`, `rotate_refresh_token/6`, and `activate_signing_key/2` each enter a transaction and acquire locks today; their delegate must preserve one entry point and one rollback owner. [VERIFIED: repository source]

### Pattern 2: Explicit dependency bundle with legacy adapter

**What:** use `%TokenExchange.Dependencies{}` (or a private equivalent) containing named concrete dependencies: `client_store`, `token_store`, `device_authorization_store`, `ciba_authorization_store`, `interaction_store`, `key_store`, `server_policy_store`, `dpop_replay_store`, `clock`, `token_signer`, `telemetry`, and `audit_store`. Build it once at the facade/coordinator boundary. `LegacyOptions.from_request/1` maps the currently supported `request.opts` injection keys and defaults to `Repository`/normal production services.

**Why:** collaborators can call their required dependencies directly and do not silently degrade based on `function_exported?/3`; existing test and host injection remain source-compatible through the adapter. [VERIFIED: `TokenExchangeCase.token_request/2` provides individual options; source contains capability checks]

**Rule:** dependencies are required by construction. Optional product features must be represented as explicit values/strategies (for example `nil` only where the current public contract intentionally supports it), not by checking whether a module happens to export an unrelated function. [VERIFIED: COH-04]

### Pattern 3: Grant coordinator delegates by responsibility

**What:** keep stable public grant modules/facade as protocol translators, but split `GrantSupport` into focused collaborators:

| Collaborator | Owns | Must not own |
|--------------|------|--------------|
| `ClientAuthentication` | client credentials/JWT auth and client lookup | token issue/persistence |
| `ResourceSelection` | grant resource/audience narrowing validation | polling/audit |
| `AuthorizationCode`, `DeviceCode`, `Ciba` | state-specific validation/polling/redemption intent | shared signing/audit plumbing |
| `TokenIssuer` | token/ID-token construction and signing | record locking/response telemetry |
| `GrantPersistence` | a single atomic storage operation plus audit intent | protocol error translation |
| `GrantObservability` | current telemetry/audit success/failure shape | business decisions |

The authorization-code, device, CIBA, refresh, and RFC 8693 coordinators compose these collaborators and translate to the existing neutral/public `TokenResult` values. [VERIFIED: function clusters in `grant_support.ex`, current facade/result compatibility]

### Pattern 4: Characterize at the externally observable seam

**What:** before and during moves, exercise each supported grant through `TokenExchange.exchange/1` and endpoint integration tests, then assert public result/error shape, stored token transitions, audit rows/events, and telemetry emissions. Use DB-backed tests for locks/rollback; use capture handlers only to observe telemetry.

**Why:** source routing and pure helper unit tests cannot establish that a refactor kept atomic side effects or published error/telemetry behavior. [VERIFIED: COH-02/05 and existing unit/integration test layout]

### Anti-Patterns to Avoid

- **Copying Ecto helpers into aggregate modules:** produces divergent `repo_*` options/sensitive logging behavior. Extract shared private helpers first, then delegate aggregate functions. [VERIFIED: repository low-level helpers include sensitive options]
- **Moving transaction ownership to a coordinator:** lets two aggregates commit independently and breaks rollback. Keep locking/mutation/audit composition in one transaction-owning storage operation. [VERIFIED: repository transaction-sensitive operations]
- **Replacing all legacy `:opts` injection at once:** breaks tests/hosts with custom stores. Convert legacy inputs at one compatibility boundary and characterize accepted overrides. [VERIFIED: `TokenExchangeCase`] 
- **Using `function_exported?/3` as feature detection:** missing behavior becomes a different execution path. Require the explicit dependency and fail construction/tests if it is invalid. [VERIFIED: COH-04 and source calls]
- **Changing public `TokenExchange.Success/Error` structs:** breaks callers that pattern-match exact modules. Preserve facade result conversion. [VERIFIED: `token_exchange.ex`, Phase 134 compatibility decision]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Database atomicity/concurrency | in-memory locks or coordinator rollback logic | Ecto `transaction`, `rollback`, and existing `FOR UPDATE` queries | PostgreSQL is the source of truth across processes. [VERIFIED: repository source] |
| Compatibility migration | parallel replacement public API | retained facade plus an internal legacy-options adapter | Existing host/tests inject the facade and option keys. [VERIFIED: `TokenExchangeCase`, public facade] |
| Telemetry assertions | production telemetry implementation duplicate | existing observability plus ExUnit capture/handlers | Characterization should observe real emissions, not recreate them. [ASSUMED] |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Existing PostgreSQL records use the current Ecto schemas; no schema/key rename is in phase scope. | None — code extraction only; preserve migrations and records. [VERIFIED: Ecto record files and phase scope] |
| Live service config | Storage repo and token collaborators are selected by application/request configuration, not a renamed external service. | Compatibility adapter preserves current option injection; no external configuration migration. [VERIFIED: `TokenExchangeCase`, repository source] |
| OS-registered state | None found in repository scope. | None. [VERIFIED: phase scope/source audit] |
| Secrets/env vars | No secret/env key rename is planned. | None; preserve sensitive query logging/redaction. [VERIFIED: repository helper, AGENTS.md] |
| Build artifacts | No package/module rename requires a rebuilt installed artifact beyond normal compile. | Normal `mix compile` and test execution. [VERIFIED: phase scope] |

## Common Pitfalls

### Pitfall 1: Rollback test passes while concurrent callers still race

**What goes wrong:** an extraction retains error rollback but drops/moves `FOR UPDATE`, allowing two redemptions or key activations to observe stale state.  
**How to avoid:** retain the locked query and transaction in the same aggregate module; add a SQL-sandbox-enabled `Task.async` two-contender test for code redemption and one relevant lifecycle transition. [VERIFIED: repository uses `lock("FOR UPDATE")`; existing concurrency style in `initial_access_token_test.exs`]

### Pitfall 2: DCR audit becomes a follow-up write

**What goes wrong:** client replacement or RAT rotation commits before audit failure.  
**How to avoid:** preserve `transact_with_audit`/transaction composition in the client aggregate and explicitly inject an audit failure in characterization tests. [VERIFIED: `replace_client_registration/4`, `transact_with_audit/2`]

### Pitfall 3: Explicit bundles accidentally change test injection

**What goes wrong:** tests that provide only `:server_policy_store`, `:dpop_replay_store`, or `:now` silently use production defaults.  
**How to avoid:** make adapter mapping exhaustive, write a table-driven compatibility test for every currently read option key, and forbid collaborators from reading `request.opts` directly. [VERIFIED: `TokenExchangeCase`, internal `request_options/1` functions]

### Pitfall 4: Audit/telemetry parity is assumed from a successful token response

**What goes wrong:** OAuth wire response remains correct but events/reason codes disappear or duplicate.  
**How to avoid:** assert captured event metadata/reason codes for success, replay/reuse, invalid resource, pending/slow-down, and exchange denial cases. [VERIFIED: COH-05 and current audit helper clusters]

## Code Examples

### Facade delegation with retained API

```elixir
# Illustrative internal pattern; keep existing public arities and behaviours.
defmodule Lockspire.Storage.Ecto.Repository do
  @impl Lockspire.Storage.TokenStore
  def redeem_authorization_code(token_hash, redeemed_at, access_token) do
    TokenStore.redeem_authorization_code(repo(), token_hash, redeemed_at, access_token)
  end
end

defmodule Lockspire.Storage.Ecto.Repository.TokenStore do
  def redeem_authorization_code(repo, token_hash, redeemed_at, access_token) do
    repo.transaction(fn ->
      # locked query + mutation remain together
    end)
  end
end
```

### Construct dependencies once, then pass them explicitly

```elixir
deps = TokenExchange.LegacyOptions.dependencies_from(request)
TokenExchange.AuthorizationCodeGrant.exchange(request, deps)

# collaborators receive only what they require
ClientAuthentication.authenticate(params, authorization, deps.client_store)
ResourceSelection.validate(params, authorization_code)
GrantPersistence.redeem_authorization_code(intent, deps.token_store, deps.audit_store)
```

The examples express the recommended shape; actual values must preserve current request/result contracts. [VERIFIED: existing request option and facade patterns]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| One adapter owns all Ecto aggregates | Facade plus aggregate modules sharing controlled Ecto support | Makes ownership searchable while retaining ports. [VERIFIED: COH-01] |
| Capability sniffing on injected modules | Explicit dependency bundle with compatibility adaptation | Invalid/missing dependencies fail deterministically instead of choosing degraded paths. [VERIFIED: COH-04] |
| Broad grant-support helper | focused auth/resource/polling/issue/persist/observe collaborators | Smaller, independently characterized protocol responsibilities. [VERIFIED: COH-03] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing observability has a suitable ExUnit capture handler without a new dependency. | Don't Hand-Roll | Test implementation may need to use the project’s existing telemetry test helper instead. |

## Open Questions

1. **Which exact `request.opts` keys are public injection compatibility rather than test-only seams?**
   - What we know: `TokenExchangeCase` injects stores, clock, generators, and signer-related values; internal modules read options directly. [VERIFIED: `test/support/token_exchange_case.ex`, token internals]
   - Recommendation: inventory all `Keyword.get*`/`Map.get(:opts)` keys before deletion and make every observed key compatible in the adapter.
2. **Should an internal dependency bundle be a struct or validated map?**
   - Recommendation: a private struct is clearer and validates construction; do not expose it as an advertised public API. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | extraction/tests | ✓ | Elixir 1.19.5 / OTP 28 | — |
| PostgreSQL | DB rollback/concurrency proof | ✓ | 14.17; local server accepting connections | — |
| Ecto test sandbox | concurrent test ownership | ✓ | project existing infrastructure | — |

**Missing dependencies with no fallback:** none. [VERIFIED: local probes and existing test suite]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox |
| Config file | `test/test_helper.exs` / project Mix aliases |
| Quick run command | `mix test test/lockspire/storage/repository_test.exs test/lockspire/protocol/token_exchange_test.exs` |
| Full suite command | `mix test.fast && mix test.integration && mix qa && mix docs.verify` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COH-01 | Existing facade exports and delegates aggregate operations | source/compatibility | `mix qa.architecture` | ✅ expand `architecture_fitness_test.exs` |
| COH-02 | rollback/locks for code, refresh, DCR audit, keys | DB unit + concurrency | focused repository/client tests | ✅ expand `repository_test.exs`; add DCR concurrency case |
| COH-03 | focused grant coordination retains five result contracts | protocol unit | token-exchange focused suite | ✅ existing grant suites, add collaborator boundary checks |
| COH-04 | legacy injection maps to explicit dependencies; no sniffing/runtime env | source + unit | `mix qa.architecture` + focused bundle test | ❌ add bundle/fitness test |
| COH-05 | responses/errors/tokens/audits/telemetry per five flows | protocol/integration characterization | `mix test.fast && mix test.integration` | ✅ extend existing code/refresh/device/CIBA/RFC8693 suites |

### Sampling Rate

- **Per task commit:** focused affected ExUnit files plus `mix compile --warnings-as-errors`.
- **Per wave merge:** `mix test.fast` and `mix qa.architecture`.
- **Phase gate:** `mix test.fast && mix test.integration && mix qa && mix docs.verify`.

### Wave 0 Gaps

- [ ] A DB-backed concurrency test for authorization-code redemption after the aggregate split.
- [ ] A DCR replacement/RAT audit rollback characterization test at the retained facade.
- [ ] A dependency-bundle compatibility matrix for all legacy token request options.
- [ ] A source fitness test rejecting `function_exported?/3` and `Mix.env()` in token collaborator internals, allowing only the legacy adapter if needed.
- [ ] One characterization fixture/assertion helper that captures public result, tokens, audit events, and telemetry for all five grant paths.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve client auth and PKCE collaborators/results. [VERIFIED: AGENTS.md, grant support] |
| V3 Session Management | yes | Preserve code single-use and refresh family-reuse revocation atomically. [VERIFIED: AGENTS.md, repository] |
| V4 Access Control | yes | Preserve client/grant binding and resource narrowing validation. [VERIFIED: grant support] |
| V5 Input Validation | yes | Preserve existing parameter/resource validation at protocol boundary. [VERIFIED: grant support] |
| V6 Cryptography | yes | Preserve current signer/key lookup and no plaintext secret logging. [VERIFIED: `access_token_signer.ex`, AGENTS.md] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Double authorization-code redemption | Tampering | one transaction + row lock + concurrency proof. [VERIFIED: repository] |
| Refresh-token replay loses family revocation | Elevation of privilege | preserve rotation/reuse detection transaction and token-family revoke. [VERIFIED: repository] |
| DCR mutation without audit | Repudiation | compose update/RAT/audit in one transaction and test audit failure rollback. [VERIFIED: `replace_client_registration/4`] |
| Injection fallback silently omits DPoP/policy behavior | Spoofing | explicit validated dependency bundle, legacy adapter test. [VERIFIED: COH-04] |
| Logging key/secret material during extraction | Information disclosure | reuse sensitive repo options/redaction and test error/telemetry contracts. [VERIFIED: repository helper, AGENTS.md] |

## Sources

### Primary (HIGH confidence)

- `lib/lockspire/storage/ecto/repository.ex` — existing facade behaviours, Ecto transactions/locks, aggregate operations.
- `lib/lockspire/protocol/token_exchange.ex` — stable public token facade and result structs.
- `lib/lockspire/protocol/token_exchange/internal/grant_support.ex` — concentrated collaborator responsibilities and capability checks.
- `lib/lockspire/protocol/token_exchange/internal/{refresh_exchange,access_token_signer,token_endpoint_dpop}.ex` — injection and issuance/persistence seams.
- `test/support/token_exchange_case.ex`, `test/lockspire/storage/repository_test.exs`, grant tests — compatibility and proof conventions.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `AGENTS.md` — phase goal/security constraints.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked project dependencies and local runtime verified.
- Architecture: HIGH — exact monolith and transaction/capability seams inspected locally.
- Pitfalls: HIGH — based on concrete locks, transactions, and source injection branches.

**Research date:** 2026-08-27  
**Valid until:** implementation completion; this is repository-specific refactor research.
