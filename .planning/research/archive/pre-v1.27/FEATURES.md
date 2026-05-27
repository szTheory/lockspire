# v1.24 Research: Features

## Table Stakes

- Confidential clients can authenticate with `client_secret_jwt` on the shared Lockspire-owned direct-client endpoints.
- Assertions require `iss` and `sub` equal to the client identifier, issuer-bound `aud`, bounded lifetime claims, and replay-resistant `jti`.
- Registration and management flows can persist and read back `token_endpoint_auth_method=client_secret_jwt` and the required assertion-signing algorithm.
- Discovery publishes truthful auth-method and signing-alg metadata only for endpoints that actually consume the shared verifier.

## Differentiators

- Reuse the existing shared direct-client auth runtime so all supported endpoints fail the same way and produce one support story.
- Keep the audience rule aligned with Lockspire's current issuer-string posture rather than opening endpoint-specific audience ambiguity.
- Preserve hashed-at-rest secret handling and avoid any feature that would require storing recoverable secrets or broadening operator trust.
- Keep docs explicit that `client_secret_jwt` is a convenience slice for direct clients, not a new higher-trust or broader certification claim.

## Anti-Features

- Do not add generic symmetric JWT support outside Lockspire-owned direct-client endpoints.
- Do not widen discovery or docs into a claim that all endpoint auth methods are equally strong under FAPI.
- Do not add secret-derivation fallbacks, unsigned assertions, or relaxed replay rules to improve compatibility.
- Do not expand this milestone into advanced setup support-burden work unless it is directly required for truthful `client_secret_jwt` operation.

## Complexity Notes

- The main implementation risk is not JOSE mechanics; it is preserving Lockspire's existing secret-handling model while still verifying signed assertions correctly.
- Registration truth and discovery truth must move together so clients do not see advertised metadata that runtime cannot honor.
- The current codebase already assumes JWT auth metadata is driven by `private_key_jwt`; `client_secret_jwt` will require that logic to become method-aware.
