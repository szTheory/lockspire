# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.27 — Phoenix Resource Server Token Acceptance

**Shipped:** 2026-06-03
**Phases:** 6 | **Plans:** 24 | **Sessions:** ~6

### What Was Built
- `Lockspire.Plug.VerifyToken` narrowed to RFC 9068 `at+jwt` only, with strict `typ`, `iss`, and required claims validation.
- One shared `AccessTokenSigner` now owns RFC 9068 `at+jwt` issuance across all grant paths.
- Default access-token issuance format flipped from opaque to `:jwt` for AC, refresh, device, and CIBA paths, with a runtime-settable server default and nullable per-client override.
- End-to-end sender-constraint proof (DPoP and mTLS) delivered across the canonical pipeline, closing misordered-pipeline bypasses.
- The adoption demo is re-wired to use the blessed `at+jwt` path against the protected route.
- Generated-host scaffolding, operator telemetry, and migration diagnostics all shipped to reflect the new default issuance.

### What Worked
- **Contract-First Development:** Writing the canonical doc block (Phase 97) before writing code anchored the entire implementation on a known target, making subsequent phases predictable.
- **Wave-based execution in Phase 102:** Handling telemetry/scaffolding guards before writing the migration doc correctly unblocked dependent work safely.

### What Was Inefficient
- 9 stale test fixtures were invalidated by the plug hardening, leading to red tests at the end of the milestone that needed manual cleanup via `AccessTokenSigner.issue/3` and key seeding.
- `release_readiness_contract_test` assertions had to be run and fixed multiple times due to slight whitespace or block structure mismatches across the four carrier sites.

### Patterns Established
- **Single Signer Ownership:** `AccessTokenSigner` now handles token format resolution, `aud` derivation, and `cnf` carry-through in one place instead of scattered across grant paths.
- **Strict Verification:** `VerifyToken` acts as a hard gate for RFC 9068 adherence, explicitly rejecting opaque tokens with a helpful challenge rather than failing silently.

### Key Lessons
1. **Docs as a Contract:** Hash-pinning the pipeline declaration block across docs, demo, install template, and smoke tests guarantees the shipped code acts as advertised.
2. **Explicit is Better than Implicit:** Instead of auto-detecting token shapes inside the plug (which leads to security footguns), Lockspire forces the `at+jwt` shape for the host API and opaque for its own endpoints.

### Cost Observations
- Model mix: 100% gemini-2.5-pro
- Notable: TDD and executable testing caught contract drift early.

---

## Milestone: v1.29 — Admin UI Journey & Design-System Deep Polish

**Shipped:** 2026-06-04
**Phases:** 4 | **Plans:** 17

### What Was Built
- Route-by-route journey contracts now map the admin UI to Orient, Configure, Support, and Operate with shared vocabulary across docs and LiveView surfaces.
- Shared BEM/design-token primitives now cover repeated admin heroes, metrics, filters, rows, copy-once secrets, long values, status treatment, focus, and reduced-motion behavior.
- Support, operations, DCR/IAT, key, and client-detail weak spots now have clearer scan paths, safer risky actions, mobile-safe long values, and stronger redaction boundaries.
- Demo seeds, operator docs, screenshot inventory, browser evidence, and contract tests now pin the polished admin route surface, including 390px mobile no-page-overflow proof.

### What Worked
- Starting with the Phase 107 journey contract kept the later component and page polish grounded in operator jobs instead of page-by-page decoration.
- Contract tests were effective at holding the BEM/design-token boundary while allowing localized CSS/component improvements.
- Browser and screenshot evidence exposed mobile overflow issues that static source checks would have missed.

### What Was Inefficient
- Some proof artifacts validated screenshot inventory rows and proof cells before checking referenced screenshot files directly.
- Browser evidence covered route groups after entering through overview, but not every detail and workflow route through a strict scripted click path.
- Quick-task closeout needed a legacy-compatible `SUMMARY.md` because the installed `gsd-sdk` audit scanner lagged the local scanner behavior.

