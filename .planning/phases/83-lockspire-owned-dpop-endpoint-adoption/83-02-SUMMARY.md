---
phase: 83-lockspire-owned-dpop-endpoint-adoption
plan: 02
subsystem: auth
tags: [dpop, oauth, oidc, userinfo]
requirements-completed: [NONCE-RS-01, NONCE-RS-02, NONCE-RS-03]
completed: 2026-05-24
---

# 83-02 Summary

- Added protocol proof that `/userinfo` succeeds after retrying with the issued resource-server nonce while preserving token-key binding.
- Tightened the `/userinfo` controller contract to assert `WWW-Authenticate`, `DPoP-Nonce`, exposed headers, and a successful second request.
- Reused the existing protected-resource seam instead of introducing any new gateway or host-plug abstraction.
