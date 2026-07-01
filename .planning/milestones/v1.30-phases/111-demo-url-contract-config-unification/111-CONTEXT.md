# Phase 111: Demo URL Contract & Config Unification - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 111 makes `LOCKSPIRE_DEMO_BASE_URL` the single browser-visible URL truth for the adoption demo. It unifies Phoenix endpoint URL generation, Lockspire issuer configuration, seeded local redirect/callback/verification URLs, smoke proof, and Docker bind behavior before later phases change Compose topology, conflict controls, startup output, docs, and hygiene.

This phase must not add the default app-plus-Postgres Docker stack, make Traefik required, build startup banners, overhaul adoption-demo docs beyond narrow URL-contract truth, add cleanup lanes, or change OAuth/OIDC protocol behavior.

</domain>

<decisions>
## Implementation Decisions

### Public URL Contract

- **D-01:** Parse `LOCKSPIRE_DEMO_BASE_URL` once in the adoption demo config and derive both `AdoptionDemoWeb.Endpoint` `url:` and `config :lockspire, :issuer` from it. The Lockspire issuer should be exactly `{base_url}/lockspire`.
- **D-02:** Keep `LOCKSPIRE_DEMO_BASE_URL` as the browser-visible external origin, not as the bind interface or database/network configuration. The config path should normalize the value enough to avoid trailing-slash drift.

### Seeded Demo URLs

- **D-03:** Derive seeded local browser-visible URLs from the same base URL, especially the `acme-ledger-public` and `acme-ledger-backend` redirect URIs plus local demo output strings that show `/oauth/callback`.
- **D-04:** Preserve intentionally external partner fixtures such as Northstar and legacy callback/logout URLs; those model non-local partner state and should not be rewritten to the demo base URL.

### Smoke Proof

- **D-05:** Keep `scripts/demo/adoption_smoke.py` as the executable drift fence for Phase 111. It should continue to use `LOCKSPIRE_DEMO_BASE_URL` as its only external URL input.
- **D-06:** Improve smoke failure clarity for issuer, endpoint, redirect, and verification-URI drift where useful, but do not create a new smoke wrapper or startup-output path in this phase. Those belong to Phase 114.

### Docker Bind Behavior

- **D-07:** Add one explicit bind-interface environment option for the demo endpoint. The default remains loopback for host-local runs, and Docker startup can set it to a container-reachable interface such as `0.0.0.0`.
- **D-08:** Do not infer bind IP from `LOCKSPIRE_DEMO_BASE_URL`; public URL and listening interface are separate concerns.

### Scope Split

- **D-09:** Keep Phase 111 narrowly focused on URL contract/config unification and deterministic proof. App-plus-Postgres Compose work is Phase 112; conflict controls and optional Traefik are Phase 113; startup output, smoke wrapper, and docs expansion are Phase 114; hygiene and cleanup are Phase 115.

### the agent's Discretion

- The exact helper shape for parsing `LOCKSPIRE_DEMO_BASE_URL` is at the agent's discretion, provided it stays local to the adoption demo and does not broaden Lockspire's public API.
- The exact environment variable name for endpoint bind IP is at the agent's discretion, provided the default remains loopback and Docker can opt into a container-reachable bind.
- The exact wording of smoke assertion errors is at the agent's discretion, provided issuer and endpoint drift fail clearly.

### Folded Todos

