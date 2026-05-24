# Phase 32: Polling & Token Issuance - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/domain/device_authorization.ex` | model | transform | `lib/lockspire/domain/device_authorization.ex` | exact |
| `lib/lockspire/storage/device_authorization_store.ex` | behavior | CRUD | `lib/lockspire/storage/device_authorization_store.ex` | exact |
| `lib/lockspire/storage/ecto/device_authorization_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/device_authorization_record.ex` | exact |
| `priv/repo/migrations/*_extend_lockspire_device_authorizations_polling_state.exs` | migration | transform | `priv/repo/migrations/20260428090000_extend_lockspire_device_authorizations_verification_state.exs` | role-match |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |
| `lib/lockspire/protocol/token_exchange.ex` | protocol/service | request-response | `lib/lockspire/protocol/token_exchange.ex` | exact |
| `lib/lockspire/web/controllers/token_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/token_controller.ex` | exact |
| `lib/lockspire/web/controllers/token_json.ex` | serializer | request-response | `lib/lockspire/web/controllers/token_json.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | protocol/service | request-response | `lib/lockspire/protocol/discovery.ex` | exact |
| `test/lockspire/storage/ecto/repository_device_authorization_test.exs` | test | CRUD | `test/lockspire/storage/ecto/repository_device_authorization_test.exs` | exact |
| `test/lockspire/protocol/token_exchange_test.exs` | test | request-response | `test/lockspire/protocol/token_exchange_test.exs` | exact |
| `test/lockspire/web/token_controller_test.exs` | test | request-response | `test/lockspire/web/token_controller_test.exs` | exact |
| `test/lockspire/protocol/discovery_test.exs` | test | request-response | `test/lockspire/protocol/discovery_test.exs` | exact |
| `test/lockspire/web/discovery_controller_test.exs` | test | request-response | `test/lockspire/web/discovery_controller_test.exs` | exact |
| `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | integration test | request-response | `test/integration/phase31_generated_host_verification_e2e_test.exs` | role-match |

## Pattern Assignments

### `lib/lockspire/protocol/token_exchange.ex`

**Analog:** `lib/lockspire/protocol/token_exchange.ex`

**Grant-type dispatch pattern:** route on `grant_type`, then delegate to a grant-specific helper while preserving shared error shaping and token response assembly. Use this same shape for `urn:ietf:params:oauth:grant-type:device_code`. [VERIFIED: lib/lockspire/protocol/token_exchange.ex]

**Success assembly pattern:** existing auth-code flow builds one `Success` struct and one OAuth-safe `Error` struct; device flow should return those same structs rather than introducing a new surface. [VERIFIED: lib/lockspire/protocol/token_exchange.ex]

### `lib/lockspire/storage/ecto/repository.ex`

**Analog:** `lib/lockspire/storage/ecto/repository.ex`

**Transition pattern:** `transact(fn -> ... |> lock("FOR UPDATE") |> ... end)` plus explicit expected-state guards already exists for interactions and Phase 31 device verification. Reuse that exact discipline for poll timing updates and `approved -> consumed` redemption. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

**Mapping pattern:** repo functions return domain structs through `map_one/2` and collapse nil/not-found cases explicitly. Device-code polling should follow the same behavior instead of leaking raw records. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

### `lib/lockspire/domain/device_authorization.ex`

**Analog:** `lib/lockspire/domain/device_authorization.ex`

**Domain-shape pattern:** explicit fields, explicit statuses, and helper functions for canonicalization live here already. Poll-state fields such as `effective_poll_interval_seconds` and `next_poll_allowed_at` should be added in the same explicit style rather than hidden in opaque metadata. [VERIFIED: lib/lockspire/domain/device_authorization.ex]

### `lib/lockspire/storage/ecto/device_authorization_record.ex`

**Analog:** `lib/lockspire/storage/ecto/device_authorization_record.ex`

**Schema-update pattern:** keep additive field definitions in the schema, widen `changeset/2` and `update_changeset/2`, and extend `to_domain/2` so the protocol always consumes typed domain structs. [VERIFIED: lib/lockspire/storage/ecto/device_authorization_record.ex]

### `lib/lockspire/web/controllers/token_controller.ex` and `token_json.ex`

**Analog:** same files

**Thin-controller pattern:** controller reads the `Authorization` header, calls `TokenExchange.exchange/1`, sets cache headers, and serializes the returned struct. Device-flow work should preserve this shape; the controller should not classify device states itself. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex]

**Serializer pattern:** `TokenJSON.error_response/1` currently exposes only `error` and `error_description`. If Phase 32 chooses to add `interval` to `slow_down`, make it an explicit extension in `TokenJSON`, not an ad hoc controller override. [VERIFIED: lib/lockspire/web/controllers/token_json.ex]

### `lib/lockspire/protocol/discovery.ex`

**Analog:** `lib/lockspire/protocol/discovery.ex`

**Truthful-metadata pattern:** published lists derive from mounted-route truth and repo state. Extend `@grant_types_supported` only when the device grant is actually shipped, and consider whether `device_authorization_endpoint` should now be published since `/device/code` is already mounted. [VERIFIED: lib/lockspire/protocol/discovery.ex]

### Test Patterns

**`test/lockspire/protocol/token_exchange_test.exs`:**
- integration-heavy setup with real repo, real client records, and helper functions
- asserts both returned payloads and persisted storage side effects
- already has patterns for refresh rotation, replay handling, and optional `id_token` issuance

**`test/lockspire/web/token_controller_test.exs`:**
- HTTP contract proof for `/token`
- asserts cache headers and JSON shape
- should mirror protocol-level device cases at the controller layer

**`test/lockspire/protocol/discovery_test.exs` + `test/lockspire/web/discovery_controller_test.exs`:**
- truth-based metadata verification at both pure protocol and HTTP layers
- ideal place to pin `grant_types_supported` widening for device flow

**`test/integration/phase31_generated_host_verification_e2e_test.exs`:**
- best analog for end-to-end device-flow state because it already creates approved device authorizations through the host-owned seam
- Phase 32 E2E should continue from that approved state into `/token` polling success and replay failure
