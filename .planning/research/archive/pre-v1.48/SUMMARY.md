# Project Research Summary

**Project:** Lockspire v1.47 OAuth/OIDC Core Interoperability & Hardening
**Researched:** 2026-10-24
**Confidence:** High for current source/support boundaries and chosen direction; historical external failures require fresh attribution.

## Key Findings

Three focused subagents considered interoperability, security/distributed storage and delivery/CI; the orchestrator synthesized the decisions. v1.47 should first qualify retained OIDC authorization-error and FAPI PAR/TLS/WebRunner findings, then correct only selected supported-surface behavior with deterministic and package-level proof. No current defect or fresh runtime result is claimed by this research.

No dependency or platform upgrade is selected. Use existing tooling and reviewed primitives. Preserve pinned historical suite inputs for comparable reproduction; explicitly review any required input refresh. Keep protocol and harness fixes distinct.

SEC-01 dedicated client-auth verifier key isolation is the preferred separate provisional v1.48. Existing refresh/replay/rollback coverage is substantial; additional concurrency scope requires evidence. OPS-03 paging and KEK-04 provider work require measured/operator triggers.

## Implications for Roadmap

| Phase | Outcome | Decision gate |
|---|---|---|
| 171 | Current baseline, reproducible findings and finite case ownership | Accepted-main implementation entry; exact input identities and supported/normative attribution |
| 172 | Selected authorization responses and silent-auth/freshness cases | Only qualified cases; reuse correct proof and fix reproduced defects |
| 173 | Selected PAR/profile boundary cases | Transport/issuer/browser issues attributed first; conditional scope may shrink |
| 174 | Package-level proof, required candidate checks and delivery handoff | All selected acceptance; honest supplemental disposition; no publication claim |

The roadmap maps all 14 requirements exactly once to these phases; no implementation plans have been created. Phase 171 must settle the downstream case inventory before dependent plans fan out. If no material correction or proof gap survives, explicitly narrow/replan rather than force four implementation phases.

## Decision Resolution

Normative standards plus current support and reproduction outrank suite labels. Full external-suite success/certification is not milestone acceptance. Required selected behavior remains mandatory; a documented blocked external probe does not become a pass. Reuse existing tests for already-correct cases and preserve unqualified findings with owners. Keep entry maintenance separate from protocol expansion.

Remote main was observed green at a1e39a01 with matching CI and Release push no-publish shape. The feature checkout is not yet synchronized/accepted main; [baseline](v1.47-core-hardening/BASELINE.md) records prior delivery, worktrees and preserved machine-state bytes. Do not spend dependent implementation work until that entry gate and case qualification are settled.

## Sources

- [Interoperability and primary standards](v1.47-core-hardening/INTEROPERABILITY.md): OIDC Core, RFC 9700/9126, FAPI final specifications and OIDF tooling/process.
- [Security and sequencing](v1.47-core-hardening/SECURITY-AND-SEQUENCING.md): current verifier-key coupling, existing token/storage evidence and bounded migration decisions.
- [Delivery](v1.47-core-hardening/DELIVERY.md): repository train, exact-main and workspace handoff.
- [Scope and decisions](v1.47-core-hardening/SCOPE.md), [rolling roadmap](../MILESTONE-ARC.md).
