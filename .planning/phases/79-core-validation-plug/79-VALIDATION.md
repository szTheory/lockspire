# Phase 79: Core Validation Plug - Validation Plan

## Phase Goal
Establish the `Lockspire.Plug.VerifyToken` Plug with basic JWT validation.

## Requirements Validated
- REQ-79-1: The system MUST provide a plug to extract and validate Bearer tokens from the Authorization header without halting the connection immediately.
- REQ-79-2: The system MUST cache signing keys in ETS to avoid DB lookups during token validation.
- REQ-79-3: The system MUST provide a plug to strictly enforce token presence and halt unauthorized requests with RFC 6750 headers.

## Validation Steps
1. Verify `Lockspire.AccessToken` struct is defined and successfully encapsulates token data.
2. Verify `Lockspire.KeyCache` GenServer correctly synchronizes signing keys from the DB into an ETS cache on boot.
3. Verify `Lockspire.Plug.VerifyToken` evaluates JWTs for valid signatures and time constraints, assigning an `AccessToken` to the connection.
4. Verify `Lockspire.Plug.RequireToken` successfully enforces authorization by checking the `AccessToken` and halting with a 401 when missing or invalid.

## Automated Tests
- `mix test test/lockspire/access_token_test.exs`
- `mix test test/lockspire/key_cache_test.exs`
- `mix test test/lockspire/plug/verify_token_test.exs`
- `mix test test/lockspire/plug/require_token_test.exs`
