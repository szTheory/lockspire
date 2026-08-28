# Phase 135: Cohesive Internals — Codebase Patterns

**Purpose:** Map existing Lockspire patterns that Phase 135 can preserve while splitting the Ecto repository and token-exchange internals. This is a read-only design aid; it does not prescribe a new public API.

## 1. Stable facade over aggregate collaborators

| Target responsibility | Closest existing pattern | Evidence | Phase 135 application |
|---|---|---|---|
| Compatible storage entry point | `Lockspire.Storage.Ecto.Repository` implements all public storage behaviours and resolves the configured repo only through its private `repo/0`. | [repository.ex](../../../lib/lockspire/storage/ecto/repository.ex) module declarations and `repo/0` | Retain this module, its behaviour implementations, and `Config.repo!/0` lookup as a forwarding facade. New aggregate collaborators must remain private implementation details. |
| Record/domain ownership | Each aggregate already has a paired `*_record.ex` schema with `changeset/…` and `to_domain/1`: `ClientRecord`, `TokenRecord`, `SigningKeyRecord`, etc. | `lib/lockspire/storage/ecto/*_record.ex` | Place each collaborator beside the owned record(s), using existing schema mapping rather than introducing a generic persistence layer. |
| Narrow public contracts | Existing contracts are aggregate-specific: `ClientStore`, `TokenStore`, `KeyStore`, `ConsentStore`, `AuditStore`, and others. | `lib/lockspire/storage/*_store.ex` | Split repository code by these contracts, not merely by file size. A collaborator should own complete queries, mapping, state transitions, and persistence for one aggregate family. |
| Compatibility characterization | `test/lockspire/architecture_fitness_test.exs` locks stable facade exports; facade tests exercise callers through storage behaviours rather than record internals. | `architecture_fitness_test.exs:45-55` | Add/retain tests against facade functions while moving implementation beneath it; do not route production callers to new collaborator modules. |

## 2. Atomic Ecto operation shape

The repository’s established transition pattern is: `transact(fn -> locked query -> state validation -> record changeset -> repo update/insert -> domain mapping -> audit or rollback end)`. Examples are client registration replacement/rotation (`repository.ex:117-169`), server-policy updates, signing-key lifecycle transitions (`:1170-1229`), and authorization-code redemption (`:1238-1252`).

### Required preservation rules

| Operation class | Existing boundary | Refactor rule |
|---|---|---|
| Single-row lifecycle change | `transact/1` with `lock("FOR UPDATE")` before checking current state. | The aggregate collaborator owns the lock query and invalid-state mapping; the facade delegates without opening a second transaction. |
| Multi-record token rotation | `repo().transaction` wrapping `run_rotate_refresh_token/…`, returning normalized nested success/error values. | Keep refresh-family mutation, new-token insertion, and revocation outcome in one transaction; preserve the result normalization at the facade boundary. |
| Mutation plus audit | `transact_with_audit/2` rolls back work when audit persistence fails, and rolls back audit when work fails. | Do not split audit append into a post-commit side effect. Token/client/key collaborators must receive the transaction/audit capability explicitly. |
| Read paths | Query → `repo_one/all` → `to_domain/1` mapping, with sensitive reads marked where relevant. | Keep raw DB records inside the collaborator and return domains/results only. |

## 3. Token responsibility split

`Lockspire.Protocol.TokenExchange` is already the stable public dispatch and result-conversion facade. It owns grant selection and conversion from internal `TokenResult.Success/Error` to retained public `%TokenExchange.Success{}` / `%TokenExchange.Error{}` structs.

