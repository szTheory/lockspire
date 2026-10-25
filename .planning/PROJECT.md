# Lockspire

## What This Is

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It helps Phoenix SaaS teams turn an existing app into a trustworthy OAuth/OIDC provider for third-party developers without standing up a separate auth service or assembling protocol-sensitive pieces by hand. The host app owns accounts, login UX, layouts, branding, and product policy; Lockspire owns protocol correctness, token and consent domain logic, admin tools, telemetry, and install flow.

## Core Value

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Completed Milestone: v1.45 DCR Lifetime Enforcement (Completed 2026-10-22)

**Delivered:** Phases 162–166 completed 40 plans and satisfied all 18 requirements. App, shared-secret and app-management-token lifetimes now use the selected issuance snapshots and strict boundary semantics, current-row authority, atomic rotation/recovery and compatible legacy promotion. Packaged fresh, both-prefix legacy and configured shared-PostgreSQL adapter journeys passed against candidate `f8dd7712af7f3ef906305db549c6312284339dba`. Required CI passed all seven contexts; nine package scenarios passed 49/49 checks; independent security closed 25/25 mitigations.

**Closeout:** All five phase verification owners passed before archival. The audit is tech_debt with 18/18 requirements, 29/29 links and 6/6 flows. Recorded evidence limits and bookkeeping are accepted for archival; no undefined probe or unperformed visual review is relabeled as passing. See [audit](milestones/v1.45-MILESTONE-AUDIT.md), [roadmap](milestones/v1.45-ROADMAP.md) and [requirements](milestones/v1.45-REQUIREMENTS.md). Latest public package remains verified 1.6.1; this planning completion does not publish the candidate.

## Completed Milestone: v1.46 Embedded Host Integration Reliability (Completed 2026-10-24)

**Delivered:** Native Phoenix admin integration, host-owned authorization, safe install/upgrade convergence and reproducible packaged compatibility proof. Phases 167–170 completed all 16 plans and 15 requirements. All four phase owners passed immediately before archival; integration passed 14/14 boundaries and 6/6 flows, with 68/68 security threats closed. Local Chrome/CDP receipts cover 96 cases across two exact dependency pairs and three mounts; separate lifecycle receipts contain 43/44 checks. Hosted CI remains unobserved.

**Closeout:** Audit tech_debt with no blockers. The duplicate trace-clause fixture warning is accepted for archival and remains deferred; no phase-verification verdict was overridden. See [audit](milestones/v1.46-MILESTONE-AUDIT.md), [roadmap](milestones/v1.46-ROADMAP.md) and [requirements](milestones/v1.46-REQUIREMENTS.md). Package publication is separate.

## Completed Milestone: v1.47 OAuth/OIDC Core Interoperability & Hardening (Completed 2026-10-25)

**Goal:** Clients using the supported embedded Phoenix surface receive secure, standards-grounded authorization and PAR/profile behavior, with reproducible evidence for each selected correction.

**Target features:**
- Qualify historical OIDC authorization-error and FAPI PAR/TLS/WebRunner findings against exact current inputs; distinguish protocol, harness, infrastructure and unsupported cases.
- Correct selected authorization-response and PAR/profile boundaries only where fresh evidence warrants it; reuse existing proof for already-correct behavior.
- Prove selected outcomes through a packaged host, focused security review and required contributor/CI checks while keeping external suites supplemental and non-certifying.
- Leave a reviewed, green-main and clean-workspace handoff through the existing development/release train; refresh the rolling milestone ranking at every boundary.

**Selected:** User approved the core-hardening direction and delegated upstream research, adversarial synthesis and routine scoped decisions on 2026-10-24. Continue phase numbering at 171. [Scope](research/v1.47-core-hardening/SCOPE.md), [research](research/v1.47-core-hardening/SUMMARY.md), [rolling roadmap](MILESTONE-ARC.md).

**Entry condition satisfied — Phase 171:** Reviewed cumulative delivery in PR #138 and the original exact-main receipt establish accepted base `fe38beee987b135e87c99e7aa7f2488b4c8613e8`, with preserved history and delegated resource custody. The implementation branch remains distinct from accepted main. [Phase 171 verification](milestones/v1.47-phases/171-accepted-baseline-finding-qualification/171-VERIFICATION.md) passed 10/10; its frozen twelve-case matrix reuses ten proofs and assigns A171-003 to Phase 172 and P171-005 to Phase 173. Optional external profiles remain unlaunched and non-certifying; later milestone delivery/publication remains separate.

**Implementation verified — Phase 174 (2026-10-25):** All four phases, ten plans and fourteen requirements are verified. The two production corrections are unsupported response-mode disposition and stored pushed-request authority. Selected package proof passed 12/12, final candidate local/hosted gates passed, and source/security reviews are closed with nine non-authoritative judgment recommendations retained across the four phases. The canonical milestone audit passes 14/14 requirements and 6/6 integration links/flows. PR #140 was squash-merged as `173059a166e9ade0f5f57c9980b7b2400a98538c`; fresh exact-main acceptance passed local `mix ci`, all seven push CI jobs, hygiene 22 PASS / 2 WARN / 0 BLOCK and no-publish Release. The [byte-preserved receipt](milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-MAIN-ACCEPTANCE.json) and custody records are retained on the milestone evidence branch. No next product milestone or publication is selected.

**Next candidates:** Provisional v1.48 addresses dedicated client-auth verifier key isolation/rotation (SEC-01). Token concurrency requires a fresh gap; OPS-03 requires scale evidence; KEK-04 requires an adopter custody need. Re-rank rather than execute automatically. Legacy fixture maintenance and existing debt retain their owners.

## Current Milestone: v1.48 Client Authentication Key Isolation & Rotation

**Goal:** A Phoenix host can protect and rotate `client_secret_jwt` verifier material independently of endpoint/session secrets while preserving existing clients through an explicit, verifiable upgrade path.

**Target features:**
- Dedicated-purpose verifier encryption keys with explicit read/write key selection and fail-closed authenticated decryption.
- Compatible legacy reads, staged mixed-version deployment, safe rewrap/check and eventual legacy rejection.
- Retry-safe maintenance that preserves concurrent secret rotation, truthful redacted status and documented key-loss recovery.
- Fresh-install and packaged-upgrade proof across the existing supported direct-client authentication surface, with unchanged secret hashes and protocol/security defaults.

**Selected:** On 2026-10-25 the owner said “follow ur recs” after the milestone-selection checkpoint. This retains the recommended SEC-01-first ordering and selects v1.48. Requirements and roadmap remain subject to their GSD gates; no product implementation is started by this selection. Continue after Phase 174, using the completed milestone records rather than the initializer's stale v1.44 completion field.

**Planning entry:** [Baseline](research/v1.48-client-auth-key-isolation/BASELINE.md) records the planning branch and retained prior history. Fresh synchronized-main acceptance and delivery reconciliation are required before product implementation. Preserve historical Phase 142/143 directories; v1.47 phases are already archived.

**Next candidate:** [UI Stories & Continuous Quality](research/ui-quality-engine/MILESTONE-PROPOSAL.md) follows SEC-01 unless fresh evidence changes the ranking. Preserve the completed Q1–Q10 interview and final confirmation, including the adoption-demo dev/test `phoenix_storybook` host, both complete jobs, observed improvements, blocking mechanical checks, experimental budgets and same-PR maintenance. Do not repeat settled design questions. Token lifecycle, OPS-03 and KEK-04 retain their evidence triggers in MILESTONE-ARC.md.

## Standing Planning and Delivery Posture

Use [MILESTONE-GUIDE.txt](MILESTONE-GUIDE.txt) for durable user preferences and [MILESTONE-ARC.md](MILESTONE-ARC.md) for the live chunked direction. Research consequential decisions through relevant stakeholder lenses and reputable primary sources, adversarially compare alternatives, then synthesize one coherent scoped recommendation before downstream implementation. Stop at diminishing returns; automate routine decisions within the approved scope and avoid speculative future plans.

Prefer small auditable local glue to another dependency when simpler; keep the tree small and flat, retaining vetted crypto/framework primitives and adding maintained packages when their benefit justifies the cost. At run/milestone boundaries, commit owned work, preserve unknown edits/unique commits, safely clean owned worktrees/resources, record exact evidence and next action, and establish fresh green main through the existing train before starting the next implementation milestone.

<details>
<summary>Original v1.46 intent and execution handoff</summary>

### Original milestone: v1.46 Embedded Host Integration Reliability

**Goal:** A Phoenix host can install, mount and securely use Lockspire’s admin LiveViews through one supported integration, with reliable connections and navigation and executable proof.

**Target features:**
- One reusable host-router integration replacing the demo’s duplicated admin routes and the unsupported forwarded LiveView path.
- Explicit host-owned authorization for initial HTTP requests, LiveView connections, reconnects and navigation; Lockspire does not take over staff accounts or policy.
- Generated installation and upgrade guidance, installation verification, the adoption demo and clean-room fixtures use the same supported integration.
- Automated proof for default and custom mount paths, connected navigation, denied access and separation from public OAuth/OIDC endpoints across supported LiveView baselines.

**User direction:** Favor impactful mechanical fixes with little maintainer attention. No visual redesign or subjective UI signoff; focused research approved before requirements. Version and scope confirmed 2026-10-22. Phase numbering continues from 167.

**Delivered through Phase 170 (2026-10-24):** Native host routing, host-owned authorization, install/upgrade convergence and packaged compatibility proof are complete. Phase 170 proves 16 browser cases at each of three mounts on both exact Phoenix/LiveView pairs (96 cases), with separate 43/44 lifecycle checks. Final independent verification passed all 24 roadmap/plan truths and all three HPROOF requirements; security closed 19/19 threats and code re-review has no open findings. Fresh prior-phase regressions passed 202 tests. The broad 2,027-check result retains its recorded source, separate from later focused wrapper-containment checks. Local Elixir/OTP results do not claim hosted CI execution; milestone audit and publication remain separate.

**Deferred:** Dedicated client-secret-JWT verifier encryption (SEC-01), KMS/Vault (KEK-04), paged key-maintenance dry-run, legacy-plaintext fixture maintenance and unrelated v1.45 debt remain separate work. Package publication and remote ref updates are separate actions.

</details>

<details>
<summary>Original v1.45 intent (2026-10-20)</summary>

### Milestone intent: v1.45 DCR Lifetime Enforcement

**Goal:** Make registration and credential expiry trustworthy, with matching advertised and enforced behavior and an explicit upgrade path for existing Phoenix hosts.

**Target features:**
- Resolve unset/zero/positive lifetime semantics, policy timing, expiry effects, management recovery and legacy compatibility in Phase 162 before implementation planning.
- Enforce app, app-management-token and shared-secret lifetimes consistently across issuance, use and rotation.
- Support existing installations, generated migrations and custom storage with executable compatibility evidence.
- Prove boundary-time behavior, concurrency, redaction and complete host journeys; update operator and public guidance only after implementation is verified.

**Inputs:** [DCR scope](research/dcr-lifetimes/SCOPE.md) and the completed [Phase 153 audit](milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md). Focused standards and compatibility research is approved. No new timeout, backfill or rejection policy is selected by initializing this milestone. Package publication is a separate verified step.

</details>

## Completed Milestone: v1.44 Adopter Polish & Verified 1.6.0 (Completed 2026-10-20)

**Goal:** Make the first encrypted-at-rest release easy to adopt, then publish and verify it end to end.

**Target features:**
- Confirm in a clean-room host, then fix, the DB-touching Mix tasks (`lockspire.client.create`, `lockspire.doctor.token_format`, `lockspire.doctor.remote_jwks`) that do not start the repo, using the shared `TaskError` / `RepoRunner` pattern, with tests that run each task without a pre-started repo.
- `mix lockspire.gen.kek` prints a fresh key-encryption key and the `runtime.exs` snippet (KEK-03).
- `{:system, "ENV"}` key-encryption-key resolution (KEK-05).
- A read-only "Key protection" line on the admin Keys pages showing whether keys are encrypted and under which key ID (KEY-UI-01), worded from the PRODUCT.md vocabulary map.
- An admin key-generation error that names the missing key-encryption key instead of generic copy.
- Merge Release Please PR #121 and verify the published lockspire 1.6.0 (Hex checksum, docs, GitHub release and tag, clean-room install), as v1.39 did for 1.5.1.

**Delivered (2026-10-20):** Phases 158–161 delivered all 13 requirements in 17 plans. Lockspire 1.6.0 was published from `428a9c53e02bc573376d0fcac313f047fbbea81c` through protected run 39481079989, with matching canonical source CI, exact artifact proof and terminal `release_verified: true`. Independent public checksum/manifest/tar/lockfile checks, versioned docs, exact11-task inventory, tag/release source and a fresh Hex/Mix-home install all passed. PR133 records that verified release on main; later documentation commits are distinct from the published source.

