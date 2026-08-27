# Phase 134: Architecture Topology - Discussion Log (Assumptions Mode)

> **Audit trail only.** Decisions are captured in `134-CONTEXT.md`; this log records the autonomous evidence used because user feedback was intentionally unavailable.

**Date:** 2026-08-27
**Phase:** 134-architecture-topology
**Mode:** assumptions (`--auto`)
**Areas analyzed:** Runtime Graph, Public Compatibility, Protocol/Delivery Boundary, Client Metadata and Lifecycle Ownership, Fitness Evidence

## Assumptions Presented

| Area | Assumption | Confidence | Evidence |
|---|---|---|---|
| Runtime graph | Remove every currently reported runtime/export cycle, not only the most visible protocol/web cycle. | Confident | `mix xref graph --format cycles` reports five named cycles; ARCH-01 requires no runtime or export cycles. |
| Public compatibility | Preserve current nested public module names as facades when implementation moves. | Confident | Phase goal requires compatible public module structure; `docs/supported-surface.md` names `Lockspire.Web.AdminRouter`, `Lockspire.Plug.*`, and direct/DCR behavior. |
| Protocol boundary | Protocol has no dependency on `Lockspire.Web` or `Lockspire.Admin`; router/delivery selection is an outer concern. | Confident | `lib/lockspire/protocol/discovery.ex` defaults to `Lockspire.Web.Router`; registration and management call `Lockspire.Admin`; ARCH-02 expressly forbids delivery/operator reach-through. |
| Client service | Extract a shared neutral client metadata/lifecycle service underneath DCR and admin facades while preserving their deliberately different boundary errors/results. | Confident | `lib/lockspire/protocol/registration.ex`, `registration_management.ex`, and `admin/clients.ex` duplicate/cross-call metadata/lifecycle behavior; Phase 132 established neutral `ClientRegistration.Shape` precedent. |
| Fitness evidence | Use Mix xref plus focused AST/characterization tests, not a new analyzer dependency. | Likely | Existing `test/lockspire/architecture_fitness_test.exs` parses AST and `mix xref` reports cycles in the installed toolchain; no repository evidence requires a third-party analyzer. |

## Auto-Resolved

- Chose a strict inward dependency direction rather than a package-name-only convention, because the current cycle output already crosses protocol, web, configuration, security, and storage layers.
- Chose a neutral client service below DCR/admin rather than having DCR call the public admin facade, because the latter is the present ARCH-02 violation and obscures ownership.
- Kept direct/DCR differences explicit instead of normalizing their public contracts, because Phase 132 intentionally distinguishes required direct scopes from optional DCR `scope` metadata and preserves DCR policy/RAT/IAT behavior.

## Open Risks

- The nine-node token-exchange cycle may expose a larger collaborator boundary than the smaller three-node cycles; plan it as an independently verifiable slice so behavior characterization precedes inversion.
- Module relocation can accidentally change compile/export edges or documentation visibility even when functions still work; compatibility tests must exercise existing names, not merely compile the new implementations.
- Centralizing client lifecycle must not broaden operator powers into DCR or lose DCR audit attribution/atomic RAT rotation; characterize these security properties before extraction.

## External Research

None required for phase scoping. Mix xref and the repository's AST fitness pattern are sufficient for the specified enforceable graph proof.
