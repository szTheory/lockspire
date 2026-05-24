# Phase 76: MTLS Client Authentication - Validation

## Goal-Backward Verification
This phase is complete when the application can successfully parse MTLS certificates provided via the load balancer (`conn.private[:lockspire_mtls_cert]`) and authenticate clients using both `tls_client_auth` and `self_signed_tls_client_auth` methods as per RFC 8705.

## Test Matrix

| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| REQ-01 | Evaluate `tls_client_auth` | unit | `mix test test/lockspire/protocol/client_auth/mtls_test.exs` |
| REQ-02 | Evaluate `self_signed_tls_client_auth` | unit | `mix test test/lockspire/protocol/client_auth/mtls_test.exs` |
| REQ-03 | Extract certificate correctly | unit | `mix test test/lockspire/mtls/certificate_test.exs` |

## Acceptance Criteria
- [ ] Erlang X.509 certificates are decoded successfully into Elixir structs.
- [ ] Ecto schema for Client supports the 5 PKI SAN fields.
- [ ] `tls_client_auth` correctly matches the provided cert's SAN or Subject DN against the registered client attributes.
- [ ] `self_signed_tls_client_auth` correctly extracts the cert's public key, converts it to a JWK, and finds a matching key in the client's JWKS.
- [ ] Fallback mechanism is cleanly implemented, meaning no mixed auth (cert + secret) is allowed if MTLS is configured.
