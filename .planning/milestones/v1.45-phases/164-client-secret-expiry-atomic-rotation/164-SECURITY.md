---
phase: "164"
slug: "client-secret-expiry-atomic-rotation"
status: verified
threats_open: 0
threats_total: 24
threats_closed: 24
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-21"
---

# Phase 164 — Security

Independent typed gsd-security-auditor reviewed all plan-authored threats at HEAD 89001a2e, then re-audited the bounded T-164-21 correction at HEAD 5490ac7b. Result: SECURED, 24/24 closed; no accepted-risk override or unregistered flags.

## Trust Boundaries

Untrusted client credentials enter protocol authentication; verified identity crosses into current-row guarded issuance; host-authorized replacement crosses storage and required audit under one transaction authority; secret-bearing operations cross into redacted observability; durable versioned deadlines cross into public/operator claims. These are the plan-authored boundaries and preserve the host seam.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and verified evidence | Status |
|---|---|---|---|---|---|---|
| T-164-01 | Tampering | secret policy resolver/changeset | high | mitigate | 164-01-02 rejects original malformed values and returns configuration/server errors at use. Verified: `storage/ecto/server_policy_record.ex:75; protocol/dcr_policy.ex:162`. | closed |
| T-164-02 | Spoofing | ClientAuth/domain secret gate | high | mitigate | 164-01-01 verifies real material and strict deadline, with equality rejection and generic public errors. Verified: `protocol/client_auth.ex:48; domain/client.ex:217`. | closed |
| T-164-03 | Tampering | registration serializer | medium | mitigate | 164-01-03 uses effective version/method-aware state and tests legacy/no-secret branches. Verified: `web/registration_json.ex:45,67`. | closed |
| T-164-04 | Spoofing | Basic/post/secret-JWT | high | mitigate | 164-02-01 tests strict shared deadline with real verification and no assertion-skew grace. Verified: `protocol/client_auth.ex:51; client_secret_lifetime_auth_test.exs`. | closed |
| T-164-05 | Elevation of privilege | code/refresh finalizers | high | mitigate | 164-02-02 checks current identity and fresh secret eligibility after the last blocking lock inside rollback authority. Verified: `token_exchange/internal/grant_persistence.ex:303,363; refresh_exchange.ex:177`. | closed |
| T-164-06 | Spoofing | secret-JWT replay store | high | mitigate | Independent claim/algorithm/JTI regressions and successful single-assertion issuance prevent replay weakening or double consumption. Verified: `client_auth/client_secret_jwt.ex:22,163; client_secret_lifetime_jwt_boundary_test.exs`. | closed |
| T-164-07 | Information disclosure | token/introspection/revocation errors | medium | mitigate | 164-02-03 asserts generic public errors and established challenges for real expired credentials. Verified: `protocol/client_auth.ex:288; token/introspection/revocation controller tests`. | closed |
| T-164-08 | Tampering | locked secret replacement | high | mitigate | 164-03-01 derives current provenance/policy/time inside the lock and writes only intended fields. Verified: `storage/ecto/repository/client_store.ex:182,189,195`. | closed |
| T-164-09 | Tampering | v0 promotion | high | mitigate | 164-03-02 clears all historical dates atomically before v1, preserving unrelated current state. Verified: `domain/client.ex:314,332; client_lifetime_promotion_test.exs`. | closed |
| T-164-10 | Repudiation | replacement audit | high | mitigate | 164-03-01/03 bind audit timestamp and success to the same replacement transaction and test audit failure. Verified: `client_lifecycle.ex:70,116; admin/clients.ex:184`. | closed |
| T-164-11 | Elevation of privilege | operator facade | high | mitigate | 164-03-03 preserves existing host authorization and app state, adding no credential-derived renewal authority. Verified: `admin/clients.ex:176; storage/ecto/client_record.ex:302`. | closed |
| T-164-12 | Information disclosure | secret delivery | high | mitigate | 164-03-03 asserts failed write/audit returns no success plaintext and storage stays hashed/protected. Verified: `admin/clients.ex:190,197; client_lifetime_rollback_test.exs`. | closed |
| T-164-13 | Elevation of privilege | poll finalizers | high | mitigate | 164-04-01 rechecks identity/secret at fresh post-request-lock time before consumption. Verified: `grant_persistence.ex:494,517,541`. | closed |
| T-164-14 | Elevation of privilege | CIBA internal authority context | high | mitigate | Authority is overwritten in trusted entry points; adversarial poll context cannot select queued exemption. Verified: `device_code_grant.ex:29; ciba_grant.ex:29,59`. | closed |
| T-164-15 | Denial of service | issuer/target/push secret gating | high | mitigate | 164-04-01/02/03 explicitly prove secret expiry does not invalidate issued tokens, issuer inputs or queued push. Verified: `grant_persistence.ex:145,600; existing_tokens/poll_exchange tests`. | closed |
| T-164-16 | Spoofing | RFC requester finalizer | high | mitigate | 164-04-02 checks current verified requester identity and secret after input-token waits. Verified: `grant_persistence.ex:20,132; grant_wait_test.exs:275`. | closed |
| T-164-17 | Elevation of privilege | client/later-lock races | high | mitigate | 164-05-01/02 require exact blocker proof and strict post-wait secret expiry with no consumption. Verified: `client_secret_lifetime_client_wait_test.exs; client_secret_lifetime_grant_wait_test.exs`. | closed |
| T-164-18 | Tampering | competing rotations | high | mitigate | 164-05-03 checks each committed winner and current provenance/policy/time without stale whole-row replacement. Verified: `client_secret_lifetime_rotation_race_test.exs:19,85,97`. | closed |
| T-164-19 | Repudiation | failed credential/audit transaction | high | mitigate | 164-05-03 reaches both failures and compares full durable credential/lifecycle/audit state. Verified: `client_secret_lifetime_rotation_race_test.exs:212,216,270`. | closed |
| T-164-20 | Denial of service | race harness | medium | mitigate | Unique committed fixtures, bounded receives/tasks, holder release in after and on_exit cleanup prevent hanging locks. Verified: `test/support/client_lifetime_race_helpers.ex; scoped cleanup and policy restoration`. | closed |
| T-164-21 | Information disclosure | finite-secret observability | high | mitigate | 164-06-01 observes actual positive event counts and scans every channel for plaintext/hash/verifier forms. Verified: `dcr_telemetry_redaction_test.exs:284,290,298,305,312,316,320,327,333,456,461; independent 26 tests passed`. | closed |
| T-164-22 | Tampering | documentation/admin consequences | medium | mitigate | 164-06-02/03 tie unlimited/finite/legacy/rotation claims to behavioral tests and vocabulary contracts. Verified: `docs/dynamic-registration.md; docs/upgrading/client-lifetimes.md; vocabulary/guidance tests`. | closed |
| T-164-23 | Repudiation | validation ledger | high | mitigate | 164-06-03 records exact full/race/adapter commands, executed counts and exclusions instead of unsupported completeness claims. Verified: `164-VALIDATION.md exact normal and independent PostgreSQL selections`. | closed |
| T-164-SC | Tampering | npm/pip/cargo installs | high | mitigate | No installs; any new package requires legitimacy audit and blocking human review for ASSUMED/SUS. Verified: `mix.exs and mix.lock unchanged from a1a55de0; no dependency installation`. | closed |

