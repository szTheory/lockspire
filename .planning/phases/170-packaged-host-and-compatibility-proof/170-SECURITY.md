---
phase: "170"
slug: packaged-host-and-compatibility-proof
status: verified
threats_open: 0
threats_total: 19
threats_closed: 19
asvs_level: 1
block_on: high
created: "2026-10-24"
audited_head: 14e9fa173e21a20d764f3730f221d51f9db3d9eb
runtime_evidence_source: ef9ef86030467792346d1b674c58b44d8db30d38
---

# Phase 170 — Security

Independent security-auditor verification of the 19 unique planned threats.
Repeated T-170-SC rows share one dependency/toolchain threat. All dispositions
are mitigate; no risk was accepted or transferred.

## Trust boundaries

| Boundary | Control |
|---|---|
| Package to child filesystem/runtime | Immutable archive/tree inventory, resolved dependency and compiled binding |
| Host authority to HTTP/LiveView | Current host-owned policy at tested entry/navigation/reconnect boundaries |
| Browser/process observations to retained evidence | Strict allowlisted fields, types, identities and safe diagnostics |
| Child resources to timeout/cleanup owner | Finite owned subprocesses, signals, independent cleanup and unique DB disposal |
| Local evidence to compatibility/CI claims | Exact runtime observations, required job contracts and explicit remote limits |

## Threat register

| Threat ID | Category | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|
| T-170-01 | Tampering | high | mitigate | package_input.py archive/tree/resolver/compiled binding; build_provider.py pre-load and final checks | closed |
| T-170-02 | Spoofing / elevation | high | mitigate | Opt-in proof host, capability/loopback controls, current authority, generated unconditional denial | closed |
| T-170-03 | Information disclosure | high | mitigate | Nested diagnostic field allowlists and unknown-field counts; hostile-key reproduction and regression | closed |
| T-170-04 | Denial of service / tampering | medium | mitigate | Bounded owned preparation children; runner and Chrome signal cleanup; real subprocess regressions | closed |
| T-170-05 | Elevation / spoofing | high | mitigate | Actual cached-join, invalidated-session reconnect and deleted-identity params cases; current lookup | closed |
| T-170-06 | Elevation | high | mitigate | Separate public/consent sessions; real crossing plus fresh denied admin entry | closed |
| T-170-07 | Denial of service | high | mitigate | Anonymous discovery/JWKS and protocol token error with zero staff decisions in all six receipts | closed |
| T-170-08 | Information disclosure | high | mitigate | Known enums/field names only; nested hostile-key/value and malformed-enum regressions | closed |
| T-170-09 | Spoofing / repudiation | high | mitigate | Exact runtime assertions; same four original shared test files; positive test counts | closed |
| T-170-10 | Tampering | high | mitigate | Pair/lock/environment caches, reuse refusal and runtime/asset source containment | closed |
| T-170-11 | Elevation / tampering | high | mitigate | Package support exclusion and proof-overlay boundary audit before compilation | closed |
| T-170-12 | Repudiation / tampering | high | mitigate | Required existing jobs; preserved child/signal status; subprocess failure regressions | closed |
| T-170-13 | Spoofing / tampering | high | mitigate | Independent expected identities; exact cases/runtime/types; stale staging removal | closed |
| T-170-14 | Information disclosure | high | mitigate | Independent guarded cleanup reaches root removal after drop errors/timeouts; validation before staging | closed |
| T-170-15 | Denial of service | medium | mitigate | 900s workload bound; bounded termination and EXIT cleanup of only the generated lifecycle DB | closed |
| T-170-16 | Repudiation / spoofing | high | mitigate | Refreshed source/package/pair/mount-bound acceptance ledger; independently validated six receipts | closed |
| T-170-17 | Elevation | high | mitigate | Generated authorization stays denied; synthetic policy is disposable host-owned; no production identity system | closed |
| T-170-18 | Information disclosure | high | mitigate | Strict receipt schema, bounded summaries and mode-0600 safe artifacts | closed |
| T-170-SC | Tampering | high | mitigate | Unchanged root/provider locks, fixture-only frozen dependencies, immutable workflow pins, no installer/dependency addition | closed |

## Accepted risks log

No accepted risks.

## Audit trail

| Audit | Head | Closed | Blocking open | Below-threshold open | Result |
|---|---|---|---|---|---|
| Initial independent L1 audit | 04137365578662af6680adab5f50ac9ca4880aa0 | 14 | 3 | 2 | Nested diagnostic keys leaked; drop exceptions skipped raw-root cleanup; interruption and lifecycle DB cleanup incomplete |
| Independent re-audit | 14e9fa173e21a20d764f3730f221d51f9db3d9eb | 19 | 0 | 0 | Prior fault reproductions closed after ef9ef860, debd3d28 and 8f775485; refreshed evidence recorded by 14e9fa17 |

Fresh auditor checks: Node 8/8, 18 selected Python checks, hostile nested
diagnostics, actual-main drop timeout/error probes, and an owned child ignoring
SIGTERM terminated by its deadline. Six browser receipts and both lifecycle
identities/versions were independently revalidated. Recorded full remediation
checks are Python 35, CI/docs 14 and serialized broad suite 2,027 passed.

See 170-REMEDIATION.md for fixes, reproduction methods and exact commands;
170-ACCEPTANCE.md records the refreshed pair/mount evidence and timing boundary.

## Limits and sign-off

ASVS L1 verification of the declared register, not certification. Local runtime
evidence is 43/44 lifecycle tests plus three mounts x 16 browser cases per pair.
Authorization is established at tested boundaries; continuous socket revocation
is not claimed. No hosted CI run or execution on CI's expected BEAM versions
was observed. Runtime implementation is unchanged since receipt source ef9ef860.

- [x] Every registered threat has a disposition and implementation evidence.
- [x] Initial audit gaps have explicit repairs and independent re-verification.
- [x] No accepted risks or blocking threats remain.
- [x] Status verified; threats_open is zero.