### Patterns Established
- Use the route journey contract as the source of truth for page titles, docs vocabulary, screenshot inventory, and contract tests.
- Keep admin UI polish inside reusable Phoenix components plus `lockspire-admin-*` tokens before adding any one-off route CSS.
- Treat long identifiers, URLs, timestamps, and copy-once secrets as first-class responsive primitives, not incidental table content.

### Key Lessons
1. A second-pass UI milestone can be valuable when it has a contract-first route model and explicit weak-spot target list.
2. Admin UI proof should combine source contracts, route inventory, screenshots, browser checks, and mobile overflow checks; none of those alone is enough.
3. Milestone-close tooling needs compatibility artifacts when installed and local GSD scanners disagree.

### Cost Observations
- Model mix: not recorded.
- Notable: The final audit passed functionally, but retained Nyquist partial warnings because validation matrices still had pending rows despite `nyquist_compliant: true` frontmatter.

---

## Milestone: v1.30 — Adoption Demo Docker DX & Repo Hygiene

**Shipped:** 2026-06-24
**Phases:** 5 | **Plans:** 12

### What Was Built
- One `LOCKSPIRE_DEMO_BASE_URL` contract now drives endpoint URL generation, issuer, seeded local URLs, developer callback output, startup output, docs, and smoke proof.
- The default repo-local Docker demo now starts Phoenix/Bandit plus PostgreSQL with project-scoped volumes, idempotent setup, and readiness before reporting the demo ready.
- Conflict controls cover configurable Compose project names, app ports, optional DB host exposure, scoped reset, and opt-in Traefik hostname routing.
- Startup and reprint output now expose redacted URL/account/client/smoke information, including project-aware reprint guidance for alternate Compose projects.
- Stop, reset, cleanup, and hygiene lanes are scoped to the active demo project, dry-run or non-destructive by default, and backed by Docker-free CI contracts.

### What Worked
- Keeping direct Docker as the default and Traefik as an explicit override made the maintainer path simpler without losing hostname-routing support.
- Source contracts were effective for shell/docs behavior that would otherwise depend on local Docker daemon state.
- The milestone audit caught a real edge case in alternate-project reprint guidance before archival.

### What Was Inefficient
- Validation metadata quality varied across phases even when executable verification was strong.
- The generated roadmap archive preserved Phase 114/115 summary rows less descriptively than the phase archives themselves, so future readers should prefer the archived phase details for exact plan names.

### Patterns Established
- Treat demo shell scripts as public maintainer contracts: syntax-check them, assert allowed destructive scope, and keep docs/tests synchronized.
- Separate public browser URL truth from container-local readiness URL and listener bind IP.
- Keep CI deterministic by validating Docker source contracts instead of requiring a local Docker lifecycle in CI.

### Key Lessons
1. Local demo DX is part of product trust for an embedded auth library; ambiguous startup, cleanup, or smoke instructions erode confidence quickly.
2. Project-name and port overrides need to be carried through every visible command, not only startup and cleanup.
3. Milestone close should include an integration pass even when every phase verification is green, because cross-phase command drift tends to hide between individually correct slices.

### Cost Observations
- Model mix: not recorded.
- Notable: The automated follow-up closed the audit's only tech-debt item before archive.

---

## Milestone: v1.31 — Admin Design-System Stress Test

**Shipped:** 2026-06-26
**Phases:** 5 | **Plans:** 14

### What Was Built
- Source-derived admin route/workflow and component/group inventories, plus a brandbook visual rubric and internal lab boundary contract.
- A test-only Phoenix component stress lab with redaction-safe fixtures for dense, empty, disabled, destructive, long-value, theme, and reduced-motion states.
- Shared admin primitives for panes, entity headers, workflow shells, status/action clusters, lifecycle rows, dense resource rows, responsive alternatives, status semantics, and form/workflow chrome.
- Highest-drift admin pages now use clearer operator IA and consequence-oriented copy across client detail, DCR policy, IAT, token, consent, device authorization, interaction, and logout queues.
- Browser-proof matrix, deterministic ExUnit/LiveView/LazyHTML guardrails, bounded operator docs, and final adversarial signoff now protect the admin design system without public lab/theming/tooling creep.