No protocol change, no new dependency, and security defaults stay the same. Deferred: DCR lifetime enforcement (DCR-01, its own protocol milestone), KMS/Vault key-set provider (KEK-04), the dedicated `client_secret_jwt` verifier key (SEC-01), and a paged `--dry-run`.

## Completed Milestone: v1.43 Signing Key Encryption at Rest (Completed 2026-10-16)

**Goal:** Close CR-01: private signing keys are genuinely encrypted at rest, existing installs upgrade safely, and the host-facing experience stays calm.

**Target features:**
- Real envelope encryption of private JWKs with AES-256-GCM from OTP `:crypto` (no new dependency), using a versioned ciphertext format tagged with the wrapping-key ID, applied at the single write seam (`Admin.Keys`) and the single read seam (`PrivateJwk.decode`).
- An explicit host-supplied key-encryption key configured as a rotatable list, not derived from `secret_key_base`; startup fails fast when it is missing or malformed, with install-generator and docs guidance.
- A safe upgrade path for existing installs: legacy plaintext rows stay readable, an idempotent re-encryption task migrates them, and a strict mode refuses plaintext once migration is complete.
- Rotation of the key-encryption key that re-wraps signing keys while the old key still decrypts, without reissuing signing keys.
- Proven redaction and end-to-end signing: no private material or encryption key in logs, telemetry, admin pages, or errors; signing and verification proven across ID tokens, JARM, introspection JWTs, and token exchange; CI asserts no plaintext JWK at rest.
- Housekeeping: bump Bandit to 1.13.1 (CVE fix) in the adoption demo lock and both clean-room host pins.

OAuth/OIDC behavior and existing security defaults stay the same, and the library remains embedded. The DCR default lifetime semantics todo is deferred to a later protocol milestone.

**Delivered:** Phases 155–157 completed 14 plans and satisfied all 16 requirements, closing CR-01. New private signing keys are sealed as AES-256-GCM `LSK\x01` envelopes under a host-supplied KEK list in `runtime.exs` (no `secret_key_base` fallback). Without a KEK the app still boots and signs with existing keys, but key generation refuses with `{:error, :key_encryption_not_configured}`. `mix lockspire.keys.reencrypt` migrates legacy rows and rotates KEKs with per-row locking and CAS, `--check` gates the opt-in `legacy_plaintext: :reject` mode, and all six signing/decrypting consumers read through one guarded `PrivateJwk` path. A structural matcher sweep found no key material in admin, telemetry, log or operator output. Install prints a fail-closed KEK block, the demo and clean-room hosts run encrypted on Bandit 1.13.1, and a HexDocs upgrade guide covers rotation, rollback and KEK loss. No new dependency, no schema migration, no protocol change (SAFE-01).

**Closeout:** Audit `tech_debt`, no blockers (16/16 requirements, 15/15 integration, 4/4 flows; every phase Nyquist-compliant and security-verified). Override closeout: the Phase 155 and 156 verification reports went stale only because later in-milestone work edited files they covered. The DB-touching Mix task todo was acknowledged as out of scope. Accepted debt includes the unpaged `--dry-run`, rolling-restart ordering for KEK rotation and `:reject` (documented, AR-156-01), and generic admin copy when key generation lacks a KEK. The package release goes through Release Please. See the [v1.43 audit](milestones/v1.43-MILESTONE-AUDIT.md), [roadmap](milestones/v1.43-ROADMAP.md), and [requirements](milestones/v1.43-REQUIREMENTS.md).

## Completed Milestone: v1.42 Admin UI Clarity & Workflow Refinement (Completed 2026-10-15)

**Goal:** Make Lockspire's existing admin pages easier to scan and safer to use by removing low-value copy, clarifying outcomes, and making common tasks feel focused and consistent.

**Target features:**
- Review all 29 existing admin route scorecards and inspect complete page sections in the mounted synthetic demo; use Impeccable's critique and Operate guidance to ground changes in the actual work.
- Simplify labels and explanations around the staff user's decision. Remove implementation provenance and duplicated copy when they do not change a decision; explain necessary protocol terms in context and describe supported consequences plainly.
- Move client creation to a dedicated page and give task pages one clear title, concise task context, relevant client identity, and a clear way back.
- Apply a consistent primary, secondary, and destructive-action hierarchy; reduce repetitive metrics and card scaffolding where it adds noise.
- Correct demonstrated control-spacing and contrast issues using the existing Signal Cyan tokens and component system. Preserve responsive layout, light/dark/system themes, keyboard access, and reduced-motion behavior.
- Add focused regression checks and redaction-safe before/after browser evidence for the routes and states changed.

The milestone is limited to admin presentation and task flow. OAuth/OIDC behavior, security policy, the embedded-library boundary, host-owned UX, and intentionally read-only queues remain unchanged. Keep CR-01 tracked as a separate unresolved security issue.

**Delivered:** Phases 151–154 completed 21 plans and satisfied all nine requirements. App registration has its own page and app task pages are focused; overview counts open exact read-only queue subsets; all 30 admin paths use the PRODUCT.md vocabulary and one page-hero contract; controls meet 3:1 contrast with visible focus in light and dark themes; and a local-only, navigate-only browser harness produced 928 passing redaction-safe checks across 7 widths and 3 themes. Phases 151–153 were re-verified at HEAD during closeout after Phase 154 edited shared files.

**Closeout:** Audit `tech_debt`, no blockers. Accepted: four deferred layout-polish items, the "Add app" path when the inventory read fails, emulated rather than native 200% zoom, and a possible keyboard-harness flake. Two out-of-scope todos (DCR default lifetime semantics; Bandit bump in demo hosts) were acknowledged. No protocol, storage or security code changed and no package was published. See the [v1.42 audit](milestones/v1.42-MILESTONE-AUDIT.md), [roadmap](milestones/v1.42-ROADMAP.md), and [requirements](milestones/v1.42-REQUIREMENTS.md).

## Completed Milestone: v1.41 Product Language & Repository Clarity (Completed 2026-10-11)

**Goal:** Make Lockspire's admin UI language plain, accurate, and consistent, then give adopters and maintainers a clear route through the repository and trustworthy documentation.

**Target features:**
- Review and simplify admin UI labels, headings, instructions, errors, empty/success states, and confirmations from the perspective of the people using them: their goals, familiarity, mental models, questions, and decisions. Translate internal concepts into user-facing language that helps them act; preserve protocol meanings, security distinctions, and truthful consequences. Name the task or object; do not use “operator” as visible audience copy or generic UI filler.
- Use the reviewed vocabulary to improve the README and canonical adopter/maintainer documentation; verify navigation, setup steps, links, and claims against current code and `docs/supported-surface.md`.
- Clarify repository directory ownership and lifecycle, and move or remove clutter only after verifying it is stale, unowned, and unused by CI, tests, packaging, or maintained workflows.

**Delivered:** Phases 148–150 completed 10 plans and 24 tasks. Admin pages now use task- and object-centered language while preserving OAuth/OIDC distinctions and truthful outcomes. Contributors have a source-backed repository lifecycle map; Phoenix adopters and maintainers have a direct path through product fit, canonical installation, verification, and task guides. All eight requirements passed verification, the cross-phase audit found no broken flows, and no manual UAT was needed for the covered facts.

**Closeout:** The audit records one acknowledged copy-scope compiler-warning follow-up and three ambiguous Git worktree records preserved until ownership is established. This was planning and documentation work; Lockspire 1.5.1 remains the latest public package. See the [v1.41 audit](milestones/v1.41-MILESTONE-AUDIT.md), [roadmap](milestones/v1.41-ROADMAP.md), and [requirements](milestones/v1.41-REQUIREMENTS.md).

## Verification and Automation Default

Treat executable verification as the default. For each feature or maintenance change, identify the highest-value unit, integration, end-to-end, smoke, and seam checks; automate them and run them as early as practical. Put checks in CI when they provide recurring value and can run reliably there. Aim for zero human UAT or verification handoffs: reserve maintainer attention for the judgment, access, or real-world observation that cannot be established safely and reliably by automation. Prefer deterministic evidence that fails visibly and explains what remains unverified.

Once a repeatable check is automated and required CI proves it, do not add a manual UAT/signoff step for the same property or reopen that choice without new evidence that automation cannot establish it. Keep human approval for genuinely consequential external actions, such as a specifically identified ref update, separate from verification.

Before presenting a UAT checkpoint, map each criterion to current focused tests, end-to-end/smoke/seam checks, and required CI evidence. Add only missing deterministic checks with recurring regression value. If rendered or subjective acceptance belongs to a later phase, record that owner and reason instead of handing the same check to the user.

The user reaffirmed this default during Phase 167 verification on 2026-10-22 and delegated routine verification classification and evidence review to the agent. Follow [VERIFICATION-POLICY.md](VERIFICATION-POLICY.md): missing check descriptors are planning metadata to repair, not a reason to request maintainer signoff. Preserve explicit evidence limits and record each closure so later sessions do not repeat it.

## Recent Milestone: v1.40 Admin Operator UI Refinement (Completed 2026-10-10)

**Goal:** Refine Lockspire's existing operator UI into a calm, coherent interface for configuration, investigation, and operations, with a working preview and bounded automated/browser verification.

**Delivered:** Phases 144–147 completed 21 plans across the mounted synthetic preview, Configure/onboarding, Support/Orient/read-only operations, and cross-surface refinement. All 24 milestone requirements and eight reviewed operator flows are satisfied. The GSD closeout is an override because three phase reports are stale after covered-source edits and Phase 146 remains `human_needed`; the original report verdicts were preserved. Billingo is synthetic demo-adopter data, not a real customer or account. See the [archived requirements](milestones/v1.40-REQUIREMENTS.md), [roadmap](milestones/v1.40-ROADMAP.md), and [audit](milestones/v1.40-MILESTONE-AUDIT.md).

## Completed Milestone: v1.38 Repository Baseline & Reconciliation

**Goal:** Bring Lockspire to a clean, green, internally consistent maintenance baseline, then close only concrete loose ends supported by repository evidence.

**Target features:**
- Verify that local Git state, branches, tags, worktrees, GitHub pull requests and issues, required CI and release workflows, local quality gates, and repository hygiene all have an intentional disposition.
- Reconcile GSD planning state, roadmap and requirements truth, release records, maintained documentation, and other repository-owned evidence so they describe one coherent baseline.
- Audit existing plans, findings, todos, and archived evidence, fixing only blockers, regressions, contradictions, stale actionable artifacts, and small high-confidence maintenance gaps while deferring speculative or feature-sized work.

**Delivered:** Phases 138-141 closed the repository evidence baseline, exact-SHA required CI and Release no-publish acceptance, and a sustaining-train handoff. This v1.38 completion archives planning only and publishes no package; Lockspire 1.5.0 remains the latest public release. Three audit items were acknowledged at closeout: one halted Phase 139 verification-repair task and the `gaps_found` reports for Phases 139 and 140. See [MILESTONES.md](MILESTONES.md) and [STATE.md](STATE.md).

## Completed Milestone: v1.39 Verified 1.5.1 Release

**Goal:** Correct the release record on `main`, land the reviewed Phase 141 baseline, and publish Lockspire 1.5.1 only after exact-main checks and protected artifact verification pass.

**Target features:**
- Merge the corrected release record through the normal reviewed PR path, keeping 1.5.0 identified as the latest public package until 1.5.1 is proven public.
- Require green CI and a passing repository-hygiene check for the exact current `main` revision before release.
- Use the protected release workflow to publish the manifest-verified 1.5.1 artifact and verify its public checksum, matching GitHub release, and clean-room install journey.
- If any gate fails, preserve the evidence, record the blocker, and make no claim that 1.5.1 shipped.

**Verification:** Use the existing required CI, repository-hygiene, protected publish, and public install checks as the acceptance evidence. Do not add a manual UAT step for a property those checks prove.

**Delivered:** Phase 142 corrected and verified the main baseline. Phase 143 published and verified Lockspire 1.5.1 from `0b56503859b69531ff86d8e4a465a0e75f963594`, with canonical CI, protected run, package checksum, release/tag target, docs, and clean-room install evidence joined in the release receipt. The Phase 143 verifier remains `gaps_found` (16/18) because retained records do not establish an exact-head maintainer merge decision for PR #119. The user acknowledged this historical provenance gap for forward development; no approval is inferred from the separate publication approval. See the [milestone audit](milestones/v1.39-MILESTONE-AUDIT.md) and [milestone history](MILESTONES.md).

## Completed Milestone: v1.37 Prime-Time Readiness Ratchet

**Goal:** Make Lockspire's documented embedded-provider path genuinely installable, prove it through a separate SaaS client and resource-server journey, and tighten the architecture and executable quality gates around that truth.

