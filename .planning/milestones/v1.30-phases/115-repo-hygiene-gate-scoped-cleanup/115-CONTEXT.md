# Phase 115: Repo Hygiene Gate & Scoped Cleanup - Context

**Gathered:** 2026-06-24 (assumptions mode with research expansion)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.30 by making adoption-demo cleanup and repo hygiene explicit, scoped, and non-destructive by default. This phase delivers maintainer-local stop/reset/cleanup/hygiene behavior for demo-owned Docker resources and generated artifacts, plus deterministic CI hygiene checks where appropriate. It must not add OAuth/OIDC protocol behavior, admin workflow behavior, production Docker packaging, hosted-auth shape, or broader public support claims.

</domain>

<decisions>
## Implementation Decisions

### Command Architecture

- **D-01:** Use a split shell-script architecture: keep the repo-wide hygiene gate in `scripts/maintainer/repo_hygiene_check.sh`, and keep adoption-demo lifecycle/cleanup commands under `examples/adoption_demo/bin/`.
- **D-02:** Do not introduce Mix tasks, a Makefile facade, GenServers, application runtime state, or production Lockspire modules for this phase. These commands are maintainer/repo-local DX, not shipped library API.
- **D-03:** Preserve the existing `examples/adoption_demo/bin/docker-reset` active-project reset shape, and add any broader cleanup as a separate explicit command rather than broadening reset semantics.

### Docker Scope And Safety

- **D-04:** Stop must preserve volumes. Reset may remove only the active Compose project's known demo volumes: `db_data`, `deps_volume`, and `build_volume`.
- **D-05:** Cleanup must be allowlist-driven and non-destructive by default. Destructive cleanup should default to dry-run/reporting and require an explicit execution flag such as `--execute`.
- **D-06:** Never use `docker system prune`, `docker volume prune`, broad `docker compose down -v`, or host-wide Docker cleanup in this phase.
- **D-07:** Use Docker Compose project names as the ownership boundary. Respect `--project`, `COMPOSE_PROJECT_NAME`, and the Compose default project name consistently across stop/reset/cleanup/hygiene commands.
- **D-08:** Docker Compose labels such as `com.docker.compose.project` may be used for local discovery/reporting of containers, networks, and volumes, but destructive deletion should remain constrained by explicit allowlists and exact active-project resource names.

### Hygiene Gate Behavior

- **D-09:** Extend `scripts/maintainer/repo_hygiene_check.sh` to report demo Docker leftovers and repo-owned generated artifacts using the existing `PASS` / `WARN` / `BLOCK` model.
- **D-10:** Local hygiene may inspect Docker daemon state when Docker is available. If Docker is unavailable or unreachable in local mode, report a `WARN`, not a `BLOCK`, unless a checked-in deterministic contract is broken.
- **D-11:** `--ci` hygiene must remain deterministic and must not require Docker daemon access or inspect local Docker/container/volume state. CI should validate scripts, docs, static allowlists, and release/demo contracts that GitHub can prove from checked-in files.
- **D-12:** Classify running active-project demo containers as `BLOCK` because they leave the demo lifecycle unfinished. Stopped containers, project volumes, and demo-owned artifacts should be classified according to whether they invalidate the expected clean lifecycle; output must include exact resource names and next commands.

### Generated Artifact Policy

- **D-13:** Cleanup and hygiene must distinguish generated demo junk from useful evidence. Preserve `tmp/admin-ui-polish/` by default because it contains admin UI proof for the next UI pass.
- **D-14:** Demo-owned generated artifacts such as `tmp/adoption_demo.log`, adoption-demo `_build`, and adoption-demo `deps` may be reported and cleaned only when explicitly allowlisted.
- **D-15:** Do not delete broad `tmp/`, arbitrary ignored files, unrelated example artifacts, or user-created local files.

### Output, Docs, And UX

- **D-16:** Treat repo hygiene as part of Lockspire's trust surface. Output should be calm, exact, action-oriented, and low-anxiety: `PASS` is terse, `WARN` gives triage context, and `BLOCK` gives a concrete remediation command.
- **D-17:** Hygiene and cleanup output may print fake demo account names, client IDs, paths, project names, ports, URLs, resource names, and remediation commands. It must not print secrets, tokens, private keys, authorization codes, refresh tokens, cookies, or unredacted sensitive values.
- **D-18:** `docs/adoption-demo.md`, maintainer scripts, startup output, smoke commands, cleanup commands, and hygiene output must agree on command names, scope, preserved evidence, and deleted resources.
- **D-19:** The intended lifecycle proof is explicit: start -> smoke -> stop -> cleanup -> hygiene leaves no demo-owned `BLOCK` findings.

### Verification Boundary

