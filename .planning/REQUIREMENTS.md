# Requirements: Lockspire v1.47

**Milestone:** OAuth/OIDC Core Interoperability & Hardening
**Defined:** 2026-10-24
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Scope authority:** User-approved direction and autonomous scoped research/synthesis; [scope and decisions](research/v1.47-core-hardening/SCOPE.md).

## v1.47 Requirements

### Baseline and Finding Qualification

- [x] **BASE-01**: Maintainer can start product implementation from a fresh accepted main baseline after reviewed prior-delivery reconciliation, with exact SHA, complete local contributor checks, matching canonical CI/Release no-publish evidence, and explicit worktree/edit ownership.
- [x] **BASE-02**: Maintainer can run the selected existing conformance profiles with explicit provider/package, suite, image/helper and plan identities; missing or obsolete inputs fail visibly and any input update is reviewed separately from protocol corrections.
- [x] **FIND-01**: Maintainer can inspect a finite redacted ledger attributing each selected historical/current finding to protocol behavior, harness/transport/browser setup, infrastructure, unsupported scope or already-correct/not-reproduced behavior, with normative/support references and a next owner.
- [x] **FIND-02**: Downstream implementers can use a qualified case matrix that fixes expected outcomes, repro commands, regression owners and exclusions before dependent implementation plans are created or executed; qualification that removes the corrective premise explicitly narrows/replans the milestone.

### Authorization Responses

- [x] **AUTHR-01**: A client receives the applicable safe response for each qualified authorization-error case, preserving exact registered-redirect validation and returning no attacker-controlled redirect for an invalid client/redirect combination.
- [x] **AUTHR-02**: A client receives the specified error/state and supported response-mode representation for each selected valid-callback case, with reserved/error parameters encoded unambiguously and adversarial cases covered.
- [x] **AUTHR-03**: A client using selected prompt=none or max_age cases receives the applicable protocol outcome and authentication-freshness claims without an inappropriate host login redirect, while account/session authority stays host-owned.

### PAR and Profile Boundaries

- [x] **PARB-01**: A client using selected pushed-request cases observes the supported client binding, expiry and one-use semantics; invalid, mismatched or reused references fail according to the qualified contract.
- [x] **PARB-02**: A client receives the qualified outcome for selected pushed-versus-front-channel parameter conflicts and required-PAR profile cases, preserving existing PKCE and security-profile boundaries.
- [x] **PARB-03**: A host/integrator can distinguish public issuer/TLS/proxy/browser-harness failures from the selected PAR/profile assertions, with advertised endpoints and tested configured surface agreeing for those cases.

### Proof and Delivery

- [x] **CPROOF-01**: Each selected supported behavior has a deterministic automated owner and each actual correction has a failing-before/passing-after regression plus applicable negative/security proof; already-correct behavior reuses valid evidence.
- [x] **CPROOF-02**: A packaged embedded Phoenix host demonstrates the selected client-visible authorization/PAR outcomes at recorded source/package identities; supplemental external results retain their exact classifications and imply neither certification nor a new full-suite release gate.
- [x] **DELIV-01**: Maintainer can review a source-bound milestone verification/audit, focused security review and passing required candidate contributor/CI checks; support/guidance changes match delivered behavior and unresolved external limits remain explicit.
- [x] **DELIV-02**: The next run can resume from a dated handoff recording integration/main acceptance, owned worktree/resource cleanup or explicit remaining blockers, preserved unknown work, and a refreshed ranked milestone roadmap with sources and triggers.

## Acceptance Rules

Phase 171 must enumerate the finite cases for AUTHR/PARB and select the actual downstream scope before implementation plans fan out. These IDs do not assert present bugs or preselect a changed policy. An existing correct implementation may satisfy a case through current evidence; do not invent code changes or duplicate tests. If a slice is unsupported, unobservable, already fully covered or no longer valuable, amend requirements/roadmap explicitly with a reason rather than silently counting a gap as passed.

