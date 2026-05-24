---
phase: 66
slug: conformance-debt-retirement-milestone-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 66 — Validation Strategy

> Per-phase validation contract for conformance-truth retirement and milestone-closure evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/lockspire/release_readiness_contract_test.exs` |
| **Full suite command** | `mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/protocol/token_exchange_test.exs test/integration/phase6_onboarding_e2e_test.exs test/integration/phase37_protocol_strictness_e2e_test.exs` |
| **Estimated runtime** | ~5 seconds measured from recent targeted runs in this workspace |

## Sampling Rate

- **After every task commit:** run the task-local verify command from the plan
- **After every plan wave:** run the full suite command above
- **Before `$gsd-verify-work`:** the full suite command must be green
- **Max feedback latency:** 5 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | CONF-01, CONF-02 | T-66-01-01 / T-66-01-03 | Conformance-truth drift fence rejects future overclaims and keeps canonical proof references narrow | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 66-01-02 | 01 | 1 | CONF-01, CONF-02 | T-66-01-01 / T-66-01-02 | Canonical and maintainer docs describe repo-native proof first and external-suite work as secondary manual evidence only | contract | `mix test test/lockspire/release_readiness_contract_test.exs` | ✅ | ⬜ pending |
| 66-02-01 | 02 | 2 | CONF-01 | T-66-02-01 | Historical Phase 37 summary no longer claims `CONF-04` completed when verification says otherwise | artifact | `! rg 'requirements-completed: \\[CONF-04\\]|Phase 37 is now complete|CONF-01 through CONF-04 satisfied' .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md && rg '37-VERIFICATION.md|historical|skipped|non-authoritative' .planning/phases/37-protocol-strictness-conformance/37-04-SUMMARY.md` | ✅ | ⬜ pending |
| 66-02-02 | 02 | 2 | CONF-01 | T-66-02-02 | Raw artifact bundle is preserved but explicitly labeled as skipped-suite historical audit trail, not current proof | artifact | `test -f .artifacts/conformance/phase37/README.md && rg 'historical|skipped|non-authoritative|do not use as current proof' .artifacts/conformance/phase37/README.md` | ❌ | ⬜ pending |
| 66-03-01 | 03 | 3 | V-01 | T-66-03-01 / T-66-03-02 | v1.16 closes with a milestone audit that maps every requirement to proof or explicit non-claim without creating a second contract | artifact | `test -f .planning/milestones/v1.16-MILESTONE-AUDIT.md && rg '## Verdict|## Requirements Audit|## Phase Audit|## Integration Audit|## Nyquist Discovery|HOST-01|HOST-02|HOST-03|SIGRA-01|SIGRA-02|SIGRA-03|TRUTH-01|TRUTH-02|CONF-01|CONF-02|V-01' .planning/milestones/v1.16-MILESTONE-AUDIT.md` | ❌ | ⬜ pending |
| 66-03-02 | 03 | 3 | CONF-02, V-01 | T-66-03-02 | Planning state records the retired conformance debt honestly and no longer implies the old Phase 37 lane is still the closure path | artifact | `! rg 'Phase 37 verification debt remains acknowledged and deferred' .planning/STATE.md && rg 'retired|non-claim|historical' .planning/STATE.md && rg 'CONF-01|CONF-02|V-01' .planning/REQUIREMENTS.md && rg 'milestone-close workflow|milestone close workflow|post-phase milestone-close workflow' .planning/STATE.md .planning/milestones/v1.16-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Wave 0 Requirements

- [x] `66-01` Task 1 establishes the release-readiness drift fence before broad doc-truth changes land
- [x] Per-task sampling uses the targeted release-readiness test runtime already exercised in this workspace
- [x] Early coverage exists for current-proof hierarchy and explicit non-claim wording before historical-artifact demotion begins

*Wave 0 baseline is satisfied by starting Phase 66 with the contract-test fence.*

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional external OIDF or FAPI suite execution remains clearly supplemental rather than a release gate | CONF-02 | The truth to validate is wording and maintainer workflow posture, not a deterministic local test outcome | During review, confirm `docs/maintainer-conformance.md` positions any external-suite run as optional maintainer corroboration and not as a required release or milestone-close step |
| Milestone-close evidence index is easy for a maintainer to follow end to end | V-01 | Human readability and least-surprise hierarchy are documentation qualities, not binary runtime facts | Read `v1.16-MILESTONE-AUDIT.md` from top to bottom and confirm each requirement points to one canonical proof artifact or explicit non-claim without duplicating the public support contract |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or an explicit artifact validation command
- [ ] Sampling continuity: no 3 consecutive tasks without executable verification
- [ ] Wave 0 covers all current-proof hierarchy risks before doc or audit changes land
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