- **D-20:** Verification should be contract-focused around scripts, docs, CI behavior, Docker-scope semantics, allowlists, and hygiene output. Use runtime Docker proof locally where available, but do not make full Docker smoke a new CI requirement in this phase.
- **D-21:** Preserve `scripts/demo/adoption_smoke.py` as the only black-box OAuth/OIDC proof implementation and `scripts/demo/adoption_smoke.sh` as the maintainer-facing smoke wrapper. Do not add OAuth/OIDC/admin UI behavior changes.
- **D-22:** Keep demo/sample cleanup separate from public Lockspire support claims and package surface. The adoption demo remains repo-local proof, not production Docker packaging.

### Claude's Discretion

- Exact script names and flag spelling are at the planner/implementer discretion, provided the names are unsurprising, documented, shell-compatible, and consistent across tests/docs.
- Exact `WARN` versus `BLOCK` thresholds for stopped containers, preserved volumes, and generated files are at the planner/implementer discretion where the lifecycle proof remains enforceable and no clean repo state becomes noisy by default.
- Exact source-contract test structure is at the planner/implementer discretion, provided tests prove no broad prune/delete behavior and prove `--ci` remains Docker-free.

### Folded Todos

No matching pending todos were found for Phase 115.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/ROADMAP.md` — Phase 115 boundary, success criteria, and fixed requirements.
- `.planning/REQUIREMENTS.md` — Pending `SMOKE-03`, `CLEAN-01..03`, `HYGIENE-01..04`, and `BOUNDARY-01..02` requirements.
- `.planning/STATE.md` — v1.30 current state and prior Phase 113/114 decisions.
- `.planning/METHODOLOGY.md` — Assumption-first, research-first, high-threshold escalation, and one-shot recommendation lenses.

### Prior v1.30 Context

- `.planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md` — Base URL and bind-IP split; smoke proof boundary.
- `.planning/phases/112-default-docker-compose-app-db/112-CONTEXT.md` — Default direct Docker topology and Docker smoke CI deferral.
- `.planning/phases/113-conflict-controls-optional-traefik/113-CONTEXT.md` — Compose project scoping, optional Traefik, host-port controls, and active-project reset scope.
- `.planning/phases/114-startup-output-smoke-wrapper-docs/114-01-SUMMARY.md` — `docker-info` output/redaction posture.
- `.planning/phases/114-startup-output-smoke-wrapper-docs/114-02-SUMMARY.md` — Smoke wrapper and reprint command truth.
- `.planning/phases/114-startup-output-smoke-wrapper-docs/114-03-SUMMARY.md` — Docker-first docs and Phase 115 cleanup boundary.
- `.planning/phases/114-startup-output-smoke-wrapper-docs/114-PATTERNS.md` — Script/docs/test analogs for adoption-demo helpers.

### Product And DX Principles

- `prompts/lockspire-elixir-oss-library-practices.md` — OSS library DX and repo-shape principles.
- `prompts/lockspire-release-engineering-and-ci.md` — Release hygiene and CI posture.
- `prompts/lockspire-release-readiness-and-conformance.md` — Release trust and executable proof expectations.
- `prompts/lockspire-phoenix-system-design.md` — Embedded Phoenix architecture boundary.
- `prompts/Oauth server jtbd and domain.md` — Adoption/operator jobs-to-be-done language.
- `prompts/lockspire_brand_book.md` and `brandbook/README.md` — Tone and visual brand references if docs/evidence surfaces are touched.

### External Research References

- Docker Compose project names: `https://docs.docker.com/compose/how-tos/project-name/`
- Docker Compose `down`: `https://docs.docker.com/reference/cli/docker/compose/down/`
- Docker resource pruning: `https://docs.docker.com/engine/manage-resources/pruning/`
- Docker Compose service labels: `https://docs.docker.com/reference/compose-file/services/`
- Docker Compose volume labels: `https://docs.docker.com/reference/compose-file/volumes/`
- Docker volume label filtering: `https://docs.docker.com/reference/cli/docker/volume/ls/`
- Docker Compose merge behavior: `https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/`
- Mix task docs: `https://mix.hexdocs.pm/Mix.Task.html`
- Mix docs/aliases: `https://mix.hexdocs.pm/Mix.html`
- Hex publish package files: `https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html`
- Phoenix testing and CI article: `https://www.phoenixframework.org/blog/improving-testing-and-continuous-integration-in-phoenix`
- Rails contributing guide: `https://guides.rubyonrails.org/contributing_to_ruby_on_rails.html`
- Django contributing guide: `https://docs.djangoproject.com/en/6.0/intro/contributing/`
- Doorkeeper contributing guide: `https://github.com/doorkeeper-gem/doorkeeper/blob/main/CONTRIBUTING.md`
- node-oidc-provider package boundary: `https://github.com/panva/node-oidc-provider/blob/main/package.json`
- OpenIddict README/sample boundary: `https://github.com/openiddict/openiddict-core`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `scripts/maintainer/repo_hygiene_check.sh` already has argument parsing for `--ci` and `--skip-mix-ci`, shared `record_result`, PASS/WARN/BLOCK accounting, repo-owned checks, local-only checks, and final result summaries.
- `examples/adoption_demo/bin/docker-reset` already resolves the repo root, accepts `--project`, runs `docker compose --project-name "$project" ... down`, and removes only `${project}_db_data`, `${project}_deps_volume`, and `${project}_build_volume`.
- `examples/adoption_demo/bin/docker-start` already handles container startup, database setup, readiness, and prints `docker-info` after readiness.
- `examples/adoption_demo/bin/docker-info` already prints safe startup/reprint/smoke information from static allowlisted fixture truth.
- `scripts/demo/adoption_smoke.sh` already normalizes `LOCKSPIRE_DEMO_BASE_URL` and delegates to `scripts/demo/adoption_smoke.py`.
- `test/lockspire/adoption_demo_docker_contract_test.exs` already contains contract tests for Compose defaults, optional overrides, reset scope, docs, startup output, smoke wrapper, and Docker availability skips.
- `test/lockspire/release_readiness_contract_test.exs` already asserts hygiene script output/result strings and CI workflow wiring.

