# SEC-01 capability scope

Researched 2026-10-25. Recommendation for requirements confirmation, not shipped behavior. [Baseline](BASELINE.md), [architecture](ARCHITECTURE.md), [pitfalls](PITFALLS.md).

| Category | Required outcome | Why and acceptance boundary |
|---|---|---|
| Key custody | Host supplies independent verifier keys; explicit current/write and readable IDs; no implicit endpoint/signing-key fallback after dedicated mode is selected. | Decouples endpoint/session-secret rotation from verifier decryption. Missing/malformed/unknown keys produce redacted failure, never weaker auth. |
| Authenticated storage | New verifier envelopes bind version/header, cryptographic purpose and canonical client identity; same-client round trip succeeds and cross-client/purpose substitution fails. | Reuse vetted OTP primitives; keep current signing-key envelope stable. Text-compatible storage is mandatory. |
| Existing callers | Registration, DCR and operator rotation produce coherent hash/encrypted-verifier pairs; protocol methods and current lifetime fields retain their meanings. | Existing code creates verifier material for basic/post as well as JWT clients. Audit all writers, not just current JWT-method rows. |
| Runtime compatibility | The supported token, introspection, revocation, device-authorization and CIBA caller paths use the canonical reader. | Preserve HS256, issuer audience, required JTI/replay and existing PAR/FAPI exclusion; no new endpoint or auth algorithm. |
| Upgrade | Existing usable Plug.Crypto rows stay readable during explicit compatibility; legacy rejection is a deliberate final stage. | Qualify old ciphertext age independently from application/secret expiry; no silent age bypass or newly invented expiry policy. |
| Rolling deployment | Reader support and all read keys deploy to every node before changing write format/current key; rollback limits are stated and tested. | Old releases cannot read the new format. Configuration parity is an operator duty, not a database-derived guarantee. |
| Maintenance | Preview/apply/check safely rewrap existing rows; re-run is idempotent; status reports unknown/malformed/unreadable/pending rows without hiding partial failures. | Rewrap changes encryption only. It must not rotate secrets, hashes, timestamps, expiry, authorization state or management tokens. |
| Recovery | Key retirement requires complete relevant-row inventory; key loss identifies affected clients and uses the existing authorized secret-rotation/reprovision path. | Ciphertext cannot be recovered without a usable decryption key; no fallback, deletion or fabricated restoration. |
| Proof and delivery | Negative crypto cases, actual PostgreSQL contention/rollback and package-installed fresh/upgrade journeys; redacted receipts, review and normal train delivery. | A crypto unit round trip cannot prove rollout, custom storage, operator tasks or public integration. |

No optional differentiator is needed to make this wedge useful. Do not expand into admin redesign, Storybook, generic secrets custody, KMS/Vault, signing-key paging, token concurrency improvements or full conformance suites. UI quality remains next with its confirmed interview intact; no UI phase IDs/version reserved.

## Standards versus local policy

[OIDC Core §9](https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication) describes HMAC-based client assertions. [RFC 7523](https://www.rfc-editor.org/rfc/rfc7523.html) governs assertion processing; neither prescribes Lockspire's storage key configuration or rolling deployment. Independent at-rest custody, client-bound envelopes, the compatibility window and operator tooling are local product decisions. Preserve the narrower supported-surface contract rather than broadening it to every standard option.

Existing evidence is reused where it proves the selected behavior. No fictional failing client, adopter incident or exploit is claimed. The concrete motivation is the observed endpoint-key coupling and missing independent rotation seam.
