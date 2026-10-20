# Feature Research

**Milestone:** v1.45 DCR Lifetime Enforcement
**Researched:** 2026-10-20
**Confidence:** HIGH for cited standards; product choices explicitly unresolved.

## Feature Landscape

| Table stakes | User outcome | Complexity |
|---|---|---|
| Explicit duration rules | Host understands unset, zero and positive settings | Medium |
| Honest secret metadata | Advertised expiry matches actual acceptance | High |
| App eligibility | Registration expiry has documented effects across supported paths | High |
| Management lifecycle | Client can manage registration or use documented recovery | High |
| Atomic rotation | New credential and expiry become effective together | High |
| Upgrade contract | Existing apps do not silently inherit guessed deadlines | High |
| Custom store compatibility | Host knows required storage changes before deployment | High |
| Executable proof | Boundaries and host journeys are reproducible | High |

## Standards Findings

[RFC 7591 section 3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1) requires secret-expiry metadata when a secret is issued; its wire zero means the secret does not expire. It does not determine the meaning of a zero-second server policy setting.

[RFC 7592 section 5](https://www.rfc-editor.org/rfc/rfc7592.html#section-5) advises keeping management tokens valid while the client remains registered to avoid losing management access; read/update rotation is permitted. This is an Experimental specification, not a universal management timeout mandate. A bounded timeout needs a deliberate policy and recovery rationale.

[RFC 7592 section 2](https://www.rfc-editor.org/rfc/rfc7592.html#section-2) distinguishes invalid management credentials, forbidden operations and deprovisioning. An expired registration is not automatically the same operation as explicit deletion; Phase 162 must define the relationship.

## Feature Dependencies

Semantic and compatibility contract → schema/storage support → issuance and enforcement → rotation/recovery → complete host proof and truthful documentation. Each implementation slice must carry its own tests; final proof adds cross-slice coverage.

## Anti-Features and Deferred Work

No universal timeout invented from field names; no automatic destructive backfill from ambiguous old metadata; no unrelated grants or admin redesign. KMS/Vault, federation, dedicated secret-JWT verifier encryption key and broad dependency upgrades remain deferred. Package publication follows implementation and is separate from this milestone setup.

## Decisions Needed

Choose defaults, existing-versus-future policy application, lifetime renewal on rotation, management recovery, disabled-versus-expired semantics, and the effect of app expiry on already-issued tokens. Recommendations are inputs, not selected product behavior.
