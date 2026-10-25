# Project Research Summary

**Project:** Lockspire v1.46 Embedded Host Integration Reliability
**Domain:** Embedded Phoenix admin routing and host-owned staff authorization
**Researched:** 2026-10-22
**Confidence:** HIGH for constraints; MEDIUM for final API pending reproduction

## Executive Summary

The highest-value mechanical fix is to converge the supported installation path and the working demo on one host-expanded admin route integration. The generator forwards AdminRouter; the demo duplicates its live routes to obtain correct host-path signing; the verifier currently treats the forward as healthy. Native LiveView routing documentation supports replacing that mismatch with direct declarations in the host router.

Keep staff identity and decisions in the host. Explicit HTTP and LiveView authorization, an admin live-session boundary, compatible upgrades and connected packaged proof are required. Add no dependency and no visual redesign. Work was researched inline under the skill's Codex fallback; no research or roadmapper subagents were spawned.

## Key Findings

### Recommended Stack

Use the existing Phoenix/LiveView route, session and hook primitives. Root locks are Phoenix 1.8.13 / LiveView 1.2.10; the exact supported floor remains Phoenix 1.8.5 / LiveView 1.1.28. The compatibility job presently compiles the fixture and needs scoped runtime coverage for the repaired integration. See [STACK.md](STACK.md).

### Expected Features

One reusable route integration; existing route/action and default/custom mount parity; host-owned request and connected authorization; isolated admin navigation; safe install/upgrade; truthful diagnostics; packaged and supported-floor lifecycle tests in CI. Defer visual work, new auth/identity systems, continuous permission polling, KMS and unrelated encryption/maintenance work. See [FEATURES.md](FEATURES.md).

### Architecture Approach

Library declarations expand in the host router with an explicit live_session and required host authorization hook. Generated helpers, demo and clean-room hosts consume that same API. Existing manifest and file-transaction safety governs upgrades; verification inspects the new route/session shape without claiming to validate arbitrary host policy. See [ARCHITECTURE.md](ARCHITECTURE.md).

### Critical Pitfalls

Connected success is distinct from HTTP rendering; an HTTP staff plug is insufficient for stateful entry; duplicated demo routes can hide generator defects; custom mount links and route order must be tested end to end; compile-only version checks cannot establish runtime compatibility. Mount-only authorization does not promise immediate revocation of an already connected socket. See [PITFALLS.md](PITFALLS.md).

## Implications for Roadmap

| Proposed phase | Outcome | Reason for order |
|---|---|---|
| 167 — Host-Expanded Admin Routing | Reproduce forward-only failure and deliver one route/session contract with parity | Establish the integration primitive first |
| 168 — Host-Owned LiveView Authorization | Prove host checks on request, connection/reconnect and session/navigation boundaries | Secure the primitive before generating it |
| 169 — Install and Upgrade Convergence | Generated helper, safe migration, verifier, demo and docs agree | Make the supported path installable |
| 170 — Packaged Host and Compatibility Proof | Real connected journeys and runtime floor run in required CI | Validate the delivered package and complete integration |

Every phase adds its own focused regression checks. Phase 170 integrates proof; it is not the first test phase.

## Confidence Assessment

| Area | Confidence | Evidence / limitation |
|---|---|---|
| Stack | High | Official baseline docs and local installed source; no new dependencies |
| Features | High | User-approved scope and current template/demo/verify mismatch |
| Architecture | Medium | Native APIs exist; exact signature and upgrade behavior need a red reproduction |
| Pitfalls | High | Framework lifecycle documentation and local coverage limits |

### Gaps to Address

- Phase 167 must freshly reproduce the forwarded connection problem; current research makes no new runtime/exploit claim.
- Settle route API signature, session name and hook composition, supported mount normalization, layout/session options and AdminRouter compatibility in phase context/planning.
- Determine the smallest reusable client/socket harness and precise CI command in Phase 170; do not claim visual verification or whole-protocol recertification.
- Existing Phase 142/143 directories are historical evidence, not outgoing v1.45 work; v1.45's phases were already archived. Preserve them and the original dirty state.json bytes.
- The source candidate is still on feat/164-client-secret-lifetimes. This planning run does not merge, push or publish it and does not establish a clean-main baseline; refresh exact repository/CI state before implementation/ship decisions.

## Sources

- [LiveView 1.1.28 routing](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html#live_session/3).
- [LiveView 1.1.28 lifecycle hooks](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.html#on_mount/1).
- [LiveView 1.1.28 tests](https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html).
- [Phoenix 1.8.5 routing](https://hexdocs.pm/phoenix/1.8.5/Phoenix.Router.html).
- [Current LiveView security guide](https://hexdocs.pm/phoenix_live_view/security-model.html), served v1.2.13 at access time.
- Local: mix.exs/mix.lock; AdminRouter; generated router template; demo router; Install.Verify; Install.OperationPlan; Install.Manifest; compatibility fixture and CI. Prior canonical research was preserved byte-for-byte in research/archive/pre-v1.46/.

---
*Research completed: 2026-10-22. Ready for requirements confirmation; final API and runtime claims await implementation proof.*
