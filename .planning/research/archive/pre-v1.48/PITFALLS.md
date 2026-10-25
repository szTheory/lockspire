# Pitfalls: v1.47 Core Hardening

**Researched:** 2026-10-24.

- Converting a historical suite_failure summary into a current protocol bug. Require exact current reproduction and normative/support attribution.
- Treating any 302 as correct or redirecting errors to an unvalidated callback. Assert exact location, state, error, mode and host-login isolation.
- Fixing TLS/proxy/issuer/WebRunner setup in OAuth code, or relaxing validation for a suite.
- Changing suite inputs and provider behavior in one comparison; preserve identities and isolate reviewed lock updates.
- Treating overall supplemental success as certification or supplemental failure as a new required release gate.
- Manufacturing code/tests for already-covered behavior; reuse owners and replan empty conditional slices.
- Broadening into every grant, token concurrency, verifier-key migration and KMS in one milestone.
- Planning completion mistaken for integration into green main. Re-observe exact main and required checks; preserve unknown edits/unique commits during cleanup.
- Recursively researching every role or adding parallel agents after the consequential decisions have converged. Stop when further review cannot alter scope, controls, acceptance or ordering.
- Avoiding a dependency by copying cryptography/security parsers. Small local glue is a preference, not permission to replace vetted primitives.

See [interoperability](v1.47-core-hardening/INTEROPERABILITY.md), [security/sequencing](v1.47-core-hardening/SECURITY-AND-SEQUENCING.md), [delivery](v1.47-core-hardening/DELIVERY.md) and [baseline](v1.47-core-hardening/BASELINE.md).