### Established Patterns

- Shell scripts are the established maintainer-local command surface for repo hygiene and adoption-demo Docker lifecycle commands.
- The adoption demo is repo-local proof, not a production deployment package or public Lockspire API.
- Direct Docker remains the default maintainer path; optional Traefik remains opt-in and external-network dependent.
- `LOCKSPIRE_DEMO_BASE_URL` remains the only browser-visible URL truth. Cleanup/hygiene must not introduce alternate URL semantics.
- Startup and smoke output use redacted, static, copyable maintainer-facing text rather than database inspection or secret-bearing seed output.
- Exact Docker project scoping matters because multiple Lockspire checkouts or sibling Elixir OSS demos may run on the same machine.

### Integration Points

- Add local Docker/artifact hygiene checks inside `local_checks` or an adjacent local-only helper path in `scripts/maintainer/repo_hygiene_check.sh`, not inside `repo_owned_checks`.
- Keep `--ci` path limited to deterministic repo-owned checks and script/docs/source contracts.
- Add adoption-demo cleanup helpers under `examples/adoption_demo/bin/`, reusing `docker-reset` project resolution semantics.
- Update `docs/adoption-demo.md` to replace the Phase 114 cleanup-boundary placeholder with the final stop/reset/cleanup/hygiene commands and their preservation/deletion semantics.
- Extend `test/lockspire/adoption_demo_docker_contract_test.exs` and/or `test/lockspire/release_readiness_contract_test.exs` to prove command names, allowlists, no broad prune/delete behavior, `--ci` Docker independence, docs alignment, and redaction.

</code_context>

<specifics>
## Specific Ideas

- Preferred recommendation bundle: scoped active-project cleanup, explicit generated-artifact allowlist, local PASS/WARN/BLOCK hygiene, daemon-free CI hygiene, and demo/sample separation from public product support claims.
- Use Docker Compose labels for reporting/discovery where useful, but use explicit allowlists for destructive cleanup.
- Output examples should look like:
  - `PASS demo containers: no active Lockspire demo containers found`
  - `WARN demo volumes: active project volumes remain; run examples/adoption_demo/bin/docker-reset --project lockspire-adoption-demo to rebuild demo state`
  - `BLOCK demo Docker resources: running containers from the active project remain`
  - `Preserved: tmp/admin-ui-polish/ contains admin UI evidence and is not removed by default`
- UI/UX design work is not in scope. If rendered docs/evidence surfaces are touched, keep existing brand/design-system constraints: non-color status labels, accessible contrast, visible focus, reduced-motion support, and concise operational copy. CLI output should borrow the product tone, not the visual system.

</specifics>

<deferred>
## Deferred Ideas

- Structured JSON hygiene/readiness output for automation.
- Full Docker smoke in CI after local proof shows it is stable and non-flaky.
- Cross-repo local development cleanup/proxy conventions shared across sibling Elixir OSS libraries.
- Browser screenshot automation for the next admin UI polish milestone.
- Production Docker release images or deployment packaging, only in a future distribution milestone.
- Cleanup or archive commands that explicitly target `tmp/admin-ui-polish/`; not default Phase 115 cleanup.

</deferred>

---

*Phase: 115-repo-hygiene-gate-scoped-cleanup*
*Context gathered: 2026-06-24*