**Target features:**
- Make generated routes, host consent, migrations, required configuration, claims examples, and default generated tests executable from a packaged Lockspire artifact.
- Prove a clean-room Phoenix SaaS provider plus separate-origin confidential client and protected resource API across OIDC validation, token lifecycle, negative cases, and durable DPoP replay protection.
- Improve public API truth, dependency topology, storage and token cohesion, static-analysis depth, test readability, CI signal, conformance reproducibility, and release artifact proof without breaking v1.x behavior.

**Delivered:** Phases 131-137 are complete, verified, audited, archived, and published as Lockspire 1.5.0. The milestone shipped executable packaged installation, semantic public resource-server APIs, a real separate-origin SaaS journey, cycle-free and cohesive internals, high-signal quality gates, immutable supplemental conformance evidence, and exact-artifact public release proof while preserving the embedded-library boundary and secure defaults.

## Completed Milestone: v1.36 Structural Quality Ratchet

**Goal:** Raise Lockspire's correctness, release safety, architectural clarity, static-analysis signal, compatibility proof, and code readability through high-yield structural improvements without adding protocol surface or changing public behavior.

**Delivered:** Phases 126-130 are complete, verified, audited, and archived. The milestone bound publication to exact successful-CI evidence, made static-analysis/coverage/minimum-version claims executable, repaired host-Repo/storage boundaries, decomposed token orchestration behind stable facades, centralized lifetime and private-key policy, and made repository proof easier to maintain without adding protocol surface or changing public behavior.

## Current State

Latest public package: **1.6.1**, published and independently verified on2026-10-20 from source `d04be40262e975a4eb8d8567eb0d1458a9c23181`. The key re-encryption task now uses the shared repo runner and safe error classifier. Protected run 39496849388 and fresh public install/checksum/docs/tag proof passed. See [release evidence](releases/1.6.1-EVIDENCE.md). v1.46 Embedded Host Integration Reliability is complete, audited and archived (2026-10-24): 4 phases, 16 plans, 15/15 requirements. v1.47 is complete, audited and archived:4 phases, 10 plans and14/14 requirements. PR140 delivered the reviewed work to accepted main `173059a166e9ade0f5f57c9980b7b2400a98538c`; fresh local acceptance, seven canonical push CI jobs and Release no-publish passed. The implementation includes the earlier reviewed cumulative delivery. Public package publication remains separate.

v1.44 Adopter Polish & Verified 1.6.0 has delivered its scoped work and public release (2026-10-20). The host-facing repo-start, KEK setup and admin guidance improvements are shipped; the release ledger is on main. All four phases are complete and verified; the milestone is audited and archived. The bounded keys.reencrypt follow-up is merged in PR135 and publicly shipped in verified1.6.1. DCR lifetimes subsequently completed in v1.45; the verified public package remains 1.6.1.

v1.43 Signing Key Encryption at Rest is complete and archived (2026-10-16). Phases 155–157 delivered all 16 requirements in 14 plans and closed CR-01: private signing keys are encrypted at rest under a rotatable host KEK, existing installs have a checked migration path, and redaction is proven across every surface. This work is now publicly shipped in 1.6.0 together with v1.44 adopter polish.

v1.42 Admin UI Clarity & Workflow Refinement is complete and archived (2026-10-15). Phases 151–154 delivered all nine requirements in 21 plans; every phase is verified, Nyquist-validated and security-audited, and the full suite passes (1573 tests).

v1.41 Product Language & Repository Clarity is complete and archived. Phases 148–150 delivered all eight requirements in 10 plans and 24 tasks; the milestone audit found no unsatisfied requirements or broken flows. The Phase 999.1 repository readability/docs-polish scope was delivered through these phases and should not be run again.

The v1.40 Admin Operator UI Refinement milestone closed on 2026-10-10 with all 24 requirements and eight reviewed flows satisfied across Phases 144–147 (21 plans). The override closeout records three phase reports as stale after covered-source edits and Phase 146 as `human_needed`; original verification reports were preserved. The late policy/client readiness changes passed 35 focused tests and a clean code review. The audit makes no claim that every phase currently has fresh verification.

Billingo is a synthetic demo-adopter fixture in Lockspire's adoption demo. It is not a real customer or production integration. The stable preview remains backed by synthetic data, and mutation checks use a separate disposable target.

Lockspire 1.6.1 is the latest public package, verified through protected run 39496849388 and independently from public sources; checksum `629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d`. Repository readability/docs-polish backlog Phase 999.1 was promoted into v1.41 and delivered through Phases 148–150. The CR-01 private-key-at-rest finding, left open by the UI milestones (v1.40, v1.42), was resolved in v1.43.

The embedded-library shape, host-owned account/login/layout/branding/policy seam, protocol security defaults, and sustaining GA release-train posture remain unchanged. Verification defaults to deterministic tests and CI where they provide recurring value; human handoffs remain only for subjective or otherwise unreachable evidence.

## Completed Milestone: v1.32 Admin Page IA & Interaction Model Polish

**Goal:** Make the admin/operator UI feel deliberately composed page by page, with judgment-level IA, component-group, copy, interaction, and responsive polish that advances from v1.31 without regressions.

**Target features:**
- Add deterministic page and section scorecards for every admin route that judge persona, JTBD, top task, information hierarchy, redundancy, "is this element earning its place?", empty/error/long-data states, mobile behavior, theme parity, focus, and motion.
- Deeply polish the highest-pressure Support and Operate clusters first: tokens, consents, interactions, device authorizations, and logout deliveries under dense, long, empty, warning, incident, and read-only queue states.
- Propagate only proven patterns into Configure onboarding and lifecycle surfaces: clients, DCR/IAT, keys, policies, copy-once handoffs, and destructive confirmations.
- Lock the improvement loop with ugly redaction-safe fixtures, source/rendered guardrails, browser/manual evidence, operator docs, and a final adversarial review that keeps lab, judge, and browser proof maintainer-only.

**Why now:** v1.31 strengthened foundations, primitives, fixtures, and broad weak-page coverage. The remaining quality gap is more judgmental than structural: make each page and component group feel necessary, coherent, least-surprising, and operator-flow-oriented instead of drifting toward info dumps or generic admin density. This milestone preserves the embedded-library boundary and treats Support + Operate pages as the first quality bar before propagating patterns.

**Delivered:** Phases 121-125 are complete, verified, audited, and archived. v1.32 shipped route scorecards, Support and Operate flow polish, Configure propagation, redaction-safe fixtures, browser/manual evidence, deterministic guardrails, bounded operator docs, and adversarial proof without protocol, storage, host-seam, public lab, theming, browser-tooling, or support-surface creep.

## Completed Milestone: v1.31 Admin Design-System Stress Test

**Goal:** Systematically strengthen the Lockspire admin/operator design system so foundations, primitives, component groups, weak pages, fixtures, and browser evidence all move forward together without regressions.

**Target features:**
- Create a lightweight Lockspire-owned component lab and stress surface that renders real admin primitives, component groups, ugly fixture data, light/dark/system theme states, reduced-motion states, and key empty/error/disabled/danger paths without adding a supported runtime admin route.
- Upgrade shared Phoenix function components and embedded BEM/design-token CSS around architectural panes, entity headers, workflow shells, status/action clusters, lifecycle rows, dense resource rows, form/error primitives, semantic status coverage, theme behavior, and motion guardrails.
- Apply the strengthened system to the highest-drift admin surfaces: client detail, DCR policy, IAT index/new, token and consent support pages, and device/interactions/logout operation queues.
- Add regression guardrails and fresh browser evidence for responsive widths, theme modes, focus, accessibility, long values, redaction, and no-page-overflow behavior.

**Why now:** v1.29 made the admin UI coherent and v1.30 made the adoption demo boring to start and inspect. The next leverage point is not protocol breadth; it is making the admin UI's design system compound at the component and group level so future operator pages can be improved idempotently without reintroducing generic styling, inaccessible controls, dark-mode regressions, mobile overflow, or host-integration weight.

**Delivered:** Phases 116-120 are complete, verified, audited, and archived. The component lab contract, stress fixtures, shared primitives, highest-drift admin page/group pass, browser proof matrix, deterministic regression guardrails, bounded operator docs, and final adversarial audit shipped without adding public lab/design-system/theming support or browser-tooling product surface.

## Completed Milestone: v1.30 Adoption Demo Docker DX & Repo Hygiene

**Goal:** Make the repo-local adoption demo easy to start, hard to conflict with other local projects, and clean enough to serve as the stable base for the next admin UI polish milestone.

**Target features:**
- Support conflict-resistant local development through configurable project names, ports, and optional Traefik hostname routing.
- Print the important demo URLs, admin routes, seeded accounts, and smoke-test command after startup so maintainers can poke the admin UI without source-diving.
- Add a repo hygiene gate and cleanup lane for generated demo artifacts, Docker leftovers, and dirty local state before the next UI milestone.

**Why now:** v1.29 produced route-complete admin UI proof, but the next UI iteration needs a boring, repeatable local demo base. Docker port conflicts and leftover generated artifacts are recurring friction when multiple local Elixir OSS libraries with admin UIs are running side by side.

**Delivered:**
- Phase 111 unified the adoption demo around `LOCKSPIRE_DEMO_BASE_URL` for endpoint URL generation, issuer, seed URLs, developer callback output, and smoke drift proof.
- Phase 112 added the direct Docker app plus PostgreSQL path with explicit DB wiring, project-scoped volumes, idempotent setup, and HTTP readiness.
- Phase 113 added configurable Compose project names, app ports, optional DB host exposure, scoped reset, and opt-in Traefik hostname routing.
- Phase 114 added redacted startup/reprint output, wrapper-driven smoke proof, Docker-first docs, and project-aware reprint guidance.
- Phase 115 added scoped stop/reset/cleanup helpers, local PASS/WARN/BLOCK hygiene, Docker-free CI hygiene contracts, and final lifecycle proof.

## Completed Milestone: v1.29 Admin UI Journey & Design-System Deep Polish

**Goal:** Take the shipped admin UI from coherent baseline to a deliberately mapped operator product where every route, component, and state supports a clear persona, job, next action, and safety boundary.

**Target features:**
- Define and enforce an admin journey contract that maps every admin route to operator persona, JTBD, entry point, primary decision, safe action, empty state, risk state, and follow-up route.
- Deepen the shared BEM/design-token system so reusable Phoenix components carry layout, status, action, data-display, responsive, focus, and reduced-motion behavior consistently.
- Polish the least-iterated support and operations surfaces first, then tighten DCR/IAT, keys, client-detail action grouping, mobile table/list behavior, and demo seed expressiveness.
- Re-run browser screenshot and contract proof across the full admin route surface so docs, seeds, design-system tests, and desktop/mobile evidence remain aligned.

**Why now:** v1.28 proved the admin UI can read as one coherent operator surface. The next highest-leverage adoption wedge is not more protocol breadth; it is raising the weaker pages and cross-route mental model to the same standard so operators can orient, configure, support, and operate without guessing.

**Delivered:**
- Phase 107 defined the route-by-route admin journey contract, aligned operator docs to Orient/Configure/Support/Operate, and added deterministic route/docs drift proof.
- Phase 108 deepened the shared BEM/design-token component contract for layout, status, action, data display, focus, responsive, and reduced-motion behavior.
- Phase 109 polished weak support, operations, DCR/IAT, key, and client-detail surfaces while preserving route vocabulary and host-owned seams.
- Phase 110 completed demo seed, docs, screenshot inventory, browser click-through, regression, and 390px mobile no-page-overflow proof.

## Recently Shipped Milestone: v1.28 Admin UI Operator Experience Polish

**Goal:** Make the Lockspire admin UI feel like one coherent operator product without adding protocol breadth or weakening host-owned seams.

**Delivered:**
- Added shared admin components and BEM/design-token CSS primitives for forms, actions, data display, confirmation panels, resource rows, badges, responsive behavior, and focus/motion states.
- Reworked client detail into a canonical client workspace covering identity, effective posture, credentials, endpoints, logout, DCR/RAT context, and safe actions.
- Polished support, operations, policy, DCR, and key lifecycle workflows around scan-friendly queues, exception pressure, lifecycle safety, and partner handoff context.
- Verified demo seed state coverage, operator admin docs, desktop/mobile screenshot inventory, and design-system regression contracts.

**Why now:** The admin surface now spans enough setup, partner, support, security, operations, DCR, and key workflows that operator clarity and design-system consistency became the highest-leverage adoption wedge.

## Archived Milestone Snapshot: v1.26 Host Integration & Operator Boundary Hardening

**Goal:** Make the first real Phoenix SaaS adoption path clearer without adding protocol breadth.

**Delivered:**
- Added `Lockspire.Web.AdminRouter` as a bounded admin-only router that hosts can mount behind their own operator-auth pipeline.
- Updated generated router and account-resolver scaffolding so account lookup, stable subject claims, tenant checks, product authorization, and Sigra-specific wiring stay host-owned.
- Improved first-client CLI output with token endpoint auth truth and practical next steps for proving authorization-code + PKCE.
- Added a compact SaaS adoption recipe and release-readiness assertions that pin the host-owned account/operator boundary.

