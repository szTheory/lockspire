# Requirements: Lockspire

**Defined:** 2026-04-23
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1.1 Requirements

### Release Gates

- [ ] **GATE-01**: `mix qa` passes from repo truth on the maintained development path.
- [ ] **GATE-02**: `mix docs.verify`, `mix deps.audit`, and `mix package.build` pass from repo truth on the maintained development path.
- [ ] **GATE-03**: `mix test.integration` and `mix test.phase3` pass from repo truth on the maintained development path.

### Trusted Release Path

- [ ] **RELS-01**: The trusted release workflow runs `mix release.preflight` inside the protected `hex-publish` environment with the required credentials wired through environment secrets.
- [ ] **RELS-02**: Maintainer-facing release guidance references only real commands and the trusted publish path used by the repo.
- [ ] **RELS-03**: Release automation and package metadata remain pinned and reviewable enough that a preview release can be published without undocumented manual steps.

### Preview Support Posture

- [x] **POST-01**: Public docs and supported-surface guidance describe only the implemented `v0.1` preview scope and explicitly avoid unsupported protocol claims.
- [x] **POST-02**: Contract tests fail if release docs, security policy, or workflow files drift from the supported preview posture.
- [x] **POST-03**: The next protocol-expansion milestone is documented as PAR, but PAR is not implemented and not supported during v1.1.

## v1.2 Requirements

### Advanced OAuth Surface

- **PAR-01**: Provider supports pushed authorization requests as an extension of the existing authorization code + PKCE flow.
- **PAR-02**: Discovery metadata advertises PAR support truthfully.
- **PAR-03**: PAR lifecycle behavior is covered by protocol, security, and integration tests before broader v2 candidates are considered.

## Out of Scope

| Feature | Reason |
|---------|--------|
| PAR implementation in v1.1 | Chosen as the next rough milestone only after release hardening lands, so it remains not implemented and not supported in v1.1 |
| Dynamic client registration | Expands trust, policy, and operator complexity beyond the current polish goal |
| Device authorization flow | Introduces a new interaction model while release hardening is still unfinished |
| Sender-constrained token modes | Valuable later, but not the highest-leverage next step for current velocity |
| Stable `1.0` claim before repeated green gates | Public claims must follow proof, not precede it |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GATE-01 | Phase 10 | Pending |
| GATE-02 | Phase 10 | Pending |
| GATE-03 | Phase 10 | Pending |
| RELS-01 | Phase 11 | Pending |
| RELS-02 | Phase 11 | Pending |
| RELS-03 | Phase 11 | Pending |
| POST-01 | Phase 9 | Complete |
| POST-02 | Phase 9 | Complete |
| POST-03 | Phase 9 | Complete |

**Coverage:**
- v1.1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-23*
*Last updated: 2026-04-24 after milestone audit reopened release-hardening gaps and assigned closure to phases 10-11*
