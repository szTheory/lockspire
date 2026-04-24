---
phase: 16
slug: verification-and-release-runtime-hygiene
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-24
---

# Phase 16 - Validation Strategy

> Per-phase validation contract for PAR milestone closure evidence and release runtime hygiene without widening scope.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit contract, protocol, web, and integration tests plus checked-in workflow/docs review artifacts |
| **Config file** | `test/test_helper.exs`, `config/test.exs`, `.github/workflows/release.yml`, `docs/maintainer-release.md` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/release_readiness_contract_test.exs && mix docs.verify` |
| **Estimated runtime** | ~25-35 seconds for focused proof loops; ~45-60 seconds for the wave/closure suite |

---

## Sampling Rate

- **After every task commit:** Run the focused command listed for that task below.
- **After every plan wave:** Run the full suite command and capture the result in `16-VERIFICATION.md` during execution.
- **Before phase closure:** All focused commands plus the full suite command must be green, and the execution report must reconcile `PAR-04` and `RELS-04` to concrete evidence.
- **Max feedback latency:** Keep task-level loops under ~35 seconds; reserve the longer wave-end suite for closure proof only.

### Nyquist Note

Phase 16 keeps `nyquist_compliant: true` because it reuses focused existing harnesses and repo-truth contract tests instead of introducing broad new suites. Per D-02 and D-03, there is no Nyquist backfill for historical validation files unless execution uncovers a concrete closure blocker.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | PAR-04 | T-16-01 / T-16-03 | Existing protocol, web, integration, and discovery harnesses are traced explicitly to PAR success, expiry, wrong-client rejection, replay rejection, and discovery truth without inventing a second proof stack | protocol + web + integration + contract | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs` | ✅ existing reused | ✅ green |
| 16-01-02 | 01 | 1 | PAR-04 | T-16-02 | Closure proof either records that the existing Phase 15 PAR harnesses are sufficient or closes one demonstrable gap in-place, then captures the result in `16-VERIFICATION.md` | closure suite | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` | ✅ existing reused / ✅ execution report created during plan execution | ✅ green |
| 16-02-01 | 02 | 1 | RELS-04 | T-16-04 / T-16-05 | The checked-in release lane replaces the deprecated Node 20 Release Please implementation detail without changing review-only PR posture, recovery-only manual dispatch, or the protected `hex-publish` boundary | contract | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | ✅ existing reused | ✅ green |
| 16-02-02 | 02 | 1 | RELS-04 | T-16-06 | Maintainer docs and repo-truth tests remain aligned with `mix ci`, `mix release.preflight`, `mix hex.publish --yes`, checked-in Release Please config/manifest, and the warning-free runtime swap | docs + contract | `mix docs.verify && MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | ✅ existing reused | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Earliest Verification Artifacts

- [x] `test/lockspire/protocol/authorization_request_test.exs` - existing reused protocol harness covering PAR success, expiry, replay rejection, wrong-client burn, and mixed-input rejection
- [x] `test/lockspire/web/authorize_controller_test.exs` - existing reused browser-path harness covering PAR-backed `/authorize` success and safe failures
- [x] `test/lockspire/web/discovery_controller_test.exs` - existing reused discovery-truth contract harness
- [x] `test/integration/phase15_par_authorization_e2e_test.exs` - existing reused canonical PAR end-to-end proof; this remains the milestone's canonical `/par -> /authorize -> /token` evidence
- [x] `test/lockspire/release_readiness_contract_test.exs` - existing reused release-contract and public-truth harness
- [x] `.planning/phases/16-verification-and-release-runtime-hygiene/16-VERIFICATION.md` - execution-time closure artifact recording `PAR-04` command results, reused evidence, and no-gap findings during `16-01`

---

## PAR-04 Requirement-To-Command Traceability