**Why now:** `v1.25` made the shipped advanced setup story coherent. The next highest-leverage adoption wedge was not more protocol breadth; it was reducing first-adopter ambiguity at the host seam.

## Archived Milestone Snapshot: v1.25 Support-Burden Reduction

**Goal:** Reduce advanced setup ambiguity on already-shipped high-trust surfaces so adopters can configure, diagnose, and support Lockspire without source-diving or relying on maintainer tribal knowledge.

**Delivered:**
- Lockspire now classifies remote `jwks_uri` incidents through one shared diagnostics model and exposes the same bounded-reactive support story across runtime, doctor, admin, and docs.
- `mix lockspire.doctor remote-jwks` and the admin client detail Remote JWKS panel now provide one calm remediation path and ownership split without widening install-time verification.
- The canonical mTLS, logout propagation, and protected-route guidance now states one explicit Lockspire-owned versus host-owned support boundary.
- Release-contract assertions and representative runtime regressions now fail loudly if the advanced-setup support story drifts from shipped behavior.

**Why now:** `v1.24` closed the last practical direct-client auth gap. The remaining high-leverage work was support cost and setup ambiguity on advanced surfaces Lockspire already shipped.

## Recently Shipped Milestone: v1.27 Phoenix Resource Server Token Acceptance

**Goal:** Make it obvious which Lockspire-issued token shape a host Phoenix API should accept, how that relates to `Lockspire.Plug.VerifyToken`, and what CI proof backs the blessed path — without conflating stored opaque access tokens with JWT bearer route-protection fixtures.

**Delivered:**
- `Lockspire.Plug.VerifyToken` narrowed to RFC 9068 `at+jwt` only, with strict `typ`, `iss`, and required claims validation.
- One shared `AccessTokenSigner` now owns RFC 9068 `at+jwt` issuance across all grant paths.
- Default access-token issuance format flipped from opaque to `:jwt` for AC, refresh, device, and CIBA paths, with a runtime-settable server default and nullable per-client override.
- End-to-end sender-constraint proof (DPoP and mTLS) delivered across the canonical pipeline, closing misordered-pipeline bypasses.
- The adoption demo is re-wired to use the blessed `at+jwt` path against the protected route.
- Generated-host scaffolding, operator telemetry, and migration diagnostics all shipped to reflect the new default issuance.

**Why now:** `v1.26` delivered the host integration seam and adoption demo, but in doing so exposed an unfinished design tension: the demo uses Lockspire's issued stored access token against Lockspire `/userinfo`, while the Phoenix protected-resource plug remains JWT-bearer-oriented. That ambiguity is now a real first-adopter trip hazard — and the earmark documented in `STATE.md` and `.planning/ROADMAP.md` flagged this as the next feature-sized wedge once adopter evidence justifies leaving sustainment.

## Release Train Default

**Goal:** Preserve Lockspire as a boring sustained GA library: patch-on-merge for eligible fixes, one maintainer hygiene gate, one CI drift fence, and one canonical release ledger instead of milestone churn.

