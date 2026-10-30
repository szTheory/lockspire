---
phase: "178"
slug: "packaged-upgrade-proof-delivery-handoff"
status: validated
nyquist_compliant: false
wave_0_complete: false
coverage_verdict: PARTIAL
recorded: "2026-10-29"
supersedes_execution_map: "178-ACCEPTANCE-ADDENDUM.md#executed-validation-map--later-evidence-metadata"
---

# Phase 178 — Postrun Validation Coverage Audit

## Authority and immutability

This dated postrun report is the current validation-discovery result. It was
created after actual local, hosted, candidate, handoff, verification, and
security outcomes were available. The original `178-VALIDATION.md` is a frozen
historical planning draft and selected input of the security-reviewed 1,079
input closure. It remains byte-identical (SHA-256
`213413e7252aecc8e075f824a6103579e819c5a37fe4f4b0a2f75b9b5a037ed7`). Its
`draft`/false bits describe that original draft and are not rewritten. The
executed map in the acceptance addendum records actual command/evidence
ownership; this report adds requirement-level coverage judgments. These later
reports do not restamp historical package executions or change their identity.

This report does not claim Nyquist compliance. Existing behavioral tests and
receipts cover the declared positive package and delivery outcomes, but
unclassified evidence edges and plan prohibitions remain explicitly
unverified/non-authoritative. Closed declared security threats do not resolve
those separate validation questions. No new runtime checks were started for
this audit.

## Test infrastructure and actual execution evidence

| Layer | Framework / entry point | Actual green evidence reviewed | Coverage boundary |
|---|---|---|---|
| Acceptance harness contracts | Python standard-library `unittest`; named acceptance contract suites and native receipt validators | Existing named Python focused records include the 12 wrapper contracts from the pre-C762 working tree and unchanged control blob at its commit; they are not an E7AD Python-suite execution claim. Native acceptance validators separately accepted the retained package receipts and candidate/handoff evidence. | Harness behavior; not a substitute for installed package behavior; no claim that all Python tests ran at E7AD |
| Source and integration behavior | ExUnit through owned-source runner / canonical CI | E7AD local canonical gate 2,463 ExUnit tests/0 failures + 2 properties; actual hosted Fast 2,187/0, Minimum 2,755/0, Integration 565/0 + 3 lifetime tests/0 | Exact source/checkout identities retained in source acceptance and CI receipts |
| Installed package matrix | Native receipt validator and clean-room package hosts | Fresh E7AD local matrix 26 receipts / 64 cases / 0 failures; actual hosted attempt 2 locked 14/33 and floor 12/31; aggregate 26/64 accepted by native candidate checker | Current/minimum hosted profiles are separate from the local floor; EC92 47 lifetime checks, 9 scenarios, 5 SaaS groups, and 96 host scenarios retain original EC92 execution identity and apply to E7AD only through measured archive/tree byte equality |
| Candidate / handoff | Native `_check_candidate` and `_check_handoff` | Original execution 34027 exit 0; 7 hosted jobs authenticated; candidate and pending-main handoff accepted; 80 original child processes closed | D-19 permits pending integration/main; no main acceptance receipt or merge is claimed |
| Reviews and requirement disposition | Independent phase verification, integration check, security assessment, milestone audit | Verification PASSED 4/4 roadmap truths and 3/3 phase requirements; integration traced 5 flows and 18 requirements; canonical security assessment SECURED 37/37 declared threats, 0 open, 0 accepted risks | Does not discharge unclassified edges, historical flags, or non-authoritative prohibitions |

## Requirement coverage

The requirement map distinguishes demonstrated behavior from evidence that
remains deliberately unresolved. “Covered” means a concrete existing
behavioral test/receipt or independent observable verification is bound below;
it does not mean every advisory or provenance flag is resolved.

| Requirement | Behavioral test / actual evidence | Status |
|---|---|---|
| VPROOF-02 — installed source-bound upgrade proof | Focused acceptance harness tests and installed runner groups from plans 01–08; E7AD source acceptance, local 26/64 matrix, actual hosted attempt-2 7/7 jobs and same-attempt 26/64 native receipt validation; source/package/checkout identities remain distinct | COVERED |
| VDELIV-01 — reviewed and executable delivery evidence | Guidance and rewrap ExUnit coverage; three focused review lanes; guarded contributor gate; actual hosted seven-job candidate graph and same-attempt artifacts; independent canonical audit and verification | PARTIAL: declared evidence chain is covered, while two spec-less edges retain null verification and plan prohibition flags remain unverified/non-authoritative |
| VDELIV-02 — truthful custody and premerge handoff | Native `_check_handoff` accepted actual dated pending state; independent verification truth 4 and requirement disposition; custody/handoff record names owner, blocker, next action, retained unknowns, and absent main receipt | PARTIAL: premerge handoff behavior is covered; spec-less edge and prohibition flags remain unresolved; accepted-main behavior is intentionally not claimed or required by D-19 |

## Plan/task verification map

Commands are not rerun here. The actual identities and results are those in
`178-SOURCE-ACCEPTANCE.json`, the acceptance addendum and its linked native
receipt projections, `178-VERIFICATION.md`, `178-SECURITY.md`, and the
canonical milestone/integration reports. For plans 01–08, “matrix” means the
installed runner/strict native receipt evidence above, not a claim that every
historical planned command was re-executed at E7AD.

