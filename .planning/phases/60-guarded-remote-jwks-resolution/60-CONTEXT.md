# Phase 60: Guarded Remote JWKS Resolution - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn `Lockspire.JwksFetcher` into a narrow, testable security boundary for `jwks_uri`-backed client authentication. This phase is about guarded retrieval, target safety, bounded caching, and rotation-friendly refresh semantics for remote client keys. It is not a generic remote-ingestion subsystem, not a background sync service, and not the phase that wires full `private_key_jwt` signature verification into `ClientAuth`.

</domain>

<decisions>
## Implementation Decisions

### Planning posture
- **D-01:** Downstream Phase 60 work should default to strong, concrete recommendations. Escalate only if a decision would materially change Lockspire's embedded-library boundary, outbound network posture, or public API shape.
- **D-02:** The phase should optimize for a narrow, fail-closed fetch path that later `ClientAuth` verification can trust. Convenience behavior is secondary to explicit security boundaries.

### Remote fetch scope
- **D-03:** Harden the existing `Lockspire.JwksFetcher` seam rather than designing a broader outbound framework. The milestone needs one purpose-built remote-key path for `jwks_uri`, not reusable remote metadata plumbing.
- **D-04:** Keep the fetch path synchronous and intentionally strict on the auth path: `https` only, redirects disabled, retries disabled, and low connection/read timeout budgets.
- **D-05:** Normalize failure reasons into a stable internal contract that later phases can map to `invalid_client` outcomes without leaking transport internals into protocol handlers.

### Target safety and body boundaries
- **D-06:** Unsafe targets must be rejected before an outbound request is made. The safety rule is based on resolved destination addresses, not on string heuristics alone.
- **D-07:** Reject loopback, link-local, RFC1918 private ranges, and other clearly non-public destinations by default. Testability matters, so any resolver or socket inspection logic should be injectable in unit tests.
- **D-08:** Response size must be bounded as part of the fetcher contract. The phase should prefer one explicit payload cap and closed failure behavior over best-effort parsing of arbitrarily large bodies.

### Cache and rotation behavior
- **D-09:** Preserve the current in-process cache shape for v1.15 rather than refactoring cache infrastructure. The work should harden the current implementation first, not re-litigate the storage substrate.
- **D-10:** Successful remote JWKS fetches should retain an explicit TTL, and the fetcher should expose one bounded forced-refresh path so later signature verification can recover from ordinary key rotation.
- **D-11:** Forced refresh should replace stale cache state only on successful refresh. A failed refresh must not silently widen trust or erase the last known-good entry without an explicit reasoned choice in code.
- **D-12:** Do not add background polling, prefetch jobs, or operator-triggered preview workflows in this phase.

### Product boundary
- **D-13:** Keep all remote key resolution Lockspire-owned. The host app should not need to re-implement SSRF checks, timeout policy, or cache behavior for `jwks_uri`.
- **D-14:** Do not pull full JWT signature verification, audience binding, or replay-ordering logic into this phase. Those belong to Phase 61 and should consume the hardened fetcher contract built here.

### the agent's Discretion
- Exact helper/module names for target safety and cache-refresh behavior.
- Whether the forced refresh API is a separate function or an opt-in parameter on the existing fetch call, as long as the contract remains narrow and testable.
- Exact body-cap value and timeout defaults, provided they remain intentionally low and are justified in code/tests.

</decisions>

<specifics>
## Specific Ideas

- The likely implementation center is still `lib/lockspire/jwks_fetcher.ex`, with one small helper module for network-target safety if that keeps the main fetcher readable.
- `Lockspire.Protocol.ClientAuth` should remain untouched in this phase unless a tiny seam is needed to prepare for the later forced-refresh integration point.
- Existing `Req.Test` coverage should remain the primary fast feedback path, with new tests proving redirect refusal, oversize-body rejection, unsafe-address rejection, and refresh-on-rotation behavior.
- The older `45-S02` strategy favored a cache redesign; Phase 60 should not reopen that architectural debate unless the current `Cachex` seam makes the security contract impossible to express.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Lockspire planning artifacts
- `.planning/ROADMAP.md` — Phase 60 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — `JWKS-01`, `JWKS-02`, `JWKS-03`.
- `.planning/PROJECT.md` — embedded-library boundary and host seam.
- `.planning/STATE.md` — current milestone position and next action.
- `.planning/research/SUMMARY.md` — milestone-wide findings for `jwks_uri` and `private_key_jwt`.
- `.planning/phases/59-registration-policy-metadata-truth/59-RESEARCH.md` — prior phase truth decisions that Phase 60 must not contradict.
- `.planning/phases/45-s02-dynamic-jwks-fetching/45-S02-STRATEGY.md` — older cache/fetch strategy note; useful background but not the binding plan.

### Lockspire codebase and tests
- `lib/lockspire/jwks_fetcher.ex` — current remote JWKS seam to harden.
- `lib/lockspire/application.ex` — current cache child-spec wiring.
- `lib/lockspire/protocol/client_auth.ex` — downstream consumer that will later need the hardened fetcher contract.
- `test/lockspire/jwks_fetcher_test.exs` — current fetcher coverage to expand.
- `test/lockspire/protocol/client_auth_test.exs` — current proof that `private_key_jwt` verification is still payload-based and not yet cryptographic.

</canonical_refs>

<deferred>
## Deferred Ideas

- Full `private_key_jwt` signature and claim verification.
- Background JWKS refresh or prefetch scheduling.
- Cache substrate replacement solely for elegance.
- Generic outbound-fetch tooling for unrelated remote metadata.
- Operator-facing remote JWKS preview or diagnostics UI.

</deferred>

---

*Phase: 60-guarded-remote-jwks-resolution*
*Context gathered: 2026-05-06*
