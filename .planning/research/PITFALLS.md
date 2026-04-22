# Pitfalls Research

**Domain:** Embedded OAuth/OIDC authorization server library for Phoenix/Elixir
**Researched:** 2026-04-22
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Scope Creep Into a Full Identity Suite

**What goes wrong:**
The project expands from an embedded OAuth/OIDC provider into SAML, LDAP, hosted auth, theming engines, and general CIAM workflows before the core provider path is solid.

**Why it happens:**
Identity products attract adjacent requests immediately, and broad auth suites look safer than a narrow wedge on paper.

**How to avoid:**
Keep non-goals explicit in planning docs, require new scope to justify the wedge, and prioritize the smallest credible v1 that proves Lockspire's provider-side value.

**Warning signs:**
- Requirements mention SAML, social-login brokering, or hosted-service concerns
- Roadmap phases mix core protocol work with unrelated enterprise federation asks
- Install DX is slipping because the surface area keeps expanding

**Phase to address:**
Phase 1 and Phase 6

---

### Pitfall 2: Weak Host Boundary

**What goes wrong:**
Lockspire starts to own account schemas, login UX, layout decisions, or product-specific consent policy, making integration brittle and adoption narrow.

**Why it happens:**
It's tempting to "just solve the whole flow" when building a library, especially when demoing the happy path.

**How to avoid:**
Force all account and login concerns through explicit behaviours and generated host glue. Review every public API change against the host-ownership rule.

**Warning signs:**
- Library internals assume a specific user schema
- Generated code becomes thin wrappers over hidden library-owned auth logic
- Non-Sigra hosts would need adapters that feel second-class

**Phase to address:**
Phase 1

---

### Pitfall 3: Process State Becomes the Source of Truth

**What goes wrong:**
Authorization codes, refresh lineage, revocations, or key state rely too heavily on ETS, process memory, or PubSub hints and become hard to recover or inspect.

**Why it happens:**
Elixir makes process-local state easy and fast, and auth flows often start as in-memory prototypes.

**How to avoid:**
Keep durable truth in Postgres, use ETS only for bounded caches, and make every operator-relevant state transition reconstructible from durable records.

**Warning signs:**
- Revocation behavior changes after restarts or node joins
- Admin UI cannot explain current token or key state from stored records alone
- Tests require single-node assumptions to pass

**Phase to address:**
Phase 2, Phase 3, and Phase 5

---

### Pitfall 4: Operator UX Is Treated As Nice-To-Have

**What goes wrong:**
The library ships endpoints and maybe a few screens, but incident response still requires database queries or shell access because the operator surface is too shallow.

**Why it happens:**
Teams often over-prioritize protocol coverage and under-prioritize the product layer around it.

**How to avoid:**
Plan explicit admin workflows for clients, tokens, consents, keys, and audit early enough that the underlying domain model supports them cleanly.

**Warning signs:**
- Tokens can be issued but not inspected or traced
- Secret rotation or key retirement exists only as a manual task
- Audit events are emitted but not queryable in the product

**Phase to address:**
Phase 4 and Phase 5

---

### Pitfall 5: Release Readiness Arrives Too Late

**What goes wrong:**
The code "works," but the library lacks executable docs, negative-path coverage, conformance planning, release workflow discipline, or an honest operator boundary.

**Why it happens:**
Release hygiene often gets deferred until the end, when protocol and UI work have already consumed the schedule.

**How to avoid:**
Treat docs, CI, changelog, release flow, and conformance lanes as product work from the start and reserve a dedicated roadmap phase for them.

**Warning signs:**
- Demos pass but failure-mode tests are thin
- There is no canonical onboarding path
- Release steps depend on maintainer memory instead of versioned workflow