Every selected case needs its applicable automated evidence. An infrastructure failure is not a protocol pass. External-suite success remains supplemental and non-certifying; full FAPI plan success is not required by implication. Preserve S256 PKCE, exact redirects, hashed client secrets, single-use short-lived codes, refresh rotation/family reuse revocation, no implicit flow, no alg=none, redaction and narrow host ownership.

## Qualification-driven scope reconciliation (2026-10-24)

All six authorization/PAR requirements remain pending. Phase 171 qualifies the following cases without marking downstream behavior accepted: AUTHR-01 reuses A171-001; AUTHR-02 reuses A171-002 and retains A171-003 as a correction; AUTHR-03 reuses A171-004, A171-005 and A171-006; PARB-01 reuses P171-001, P171-002 and P171-003; PARB-02 reuses P171-004 and retains P171-005 as a correction; PARB-03 reuses P171-006 source-host metadata proof. See the frozen Phase 171 matrix for exact requests, expected projections, evidence identities and owners.

The A171-003 correction is limited to unsupported `response_mode` returning HTTP 400 without OAuth Error Response parameters. The P171-005 correction is limited to a valid pushed reference using pushed `openid email` despite outer `scope=profile`; the linked-clause interpretation is documented in `171-QUALIFICATION-DECISIONS.md`. Existing proofs carry forward without duplicate corrections. Neither unavailable optional profile wrapper is treated as product evidence or as a selected-case blocker. CPROOF-01/02 and DELIV-01/02 remain for Phase 174, including each actual correction's RED/GREEN proof, applicable negative/security coverage and packaged-host proof.

## Future Requirements and Triggers

- **SEC-01**: Preferred provisional v1.48 — dedicated-purpose rotatable verifier encryption with explicit legacy read/rewrap, mixed-node compatibility, key-loss recovery and package upgrade proof. Settle its design in that milestone.
- **TLR-CANDIDATE**: Token lifecycle resilience only after a current counterexample or material uncovered supported-store/concurrency invariant.
- **OPS-03**: Paged key-maintenance dry-run/status work only after measured scale/operator evidence.
- **KEK-04**: Host-controlled KMS/Vault provider only after concrete adopter custody and outage requirements.
- Existing fixture maintenance, archived verification/debt and pending release/integration obligations retain their original owners; they are not silently closed here.

## Out of Scope

| Scope | Reason |
|---|---|
| New flows, all-extension audit, broader FAPI or certification claims | Selected supported interoperability cases only |
| Dedicated verifier-key persistence migration, KMS/Vault | Separate security design and rollout milestone |
| Refresh retry grace, grant-family rewrites, speculative performance | Requires a concrete finding and explicit policy decision |
| UI redesign, subjective visual review, account/login/claim-policy ownership | Protocol hardening and embedded host boundaries |
| Unnecessary dependencies or a second general testing framework | Reuse current tools and small auditable glue; vetted security primitives retained |
| Manual package publication or release ownership changes | Normal development/Release Please/protected train remains authoritative |

## Traceability

All 14 requirements map to exactly one of phases 171–174. Conditional scopes must be reconciled at qualification before dependent planning; later milestone candidates have no reserved phase numbers.

| Requirement | Phase | Status |
|---|---|---|
| BASE-01 | Phase 171 | Complete |
| BASE-02 | Phase 171 | Complete |
| FIND-01 | Phase 171 | Complete |
| FIND-02 | Phase 171 | Complete |
| AUTHR-01 | Phase 172 | Complete |
| AUTHR-02 | Phase 172 | Complete |
| AUTHR-03 | Phase 172 | Complete |
| PARB-01 | Phase 173 | Complete |
| PARB-02 | Phase 173 | Complete |
| PARB-03 | Phase 173 | Complete |
| CPROOF-01 | Phase 174 | Complete |
| CPROOF-02 | Phase 174 | Complete |
| DELIV-01 | Phase 174 | Complete |
| DELIV-02 | Phase 174 | Complete |

---
*Defined 2026-10-24. No runtime correction or implementation acceptance is claimed by planning.*