## Accepted Risks Log

No accepted risks. Dedicated secret-JWT encryption-key design remains the existing SEC-01 scope; this phase does not claim to deliver it.

## Security Audit Trail

| Audit Date | Total | Closed | Open | Run By |
|---|---:|---:|---:|---|
| 2026-10-21 | 24 | 23 | 1 | gsd-security-auditor initial independent review |
| 2026-10-21 | 24 | 24 | 0 | gsd-security-auditor re-audit at 5490ac7b |

T-164-21 was a verification gap, not an observed runtime disclosure. Elixir term ordering made missing `nil > 0` event checks pass; actual JWT verifier material was omitted and tuple recursion was absent. Commit 42d0fd0f adds positive-integer/missing-event negative controls, old/new persisted JWT verifier and hash/secret scans, and nested tuple controls. Auditor independently ran the focused redaction selection: 26 tests, 0 failures. Summary/validation correction: 5490ac7b.

## Sign-Off

- [x] All 24 unique threats have mitigate dispositions and verified evidence.
- [x] No accepted-risk override.
- [x] threats_open: 0.
- [x] status: verified.

Approval: independently verified 2026-10-21 at ASVS L1. This report does not replace independent code review, final goal verification or deferred Phase 165/166 work.

## Current-source refresh (2026-10-22)

Independent typed gsd-security-auditor rechecked all 24 planned mitigations at `cecd4bdbfa74a59802d6c63ac483ef4dc393df10`: 24 closed (20 high, 4 medium), 0 open, ASVS L1. Actual current source retains strict shared-secret expiry, independent JWT signature/claim/replay validation, final post-lock identity and eligibility checks, atomic current-row rotation/promotion with required audit, selected-store authority checks, safe plaintext handoff, redacted observability, and continued validity of previously issued tokens. Existing planned race tests inspect exact blockers and durable rollback state. No new dependency or accepted risk was introduced.

At the initial audit before WR-01, runtime, scripts and Mix inputs matched completed candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`; the later guide and existing guidance-assertion correction explicitly postdates that CI proof. This audit checks ASVS L1 mitigation presence, not a new runtime run. Phase 164's three unclassified edge assumptions, Phase 166's three undefined probes, two descriptor-less prohibitions and historical TDD caveats remain explicit limits; no new predicates or approvals were invented.

## Security Audit 2026-10-22

| Metric | Count |
|---|---|
| Threats found | 24 |
| Closed | 24 |
| Open | 0 |

## WR-01 bounded security correction (2026-10-22)

The subsequent runtime guard and public-facade regression are post-candidate changes. Independent bounded security review confirmed T-164-05/16/17/19 remain mitigated: malformed post-lock time returns controlled server_error before validation/signing/persistence/audit; requester identity/secret, issuer app-only and transaction boundaries are unchanged. That review flagged T-164-23 because initial refresh paragraphs still described runtime parity. Those paragraphs are now explicitly historical, and 164-VALIDATION.md records actual RED/GREEN results (27 green tests, 0 failures) and the pending new-candidate final CI gate. Old CI/package proof remains bound only to 0bd4070d. No accepted-risk override is used; evidence-accounting closure requires the bounded follow-up.

Independent bounded follow-up rechecked the revised evidence accounting and closed T-164-23: SECURED 24/24, threats_open 0. The guard-related T-164-05/16/17/19 closures remain retained; new-candidate final CI is still pending.
