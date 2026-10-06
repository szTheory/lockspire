# Requirements: Lockspire

**Defined:** 2026-10-06
**Milestone:** v1.39 Verified 1.5.1 Release
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1 Requirements

Requirements for the v1.39 release milestone. Each maps to exactly one roadmap phase.

### Release Truth

- [ ] **TRUTH-06**: Maintainer can merge the corrected Phase 141 release record through the reviewed PR path and keep 1.5.0 identified as the latest public package until public proof for 1.5.1 exists.

### Main Readiness

- [ ] **CI-09**: Maintainer can verify that required CI and the repository-hygiene check pass for the exact current `main` revision before release; every reported warning has an explicit disposition.

### Protected Publication

- [ ] **REL-01**: Maintainer can publish Lockspire 1.5.1 only through the protected release workflow for the exact current `main` SHA with its matching successful canonical CI run.
- [ ] **REL-02**: Maintainer can verify that the public Hex package checksum matches the workflow's manifest-bound artifact, the `lockspire-v1.5.1` GitHub release targets the same source, and the clean-room public install journey passes.
- [ ] **REL-03**: If a release gate fails, maintainer can preserve its evidence and record the blocker without claiming 1.5.1 shipped or closing the milestone.

## Future Requirements

No additional release automation or product capability is planned by this milestone.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New OAuth/OIDC capability, host seam, or admin surface | v1.39 corrects release truth and publishes an already-prepared patch; it does not expand Lockspire's product surface. |
| A new release platform or replacement publishing workflow | The repository already has a protected exact-SHA lane that builds, verifies, publishes, and checks public install truth. |
| Manual edits to release-owned version metadata, tags, or package contents | Release Please and the protected release workflow own those changes. |
| Manual UAT for behavior already proven by required CI and the protected clean-room release journey | Repeatable checks are the acceptance evidence; human attention is reserved for judgments those checks cannot establish. |
| Supplemental OIDF/FAPI certification or pass requirements | These remain supplemental, non-certifying evidence and are not a 1.5.1 release gate. |
| Non-critical dependency refreshes or a broad Dependabot campaign | They are unrelated to this release and remain outside the approved milestone scope. |

## Traceability

Populated during roadmap creation. Every v1.39 requirement maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TRUTH-06 | Pending | Pending |
| CI-09 | Pending | Pending |
| REL-01 | Pending | Pending |
| REL-02 | Pending | Pending |
| REL-03 | Pending | Pending |

**Coverage:**
- v1 requirements: 5 total
- Mapped to phases: 0
- Unmapped: 5

---
*Requirements defined: 2026-10-06*
*Last updated: 2026-10-06 after v1.39 requirements definition*
