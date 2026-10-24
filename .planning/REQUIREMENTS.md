# Requirements: Lockspire

**Milestone:** v1.46 Embedded Host Integration Reliability
**Defined:** 2026-10-22
**Status:** Requirements and roadmap approved by user on 2026-10-22
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1.46 Requirements

Requirements cover the user-confirmed mechanical integration scope. They do not introduce staff identity, protocol breadth or UI redesign. Research: [summary](research/v1.46-host-integration/SUMMARY.md).

### Admin Mounting

- [x] **MNT-01**: A Phoenix host can mount the complete admin surface through one reusable integration that defines the LiveView routes inside its own router, without copying Lockspire's route list.
- [x] **MNT-02**: Staff can open, navigate and reconnect to admin pages at the default mount and supported custom mount paths, with links, redirects and task URLs retaining the configured prefix.
- [x] **MNT-03**: Existing admin URLs keep their corresponding LiveView and action, including list/detail/new/edit and policy/rotation task routes; adopting the new integration does not silently remove routes or change their meaning.
- [x] **MNT-04**: A host can protect admin pages independently while its public OAuth/OIDC endpoints and host-owned consent routes retain their intended access and routing behavior, without being shadowed by either mount.

### Host-Owned Authorization

- [x] **HAUTH-01**: The host can enforce its staff-access policy on initial admin HTTP requests; unauthenticated and unauthorized visitors are denied before admin data is rendered or actions run.
- [x] **HAUTH-02**: The host can enforce its current staff-access policy before disconnected and connected admin mounts through an explicit LiveView authorization seam; missing required authorization wiring is refused rather than silently permitting access.
- [x] **HAUTH-03**: A visitor cannot bypass host staff checks by navigating from a public or consent LiveView into the admin surface or between admin destinations; every admin destination belongs to the protected admin session and receives its required host hooks.
- [x] **HAUTH-04**: A reconnect with an invalid session or no-longer-authorized host identity is denied by the host policy, while a currently authorized staff session reconnects successfully.

### Installation, Upgrade and Diagnostics

- [x] **HDX-01**: A newly installing host receives scaffolding and instructions for the canonical route/session integration, required host authorization and endpoint/browser wiring, without an assumed account schema or an allow-all staff-policy default.
- [x] **HDX-02**: An existing host can migrate from the generated forwarded-admin integration through explicit guidance and safe managed-file upgrade behavior; dry runs write nothing, repeat runs are safe, drift is refused and host-owned policy files are preserved.
- [x] **HDX-03**: A maintainer can use `mix lockspire.verify` to distinguish complete canonical admin route/session/hook wiring from incomplete, shadowed or legacy forward-only wiring, with actionable secret-safe guidance and an explicit limit that structural checks do not prove arbitrary host policy.
- [x] **HDX-04**: Adopters can follow consistent supported-surface, installation, admin and upgrade guidance, and the demo and maintained host fixtures consume the same reusable admin integration without duplicated live-route inventories.

### Executable Host Proof

- [x] **HPROOF-01**: Maintainers can run a packaged clean-room host journey proving connected admin operation at default and custom mounts, reconnect/navigation and denied access, alongside successful public-route access that does not require staff authentication.
- [x] **HPROOF-02**: Maintainers can run the relevant route/session, connected authorization and navigation regressions on both the current locked Phoenix/LiveView pair and the exact supported floor (Phoenix 1.8.5 / LiveView 1.1.28), with runtime evidence rather than compilation alone.
- [x] **HPROOF-03**: Required CI runs the bounded host-integration checks and reports failures with redaction-safe source-bound evidence, so acceptance does not depend on manual visual review or an untracked local workaround.

## Acceptance Boundaries

