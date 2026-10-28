Reviewer: Codex security auditor /root/review_178_security  
Date: 2026-10-28  
Disposition: rejected  
Scope: unlaunched collector v3; C50 source acceptance is unchanged.

**SEC-178-COLLECTOR-VOCABULARY-03 — medium, correction required.** Collector v3 omits `stderr_classification` from its typed string fields (`:66–68,84–133`). Driver v51 necessarily emits this field during initdb (`:1084`) and PostgreSQL readiness (`:1164`). Those normal strings become null with an invalid-line count, preventing collector acceptance. Add the exact classification field with finite permitted values and cover the successful startup event vocabulary in an inert fixture.

The prior two collector findings are corrected:

- Paths, hashes and UUIDs are restricted to typed fields and permitted forms; the known-key private-text cases no longer survive projection.
- Event membership and native result checks validate structures before dereferencing. Malformed runs and oversized objects produce failed facts. Original identity tokens are validated before assignment or persistence.

The reviewed handle ownership, continued native cleanup after observer-write failure, atomic final persistence and readback remain intact. V51’s approved path-only delta is unchanged.

Reviewed collector SHA256: `6548ea7a2dde7e1976a90213806f2dfd323c3f4d6486d986f78a5ef3db2cd0e5`.

No tests, producers, probes or edits were performed. V1/v2 remain preserved and unlaunched; run 71794’s final PG/root status remains unqualified.