| Task | Requirement | Existing behavioral coverage / actual result | Status |
|---|---|---|---|
| 178-01-01 | VPROOF-02 | Tracer preparation/binding and strict receipt tests; installed tracer scope represented in actual package matrix | COVERED |
| 178-01-02 | VPROOF-02 | Adversarial preparation/receipt contracts and strict native actual-case validation | COVERED |
| 178-02-01 | VPROOF-02 | Core installed-package cases across pair/store profiles; actual matrix receipts | COVERED |
| 178-02-02 | VPROOF-02 | Rewrap/task and repository runner ExUnit tests; actual core matrix receipts | COVERED |
| 178-03-01 | VPROOF-02 | Rollout and legacy-control installed evidence, with public control kept narrowly attributed | COVERED |
| 178-03-02 | VPROOF-02 | Actual rollout matrix and retained locked-only legacy control | COVERED |
| 178-04-01 | VPROOF-02 | Installed mounted endpoint group with individual endpoint/case IDs | COVERED |
| 178-04-02 | VPROOF-02 | Release RPC installed observation and endpoint matrix; explicit exclusions remain scoped | COVERED |
| 178-05-01 | VPROOF-02 | Contention behavior and ExUnit concurrency regression; actual installed receipts | COVERED |
| 178-05-02 | VPROOF-02 | Atomicity cases on delegated stores across supported pairs | COVERED |
| 178-06-01 | VPROOF-02 | Recovery behavior, maintenance and legacy-age ExUnit coverage; installed recovery receipts | COVERED |
| 178-06-02 | VPROOF-02 | Issuance behavior and guarded-issuance ExUnit coverage; installed issuance receipts | COVERED |
| 178-07-01 | VPROOF-02 | Disclosure harness tests and installed disclosure receipts; source/channel coverage remains separately evidenced | COVERED |
| 178-07-02 | VPROOF-02 | Both-pair installed disclosure and owned-source disclosure/inspection tests | COVERED |
| 178-08-01 | VPROOF-02, VDELIV-01 | Strict receipt contracts and actual native aggregate validation (26/64/0); current hosted owner artifacts authenticated | COVERED |
| 178-08-02 | VPROOF-02, VDELIV-01 | CI wrapper contract tests plus actual hosted attempt-2 complete graph 7/7 and native current/floor artifacts | COVERED |
| 178-09-01 | VDELIV-01 | Guidance/re-wrap ExUnit tests, three source/security review lanes, actual contributor gates | COVERED |
| 178-09-02 | VDELIV-01 | Reviewed documentation and independent audit trace it to supported observations | COVERED |
| 178-10-01 | VPROOF-02, VDELIV-01 | Native private assembly accepted five semantic stages; source/frozen/package/review identity evidence retained | COVERED |
| 178-10-02 | VPROOF-02, VDELIV-01 | ROOT semantic checks accepted four stages with retained roots and unchanged inputs | COVERED |
| 178-10-03 | VPROOF-02, VDELIV-01 | Native candidate identity, registry authority, receipt ownership, wrapper lifecycle and delivery-chain adversarial contracts; final native acceptance | COVERED |
| 178-11-01 | VDELIV-01, VDELIV-02 | Actual hosted attempt-2 seven-job graph, exact job-owned locked/floor artifacts, native candidate and handoff checks | COVERED |
| 178-11-02 | VDELIV-01, VDELIV-02 | Actual checkout/artifact owner authentication, strict raw partition checks, truthful pending-main boundary | COVERED |
| 178-12-01 | VDELIV-01, VDELIV-02 | Independent custody/handoff verification, dated owner/action and preserved unknown-resource disposition; UI-next ranking retained | PARTIAL: plan’s three projected prohibitions stay unresolved, flagged, non-authoritative; two unclassified delivery edges remain null/unverified |
| 178-12-02 | VDELIV-01, VDELIV-02 | Canonical audit; independent verification 4/4 truths and 3/3 requirements; independent integration check; security review completed 37/37 declared threats | PARTIAL: unresolved/unclassified evidence is preserved correctly, but no behavioral test or human adjudication resolves it; accepted-main remains pending by design |

## Explicitly unresolved coverage

- E02, E14, E15, E09, and E10 retain their original unresolved/flagged
  dispositions.
- The two generic, spec-less VDELIV-01/VDELIV-02 assumptions retain null
  verification. No concrete predicate or passing probe is inferred.
- All three plan-12 projected prohibitions remain unresolved, flagged,
  unverified, and non-authoritative, with human review recommended. This report
  does not claim that review occurred.
- Descriptorless prohibitions and their original no-descriptor judgments remain
  unresolved. Closed T-178-01 through T-178-36 and T-178-SC declared mitigations are not
  evidence that these separate edges passed.
- Historical failed attempts, unknown inner predicates, custody unknowns, and
  root-tar restoration incident remain retained and unwaived.
- Integration and accepted main remain pending under D-19. The absent
  `178-MAIN-ACCEPTANCE.json` is correct; no post-merge/helper behavior is
  asserted.

These are validation gaps in the formal coverage record, not a finding that the
green package/runtime outcomes failed. The appropriate current classification
is PARTIAL, with the unresolved edges explicitly identified for later evidence
or human disposition. Do not set `nyquist_compliant` true until those items are
independently resolved or explicitly dispositioned under their governing
process.

## Audit scope

Read-only inspection of the phase plans 01–12, summaries 01–11, frozen
validation draft, executed acceptance map, requirement dispositions, final
verification/security assessments, canonical milestone audit, and independent
integration check. No tests, application/runtime checks, database/browser
checks, or source/implementation changes were made in this audit.
