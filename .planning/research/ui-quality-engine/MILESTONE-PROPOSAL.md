# Proposal: composable UI stories and continuous quality

**Captured:** 2026-10-25. **Status:** unversioned, unscheduled candidate; no milestone opened, phase numbers reserved or implementation started. [Recommendation](RECOMMENDATIONS.md) · [Inventory](INVENTORY.md).

## Why this deserves a place in the rolling direction

The owner identified a high-leverage quality opportunity: inspect real UI compositions and jobs with plausible data before expensive browser journeys or owner review. Lockspire has 20 admin LiveViews and reusable components, but no Storybook. Its existing stress fixtures, page scorecards, token/copy contracts and browser evidence provide a substantial starting point. Current gaps include coherent scenario invariants, discoverable composed states and token/metadata drift; they are evidence for a bounded pilot, not a claim the UI looks bad today.

The intended result is a fast maintainer loop from primitive to group to area to complete page/job, using production presentation and real state classes. Mechanical checks find regressions; bounded rendered review assesses hierarchy, visual restraint, language and workflow. Story count is not the success metric.

**Owner clarification, 2026-10-25:** use `phoenix_storybook` for the layered story surface. Reuse its discovery, variations, navigation and render facilities. Lockspire-specific fixture adapters and small manifest/check helpers integrate with that package; they do not become a hand-rolled replacement Storybook or second gallery.

## Required GSD ceremony

This proposal is research input to the normal GSD workflow. Before implementation, run `$gsd-new-milestone` with its goal/version confirmation, research decision, scoped requirements, roadmap approval and commit gates. Then follow the configured phase discussion, `$gsd-plan-phase` and plan checking, `$gsd-execute-phase`, verification/review and milestone audit/`$gsd-complete-milestone` closeout. Reuse the evidence here without bypassing those gates. No new milestone is opened by this clarification; the lettered build order below cannot be executed as if it were an approved GSD roadmap.

## Owner-confirmed first milestone contract

Confirmed in interview Q1–Q7 on 2026-10-25:

- Inventory the whole UI and deliver complete layered coverage for **app setup/configuration** and **token/consent investigation**. Keep remaining jobs in an explicit expansion list.
- Establish a rendered baseline, fix observed usability/design problems at the lowest shared component tier, and provide before/after evidence. Tool installation alone is not completion; do not invent defects or a quota.
- After adoption, maintain relevant stories/scenarios in the same PR as each UI change, including pruning newly impossible scenarios.
- Use the distinct [glossary terms](../../../GLOSSARY.md) operator persona, adopter profile, scenario and story variation. PRODUCT.md remains the user-facing vocabulary authority.
- Host `phoenix_storybook` inside the adoption demo in dev/test. Story rendering stays DB-free; starting the demo may require its database. Reconsider a lightweight host only for measured startup cost.
- Complete the existing Apps list/create/detail/per-app settings/credential workflows and Tokens/Consents list/detail/investigation pivots/supported revocation actions, with their real happy/error/boundary states. Provider-wide Security, Keys, registration rules and operational queues are later expansion scope.
- By milestone completion, reliable mechanical checks block new confirmed regressions in covered UI. Tune them during the pilot; explicitly triage uncertain findings, keep design judgment advisory, and retain connected behavior/security tests. Unresolved checks cannot silently become passes.

These accepted planning decisions narrow the proposal. The interview remains open for dependent choices; implementation still requires GSD milestone selection and its gates.

## Sequencing recommendation

[STATE.md](../../STATE.md) records v1.47 complete; no next milestone is selected. Therefore this is a **proposal, not an active-milestone seed**. Keep SEC-01 key isolation/rotation as the preferred provisional next implementation scope in the existing rolling ranking. Recommend this UI proposal as the next substantial candidate after SEC-01, ahead of token-concurrency, maintenance-scale or KMS candidates unless their evidence triggers become more urgent. This recommendation does not assign a version or change [ROADMAP.md](../../ROADMAP.md) / [MILESTONE-ARC.md](../../MILESTONE-ARC.md).

At the next `$gsd-new-milestone`, re-rank SEC-01, this proposal and sustaining work against current security/adopter evidence and measured pilot cost. Move UI earlier only for an actual material adopter/usability gap or a deliberate owner reprioritization. Do not bolt a broad UI refactor onto key-isolation work. If that work touches a key-status message, retain its focused existing tests and record reusable scenario requirements for this candidate.

Discoverability lives in the standing MILESTONE-GUIDE pointer. At every milestone start/close: read this proposal, refresh current UI/persona/job evidence, retire stale candidate assumptions, carry unresolved findings and prune proposed story classes. During non-UI milestones this is a brief relevance check, not a new mandatory UI audit. If superseded, update this proposal with the replacement/reason rather than restarting from memory.

## Ordered build phases, only if selected

