---
phase: 09
slug: preview-posture-lock
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-24
---

# Phase 09 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| public docs -> adopters | Untrusted readers infer current capability and support commitments from public documentation. | Support commitments, protocol-surface claims |
| maintainer docs -> release claims | Release guidance can accidentally broaden what the repo is said to prove. | Release-readiness and trust claims |
| onboarding guide -> host app expectations | Installation guidance can blur the host-owned seam or imply unsupported deployment shapes. | Integration responsibilities and ownership boundaries |
| public docs -> contract tests | Drift is only caught if trust-bearing public posture is encoded in executable checks. | Repo-truth phrases that define preview support |
| planning metadata -> public posture | Future protocol work can leak into current support-facing language. | Roadmap intent, future PAR posture |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-09-01 | T | README.md, docs/supported-surface.md | mitigate | `docs/supported-surface.md` is the canonical preview contract and README is reduced to a referential summary. Verified in current docs and by `mix docs.verify`. | closed |
| T-09-02 | I | SECURITY.md, docs/install-and-onboard.md, docs/maintainer-release.md | mitigate | Each doc is limited to its owned claims and refers back to the canonical support contract and repo-owned proof. Verified in current docs and by `mix docs.verify`. | closed |
| T-09-03 | R | public preview posture | mitigate | Public proof is tied to checked-in tests and workflows rather than demo-app or certification claims. Verified in `docs/supported-surface.md`, `docs/install-and-onboard.md`, `docs/maintainer-release.md`, and the release-readiness contract test. | closed |
| T-09-04 | E | public product framing | accept | Future `1.0` posture remains documented only as bounded guidance in `docs/supported-surface.md` and does not expand current `v0.1` capability claims. | closed |
| T-09-05 | T | test/lockspire/release_readiness_contract_test.exs | mitigate | Contract sentinels now cover preview-only claims, secure defaults, disclosure path, and PAR-negative assertions. Verified by `mix test test/lockspire/release_readiness_contract_test.exs`. | closed |
| T-09-06 | R | .planning/PROJECT.md, .planning/ROADMAP.md, .planning/REQUIREMENTS.md | mitigate | Planning metadata records PAR as future-facing only and explicitly not implemented or supported in `v1.1`. Verified in current planning artifacts and contract tests. | closed |
| T-09-07 | I | README.md, docs/supported-surface.md, SECURITY.md, docs/maintainer-release.md | mitigate | Cross-file checks fail if support-facing docs imply PAR or broader protocol support than planning truth allows. Verified by the release-readiness contract test. | closed |
| T-09-08 | D | contract-test maintainability | accept | The phase intentionally uses narrow phrase-level sentinels instead of snapshot locking; purely stylistic drift may pass, but this is accepted to keep tests reviewable and stable. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-09-01 | T-09-04 | Future `1.0` guidance remains in docs, but it is explicitly bounded as posture guidance and does not claim current support expansion. | Phase 09 threat model | 2026-04-24 |
| AR-09-02 | T-09-08 | Narrow contract tests may miss editorial-only drift, but broader snapshot assertions were intentionally rejected to avoid brittle trust checks. | Phase 09 threat model | 2026-04-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-24 | 8 | 8 | 0 | Codex (`$gsd-secure-phase 09`) |
| 2026-04-24 | 8 | 8 | 0 | Codex (`$gsd-secure-phase 09`, revalidation) |

Verification evidence used for this audit:

- `mix docs.verify`
- `mix test test/lockspire/release_readiness_contract_test.exs`
- `rg -n 'PKCE S256|required by default|exact-match redirect URI|hashed at rest|single-use|revocation on reuse|no implicit flow|no \`alg=none\`' SECURITY.md docs/supported-surface.md`
- `rg -n 'PAR' README.md docs/supported-surface.md SECURITY.md docs/install-and-onboard.md docs/maintainer-release.md`
- Current review of `README.md`, `docs/supported-surface.md`, `SECURITY.md`, `docs/install-and-onboard.md`, `docs/maintainer-release.md`, `test/lockspire/release_readiness_contract_test.exs`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md`

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-24