**Phase to address:**
Phase 5 and Phase 6

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hard-coding one host auth shape | Faster first demo | Makes adoption narrow and rewrites likely | Never |
| Using in-memory-only state for durable protocol artifacts | Faster implementation | Breaks operability, restarts, and multi-node correctness | Only for explicitly bounded caches |
| Shipping admin UI without token/key lineage | Faster screens | Incident response still requires shell access | Never for v1 operator goals |
| Deferring executable docs until after protocol work | Reduces early writing | Makes install DX and support posture weak at launch | Only if Phase 6 is protected and not descoped |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Host authentication | Assuming one user/session model | Use explicit behaviours and generated host-owned glue |
| Redirect handling | Allowing partial or wildcard URI matching | Exact-match validation with narrowly defined localhost exceptions |
| Telemetry | Logging secrets or raw tokens | Emit structured redacted metadata and persist operator-safe identifiers |
| Background work | Making key rotation or cleanup manual | Use durable jobs with clear visibility and retries |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Over-querying token or audit data without operator-focused indexes | Admin screens degrade quickly | Design queryable lineage and filter paths early | As operator usage grows beyond basic demos |
| Treating revocation as only an in-memory concern | Cross-node inconsistency and restart bugs | Store revocation truth durably and use runtime caches as hints | At multi-node or even during routine restarts |
| Building everything as synchronous request work | Slow admin actions and fragile key rotation | Offload lifecycle and cleanup jobs to Oban where appropriate | As token volume and maintenance work increase |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Weak redirect URI validation | Open redirect and code theft | Exact-match redirect rules and test matrices |
| Refresh reuse without family-wide handling | Stolen refresh tokens remain useful | Rotate every use and revoke the family on reuse detection |
| Secrets visible in logs or admin surfaces | Credential leakage | Hash at rest, show plaintext once, redact everywhere else |
| Treating public clients as low-risk by default | Consent bypass or weak auth handling | Keep strict defaults and explicit downgrade policies |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Operator UI reads like marketing copy | Low trust during incidents | Use brief, exact, low-anxiety language |
| Consent screens hide what is being granted | End-users cannot make informed decisions | Show clear client identity, scopes, and revoke paths |
| Admin workflows require CLI follow-up | Operators feel the product is incomplete | Make core remediations possible in-product |

## "Looks Done But Isn't" Checklist

- [ ] **Authorization flow:** often missing denial, replay, and mismatch coverage — verify negative-path tests, not only happy-path demos
- [ ] **OIDC surface:** often missing issuer, audience, or nonce correctness — verify metadata and token validation contracts
- [ ] **Operator UI:** often missing actionable token/key state — verify incident workflows without shell access
- [ ] **Install DX:** often missing a real end-to-end host path — verify a fresh Phoenix app can complete setup cleanly
- [ ] **Release posture:** often missing documented publish discipline — verify CI, changelog, docs, and release gates exist

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Scope creep | HIGH | Freeze non-goals, cut roadmap back to the wedge, reclassify speculative features into v2 or out-of-scope |
| Weak host boundary | HIGH | Extract behaviours, move host-specific logic into generated modules, and deprecate takeover APIs |
| In-memory truth | HIGH | Introduce durable records, migration path, rebuild admin/query layers from persisted state |
| Shallow operator UX | MEDIUM | Add domain queries, lineage models, and focused LiveViews tied to real workflows |
| Late release hardening | MEDIUM | Reserve a dedicated release-readiness phase and block public release until it lands |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Scope creep into full identity suite | Phase 1, Phase 6 | Requirements and roadmap keep non-goals explicit; v1 remains focused |
| Weak host boundary | Phase 1 | Host seam behaviour exists and generated code owns product-specific glue |
| Process state becomes source of truth | Phase 2, Phase 3, Phase 5 | Token, key, and revocation behavior can be explained from durable records |
| Operator UX treated as optional | Phase 4, Phase 5 | Core incident workflows are available in-product |
| Release readiness arrives too late | Phase 5, Phase 6 | Negative-path tests, docs, CI, and release flows are present before launch |

## Sources

- `lockspire-idea.md`
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md`
- `prompts/lockspire-security-posture-and-threat-model.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-release-readiness-and-conformance.md`

---
*Pitfalls research for: Embedded OAuth/OIDC authorization server library for Phoenix/Elixir*
*Researched: 2026-04-22*
