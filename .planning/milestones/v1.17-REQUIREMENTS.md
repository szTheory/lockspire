# Requirements: Lockspire v1.17 — Real Public Release

**Status:** Draft
**Defined:** 2026-05-07
**Milestone:** v1.17 Real Public Release
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Milestone goal:** Turn Lockspire's repo-aligned `1.0.0` support story into an actual public release, prove the trusted publish lane end to end, and leave maintainers with a clean post-release truth state that matches what users can install from Hex.

## v1.17 Requirements

Each requirement is atomic, testable, and traceable to a phase. Phase numbering continues from v1.16 (closed at Phase 66); v1.17 starts at Phase 67.

### Release Execution

- [ ] **REL-01**: Maintainers can produce one approved release candidate for Lockspire whose version, changelog entry, tag, and published package metadata all describe the same shipped `1.0.0` surface.
- [ ] **REL-02**: The trusted publish lane can be executed without undocumented manual steps beyond the protected credentials and approval boundaries already declared in repo-owned maintainer guidance.
- [ ] **REL-03**: The release cut preserves Lockspire's embedded-library support boundary and does not widen the shipped contract through ad hoc release notes or emergency packaging exceptions.

### Publish Verification

- [ ] **PUB-01**: After publish, maintainers can verify that Hex package metadata, docs pointers, and release artifacts match the repo's canonical support contract.
- [ ] **PUB-02**: Post-publish verification proves that a Phoenix maintainer can discover and install the released Lockspire package using the documented embedded host path without contradictory version or support signals.

### Post-Release Truth & Closure

- [ ] **POST-01**: Maintainer-facing release records capture what was published, what evidence proved it, and any explicitly deferred follow-up work without relying on oral history.
- [ ] **POST-02**: Project planning state, release guidance, and milestone closure artifacts all agree on what `v1.17` shipped and what remains for later milestones.

## Future Requirements

Acknowledged but deferred beyond v1.17.

### Future Adoption & Surface Work

- **ADOPT-FUT-01**: Add another narrow embedded-adoption wedge only after the real public release is cut and the post-release support story is stable.
- **AUTH-FUT-01**: `client_secret_jwt` support with a truthful security posture that does not weaken current secret handling.
- **CONF-FUT-01**: Broader external certification or corroboration work once the published release cadence is routine.

## Out of Scope

Explicitly excluded to keep v1.17 narrow and coherent.

| Feature | Reason |
|---------|--------|
| New OAuth or OIDC protocol families | `v1.17` is about publishing the already-shipped surface, not widening it before the first real release cut. |
| Lockspire-owned hosted auth or login UX | The embedded-library boundary remains the product thesis and should not be blurred during release work. |
| Broad documentation rewrite unrelated to release truth | Only release-blocking or publish-truth corrections belong in this milestone. |
| New support claims not backed by shipped repo proof and published artifacts | The milestone exists to reduce trust debt, not to create another round of it. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 67 | Pending |
| REL-02 | Phase 67 | Pending |
| REL-03 | Phase 67 | Pending |
| PUB-01 | Phase 68 | Pending |
| PUB-02 | Phase 68 | Pending |
| POST-01 | Phase 69 | Pending |
| POST-02 | Phase 69 | Pending |

**Coverage:**
- v1.17 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0
