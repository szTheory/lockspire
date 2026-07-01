---
phase: 113
slug: conflict-controls-optional-traefik
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-04
---

# Phase 113 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| maintainer shell -> Docker Compose | Untrusted environment variables and CLI flags render local container, port, network, and volume configuration. | Local DX configuration: ports, Compose project name, base URL, Traefik labels, Docker networks, and Docker volume names. |
| reset helper -> Docker daemon | Local shell command can stop containers and remove Docker volumes for the active adoption-demo project. | Docker project name and allowlisted demo volume suffixes. |
| browser/smoke -> adoption demo | Public base URL controls issuer, redirect, endpoint, and smoke proof alignment. | Browser-visible origin, redirect URI, issuer URL, and smoke-script target. |
| maintainer shell -> Compose override | Environment variables control optional Traefik hostname, router, service, network, and backend port labels. | Local hostname routing labels and external proxy network name. |
| web service -> external proxy network | The demo web container can be reached by an external local proxy only when the Traefik override is included. | HTTP traffic from local Traefik proxy to the demo web service. |
| Traefik hostname -> adoption demo issuer | Hostname routing must preserve the configured browser-visible base URL and exact redirect/issuer alignment. | Hostname origin used by startup, OAuth redirect/client seed data, and smoke proof. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-113-01 | Spoofing/Tampering | `examples/adoption_demo/docker-compose.yml` public URL and port env | mitigate | `LOCKSPIRE_DEMO_APP_PORT` drives host mapping and container `PORT`; `LOCKSPIRE_DEMO_BASE_URL` remains explicit browser-visible URL truth. Covered by `direct app port and browser-visible base URL stay aligned`. | closed |
| T-113-02 | Information Disclosure | `db` Compose service | mitigate | Default `db` service has no `ports`; host DB exposure lives only in `examples/adoption_demo/docker-compose.db-host.yml` bound to `127.0.0.1:${LOCKSPIRE_DEMO_DB_HOST_PORT:-5432}:5432`. Covered by default DB and opt-in DB tests. | closed |
| T-113-03 | Denial of Service | `examples/adoption_demo/bin/docker-reset` | mitigate | Reset uses the active project name and removes only `db_data`, `deps_volume`, and `build_volume`; tests forbid prune commands, `down -v`, and hard-coded legacy prefixes. | closed |
| T-113-04 | Tampering | Lockspire protocol/runtime modules | mitigate | Phase summaries list only adoption-demo Compose, docs, reset helper, and contract-test changes; no Lockspire protocol, storage, generator, Plug/Phoenix integration, admin, OAuth/OIDC flow, token lifecycle, algorithm, or redaction module was modified. | closed |
| T-113-05 | Information Disclosure | `examples/adoption_demo/docker-compose.traefik.yml` service/network membership | mitigate | Traefik override attaches only `web` to the external `traefik_proxy` network; `db` remains project-internal and default DB host port exposure remains absent. Covered by `Traefik override attaches only web to the external proxy network`. | closed |
| T-113-06 | Spoofing/Tampering | Traefik router/service labels | mitigate | Override renders configurable hostname, router, service, and network labels; tests assert configured values from `LOCKSPIRE_DEMO_TRAEFIK_*`. | closed |
| T-113-07 | Denial of Service | Traefik backend port detection | mitigate | Override sets `traefik.http.services.<service>.loadbalancer.server.port=${LOCKSPIRE_DEMO_APP_PORT:-4100}` explicitly; tests assert the configured backend port. | closed |
| T-113-08 | Elevation of Privilege | Optional proxy path broadens product/runtime boundary | mitigate | Traefik is documented and implemented as local-DX-only opt-in Compose override; default Docker path has no Traefik labels or external proxy dependency. No production packaging or hosted-auth service behavior was added. | closed |
| T-113-SC | Tampering | Package installs | accept | Plan register accepted this because no npm, pip, cargo, Hex, or Mix package install task was planned; phase summaries list `tech-stack.added: []`. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-113-01 | T-113-SC | No package installation or dependency introduction occurred in this phase; both plan threat models documented the supply-chain exposure as accepted because the planned work added only Compose, shell, docs, and tests. | GSD security audit | 2026-06-04 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-04 | 9 | 9 | 0 | Codex / gsd-secure-phase |

## Security Audit 2026-06-04

| Metric | Count |
|--------|-------|
| Threats found | 9 |
| Closed | 9 |
| Open | 0 |

Plan-time threat register was present in both `113-01-PLAN.md` and `113-02-PLAN.md`. Summary artifacts for both plans recorded focused adoption-demo Docker contract tests and Compose render verification. No unresolved `## Threat Flags` entries were present in the summaries.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-04
