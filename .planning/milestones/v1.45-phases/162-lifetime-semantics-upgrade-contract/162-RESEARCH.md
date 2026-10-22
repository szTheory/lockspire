# Phase 162: Lifetime Semantics & Upgrade Contract - Research

**Researched:** 2026-10-20  
**Domain:** OAuth/OIDC dynamic client registration lifetime policy, protocol contract design, and Elixir/Phoenix host upgrade compatibility  
**Confidence:** HIGH for selected requirements and standard constraints; MEDIUM for acceptance details pending Phase 162 deliverable verification

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Policy, time and independent lifecycles

- **D-01:** For each of app lifetime, client-secret lifetime and app-management-token lifetime, unset/nil and duration zero mean unlimited. A positive integer means seconds from the relevant issuance event. There is no invented finite default and zero never means immediate expiration. Configuration duration semantics are a Lockspire choice; RFC 7591's wire timestamp zero is a separate rule.

| Lifetime | nil / 0 | Positive N | Renewal event |
|---|---|---|---|
| DCR app | Unlimited | Registration time + N | None in this milestone; create a new registration after expiry |
| Shared secret | Unlimited | Secret issuance time + N | Explicit secret rotation |
| App management token | Unlimited | Token issuance time + N | Successful management PUT or authorized host rotation |

- **D-02:** Capture effective policy at issuance. Later policy edits affect new registrations and replacement credentials only. Read/authentication never renews anything. PUT replaces mutable metadata and rotates the management token, preserving app and secret deadlines. Secret rotation preserves app and management-token deadlines. Host management-token recovery preserves app and secret deadlines. Enabling an app does not clear an expired deadline. No automatic app renewal, retrospective recomputation, or background deadline extension.
- **D-03:** Apply DCR defaults to DCR registrations and their replacement credentials, using existing registration provenance. Direct/operator registrations retain their existing policy boundary; sharing a client struct does not make them DCR registrations. Shared-secret policy is inapplicable when there is no shared secret, including public/private-key/mTLS methods.
- **D-04:** Accept nil or integers 0..2_147_483_647 at every supported policy write boundary. Reject malformed, negative or excessive values consistently, including programmatic writes. Corrupt policy or unsupported lifetime state fails as configuration/server error, never as unlimited or a misleading credential rejection.
- **D-05:** Persist authoritative deadlines as UTC whole seconds. A finite object is eligible strictly while `now < deadline`; equality is expired. No credential/app-expiry leeway borrowed from JWT assertion skew. Use the existing injectable clock, propagated to all consumers. For a guarded mutation, sample its effective decision time after any blocking lock/current-row reload; an ingress or transaction-start timestamp must not authorize a write after the deadline. One captured decision time establishes that operation's replacement dates and checks.

#### App expiry, consumers and tokens

- **D-06:** App expiry is request-time eligibility, distinct from explicit disablement and deletion. Preserve registration, consent and audit history. Workers/pruners are not enforcement. All relevant consumers must check enabled state as well as the selected deadline, including clients without secrets. Recheck at authorization completion and token-producing persistence boundaries; a previously accepted request or queued worker is not continuing authority.
- **D-07:** Use this consumer inventory as the minimum implementation/proof checklist. Error details are governed by D-15–D-17.

| Consumer | Selected behavior on app expiry |
|---|---|
| Authorization intake | Reject before host login/consent; never redirect to an unvalidated URL |
| Resume, remembered consent, approval | Recheck; no new code after expiry; safe denial only through an already validated redirect |
| PAR creation and PAR-backed authorization | Reject ineligible client at creation and again when used |
| Device authorization and device verification/approval | Reject creation; no approval after expiry; render an ineligible request safely |
| CIBA initiation, polling and push worker | Reject initiation/issuance; recheck current client at worker issuance, not a queued snapshot |
| Authorization-code redemption | Reject ineligible client; no token write or code consumption caused by this failure |
| Refresh, device/CIBA polling, all existing grant handlers | Reject ineligible client before issuing replacement tokens; preserve independent grant expiry/replay rules |
| RFC 8693 requesting client | Reject ineligible caller |
| RFC 8693 subject and actor tokens | Reject ineligible issuing-app token as invalid grant; do not check only requesting client |
| Introspection caller | Ineligible caller fails client authentication |
| Introspection target | Otherwise authorized observation reports only `active:false` for ineligible target; preserve current ownership restrictions |
| UserInfo | Ineligible issuing-app token fails before host account/claims resolution |
| Revocation | Ineligible caller fails authentication; eligible caller keeps non-disclosing success for unknown/already-invalid tokens; authorized host revocation remains available |
| Management GET/DELETE | Valid management credential may inspect/delete naturally expired, enabled app |
| Management PUT/self-rotation | Forbidden for expired app; cannot renew or revive it |
| Explicitly disabled app | Deny ordinary protocol access and all self-management, including GET/DELETE |
| Discovery/JWKS | Provider-level public surfaces unaffected |
| Host/RP sessions and account policy | Remain host/RP-owned; no promise of logout or account disablement |