- Phase plans must reproduce the recorded forward-only connected failure before fixing it; research has inspected source and official documentation but has not freshly executed that reproduction.
- Cover the complete current path/view/action inventory and valid mount normalization. The default and a nested custom mount are mandatory; root mounting must retain its behavior if the existing supported configuration accepts it. Do not add multi-mount, reverse-proxy base-path or tenant-router support by inference.
- Staff sessions, identity resolution, MFA, roles, tenant policy and any fine-grained resource/action permissions remain host-owned. Do not treat an arbitrary session boolean or HTTP conn assign as current connected authorization.
- Authorization is required at initial request, disconnected/connected mount, reconnect and admin navigation boundaries. A mount-only check is not a promise of immediate permission revocation on an already connected socket. Host logout/disconnect and event-level policy responsibilities must be explicit in guidance; continuous reauthorization/polling and a new revocation coordinator are outside this milestone.
- Keep staff auth separate from public OAuth/OIDC and host-owned consent. Preserve the library's current protocol behavior and security defaults, including S256 PKCE, exact redirect matching, secret hashing, single-use codes, refresh-family reuse handling and redaction.
- Use focused unit/integration/lifecycle checks while building each capability. Packaged proof must consume the actual candidate artifact/templates. Real client/socket proof must cover endpoint session, browser assets and host path signing; LiveViewTest alone is not a claim of browser transport proof.
- Runtime compatibility claims name exact tested versions; no dependency upgrade is required. A static verification result describes wiring, not arbitrary application authorization correctness.
- No subjective UI signoff is required. Package publication, merging and remote ref updates are separate from implementation verification.

## Future Requirements

- **SEC-01**: Re-seal the client-secret-JWT verifier with a dedicated rotatable key instead of endpoint secret_key_base.
- **KEK-04**: Host KMS/Vault key-set provider.
- **OPS-03**: Paged keys.reencrypt dry-run and separately scoped status-read improvements.
- Remaining legacy-plaintext fixture maintenance and unrelated v1.45 accepted debt stay recorded in their existing owners; this milestone does not silently close them.

## Out of Scope

| Feature | Reason |
|---|---|
| Visual redesign, new admin workflows or vocabulary overhaul | User selected mechanical reliability work needing little attention |
| Staff account store, login UX, role engine or tenant policy | Explicit host ownership and embedded-library boundary |
| New OAuth/OIDC flows or protocol policy | Integration repair only |
| Continuous permission polling, distributed logout coordinator, new per-resource authorization engine | Separate product/design scope; document native host lifecycle responsibilities |
| KMS/Vault and client-secret-JWT key lifecycle changes | Valuable separate milestones, not dependencies of host routing |
| Multi-mount/tenant-router/proxy-prefix expansion | No newly approved support claim |
| Release publication or broad repository cleanup | Separate workflows; historical evidence and unrelated user changes are preserved |

## Traceability

Requirements confirmed by the user on 2026-10-22. Approved roadmap continues phase numbering at 167. Each of the 15 requirements maps to exactly one owning phase; integration checks in later phases supplement rather than duplicate ownership.

| Requirement | Phase | Status |
|---|---|---|
| MNT-01 | Phase 167 | Complete |
| MNT-02 | Phase 167 | Complete |
| MNT-03 | Phase 167 | Complete |
| MNT-04 | Phase 167 | Complete |
| HAUTH-01 | Phase 168 | Complete |
| HAUTH-02 | Phase 168 | Complete |
| HAUTH-03 | Phase 168 | Complete |
| HAUTH-04 | Phase 168 | Complete |
| HDX-01 | Phase 169 | Complete |
| HDX-02 | Phase 169 | Complete |
| HDX-03 | Phase 169 | Complete |
| HDX-04 | Phase 169 | Complete |
| HPROOF-01 | Phase 170 | Complete |
| HPROOF-02 | Phase 170 | Complete |
| HPROOF-03 | Phase 170 | Complete |

**Coverage:** 15 requirements defined; 15 mapped exactly once; 0 unmapped; all 15 complete across Phases 167–170. The milestone audit cross-checks traceability, phase verification and all 16 plan summaries. Evidence and limits are recorded in each phase's verification report and automated UAT closure ledger.

---
*Last updated: 2026-10-24 — milestone audit reconciled all 15 completed requirements, including HPROOF-01..03 in Phase 170.*
