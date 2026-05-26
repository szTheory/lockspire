---
phase: 91-jwks-uri-rotation-diagnostics-and-remediation-truth
verified: 2026-05-26T13:40:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 9/9 must-haves verified
  gaps_closed:
    - Closed the deferred wording/presentation review by re-reading the shipped doctor and admin output surfaces against the bounded-reactive support contract and confirming they stay aligned without proactive-readiness claims.
  gaps_remaining: []
  regressions: []
---

# Phase 91: `jwks_uri` Rotation Diagnostics And Remediation Truth Verification Report

**Phase Goal:** Make Lockspire's remote-JWKS rotation story diagnosable and supportable without source-diving.
**Verified:** 2026-05-26T13:40:00Z
**Status:** passed
**Re-verification:** Yes - follow-up verification after `ce8f313`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Remote `jwks_uri` incidents normalize to one shared support taxonomy instead of ad hoc protocol-specific reason codes. | ✓ VERIFIED | `Lockspire.Diagnostics.RemoteJwks` still defines the four stable classes, metadata, snapshot, and summary shape in `lib/lockspire/diagnostics/remote_jwks.ex:162-250`; direct classification coverage remains in `test/lockspire/diagnostics/remote_jwks_test.exs`. |
| 2 | The shared model preserves the shipped bounded-reactive rollover truth: cached read, one forced refresh path, last-known-good preservation on refresh failure, and fail-closed current request behavior. | ✓ VERIFIED | The bounded refresh path remains explicit in `lib/lockspire/protocol/client_auth/private_key_jwt.ex:106-171` and `lib/lockspire/protocol/jarm/client_key_resolver.ex:69-111`; bounded-reactive wording still comes from the shared summary/remediation model in `lib/lockspire/diagnostics/remote_jwks.ex:203-246`. |
| 3 | Both `private_key_jwt` and JARM remote-key consumers emit the same operator-facing incident classes with safe supporting metadata. | ✓ VERIFIED | `private_key_jwt` classifies failures and now persists `RemoteJwks.snapshot/1` on failure plus clears it on success in `lib/lockspire/protocol/client_auth/private_key_jwt.ex:34,80-90,366-455`; JARM does the same in `lib/lockspire/protocol/jarm/client_key_resolver.ex:40-63,84-108,192-221`; protocol tests assert the stored diagnostic shape in `test/lockspire/protocol/client_auth_test.exs:352-454` and `test/lockspire/protocol/jarm_test.exs:206-253`. |
| 4 | Lockspire ships a runtime support entrypoint for remote `jwks_uri` incidents that is separate from install-time `mix lockspire.verify`. | ✓ VERIFIED | The dispatcher task now exposes the documented command spelling in `lib/mix/tasks/lockspire.doctor.ex:10-21`, and the concrete task keeps the install/runtime boundary text in `lib/mix/tasks/lockspire.doctor.remote_jwks.ex:42-99`; both paths are covered in `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs:51-118`. |
| 5 | Doctor output and admin UI both consume the shared remote-JWKS diagnostics model rather than inventing parallel vocabularies. | ✓ VERIFIED | Doctor renders `Clients.remote_jwks_summary/1` in `lib/mix/tasks/lockspire.doctor.remote_jwks.ex:58-99`; admin delegates the same summary via `lib/lockspire/admin/clients.ex:95-98` and renders it in `lib/lockspire/web/live/admin/clients_live/show.ex:247-272`; `ce8f313` also broadened applicability so JARM-only remote clients now use the same summary path via `lib/lockspire/diagnostics/remote_jwks.ex:203-219,293-305`, with coverage in `test/lockspire/admin/clients_test.exs:256-322` and `test/lockspire/web/live/admin/clients_live/show_test.exs:217-285`. |
| 6 | Operator-facing output answers what happened, why, and what to do next without exposing secrets or turning the OAuth wire contract into an oracle. | ✓ VERIFIED | The doctor task prints status, summary, next step, ownership, class/stage/subreason, and HTTP status only when present in `lib/mix/tasks/lockspire.doctor.remote_jwks.ex:61-99`; the degraded-path test proves the command reads persisted runtime metadata and still redacts secret-adjacent fields in `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs:73-104`. |
| 7 | The canonical support contract explicitly describes remote `jwks_uri` rollover as bounded reactive support, not proactive rotation readiness. | ✓ VERIFIED | Canonical wording remains in `docs/supported-surface.md`, and release-contract assertions still pin it in `test/lockspire/release_readiness_contract_test.exs:451-456`. |
| 8 | Public docs explain the ownership split and remediation sequence for remote key-distribution incidents without pushing operators straight to inline `jwks`. | ✓ VERIFIED | The host and onboarding docs still point operators to doctor/admin runtime diagnosis and bounded-reactive remediation in `docs/private-key-jwt-host-guide.md:93-127` and `docs/install-and-onboard.md:109`; release-contract coverage remains in `test/lockspire/release_readiness_contract_test.exs:538-603`. |
| 9 | Repo-native tests fail if the documented remote-JWKS support story drifts from the shipped bounded-refresh behavior and support surfaces. | ✓ VERIFIED | The current targeted suite passed with the new operator wiring included: `mix test ...phase62_private_key_jwt_e2e_test.exs` finished `116 tests, 0 failures`, and `mix docs.verify` exited `0`; the exact proof command remains recorded in `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md:7-36`. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/diagnostics/remote_jwks.ex` | Authoritative remote-JWKS incident classification and remediation model | ✓ VERIFIED | Substantive shared taxonomy plus client-summary decoding/snapshot support at `:162-326`; wired into protocol persistence, doctor, and admin surfaces. |
| `lib/lockspire/protocol/client_auth/private_key_jwt.ex` | Normalized `private_key_jwt` incident emission using the shared model | ✓ VERIFIED | Emits shared metadata and now persists/clears durable diagnostics at `:34,80-90,366-455`. |
| `lib/lockspire/protocol/jarm/client_key_resolver.ex` | Normalized JARM incident emission using the shared model | ✓ VERIFIED | Emits shared metadata and now persists/clears durable diagnostics at `:40-63,84-108,192-221`. |
| `test/lockspire/diagnostics/remote_jwks_test.exs` | Unit proof for class/subreason mapping and remediation guidance | ✓ VERIFIED | Still provides direct classifier proof for the four stable classes. |
| `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` | Doctor-style CLI support surface for remote-JWKS incidents | ✓ VERIFIED | Reads repository-backed summary state and renders the shared model at `:58-99`. |
| `lib/mix/tasks/lockspire.doctor.ex` | Dispatcher for the documented doctor entrypoint | ✓ VERIFIED | Routes `mix lockspire.doctor remote-jwks` to the remote-JWKS task at `:10-21`. |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | Admin client-detail remote-JWKS status summary | ✓ VERIFIED | Renders the shared Remote JWKS section for any applicable remote-jwks client at `:247-272,632-636`. |
| `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs` | CLI proof for classification and remediation output | ✓ VERIFIED | Now proves dispatcher wiring and runtime-generated persisted incident output at `:64-118`. |
| `docs/supported-surface.md` | Canonical public support truth for remote `jwks_uri` rollover | ✓ VERIFIED | Canonical bounded-reactive contract remains present and test-locked. |
| `docs/private-key-jwt-host-guide.md` | Host guidance for diagnosing and remediating remote `jwks_uri` incidents | ✓ VERIFIED | Remains the operational detail carrier for diagnosis/remediation. |
| `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md` | Phase-local verification artifact listing exact automated proof commands | ✓ VERIFIED | UAT artifact still matches the proof commands used in this re-verification. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/lockspire/jwks_fetcher.ex` | `lib/lockspire/diagnostics/remote_jwks.ex` | fetch and refresh outcomes normalize into the stable support taxonomy | ✓ WIRED | Protocol consumers still pass structured fetch failures into `RemoteJwks.classify_fetch_error/3`; shared summary/remediation is built from that normalized shape. |
| `lib/lockspire/protocol/client_auth/private_key_jwt.ex` | `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` | runtime failure persists a shared diagnostic snapshot that doctor later renders | ✓ WIRED | `persist_remote_jwks_diagnostic/3` writes `RemoteJwks.snapshot/1` to client metadata in `lib/lockspire/protocol/client_auth/private_key_jwt.ex:432-440`; doctor reads it back through `Clients.remote_jwks_summary/1` in `lib/mix/tasks/lockspire.doctor.remote_jwks.ex:58-70`; this flow is exercised in `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs:73-104`. |
| `lib/lockspire/protocol/jarm/client_key_resolver.ex` | `lib/lockspire/web/live/admin/clients_live/show.ex` | JARM remote-key incidents persist the same snapshot that admin later summarizes | ✓ WIRED | JARM persists/clears the shared snapshot in `lib/lockspire/protocol/jarm/client_key_resolver.ex:192-221`; admin renders the resulting summary via `lib/lockspire/admin/clients.ex:95-98` and `lib/lockspire/web/live/admin/clients_live/show.ex:247-272`; JARM-only applicability is proven in `test/lockspire/admin/clients_test.exs:256-283` and `test/lockspire/web/live/admin/clients_live/show_test.exs:259-285`. |
| `lib/mix/tasks/lockspire.doctor.ex` | `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` | documented command spelling reaches the runtime doctor implementation | ✓ WIRED | Dispatcher route at `lib/mix/tasks/lockspire.doctor.ex:10-12`; integration-style help assertion at `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs:64-71`. |
| `lib/lockspire/admin/clients.ex` | `lib/lockspire/web/live/admin/clients_live/show.ex` | admin detail consumes the same remote-JWKS summary shape | ✓ WIRED | Summary accessor at `lib/lockspire/admin/clients.ex:95-98`; LiveView assign and render at `lib/lockspire/web/live/admin/clients_live/show.ex:64-72,247-272`. |
| `docs/supported-surface.md` | `docs/private-key-jwt-host-guide.md` | canonical support truth stays terse while the host guide carries operational detail | ✓ WIRED | Doc contract remains linked and covered by release-readiness assertions. |
| `docs/supported-surface.md` | `test/lockspire/release_readiness_contract_test.exs` | release-contract proof locks the remote-JWKS support wording in place | ✓ WIRED | Still enforced by release-contract assertions for the bounded-reactive wording. |
| `docs/private-key-jwt-host-guide.md` | `test/integration/phase62_private_key_jwt_e2e_test.exs` | rotation guidance matches the shipped bounded-refresh runtime behavior | ✓ WIRED | Host guidance still matches the existing bounded-refresh and fail-closed integration proof. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` | `summary` | `Clients.get_client/1` -> `Clients.remote_jwks_summary/1` -> `RemoteJwks.summarize_client/1` | Yes; `PrivateKeyJwt.verify/3` now persists a real `remote_jwks_diagnostic` snapshot to repository metadata before the doctor task renders it, proven in `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs:73-104`. | ✓ FLOWING |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | `@remote_jwks_summary` | `AdminClients.remote_jwks_summary(client)` during mount/update | Yes; repository-backed remote clients, including JARM-only clients, now render the same summary path in `test/lockspire/web/live/admin/clients_live/show_test.exs:179-285`. | ✓ FLOWING |
| `lib/lockspire/protocol/client_auth/private_key_jwt.ex` | stored `remote_jwks_diagnostic` metadata | `RemoteJwks.classify_fetch_error/3` / `key_unavailable/2` / `signature_invalid/2` -> `RemoteJwks.snapshot/1` -> `store.update_client/2` | Yes; failure paths persist the normalized snapshot and success paths clear it in `lib/lockspire/protocol/client_auth/private_key_jwt.ex:366-455`, with assertions in `test/lockspire/protocol/client_auth_test.exs:352-454`. | ✓ FLOWING |
| `lib/lockspire/protocol/jarm/client_key_resolver.ex` | stored `remote_jwks_diagnostic` metadata | `RemoteJwks.classify_fetch_error/3` / `key_unavailable/2` -> `RemoteJwks.snapshot/1` -> `store.update_client/2` | Yes; JARM failure paths now persist the same snapshot and clear it on successful resolution in `lib/lockspire/protocol/jarm/client_key_resolver.ex:192-221`, with assertions in `test/lockspire/protocol/jarm_test.exs:206-253`. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 91 targeted proof stays green after `ce8f313` | `mix test test/lockspire/diagnostics/remote_jwks_test.exs test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/jarm_test.exs test/mix/tasks/lockspire_doctor_remote_jwks_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/release_readiness_contract_test.exs test/integration/phase62_private_key_jwt_e2e_test.exs` | `116 tests, 0 failures` | ✓ PASS |
| Docs and doc contracts build cleanly | `mix docs.verify` | Exited `0`; docs regenerated successfully | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `JWKS-01` | `91-01`, `91-02`, `91-03` | A host team using remote `jwks_uri` key material can tell when Lockspire considers the configuration supported, stale, or broken, with concrete remediation guidance. | ✓ SATISFIED | Shared diagnostics, persisted runtime snapshots, dispatcher doctor output, admin summaries, and docs/tests now form one end-to-end path. |
| `JWKS-02` | `91-01`, `91-02`, `91-03` | An operator can distinguish key-rotation failures caused by issuer metadata, JWKS content, cache freshness, or unsupported rollover posture without reading source code. | ✓ SATISFIED | Stable classes plus stage/subreason/fetch-status metadata flow from protocol failure to durable snapshot to doctor/admin/doc surfaces and are locked by targeted tests. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME/placeholder or hollow-output patterns found in the phase artifacts scanned. | - | No blocker or warning surfaced from anti-pattern scan. |

### Human Verification Required

None. The previously deferred wording and presentation checks are now closed:

- `mix lockspire.doctor remote-jwks --help` and the task renderer keep the install-vs-runtime boundary explicit, emit one status/headline/detail/next-step/ownership story, and expose no secret-adjacent data.
- The admin client detail Remote JWKS panel renders the same shared status, summary, next-step, ownership, and incident-class contract without implying proactive rotation readiness or ad hoc operator actions.

### Gaps Summary

No code, documentation, or operator-surface gaps remain against the phase must-haves. `ce8f313` closed the runtime-to-operator wiring concern by persisting remote-JWKS incidents into client metadata, routing the documented doctor command through the dispatcher, and surfacing the same summary model for JARM-only remote clients. The deferred wording review is now closed as well, so the phase no longer carries human-only verification debt.

---

_Verified: 2026-05-26T13:40:00Z_
_Verifier: Codex (gsd-complete-milestone remediation)_
