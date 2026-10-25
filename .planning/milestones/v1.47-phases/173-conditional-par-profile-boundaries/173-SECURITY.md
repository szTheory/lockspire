---
phase: "173"
slug: "conditional-par-profile-boundaries"
status: verified
threats_found: 6
threats_closed: 6
threats_open: 0
asvs_level: 1
created: "2026-10-24"
---

# Phase 173 — Security

ASVS level 1, blocking threshold high. Typed security auditor independently verified five mitigations at HEAD `c6d4d3fac68914a4c3c3014ec68f6973d10b9e3b`. Root persisted the previously authored low-risk acceptance under delegated maintainer authority; independent auditor subsequently read-verified this entry and returned SECURED, 6/6 dispositions closed. No new runtime protection or certification is claimed.

## Trust Boundaries

Untrusted authorize inputs resolve into a stored PAR request before current-policy validation. Bound references cross the locked, expiring one-use store boundary. Validated interaction fields reach the host-owned account/session/consent seam. Mutable current inputs remain distinct from frozen historical qualification evidence.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-173-01 | Tampering | Stored PAR authority | high | mitigate | Resolver at authorization_request.ex:318 retains stored-only map at :909; protocol test :682 proves stored client/redirect/scopes/state/nonce/S256 despite conflicts. Phase15 Router regression proves persisted projection using independent references. | closed |
| T-173-02 | Spoofing / Elevation of privilege | Bound reference lifecycle | high | mitigate | Existing client lookup, prefix validation and consume remain. Ecto store retains transaction, FOR UPDATE, deletion before binding/expiry checks. Wrong-client burn, expiry, replay and required-PAR owners pass. | closed |
| T-173-03 | Elevation of privilege | Current policy and host seam | high | mitigate | Current eligibility/policy, distinct request/request_uri rejection, exact redirect, strict signing and S256 remain. Phase37/172 and consumed-PAR/collision owners pass. Controller validates before host subject resolution. | closed |
| T-173-04 | Repudiation / Tampering | Consent evidence and ledger | medium | mitigate | Reference-only control precedes fresh candidate; exact relative consent and stored fields asserted, hostile absolute URL rejected. Frozen content/history/order/prior audits preserved; only two owned identities changed with attributed old/new records. | closed |
| T-173-05 | Denial of service | Supplemental external-profile execution | low | accept | AR-173-01 documents the exact unlaunched supplemental boundary; no runtime or general concurrency guarantee inferred. | closed — accepted boundary |
| T-173-SC | Tampering | Package inputs | high | mitigate | Diff since 79048ed2 contains no dependency/lock/public API/endpoint/schema/migration changes; no installation needed. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-173-01 | T-173-05 | No external wrapper/profile is launched; absence of a newly qualified automatic interruption/overlap/cleanup guarantee is outside this selected correction. See exact boundary below. | Executing Codex maintainer under explicit autonomous recommendation-following authority; agent judgment, not fabricated human confirmation | 2026-10-24 |

**T-173-05 — Low — Accepted within the unlaunched supplemental external-profile boundary.** Provider-origin, TLS, proxy and browser profiles remain unavailable, unlaunched, supplemental and non-certifying. Phase 173 accepts the absence of a newly qualified automatic interruption, overlapping-run or cleanup guarantee for those external profiles because it launches no wrapper or profile input. This acceptance does not establish runtime protection, a general PAR concurrency/interruption guarantee, external reachability, packaged-host proof or certification. Existing bound, expiring, locked one-use reference semantics remain covered by their finite tests. Broader external-profile work requires its own reviewed execution boundary; Phase 174 retains packaged proof, candidate/CI and delivery ownership. The original fallback assumptions remain unresolved and traceable.

## Verification Evidence

Independent auditor ran the following with the owned toolchain/database and integration included:

```text
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/lockspire/web/authorize_controller_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/web/discovery_controller_test.exs test/integration/phase37_protocol_strictness_e2e_test.exs test/lockspire/qualification_ledger_contract_test.exs
```

Exit 0: 132 tests, 0 failures, 10.6 seconds, seed 354043. Independent frozen-content/history, receipt/probe byte, two owned audit-chain, order and aggregate digest checks passed. RED/GREEN integration bytes match SHA-256 `9a286e37949857ced7bdf5672d01a9d7d89c4f381d579be7aff6e9a5c3c35413`; source hashes and commit order match the summary. Ordered input digest: `ed2ef990dd80b0eab18e3ad69400870cb54c01899464137697a6e9e3b58f371e`. Historical RED was not rerun.

No new unregistered flags were identified in this scoped audit. The original three fallback assumptions and two descriptor-less prohibitions remain traceable; passing finite tests does not establish universal negative or concurrency claims.

## Security Audit Trail

| Audit Date | Threats Total | Mitigations Verified | Accepted Boundaries | Blocking Open | Run By |
|------------|---------------|----------------------|---------------------|---------------|--------|
| 2026-10-24 | 6 | 5 | 1 | 0 | Typed security auditor; root artifact writer |

## Sign-Off

- [x] Five mitigation dispositions independently verified
- [x] Low accepted boundary explicitly persisted without broader runtime claim
- [x] Blocking threats_open: 0
- [x] Independent auditor confirmed accepted-risk entry; status verified
