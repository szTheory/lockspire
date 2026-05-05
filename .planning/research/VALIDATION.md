# Phase 51: Core Protocol & Poll Mode (CIBA) - Validation Strategy

## Overview

The verification strategy for Phase 51 focuses on ensuring strict compliance with the OpenID Connect CIBA Core 1.0 specification, specifically the Backchannel Authentication endpoint (`/bc-authorize`) and the Token endpoint polling behavior.

## Verification Tiers

### 1. Integration Tests (E2E)
We use end-to-end integration tests to verify the full CIBA flow from initial request to token issuance.

- **File:** `test/integration/phase51_ciba_poll_mode_e2e_test.exs`
- **Scope:** 
    - Successful client authentication and `auth_req_id` issuance.
    - Enforcement of "exactly one" hint rule (`login_hint`, `id_token_hint`, or `login_hint_token`).
    - Polling the `/token` endpoint with `grant_type=urn:openid:params:grant-type:ciba`.
    - Verification of `authorization_pending`, `slow_down`, and `access_denied` error codes.
    - Final exchange of `auth_req_id` for Access Token, ID Token, and Refresh Token.

### 2. Protocol & Domain Unit Tests
Unit tests target specific logic within the protocol and storage layers.

- **Files:**
    - `test/lockspire/protocol/backchannel_authentication_test.exs` (Request validation)
    - `test/lockspire/protocol/token_exchange_test.exs` (CIBA grant handling)
    - `test/lockspire/storage/ciba_authorization_store_test.exs` (State persistence)
- **Scope:**
    - Hint validation logic (ensuring zero or multiple hints are rejected).
    - Polling interval calculation and enforcement logic.
    - Secret hashing verification for `auth_req_id`.

## Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| CIBA-01 | `/bc-authorize` endpoint returns `auth_req_id` and enforces exact hint rules | integration | `mix test test/integration/phase51_ciba_poll_mode_e2e_test.exs` |
| CIBA-02 | `/token` validates `grant_type=urn:openid:params:grant-type:ciba` and retrieves authorization | integration | `mix test test/integration/phase51_ciba_poll_mode_e2e_test.exs` |
| CIBA-03 | `slow_down` returned if polling occurs before `next_poll_allowed_at` | integration/unit | `mix test test/integration/phase51_ciba_poll_mode_e2e_test.exs` |

## Execution Protocol

1. **Local Development:** Run `mix test <specific_file>` after each task.
2. **Phase Completion:** Run the full integration test suite: `mix test test/integration/phase51_ciba_poll_mode_e2e_test.exs`.
3. **Regression:** Run the full project test suite: `mix test`.