- **D-08:** Cap newly issued access and refresh token expiry to the minimum of ordinary token expiry and finite app deadline. Persisted expiry, JWT `exp` and response `expires_in` must agree. Do not mint zero-lifetime tokens at equality. Recheck app eligibility when redeeming every online authorization artifact. Existing short TTLs for codes, PAR and device/CIBA requests remain; no requirement to cap all these artifacts. Preserve existing ID-token TTL/session semantics. This keeps the change focused while bounding planned app expiry for newly minted offline access tokens.
- **D-09:** Keep the local JWT verifier's offline shape. New signed `exp` can encode a planned deadline; already signed tokens cannot learn later disablement, policy or server-state changes. Existing legacy tokens keep their signed expiry, and introspection caches can be stale. Online Lockspire consumers enforce current issuing-app state. Document offline/cache limits; do not claim universal immediate revocation or host/RP session logout.
- **D-10:** Secret expiry gates Basic, post and secret-JWT authentication consistently; JWT assertion expiry, algorithm restrictions and replay protection remain independent. Secret expiry alone does not revoke already issued access/refresh tokens. A confidential refresh operation still requires a valid current client credential. Public/private-key/mTLS clients do not acquire a shared-secret expiry check.

#### Management, recovery and wire metadata

- **D-11:** Management tokens are unlimited by default, optionally finite by explicit host policy. GET is side-effect-free for lifecycle: never rotate or extend. Successful PUT rotates the management token immediately using current DCR policy; the previous token stops authorizing subsequent operations. No overlapping-secret/token feature. A lost PUT response is recovered through authorized host rotation, not replay with the invalidated token.
- **D-12:** Existing host staff authorization is the recovery authority; no new self-service recovery credential or Lockspire account system. Recovery atomically replaces management token and deadline, shows plaintext once through existing handling, and never enables an app or extends its deadline. An expired app may only be read/deleted even after recovery; a disabled app remains blocked. Neither client ID, setup token, expired token nor client secret proves recovery authority. Do not add an app-renewal workflow in this milestone.
- **D-13:** Registration intake `:disabled` prevents new registrations; it must not blanket-disable existing registration management. Apply selected management gates independently. This narrow correction makes finite-token recovery usable when intake has been closed; deliberate app disablement remains the containment action.
- **D-14:** Advertise actual effective deadlines. For a shared secret, standard `client_secret_expires_at` is Unix seconds or 0 for unlimited; omit it if no shared secret exists. Add documented server-owned Lockspire extensions `lockspire_client_expires_at` and `lockspire_registration_access_token_expires_at`, each numeric Unix seconds or 0 for unlimited, in applicable registration/management responses. The latter describes the currently represented management credential. GET never returns plaintext secrets or management token. Do not represent these extensions as RFC-standard fields or reuse access-token `expires_in` for them.
- **D-15:** Preserve RFC 7592 replacement semantics for mutable metadata. PUT includes unchanged `client_id`; standard server-owned fields `registration_access_token`, `registration_client_uri`, `client_secret_expires_at`, `client_id_issued_at` are prohibited. If `client_secret` is included it must match the current secret; it is not a rotation request. For the two new extension fields, identical echoes are accepted, omission preserves server values, attempted changes return 400 `invalid_client_metadata`. Separate these server-owned fields from mutable metadata so omission cannot clear deadlines. Apply this same non-client-authoritative treatment at registration intake: an inbound extension may not select or override its server-computed deadline; reject supplied lifecycle extension fields there as `invalid_client_metadata`.
- **D-16:** Use generic, non-disclosing errors. Management missing Bearer credential returns 401 Bearer challenge without error detail; expired/replaced/wrong token, unknown app or disabled-app credential returns 401 Bearer `invalid_token`. Valid management credential plus forbidden expired-app PUT returns 403 with the existing registration error envelope and a documented Lockspire `registration_expired` code; do not mislabel it `insufficient_scope` or an invalid token. This code is a local extension, not mandated by RFC 7592. GET/PUT success 200 and DELETE success 204.
- **D-17:** Client-authentication failures retain existing 401 `invalid_client` behavior; Basic requests include the matching challenge. RFC 6749 permits 401 for other client-auth failures; do not introduce an unrelated global 400/401 normalization. Introspection invalid caller is 401; authorized inactive target is 200 `{"active":false}`. Current introspection allows only owned tokens: rejecting an expired caller does not also produce an inactive response for that same request. UserInfo returns 401 Bearer `invalid_token`; valid caller with invalid code/refresh/exchange token returns `invalid_grant`. Authorization errors use local failure before a trusted redirect exists and existing `access_denied` plus original state once safe. Device/CIBA grant expiry retains its distinct `expired_token` condition. Preserve endpoint-specific challenges and avoid new disclosure of app/secret/token expiry reasons to unauthenticated callers.

#### Legacy authority and custom storage