### What Worked
- Starting with inventory and lab contracts kept the stress test systematic instead of page-by-page polish.
- Keeping the component lab under `test/support` preserved the embedded-library boundary while still making ugly states inspectable.
- LazyHTML and mounted LiveView assertions were a better fit than adding browser tooling as the blocking proof path.

### What Was Inefficient
- Phase 118 implementation proof existed in tests and summaries, but the missing `118-VERIFICATION.md` blocked the milestone audit until reconstructed.
- Phase 119 and Phase 120 validation metadata lagged actual verification, creating closeout noise despite green tests.
- The generated milestone accomplishments needed manual cleanup to remove low-level review-note extraction.

### Patterns Established
- Use source-derived route/component inventories before large admin UI system work.
- Keep design-system proof layered: source contracts, rendered component stress, mounted route assertions, docs/package boundary checks, and maintainer-only browser notes.
- Treat public support-surface drift as a first-class UI regression, not only a docs concern.

### Key Lessons
1. Component systems get stronger when the lab renders real components with hostile data before production pages adopt the primitives.
2. Milestone audits should fail on missing verification artifacts even when tests pass; the artifact is part of the project memory.
3. Browser proof does not have to mean browser tooling in the package path; deterministic rendered checks plus bounded manual evidence can be the right tradeoff.

### Cost Observations
- Model mix: not recorded.
- Notable: Closeout required an inline audit repair pass, but no product code changes were needed during archival.

---

## Milestone: v1.32 — Admin Page IA & Interaction Model Polish

**Shipped:** 2026-06-30
**Phases:** 5 | **Plans:** 24

### What Was Built
- Route scorecards and deterministic guardrails now cover every AdminRouter route plus the logout-propagation workflow.
- Token and consent Support flows now lead with decision summaries, dense redaction-safe rows or detail panes, exact consequence copy, and verified closed-state behavior.
- Interactions, device authorizations, and logout deliveries now scan by pressure, safe pivots, lifecycle context, and support notes while preserving read-only boundaries.
- Clients, DCR/IAT onboarding, keys, and policy pages now share page-first posture, copy-once handoffs, confirmation-backed risky actions, and source/stress proof.
- Redaction-safe fixtures, rendered-HTML guardrails, browser/manual maintainer evidence, operator docs, empty/no-match proof, and adversarial artifacts close the proof loop.

### What Worked
- Starting with route scorecards gave later Support, Operate, Configure, and proof work a clear operator job and regression target.
- Propagating patterns only after Support and Operate proved them kept Configure polish grounded instead of speculative.
- Keeping browser/manual evidence maintainer-only while making parsed proof rows deterministic preserved the package/runtime boundary.

### What Was Inefficient
- The first milestone audit was run before Phases 123-125 existed, so closeout needed a fresh audit repair pass.
- Broad `mix test.fast` remained noisy because out-of-scope Phase 115 adoption-demo/release-readiness failures and one `jwks_fetcher_test.exs` rerun failure were carried as deferred debt.
- Browser/manual evidence was captured from the maintainer working tree, not a clean detached checkout, so deterministic tests had to remain the blocking proof.

### Patterns Established
- Treat route scorecards as a maintainer contract tying persona, top task, state coverage, follow-up route, and public-boundary truth together.
- Use pressure-first dense rows for support and operation queues when tables would hide lifecycle and consequence information.
- Parse proof artifacts structurally when manual/browser evidence is accepted, instead of relying on screenshot filenames or raw markdown grep.

### Key Lessons
1. Page-first UI polish is easier to verify when every route has a scorecard before implementation work starts.
2. Read-only operator surfaces need explicit negative assertions for unsupported controls, not just absence by convention.
3. Manual/browser evidence can be useful at closeout, but the milestone gate should stay deterministic and repo-native.

### Cost Observations
- Model mix: not recorded.
- Notable: The formal audit ended as `tech_debt` rather than `passed` because the remaining issues were non-blocking support-hardening and proof-environment caveats.

---

## Milestone: v1.37 — Prime-Time Readiness Ratchet

**Shipped:** 2026-08-28
**Phases:** 7 | **Plans:** 58 | **Tasks:** 127

