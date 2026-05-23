# v1.22 DPoP Nonce Support Requirements

## Shared Nonce Primitive (NONCE-CORE)
- **NONCE-CORE-01**: Lockspire MUST issue unpredictable DPoP nonce values for authorization-server and resource-server DPoP validation separately.
- **NONCE-CORE-02**: Lockspire MUST reject DPoP proofs on nonce-enforced surfaces when the proof omits the required `nonce` claim.
- **NONCE-CORE-03**: Lockspire MUST reject DPoP proofs on nonce-enforced surfaces when the supplied `nonce` was not issued by the matching Lockspire surface or is no longer recent.
- **NONCE-CORE-04**: Lockspire MUST keep authorization-server and resource-server nonce values distinct so a nonce issued for one class of surface is not accepted on the other.

## Authorization Server DPoP (NONCE-AS)
- **NONCE-AS-01**: On Lockspire-owned `/token` DPoP exchanges, Lockspire MUST return `400` with OAuth error `use_dpop_nonce` and a `DPoP-Nonce` response header when a DPoP proof is present but lacks a valid authorization-server nonce.
- **NONCE-AS-02**: Lockspire MUST accept the retried `/token` request when the DPoP proof includes the supplied authorization-server nonce and all existing DPoP checks still pass.
- **NONCE-AS-03**: Existing token-endpoint behavior for missing DPoP proofs, replay, `ath`, `jkt`, MTLS binding, and bearer-mode clients MUST remain otherwise unchanged.

## Resource Server DPoP (NONCE-RS)
- **NONCE-RS-01**: On Lockspire-owned protected resources and the shipped host Phoenix plug pipeline, Lockspire MUST return a DPoP-aware `401` challenge with `error="use_dpop_nonce"` and a `DPoP-Nonce` response header when a DPoP proof is present but lacks a valid resource-server nonce.
- **NONCE-RS-02**: Lockspire MUST accept the retried protected-resource request when the DPoP proof includes the supplied resource-server nonce and all existing DPoP checks still pass.
- **NONCE-RS-03**: Existing protected-resource behavior for missing DPoP proofs, `Authorization: DPoP` enforcement, replay, `ath`, token binding, MTLS binding, and `401` vs `403` semantics MUST remain otherwise unchanged.

## Support Truth & Proof (NONCE-TRUTH)
- **NONCE-TRUTH-01**: `docs/supported-surface.md` MUST stop claiming DPoP nonce support is out of scope and instead describe the shipped nonce-backed surface narrowly.
- **NONCE-TRUTH-02**: `docs/protect-phoenix-api-routes.md` and any Lockspire-owned DPoP docs MUST describe the nonce challenge/retry contract truthfully, including the retained narrow support boundary.
- **NONCE-TRUTH-03**: Repo-native tests MUST prove nonce challenge and retry behavior for `/token`, `/userinfo`, and the generated-host protected-route pipeline.