- **D-18:** All pre-upgrade app/credential lifetimes remain effectively unlimited in built-in enforcement. Historical secret dates were advisory and may be stale; do not infer deadlines from them, creation dates or today's policy. Effective responses report unlimited rather than a false enforced historical date. Host-owned stricter enforcement remains host-owned. Upgrade documentation must explicitly disclose this grandfathering and the required deliberate replacement for finite enforcement.
- **D-19:** Select one persisted `lifetime_version` (0 legacy, 1 authoritative) and nullable app/management deadlines, reusing the secret deadline field. New rows explicitly write v1; migration defaults existing rows to v0. Missing/unknown versions from a lifetime-aware custom adapter are errors, not implicit legacy. V1 nil is authoritative unlimited. No per-credential provenance matrix or general capability framework is required.
- **D-20:** Legacy promotion is an atomic whole-row canonicalization on the locked current row: preserve current identity, hashes, active state and unrelated metadata; normalize legacy app/secret/management deadlines to nil; establish the new deadline only for the credential being issued/replaced; then persist v1 with the operation. Never just flip version. Thus RAT-only rotation cannot make an old secret date enforceable. Ordinary reads, metadata edits without credential issuance, and enable/disable do not independently require promotion. Existing PUT does issue a replacement RAT and therefore applies this rule. No eager fleet backfill. A legacy app gains a finite app lifetime only by new registration; legacy secrets/RATs gain finite lifetimes through explicit replacement under current policy. Do not add a general adoption command in this milestone.
- **D-21:** Require a declared lifetime-aware client-store contract version, validated at the existing dependency/adapter boundary. It must round-trip version/deadlines, atomically replace credential material plus lifetime and audit, and support current-state guarded mutation/issuance. Unsupported adapters/missing schema/unknown row state fail closed as configuration/server failures. Never claim finite enforcement while silently dropping fields or falling back to legacy. Runtime callback probing inside token internals remains forbidden by architecture tests. Exact callback names/typed values are planner discretion, but the observable conformance obligations are locked.

#### Concurrency, deployment and rollback

- **D-22:** Reauthorize management mutations against current locked client, matching the presented management credential to current hash plus URL binding, enabled state and operation-specific app/token deadlines. Apply only intended mutable metadata to that current row. Never persist a whole stale snapshot that restores old secrets/deadlines/active state. Two PUTs using one old token have one winner. DELETE, self-rotation and operator recovery participate in the same current-state ordering. Credential hash, secret-JWT verifier where applicable, version, deadline and audit commit/rollback together.
- **D-23:** Token-producing mutations revalidate current app eligibility and the already-verified credential identity at the final guarded issuance/redemption boundary. Expensive verification may happen before locking, but a stale fingerprint cannot authorize new issuance after a committed disable/rotation. Define one consistent lock order with grant/token rows. Concurrent reads/auth checks may linearize at their successful current-state check; completed responses are not retrospectively invalidated. Do not hold locks through network calls/response rendering. Sample time after blocking waits (D-05), not PostgreSQL transaction-start `now()`.
- **D-24:** Add a new prefix-aware packaged migration; never alter previously shipped migration contents/checksums. Expand schema while old code runs, stage new code and upgraded adapters without serving ingress, drain/stop every old writer (web, admin, jobs, CLI), then cut over to new ingress. Activation means this cutover, not a new permanent distributed activation service. Mixed old/new serving traffic cannot claim enforcement. A brief maintenance cutover is the supported baseline; zero-downtime bridge-release deployment is deferred.
- **D-25:** Before any v1 write, old binaries remain compatible with the additive schema. After the first v1 write, old binaries may not serve protocol traffic: retain schema/state and fix forward or use an enforcement-aware rollback build. Do not reset versions/clear deadlines/drop columns to make downgrade appear safe. Validate migration lock duration operationally; nullable/constant additive columns do not mean lock-free DDL.

#### Proof, language and responsibility

- **D-26:** Every implementation slice carries focused tests. Phase 166 adds cross-phase proof, real PostgreSQL races, fresh/legacy/custom-store packaged hosts, scoped security review and required CI. Reuse existing lock-barrier/race helpers and injected clocks; no sleeps or new time/locking library. Preserve PKCE, exact redirects, hashed secrets, code single-use, refresh-family reuse revocation and redaction.
- **D-27:** Observe actual exercised expiry/rotation/recovery events; a redaction sweep observing zero events cannot pass. Audit/telemetry distinguishes authorized host recovery from self-management and emits no plaintext credential/verifier/hash material. Correct existing false PUT-secret-rotation guidance when behavior is proven. Runtime/operator copy uses PRODUCT.md vocabulary, states expired vs disabled vs unknown accurately, and adds new concepts/retired phrases with their contract tests. No admin redesign or exposure of storage-version guts to support staff.

### the agent's Discretion

Exact helper modules, callback signatures, adapter declaration shape, column names for the two new deadlines, shared pure eligibility functions, lock ordering implementation, focused test organization and concise copy remain flexible within these decisions. Use ordinary Elixir data/functions, explicit dependencies and existing Ecto transactions. No new runtime dependency is justified by the research. Reopen only a demonstrated contradiction, not routine implementation preferences.

