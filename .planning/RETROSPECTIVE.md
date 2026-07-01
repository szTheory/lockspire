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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.32 | N/A | 5 | Admin UI quality moved from component stress to page-first IA and interaction proof. |
| v1.31 | N/A | 5 | Admin UI quality moved from page polish to source-derived design-system stress contracts. |
| v1.30 | N/A | 5 | Docker demo lifecycle and hygiene commands became source-contracted maintainer surfaces. |
| v1.29 | N/A | 4 | Route journey contract became the admin UI source of truth across docs, tests, screenshots, and page polish. |
| v1.27 | ~6 | 6 | Hash-pinned canonical docs as an executable contract before code. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
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
