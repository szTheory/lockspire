---
phase: "171"
slug: accepted-baseline-finding-qualification
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-24"
---

# Phase 171 — Security

The independent security auditor verified twelve mitigations. Its one remaining
documentation gap was T-171-SC: the existing plan-time accepted no-install
disposition needed this accepted-risk log. The executing maintainer recorded
that existing disposition below; no package installation or new risk acceptance
was inferred. This report verifies qualification controls, not correction of the
two product counterexamples assigned to phases 172/173.

## Trust Boundaries

| Boundary | Control |
|---|---|
| Local/history/hosted evidence → implementation authority | Immutable original accepted-main receipt and distinct source identities |
| Other worktrees/resources → current run | Explicit custody, preserved tips and no unknown cleanup |
| Suite inputs/diagnostics → durable evidence | Locked identities, allowlisted facts and honest unlaunched outcomes |
| Probe controls → normative counterexamples | Successful positive controls, exact final assertions, source/probe hashes |
| Frozen matrix → dependent scope | Case/requirement correspondence, ordered input hashes and explicit amendments |

## Threat Register

| Threat ID | Category | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|
| T-171-01 | Spoofing | high | mitigate | Ledger contract validates accepted/base SHA equality, original receipt hash, required gates, positive count and warning dispositions | closed |
| T-171-02 | Tampering | high | mitigate | DELIVERY custody record; auditor checked retained worktree tips, feature history and archived original main | closed |
| T-171-03 | Repudiation | medium | mitigate | Contract requires dated source, named command/test, observations and owners; negative identity/owner fixtures | closed |
| T-171-04 | Tampering | high | mitigate | Existing oidf_inputs.py validator and unchanged lock/plan hashes; no input refresh | closed |
| T-171-05 | Information disclosure | high | mitigate | Existing redacted-evidence allowlist; unlaunched profiles have no receipts; bounded probe projections | closed |
| T-171-06 | Denial of service | medium | mitigate | Neither wrapper launched; cleanup inapplicable; owned serial retry instructions and existing occupied-output/interruption guards | closed |
| T-171-07 | Repudiation | high | mitigate | Supported/normative references and deterministic proof required; suite/interruption substitution rejected | closed |
| T-171-08 | Elevation of privilege | high | mitigate | Selected-case blockers prevent freeze; narrow host seam and unchanged runtime/API/dependency files | closed |
| T-171-09 | Tampering | high | mitigate | Matrix case correspondence, six requirement dispositions, zero blockers and ordered manifest/hash checks | closed |
| T-171-10 | Repudiation | medium | mitigate | Dated REQUIREMENTS/ROADMAP scope amendments preserve IDs and pending correction status | closed |
| T-171-11 | Information disclosure | high | mitigate | Probe retains only status/location category, scope/parameter names and equality booleans; no reference/connection/body values | closed |
| T-171-12 | Tampering | high | mitigate | Positive controls before named assertions; contract binds controls, actual exit/count, source/probe hashes and distinct expected/observed projections | closed |
| T-171-13 | Tampering | medium | mitigate | Dated procedure-scoped claim and retained no-launch evidence; draft fixture specifically rejects interrupted=true for an unlaunched profile | closed |
| T-171-14 | Repudiation | high | mitigate | Attributed delegated dispositions preserve uncertainty and original observations; reviewed changed manifest identities have source, old/new hashes and reasons | closed |
| T-171-SC | Tampering | high | accept | Existing accepted no-install boundary explicitly logged below | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| R-171-SC | T-171-SC | Phase 171 selects no package installation, dependency update or immutable-input refresh. Missing Python prerequisites remain unavailable with a concrete owner/retry. Any future preparation/install remains a separately reviewed legitimacy boundary. This accepts the bounded no-install scope, not unknown dependencies. | Existing disposition in all three approved plans; recorded by Codex executing maintainer under the user's delegated scoped authority | 2026-10-24 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-24 | 13 | 12 | 1 | Independent gsd-security-auditor: mitigation review; missing accepted-risk log identified |
| 2026-10-24 | 13 | 13 | 0 | Codex executing maintainer: documented existing T-171-SC acceptance and checked log presence |

## Sign-Off

- [x] All fifteen unique planned threats have a disposition and evidence.
- [x] Existing accepted risk is explicitly recorded.
- [x] No open threat at or above the high blocking threshold remains.
- [x] No protocol correction, external-suite execution, certification or human confirmation is claimed.

The two controlled normative failures remain assigned to phases 172/173. Both
optional external profiles remain unlaunched. The four review warnings were subsequently fixed; fresh full Credo is clean and
the ledger contract passes 22 tests. The strengthened consent-origin control
rejects off-origin, network-path and lookalike routes before interaction lookup.
The new dated probe repeated both controlled normative failures and preserves
the original observation. This strengthens T-171-11/12 without changing the
planned risk disposition or claiming either product defect corrected.

## Gap-plan mitigation audit — 2026-10-24

The executing maintainer checked new T-171-13/14 at ASVS L1 after Plan 04 execution. The procedure amendment and unavailable broader claim are explicit in Plan 02, DECISIONS, DELIVERY and VALIDATION. The isolated draft fixture first failed, then the new unavailable-profile predicate rejected impossible interruption evidence; final contract: 22 tests, 0 failures. The three delegated judgments name sources and preserve flagged assumptions/prohibitions and absent human confirmation. Manifest audits preserve original cases, receipts, profiles and probe observations while attributing changed authority references. Both new planned mitigations are present; fifteen unique threats are closed and threats_open remains zero. No optional profile operation or new risk acceptance occurred.