### Deferred Ideas (OUT OF SCOPE)

- Zero-downtime mixed-version bridge release, dual-secret/token overlap, automatic renewal, a new credential-adoption UI/CLI, and generic capability/activation frameworks are outside this milestone's selected minimum.
- Broad admin redesign, account/session ownership changes, new federation/grants, new runtime dependencies, unrelated security-key work and package publication remain outside Phase 162.
- Phases 163–165 implement the selected lifecycles; Phase 166 proves full journeys and updates public/operator truth. Capturing context does not finish Phase 162 or close DCR-02–04; its design deliverables still need planned execution and verification.

### Reviewed todos

The matching DCR umbrella is retained pending final Phase 166 proof, as described above. No other todo was folded.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DCR-02 | A host maintainer can consult one selected decision matrix for unset, zero and positive values for all three lifetimes, clock precision, exact expiry boundaries, policy-change timing and rotation renewal rules. | D-01–D-05 are selected; contract must publish the normative matrix plus boundary/policy/renewal acceptance fixtures. |
| DCR-03 | A host maintainer can identify the selected effect of app expiry on every applicable authorization, token, refresh, management and issued-token path, including protocol error mappings and offline verification limits. | D-06–D-17 define consumer, token, management and error outcomes; contract must provide endpoint inventory and response examples. |
| DCR-04 | An upgrading host has a selected compatibility contract covering ambiguous legacy secret dates, custom storage, migration and activation ordering, mixed-version nodes and rollback limits before implementation planning begins. | D-18–D-25 select legacy treatment, adapter obligations, current-state mutation, deployment cutover and rollback; contract must provide upgrade/rollback runbooks and acceptance fixtures. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Lockspire remains a separate embedded companion library, not a Sigra module or required standalone auth service; preserve boundaries among protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces.
- Keep the host seam narrow: account resolution, claims, login redirects, branding, and product-specific policy stay host-owned. Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite.
- Preserve PKCE S256 by default, exact-match redirect URI validation, hashed client secrets, short-lived single-use authorization codes, refresh-token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong log/operator redaction.
- The repo's declared stack is Phoenix 1.8.5, LiveView 1.1.28, Ecto SQL 3.13.5, PostgreSQL 14+, Oban 2.21.x, and OpenTelemetry 1.6.0. Bandit is for host apps/adoption and clean-room hosts, not a Lockspire dependency. [VERIFIED: `AGENTS.md:25-31`]
- If later implementation changes admin copy, read PRODUCT.md personas and vocabulary first, use its “UI says” term, add new concepts and retired wording to the vocabulary map, and describe actual behavior. Phase 162 does not change admin UI.
- Canonical planning references include `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and `.planning/research/SUMMARY.md`.

## Summary

Phase 162 is a design-contract and acceptance-definition phase [VERIFIED: `.planning/ROADMAP.md:29-39`; quote: “Host maintainers have one selected, standards-grounded expiry and upgrade contract before implementation planning.”]. The selected policy is locked in phase context: “**D-01:** For each of app lifetime, client-secret lifetime and app-management-token lifetime, unset/nil and duration zero mean unlimited” and decisions D-01 through D-27 are recorded at [`.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:18-88`]. Implementation should consume the selected decisions without reopening choices. Write a concise normative contract that makes all 27 decisions auditable through traceable tables, endpoint/error examples, legacy/custom-store/deployment matrices, and concrete acceptance fixtures; the exact selected scope is stated in [`.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:7-13`] (“Resolve DCR-02, DCR-03 and DCR-04: one selected lifetime matrix, endpoint/error inventory, management recovery contract, and existing-host/custom-store deployment contract.”). Reuse the Phase 153 audit rather than repeat it, as required by the phase boundary and [`.planning/REQUIREMENTS.md:61-70`].

The standards constrain wire behavior and management interoperability but do not choose Lockspire's policy duration semantics [CITED: RFC7591 §3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1) [CITED: RFC7592 §§2.2, 3, 5](https://www.rfc-editor.org/rfc/rfc7592.html). RFC 7591 defines `client_secret_expires_at` as Unix seconds or zero when no expiry is set. RFC 7592 defines complete replacement behavior for PUT, says a newly returned registration access token replaces the prior token, warns that expiring a token while the client remains active risks lockout, and permits 403 for a valid credential without permission. Thus the selected duration matrix and two Lockspire expiry extensions must be clearly labeled as product policy/local metadata; the exact fields are selected in “Add documented server-owned Lockspire extensions `lockspire_client_expires_at` and `lockspire_registration_access_token_expires_at`” [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:66`]. PostgreSQL 14 documents `now()`/`transaction_timestamp()` as transaction-start time and `clock_timestamp()` as actual current time, supporting the selected post-wait decision-time rule [CITED: PostgreSQL 14 date/time functions](https://www.postgresql.org/docs/14/functions-datetime.html).

**Primary recommendation:** Plan one deliverable-focused phase: a normative lifetime/endpoint/upgrade contract, a machine-checkable requirements and decision coverage matrix, and deterministic semantic examples. Validation should check coverage, links, examples, and adversarial contradictions in the documents only; it must not claim the future runtime behavior is proved.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Lifetime policy semantics and public contract | API / Backend | Documentation | Protocol behavior belongs to Lockspire; Phase 162 records it as design and acceptance criteria only. |
| Deadline persistence and adapter compatibility | Database / Storage | API / Backend | Existing-host migration and custom client-store conformance carry durable authority; no schema is changed in this phase. |
| Management recovery and host authorization | API / Backend | Host application | Lockspire contract defines permitted operation/state; existing host staff authorization remains the authority. |
| Adoption, activation and rollback guidance | Documentation / Deployment | Database / Storage | Host maintainers need an ordered procedure that states the mixed-version boundary and downgrade restriction. |
| Contract coverage and semantic validation | Documentation / CI | — | Checks prove internal completeness and consistency of the design artifact, not implementation behavior. |

## Standard Stack

### Core

| Library / source | Version | Purpose | Why Standard |
|---|---|---|---|
| Existing Lockspire planning artifacts | Current repository | Normative decisions, requirements, existing audit and project boundaries | Phase 162 is contract work; source-of-truth artifacts are `.planning/phases/162-.../162-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, and the Phase 153 audit. |
| OAuth 2.0 Dynamic Client Registration Protocol, RFC 7591 | RFC | Secret-expiry metadata and registration response semantics | Primary standards source; `client_secret_expires_at` is Unix seconds and 0 means it will not expire. [CITED: RFC7591 §3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1) |
| OAuth 2.0 Dynamic Client Registration Management, RFC 7592 | Experimental RFC | PUT replacement, management credential rotation, response and lockout considerations | Primary standards source for the registration management contract. [CITED: RFC7592 §§2–5](https://www.rfc-editor.org/rfc/rfc7592.html) |
| PostgreSQL documentation | 14 (project minimum) | Explain transaction time versus actual current time in guarded operations | The product supports PostgreSQL 14+; cite versioned docs to avoid relying on current-major changes. [CITED: PostgreSQL 14 date/time functions](https://www.postgresql.org/docs/14/functions-datetime.html) |

### Supporting

| Source | Purpose | When to Use |
|---|---|---|
| `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md` | Existing implementation baseline | Reuse; do not repeat the broad code audit. |
| `.planning/research/dcr-lifetimes/{SUMMARY,ARCHITECTURE,PITFALLS,SCOPE}.md` | Prior focused research and approved milestone boundary | Reuse as rationale and cross-check decisions. |
| `.planning/METHODOLOGY.md` | Research-first, least-surprise host seam, and coherent recommendations | Keep the deliverable decisive and host responsibilities narrow. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Context-locked decision bundle | Reopen each choice as an implementation option | Conflicts with decision authority in context and delays the gated implementation phases. |
| One versioned lifetime contract plus adapter conformance obligations | Generic capability negotiation or per-credential provenance state | More combinations and runtime discovery than the selected minimum requires. |
| Documentation coverage/link/example validation plus adversarial semantic review | Runtime integration tests in Phase 162 | Runtime tests would be false proof because Phase 162 changes no implementation; runtime proof belongs to Phases 163–166. |

**Installation:** None. This phase is documentation/design only and adds no package or runtime dependency.

## Architecture Patterns

### System Architecture Diagram

```text
Selected decisions (162-CONTEXT.md) + requirements + Phase 153 audit
                               |
                               v
                Normative lifetime contract
       (policy matrix, endpoints/errors, wire metadata)
                  /                         \
                 v                           v
       Upgrade contract              Acceptance fixtures
 (legacy/store/deploy/rollback)   (fresh, legacy, custom, races)
                 \                           /
                  v                         v
        Coverage/link/example validator + adversarial review
                               |
                               v
          Verified design artifact for Phases 163–166
```

### Recommended Project Structure

Keep the phase deliverable under `.planning/phases/162-lifetime-semantics-upgrade-contract/`. The plan should name the exact normative artifact and any focused validator/fixture artifacts it creates. Do not change library source, dependencies, generated host code, UI or SDK state.

### Pattern 1: Decision-to-contract traceability

**What:** Give each context decision D-01 through D-27 an explicit contract location and at least one observable acceptance statement or a reasoned group mapping. Keep the requirement map for DCR-02/03/04 separate, so requirement coverage does not rely on readers inferring it from decision numbering.

**When to use:** For this entire phase. Decisions include policy, wire behavior, data compatibility, deployment and audit; a single prose summary can hide omissions.

**Example:** A row maps D-05 to the selected rule “Persist authoritative deadlines as UTC whole seconds. A finite object is eligible strictly while `now < deadline`; equality is expired.” [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:29`] The contract also cites the selected post-lock decision time from that same D-05 sentence. This is an illustration of the decision record, not evidence that runtime enforcement exists.

