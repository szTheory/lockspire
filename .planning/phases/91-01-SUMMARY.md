# Plan 91-01 Summary

- Added `Lockspire.RemoteJwksDiagnostics` as the shared classification seam for remote `jwks_uri` posture.
- Threaded diagnosis recording through `private_key_jwt`, JARM client-key resolution, and mTLS remote-JWKS fetch paths.
- Preserved generic OAuth wire failures while retaining internal posture categories for target safety, transport, HTTP, payload, freshness, and unsupported rollover.
- Added unit coverage for supported refresh recovery and ambiguous same-`kid` rollover.

Verification:

- `mix test test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/jarm_test.exs`

