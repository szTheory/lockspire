# Phase 76 Plan 04: MTLS Controller Integration

**Objective:**
Wire the MTLS validation pipeline into the core Client Authentication dispatcher and update Plug controllers to supply the out-of-band certificate.

**Changes made:**
- **Task 1**: Updated `Lockspire.Protocol.ClientAuth` dispatch logic to handle MTLS methods. Added `tls_client_auth` and `self_signed_tls_client_auth` methods and delegated them to `Lockspire.Protocol.ClientAuth.MTLS.verify/4`. (Completed by gsd-executor)
- **Task 2**: Updated `TokenController`, `IntrospectionController`, and `RevocationController` to extract the `conn.private[:lockspire_mtls_cert]` and inject it as `opts[:mtls_cert]` for protocol resolution.
- Updated discovery tests in `discovery_controller_test.exs` and `discovery_test.exs` to expect the two new MTLS methods in `token_endpoint_auth_methods_supported`.

**Validation:**
- `mix test --stale` passes locally.

**Commits:**
- `test(76-04): add failing test for MTLS auth dispatch` (from gsd-executor)
- `feat(76-04): update client auth to route MTLS methods` (from gsd-executor)
- `feat(76-04): pass MTLS cert from connection context to protocol endpoints`