### Pattern 2: Separate protocol outcome from credential disclosure

**What:** Specify each path by precondition, check point, state effect, HTTP/OAuth outcome, challenge behavior and disclosure limit. Keep expired app, disabled app, unknown app, invalid client credential and invalid grant semantically distinct internally while mapping externally to the selected non-disclosing response.

**When to use:** Authorization, token, introspection, UserInfo, revocation, and registration-management inventories.

**Example:** The selected behavior says an authorized observation of an ineligible target reports only `active:false`, while an ineligible caller fails client authentication [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:49-50`]. RFC 7662 separately specifies an inactive response and cautions against including why a token is inactive [CITED: RFC7662 §§2.2, 2.3](https://www.rfc-editor.org/rfc/rfc7662.html). Do not combine those cases or claim the target observation bypasses current ownership restrictions.

### Pattern 3: Explicit deployment state transition

**What:** Present additive schema preparation, upgraded adapters, stopping old writers, ingress cutover, first v1 write, and rollback compatibility as ordered states. Name the cutover as activation and call out that mixed old/new serving cannot claim enforcement.

**When to use:** Existing-host upgrade and operator runbook sections.

**Example:** The selected compatibility boundary is: “Before any v1 write, old binaries remain compatible with the additive schema. After the first v1 write, old binaries may not serve protocol traffic” [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:82-83`]. The plan must show fix-forward or enforcement-aware rollback, not resetting version/deadline state.