| Responsibility | Existing owner/analogue | Recommended internal home |
|---|---|---|
| Public dispatch and public response shape | `protocol/token_exchange.ex` | Keep unchanged. It must not call per-grant public facades recursively. |
| Grant orchestration | `Internal.AuthorizationCodeGrant`, `DeviceCodeGrant`, `CibaGrant`, `RefreshExchange`, `Rfc8693Exchange` | Retain per-grant coordinators; extract shared steps only when the owner is unambiguous. |
| Client authentication, resource validation, token issuance, persistence, audit, telemetry/failure emission | `Internal.GrantSupport` | Split into private focused collaborators behind an internal dependency bundle. Preserve grant coordinators as callers. |
| Token signing/formatting | `Internal.AccessTokenSigner`, `Protocol.TokenFormatter`, `Protocol.TokenLifetime` | Keep signing/formatting separate from storage mutation and OAuth error mapping. |
| Refresh-family lifecycle | `Internal.RefreshExchange` plus `TokenStore.rotate_refresh_token/…` | Preserve the dedicated refresh path and its family-wide replay semantics; do not force it through authorization-code support abstractions. |

## 4. Dependency-bundle normalization

Current internals obtain stores, clock, signers, and generators independently from `request[:opts]`; `GrantSupport` defaults most stores to `Repository`, while `RefreshExchange` requires its token store and negotiates transaction/audit functions with `function_exported?/3`.

**Recommended analogue:** introduce one private `Dependencies` struct/builder at the internal token boundary. It should:

1. Normalize existing `:opts` injection keys once (`:client_store`, `:token_store`, `:device_authorization_store`, `:ciba_authorization_store`, `:interaction_store`, `:key_store`, `:now`, token generators, signer/config dependencies).
2. Validate required capabilities eagerly (transaction and audit capability for operations needing durable audit) and return the existing OAuth-safe internal error class before mutating state.
3. Pass the typed bundle to internal collaborators; do not allow them to reach back into a request keyword bag.
4. Preserve legacy option keys in the adapter for v1.x tests and integrations.

This follows the current explicit test-injection convention while removing inconsistent defaults and runtime capability discovery from individual grant paths.

## 5. Characterization-test map

| Contract to pin before movement | Closest test evidence | Needed Phase 135 assertion style |
|---|---|---|
| Public facade/export and struct compatibility | `test/lockspire/protocol/token_exchange_test.exs:48-120`; architecture fitness suite | Call stable facade; assert exact retained success/error struct fields and OAuth status/error semantics. |
| Code redemption atomicity plus audit/telemetry | `test/lockspire/protocol/token_exchange/authorization_code_test.exs:624-718` | Prove one redemption succeeds, replay fails, and required audit/telemetry attribution remains observable. |
| Refresh rotation and reuse containment | `test/lockspire/protocol/refresh_exchange_test.exs:516-573`; `test/lockspire/storage/repository_test.exs:587-706` | Prove first rotation works and reuse revokes the family within one durable boundary. |
| Device/CIBA terminal transitions | `test/lockspire/protocol/token_exchange/device_code_test.exs`; CIBA/resource tests | Characterize terminal-state error, audit event, and preserved client/account attribution. |
| Signing-key transitions | `test/lockspire/storage/repository_test.exs:814-865` | Preserve guided locked state transitions and error classifications. |
| Audit rollback | `transact_with_audit/2` repository tests and caller tests | Inject failing audit store/repo capability and assert no operation commits. |

## Sequencing guidance

1. First add characterization tests at the stable facade/endpoint level where current coverage is incomplete.
2. Extract one repository aggregate at a time, preserving existing facade calls and transaction ownership.
3. Normalize internal token dependencies at the `TokenExchange` → internal grant boundary, then migrate one grant owner at a time.
4. Keep architecture-fitness/import checks green throughout; dependency direction and public shapes are correctness constraints, not cleanup follow-ups.

## Avoid

- Do not create a new public storage API or reconfigure the repository lookup.
- Do not expose Ecto record structs from new collaborators.
- Do not move audit append after commit or relax `FOR UPDATE` state transitions.
- Do not delete legacy `request[:opts]` injection without a compatibility adapter.
- Do not use source-file movement or compilation alone as refactor proof.
