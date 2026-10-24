# Phase 165: Management-Token Lifecycle & Recovery - Pattern Map

**Mapped:** 2026-10-21  
**Files analyzed:** 20 anticipated files (production, tests, docs)  
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/dcr_policy.ex` | service | transform | same file | exact |
| `lib/lockspire/protocol/registration.ex` | service | request-response | same file | exact |
| `lib/lockspire/client_metadata.ex` | utility | transform | same file | exact |
| `lib/lockspire/domain/client.ex` | model | transform | same file | exact |
| `lib/lockspire/protocol/registration_management.ex` | service | request-response | same file | exact |
| `lib/lockspire/client_lifecycle.ex` | service | CRUD | same file | exact |
| `lib/lockspire/storage/ecto/repository/client_store.ex` | service | CRUD | same file | exact |
| `lib/lockspire/web/controllers/registration_controller.ex` | controller | request-response | same file | exact |
| `lib/lockspire/web/registration_json.ex` | utility | transform | same file | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | component | request-response | same file | exact |
| `test/lockspire/protocol/dcr_policy_test.exs` | test | transform | same file | exact |
| `test/lockspire/protocol/registration_management_test.exs` | test | request-response | same file | exact |
| `test/lockspire/web/controllers/registration_controller_test.exs` | test | request-response | same file | exact |
| `test/lockspire/web/registration_json_test.exs` | test | transform | same file | exact |
| `test/integration/app_lifetime_management_test.exs` | test | request-response | same file | exact |
| `test/lockspire/storage/client_lifetime_conformance_test.exs` | test | CRUD | same file | exact |
| `test/lockspire/storage/repository_concurrency_test.exs` | test | event-driven | same file | exact |
| `test/support/client_lifetime_race_helpers.ex` | utility | event-driven | same file | exact |
| `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` | test | event-driven | same file | exact |
| `docs/dynamic-registration.md`, `docs/upgrading/client-lifetimes.md`, `docs/operator-admin.md`, `docs/supported-surface.md` | documentation | transform | same topic docs | exact |

The phase inputs name these integration points and focused proof files; planner may split test or docs edits into separate tasks. Adapter contracts and schema fields already exist, so no new migration is implied.

## Pattern Assignments

### `lib/lockspire/protocol/registration_management.ex` (service, request-response)

**Analog:** same file; tracked source.

Current public update generates a plaintext/hash pair, validates intake, persists through a lifecycle function, and returns plaintext only from success (`lib/lockspire/protocol/registration_management.ex:74-123`). Host recovery delegates to `ClientLifecycle.rotate_registration_access_token/3` and returns the plaintext only on `{:ok, updated_client}` (`:151-172`). Current authorization transaction locks/reloads, compares row id and snapshot hash, checks active state and app eligibility (`:181-218`). Extend this orchestration with the post-lock clock and management deadline check. Keep Phase 164's secret-rotation serialization semantics separate: management keeps stale-snapshot/hash rejection, with one winner and no overlap.

### `lib/lockspire/storage/ecto/repository/client_store.ex` (service, CRUD)

**Analog:** same file; tracked source.

The DCR replacement path locks by id and converts the locked record to the current domain row; it checks active and presented hash before deriving lifetime changes, selects only DCR metadata fields, then writes hash/lifecycle changes and appends audit in the same transaction (`lib/lockspire/storage/ecto/repository/client_store.ex:81-125`). Host replacement uses the same current-row/hash guard and transaction/audit boundary (`:128-163`). Secret rotation is a useful clock plumbing reference (`:170-` onward), but its post-lock/current-policy behavior does not change management's stale-hash competition policy. Management replacement must derive intended updates from the locked row, atomically set deadline/hash/version/metadata/audit, and return no plaintext on rollback.

### `lib/lockspire/domain/client.ex` (model, transform)

**Analog:** same file; tracked source.

`credential_lifetime_changes/3` is the canonical legacy promotion seam. For management replacement, v0 clears advisory app and secret deadlines, sets the new management deadline, and promotes the whole row to v1; v1 preserves authoritative app/secret dates. Use this existing contract rather than a version-only update or guessed backfill. The eligibility/deadline helpers are the place to preserve strict UTC whole-second boundary semantics.

### `lib/lockspire/protocol/dcr_policy.ex` and `lib/lockspire/protocol/registration.ex` (service, transform/request-response)

**Analogs:** same files; tracked source.

Resolved DCR policy already carries `default_registration_access_token_lifetime_seconds`; app and secret policy validators provide the pattern for validating nil or bounded nonnegative integer at policy resolution and persistence. Registration's `generate_credentials/2` creates the management token/hash at issuance (`lib/lockspire/protocol/registration.ex:453-465`). Snapshot the policy duration there and calculate its deadline from the issuance clock. Management replacement should likewise use the resolved current policy and a clock sampled after lock/reload.

### `lib/lockspire/client_metadata.ex` (utility, transform)

**Analog:** same file; tracked source.

`build_dcr_client/4` is the construction seam for attaching the resolved management deadline to newly registered clients. Preserve provenance-specific defaults and keep server-owned lifecycle values out of client-supplied metadata.

### `lib/lockspire/web/controllers/registration_controller.ex` (controller, request-response)

**Analog:** same file; tracked source.

The controller maps show/update/delete requests to the protocol layer and maps protocol outcomes to HTTP responses (`lib/lockspire/web/controllers/registration_controller.ex:38-93,125-167`). Update currently deletes body `client_id` before protocol validation (`:54-68`); complete the contract by retaining separate URL identity and required body identity. Missing Bearer and supplied invalid Bearer need distinct challenge formatting while keeping invalid credentials non-disclosing.

### `lib/lockspire/web/registration_json.ex` (utility, transform)

**Analog:** same file; tracked source.

Success and update serializers are the only plaintext token disclosure paths; read serialization removes secret material (`lib/lockspire/web/registration_json.ex:8-48`). Add server-derived extension values here: finite deadlines as Unix seconds, effective unlimited/legacy as `0`. Do not trust or echo client metadata for these server-owned extensions.

### `lib/lockspire/web/live/admin/clients_live/show.ex` (component, request-response)

**Analog:** same file; tracked source.

The existing confirmed `rotate_rat` event is restricted to self-registered clients, prevents repeat display, delegates to protocol recovery, and sets `revealed_rat` only on success (`lib/lockspire/web/live/admin/clients_live/show.ex:199-250`). Preserve this host permission/confirmation boundary and one-time display behavior. Recovery does not enable the app or change app/secret deadlines. Correct actor attribution in protocol telemetry while retaining the operator audit actor.

### PostgreSQL integration and concurrency tests

**Analogs:** `test/support/client_lifetime_race_helpers.ex` and `test/lockspire/storage/repository_concurrency_test.exs`; both tracked.

`start_session/4` runs an independent unboxed sandbox connection and reports its PostgreSQL backend pid; `await_blocker!/4` polls `pg_blocking_pids`, and `barrier_clock/2` advances a deterministic clock after the wait (`test/support/client_lifetime_race_helpers.ex:9-37,72-107`). Use these to prove the actual matching blocker and post-wait decision time. Assert durable row state and one-winner outcomes for expiry, stale GET/PUT/DELETE, competing PUT/recovery, secret rotation, disablement, and audit rollback. Sleeps or shared sandbox connections alone do not establish a race.

### Protocol, endpoint, serializer, conformance, and redaction tests

**Analogs:** corresponding existing files in `test/lockspire/protocol/`, `test/lockspire/web/`, `test/lockspire/storage/`, and `test/integration/`; tracked paths listed in File Classification.

Extend existing fixtures and assertions rather than inventing parallel test architecture. Cover nil/zero/positive policy, before/equality/after expiry, GET non-renewal, PUT body identity and replacement fields, expired/disabled app behavior, wire extension values, legacy promotion, adapter persistence/rollback, and authorized recovery. Telemetry/redaction cases must actually exercise self PUT and host recovery and assert observed events contain no plaintext/hash/secret/verifier material.

### Guidance docs

**Analogs:** `docs/dynamic-registration.md`, `docs/upgrading/client-lifetimes.md`, `docs/operator-admin.md`, and `docs/supported-surface.md`; tracked docs.

Update the existing topic sections with executable behavior: finite-token lockout tradeoff, host recovery steps, no-overlap behavior after successful PUT, and lost-response recovery. For admin copy, follow AGENTS.md: consult PRODUCT.md personas/vocabulary, use “app management token,” and update vocabulary contract/retired wording if terms change.

## Shared Patterns

### Current-state authority and transaction boundary

**Sources:** `lib/lockspire/protocol/registration_management.ex:181-218`; `lib/lockspire/storage/ecto/repository/client_store.ex:91-125,132-163`.

Recheck URL/client/hash/active state against a locked current row. Sample the injected decision clock after the blocking lock/reload. Persist replacement hash, deadline, lifetime canonicalization, intended mutable metadata, and required audit together. Keep response encoding/remote work outside the lock and reveal plaintext only after committed success.

### Lifetime rules

**Sources:** `lib/lockspire/domain/client.ex` (`credential_lifetime_changes/3`, eligibility/deadline helpers); `lib/lockspire/protocol/dcr_policy.ex`.

Nil and zero mean unlimited; finite deadlines use UTC whole seconds and strict `now < deadline`. GET never renews. Legacy v0 stays effectively unlimited until explicit replacement, which canonicalizes the whole row as specified. V1 management replacement preserves app and secret deadlines.

### Error and disclosure boundary

**Sources:** `lib/lockspire/web/controllers/registration_controller.ex:107-167`; `lib/lockspire/web/registration_json.ex:8-48`.

Missing Bearer gets a bare 401 Bearer challenge; wrong/expired/replaced/wrong-client/disabled credential gets non-disclosing `invalid_token`; unsupported state/storage failure remains server error. GET includes neither plaintext management token nor client secret. PUT/recovery disclose only the newly committed management token once.

### PostgreSQL race proof

**Source:** `test/support/client_lifetime_race_helpers.ex:9-107`.

Use independent backend sessions, observe the expected blocker via `pg_blocking_pids`, then advance the barrier clock and assert persisted state. This helper already supports real blocker and clock-wait verification.

## No Analog Found

None. Existing code and tests cover each role/data flow; no new schema, migration, background worker, or generic capability framework is in scope.

## Metadata

**Analog search scope:** `lib/lockspire/{protocol,storage,web}`, `test/{lockspire,integration,support}`, and `docs/`  
**Tracked-source gate:** all analog paths cited above were verified with `git ls-files`; no ignored runtime mirror paths are used.  
**Pattern extraction date:** 2026-10-21