### Anti-Patterns to Avoid

- **Re-auditing Phase 153:** The source audit is complete and explicitly reusable; investigate only a concrete contradiction required to make the contract plan finite.
- **Treating RFC metadata as policy:** RFC wire timestamp zero does not define the meaning of a Lockspire duration setting.
- **Claiming runtime proof from document tests:** A coverage validator establishes that contract claims are present and cross-referenced, not that Lockspire enforces them.
- **Using a fresh ingress timestamp after a lock wait:** It can authorize a guarded write after the deadline; the selected decision clock is after current-row reload.
- **Documenting mixed-version enforcement as safe:** An old writer can drop authoritative lifecycle fields or continue serving without checks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Standards semantics | A new interpretation of RFC registration fields | RFC 7591/7592 terminology and explicit Lockspire extension names | Prevents local duration policy from being mistaken for standardized metadata. |
| Existing behavior baseline | A second broad source audit | Completed Phase 153 audit plus targeted discrepancy checks | Avoids duplicated work and contradictory audit snapshots. |
| Runtime expiry proof | Prose assertions or timing sleeps in this docs phase | Phase 166 deterministic injected-clock and PostgreSQL evidence | Runtime behavior has not yet been implemented; this phase can define tests only. |
| Custom-store compatibility | Silent field dropping or token-internal callback discovery | Declared store-contract version and boundary validation selected in D-21 | Silent fallback can falsely advertise enforcement; architecture tests forbid ambient probing. |

**Key insight:** This phase's output is an executable design contract in the sense that its decisions can be translated into fixtures. Its validator proves completeness and internal coherence only. Implementation and runtime conformance stay gated to later phases.

## Common Pitfalls

### Pitfall 1: Contract coverage that merely counts 27 IDs

**What goes wrong:** A contract lists each D-number but does not define response behavior or an acceptance example for it.
**Why it happens:** Mechanical coverage can be mistaken for semantic resolution.
**How to avoid:** For each D-01–D-27, record the contract section and a checkable expected observation; group decisions only where a shared fixture truly exercises them.
**Warning signs:** Rows say only “covered,” endpoint/error decisions have no response examples, or deployment decisions have no ordering.

### Pitfall 2: False runtime proof

**What goes wrong:** Documentation tests pass and are reported as evidence that expiration is enforced.
**Why it happens:** The design uses concrete examples that resemble runtime tests.
**How to avoid:** Label each fixture “expected contract behavior; not executed against runtime.” Phase 162 validates links, matrix completeness, fixture arithmetic and semantic consistency. Runtime tests remain owned by later requirements.
**Warning signs:** A Phase 162 test starts the app, changes database state or asserts real endpoint responses despite no runtime implementation scope.

### Pitfall 3: Standards and local extension blur

**What goes wrong:** A host believes app and management-token expiry fields are RFC-standard or that duration zero's meaning comes from RFC 7591.
**Why it happens:** The fields appear beside `client_secret_expires_at` in the same JSON response.
**How to avoid:** Mark each `lockspire_*` field as a Lockspire extension, distinguish issuance-duration settings from Unix epoch timestamps, and use 0 only as the selected serialized unlimited marker.
**Warning signs:** “RFC expiry field” is used for app/RAT fields or the prose says “zero expires immediately.”

### Pitfall 4: Legacy migration advertises a guarantee before cutover

**What goes wrong:** Hosts run old and new serving binaries together or downgrade after v1 writes, causing an old writer to ignore or erase authoritative state.
**Why it happens:** Additive columns appear backward-compatible and mixed traffic appears operationally convenient.
**How to avoid:** Document pre-v1 additive compatibility, drain all writers, cut over before claiming enforcement, and fix forward after first v1 write unless rollback code understands the contract.
**Warning signs:** No named activation point, jobs/admin/CLI omitted from drain, or rollback instructions clear version/deadline state.

