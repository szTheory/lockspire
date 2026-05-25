# Phase 92: Advanced Setup Support Truth - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `92-CONTEXT.md`.

**Date:** 2026-05-25
**Phase:** 92-advanced-setup-support-truth
**Mode:** assumptions with targeted subagent research
**Areas analyzed:** support-contract architecture, mTLS setup truth, protected-route pipeline truth, logout propagation truth, repo-level GSD defaults

## Assumptions Presented

### Shared support-contract architecture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `docs/supported-surface.md` should remain the single canonical public support contract, while scenario guides and admin/doctor surfaces stay derived consumers. | Confident | `docs/supported-surface.md`, `docs/install-and-onboard.md`, `docs/maintainer-release.md`, `.planning/phases/87-CONTEXT.md`, `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md` |
| Shared normalized truth should exist for runtime/admin/doctor status surfaces, but nuanced support-boundary prose should stay in docs rather than code constants. | Likely | `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`, Phase 91 context, `docs/private-key-jwt-host-guide.md` |

### mTLS setup truth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Lockspire should bless exactly two first-class mTLS deployment patterns in public docs: direct app termination and trusted proxy-header extraction. | Confident | `docs/mtls-host-guide.md`, `lib/lockspire/mtls/extractor.ex`, `lib/lockspire/plug/enforce_sender_constraints.ex` |
| Arbitrary custom extractors should remain an escape hatch, not an equal public support-contract tier. | Likely | extractor behaviour design plus milestone support-burden goals |

### Protected-route pipeline truth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The canonical host Phoenix route pipeline is `VerifyToken -> EnforceSenderConstraints -> RequireToken`, with each plug owning a distinct step in the protocol/wire contract. | Confident | `docs/protect-phoenix-api-routes.md`, `lib/lockspire/plug/*.ex`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs`, plug tests |
| `EnforceSenderConstraints` should be treated as part of the canonical supported pipeline even for bearer-first examples because it is a no-op for unconstrained tokens and preserves future correctness. | Likely | current plug design, test behavior, and DPoP/mTLS support posture |

### Logout propagation truth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Lockspire should continue to present one asymmetric logout truth model: durable back-channel, best-effort front-channel. | Confident | `docs/supported-surface.md`, `docs/operator-admin.md`, `docs/install-and-onboard.md`, `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex`, `.planning/phases/87-CONTEXT.md` |
| DCR/admin/logout docs should explicitly frame metadata management as controlling the existing runtime rather than creating a new logout system. | Confident | `docs/dynamic-registration.md`, `docs/operator-admin.md`, Phase 87 context |

### Repo-level GSD defaults
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Future GSD discuss/plan work should default to research-first, assumption-first, one-shot recommendations for already-shipped support surfaces, escalating only for high-impact boundary or support-claim changes. | Confident | `.planning/METHODOLOGY.md`, user instruction in this phase discussion, prior methodology themes |

## Research Inputs

- `gsd-advisor-researcher` (mTLS): compared two-pattern, proxy-first, and fully generic extractor support-contract options; recommended the two-pattern contract with custom extractors as an escape hatch.
- `gsd-advisor-researcher` (protected routes): compared primitive-only docs, explicit canonical pipeline, and wrapper/macro-heavy support stories; recommended the explicit canonical pipeline.
- `gsd-advisor-researcher` (logout): compared spec-maximal parity, symmetric-channel framing, and asymmetric truth model; recommended the asymmetric truth bundle.
- `gsd-advisor-researcher` (support architecture): compared canonical-doc-first, code-truth-first, and per-surface truth models; recommended canonical prose authority plus narrow shared runtime truth primitives.

## Corrections Made

No user corrections were needed before context capture. The repo evidence and targeted subagent research converged strongly enough to lock a cohesive recommendation bundle directly.

## Deferred Questions

- Whether Phase 92 should also introduce any new small support-truth primitive module or limit itself to documentation and wording alignment.
- Whether the repo-level GSD preference should remain captured in methodology/planning conventions only, or also be reflected in additional planning templates later.

---

*Audit log only. Use `92-CONTEXT.md` for downstream work.*
