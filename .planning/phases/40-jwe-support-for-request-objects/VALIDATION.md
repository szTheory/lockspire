# Phase 40: JWE Support for Request Objects - Validation Strategy

## Overview
This document outlines the validation strategy to ensure Nyquist compliance for Phase 40 (JWE Support for Request Objects). The validation strategy maps to the requirements implemented in `40-01-PLAN.md` and `40-02-PLAN.md`, ensuring all functionality is verifiable via automated tests.

## Requirement Verification Mapping

### AUTHZ-01: Encryption Key Management
**Goal:** Ensure the server can securely isolate encryption (`enc`) keys from signing (`sig`) keys, and advertise them in the JWKS.
- **Validation Method:** Automated tests in `test/lockspire/storage/repository_test.exs` and `test/lockspire/protocol/jwks_test.exs`.
- **Nyquist Criteria:**
  - `mix test test/lockspire/storage/repository_test.exs` must pass.
  - Test must verify `fetch_active_signing_key/0` only returns `:sig` keys.
  - Test must verify `list_decryption_keys/0` returns only `:enc` keys.
  - `mix test test/lockspire/protocol/jwks_test.exs` must pass.
  - Test must verify `enc` keys are properly rendered in the JWKS public view.

### AUTHZ-02: JWE Request Object Processing
**Goal:** Ensure the server can correctly digest and decrypt nested JWE strings in request objects.
- **Validation Method:** Automated tests in `test/lockspire/protocol/jar_test.exs` and `test/lockspire/protocol/request_object_test.exs`.
- **Nyquist Criteria:**
  - `mix test test/lockspire/protocol/jar_test.exs` must pass.
  - Test must verify successful decryption of 5-part JWEs.
  - Test must verify fallback handling for 3-part JWS (returned as-is).
  - Test must verify failed decryption results in safe `{:error, :decryption_failed}` responses, verifying the Error Handling pattern.
  - `mix test test/lockspire/protocol/request_object_test.exs` must pass.
  - End-to-end integration test must verify a nested JWE string successfully produces verified claims for `RequestObject.consume`.

## Compliance Verification
All test suites must be fully automated using the Elixir `ExUnit` testing framework (`mix test`) and capable of running in a standard CI environment without external human checkpoints.