# Lockspire Roadmap

## Current Milestone: v1.36 Adopter Path Proof

**Goal:** Prove the documented path from `mix phx.new` to a working third-party OAuth flow end to end in one run, and fix every break found along the way.

**Milestone posture:** This is an adoption-hardening milestone, not protocol breadth. It adds no protocol surface, does not widen `docs/supported-surface.md`, does not change host-owned seams (accounts, login UX, layouts, branding, policy), and does no admin/operator UI work. Two tempting outcomes — making the installer inject into the host router/config/application, and rewriting `examples/adoption_demo` as a generated app — are explicitly deferred pending evidence from the walk itself.

**Sequencing rule (read this before planning any phase):** This milestone is deliberately evidence-generating. Phase 126 walks the real adopter path and *records* what breaks; it does not fix. Phases 127-129 are scoped to "fix the defects the walk found in area X" and their defect lists are intentionally unknown at roadmap time — a planner encountering that openness should treat it as the design, not as a missing detail, and should read the Phase 126 defect ledger as its input. Phase 130 comes last because automating a red path only institutionalizes a known failure.

**Evidence anchors:** `scripts/publish/verify_install_truth.sh` proves package resolution only — it never runs the installer, migrates, boots, or completes a flow. `test/integration/install_generator_test.exs` wipes its fixture to a bare `.keep`, so the installer runs into an empty directory. `lib/mix/tasks/lockspire.install.ex` injects nothing into host router, config, or application; section 3 of `docs/install-and-onboard.md` is unexecuted hand-work. `examples/adoption_demo` has zero references to `mix lockspire.install`.

## Phases

- [x] **Phase 126: Adopter Path Walk & Defect Ledger** - One command walks the whole documented path against a stock Phoenix app and records every defect it surfaces (completed 2026-07-29)
- [ ] **Phase 127: Installer Against A Real Host** - Fix the installer defects the walk found, and exercise `mix lockspire.install` against a real generated app instead of an empty fixture
- [ ] **Phase 128: Documented Wiring Truth** - Fix the wiring defects the walk found at their real source and close the gap between the guide and what actually works
- [ ] **Phase 129: Reference Artifact Alignment** - Make the relationship between `examples/adoption_demo` and the installer path explicit and accurate
- [ ] **Phase 130: Adopter Path Guardrail** - Automate the now-green walk and stop `verify_install_truth.sh` from overstating what it proves

## Phase Details

### Phase 126: Adopter Path Walk & Defect Ledger

**Goal**: A maintainer can run one command that walks the entire documented adopter path against a stock Phoenix app and gets an attributable verdict plus a written record of every defect the walk surfaced. This phase deliberately does not fix what it finds — its deliverables are a working harness and evidence.

**Depends on**: Nothing (first phase of v1.36)

**Requirements**: ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04

**Success Criteria** (what must be TRUE):

1. A maintainer runs a single command and the walk generates a stock `mix phx.new` application with the defaults a real adopter would use — Ecto and HTML included, not a stripped-down variant — then runs `mix lockspire.install`, performs the documented wiring, migrates, boots the app, registers a client, and drives an authorization-code + PKCE flow, ending in one pass/fail verdict.
2. When the walk fails, the output names which documented step failed and the underlying error, and a maintainer can inspect or resume from that step without re-running the earlier steps by hand.
3. The walk fails when the flow does not yield a usable access token — the token is exercised against a token-consuming endpoint rather than merely observed to exist — so a run cannot pass on exit codes alone.
4. A committed defect ledger records every break the walk surfaced, each attributed to its real source (installer, generated scaffolding, guide, reference demo, or library) and to the requirement area that will fix it.
5. Any temporary workaround the harness needs in order to reach a later step is recorded in the ledger as a defect rather than left silently in the harness as if it were normal.

**Plans**: 6/6 plans executed

Plans:
**Wave 1**

- [x] 126-01-PLAN.md — Walk harness skeleton and clean-room generation of the stock host app

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 126-02-PLAN.md — Guide §1-§3b: add the dependency, run the installer, wire config and router
- [x] 126-03-PLAN.md — Stdlib flow driver and the two-layer ADOPT-04 token proof

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 126-04-PLAN.md — Guide §3c-§3e: account resolver, application start, protected host route

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 126-05-PLAN.md — Guide §4-§6: migrate, verify, client and key, then boot and drive

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 126-06-PLAN.md — Run the walk, author the committed defect ledger, reconcile workaround markers