No matching pending todos were found for Phase 111.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` - v1.30 milestone intent, embedded-library boundary, and non-negotiable host seam constraints.
- `.planning/REQUIREMENTS.md` - URL-01..05 requirements and v1.30 boundaries.
- `.planning/ROADMAP.md` - Phase 111 scope and the split across Phases 112-115.
- `.planning/STATE.md` - current milestone state and locked decision that `LOCKSPIRE_DEMO_BASE_URL` is the single public URL truth.
- `.planning/METHODOLOGY.md` - assumption-first, least-surprise host seam, research-first defaults, and high-threshold escalation lenses.
- `.planning/phases/101-adoption-demo-re-wire/101-CONTEXT.md` - prior adoption-demo smoke, callback, protected-route, and base-URL-driven proof decisions.
- `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-CONTEXT.md` - precedent for demo seeds as repeatable proof state.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-CONTEXT.md` - latest seed and proof boundary decisions.
- `examples/adoption_demo/config/config.exs` - current split endpoint URL, issuer, DB, and bind configuration.
- `examples/adoption_demo/priv/repo/seeds.exs` - seeded clients, redirect URIs, registration URIs, and local demo output.
- `examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex` - developer-app demo output and OAuth callback display.
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` - local callback, verification, admin, Lockspire, and protected API route surface.
- `examples/adoption_demo/docker-compose.yml` - current Traefik-only web service and Docker bind intent.
- `examples/adoption_demo/Dockerfile.dev` - current demo container startup command.
- `scripts/demo/adoption_smoke.py` - existing black-box drift fence and base-URL-driven smoke proof.
- `.github/workflows/ci.yml` - current adoption-demo CI job, env wiring, server startup, and smoke invocation.
- `lib/lockspire/config.ex` - issuer validation and `device_verification_uri/0` behavior.
- `lib/lockspire/protocol/discovery.ex` - discovery metadata derived from `Lockspire.Config.issuer!/0`.
- `docs/adoption-demo.md` - current host-local run and smoke documentation.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scripts/demo/adoption_smoke.py` already reads `LOCKSPIRE_DEMO_BASE_URL`, waits for the demo root, asserts discovery issuer/endpoint URLs, drives authorization code + PKCE with base-derived callback URIs, checks device verification URI, and calls the protected API.
- `.github/workflows/ci.yml` already passes `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100` to the adoption-demo smoke job and runs the same black-box Python script.
- `examples/adoption_demo/mix.exs` already provides `mix ecto.setup` as the idempotent-ish local create/migrate/seed path that later Docker startup can reuse.

### Established Patterns

- Demo seed state lives in `examples/adoption_demo/priv/repo/seeds.exs` and is the repeatable source of admin/demo proof state.
- Lockspire protocol URLs derive from `Config.issuer!()`; discovery metadata and device verification URI inherit whatever issuer the host config supplies.
- The smoke script is the existing repo-native executable proof for adoption-demo drift rather than a separate browser automation stack.
- Exact redirect URI matching is a protocol security invariant, so seeded redirect URIs and smoke callback parameters must stay byte-aligned with the configured base URL.

### Integration Points

- `examples/adoption_demo/config/config.exs` currently hard-codes issuer to `http://127.0.0.1:4100/lockspire`, configures endpoint URL from `LOCKSPIRE_DEMO_HOST`/`PORT`, and binds HTTP to `{127, 0, 0, 1}`.
- `examples/adoption_demo/priv/repo/seeds.exs` currently hard-codes local redirect URIs and local registration output to `http://127.0.0.1:4100`.
- `examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex` currently hard-codes local callback URLs in displayed client details.
- `examples/adoption_demo/docker-compose.yml` currently sets `PORT=4000` and comments that Phoenix should bind to `0.0.0.0`, but no config consumes a bind-IP env.
- `lib/lockspire/config.ex` computes `device_verification_uri/0` from the issuer by replacing the path with `/verify`; once issuer follows base URL, device verification follows automatically.
- `lib/lockspire/protocol/discovery.ex` builds endpoint metadata from `Config.issuer!()`, so discovery endpoint drift should be fixed by the issuer unification rather than by discovery-specific logic.
</code_context>

<specifics>
## Specific Ideas

- Prefer a small local config helper in `examples/adoption_demo/config/config.exs` or a tiny adoption-demo-only module/script if planning finds config helpers too awkward in `config.exs`.
- Preserve `http://127.0.0.1:4100` as the default `LOCKSPIRE_DEMO_BASE_URL` for host-local runs and current CI.
- Treat `http://127.0.0.1:4100/oauth/callback` as the default derived callback URI, not a literal repeated across seeds and demo output.
- Docker can later use a different base URL/port while setting the bind interface explicitly.
</specifics>

<deferred>
## Deferred Ideas

- Default app-plus-Postgres Compose topology, database healthcheck, project-scoped volumes, idempotent container setup, and HTTP readiness wait - Phase 112.
- Configurable Compose project names, public app ports, scoped cache reset, and optional Traefik hostname routing - Phase 113.
- Startup ready banner, reprint command, smoke wrapper, and expanded adoption-demo docs - Phase 114.
- Repo hygiene gate, scoped cleanup lanes, CI/local hygiene split, and demo-owned Docker artifact cleanup - Phase 115.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>

---

*Phase: 111-demo-url-contract-config-unification*
*Context gathered: 2026-06-04*