Letters describe dependencies, **not scheduled GSD phase IDs**. Stop detailed downstream planning when the pilot does not justify more work.

| Order | Bounded outcome | Exit evidence and stop rule |
|---|---|---|
| A. Refresh jobs and scenario truth | Reuse PRODUCT.md's personas, vocabulary and four journeys; map current routes/aliases to scorecards; define the five proposed profiles only where each adds a real state. Establish fixed-time scenario graphs/adapters and domain-specific invariant tests. | Trace each case to a real caller/job; reject impossible graph/time/page/action combinations. Resolve the seed subject/account mismatch before sharing it. No destructive demo reset. |
| B. Prove one layered review loop | Add host-only dev/test `phoenix_storybook` and explicit shared scenario compilation. Use its story/variation/render facilities. Start with existing app-form/rotation areas and the Apps list/detail/setup job. Record primitive/group/area/page situations in one generated manifest. Extend L1 token/copy/redaction rules and run a minimal generic L2 observer. | Same production presentation in story and real page; no DB in render adapters; exact effective theme, source and served assets. Compile production with no tool/scenario routes/modules/assets; inspect package closure. Benchmark warm/cold iteration and CI cost. Stop/revise if host coupling overwhelms value. |
| C. Prove the second job and propagate shared fixes | Extract selected Tokens investigation presentation and then connected Consents evidence. Add many/page-boundary/mixed-script/failed-observation cases. Preserve form/events/navigation and validate support pivots. | No duplicate page markup, correct family/revocation semantics and action availability; existing connected authorization/navigation proof stays green. Both jobs show coherent narrow and desktop results in light/dark. |
| D. Calibrate blocking checks | Reconcile token JSON/runtime aliases and named layers/breakpoints. Extend existing browser/redaction/receipt machinery; evaluate axe-core with written dependency justification. Select matrix by affected callers and actual breakpoints. | Confirmed new regressions fail reproducibly; incomplete/uncertain results retain triage. Proposed incremental budgets: L1 ≤60s; L2 ≤5m warm/≤8m cold, ≤2 shards, subject to measured startup, p95 and flake evidence. No silent coverage cuts. |
| E. Curate visual and judgment review | Add selected stable screenshots and one bounded rubric pass per covered section. Extend existing Impeccable records with structured advisory findings/decisions; document incumbent DESIGN.md if useful. | Fixed source/browser/OS/DPR/fonts/time; no screenshot secrets; approved baselines separate from verification. Advisory model/prompt pinned; missing labels means uncalibrated, not invented precision. Owner reviews only unresolved taste/strategy. |
| F. Consolidate and reassess | Port remaining valuable lab review cases, retire duplicate browsing only after parity, prune impossible/redundant scenarios, document ownership and rolling reassessment. | No lost distinct behavioral proof, public surface or historical receipt. Story/caller/job links remain current. Re-rank remaining Keys, Security, registration and read-only queue coverage by evidence instead of extracting every page automatically. |

Phases B/C deliberately establish complete jobs before broad catalogue expansion. L1/L2 start in the pilot; D improves measured coverage rather than delaying all checks until extraction is finished. Keys reuse the existing lifecycle area and belong in the next propagation slice when pilot results warrant it. End-user ConsentLive remains a separate host-facing boundary; no host login/consent redesign is implied.

## Scope ceiling and success

No new protocol behavior, storage schema, mutation capability, public theming contract, product branding change, font download, adopter Node requirement or supported lab route. No paid/open-ended judge. Keep published library dependency closure small; Storybook belongs to the maintainer host. Playwright is conditional on a comparative benefit; axe-core requires justification. Do not replace integration tests with screenshots.

Success means a maintainer can select a real operator situation, inspect shared production UI at the right level/container/theme and reproduce a finding; invalid fixture graphs are rejected; new confirmed mechanical violations are caught within a measured budget; and both selected jobs have complete layered coverage and coherent functional journeys. Show rendered before/after evidence for actual observed UI improvements. If discovery finds no material defect to improve, record that evidence and re-scope through GSD rather than manufacture one or silently relabel tooling as the whole outcome. Future pages are added when they supply distinct value. Track coverage by job/state/caller, review latency, actionable defect yield, flake rate and retired scenarios; stories/component is a sprawl signal, not a quota.

## Decisions needing the owner

The grill-with-docs interview is in progress. Q1–Q7 are accepted above; dependent questions about measured cost limits, initial adopter-profile coverage and incremental maintenance boundaries remain to be resolved before declaring shared understanding. Selecting/reordering a milestone remains a later explicit GSD workflow decision. Outside this requested interview, escalate only material brand, public API/support, host ownership, adopter-visible removal or dependency/tooling scope decisions. Historical browser restrictions and their scoped resolution are quoted in RECOMMENDATIONS.md.
