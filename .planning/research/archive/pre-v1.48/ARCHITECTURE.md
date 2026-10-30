# Architecture: v1.47 Core Hardening

**Researched:** 2026-10-24. Preserve existing protocol/storage/host boundaries.

Trace selected HTTP requests through controllers, authorization request/flow, PAR storage and security-profile enforcement to response serialization. Qualify expected behavior and create a deterministic regression at the lowest boundary that proves the issue, then exercise the repaired result through the embedded packaged host. Database and browser/transport assertions require those actual boundaries; source/compile proof cannot substitute.

Own one finite finding ledger linking standards, exact identities, expected outcomes, repro commands, test owners and dispositions. Harness fixes remain in conformance/disposable-host tooling; protocol changes remain in current protocol seams. Never weaken issuer/TLS/redirect validation to make an external runner pass.

Build order: accepted repository baseline → exact-input/owner qualification → authorization slice → conditional PAR/profile slice → package evidence/security/required gates and handoff. Phase 171 freezes cases before dependent implementation plans; replan when qualification removes a slice. Separate SEC-01 persistence migration and future KMS work. See [scope](v1.47-core-hardening/SCOPE.md), [interoperability](v1.47-core-hardening/INTEROPERABILITY.md), [delivery](v1.47-core-hardening/DELIVERY.md).
