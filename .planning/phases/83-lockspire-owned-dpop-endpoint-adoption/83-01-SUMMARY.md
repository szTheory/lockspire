---
phase: 83-lockspire-owned-dpop-endpoint-adoption
plan: 01
subsystem: auth
tags: [dpop, oauth, token, refresh, ciba, device-code]
requirements-completed: [NONCE-AS-01, NONCE-AS-02, NONCE-AS-03]
completed: 2026-05-24
---

# 83-01 Summary

- Added protocol retry coverage for authorization-code, device-code, CIBA, and refresh exchanges when `/token` requires an authorization-server nonce.
- Kept all supported `/token` DPoP flows on the shared `TokenEndpointDPoP` seam and proved successful retries preserve DPoP token binding.
- Expanded the `/token` controller proof with a DPoP device-code retry flow instead of duplicating protocol-only negative-path matrices.