| Truth | Reused Evidence | Command | Status | Notes |
|-------|-----------------|---------|--------|-------|
| PAR success resolves into the canonical authorization contract | `test/lockspire/protocol/authorization_request_test.exs` | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs` | ✅ green | `AuthorizationRequest.validate/1` consumes a Lockspire-issued `request_uri` and returns `%Validated{}`. |
| Expired `request_uri` values fail safely | `test/lockspire/protocol/authorization_request_test.exs`, `test/lockspire/web/authorize_controller_test.exs` | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs` | ✅ green | Protocol and browser surfaces both reject expired PAR references. |
| Wrong-client PAR usage is rejected and burns the reference | `test/lockspire/protocol/authorization_request_test.exs`, `test/lockspire/web/authorize_controller_test.exs` | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs` | ✅ green | The same reference remains unusable by the original client after wrong-client access. |
| Replay rejection remains enforced after first successful use | `test/lockspire/protocol/authorization_request_test.exs`, `test/lockspire/web/authorize_controller_test.exs`, `test/integration/phase15_par_authorization_e2e_test.exs` | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs` | ✅ green | Phase 15's E2E harness remains the canonical replay-proof closure evidence. |
| Discovery advertises only the narrow shipped PAR slice | `test/lockspire/web/discovery_controller_test.exs` | `MIX_ENV=test mix test test/lockspire/web/discovery_controller_test.exs` | ✅ green | Discovery publishes `pushed_authorization_request_endpoint` and omits broader request-object metadata. |

### Reused Evidence Notes

- `test/integration/phase15_par_authorization_e2e_test.exs` remains the canonical `/par -> /authorize -> /token` proof for milestone closure. Phase 16 reuses that harness directly instead of creating a second end-to-end suite.
- No concrete `PAR-04` gap was found during the traceability audit, so no new PAR test file or duplicate Phase 16 proof pyramid was added.

---

## Typed Human-Only Verifications

All local repo checks are automated and green. One external-service confirmation remains: a live GitHub Actions recovery run should prove that invalid branch refs fail before publish, valid immutable refs proceed, and the deprecated Node 20 warning is gone. That item is persisted in `16-HUMAN-UAT.md` and referenced from `16-VERIFICATION.md`.

---

## Source Coverage Audit

| Source Type | Item | Covered By | Notes |
|-------------|------|------------|-------|
| GOAL | Close milestone verification for the PAR wedge | Plan `16-01` | Reuses existing PAR harnesses and writes closure traceability per D-04 through D-07 |
| GOAL | Remove the deprecated release runtime warning without regressing the trusted preview release path | Plan `16-02` | Limited to workflow implementation swap, maintainer docs, and repo-truth tests |
| REQ | `PAR-04` | Plan `16-01` | No new tests unless the traceability audit identifies a concrete gap |
| REQ | `RELS-04` | Plan `16-02` | Preserves review-only Release Please, recovery-only `workflow_dispatch`, protected `hex-publish`, `mix ci`, `mix release.preflight`, and `mix hex.publish --yes` |
| RESEARCH | Reuse the Phase 15 proof stack as the canonical evidence surface | Plan `16-01` | Existing PAR proof harnesses are explicitly marked as reused evidence |
| RESEARCH | Replace the warning-producing Release Please action with a checked-in implementation path | Plan `16-02` | Uses a repo-controlled action path instead of redesigning release policy |
| CONTEXT | D-01 to D-07 | Plan `16-01` | Scope limited to `PAR-04`; traceability-first closure; Phase 15 end-to-end harness remains canonical |
| CONTEXT | D-08 to D-14 | Plan `16-02` | Release policy preserved; runtime fix remains an implementation-detail replacement only |

No unplanned source items found. Deferred Nyquist backfill and broader release-process redesign remain out of scope.

---

## Validation Sign-Off

- [x] All planned tasks have executable automated verification commands
- [x] Existing PAR proof harnesses and release contract tests are explicitly marked as reused evidence
- [x] `16-VERIFICATION.md` is treated as an execution output, not a planning-time completed report
- [x] No Nyquist backfill is included absent a concrete blocker
- [x] No broader release-process redesign is included
- [x] Exactly two plans cover the Phase 16 roadmap scope

**Approval:** automated checks complete; awaiting live GitHub Actions recovery proof
