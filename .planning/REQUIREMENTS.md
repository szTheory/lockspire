# Requirements: Lockspire v1.45 DCR Lifetime Enforcement

**Defined:** 2026-10-20
**Status:** Scope approved by user; roadmap approval pending.
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Milestone Requirements

The user approved all eight outcome areas on 2026-10-20. The atomic requirements below expand that scope without selecting unresolved expiry policy. Historical DCR-01 is the umbrella lifetime-enforcement backlog item; DCR-02 through DCR-19 provide this milestone's traceable acceptance requirements.

Phase 162 must select and record semantics and upgrade compatibility before any implementation plan for subsequent phases. Scope approval does not itself select new global timeouts, automatic backfills or rejection rules. Every implementation slice carries its own tests; final proof adds cross-phase evidence.

### Semantics and compatibility design

- [ ] **DCR-02**: A host maintainer can consult one selected decision matrix for unset, zero and positive values for all three lifetimes, clock precision, exact expiry boundaries, policy-change timing and rotation renewal rules.
- [ ] **DCR-03**: A host maintainer can identify the selected effect of app expiry on every applicable authorization, token, refresh, management and issued-token path, including protocol error mappings and offline verification limits.
- [ ] **DCR-04**: An upgrading host has a selected compatibility contract covering ambiguous legacy secret dates, custom storage, migration and activation ordering, mixed-version nodes and rollback limits before implementation planning begins.

### App lifetime and host storage

- [ ] **DCR-05**: A newly registered app stores and uses its effective lifetime according to the selected contract, with distinct disabled and expired behavior where the contract requires it.
- [ ] **DCR-06**: A host can rely on app expiry being checked consistently across applicable existing protocol paths, with issued tokens handled exactly as selected in DCR-03 and without depending on worker scheduling.
- [ ] **DCR-13**: An existing host can upgrade representative legacy registrations under the selected compatibility contract without deriving unapproved rejection deadlines from ambiguous historical dates.
- [ ] **DCR-14**: A fresh generated host and a host using custom client storage can satisfy the lifetime contract through documented schema and storage changes, with unsupported capabilities handled explicitly.

### Client-secret lifetime

- [ ] **DCR-07**: An app receiving a shared secret gets stored and advertised secret expiry that matches its effective policy, including unlimited and non-secret cases.
- [ ] **DCR-08**: A client using Basic, post or secret-JWT authentication is accepted or rejected consistently according to secret expiry, while independent JWT assertion timing and replay protection remain enforced.
- [ ] **DCR-09**: An operator can rotate a shared secret with its replacement expiry committed atomically, with prior-credential and changed-policy behavior matching the selected contract.

### App-management-token lifecycle

- [ ] **DCR-10**: An app receives an app-management token whose stored lifecycle matches the selected policy, including any chosen finite or unlimited lifetime.
- [ ] **DCR-11**: A client can read, update and delete its registration according to the selected management-token and app lifecycle, and an authorized host operator has the documented recovery path when management access is lost.
- [ ] **DCR-12**: A management-token rotation commits the replacement hash and lifecycle together and handles stale credentials and competing requests according to the selected transaction contract.

### Proof, safety and guidance

- [ ] **DCR-15**: A maintainer can reproduce deterministic before/at/after-expiry checks for all three lifetimes, unset/zero/positive settings, policy changes, rotation and disabled/expired registrations.
- [ ] **DCR-16**: A maintainer can reproduce real PostgreSQL races and failed-write rollback checks for expiry, disablement and credential rotation without stale authorization restoring an invalid credential.
- [ ] **DCR-17**: An adopter can complete an executable packaged clean-room registration-to-use-to-expiry/rotation journey, with fresh-install, legacy-upgrade and custom-storage evidence linked to the selected contract.
- [ ] **DCR-18**: A maintainer can verify that the changed protocol, storage and host surfaces preserve established security defaults and redaction, with required CI and a scoped security review passing before merge.
- [ ] **DCR-19**: An operator or host developer can follow configuration, storage, migration and rotation guidance whose expiry claims match verified behavior; changed admin wording follows PRODUCT.md vocabulary and retired-wording contracts.

## Future Requirements

- KEK-04: KMS/Vault key-set provider (separate key-management scope).
- SEC-01: Dedicated secret-JWT verifier encryption key (separate security design).
- Paged signing-key re-encryption dry-run (separate operator maintenance).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Hosted auth, federation, SAML or LDAP | Preserve the embedded companion-library boundary |
| Host accounts, login UX and branding ownership changes | Existing host seam stays narrow |
| Unrelated grants, admin redesign or broad dependency upgrades | Not required for lifetime enforcement |
| Repeating the completed Phase 153 audit | Reuse the evidence; trace only additional consumers required by the new contract |
| Automatic universal timeout or guessed legacy backfill | Must be explicitly selected through Phase 162's compatibility design |
| Package publication | Separate verified release step after implementation |
| Altering old verification exceptions or deleting historical phase records | Unrelated history is preserved |

## Inputs

- [Approved scope](research/dcr-lifetimes/SCOPE.md)
- [Focused research](research/dcr-lifetimes/SUMMARY.md)
- [Completed Phase 153 audit](milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md)

## Traceability

To be populated during roadmap creation; every requirement will have exactly one owning phase.

| Requirement | Phase | Status |
|-------------|-------|--------|

**Coverage:** 18 requirements; roadmap mapping pending.

*Last updated: 2026-10-20 after user requirements approval.*