### What Was Built
- An executable packaged Phoenix installation path covering generated routes, host consent, migrations, configuration verification, claims examples, and secure default smoke proof.
- Additive semantic token/client/resource-server APIs plus a real separate-origin provider/client/protected-resource journey over HTTP.
- Cycle-free dependency direction, cohesive Ecto/token collaborators, atomic behavior proof, strict static analysis, quiet runtime evidence, and complete-suite coverage above 84%.
- Immutable supplemental OIDF evidence and a manifest-bound release chain that published and publicly re-verified Lockspire 1.5.0 from one exact tar.

### What Worked
- Using installation and the clean-room SaaS journey as the acceptance spine forced public APIs, architecture, CI, and release automation to meet at real host boundaries.
- Characterization before structural refactors preserved protocol responses, persistence, audit, telemetry, and compatibility while large modules were decomposed.
- Exact-SHA CI and checksum-bound release receipts converted release trust from workflow convention into retained evidence.

### What Was Inefficient
- The first hosted conformance run exposed a real public-DCR credential-method defect late in closure; fixing DCR before rerunning the suite advanced Phase37 to deeper authorization semantics.
- Release automation required two closure fixes: ESM compatibility for the checked runtime and an explicit canonical-CI dispatch after token-authored release merges.
- GSD's loose plan-file scanner counted `PLAN-CHECK`/`PLAN-AUDIT` artifacts as unfinished plans, and summary edits then correctly staled older verifier timestamps; closeout needed metadata normalization before archival.

### Patterns Established
- Treat the host seam as a compile-and-run contract, not prose: generated artifacts must boot and complete the supported protocol flow in a clean app.
- Carry one immutable artifact identity through prepublish proof, protected upload, registry checksum, docs, and postpublish install truth.
- Keep external conformance reproducible and safely retained even when it fails; a classified supplemental failure is better evidence than a false certification signal.

### Key Lessons
1. A mature OAuth library needs cross-origin and resource-server proof, not only endpoint-level protocol tests.
2. Release automation must explicitly account for GitHub token event-suppression semantics; successful auto-merge does not imply a recursive push workflow.
3. Machine-readable planning metadata is part of durable verification and should be normalized before the final audit, not during archive.

### Cost Observations
- Model mix: not recorded.
- Notable: The milestone completed autonomously with 36/36 requirements and a real public release; no new user-provisioned secret was required because protected repository credentials were already configured.

---

## Milestone: v1.36 — Structural Quality Ratchet

**Shipped:** 2026-08-26
**Phases:** 5 | **Plans:** 30 | **Tasks:** 63

### What Was Built
- Exact-ref CI evidence now gates release publication, recovery inputs fail closed, supply-chain dependencies are immutable, and the published Hex artifact has independent install-truth proof.
- Credo parse coverage, a measured ExUnit coverage floor, PostgreSQL 14, Phoenix 1.8.5, LiveView 1.1.28, and zero-warning Dialyzer are executable quality baselines.
- Narrow storage, transaction, audit, logout, Oban, and admin-query contracts repair the host-Repo versus Lockspire-storage boundary and prevent regression.
- Token grant coordination now sits behind the stable `TokenExchange` facade with centralized lifetime policy and one fail-closed private JWK decoder.
- Shared test isolation, capability-oriented contract suites, current-source documentation, and an explicit artifact policy reduce proof maintenance cost.

### What Worked
- Sequencing release proof, quality baselines, runtime boundaries, token cohesion, then readability let each phase consume stronger foundations from the previous one.
- Architecture fitness tests turned subtle host-Repo/storage ownership rules into executable constraints instead of review conventions.
- The final integration pass proved all 21 expected connections and all 6 representative flows, catching aggregate-reporting drift without finding product blockers.

### What Was Inefficient
- Phase 126 and Phase 129 summaries omitted `requirements-completed` metadata, so 10 behaviorally satisfied requirements could not achieve full three-source audit triangulation.
- Nyquist was enabled but no Phase 126-130 `VALIDATION.md` reconciliation files existed, leaving a proof-process gap at closeout.
- The milestone archiver reported zero tasks because these plan files did not expose task totals in the format it aggregates; the historical summary required correction to the verified 63-task count.

