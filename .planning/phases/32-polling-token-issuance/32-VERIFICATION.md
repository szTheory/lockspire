---
phase: 32-polling-token-issuance
verified: 2026-04-28T12:43:06Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
---

# Phase 32: Polling & Token Issuance Verification Report

**Phase Goal:** Devices can poll the token endpoint and receive tokens once the user authorizes the request.
**Verified:** 2026-04-28T12:43:06Z
**Status:** passed
**Re-verification:** No

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Devices receive `authorization_pending` when polling before user action. | ✓ VERIFIED | `TokenExchange` maps `:pending` to `authorization_pending` in `lib/lockspire/protocol/token_exchange.ex:236-247`; protocol, controller, and E2E proof cover the behavior in `test/lockspire/protocol/token_exchange_test.exs:522-544`, `test/lockspire/web/token_controller_test.exs:314-347`, and `test/integration/phase32_device_flow_token_exchange_e2e_test.exs:44-80`. |
| 2 | Devices receive `slow_down` if polling too frequently, respecting enforced intervals. | ✓ VERIFIED | Row-locked poll evaluation widens the next window and returns `:slow_down` in `lib/lockspire/storage/ecto/repository.ex:1179-1192`; public mapping is in `lib/lockspire/protocol/token_exchange.ex:249-260`; executable proof exists in `test/lockspire/storage/ecto/repository_device_authorization_test.exs:206-255`, `test/lockspire/protocol/token_exchange_test.exs:546-568`, and `test/lockspire/web/token_controller_test.exs:349-379`. |
| 3 | Devices successfully receive access and refresh tokens once the host app marks the request as authorized. | ✓ VERIFIED | Approved device authorizations are redeemed through the shared success path and atomically consumed in `lib/lockspire/protocol/token_exchange.ex:128-142,841-919`; E2E proof runs from `/device/code` to host approval to `/token` success and replay collapse in `test/integration/phase32_device_flow_token_exchange_e2e_test.exs:44-112`. |
| 4 | Polling interval enforcement is durable and node-safe rather than process-local. | ✓ VERIFIED | Durable state lives in `effective_poll_interval_seconds` and `next_poll_allowed_at` on the domain/schema in `lib/lockspire/domain/device_authorization.ex:18-35,88-117` and `lib/lockspire/storage/ecto/device_authorization_record.ex:10-24`; the migration persists both columns in `priv/repo/migrations/20260428130000_extend_lockspire_device_authorizations_polling_state.exs:4-21`. |
| 5 | A too-early poll atomically widens the next allowed interval and returns enough state to map to `slow_down`. | ✓ VERIFIED | `record_device_poll/3` runs under `FOR UPDATE` and updates both interval and next-allowed timestamp in `lib/lockspire/storage/ecto/repository.ex:339-346,1076-1080,1179-1192`; repository tests verify sticky growth and persisted state in `test/lockspire/storage/ecto/repository_device_authorization_test.exs:206-255`. |
| 6 | An approved device authorization can only be consumed once under row lock. | ✓ VERIFIED | `consume_device_authorization/3` locks by verification handle and only transitions `:approved -> :consumed` in `lib/lockspire/storage/ecto/repository.ex:350-357,1223-1244`; replay rejection is proven in `test/lockspire/storage/ecto/repository_device_authorization_test.exs:424-455` and `test/lockspire/protocol/token_exchange_test.exs:742-804`. |
| 7 | The existing token endpoint accepts the device grant type through `TokenExchange`. | ✓ VERIFIED | `TokenExchange.exchange/1` branches on `urn:ietf:params:oauth:grant-type:device_code` in `lib/lockspire/protocol/token_exchange.ex:56-79`; the thin Phoenix adapter passes `/token` requests through the shared protocol in `lib/lockspire/web/controllers/token_controller.ex:15-31`. |
| 8 | Pending, `slow_down`, denied, expired, mismatch, replay, and success cases map to RFC-shaped token outcomes. | ✓ VERIFIED | `TokenExchange` maps durable outcomes to `authorization_pending`, `slow_down`, `access_denied`, `expired_token`, and `invalid_grant` in `lib/lockspire/protocol/token_exchange.ex:230-320`; protocol and controller proof cover each mapping in `test/lockspire/protocol/token_exchange_test.exs:508-618,742-929` and `test/lockspire/web/token_controller_test.exs:314-505`. |
| 9 | Approved `openid` device requests reuse normal token success logic, including optional `id_token` and refresh-token policy. | ✓ VERIFIED | Device redemption reuses the same token persistence and optional refresh-token path in `lib/lockspire/protocol/token_exchange.ex:841-919`; tests prove refresh-token issuance stays policy-bound and `id_token` is present for approved `openid` requests in `test/lockspire/protocol/token_exchange_test.exs:806-929`. |
| 10 | The HTTP token endpoint returns RFC-shaped device-flow responses with the existing cache-header posture. | ✓ VERIFIED | `TokenController` remains thin and always applies `cache-control: no-store` and `pragma: no-cache` in `lib/lockspire/web/controllers/token_controller.ex:15-38`; `test/lockspire/web/token_controller_test.exs:314-505` asserts the headers and public error/success shapes across pending, `slow_down`, success, denied, expired, and replay. |
| 11 | Discovery truth advertises the shipped device-flow token support and does not over-claim beyond repo reality. | ✓ VERIFIED | Discovery publishes the device grant and `device_authorization_endpoint` only from mounted-route truth in `lib/lockspire/protocol/discovery.ex:8-18,22-26,73-90,126-132`; protocol and HTTP discovery tests pin the published metadata in `test/lockspire/protocol/discovery_test.exs:48-59` and `test/lockspire/web/discovery_controller_test.exs:52-57`. |
| 12 | Docs and E2E proof teach polling, `slow_down` backoff, and successful token redemption coherently. | ✓ VERIFIED | The host guide documents the 5-second interval, `authorization_pending`, `slow_down`, and terminal stop conditions in `docs/device-flow-host-guide.md:7-32`; onboarding and supported-surface docs are wired in `docs/install-and-onboard.md:44-50,75-82` and `docs/supported-surface.md:19-24,63-64`; release-readiness tests pin that contract in `test/lockspire/release_readiness_contract_test.exs:304-324`. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/domain/device_authorization.ex` | Durable poll-window state with deterministic initial interval | ✓ VERIFIED | Defines `effective_poll_interval_seconds`, `next_poll_allowed_at`, default interval `5`, and deterministic initial poll timing. |
| `lib/lockspire/storage/device_authorization_store.ex` | Storage contract for device-code lookup, poll evaluation, and consume | ✓ VERIFIED | Behaviour includes `fetch_device_authorization_by_device_code_hash/1`, `record_device_poll/3`, and `consume_device_authorization/3`. |
| `lib/lockspire/storage/ecto/device_authorization_record.ex` | Ecto schema fields for durable polling state | ✓ VERIFIED | Schema and mapping persist `effective_poll_interval_seconds` and `next_poll_allowed_at`. |
| `priv/repo/migrations/20260428130000_extend_lockspire_device_authorizations_polling_state.exs` | Additive schema migration for poll-state durability | ✓ VERIFIED | Adds both columns, backfills existing rows, and indexes `next_poll_allowed_at`. |
| `lib/lockspire/storage/ecto/repository.ex` | Row-locked poll evaluation and single-winner consume | ✓ VERIFIED | Substantive `record_device_poll/3` and `consume_device_authorization/3` implementations use `FOR UPDATE` and update durable state. |
| `test/lockspire/storage/ecto/repository_device_authorization_test.exs` | Executable storage proof for slow_down, pending cadence, expiry, and replay-safe consume | ✓ VERIFIED | Covers early polling, sticky widening, compliant pending polling, terminal classification, approved readiness, approval expiry, and single-winner consume. |
| `lib/lockspire/protocol/token_exchange.ex` | Device grant branch wired into shared token issuance | ✓ VERIFIED | Accepts the device grant, authenticates the client, maps durable poll outcomes, and persists tokens through the shared success pipeline. |
| `test/lockspire/protocol/token_exchange_test.exs` | Protocol proof for RFC mappings, success, replay, refresh, and `id_token` behavior | ✓ VERIFIED | Covers pending, `slow_down`, denied, expired, invalid grant, replay, shared success, refresh policy, and `openid` behavior. |
| `lib/lockspire/web/controllers/token_controller.ex` and `test/lockspire/web/token_controller_test.exs` | Thin HTTP `/token` wiring with device-flow response proof | ✓ VERIFIED | Controller injects the repository-backed stores and tests assert public response semantics plus cache headers. |
| `lib/lockspire/protocol/discovery.ex`, discovery tests, and docs/E2E artifacts | Truthful metadata, docs contract, and repo-backed flow proof | ✓ VERIFIED | Discovery advertises the device grant and endpoint; docs explain the shipped behavior; E2E test proves `/device/code -> /verify -> /token`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/lockspire/storage/device_authorization_store.ex` | `lib/lockspire/storage/ecto/repository.ex` | device-code fetch and poll/consume callbacks | ✓ WIRED | Repository implements `fetch_device_authorization_by_device_code_hash/1`, `record_device_poll/3`, and `consume_device_authorization/3` at `lib/lockspire/storage/ecto/repository.ex:317-357`. |
| `lib/lockspire/storage/ecto/repository.ex` | `lib/lockspire/storage/ecto/device_authorization_record.ex` | `FOR UPDATE` poll evaluation and consume mapping | ✓ WIRED | Locked queries and state transitions run through the Ecto record in `lib/lockspire/storage/ecto/repository.ex:1076-1244`. |
| `lib/lockspire/protocol/token_exchange.ex` | `lib/lockspire/storage/device_authorization_store.ex` | device poll evaluation and consume callbacks | ✓ WIRED | Device exchange calls `record_device_poll/3` at `lib/lockspire/protocol/token_exchange.ex:184-228` and consume during persistence at `:841-919`. |
| `lib/lockspire/web/controllers/token_controller.ex` | `lib/lockspire/protocol/token_exchange.ex` | thin controller wiring for device grant | ✓ WIRED | `/token` delegates all device-grant behavior to `TokenExchange.exchange/1` in `lib/lockspire/web/controllers/token_controller.ex:15-26`. |
| `lib/lockspire/protocol/discovery.ex` | `test/lockspire/web/discovery_controller_test.exs` | truthful HTTP discovery publication | ✓ WIRED | Discovery metadata is asserted over HTTP in `test/lockspire/web/discovery_controller_test.exs:52-57`. |
| `docs/install-and-onboard.md` | `docs/device-flow-host-guide.md` | host onboarding guidance for polling semantics | ✓ WIRED | Onboarding points directly to the device-flow host guide in `docs/install-and-onboard.md:75-82`. |
| `lib/lockspire/web/controllers/device_authorization_controller.ex` | `lib/lockspire/protocol/device_authorization.ex` | runtime verification URI and interval publication | ✓ WIRED | Controller injects `Config.device_verification_uri()` while the protocol emits `interval` from durable device authorization state in `lib/lockspire/web/controllers/device_authorization_controller.ex:18-25` and `lib/lockspire/protocol/device_authorization.ex:47-57`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/lockspire/storage/ecto/repository.ex` | `effective_poll_interval_seconds`, `next_poll_allowed_at` | Locked `lockspire_device_authorizations` row updated in-place during `record_device_poll/3` | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/token_exchange.ex` | presented `device_code` -> durable poll outcome -> consumed authorization -> persisted tokens | `Policy.hash_token/1`, `device_authorization_store.record_device_poll/3`, `device_authorization_store.consume_device_authorization/3`, and `token_store.store_token/1` | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/device_authorization.ex` | `verification_uri`, `verification_uri_complete`, `interval` | `Config.device_verification_uri/0` from controller injection plus persisted device-authorization poll interval | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/discovery.ex` | `grant_types_supported`, `device_authorization_endpoint` | Mounted router paths plus configured issuer | Yes | ✓ FLOWING |
| `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | device code, host approval handle, token response | Real repository-backed `/device/code`, generated host `/verify`, and `/token` requests | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Durable polling semantics and protocol mapping stay green together | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/protocol/token_exchange_test.exs` | `33 tests, 0 failures` | ✓ PASS |
| HTTP `/token`, discovery/docs contract, and generated-host E2E redemption stay green together | `MIX_ENV=test mix test test/lockspire/web/token_controller_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | `31 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `DEV-07` | `32-02`, `32-03` | Implement `POST /token` support for `grant_type=urn:ietf:params:oauth:grant-type:device_code`. | ✓ SATISFIED | `TokenExchange.exchange/1` accepts the grant in `lib/lockspire/protocol/token_exchange.ex:56-79`, the Phoenix adapter wires it in `lib/lockspire/web/controllers/token_controller.ex:15-26`, and protocol/controller/E2E tests exercise the live endpoint. |
| `DEV-08` | `32-02`, `32-03` | Handle `authorization_pending`, `slow_down`, and token issuance on the `/token` endpoint. | ✓ SATISFIED | Public error mapping lives in `lib/lockspire/protocol/token_exchange.ex:230-320`, token success persistence is in `:841-919`, and tests cover pending, `slow_down`, success, denial, expiry, replay, refresh, and `id_token` behavior. |
| `DEV-09` | `32-01` | Enforce polling intervals and prevent database crush via efficient Ecto queries. | ✓ SATISFIED | Poll cadence is durable and row-locked in `lib/lockspire/storage/ecto/repository.ex:339-346,1076-1205`, backed by persistent fields/migration and verified by repository tests. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `.planning/REQUIREMENTS.md` | 30-32 | Traceability table still marks `DEV-07` and `DEV-08` as pending even though Phase 32 implementation and proof are present | ℹ️ Info | Planning ledger is stale, but this does not block the shipped Phase 32 behavior or its verification. |

### Gaps Summary

No implementation gaps remain against the Phase 32 must-haves. The phase goal is achieved in the live codebase: device polling state is durable and row-locked, the shared `/token` endpoint accepts the device grant and emits RFC-shaped pending/backpressure/terminal outcomes, successful approved polls mint tokens exactly once, discovery and docs now advertise the shipped surface truthfully, and the generated-host E2E flow proves `/device/code -> /verify -> /token` end to end.

---

_Verified: 2026-04-28T12:43:06Z_
_Verifier: Claude (gsd-verifier)_
