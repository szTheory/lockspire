# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled. Residual tech debt is limited to missing `10/12/13-VALIDATION.md` files and the `release-please-action` Node 20 deprecation warning.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks. Public release posture remains `v0.1` preview pending repo-wide QA cleanup, trusted Hex publish verification, and repeated green release gates.

## No Active Milestone

The `v1.1 Release Hardening` milestone is now archived. The next planning step is to start a fresh milestone definition rather than keep growing the rolling `REQUIREMENTS.md` file.

## Next Milestone Candidate

### v1.2 PAR Foundation

**Status:** Not started; define fresh requirements with `$gsd-new-milestone`
**Candidate scope:** Extend the existing authorization-code + PKCE path with pushed authorization requests while preserving the embedded-library shape and the release-trust posture established in v1.1.

**Default goals**

- Add PAR as a narrow extension of the existing embedded provider flow.
- Keep discovery and support-facing docs honest about exactly what PAR behavior exists.
- Maintain the trusted preview release path while upgrading the pinned `release-please-action` before the GitHub Node.js 20 cutoff.
- Continue to keep dynamic registration, device flow, sender-constrained tokens, and broader CIAM expansion out of the immediate milestone.

## Deferred Tech Debt

- Add `10-VALIDATION.md`, `12-VALIDATION.md`, and `13-VALIDATION.md` if full Nyquist completeness is required before or during the next milestone.
- Upgrade the pinned `googleapis/release-please-action` before GitHub retires the Node.js 20 action runtime.

## Reference

- Milestone archive: [`.planning/milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Latest archive set: [`.planning/milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md), [`.planning/milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md), [`.planning/milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
