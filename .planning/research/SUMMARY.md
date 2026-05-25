# v1.24 Research Summary

## Milestone

`v1.24 client_secret_jwt`

## Stack Additions

- No new dependency is needed.
- Extend the existing shared direct-client auth runtime with a narrow symmetric JWT verifier.
- Reuse current hashed client-secret storage, replay tracking, registration, discovery, and admin truth paths.

## Feature Table Stakes

- Accept `client_secret_jwt` on Lockspire-owned direct-client endpoints for confidential clients.
- Require strict JWT assertion claims, replay protection, and explicit signing-alg metadata.
- Support truthful registration, discovery, and admin/operator surfaces for the new auth method.

## Why This Milestone Fits

- It closes the remaining practical direct-client auth gap without changing Lockspire's embedded-library shape.
- The repo already has a strong shared verifier pattern through `private_key_jwt`, so the new slice compounds existing architecture instead of inventing a second auth plane.
- The main work is truth and security discipline, not broad new protocol territory.

## Watch Out For

- Do not route all JWT assertions through the existing `private_key_jwt` verifier.
- Do not weaken secret-at-rest posture or reveal raw assertions in logs/admin surfaces.
- Do not broaden FAPI or higher-trust claims just because another JWT auth method exists.
- Do not publish `client_secret_jwt` metadata unless every advertised endpoint actually supports it.

## Recommended Scope

This milestone should stay narrow and core-first:

1. Shared `client_secret_jwt` runtime verification on Lockspire-owned direct-client surfaces.
2. Registration, DCR, discovery, and admin truth for the new auth method and its signing algorithms.
3. Repo-native proof for positive and negative auth behavior, metadata truth, and support-truth docs.
4. Documentation that clearly distinguishes this symmetric JWT slice from the already-shipped `private_key_jwt` and mTLS postures.