**Default rules:**
- `milestone: none` is the normal GSD state.
- Patch-eligible merged changes flow toward the next patch release through Release Please on `main`.
- The train only moves when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` reports no `BLOCK`.
- New feature milestones should open only when explicit adopter evidence shows work that is larger than patch/support/release-hygiene sustainment, and should use one `milestone/vNEXT-short-slug` branch plus one PR to `main`.

**Why now:** Lockspire is near-done for its intended scope. At this maturity level, friction and ambiguity in repo/release hygiene are a bigger adoption risk than missing another protocol wedge, so the default should encode stability rather than roadmap momentum.

## Archived Milestone Snapshot: v1.24 client_secret_jwt

**Goal:** Add a narrow `client_secret_jwt` authentication slice on Lockspire-owned direct-client endpoints without widening the embedded-library shape or weakening current secret-handling posture.

**Delivered:**
- Lockspire-owned direct-client surfaces now accept valid `client_secret_jwt` assertions through one shared runtime path instead of implicitly treating all JWT assertions as `private_key_jwt`.
- The symmetric JWT verifier preserves the existing secret-at-rest posture by storing sealed verifier material alongside the hashed client secret, and it enforces HS256-only, issuer-string audience, bounded lifetime, replay, and FAPI-denial rules.
- DCR, RFC 7592, discovery, and admin/operator surfaces now publish one coherent `client_secret_jwt` plus `HS256` truth without exposing verifier material or claiming broader support than the runtime actually ships.
- Canonical docs, maintainer guidance, discovery metadata, release-contract tests, and full regression proof now all agree on the narrow support boundary for the shipped `client_secret_jwt` slice.

## Archived Milestone Snapshot: v1.23 DCR Logout Metadata

**Goal:** Let self-service clients manage Lockspire's existing logout propagation metadata through DCR and RFC 7592 without broadening the product boundary.

**Target features:**
- Accept, validate, store, and expose `backchannel_logout_uri` plus `backchannel_logout_session_required` through DCR create/read/update flows.
- Accept, validate, store, and expose `frontchannel_logout_uri` plus `frontchannel_logout_session_required` through DCR create/read/update flows.
- Keep repo-native proof and support-truth docs aligned with Lockspire's existing asymmetric logout model: durable back-channel delivery and best-effort front-channel cleanup.

**Why now:** This milestone has shipped and is archived in `.planning/milestones/v1.23-ROADMAP.md` plus `.planning/milestones/v1.23-REQUIREMENTS.md`.

<details>
<summary>Previous milestone snapshot</summary>

### v1.22 DPoP Nonce Support

**Goal:** Add automatic DPoP nonce challenge and retry behavior across all shipped Lockspire DPoP validation surfaces.

**Delivered:**
- A shared stateless DPoP nonce primitive with strict authorization-server vs resource-server purpose separation.
- Retryable `use_dpop_nonce` behavior on Lockspire-owned `/token` and `/userinfo` surfaces.
- Nonce-aware host Phoenix protected-route enforcement through the shipped `VerifyToken -> EnforceSenderConstraints -> RequireToken` pipeline.
- Support-surface, onboarding, and protected-route docs that now describe the shipped nonce-backed DPoP slice truthfully.

</details>

## Requirements

### Active

Selected v1.48 scope: independent verifier-key custody and rotation, compatible legacy/mixed-version upgrades, safe maintenance/recovery and packaged proof. Detailed requirements are being defined through `$gsd-new-milestone`; none is implemented or verified yet.

Completed scope remains in [v1.47 requirements](milestones/v1.47-REQUIREMENTS.md) and [v1.46 requirements](milestones/v1.46-REQUIREMENTS.md).

### Validated

- ✓ Source-bound selected authorization/PAR proof and resumable delivery handoff — v1.47 CPROOF-01..02, DELIV-01..02, Phase 174; 23/23 goal verification, exact twelve-case package receipt, 17 declared mitigations closed, clean ten-file source review, complete local candidate CI and seven hosted jobs at `9b8cf54d`. PR #140 merged as `173059a1`; fresh main acceptance and seven push CI jobs passed with Release no-publish. Publication remains separate.

- ✓ Selected pushed-request authority, retained lifecycle/required-PAR and configured metadata — v1.47 PARB-01..03, Phase 173; six verified behavioral truths, actual real-PAR RED/GREEN, 132 passing selected regression tests, five verified mitigations and one documented low accepted boundary. Two non-authoritative judgment prohibitions retain prominent human-review recommendations; external profiles remain unlaunched.

- ✓ Selected authorization responses and preserved callback/silent-authentication outcomes — v1.47 AUTHR-01..03, Phase 172; 11/11 goal verification, actual Router RED/GREEN, 131 passing selected regression tests, six planned threats closed and all review findings fixed. Only the unsupported-mode classification changed production behavior; host accounts/sessions remain host-owned.

- ✓ Accepted implementation base and finite supported-case qualification — v1.47 BASE-01..02, FIND-01..02, Phase 171; 10/10 goal verification, 22 passing ledger tests, two controlled counterexamples retained for downstream correction, 15 planned threats closed and clean review. External profiles were not launched.

- ✓ Packaged-host transport, exact-version runtime and required CI wiring — v1.46 HPROOF-01..03, Phase 170; six cells × 16 browser cases, 43/44 lifecycle checks, 202 prior-phase regressions, 19/19 security threats closed and no human UAT. See [verification](milestones/v1.46-phases/170-packaged-host-and-compatibility-proof/170-VERIFICATION.md). Hosted CI remains unobserved.

- ✓ Safe generated installation/upgrade, truthful structural diagnostics and consistent demo/docs — v1.46 HDX-01..04, Phase 169; 160 phase tests, 63 prior-phase regression tests, 2,022 broad checks, 22/22 security threats closed, clean final review and zero human UAT checks. Package/browser/exact-floor/CI proof remains Phase 170.
- ✓ Host-owned HTTP, disconnected/connected entry, cached-session rejoin, cross-session/admin navigation and native patch authorization — v1.46 HAUTH-01..04, Phase 168; 45 focused tests, 1,977 broad checks, 15/15 security threats closed, clean code review and zero human UAT checks. Browser/socket and exact-floor proof remains Phase 170.
- ✓ Host-expanded admin routing, full 29-route/action parity, configured mount journeys and independent public/consent routing — v1.46 MNT-01..04, Phase 167; 48 fresh focused tests, zero remaining human UAT checks.

- ✓ Selected lifetime semantics, endpoint effects, offline limits and upgrade contract (DCR-02/03/04) — v1.45, Phase 162.
- ✓ App lifetime persistence, current-authority enforcement, legacy migration and declared host-storage compatibility (DCR-05/06/13/14) — v1.45, Phase 163.
- ✓ Truthful secret-expiry metadata, shared-secret authentication and atomic policy-derived rotation (DCR-07/08/09) — v1.45, Phase 164.
- ✓ Management-token lifecycle, strict current-row management, atomic replacement and host-owned recovery (DCR-10/11/12) — v1.45, Phase 165.
- ✓ Deterministic lifetime boundaries, PostgreSQL contention/rollback, packaged host journeys, scoped security/CI and evidence-aligned guidance (DCR-15/16/17/18/19) — v1.45, Phase 166; final candidate f8dd7712, 69 mapped cases, 49/49 package checks and seven successful required CI contexts. Undefined probes and descriptor-less prohibitions remain limited as recorded in the audit.

- ✓ Policy-derived management-token issuance, strict current-row GET/PUT/DELETE authority, immediate atomic replacement and host-owned recovery (DCR-10/11/12) — Phase165;37/37 truths,19/19 threats closed,2,413-test fast gate plus independent integration/PostgreSQL and908-test prior-phase evidence.

- ✓ Repo-free `mix lockspire.gen.kek`, shared fail-closed snippet, runtime `{:system, "VAR"}` resolution and redacted key-set inspection (KEK-03, KEK-05, KEK-06) — v1.44, Phase 159; reverified after guide edits with 83 tests / 0 failures and a fresh public-package task run.
- ✓ Read-only Key protection states and specific missing-KEK generation guidance, with vocabulary contracts (KEY-UI-01..03) — v1.44, Phase 160; existing verified report plus current118-test cross-phase regression gate.
- ✓ Task-focused install/upgrade/operator guides and executable label/pointer contracts (DOC-02), with warning-free CI docs builds — Phase 161.
- ✓ Release Please1.6.0 coverage for v1.40–v1.44, protected exact-source publication, mandatory receipt/manifest evidence, independent public/fresh-install proof and release ledger on main (REL-01, REL-02, SAFE-02) — Phase 161; source428a9c53, protected run 39481079989.
- ✓ `mix lockspire.client.create`, `doctor token_format` and `doctor remote-jwks` start and stop the host repo themselves through `RepoRunner` (an already-running pool is left untouched), report real failure reasons as fixed secret-free phrases via `Lockspire.Install.TaskError`, print a client secret once only after a committed write, and are proven by cold tests plus the clean-room journey (TASK-01..03) — v1.44, Phase 158; verifier passed 4/4, security 15/15, code review 7/7 fixed. The `keys.reencrypt` follow-up was subsequently completed in PR135 and publicly shipped in verified1.6.1.
- ✓ Demo and clean-room hosts on Bandit 1.13.1; strictly validated `:key_encryption` KEK list in runtime config with no `secret_key_base` fallback; every new private signing key sealed as an AES-256-GCM `LSK\x01` envelope bound to its kid; missing KEK keeps boot and existing signing working while generation refuses (DEP-01, KEK-01, KEK-02, ENC-01..03) — v1.43, Phase 155; verifier 5/5.
- ✓ Locked, CAS-guarded `mix lockspire.keys.reencrypt` legacy migration and KEK rotation with dry-run, `--check` readiness and durable audit; opt-in `legacy_plaintext: :reject` refuses plaintext before any parser runs (MIG-01..03, OPS-01, OPS-02) — v1.43, Phase 156; verifier 5/5, security 19/19.
- ✓ No key material in admin, telemetry, log, error or operator output; fail-closed install KEK block; upgrade-journey and CI `--check` proof; HexDocs upgrade guide; SAFE-01 gate green against v1.42 (RED-01, HOST-01, PROOF-01, DOC-01, SAFE-01) — v1.43, Phase 157; verifier passed.
- ✓ All 30 admin paths use plain, task-focused language and one page hierarchy, with retired wording enforced by `vocabulary_contract_test.exs` (UI-01, UI-02, UI-06) — v1.42, Phase 153; verifier 3/3 (re-verified at HEAD), 219 mapped tests, security 12/12.
- ✓ Changed pages stay usable at 7 widths in light, dark and system themes with 3:1 control contrast, visible focus and reduced motion; redaction-safe browser evidence and a bundled page contract on every admin route; security defaults, redaction, copy-once, revocation scopes and read-only queues proven unchanged (UI-07, PROOF-01, SAFE-01) — v1.42, Phase 154; verifier 3/3, 928 browser checks, security 22/22.
- ✓ App registration has its own focused route with a filter-preserving return, app task routes lead with the app and task, and primary/secondary/destructive action emphasis follows a documented rule (UI-04, UI-05) — v1.42, Phase 151; verifier 8/8, 55 focused tests, full fast suite green. Code review (5 warnings, 3 info) and the UI review fixes were applied afterwards; the review ledger shows 0 open.
- ✓ Overview counts and queue filters share one waiting rule, failed reads stay distinct from empty results, token-reuse and app sign-out notice copy avoids claiming compromise or a confirmed sign-out, and queue rows redact request identifiers (UI-03) — v1.42, Phase 152; verifier 3/3, 41 focused tests, full fast suite green. Code review (3 warnings, 3 info) and UI review fixes applied; review ledger 0 open.
- ✓ Existing admin pages use task-focused, plain language while preserving protocol meanings, security consequences, redaction, and host-owned UX boundaries — v1.41, Phase 148; verifier 33/33, 215 focused tests, and responsive review at desktop, tablet, and mobile sizes. No user-comprehension claim is made.
- ✓ Contributors can identify the purpose and lifecycle of repository areas, and cleanup decisions are backed by ownership/reference evidence — v1.41, Phase 149; ambiguous worktree and retained artifacts were preserved.
- ✓ Phoenix adopters and maintainers can follow task-oriented README/HexDocs routes through canonical installation and verification; setup claims match source, and published guide/package boundaries are automated — v1.41, Phase 150; verifier 7/7, focused docs contract, docs build, package build, and regression checks pass.
- ✓ Current mounted preview, refreshed route/state inventory, and shared improvements demonstrated in representative whole workflows — v1.40, Phases 144 and 147; GSD freshness limitations are recorded in the milestone audit.
- ✓ Consistent client, onboarding, credential, key, and security-policy configuration journeys — v1.40, Phase 145; visual coverage gaps remain disclosed.
- ✓ Clear token/consent investigation, truthful observation failures, and readable read-only operations — v1.40, Phase 146; functional truths passed, visual backstops remain `human_needed`.
- ✓ Coherent responsive, accessible, theme-aware, and reduced-motion behavior across the existing admin surface — v1.40, Phase 147; bounded evidence and freshness limitations are recorded in the audit.
- ✓ Bounded visual refinement and meaningful automated regression evidence, with a stable preview for optional user feedback — v1.40, Phases 144–147; Billingo preview data is synthetic demo-adopter data.
- ✓ The protected release workflow published one manifest-verified 1.5.1 artifact with matching public checksum, GitHub release/tag, docs, and clean-room install proof — Phase 143; source `0b56503859b69531ff86d8e4a465a0e75f963594`, CI `37788996197`, protected run `37795671282`, checksum `c13dabddef307dcb5d89490642272571e91d12bdf3fd14756e820600121df0b3`. The phase audit still records the separate PR #119 merge-authorization gap.
- ✓ Failed release attempts preserve per-stage evidence and distinguish public package presence from complete verification — Phase 143; the first failed attempt and the later evidence-retention failure are recorded without inferring a successful workflow or inventing missing evidence.
- ✓ The corrected Phase 141 release record is merged through a reviewed PR, and 1.5.0 remains the latest-release claim until public 1.5.1 proof exists — Phase 142; PR #113 merged at `6f1a19b39999f96eb24352c75c2a0628375175ae`, with public Hex/GitHub checks confirming no 1.5.1 release or tag.
- ✓ Required CI and repository hygiene pass for the exact current `main` revision before release dispatch — Phase 142; all seven canonical jobs passed on the accepted SHA and the private receipt records 24 PASS, 0 WARN, 0 BLOCK.
- Phase 132 aligned the public client and resource-server contract with shipped behavior: semantic `AccessToken` readers, shared capability-aware registration, exact redirect enforcement, durable fail-closed DPoP replay storage, truthful generated examples, and 16/16 modeled threats are verified.
- Phase 131 delivered the executable packaged-install path: generated host/router/consent seams compile and run, migrations and managed files install and upgrade transactionally, `mix lockspire.verify` reports all required seams, default and opt-in FAPI smoke proofs match their profiles, and the generated consent flow completes through token exchange with 31/31 modeled threats closed.
- Delivered v1.36 Structural Quality Ratchet: exact-ref release proof, executable quality and compatibility baselines, repaired storage boundaries, cohesive token internals, zero-warning Dialyzer, readable tests/runtime code, synchronized docs, and artifact hygiene were completed across Phases 126-130.
- Delivered v1.32 Admin Page IA & Interaction Model Polish: route scorecards, Support and Operate flow polish, Configure propagation, ugly fixtures, browser/manual evidence, deterministic guardrails, bounded operator docs, and final adversarial proof were completed across Phases 121-125.
- Embedded-library install and host-owned integration seams were delivered in the archived v1.0 milestone.
- Authorization code + PKCE, OIDC discovery/JWKS/userinfo, revocation, introspection, and refresh rotation were delivered in the archived v1.0 milestone.
- Operator/admin workflows for clients, consents, tokens, and keys were delivered in the archived v1.0 milestone.
- Security defaults, telemetry, auditability, redaction, and negative-path coverage were delivered in the archived v1.0 milestone.
- Canonical onboarding, executable docs, CI/release assets, and supported-surface policy were delivered in the archived v1.0 milestone.
- Repo-truth QA, contributor gate closure, trusted protected release proof, and preview-posture drift fences were delivered in the archived v1.1 milestone.
- PAR-backed authorization consumption on the existing authorization code + PKCE path was validated in Phase 15.
- Discovery, support docs, and SECURITY wording now describe only the shipped PAR slice, validated in Phase 15.
- PAR milestone closure and release-runtime hygiene were validated in Phase 16, including warning-free checked-in release automation.
- Deliver RFC 7591 `POST /register` intake bounded by operator policy without widening the embedded-library shape. Validated in Phase 26.
- Deliver operator policy controls for self-registration, Initial Access Tokens, and truthful discovery without widening the embedded-library shape. Validated across Phases 25-29.
- Deliver RFC 7592 client configuration management with `registration_access_token` rotation and admin-UI provenance. Validated in Phases 26-28.
- Implement `POST /device/code`, host-owned `/verify`, durable polling cadence enforcement, and `POST /token` device-code redemption with RFC 8628 outcomes. Validated across Phases 30-32.
- Generated-host proof, security posture, and support-truth docs for the device-flow slice were delivered and archived in the v1.6 milestone.
- Deliver DPoP core: proof validation, token binding, replay protection, and DPoP-aware issuance for authorization-code, refresh, and device-code exchanges. Validated across Phases 33-36.
- End-to-end proof, security posture, and support-truth docs for the shipped DPoP slice were delivered and archived in the v1.7 milestone.
- Session Management & RP-Initiated Logout workflows were verified and archived in the v1.8 milestone.
- Automated Back-Channel and Front-Channel Logout propagation mechanisms were verified and archived in the v1.8 milestone.
- Strict OIDC protocol validation and integer enforcement for timestamps were verified and archived in the v1.8 milestone.
- Implement RSA/EC encryption key management in `Storage.KeyStore` and advertise via JWKS, validated in Phase 40.
- Implement nested JWT validation (Sign-then-Encrypt) in `Protocol.Jar`, validated in Phase 40.
- Deliver single-flag configuration (`security_profile: :fapi_2_0_security`) to enable strict mode globally or per-client, validated in Phase 41.
- Enforce mandatory PAR usage and DPoP sender-constraining for token and userinfo endpoints when the profile is active, validated in Phase 41.
- Restrict cryptographic algorithms to `PS256` or `ES256` exclusively under the profile, validated in Phase 41.
- Strictly enforce exact redirect URI matching and expose FAPI 2.0 compliance in discovery metadata, validated in Phase 42.
- Delivered 1.0 GA stabilization including API contract lock, telemetry standardization, operator seams consistency, and formal security audit in the v1.11 milestone.
- Delivered OAuth 2.0 Token Exchange (RFC 8693) with host policy behavior and delegation depth enforcement in the v1.12 milestone.
- Implement OIDC CIBA Core: `/bc-authorize` endpoint, CIBA token grant type, and durable polling state machine. Validated across Phases 51-53.
- Deliver resilient CIBA notifications: Oban-backed webhook delivery for both Ping and Push modes, including direct token delivery in Push mode. Validated across Phases 51-53.
- Establish CIBA host seams: defined and integrated `Lockspire.Host` behaviours for out-of-band notification and user consent resolution. Validated across Phases 51-53.
- Support Rich Authorization Requests (RAR - RFC 9396) intake in PAR and Authorization pipelines. Validated in Phase 55.
- Deliver Resource Indicators (RFC 8707) for targeted audience claims and resource parameter validation. Validated in archived v1.14.
- Deliver Ecto-based RAR validation framework and durable storage for rich authorization details. Validated in archived v1.14.
- Expose rich authorization details via introspection and verify end-to-end flows. Validated in archived v1.14.
- Update Discovery metadata and provide executable documentation for the v1.14 advanced authorization surface. Validated in archived v1.14.
- Delivered 1.0.0 GA public release artifacts and post-release execution verification in archived v1.17 and v1.18.
- Phase 121 validated the v1.32 route scorecard and judgment contract foundation: source-derived admin route scorecards, deterministic rubric guardrails, review-fix regressions, and bounded operator docs now anchor the remaining Support, Operate, Configure, and proof phases.
- Phase 122 validated Support investigation flow polish: token and consent index/detail routes now lead with decision summaries, dense redaction-safe rows or detail panes, exact consequence copy, inline confirmation errors, and verified reuse/closed-state behavior without new public surface.
- Phase 123 validated Operate queue flow polish: interactions, device authorizations, and logout deliveries now render pressure-first dense rows with safe identifiers, redacted pivots, lifecycle/expiry/activity context, endpoint/attempt/support-note truth, source/API read-only guardrails, layout/theme/focus/reduced-motion proof, and a maintainer-only proof matrix without new command, route, schema, browser, or public support surface.
- Phase 124 validated Configure onboarding propagation: clients, DCR/IAT onboarding, keys, policy overview, DCR policy, PAR, DPoP, and security-profile pages now share page-first posture, route-specific safe actions, copy-once plaintext discipline, confirmation-backed destructive flows, redaction, UI-SPEC palette/type/action constraints, and cross-route source/stress proof without broadening public routes, APIs, schemas, packages, labs, theming, or host-owned seams.
- Phase 125 validated the v1.32 proof-docs adversarial ratchet: shared fixture stress proof, route-family rendered-HTML guardrails, browser/manual maintainer evidence, empty/no-match coverage, operator docs, and adversarial proof artifacts now close the milestone without adding browser tooling, lab routes, schemas, public support APIs, or host-owned policy surface.
- Delivered 1.0.0 GA public release artifacts and post-release execution verification in archived v1.17 and v1.18.
- Delivered FAPI 2.0 Message Signing support including JARM and JWT introspection responses in archived v1.19.
- Delivered Mutual TLS client authentication, certificate-bound tokens, and truthful MTLS discovery metadata in archived v1.20.
- Delivered first-class Phoenix API route protection for Lockspire-issued tokens in archived v1.21.
- Delivered automatic DPoP nonce challenge and retry support on Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline in archived v1.22.
- Delivered DCR registration intake, typed persistence, and truthful readback for Lockspire's shipped logout propagation metadata in Phase 85 of milestone v1.23.
- Delivered RFC 7592 logout metadata replacement/clear semantics, lifecycle proof, and support-truth docs in archived milestone v1.23.
- Delivered narrow shared-runtime `client_secret_jwt` support with sealed verifier material and strict HS256, replay, audience, and FAPI-denial posture in Phase 88 of milestone v1.24.
- Delivered coherent `client_secret_jwt` registration, RFC 7592, discovery, and admin truth in Phase 89 of milestone v1.24.
- Delivered canonical docs, release-contract proof, and milestone-close evidence for the narrow `client_secret_jwt` support slice in archived milestone v1.24.

- Delivered actionable diagnostics and remediation truth for `jwks_uri` rotation on Lockspire's shipped remote-JWKS surface in archived milestone v1.25.
- Delivered one canonical mTLS extraction, logout propagation, and protected-route setup support story in archived milestone v1.25.
- Delivered repo-native proof that advanced setup docs, diagnostics, and runtime behavior stay aligned in archived milestone v1.25.

- Delivered the host integration/operator boundary hardening adoption path (admin-only router, host-owned account/claims scaffolding, first-client CLI truth, SaaS adoption recipe) in milestone v1.26.
- Delivered v1.27 Phoenix Resource Server Token Acceptance: `Lockspire.Plug.VerifyToken` narrowed to RFC 9068 `at+jwt` with hardened reason codes (VERIFIER-01..06, Phase 98); single `AccessTokenSigner` `at+jwt` signing site across all five grant paths with the default format flipped opaque→`:jwt` (runtime-settable server default, nullable per-client override) and discovery advertising `access_token_signing_alg_values_supported` (SIGNER-01/02, FORMAT-01/02, AUD-01/02/03, DISCOVERY-01, Phase 99); sender-constraint end-to-end proof (BIND-01..03, Phase 100); adoption-demo re-wire onto the blessed `at+jwt` path (DEMO-01..03, RECIPE-01, DOCS-01/02, Phase 101).
- Delivered the v1.27 generated-host scaffolding, telemetry, and migration slice: regression guards fencing the no-token-format-prompt install + uncomment-ready canonical pipeline block (SCAFFOLD-01/02), the `[:lockspire, :rs, :token_format]` RS telemetry event at two `VerifyToken` sites via direct `:telemetry.execute/3` (TELEMETRY-01), the honest `docs/upgrading/v1.27.md` migration guide with runtime `ServerPolicy` opt-out and nil-inherit affected-client naming (MIGRATE-01), and the read-only `mix lockspire.doctor token_format` diagnostic (MIGRATE-02). Validated in Phase 102.
- Delivered v1.29 Admin UI Journey & Design-System Deep Polish: route-by-route admin journey contract and docs vocabulary (JOURNEY-01..06, Phase 107); reusable BEM/design-token admin primitives and reduced-motion/style drift fences (DESIGN-01..06, Phase 108); support, operations, DCR/IAT, key, and client-detail weak-spot polish with mobile-safe rows, redaction, and risky-action grouping (OPS-01..05, CONFIG-01..02, Phase 109); demo seed, screenshot, browser, docs, and contract proof including 390px mobile no-page-overflow evidence (CONFIG-03, PROOF-01..04, Phase 110).
- Validated in Phase 111: `LOCKSPIRE_DEMO_BASE_URL` is the single browser-visible adoption demo URL contract for endpoint URL generation, Lockspire issuer, seeded local URLs, developer callback output, and smoke proof; `LOCKSPIRE_DEMO_BIND_IP` controls only listener binding for Docker opt-in.
- Validated in Phase 112: the default Docker adoption-demo path starts direct Phoenix/Bandit plus PostgreSQL without host Postgres, uses explicit DB wiring and project-scoped `db_data`, `deps`, and `_build` volumes, prepares the database idempotently, and waits for the configured public URL before printing the ready line.
- Validated in Phase 113: conflict-resistant adoption-demo Docker controls support configurable Compose project names, app ports, scoped reset of active-project volumes, optional PostgreSQL host-port exposure, and opt-in Traefik hostname routing while keeping direct Docker as the default path.
- Validated in Phase 114: startup output prints redacted URL/account/client/smoke/reprint information from `docker-info`, `docker-start` uses container-local readiness separate from the public base URL, `scripts/demo/adoption_smoke.sh` wraps the existing Python OAuth/OIDC proof for direct and optional Traefik targets, and `docs/adoption-demo.md` documents Docker-first startup, smoke, stop, reset, cleanup boundary, overrides, and troubleshooting.
- Validated in Phase 115: adoption-demo stop, reset, cleanup, and hygiene commands are scoped to the active Compose project and allowlisted repo-owned artifacts; local hygiene reports PASS/WARN/BLOCK findings; CI hygiene remains Docker-daemon-free; useful admin UI evidence is preserved; lifecycle proof can leave no demo-owned BLOCK findings; and v1.30 does not broaden OAuth/OIDC protocol behavior, admin workflow behavior, production Docker packaging, hosted-auth shape, or public support claims.
- Delivered v1.31 Admin Design-System Stress Test: route/component/lab inventory and brandbook-derived visual rubric (LAB-01/LAB-03, Phase 116); redaction-safe test-only component lab fixtures plus light/dark/system and motion CSS foundations (LAB-02/PROOF-01/DS-01/DS-05, Phase 117); shared structural primitives, domain-aware status semantics, and representative form/workflow primitive adoption (DS-02/DS-03/DS-04, Phase 118); client detail, DCR policy, IAT, token, consent, device authorization, interaction, and logout queue IA/copy polish without protocol or support-surface creep (FLOW-01..FLOW-05, Phase 119); and source-derived browser proof, deterministic guardrails, bounded operator docs, and final adversarial signoff (PROOF-02..PROOF-04, Phase 120).
- Delivered v1.32 Admin Page IA & Interaction Model Polish: deterministic route scorecards and judgment rubric (Phase 121); Support token and consent investigation polish (Phase 122); Operate interaction, device authorization, and logout delivery queue polish (Phase 123); Configure client, DCR/IAT, key, and policy page propagation (Phase 124); and shared fixture stress proof, route-family rendered-HTML guardrails, browser/manual maintainer evidence, bounded operator docs, and adversarial closeout proof (Phase 125).

### Out of Scope

- HTTP Message Signatures (RFC 9421) for the Token Endpoint — Not required by FAPI 2.0 Message Signing and adds immense complexity. Rely on DPoP.
- SAML IdP and LDAP/AD federation — expands the protocol and enterprise-systems surface far beyond the core OAuth/OIDC provider wedge.
- Hosted auth product or required separate process — the product value is embedded Phoenix deployment, not another service to run.
- End-user authentication primitives such as passwords, MFA, passkeys, and session ownership — those belong to Sigra or the host app.
- Full CIAM suite or "Keycloak for Elixir" breadth — Lockspire wins by staying narrow, trustworthy, and operator-capable.
- Mandatory theming engine — host apps should own layouts, copy, and branding through editable generated code.

## Context

v1.47 completed2026-10-25: finite twelve-case qualification, two targeted protocol corrections, standard-library receipt validation and bounded diagnostics, with no added dependency. Pre-close tracked library/template Elixir contains56,641 lines across337 files (comments/blanks included). Accepted main and package/candidate/publication identities remain distinct; see the archived receipt and closeout projection.

v1.46 completed on 2026-10-24 with native host routes, current host-policy boundaries, safe generated upgrades and packaged proof. Library/template Elixir contains 56,656 lines (tracked `.ex`/`.exs` under lib/ and priv/, including comments and blanks). No library dependency was added. Hosted CI remains unobserved; local exact dependency-pair and browser proof retains its source identity.

v1.45 completed on 2026-10-22. The checked-in Elixir library contains 53,777 lines in 285 `lib/` files at the proven source candidate; test Elixir contains 92,299 lines in 384 files. Counts include comments and blanks. No dependency was added for lifetime enforcement. Current supported host composition and upgrade limits are documented in `docs/upgrading/client-lifetimes.md`. The audit retains bookkeeping, historical TDD and undefined-probe limits; public package publication remains separate.

Lockspire is a greenfield OSS library project with a substantial prep corpus in `prompts/` defining product thesis, domain language, market positioning, implementation shape, operator workflows, telemetry, release readiness, and security posture. The core target is Phoenix SaaS teams that need provider-side OAuth/OIDC for partner ecosystems, integration marketplaces, or Auth0 exit paths. The project should follow Doorkeeper-style install DX, node-oidc-provider-style protocol seriousness and extensibility, OpenIddict-style separation between core, storage, and host seams, and Rodauth-style security defaults.

The short-to-medium-term project arc is now explicit: finish the most leverage-heavy real-integrator trust wedges first, keep the public support posture narrow and truthful, and only then spend milestone budget on broader certification depth or lower-leverage auth-method expansion. `.planning/EPIC.md` is the durable record of that arc. With v1.16 complete, `v1.17` shifted from release-truth alignment in git to the real public release cut and post-publish verification, and `v1.18` proved it in production.

## Constraints

- **Tech stack**: Embedded Phoenix/Elixir library with Phoenix LiveView admin and consent UX — the product must feel native inside a host Phoenix app.
- **Storage**: Ecto/Postgres is the default durable path — protocol truth, auditability, and operational clarity should live in durable storage rather than process state.
- **Security**: Secure-by-default OAuth/OIDC posture is mandatory — PKCE S256, exact redirect matching, hashed client secrets, single-use short-lived codes, refresh rotation, no implicit flow, no `alg=none`.
- **Architecture**: Strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and operator UI — this keeps the public API small and the library maintainable.
- **Host seam**: Host apps own accounts, login UX, layouts, branding, and policy — Lockspire must not take over the host's authentication model.
- **Release quality**: Executable docs, warnings-as-errors, CI/CD, changelog hygiene, and publish-from-release discipline are part of the product — release trust is a core feature for an auth library.
- **Verification posture**: Default phase closure to executable proof in tests and CI. Start from observable acceptance paths, shift checks left into the earliest reliable layer, and add recurring integration, end-to-end, smoke, or seam coverage to required CI when its repeat value justifies the cost. Prefer deterministic, hermetic checks; avoid duplicative or flaky automation without recurring value. Passing automated evidence satisfies UAT without a human confirmation round. Hand off only a genuinely subjective judgment or a boundary automation cannot reach, and name the exact reason and machine-owned follow-up gate. Never ask the user to confirm a fact that repository checks, CI, or an available supported lifecycle can establish.
- **UI refinement posture**: Extrapolate user feedback across equivalent workflows and shared components. Default to a bounded autonomous source/rendered review, one coherent fix batch, and desktop/mobile confirmation with durable findings and evidence. Check useful copy, hierarchy, spacing, control choice, validation, focus and terminal states before returning for optional feedback. Add cheap deterministic regressions to existing CI when they catch recurring failures. Do not make the user rediscover routine defects, silently change backend/security behavior, or create an endless cosmetic review loop. Adopted in Phase 153 on 2026-10-13; see `153-AUTOMATED-UX-SWEEP.md`.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Qualify exact supported cases before changing protocol behavior | Coarse suite failures and unavailable infrastructure do not establish product defects | Phase 171 passed; ten existing proofs reused, two source-host counterexamples assigned to 172/173 |
| Preserve original evidence and distinguish deliberate normative RED from setup failure or protocol pass | Repeated probes and metadata edits must not rewrite observed history | Phase 171 controlled observations, dated archive, focused contract and clean review |
| Classify unsupported response mode at the existing protocol boundary | Reuse safe first-party HTML delivery and preserve strict/PAR/host seams without another abstraction or dependency | Phase 172 actual Router RED/GREEN and passed 11/11 verification |
| Preserve stored PAR authority rather than rejecting all outer parameters | Remove the blanket conflict gate while retaining stored-only reconstruction, current policy and client-bound one-use consumption | Phase 173 actual Router RED/GREEN and six verified behavioral truths |
| Record judgment lifecycles explicitly in autonomous work | Resolved/judgment keeps non-authoritative flags visible without inventing mechanical proof or a human confirmation; real behavior gaps still block | Phase 173 canonical-contract review and independent autonomous verification |
| Require actual candidate/browser evidence distinct from server lifecycle and compilation | Supported integration claims need real assets, signed sessions, joins, navigation and current-authority denial at each mount | ✓ Good — Phase 170 six-cell matrix and independent goal verification |
| Validate page mount alignment at HTTP entry and retain current host authority at LiveView boundaries | Connected sockets expose the WebSocket URI rather than the original page path; account/policy ownership stays with the host | ✓ Good — Phase 170 real browser regression and host authorization tests |
| Retain only independently validated evidence and bound cleanup to owned resources | Hostile diagnostics, failed cleanup and artifact traversal must fail visibly without leaking or deleting external data | ✓ Good — Phase 170 security remediation, containment regressions and independent clean re-review |
| Generate a host-owned deny-first Plug and LiveView hook, with one canonical native route declaration | Preserve host identity/policy/layout ownership while preventing unfinished scaffolding from granting access | ✓ Good — rendered install, demo and maintained-host behavior verified in Phase 169 |
| Authorize managed upgrade changes by checksums and create absent host policy only once | Keep editable host policy/configuration outside managed overwrite authority and refuse drift | ✓ Good — historical conversion, byte-preserving preview/repeat and preservation tests, Phase 169 |
| Journal intent before publication and retain terminal state through cleanup | Process interruption must not lose mutation ownership, repeat rollback incorrectly or orphan undiscoverable staging | ✓ Good — five review findings fixed; 24 transaction tests and independent re-review, Phase 169; no power-loss or hostile-writer claim |
| Treat compiled route diagnostics as structural evidence only | Hook/pipeline declarations cannot certify arbitrary host policy or untested client transport | ✓ Good — exact dispatch, redaction and output-limit tests, Phase 169; broader proof assigned to Phase 170 |
| Snapshot positive durations at issuance; nil/zero remain unlimited and equality is expired | Avoid retroactive policy changes and inconsistent boundary interpretations | ✓ Good — selected D-01–27 contract, implemented and verified across v1.45 |
| Keep app, shared-secret and management-token expiry independent | Credential replacement must not renew app lifetime or unrelated credentials; issued-token/offline limits stay explicit | ✓ Good — independent-boundary and public-facade tests, Phase 166 |
| Fail closed on missing/unknown lifetime versions and malformed authoritative dates | Only explicit v0 is legacy; no guessed rejection deadline from old timestamps | ✓ Good — storage, authentication, migration and package proof |
| Guard current rows and verified method-specific identity under shared transaction authority | Avoid stale credential restoration and partial grant/token/audit commits; callback presence alone cannot prove atomicity | ✓ Good — real PostgreSQL waits and rollback conformance |
| Sample final UTC-second clocks after blocking locks and derive one response/JWT/storage expiry | Prevent expiry crossing a wait from authorizing stale work; malformed clocks become controlled server errors | ✓ Good — current final-clock regression and exact-source CI |
| Keep host claims/callbacks and preparation outside row locks; retain existing public approval and token APIs | Bound lock duration and preserve the narrow embedded host seam | ✓ Good — code/refresh/device/CIBA/RFC 8693 implementation and review |
| Apply current policy only on explicit credential replacement; promote v0 from the current whole row | Preserve unrelated metadata and deadlines; historical secret dates remain advisory until replacement | ✓ Good — secret and management lifecycle proof under both prefixes |
| Preserve method- and endpoint-specific errors and online/offline boundaries | Secret expiry gates secret authentication, not non-secret methods or previously issued tokens; offline JWT verification cannot observe later state | ✓ Good — current consumer inventory and focused tests |
| Require maintenance cutover before v1 writes; do not promise old-binary rollback after activation | Explicit writer drain and migration order prevent mixed-version state corruption | ✓ Good — pinned-old packaged migration proof |
| Expose only client_store and transaction_store selectors with Repository defaults | Support the named delegating PostgreSQL composition without inventing a general datastore registry | ✓ Good — real configured production HTTP and executed Markdown adapter example |
| Replace management tokens immediately with one disclosed credential; recovery stays host-authorized | Lost responses need an explicit recovery path; no overlap, new public recovery route or app renewal | ✓ Good — HTTP, operator and PostgreSQL races |
| Bind packaged proof to archive/tree/source identity and upload only validated allowlisted receipts | Reject skipped/missing scenarios and redact credentials, argv and host paths | ✓ Good — nine required scenarios, 49/49 checks, artifact-bound CI |
| Preserve evidence reuse boundaries and unresolved predicates explicitly | Historical receipts, repeated test selections and code-only UI review must not imply new runtime/visual proof | ✓ Good — final audit and all five current owner projections; undefined probes remain unresolved |
| Sample management time after locked-row preparation; prioritize credential401, app403, then metadata400 | Bind expiry/error decisions to current authority without leaking metadata on rejected credentials | Verified in Phase165 HTTP and PostgreSQL matrices |
| Use current policy for immediate management replacement; keep recovery host-owned and app expiry unchanged | Make lost-response recovery explicit without overlap or unintended renewal | Verified in Phase165 transaction, rollback and mounted recovery tests |
| Share KEK snippet generation between installer and print-only task; resolve env references at runtime and fail closed | Keep adopter setup consistent without writing secrets or hiding missing configuration | ✓ Good — Phase159 and public1.6.0, covered by generator/config/guidance contracts |
| Keep key protection read-only and unknown states explicit | Operators need truthful status while the host owns encryption-key lifecycle | ✓ Good — Phase160 state matrix, rendered checks and vocabulary contracts |
| Approve pending bot-created PR workflow runs through the normal API when authorized | Manual dispatch success alone does not satisfy PR check gates | ✓ Good — corrected D-21 premise; actual PR runs passed before normal merge |
| Keep planning milestone tags separate from package release tags | v1.44 describes work organization; lockspire-v1.6.0 identifies immutable published source | ✓ Good — closeout does not republish or move the package tag |
| Apply explicit conditional maintainer authorization to already-scoped release steps when required checks are green | Avoid repeated approval prompts while retaining actual branch/environment protections, exact-source guards and one-use authorization cleanup | Adopted2026-10-20; normal API approvals used for verified release workflow and record PR; failed checks still stop progress |
| Start v1.41 with a plain-language admin UI copy pass before README and guide rewrites | The user reports that existing UI wording feels like boilerplate and jargon; reviewed terms should anchor the documentation pass while preserving protocol meaning and action consequences | Adopted 2026-10-10; delivered in Phase 148 with 33/33 must-haves verified, 215 focused tests, and responsive inspection; Impeccable `clarify` guidance informed the bounded copy review |
| Keep reader guides task-focused, preserve `docs/supported-surface.md` as the single capability contract, and prove recurring documentation properties with deterministic checks | Adopters need clear next steps and accurate boundaries without duplicate capability promises or manual verification of properties the build and tests can prove | Adopted and delivered in Phase 150; five ExDoc groups, an 8-test contract, warning-free docs build, package build, and Phase 148/149 regressions passed |
| Keep repository planning paths out of public adopter/admin guides | Repository-only evidence can disappear from published HexDocs and distract adopters from their tasks | Adopted in Phase 150; an executable contract checks the README and five adopter/admin guides |
| Keep synthetic adopter fixtures visibly distinct from real customers | Demo data must help adopters explore real journeys without implying a production integration or account | Applied to the v1.40 Billingo preview and its retained screenshots/records |
| Render failed admin reads as unavailable and preserve healthy emptiness as a separate state | Operators must not mistake an unknown observation for zero records or confirmed missing prerequisites | Implemented and regression-tested across overview, policy, and client readiness surfaces; v1.40 audit records current freshness limits |
| Keep revocation scopes and read-only operational queues explicit | Safe operator actions need accurate, separate consequences; queues must not imply unsupported controls | Preserved throughout the v1.40 Support and Operate journeys |
| Use stable synthetic preview data and separate disposable mutation targets | Repeatable visual comparison should not risk changing the preview data used for optional feedback | Applied and recorded in the v1.40 preview receipts |
| Treat automated evidence as the default and preserve only genuinely unautomated visual judgment as `human_needed` | Avoid repeated manual UAT for behavior already established by deterministic tests, while stating exact remaining coverage | Applied during v1.40 closeout; stale/human-needed reports remain unchanged and acknowledged for forward progress |
| Bind protected publication to an active main-only update freeze and repeat exact-SHA checks immediately before package upload | Closes the interval where `main` could move after recovery validation but before upload; fail closed if the freeze or read-back cannot be established | Adopted and verified across Phases 142–143; Lockspire 1.5.1 was published from exact source `0b56503859b69531ff86d8e4a465a0e75f963594` |
| Keep PR merge authorization separate from protected publication approval | A deployment approval for one exact source SHA does not establish that a source PR's exact head was approved for merge | Adopted in Phase 143; the missing PR #119 merge record remains an acknowledged verification gap and is not inferred from the publication approval |
| Bind baseline acceptance to the exact accepted source SHA and identify later documentation commits separately | Preserve the evidence boundary when planning and release records are reconciled after source acceptance | Adopted in Phase 141; documented in the [maintenance baseline](milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md) |
| Reconcile public-package publication separately from milestone completion | Keep latest-release claims tied to Hex and GitHub evidence and condition future patch cuts on the standing GA gates | Adopted in Phase 141 and verified in Phase 143; public Lockspire 1.5.1 is confirmed while the separate PR #119 provenance gap remains explicit |
| Use the Lockspire milestone roadmap ratchet prompt as a durable decision aid, not a commitment list | Preserve the project's quality, release, and roadmap-selection posture with explicit Lockspire boundaries and provenance | Adapted 2026-09-27; see `docs/lockspire-milestone-roadmap-ratchet-prompt.txt`; roadmap horizons remain hypotheses |
| Shift verification left and make automation the default phase-closure path | Map UAT claims to existing executable checks before creating human checkpoints; add missing repeatable tests and required CI only when they catch recurring regressions. Reserve human attention for genuinely subjective judgment or external boundaries automation cannot reach. | Adopted 2026-09-24; reaffirmed in Phase 145 (10 semantic checks closed from automated evidence; visual acceptance assigned to Phase 147); apply by default in future GSD discussion, planning, execution, and verification |
| Keep the v1.38 baseline immutable and proposal-only, with lifecycle movement authorized by exact receipts and semantic classifiers | Reconciliation needs a stable evidence boundary without mistaking publication for cleanup authority or treating ordinary GSD bookkeeping as evidence drift | Adopted and verified in Phase 138; Phase 139 consumes ledger `b8b9ad75` |
| Start v1.37 as a prime-time readiness ratchet with additive-only public API changes | Research found concrete generated-install, migration, consent, resource-server, architecture, CI, and conformance gaps; one clean-room SaaS journey provides a higher-value acceptance spine than more protocol breadth or another isolated cleanup pass | Adopted 2026-08-26; planned across Phases 131-137 |
| Start v1.36 as a structural quality ratchet | Audit evidence found high-leverage release-integrity, storage-boundary, static-analysis, compatibility, and readability gaps that can be fixed without adding product surface | Adopted and delivered across Phases 126-130; archived 2026-08-26 |
| Ship Lockspire as a separate companion library, not a Sigra module | Keeps provider-side OAuth/OIDC concerns isolated from end-user authentication concerns | Adopted in archived v1.0 milestone |
| Build as an embedded library rather than a standalone auth service | Matches Phoenix team deployment reality and preserves host control over UI, accounts, and app policy | Adopted in archived v1.0 milestone |
| Use Phoenix LiveView for admin and consent UX | Gives operators and host apps first-class Phoenix-native surfaces instead of a foreign console | Adopted in archived v1.0 milestone |
| Default to Ecto/Postgres durable storage with explicit seams for later adapters | Prioritizes correctness, auditability, and operational simplicity for v1 | Adopted in archived v1.0 milestone |
| Optimize for a narrow v1 focused on auth code + PKCE, OIDC discovery/JWKS/userinfo, client management, consent, rotation, telemetry, and release readiness | Keeps the initial scope credible and avoids drifting into a heavyweight CIAM suite | Adopted in archived v1.0 milestone |
| Treat PAR, dynamic client registration, device flow, stronger sender-constrained modes, and stronger certification profiles as later roadmap candidates | Preserves room for future protocol expansion without bloating the first milestone | Deferred to later milestone planning |
| **Sigra ecosystem sequencing** | Finish **Phase 3 → 5 → 6** before public “Sigra + Lockspire” golden paths; document via **ECOSYSTEM-SIGRA.md** and **`docs/sigra-companion-host.md`** | Adopted in archived v1.0 milestone |
| Polish the current preview surface before adding more protocol breadth | The repo already has its core provider wedge; release trust is now the gating risk to adoption and velocity | Adopted in archived v1.1 milestone |
| Make PAR the first post-polish protocol wedge | PAR extends the existing auth-code flow with less product-shape drift than dynamic registration or device flow | Adopted and delivered by Phase 15 |
| Make Dynamic Client Registration the v1.5 wedge | DCR turns Lockspire from operator-tended into partner-buildable while reusing the narrow protocol-plus-operator-policy pattern | Adopted and delivered across Phases 25-29 |
| Make Device Authorization Grant the v1.6 wedge | Device flow extends the embedded provider into CLI and partner-device use cases while preserving the host-owned verification seam and shared token pipeline | Adopted and delivered by Phase 32 |
| Make DPoP the v1.7 wedge | DPoP raises the real-integrator security story across existing public/CLI paths without requiring hosted infrastructure or enterprise PKI and composes directly with the shipped device and DCR surfaces | Adopted at v1.7 milestone start |
| Persist the multi-milestone strategy in `.planning/EPIC.md` | Milestone selection should compound from repo truth and prior decisions rather than being rediscovered every cycle | Adopted at v1.7 milestone start |
| Transition to 1.0 GA | After shipping FAPI 2.0 Security Profile, the library has the necessary features and security depth to confidently drop preview status | Adopted at v1.11 milestone start |
| Add Token Exchange (RFC 8693) | Provides standard delegation and impersonation primitives for microservice patterns without custom grant types | Adopted at v1.12 milestone start |
| Add OpenID Connect CIBA | Provides decoupled authentication and real-time out-of-band notifications, leveraging Elixir's concurrency and Oban for resilient delivery | Adopted at v1.13 milestone start |
| Use Oban for resilient delivery | Ensures that CIBA webhooks (Ping/Push) and back-channel logouts are retriable and durable across system restarts | Adopted for v1.13 CIBA implementation |
| **Select RAR & Resource Indicators for v1.14** | Empowers Phoenix teams in complex domains (fintech, healthcare) and enables "Zero Trust" targeted tokens | Adopted at v1.14 milestone start |
| Target FAPI 2.0 Message Signing for v1.19 | Provides application-layer non-repudiation without mTLS infrastructure overhead, building off existing JWS/JWE primitives | Adopted at v1.19 milestone start |
| Start `v1.23 DCR Logout Metadata` as a narrow self-service wedge | The logout propagation runtime already exists; the highest-leverage remaining gap is letting partner-managed clients register and manage the existing metadata without widening beyond current logout truth | Adopted and archived in milestone v1.23 |
| Activate `v1.24 client_secret_jwt` as the current milestone | The remaining leverage-heavy gap is a practical direct-client authentication option that fits the current embedded-library boundary when kept narrow and truthfully documented | Adopted at v1.24 milestone start |
| Ship `v1.25 Support-Burden Reduction` and default to stop-or-reassess afterward | The highest-leverage remaining work was support truth on already-shipped advanced setup surfaces; beyond that, roadmap inertia is a bigger risk than missing protocol breadth | Adopted at v1.25 milestone close |
| Treat the next work as release-truth polish rather than a new feature milestone | The remaining repo risk is stale public release posture and gate drift, not a missing core OAuth/OIDC wedge | Adopted after the v1.25 completion assessment |
| Add a repo-owned hygiene gate after the `1.1.0` release | A mature OSS library needs one disciplined pre-release command and one CI drift fence more than more branch folklore | Adopted during post-`1.1.0` release follow-through |
| Default Lockspire to a standing GA release train | A mature auth library should feel released by default: `milestone: none`, patch-on-merge for sustaining work, and a durable release ledger instead of milestone inertia | Adopted after the `1.1.0` public release verification |
| Use one milestone PR for future feature work | Keeps `main` as the release-train source of truth while preserving GSD milestones for larger feature development | Adopted after the `1.1.0` release-train baseline |
| Put green-main and support-truth work before `v1.26` | The next repo-local risks are CI trust and public-truth drift; feature work should start only after those are boring again | Adopted during post-PR #31 roadmap assessment |
| Make host integration/operator boundary hardening the next feature candidate | Account/claims recipes, client bootstrap, admin-route boundaries, and operator diagnostics improve real Phoenix adopter outcomes more than adjacent protocol breadth | Recommended for the next `$gsd-new-milestone` decision |
| Add a host-guarded admin-only router for v1.26 | The generated host needs a concrete way to put operator auth in front of `/lockspire/admin` without putting the public OAuth/OIDC endpoints behind staff auth | Adopted for v1.26 implementation |
| Deliberately leave sustainment and open `v1.27 Phoenix Resource Server Token Acceptance` | The adoption demo shipped in PR #44 exposed an unfinished design tension between Lockspire-issued stored access tokens and the JWT-bearer-oriented `Lockspire.Plug.VerifyToken`. Resolving it is a higher-leverage adopter wedge than additional protocol breadth, and qualifies as the adopter-evidenced exception to the sustaining-train default | Adopted at v1.27 milestone start (2026-05-27) |
| Resolve v1.27 with Branch A + JWT-default issuance | Narrow `Lockspire.Plug.VerifyToken` to RFC 9068 `at+jwt` only and flip the default access-token format from opaque to `:jwt` for AC/refresh/device/CIBA paths. Opaque remains available as an explicit per-client opt-in and continues to back `/userinfo` and `/introspect`. Canon-aligned (the prompts/ corpus explicitly endorses `access_token_format: :jwt` as the secure default), ecosystem-aligned (every modern RS library written post-RFC-9068 defaults to JWT at the plug), and structurally avoids the auto-detection footgun class documented in Ory oathkeeper #257 / Spring Boot's startup-exception guardrail. Branch B (dual-verifier plug with shape-dispatch) and introspection-at-the-RS as the host-API seam both explicitly rejected | Adopted at v1.27 milestone start (2026-05-27); recorded in `.planning/REQUIREMENTS.md` design-decision section |
| Start v1.28 as an admin UI polish milestone | The admin surface now spans setup proof, partner onboarding, support investigation, security posture review, operations triage, DCR, and key lifecycle. The highest-leverage adoption wedge is coherent operator UX and reusable design-system primitives, not more OAuth/OIDC protocol breadth. | Adopted at v1.28 milestone start (2026-06-03); archived in `.planning/milestones/v1.28-REQUIREMENTS.md` |
| Start v1.29 as an admin journey and design-system deep polish milestone | v1.28 established the coherent admin UI baseline. The next value is a systematic route-by-route operator journey pass, with strongest attention on support/operations/mobile/design-system weak spots rather than more protocol breadth or a UI rewrite. | Adopted at v1.29 milestone start (2026-06-03); archived 2026-06-04 |
| Start and complete v1.30 as adoption-demo Docker DX and repo hygiene | v1.29 produced route-complete admin UI proof, but the next UI iteration needed a boring, repeatable local demo base with fewer Docker conflicts, clearer startup output, wrapper-driven smoke proof, and scoped cleanup/hygiene before more UI polish. | Adopted at v1.30 milestone start (2026-06-04); archived 2026-06-24 |
| Start and complete v1.31 as an admin design-system stress test | v1.29 made the admin UI coherent and v1.30 made the demo easier to inspect; the next leverage point was making shared components, fixtures, page IA, browser proof, and docs compound without protocol/storage/host-seam creep. | Adopted at v1.31 milestone start (2026-06-25); archived 2026-06-26 |
| Start and complete v1.32 as a page-first admin IA and interaction-model polish milestone | v1.31 strengthened foundations and broad weak-page coverage; the remaining quality gap was judgment-level page composition, user-flow hierarchy, copy, and component-group polish under ugly Support/Operate data before wider Configure propagation and final proof ratchets. | Adopted 2026-06-28; shipped and archived 2026-06-30 |
| Run repo hygiene before future milestones and releases | Clean local git/worktrees, triaged GitHub PRs/issues, green CI, current GSD state, and release-truth notes keep Lockspire ready for the next scoped adventure without starting from a dirty repo state. | Adopted 2026-07-01; documented in `.planning/REPO-HYGIENE-CHECKLIST.md` |
| Start v1.40 as Admin Operator UI Refinement using the existing design system | The user requested a coherent, conventional operator experience, approved the Impeccable audience/code-first defaults, and selected this scope over the earlier docs backlog. Reuse prior UI work and sibling lessons; evaluate complete jobs in the actual browser with bounded review. | Milestone direction confirmed 2026-10-09; detailed roadmap approval tracked in STATE.md |
| Keep the v1.42 browser-proof harness local-only and navigate-only | Real-browser runs are slow and need a live demo; recurring value lives in deterministic contracts (page contract, CSS contrast, route parity) that run in CI, while screenshots stay in ignored `tmp/` | ✓ Good — adopted in Phase 154 (D-05/D-06) |
| Re-verify earlier phases at milestone close when a later phase edits shared files | Stale digests from Phase 154 CSS/component edits would otherwise force an override closeout | ✓ Good — v1.42 closed as verified; v1.43 chose an override instead because the milestone audit's integration check and full suite already covered the later edits |
| Use a dedicated host-supplied, rotatable KEK list for signing-key encryption, never derived from `secret_key_base` | Rotating `secret_key_base` would silently strand every signing key; the host owns secret custody | ✓ Good — shipped in v1.43 (R1–R8 research decisions) |
| Keep the v1.43 upgrade non-breaking: a missing KEK warns loudly and refuses key generation instead of failing boot | Existing 1.x installs must keep signing across the upgrade; doctor, Verify and boot warnings make the gap visible | ✓ Good — user decision 2026-10-15 (KEK-02) |
| Encrypt in place with a self-describing envelope header and no schema migration or decrypted-key cache | Avoids host migration cost and keeps plaintext out of memory caches; the `private_jwk_encrypted` name becomes true | ✓ Good — SAFE-01 gate green |
| Enforce `legacy_plaintext: :reject` and KEK rotation with each node's boot-cached key set, with ordering documented rather than coordinated | Avoids a cross-node coordination mechanism; `--check` and the upgrade guide gate the switch | ⚠️ Revisit — accepted risk AR-156-01 if operators report rolling-restart issues |
| Route bare-mix DB tasks through `TaskError.run/2` wrapping `RepoRunner.run/2`, with fixed classifier phrases instead of exception text | Real failure reasons without leaking SQL, host, values or secrets; reuses the pool when the host already runs it | ✓ Good — Phase 158; review fixes narrowed the migrate hint to undefined table/column and raised the log guard to `:warning` |
| Expand one shared admin route inventory inside the host router with fixed :lockspire_admin session | Preserve native path signing and 29-route parity without copying routes or Phoenix internals | ✓ Good — v1.46 routing and package/browser proof |
| Require host HTTP policy and current-identity hooks; re-resolve policy on navigation | Keep accounts, login, roles, logout and event policy host-owned | ✓ Good — denied and allowed lifecycle/browser boundaries; no continuous revocation claim |
| Generate deny-first host-owned policy; checksum-authorize managed conversion and create host files only when absent | Preserve adopter ownership while making upgrades retryable and previews read-only | ✓ Good — v1.46 install/upgrade and interruption proof |
| Validate exact compiled first-match routing and state structural proof limits | Detect shadowed/legacy/incomplete wiring without claiming arbitrary policy correctness | ✓ Good — v1.46 verifier contracts |
| Keep lifecycle and Chrome/CDP receipts separate and bind source/package/pair/mount/run identities | Establish transport/runtime behavior and fail visibly on missing or malformed proof | ✓ Good — v1.46 six-cell matrix and containment review |
| Preserve local/hosted evidence limits and historical verification paths at archival | Avoid converting local success or relocation into unsupported CI or new runtime claims | ✓ Good — v1.46 audit and closeout projection |
| Select v1.47 core interoperability with a rolling evidence-led milestone sequence | User approved research/fan-out, adversarial synthesis, small dependency trees and clean green-main/worktree boundaries; settle consequential decisions upstream and stop at diminishing returns | ✓ Good — v1.47 delivered qualified corrections and accepted green main; standing guide/ranking retained |
| Keep SEC-01 separate as provisional v1.48 and later scope conditional | Avoid mixing protocol corrections with persistence/key migration; existing token coverage should not be rebuilt without evidence | ✓ Good — kept outside v1.47; still provisional after closeout reassessment |
| Keep source/proof/verifier/audit references directed and preserve actual executed identities | Avoid circular fingerprints, metadata restamping and unsupported proof promotion | Phase 174: reviewed applicability and exact package/candidate/CI identities |
| Preserve bounded redacted failure diagnostics before owned cleanup and retain original exits | Make opaque floor failures diagnosable without leaking child logs or masking failure | Phase 174: existing helpers, ten focused wrapper tests and final hosted floor proof |

| Return unsupported response_mode through first-party browser error and consume only stored PAR fields | Preserve safe callback/error disposition and pushed integrity using existing seams | ✓ Good — actual Router RED/GREEN, package12/12 and accepted main |
| Archive milestone-only frozen planning validation with its evidence | Avoid permanent test discovery depending on mutable active planning paths or rewriting historical hashes | ✓ Good — independent lifecycle review; byte-preserved contract and pre-close22/22 result |
| Select v1.48 SEC-01 before UI quality, preserving the completed UI interview | Owner accepted the recommended order on 2026-10-25; key custody needs its own migration and rotation proof | Selected; requirements/research/roadmap gates remain |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted
6. Check that acceptance criteria have automated owners; add durable CI coverage when a stable seam has recurring regression value, and state the exact machine gate for any unavoidable external boundary.

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
5. Refresh MILESTONE-ARC.md against current evidence; preserve candidate rationale/triggers, mark shipped or stale scope, and record the next default action.
6. Record exact main/CI and worktree handoff status through the existing train; unresolved delivery blocks the next product execution even when planning or archival is complete.

---
*Last updated: 2026-10-25 after v1.48 milestone selection*
