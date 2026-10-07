# Phase 141: Maintenance-Baseline Closure - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `141-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-10-02
**Phase:** 141-maintenance-baseline-closure
**Mode:** assumptions
**Areas analyzed:** terminal acceptance evidence, planning completion and published release truth, disposition and deferral truth, maintainer journey and scope

## Assumptions Presented

### Terminal Acceptance and Evidence Identity
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 141 relies on Phase 140's final post-summary exact-SHA acceptance, not predecessor/entry receipts or independent green runs. | Confident | `.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md`, `140-HANDOFF.md` |
| One dated Markdown baseline record links the accepted SHA to local gates, canonical CI, Release no-publish, published-release proof, dispositions, and explicit deferrals. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md` |
| If the report commit differs from the accepted source SHA, record and explain both identities so evidence is never attributed to a later tree. | Confident | `.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md`, exact-SHA repository contracts |

### Planning Completion and Published Release Truth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| v1.38 milestone completion returns Lockspire to sustaining GA but does not publish a package or authorize manual release metadata changes. | Confident | `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/RELEASE-TRAIN.md`, `.planning/phases/139-required-truth-reconciliation/139-CONTEXT.md` |
| The current public release is 1.5.0 at source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`; the 1.5.1 source metadata does not prove a public release. Revalidate the public state at closure. | Confident | Hex package/release APIs, GitHub public release/tag, canonical CI run `33141161205`, protected publish run `33141484467`; repo mismatch in `.planning/PROJECT.md`, `.planning/RELEASE-TRAIN.md`, `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` |

### Disposition and Deferral Truth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Carry forward source-linked Phase 140 dispositions and triggers, preserving the distinction between resolved, historical, deferred, and out-of-scope work. | Confident | `.planning/REQUIREMENTS.md`, `140-DISPOSITIONS.md`, `139-CONTEXT.md` |
| Supplemental OIDF/FAPI evidence remains redacted, supplemental, and non-certifying. | Confident | `.planning/phases/139-required-truth-reconciliation/139-CONTEXT.md`, `140-DISPOSITIONS.md` |

### Maintainer Journey and Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The primary user experience is a navigable, accessible maintainer Markdown handoff, not a Phoenix UI, API, or runtime feature. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `138-CONTEXT.md`, `brandbook/README.md` |
| Use only release-engineering, release-readiness, and packaging-relevant OSS guidance from `prompts/`; use the current root brandbook if visual design becomes relevant. | Confident | `prompts/README.md`, `prompts/lockspire-release-engineering-and-ci.md`, `prompts/lockspire-release-readiness-and-conformance.md`, `brandbook/README.md` |

## Corrections Made

No corrections — all assumptions were confirmed. The user selected the complete recommendation set (`1`) on 2026-10-02.

## External Research

- Hex's package API lists Lockspire 1.5.0; the 1.5.1 release endpoint returned 404.
- GitHub's public 1.5.0 release/tag points to source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`; CI run `33141161205` passed and protected release run `33141484467` published/verified the package. No `lockspire-v1.5.1` release/tag was found.
- Sources: [Hex package](https://hex.pm/api/packages/lockspire), [Hex 1.5.0](https://hex.pm/api/packages/lockspire/releases/1.5.0), [Hex 1.5.1 lookup](https://hex.pm/api/packages/lockspire/releases/1.5.1), [GitHub release](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0), [CI run](https://github.com/szTheory/lockspire/actions/runs/33141161205), [protected release run](https://github.com/szTheory/lockspire/actions/runs/33141484467).
