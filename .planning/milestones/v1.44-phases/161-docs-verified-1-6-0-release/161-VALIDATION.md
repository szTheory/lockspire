---
phase: "161"
slug: "docs-verified-1-6-0-release"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-20"
validated: "2026-10-20T19:40:16+00:00"
---

# Phase161 Validation Coverage

Audited inline after all nine plans produced summaries. No missing behavioral coverage; no new tests needed beyond the shipped contract extensions. External publication facts were verified with live checks rather than mocked completion.

## Infrastructure and feedback

- ExUnit on Elixir1.19.5-otp-28 / OTP28.5; existing Mix/CI aliases.
- Quick command: `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs test/lockspire/documentation_contract_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs` — fresh14tests,0failures in0.2s.
- Existing release/hygiene contracts:13tests,0failures on refreshed1.6.0 ledger. That broader command took74.9s; it is not claimed to meet the quick-feedback target.
- Prior-phase regression extraction:5existing files,118tests,0failures. Full CI ran required suites, docs, quality, compatibility, coverage and smoke checks on actual source and record PR heads. Long external runs are bounded by their existing workflow timeouts, not a fictional sub-minute completion claim.

## Requirement and task map

| Requirement / plans | Behavior | Executable evidence | Result |
|---------------------|----------|---------------------|--------|
| DOC-02 /01 | Seven shipped Key protection labels, read-only/Unknown meaning and guide pointers | kek_guidance_contract_test.exs, upgrade_guide_contract_test.exs, documentation_contract_test.exs, vocabulary_contract_test.exs; CI docs.verify | PASS |
| REL-01 /02 | Metadata may precede publication, malformed/lower/inconsistent release claims block | repo_hygiene_check.sh --ci; repository_hygiene_contract_test.exs and release_automation_contract_test.exs fixture matrix | PASS |
| REL-01 /02,06 | Actual release-head gate, not simulation-only assumption | Head12114bb0835 disposable-worktree hygiene18PASS/0BLOCK and13contracts; actual PR checks after normal workflow approval; source428a9c53 pushCI39478977350 all7success | PASS |
| REL-01 /03–06 | Exact v1.44 landing, #122 override and complete1.6.0 changelog; guarded squash source | gh read-backs/hashes, exact-head pins, parent/tree equality, retained source CI and Release run IDs in RELEASE-EVIDENCE | PASS |
| REL-02 /07 | One exact proven artifact published through protected lane; authorization cleaned | Run39481079989 all applicable jobs success; terminal release_verified true/blocker none; variable absence read-back | PASS |
| REL-02 /08 | API == tarball == retained manifest; docs/tag/release/task inventory | Independent public Python-isolated/curl/tar checks; exact11Mix tasks; fourDocs200; verified tag/release targetS | PASS |
| REL-02 /08 | Fresh public install and new task | Isolated HEX_HOME/MIX_HOME host==1.6.0; lockfile outer checksum match; dependency compile and gen.kek length44 only | PASS |
| REL-02 /09 | Truthful ledger on main preserves prior releases and metadata | Local hygiene18PASS/0BLOCK and13contracts; PR133all8checks; merge5e8a484c parentS/tree==R; origin/main ledger read-back; Releasepushsuccess/no new releasePR | PASS |
| SAFE-02 /03,06 | No protocol/schema/dependency/default changes in v1.44 milestone | Empty forbidden-path diff038df080..S1db33c470; exactT==S1; added-line emission sweep36hits | PASS |
| SAFE-02 /03,04 | No key/KEK leak; validation errors unchanged after approved fix | Existing199-test safety suite and9cold client tests pass; Dialyzer0errors; gen.kek value never recorded | PASS |

## Wave0 and completion coverage

- Gate repair, file-derived tests and documentation-contract extension delivered and exercised.
- External verification commands and outputs retained inline in RELEASE-EVIDENCE; no missing placeholder script.
- All nine plans have automated verification/read-back evidence. Authorization is a maintainer decision, captured explicitly and later granted conditionally for green checks; it is not mislabeled as an unperformed human test.
- Bot PR workflow behavior was corrected from live evidence: normal approval-required runs exist and were approved, with no protection bypass.
- No outstanding manual-only behavior verification. Existing branch/environment protections remained active; no watch-mode test flags or unbounded local test process.

## Sign-off

Coverage complete for DOC-02,REL-01,REL-02,SAFE-02. Source and record-PR gates have executable passing evidence; final main readiness is separately observed until its CI run completes. Audit adds no product behavior and no new test duplication.

## Validation Audit 2026-10-20

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