### Pitfall 5: Acceptance fixture silently loses a boundary

**What goes wrong:** A fixture says “at expiry” but rounds to the wrong UTC second, or tests token expiry but not persisted/JWT/response agreement.
**Why it happens:** Examples use dates without an explicit timestamp convention.
**How to avoid:** Use UTC integer seconds and specify before, equality, and after values. For access/refresh issuance, compare stored expiration, signed `exp` and response `expires_in` to the same captured time/deadline.
**Warning signs:** Microseconds in examples, no equality row, or a zero remaining lifetime is described as a successful issuance.

## Code Examples

No runtime code is appropriate in this documentation-only phase. Use small protocol examples in the contract, explicitly labeled as normative examples rather than executed tests:

```text
T = 100 UTC seconds
app lifetime = 60s; secret lifetime = 10s; management lifetime = 20s
deadlines = app: 160; secret: 110; management: 120
secret eligibility: now < 110 (109 valid; 110 expired)
```

This fixture is selected as “At T=100, register with app=60, secret=10, management=20: deadlines 160/110/120” [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:141`]. Extend it with explicit nil/zero, changed-policy, token cap, legacy promotion, custom-store failure, and deployment-cutover expectations from D-01–D-25.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Treating stored secret expiry as enforced behavior | Phase 153 records the built-in auth path does not enforce the advertised date; Phase 162 selects later enforcement semantics | Audit dated 2026-10-13; decision bundle selected 2026-10-20 [VERIFIED: `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md:1-6`; quote: “Expiry metadata is implemented. Expiry enforcement is absent.”] | The contract must distinguish current behavior from future selected behavior. |
| Treating policy `nil`/zero as a wire timestamp | Separate Lockspire setting durations from RFC 7591 epoch timestamp metadata | Selected D-01/D-14 on 2026-10-20 [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:18,66`] | Unlimited policy serializes to zero where applicable; zero duration itself does not mean immediate expiry. |
| Assuming transaction `now()` advances after waiting | Use one fresh/injected decision time after guarded lock/current-state reload | Selected D-05/D-23; PostgreSQL 14 documents transaction-start semantics [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:29,81`]; [CITED: PostgreSQL 14 date/time functions](https://www.postgresql.org/docs/14/functions-datetime.html) | Avoid false acceptance after a deadline during lock wait. |

**Deprecated/outdated:** Existing product copy that says a successful registration-management PUT rotates the client secret is identified for correction once behavior is proven (D-27). Phase 162 records the correction contract; implementation/docs proof is later.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The normative contract and its checkable matrix/examples can be delivered as planning artifacts without modifying runtime source. | Summary / Validation Architecture | If a needed contract detail cannot be expressed without implementation, later phases may receive an incomplete handoff. |
| A2 | Existing repo documentation conventions provide the right home for the eventual public contract; exact filenames are not locked in context. | Architecture Patterns | Wrong placement could make the contract hard for host maintainers to find. |

These are planning assumptions, not selected product decisions. Resolve artifact placement from current repository conventions during planning and keep any contract checks scoped to the chosen documents. [ASSUMED]

## Open Questions

1. **Which exact contract artifact path should be the normative host-facing location?** [ASSUMED]
   - What we know: Context names canonical references and asks for contract deliverables but does not lock new filenames.
   - What's unclear: Whether the complete contract belongs in a new `docs/` guide, a phase artifact that later drives public docs, or both.
   - Recommendation: Plan one normative design/acceptance artifact in the phase directory and a later Phase 166 public-doc synchronization item; avoid duplicating two competing normative copies.

There are no unresolved policy choices in D-01–D-27. This artifact-location question is a routine planning decision, not a blocker.

## Environment Availability

No external runtime, service, package manager or database is required to produce the Phase 162 design contract. PostgreSQL documentation is an external reference only; no database service needs to be available.

## Validation Architecture

### Contract validator

Use a repeatable documentation-only validator (existing project test/script conventions if suitable) that checks:

- DCR-02, DCR-03 and DCR-04 each appear exactly once in a requirement-to-contract map and each points to a concrete contract section.
- D-01 through D-27 are all mapped to at least one normative section and at least one acceptance fixture or explicitly documented reasoning row; no extra selected D-number is invented.
- Matrix coverage includes all three lifetimes and nil, zero and positive values; UTC whole-second precision; before/equality/after; policy edit timing; and each selected rotation/recovery rule.
- Every D-07 consumer row has a selected outcome and matching error/challenge or explicit no-error behavior; separate app expiry, disabled, unknown, invalid credential and invalid grant cases remain distinguishable in the contract.
- Wire field examples distinguish standard `client_secret_expires_at` from the two documented Lockspire extensions, represent no-secret behavior, and keep server-owned extension echo/reject rules consistent between registration and PUT.
- Legacy, fresh install, declared custom-store support, missing/unknown capability, prefix migration, writer drain, cutover, first-v1-write and rollback cases are represented.
- Acceptance fixture arithmetic and stated timestamps are internally consistent, all local RFC references resolve, and no contract validator result is described as runtime conformance.

### Adversarial semantic review

Review the completed contract against at least these conflict pairs: expired vs disabled vs unknown; app deadline vs secret/RAT deadline; secret rotation vs PUT/RAT rotation vs host recovery; valid management credential on expired app GET/DELETE vs PUT; introspection expired caller vs expired target; existing online verifier vs offline JWT/cache; legacy RAT-only promotion vs stale secret date; custom-store missing/unknown state vs v0; v1 writes vs old binaries; `registration intake disabled` vs existing management; and credential expiry vs grant expiry/replay. Any ambiguous path returns to the contract before Phase 162 completion.

### Limits of this validation

This phase makes no runtime, migration, concurrency, telemetry, security-review, generated-host or packaged-host claim. It does not execute the acceptance fixtures against Lockspire. Those checks are assigned to Phases 163–166, including real PostgreSQL races and packaged fresh/legacy/custom-store journeys. A documentation validator can establish coverage, link integrity, arithmetic and internal consistency only.

## Security Domain

Security enforcement applies: this contract defines credential acceptance, host recovery authority, stale authorization behavior, failure disclosure and deployment boundaries. Phase 162 must preserve the selected controls and phrase runtime enforcement as future acceptance behavior until later verification.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Define client credential expiry consistently across Basic, post and secret-JWT; preserve assertion expiry, algorithm and replay controls. [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:60,87`] |
| V3 Session Management | yes, boundary only | State that host/RP sessions remain host-owned and app expiry makes no logout guarantee. [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:56,58`] |
| V4 Access Control | yes | Specify per-endpoint current-state gates and existing host staff authorization for recovery. [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:47-56,64,80-81`] |
| V5 Input Validation | yes | Specify validation for nil or bounded integer settings and reject malformed/out-of-range values at each supported write boundary. [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:27`] |
| V6 Cryptography | yes, preservation | Keep credential hashes/verifier material protected and never disclose plaintext, verifier or hash in telemetry/audit. [VERIFIED: `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md:64,80,87`] |

### Known Threat Patterns for OAuth/OIDC lifetime policy

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Stale pre-lock credential check authorizes after rotation/disable | Spoofing / Elevation of privilege | Reauthorize against current locked row and current credential identity at final guarded mutation. |
| Finite management token expires without recovery | Denial of service | Existing host staff recovery; clear 401/403 boundary; no new client-controlled recovery authority. |
| Mixed old/new serving code bypasses lifecycle fields | Tampering / Elevation of privilege | Drain old writers and cut over before claiming enforcement; old binary is unsupported after v1 writes. |
| Error detail reveals app, secret or management-token state | Information disclosure | Endpoint-specific generic errors and challenges selected in D-16/D-17. |
| Offline JWT or cached introspection overclaimed as immediate revocation | Information disclosure / Spoofing | Document signature/cache boundary; check current state in online Lockspire consumers; do not promise universal revocation. |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md` — selected D-01–D-27, acceptance examples, boundaries.
- `.planning/REQUIREMENTS.md` — normative text for DCR-02, DCR-03, DCR-04 and phase traceability.
- `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/METHODOLOGY.md` — phase gate, milestone sequencing and project method.
- `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md` — completed baseline audit reused by this phase.
- `.planning/research/dcr-lifetimes/SUMMARY.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `SCOPE.md` — focused prior research; no broad re-audit needed.
- [RFC 7591 §3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1) — standard client-secret expiry serialization.
- [RFC 7592 §§2.2, 3, 5](https://www.rfc-editor.org/rfc/rfc7592.html) — PUT replacement, response/credential replacement and management-token lockout risk.
- [RFC 6749 §§3.1, 5.2](https://www.rfc-editor.org/rfc/rfc6749.html) and [RFC 6750 §3](https://www.rfc-editor.org/rfc/rfc6750.html#section-3) — authorization redirect safety, OAuth client authentication errors and Bearer challenges.
- [RFC 7662 §§2, 4](https://www.rfc-editor.org/rfc/rfc7662.html) — introspection authorization and cache considerations.
- [RFC 7009 §3](https://www.rfc-editor.org/rfc/rfc7009.html#section-3) — revocation deployment limits.
- [PostgreSQL 14 date/time functions](https://www.postgresql.org/docs/14/functions-datetime.html) — transaction/statement/actual clock semantics.

## Metadata

**Confidence breakdown:**
- Selected semantics: HIGH — all 27 decisions are authoritative in phase context and traceable to approved requirements.
- Standards mapping: HIGH — checked against primary RFC Editor and PostgreSQL 14 documentation in this research session.
- Acceptance and validator shape: MEDIUM — actionable design derived from decisions; phase planning and adversarial review should confirm the final artifact path and exact coverage mechanism.

**Research date:** 2026-10-20  
**Valid until:** 2026-11-19 for stable RFC/design constraints; recheck project artifact paths at planning time