**Implementation notes**:

- The walk is expected to come back RED. That is the point of the phase; a red first run with a complete ledger is a passing phase, an empty ledger is not.
- If an early-step break blocks the walk from reaching later steps, use the smallest local workaround needed to keep walking and record it per criterion 5. Later phases remove those workarounds by fixing the source.
- Do not fix defects in this phase beyond what is required to make the harness itself function. Fixes belong to Phases 127-129 so the evidence stays separable from the repair.
- Prefer a maintainer-facing script plus a Mix alias consistent with existing repo lanes (`scripts/`, `mix test.integration`) over new tooling weight. This walk generates a real app and boots it, so it will not be daemon-free or fast; do not force it into the default `mix ci` lane in this phase.

### Phase 127: Installer Against A Real Host

**Goal**: Fix the installer-area defects the Phase 126 walk recorded, and prove `mix lockspire.install` against a freshly generated Phoenix application instead of an empty fixture directory. The specific defect list is unknown until the walk runs — this phase is scoped to "whatever the ledger attributed to the installer", and that openness is intended.

**Depends on**: Phase 126 (the defect ledger is this phase's input)

**Requirements**: INSTALL-01, INSTALL-02, INSTALL-03

**Success Criteria** (what must be TRUE):

1. The installer's integration proof runs `mix lockspire.install` into a freshly generated Phoenix application rather than into a directory the test emptied first.
2. A maintainer can confirm the installer's generated files match the host they were generated into — app name, web module, router module, and repo module all resolve against the real host rather than a placeholder.
3. Re-running the installer against a host that already contains conflicting files or prior Lockspire output behaves observably and predictably, and does not leave the host in an unclear half-installed state.
4. Every installer-attributed defect in the Phase 126 ledger is either fixed in `mix lockspire.install` or its templates, or explicitly deferred with a stated reason recorded in the ledger.

**Implementation notes**:

- Out of scope, deliberately: making the installer inject into the host's router, config, or application. That is a real design possibility, but v1.36 treats it as a decision the walk should *inform*, not a conclusion assumed before walking. If the evidence argues for it, log it as a future candidate.
- Host-owned seams stay host-owned. Reducing adopter friction must not absorb accounts, login UX, layouts, branding, or policy into the library.
- `test/integration/install_generator_test.exs` already asserts generated content thoroughly; extend the host-interaction gap rather than rewriting the content assertions.

**Plans**: 2/9 plans executed

Plans:
**Wave 1**

- [x] 127-01-PLAN.md — Tracer: install into a real committed `phx.new` host via `Mix.Project.in_project/4`; correct the manifest version field

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 127-02-PLAN.md — Widen the `ecto_sql` requirement to a range, commit the resolved lock, prove `mix ci` against it (ADOPT-D15)
- [x] 127-03-PLAN.md — `mix lockspire.client.create` reaches a started repo through `Ecto.Migrator.with_repo/2` (ADOPT-D08)
- [x] 127-04-PLAN.md — Installer instructions name the app-tree wiring and key lifecycle; all three migration remediation strings corrected (ADOPT-D05/D06/D07)
- [x] 127-05-PLAN.md — Router template becomes a deny-closed `defmacro`; route-table compile fence; runtime fixture regenerated (ADOPT-D01/D02/D03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 127-06-PLAN.md — Config, resolver, and HEEx templates fixed; HEEx compile fence over every generated template (ADOPT-D04/D09/D16)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 127-07-PLAN.md — Plan-then-apply atomic refusal: all conflicts reported, zero bytes written (INSTALL-03)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 127-08-PLAN.md — `--dry-run`, manifest input drift, and refuse-on-drift manifest writes (INSTALL-03)

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 127-09-PLAN.md — Retire six harness workarounds, record all twelve ledger dispositions, run the walk (criterion 4)

### Phase 128: Documented Wiring Truth

**Goal**: Close the gap between `docs/install-and-onboard.md` and reality using the wiring defects the Phase 126 walk recorded, so the manual "wire the generated files" step is verified to produce a working provider rather than trusted. As with Phase 127, the defect list is discovered rather than pre-specified.

**Depends on**: Phase 126 (defect ledger); Phase 127 (installer output must be correct before the wiring steps on top of it can be re-proven)

**Requirements**: WIRE-01, WIRE-02, WIRE-03

**Success Criteria** (what must be TRUE):

1. Every manual step in `docs/install-and-onboard.md` is executed by the path walk, and a drift check fails when the guide gains or changes a step the walk does not perform.
2. An adopter following only the guide reaches a booting provider — any knowledge the walk needed that the guide did not state has been added to the guide.
3. Every wiring-attributed defect in the Phase 126 ledger is fixed in the library, the generator templates, or the guide, rather than worked around inside the walk harness.
4. The walk harness performs only steps the guide tells an adopter to perform; the temporary workarounds recorded under Phase 126 criterion 5 are gone from the harness.

**Implementation notes**:

- Phase 126 makes the walk execute the wiring steps well enough to reach a token. This phase hardens that into provable coverage of *every* documented step plus a drift fence, which is why WIRE-01 lands here and not in Phase 126.
- Sections 1-8 of the guide are not all on the minimum path to a token (upgrade and the device-login verification seam, for example). Decide explicitly which steps the walk executes and which the drift check exempts with a stated reason; silent omission is the failure mode this phase exists to close.
- Findings that would widen `docs/supported-surface.md` are logged as future candidates, not built. Narrowing drift is in scope; widening claims is not.

### Phase 129: Reference Artifact Alignment

**Goal**: Make the relationship between `examples/adoption_demo` and the installer path explicit and accurate, so the reference artifact adopters are pointed at cannot quietly teach a different integration than the one Lockspire ships.

**Depends on**: Phase 127 (the installer's real generated wiring is the thing the demo is diffed against)

**Requirements**: REF-01, REF-02

**Success Criteria** (what must be TRUE):

1. A reader of `examples/adoption_demo` can tell from the demo itself whether it demonstrates the documented `mix lockspire.install` path or a hand-wired alternative, and why.
2. Each divergence between the demo's wiring and the installer's generated wiring is either removed or documented with its reason.
3. Deliberate divergences — the demo's in-repo path dependency being the clearest — are stated as deliberate rather than left for a reader to infer.

**Implementation notes**:

- Out of scope, deliberately: rewriting the adoption demo as a generated app. That may turn out to be the right answer, but forcing it up front presumes the conclusion, and the demo's in-repo path dependency may make full installer parity wrong. If the evidence argues for it, log it as a future candidate.
- No admin/operator UI work. v1.28-v1.32 covered that surface; adopter-path defects in admin UI get logged unless they block the walk.
- The demo's shipped Docker DX, `LOCKSPIRE_DEMO_BASE_URL` contract, and smoke lane are working assets from v1.30 — align the demo's *story* about the install path without destabilizing its startup path.

### Phase 130: Adopter Path Guardrail

**Goal**: Leave behind automation that fails when the adopter path breaks, and stop `verify_install_truth.sh` from overstating its coverage — so this surface cannot silently rot again. This phase runs last on purpose: automating a red path institutionalizes a known failure.

**Depends on**: Phases 126, 127, 128, 129 (the walk must actually be green before it is automated)

**Requirements**: GUARD-01, GUARD-02, GUARD-03

**Success Criteria** (what must be TRUE):

1. The adopter path walk runs automatically — on a schedule, on release, or both — so a break is detected without a maintainer remembering to check.
2. `scripts/publish/verify_install_truth.sh` either proves the adopter path or states plainly what it does not prove, so "Install Truth proven" cannot overstate its coverage again.
3. A failing walk is visible as a distinct, attributable failure rather than a generic red build — a maintainer can tell from the failure alone that the adopter path broke and at which documented step.
4. The walk is green at the moment automation is switched on, and that green run is recorded as the baseline.

**Implementation notes**:

- Respect the repo's existing CI economics from v1.35: this walk generates and boots a real Phoenix app, so a scheduled or release-triggered lane is the expected shape rather than adding it to every PR run.
- `.planning/RELEASE-TRAIN.md` records install-truth proof per release. If GUARD-02 changes what that proof means, update the ledger's wording so release truth and the script agree.
- The guardrail reports on Lockspire's own adopter path. It does not become a new public support claim or a supported-surface entry.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 126. Adopter Path Walk & Defect Ledger | 6/6 | Complete    | 2026-07-29 |
| 127. Installer Against A Real Host | 6/9 | In Progress|  |
| 128. Documented Wiring Truth | 0/TBD | Not started | - |
| 129. Reference Artifact Alignment | 0/TBD | Not started | - |
| 130. Adopter Path Guardrail | 0/TBD | Not started | - |

## Requirement Coverage

All 15 v1.36 requirements map to exactly one phase. No orphans, no duplicates.

| Phase | Requirements | Count |
|-------|--------------|-------|
| 126 | ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04 | 4 |
| 127 | INSTALL-01, INSTALL-02, INSTALL-03 | 3 |
| 128 | WIRE-01, WIRE-02, WIRE-03 | 3 |
| 129 | REF-01, REF-02 | 2 |
| 130 | GUARD-01, GUARD-02, GUARD-03 | 3 |
| **Total** | | **15/15** |

## Recently Landed Mainline Milestone Records

The 2026-06-30 implementation pass and 2026-07-01 release-hygiene merge landed these records on `main` through PR #58. They are mainline readiness work, not separate Hex releases yet:

- [v1.33 OSS Adoption Trust](milestones/v1.33-ROADMAP.md) - public/admin router separation, verifier truth, package hygiene, and adoption-demo support-boundary repairs.
- [v1.34 Prefix-Isolated Storage](milestones/v1.34-ROADMAP.md) - default generated `lockspire` PostgreSQL schema, prefix-aware migrations/runtime queries, Oban prefixing, example app, and upgrade docs.
- [v1.35 CI/CD Efficiency And Release Hygiene](milestones/v1.35-ROADMAP.md) - duplicate CI work removal, minimum supported Elixir/OTP compatibility job, release cache precision, Dialyzer opt-in, and package hygiene proof.

## Shipped Milestones

- [v1.32 Admin Page IA & Interaction Model Polish](milestones/v1.32-ROADMAP.md) - shipped 2026-06-30; phases 121-125; route scorecards, Support and Operate flow polish, Configure propagation, redaction-safe fixtures, browser/manual evidence, deterministic guardrails, bounded operator docs, and adversarial proof now make the admin/operator UI more deliberately composed without protocol, storage, host-seam, public lab, theming, browser-tooling, or support-surface creep.
- [v1.31 Admin Design-System Stress Test](milestones/v1.31-ROADMAP.md) - shipped 2026-06-26; phases 116-120; route/component/lab inventory, redaction-safe fixtures, shared admin primitives, weak-page IA/copy polish, source-derived browser proof, deterministic guardrails, bounded operator docs, and final adversarial signoff now strengthen the admin/operator design system without protocol, storage, host-seam, public lab, theming, or browser-tooling creep.
- [v1.30 Adoption Demo Docker DX & Repo Hygiene](milestones/v1.30-ROADMAP.md) - shipped 2026-06-24; phases 111-115; the repo-local adoption demo now has one public URL contract, a direct Docker app+PostgreSQL path, conflict-resistant project/port controls, optional Traefik routing, redacted startup/reprint output, wrapper-driven smoke proof, scoped stop/reset/cleanup helpers, Docker-free CI hygiene, and no broadened protocol or hosted-auth surface.
- [v1.29 Admin UI Journey & Design-System Deep Polish](milestones/v1.29-ROADMAP.md) - shipped 2026-06-04; phases 107-110; route-by-route admin journeys, shared BEM/design-token primitives, weak-spot support/operations/configuration polish, demo seed truth, docs, screenshots, contract tests, and 390px mobile no-page-overflow proof now align across the admin operator surface.
- [v1.28 Admin UI Operator Experience Polish](milestones/v1.28-ROADMAP.md) - shipped 2026-06-03; phases 103-106; admin UI operator journeys, shared BEM/design-token primitives, client/support/operations/security/DCR/key workflow polish, demo seed truth, operator docs, screenshots, and design-system contract tests now align as one coherent operator product.
- [v1.27 Phoenix Resource Server Token Acceptance](milestones/v1.27-ROADMAP.md) - shipped 2026-06-03; phases 97-102; `Lockspire.Plug.VerifyToken` narrowed to RFC 9068 `at+jwt`, default access-token issuance flipped to `:jwt`, sender-constraint proof delivered, adoption-demo re-wired, and generated-host scaffolding updated.
- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) - shipped 2026-05-27; phases 94-96; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) - shipped 2026-05-26; phases 91-93; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) - shipped 2026-05-25; phases 88-90; Lockspire supports a narrow `client_secret_jwt` direct-client slice on shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) - shipped 2026-05-24; phases 85-87; self-service clients can create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) - shipped 2026-05-24; phases 82-84; automatic `DPoP-Nonce` challenge and retry support covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Archives

Full shipped milestone details live in `.planning/milestones/`.