### Patterns Established
- Release publication must be tied to the exact immutable commit whose CI evidence is inspected, followed by independent installed-artifact proof.
- Treat host Ecto repos and Lockspire storage adapters as different dependency types and enforce that distinction with narrow ports plus AST/runtime tests.
- Split large proof suites by capability while retaining one shared test-only isolation layer and executable no-loss inventories.

### Key Lessons
1. Behavioral verification and metadata completeness are separate deliverables; both must be normalized before milestone audit to avoid preventable `tech_debt` verdicts.
2. Architectural boundaries become durable when production indirection and regression fitness tests land together.
3. Aggregate planning tools need their own closeout sanity checks even when every underlying phase report passes.

### Cost Observations
- Model mix: not recorded.
- Notable: The milestone closed with accepted non-blocking proof debt; behavior, integration, and representative flows all passed.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.37 | N/A | 7 | Packaged adoption, real SaaS integration, architecture quality, conformance evidence, and exact-artifact release proof converged into one acceptance spine. |
| v1.36 | N/A | 5 | Structural quality moved release, CI, architecture, token policy, and repository proof from convention to executable contracts. |
| v1.32 | N/A | 5 | Admin UI quality moved from component stress to page-first IA and interaction proof. |
| v1.31 | N/A | 5 | Admin UI quality moved from page polish to source-derived design-system stress contracts. |
| v1.30 | N/A | 5 | Docker demo lifecycle and hygiene commands became source-contracted maintainer surfaces. |
| v1.29 | N/A | 4 | Route journey contract became the admin UI source of truth across docs, tests, screenshots, and page polish. |
| v1.27 | ~6 | 6 | Hash-pinned canonical docs as an executable contract before code. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.37 | Canonical CI, clean-room provider/client/resource journey, dual-router Sobelow, architecture/quality gates, OIDF receipts, and protected public release proof | 84%+ complete suite | Semantic token readers, neutral client lifecycle, aggregate stores, typed token collaborators, immutable evidence scripts |
| v1.36 | Exact-ref release contracts, quality gates, architecture fitness tests, Dialyzer, split proof suites, and final integration flows | 73% floor | Storage ports/services, lifetime policy, private JWK decoder, shared isolation helpers |
| v1.32 | ExUnit/LiveView/LazyHTML rendered route proof, source contracts, parsed browser evidence, docs, and adversarial artifacts | High | Route scorecards, BrowserEvidence parser, redaction-safe proof matrix extensions |
| v1.31 | ExUnit/LiveView/LazyHTML source, rendered component, mounted route, docs, and package-boundary guardrails | High | Test-only admin lab fixtures, stress surface, and HTML assertion helpers |
| v1.30 | Docker/source/docs/hygiene contracts plus smoke wrapper proof | High | POSIX shell lifecycle helpers and deterministic CI source checks |
| v1.29 | Admin LiveView/design-system/browser/screenshot proof | High | BEM/design-token contract tests |
| v1.27 | N/A | High | Contract tests |

### Top Lessons (Verified Across Milestones)

1. **Executable Documentation:** Pinning docs to tests prevents setup guides from drifting from the runtime implementation.
2. **End-to-End Proof:** Smoke tests and generated-host tests are the ultimate arbitrator of feature completion.
3. **Route Contracts for Operator UI:** UI polish scales better when every route has an explicit job, risk state, empty state, and follow-up route before component work starts.
4. **Demo Lifecycle Contracts:** Maintainer-facing Docker scripts need the same source-contract and redaction discipline as protocol-facing code.
5. **Design-System Stress Before Polish:** Real component labs with hostile fixture data make reusable UI improvements safer than isolated route edits.
6. **Proof Artifacts Need Parsers:** Manual/browser evidence becomes more reliable when closeout tests parse structured rows and enforce redaction, viewport, and gap fields.
7. **Metadata Is Part of Verification:** Passing behavior is not enough for durable project memory; summary frontmatter and Nyquist reconciliation must close with the implementation.
