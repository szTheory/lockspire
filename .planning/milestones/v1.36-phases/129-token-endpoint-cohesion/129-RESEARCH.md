# Phase 129 Research: Token Endpoint Cohesion

## Discovery level

Level 0. The phase uses the existing Elixir, Dialyxir, JOSE, ExUnit, and GitHub Actions stack; no dependency or external API choice is required.

## Current evidence

- `Lockspire.Protocol.TokenExchange` is 1,923 lines and its test is 2,269 lines. Its public surface is `exchange/1`, `exchange_authorization_code/1`, `issue_ciba_tokens/4`, `%Success{}`, `%Error{}`, and `result()`.
- Authorization-code, device-code, and CIBA polling, validation, issuance, transaction, audit, and telemetry paths currently live in the facade. `RefreshExchange` and `Rfc8693Exchange` already demonstrate grant-specific modules.
- Access and ID token lifetimes are 3,600 seconds; refresh lifetime is 2,592,000 seconds. These values are duplicated across `TokenExchange`, `RefreshExchange`, `AccessTokenSigner`, `IdToken`, and `Rfc8693Exchange`.
- Six modules independently decode private JWK material: `AccessTokenSigner`, `IdToken`, `Jarm`, `IntrospectionJwt`, `LogoutToken`, and `Jar`. All accept JSON maps and safe Erlang terms, but exception handling and outward error mapping differ.
- Fresh `mix dialyzer --format short` on 2026-08-26 reports 50 warnings: 33 in `TokenExchange`, 13 in `RefreshExchange`, two in `VerifyToken`, one in `Rfc8693Exchange`, and one in `CibaNotificationWorker`. The cascade begins at overly narrow return inference around signer calls. Dialyxir reports that no ignore file is configured.
- Phase 128 established `Lockspire.Storage.Ecto.Repository` as the protocol default and explicit transaction/audit ports. Extraction must retain those dependencies, option precedence, atomic redemption, durable replay audit, telemetry metadata, and CIBA Push behavior.

## Implementation guidance

1. Preserve the facade modules and structs. Move grant coordination behind internal modules; do not create new public API or change controllers/workers.
2. Extract authorization-code first as the tracer, then device and CIBA sequentially because all three edit the facade. Characterization tests must cover success, invalid input, replay, DPoP, audit, telemetry, and rollback.
3. `TokenLifetime` should expose named zero-argument access, ID, and refresh functions returning the existing integer values. It owns policy; callers own timestamp arithmetic.
4. `PrivateJwk.decode/1` should accept only binary JSON maps or maps decoded with `Plug.Crypto.non_executable_binary_to_term/2` using safe mode. It returns `{:ok, map}` or `{:error, :invalid_signing_key}` and rescues/catches malformed term failures without logging key material.
5. Remove Dialyzer roots rather than silencing warnings. Add specs at coordinator/store/signer boundaries, make success/error branches truthful, and delete branches proven unreachable only when characterization tests preserve behavior.
6. Add a dedicated required CI job after the local warning count is zero. Cache PLTs with OTP, Elixir, and `mix.lock` in the key; never add a broad ignore file.

## Source coverage audit

| Source | ID | Feature / constraint | Plans | Status |
|---|---|---|---|---|
| GOAL | — | Understandable grant orchestration behind stable facade and one fail-closed shared security policy | 01-08 | COVERED |
| REQ | RUNTIME-03 | One lifetime policy preserving 3600/3600/2592000 | 01-02 | COVERED |
| REQ | RUNTIME-04 | One fail-closed decoder across all six signing/decryption paths | 03-04 | COVERED |
| REQ | ARCH-04 | Stable facade with authorization-code, device-code, and CIBA coordinators | 01, 05, 06 | COVERED |
| REQ | STATIC-02 | Zero warnings, no blanket ignore, cached required CI | 07-08 | COVERED |
| RESEARCH | — | Preserve wire structs, transactions, audit, telemetry, replay and DPoP behavior | 01, 05-07 | COVERED |
| RESEARCH | — | Retain JSON and safe-term key compatibility while failing closed | 03-04 | COVERED |
| CONTEXT | — | No phase CONTEXT.md exists; approved milestone decisions are represented by the four requirements and roadmap criteria | 01-08 | COVERED |

