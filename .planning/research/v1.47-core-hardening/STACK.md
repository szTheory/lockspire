# Stack: v1.47 Core Hardening

**Researched:** 2026-10-24. No new dependency or version upgrade selected.
Reuse the current Elixir/OTP, Phoenix/LiveView, Ecto/PostgreSQL, Plug/JOSE and protocol/storage boundaries. Reuse the existing conformance wrappers and immutable OIDF lock, disposable embedded host and packaged HTTP proof. External suite containers remain supplemental tooling, not a new deployment requirement.

Preserve existing suite/plan/image/helper identities for first reproduction. Any unavailable/obsolete input is an explicit input-maintenance decision with separately reviewed pins and comparison identities, not an opportunistic upgrade alongside a protocol fix.

Prefer small local standard-library glue to another dependency when it is simpler and auditable. Retain maintained vetted crypto primitives; no copied crypto, parser or TLS/security implementation. A new package requires a demonstrated capability gap, alternatives, transitive/security cost and ownership. See [interoperability research](INTEROPERABILITY.md) and [security research](SECURITY-AND-SEQUENCING.md).
