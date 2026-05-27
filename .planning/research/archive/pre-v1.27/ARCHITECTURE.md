# v1.24 Research: Architecture

## Existing Integration Points

- `lib/lockspire/protocol/client_auth.ex`
  - currently parses JWT client assertions as `:private_key_jwt`
  - owns method resolution and shared enforcement across direct-client surfaces
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex`
  - already encapsulates JWT assertion verification, replay recording, and security-profile-aware algorithm rules
- `lib/lockspire/protocol/discovery.ex`
  - currently publishes signing-alg metadata only when `private_key_jwt` is present on the endpoint auth-method list
- `lib/lockspire/protocol/registration.ex` and `lib/lockspire/clients.ex`
  - currently allow `private_key_jwt` but not `client_secret_jwt` in the repo-owned registration and operator paths
- admin client and DCR policy LiveViews under `lib/lockspire/web/live/admin`
  - currently present `private_key_jwt` truth but not a symmetric-JWT slice

## Suggested Build Order

1. Narrow the supported runtime contract for `client_secret_jwt` on the shared direct-client surfaces.
2. Add a symmetric JWT verifier that reuses the existing used-`jti` and security-posture decisions.
3. Teach the shared auth parser and method resolver to distinguish `client_secret_jwt` from `private_key_jwt`.
4. Extend operator registration, DCR, and discovery/admin truth to publish only what runtime actually supports.
5. Add repo-native proof across runtime, metadata, docs, and support-truth edges.

## Boundary Decisions

- `core`: shared verifier, runtime method resolution, client metadata validation, discovery truth, tests.
- `core`: operator and DCR registration truth because they define the shipped protocol surface.
- `docs-only`: host/operator guidance and supported-surface wording.
- `defer`: any generic JWT client-auth expansion, secret escrow, or new package boundary.

## Proof Posture

- Merge-blocking proof should be ExUnit coverage for successful and rejected `client_secret_jwt` assertions across representative shared direct-client surfaces.
- Merge-blocking proof should also cover registration/DCR acceptance and discovery/admin truth for the new auth method.
- Advisory proof can stay repo-local; no external certification or suite lane is required for this milestone.

## Support Truth

- Missing or invalid assertions fail closed as `invalid_client`.
- `client_secret_jwt` remains limited to confidential clients with an existing Lockspire-managed client secret.
- FAPI and higher-trust support posture must remain explicit: this milestone adds a narrow auth-method slice, not a stronger-trust claim.
- Hosts still own perimeter rate limiting and deployment policy around the mounted Lockspire endpoints.
