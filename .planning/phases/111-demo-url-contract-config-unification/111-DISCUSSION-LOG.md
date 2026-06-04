# Phase 111: Demo URL Contract & Config Unification - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 111-demo-url-contract-config-unification
**Mode:** assumptions
**Areas analyzed:** Public URL Contract, Seeded Demo URLs, Smoke Proof, Docker Bind Behavior, Scope Boundary

## Assumptions Presented

### Public URL Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `LOCKSPIRE_DEMO_BASE_URL` should be parsed once in the adoption demo config and should derive both `AdoptionDemoWeb.Endpoint` `url:` and `config :lockspire, :issuer` as `{base_url}/lockspire`. | Confident | `examples/adoption_demo/config/config.exs:22-42`; `scripts/demo/adoption_smoke.py:14,152-157` |

### Seeded Demo URLs

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Seeded local browser-visible URLs should derive from the same base URL, especially `acme-ledger-public` and `acme-ledger-backend` redirect URIs plus demo-facing registration/developer output; external partner demo fixtures should stay external. | Confident | `examples/adoption_demo/priv/repo/seeds.exs:91,123,139-171,601`; `examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex` |

### Smoke Proof

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep `scripts/demo/adoption_smoke.py` as the executable drift fence, but make its failure messages more explicit for issuer/endpoint/redirect drift rather than adding a new smoke entry point in Phase 111. | Likely | `scripts/demo/adoption_smoke.py:14,152-157,181,227,281`; `.github/workflows/ci.yml:200-260` |

### Docker Bind Behavior

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add one explicit bind-interface env for the demo endpoint, defaulting to loopback for host-local runs and allowing `0.0.0.0` only when Docker startup sets it. Do not infer bind IP from public base URL. | Likely | `examples/adoption_demo/config/config.exs:24-26`; `examples/adoption_demo/docker-compose.yml:22-25`; `.planning/ROADMAP.md` Phase 111 success criteria |

### Scope Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 111 should avoid replacing compose topology, adding Postgres containers, startup banners, cleanup lanes, or docs overhaul beyond narrow URL-contract notes/tests; those are Phases 112-115. | Confident | `.planning/ROADMAP.md:37-86`; `.planning/REQUIREMENTS.md` URL-01..05 versus later Docker, output, smoke, docs, hygiene requirements |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

No external research was performed. Codebase and planning artifacts provided enough evidence for this repo-local URL contract phase.
