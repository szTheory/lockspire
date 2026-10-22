# Phase 163: App Lifetime & Compatible Host Storage - Pattern Map

**Mapped:** 2026-10-20  
**Files analyzed:** 30 implementation, migration, test, and package-proof files inferred from CONTEXT/RESEARCH  
**Analogs found:** 30 / 30 (many map to shared existing modules)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/domain/client.ex` | model | transform | same file (extend aggregate) | exact |
| `lib/lockspire/storage/ecto/client_record.ex` | model/adapter | transform | same file (changeset and `to_domain/1`) | exact |
| `lib/lockspire/storage/client_store.ex` | service/contract | request-response | same file | exact |
| `lib/lockspire/storage/ecto/repository/client_store.ex` | service | CRUD | same file | exact |
| `lib/lockspire/storage/ecto/repository/transaction_store.ex` | service | request-response | same file | exact |
| `lib/lockspire/protocol/client_eligibility.ex` (or chosen helper) | utility | transform | `lib/lockspire/protocol/client_auth.ex` and endpoint error mapping | role-match |
| `lib/lockspire/protocol/token_exchange/internal/dependencies.ex` | adapter | transform | same file | exact |
| `lib/lockspire/protocol/token_exchange/internal/legacy_options.ex` | adapter | transform | same file | exact |
| `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex` | service | request-response | same file | exact |
| `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex` | service | CRUD | same file | exact |
| `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex` | service | transform | same file | exact |
| `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex` | service | transform | same file | exact |
| `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex` | service | CRUD | `grant_persistence.ex` and `token_issuer.ex` | role-match |
| `lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex` | service | request-response | same file | exact |
| `lib/lockspire/protocol/userinfo.ex` | controller/service | request-response | same file | exact |
| `lib/lockspire/protocol/authorization_request.ex` | service | request-response | same file | exact |
| `lib/lockspire/protocol/authorization_flow.ex` | service | event-driven | same file | exact |
| `lib/lockspire/protocol/pushed_authorization_request.ex` | service | CRUD | same file | exact |
| `lib/lockspire/protocol/device_authorization.ex` | service | CRUD | same file | exact |
| `lib/lockspire/protocol/device_verification.ex` | service | request-response | same file | exact |
| `lib/lockspire/protocol/backchannel_authentication.ex` | service | CRUD | same file | exact |
| `lib/lockspire/protocol/ciba.ex` | service | event-driven | same file | exact |
| `lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex` | service | CRUD | `grant_persistence.ex` | role-match |
| `lib/lockspire/workers/ciba_notification_worker.ex` | worker | event-driven | same worker | exact |
| `lib/lockspire/protocol/introspection.ex` | controller/service | request-response | same file | exact |
| `lib/lockspire/web/controllers/registration_controller.ex` | controller | request-response | same file | exact |
| `priv/lockspire_repo/migrations/*_add_client_lifetime_fields.exs` | migration | transform | packaged migrations and migration helpers | exact |
| `test/lockspire/storage/*lifetime*` | test | CRUD/transform | repository atomicity/concurrency tests | role-match |
| `test/integration/*lifetime*upgrade*` | test | batch | clean-room package host harness | role-match |
| `scripts/acceptance/clean_room/*` (bounded package fixture extension) | utility/test harness | batch | `build_provider.py` / `package_input.py` | exact |

Names marked “or chosen” are role-based inferred additions; planner should settle exact filenames. Phase 164/165 credential enforcement is not owned here. Changes to `VerifyToken` should be avoided: it remains offline and has no client-store lookup.

## Pattern Assignments

### Client domain and Ecto record

**Analogs:** `lib/lockspire/domain/client.ex`; `lib/lockspire/storage/ecto/client_record.ex` (tracked).

Extend the existing client aggregate to avoid splitting durable protocol state. The domain struct uses explicit types and defaults (`client.ex:27-87, 89-151`). The Ecto record manually maps its fields in `to_domain/1` and changeset cast lists (`client_record.ex:109-188`; inspect the mapping function later in the file before editing). Add version and nullable deadlines to both mapping directions and every create/update cast boundary that is meant to persist them. Validate version as an explicit supported value; do not turn missing/unknown into v0. Preserve existing secret expiration values on v0 expansion.

### Repository client storage, current-row guards, and rollback

**Analog:** `lib/lockspire/storage/ecto/repository/client_store.ex`.

`replace_client_registration/5` starts the transaction, locks by current ID, reloads the record, then currently applies a whole stale replacement (`client_store.ex:55-85`). Copy the lock/query/reload and in-transaction audit structure, but apply only intended fields to the locked current row and preserve unrelated current credential state. For current-state failures, call the transaction abstraction's rollback. The repository facade delegates store calls; keep that boundary and do not introduce token-internal callback probing.

**Transaction analog:** `lib/lockspire/storage/ecto/repository/transaction_store.ex:4-23`.

```elixir
def transact(repo, fun) when is_function(fun, 0) do
  case repo.transaction(fn -> run(repo, fun) end) do
    {:ok, result} -> {:ok, result}
    {:error, reason} -> {:error, reason}
  end
rescue
  error -> {:error, error}
end

defp run(repo, fun) do
  case fun.() do
    {:ok, result} -> result
    {:error, reason} -> rollback(repo, reason)
    result -> result
  end
end
```

For custom adapters, require one explicitly declared transaction authority spanning the client guard, grant/token writes, and audits. Separate callbacks alone do not prove rollback.

### Adapter declaration and explicit dependency adaptation

**Analogs:** `lib/lockspire/protocol/token_exchange/internal/dependencies.ex:8-74, 131-150` and `legacy_options.ex:9-54`.

`Dependencies` is an enforced typed bundle, validated at adaptation, then attached to the request (`dependencies.ex:8-74`). `LegacyOptions.build/1` is the existing single seam to select stores and clocks (`legacy_options.ex:19-53`). Add adapter-owned lifetime version and typed support there; reject absent/unknown declarations with the existing structured server error style. The capabilities map defaults missing entries to `:all` (`dependencies.ex:131-141`), so it cannot certify lifetime conformance. Reuse neither that default nor runtime `function_exported?` probing. Generic storage should return expired/disabled rows; endpoint-owned mapping must distinguish credential errors from store/configuration failures.

### App eligibility, endpoint mapping, and clocks

**Analogs:** `lib/lockspire/protocol/client_auth.ex` (tracked; auth/error structure), `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex:11-31`, and `lib/lockspire/protocol/authorization_flow.ex:19-41`.

`ClientAuthentication.authenticate/4` delegates through the adapted client store and converts `ClientAuth.Error` into token endpoint `Error` (`client_authentication.ex:11-26`). It currently discards its request parameter and its clock when forming `client_auth_options/1` (`:29-31`); preserve explicit clock propagation through this seam. AuthorizationFlow captures `now(opts)` at operation entry (`authorization_flow.ex:25-41`), the convention to preserve at public entry points; guarded final decisions must obtain a fresh injected time after all blocking locks. Put enabled/deadline policy in one narrow domain decision, while each consumer maps its result to its established local/OAuth error and retains storage errors as 500-class failures. Equality is expired.

### Durable issuance and token TTL

**Analogs:** `grant_persistence.ex:11-70, 89-110`, `token_issuer.ex:45-79, 93-120`, and `access_token_signer.ex:52-87`.

`GrantPersistence` puts grant consumption, access/refresh token persistence, and audit append beneath one transaction call. Preserve explicit error return propagation so the transaction store can roll back. `TokenIssuer.issue_grant/5` is the common constructor for ordinary access and optional refresh artifacts; compute capped effective expiry once from final decision time and app deadline before constructing/signing, then derive persisted expiry, JWT `exp`, and `expires_in` from that value. Keep signing as a pure construction boundary: `AccessTokenSigner` receives token/client/dependencies and has no durable store or transaction. Retain opaque-token formatting and signed-token consistency. RFC 8693 has a distinct path (`rfc8693_exchange.ex:19-87`) and must preserve subject and actor identities while checking their issuing apps; its current independent token-store write is not a substitute for the shared guarded transaction contract.

### Consumer integration

**Analogs:** the same named existing consumer modules in the classification table; use each module's local result/error pattern. `userinfo.ex:41-53, 125-139` demonstrates layered parse → stored token → access-mode/claims validation and separates invalid token (401) from store failure (500). Apply current client lookup through `Dependencies.client_store` before host claims resolution; avoid its current hardcoded repository security-profile lookup (`userinfo.ex:184-198`). Keep offline verification free of client reads. Authorization flow, PAR, device, and CIBA entry/resume/approval seams have different established errors; insert the shared decision without flattening them. End DB locks before remote JWKS work, host callbacks, delivery, or response encoding.

### Prefix-aware additive migration and installer

**Analogs:** `lib/lockspire/storage/ecto/migration.ex:4-20, 24-70` and `lib/lockspire/install/migrations.ex:34-55`.

Use `use Lockspire.Storage.Ecto.Migration` and its `lockspire_table`/prefix helpers for a new packaged expansion migration. Keep deadlines nullable and use a constant v0 legacy default. The installer plans packaged migration copies without overwriting host files (`install/migrations.ex:34-55`); retain its checksum/preflight behavior and do not edit shipped migration bytes. Treat additive DDL as locking DDL operationally; do not claim nonblocking behavior.

### Tests: atomicity, independent locking, package upgrades

**Analogs:** `test/lockspire/storage/repository_atomicity_test.exs:11-47, 96-100`; `repository_concurrency_test.exs:1-23, 25-82`; `scripts/acceptance/clean_room/build_provider.py:224-281`.

Storage tests use ExUnit with real `TestRepo`, `:integration`, sandbox setup, unique IDs, and `on_exit` cleanup. Atomicity asserts durable state and one-shot replay, not only returned errors. The concurrency test's coordinated task release is a starting point, but this phase requires true independent PostgreSQL sessions, holder/contender backend PIDs, and a targeted `pg_blocking_pids` observation before advancing the injected clock. Do not copy the global wait observation in `reencrypt_concurrency_test.exs` blindly. For host proof, `prepare_provider/3` builds/copies an isolated host, writes runtime config, locks dependencies, invokes the public installer, applies overlays, and audits package boundaries (`build_provider.py:224-281`). Extend this package-root/process seam to pin the pre-lifetime and candidate packages separately and exercise real public/custom-prefix expansion; a synthetic record fixture is not binary compatibility proof.

Adapter conformance tests should follow the same real store fixture style and assert both positive round-trips/current-row guards/rollback and negative missing-or-unknown declarations, dropped fields, absent guards, and falsely split transaction authorities. Legacy cases must demonstrate historical secret timestamps remain advisory on v0.

## Shared Patterns

### Explicit store and clock dependencies

Adapt stores and clocks once at the existing boundary (`LegacyOptions`, `Dependencies`); pass the typed bundle through consumers. Do not use global time services or per-consumer callback discovery. A final guarded operation samples time after all blocking locks and reloads.

### Current-state transaction authority

Client row guards, grant/request consumption, token writes, and required audits share one transaction and rollback authority. Lock multiple client IDs in stable order and preserve the existing client-before-grant/token ordering. Apply intended changes to reloaded current state instead of replacing it from a stale domain snapshot.

### Endpoint-owned error mapping

Storage fetches remain state-preserving. A single eligibility result is mapped by each endpoint to the contract's local/OAuth error; malformed adapter state and storage failures remain server errors, never invalid credentials or unlimited fallback.

### Package migration integrity

New migration only; prefix helper; installer checksum/preflight. Expand while old code can run, drain old writers before first authoritative v1 write, and retain version/deadline data after cutover.

## No Analog Found

No materially new role lacks a base pattern. The novel compositions are lifetime adapter conformance and pinned dual-version package upgrade proof; use the existing storage integration and clean-room package harnesses above rather than inventing a new test framework.

## Metadata

**Analog search scope:** `lib/lockspire/domain`, `lib/lockspire/storage`, `lib/lockspire/protocol`, `lib/lockspire/workers`, `lib/lockspire/install`, `priv/lockspire_repo/migrations`, `test/lockspire/storage`, `test/integration`, `scripts/acceptance/clean_room`.  
**Tracked-source gate:** Every named implementation/test analog was verified by `git ls-files`; no ignored runtime mirror paths used.  
**Pattern extraction date:** 2026-10-20
