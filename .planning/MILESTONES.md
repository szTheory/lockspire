# Milestones

## v1.5 Dynamic Client Registration (Shipped + archived: 2026-04-27)

**Phases completed:** **5** (**25-29**), **27** requirements mapped and closed.

**Key accomplishments:**

- Added full RFC 7591/7592 dynamic client registration lifecycle.
- Implemented operator policy controls and Initial Access Tokens.
- Truthful discovery and security documentation.

## v1.4 JAR and Request Objects (Shipped + archived: 2026-04-26)

**Phases completed:** **4** (**21-24**), **18** plans, **5** shipped requirements (**JAR-01**, **JAR-02**, **JAR-03**, **JAR-05**, **JAR-06**); **JAR-04** remains deferred.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the verified JAR request-object slice on top of the earlier PAR and PAR-policy work.

**Key accomplishments:**

- Added signed JAR request-object support with client-key signature validation and RFC 9101 claim checks.
- Integrated request objects into the existing authorization-code, PAR, and browser-boundary flow without widening the embedded-library shape.
- Published truthful JAR discovery and operator policy controls for the shipped request-object slice.
- Closed the milestone with explicit verification, validation, and traceability evidence while preserving JAR-04 as deferred.

**Pre-close audit:** `audit-open` clear. Formal milestone validation: [`.planning/phases/24-verification-and-milestone-closure/24-VALIDATION.md`](phases/24-verification-and-milestone-closure/24-VALIDATION.md) (`passed` with JAR-04 deferred and no boundary drift).

**Archives:** `milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md` · **Git tag:** `v1.4`

---

## v1.2 PAR Foundation (Shipped + archived: 2026-04-24)

**Phases completed:** **3** (**14-16**), **8** plans, **5** requirements (**PAR-01**-**PAR-04**, **RELS-04**)

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the narrow PAR wedge and a checked-in Release Please path on a supported runtime.

**Key accomplishments:**

- Added durable hash-only PAR intake plus a mounted `POST /par` endpoint that reuses existing client-auth and validation seams.
- Extended `/authorize` to consume Lockspire-issued PAR references with expiry, client binding, replay resistance, and unchanged auth-code + PKCE semantics.
- Locked discovery, docs, SECURITY wording, and repo-truth contract tests to the exact shipped PAR slice.
- Closed `PAR-04` traceability and removed the deferred Release Please Node 20 runtime warning by moving to a repo-controlled Node 24 composite action.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md) (`passed` with no requirement, integration, flow, or Nyquist gaps).

**Automation note:** `gsd-sdk query milestone.complete` remains unreliable, so the close again used manual `milestones/v1.2-*` artifacts, `ROADMAP.md` collapse, and `git rm .planning/REQUIREMENTS.md`.

**Archives:** `milestones/v1.2-ROADMAP.md`, `milestones/v1.2-REQUIREMENTS.md`, `milestones/v1.2-MILESTONE-AUDIT.md` · **Git tag:** `v1.2`

---

## v1.1 Release Hardening (Shipped + archived: 2026-04-24)

**Phases completed:** **7** (**07-13**), **15** plans, **9** requirements (**GATE-01**-**GATE-03**, **RELS-01**-**RELS-03**, **POST-01**-**POST-03**)

**Package posture:** `lockspire 0.2.0` exists at archive time; planning milestone complete, but public product posture remains preview rather than `1.0`.

**Key accomplishments:**

- Repo-truth QA and contributor gate recovery closed the maintained `mix qa`/`mix ci` drift and backfilled formal gate verification.
- Trusted release hardening locked the checked-in publish policy, maintainer guide, protected environment proof, and approved canonical run evidence.
- Preview-support docs and contract tests now keep public claims bounded to the implemented embedded-provider wedge while leaving PAR as the next milestone candidate only.
- Final verification and ledger-reconciliation phases closed the remaining audit handoff gaps without reopening release implementation.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md) (`tech_debt` for Nyquist completeness gaps and the `release-please-action` Node.js 20 warning only).

**Automation note:** `gsd-sdk query milestone.complete` failed again (`version required for phases archive`), so the close used manual `milestones/v1.1-*` artifacts, `ROADMAP.md` collapse, and `git rm .planning/REQUIREMENTS.md`.

**Archives:** `milestones/v1.1-ROADMAP.md`, `milestones/v1.1-REQUIREMENTS.md`, `milestones/v1.1-MILESTONE-AUDIT.md` · **Git tag:** `v1.1`

---

## v1.0 Embedded OAuth/OIDC Provider Foundation (Shipped + archived: 2026-04-23)

**Phases completed:** **6** (**01-06**), **25** plans

**Archives:** `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md` · **Git tag:** `milestone/v1.0`
