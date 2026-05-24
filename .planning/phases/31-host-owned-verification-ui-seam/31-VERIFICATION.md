---
phase: 31-host-owned-verification-ui-seam
verified: 2026-04-28T11:26:04Z
status: passed
score: 15/15 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 14/15
  gaps_closed:
    - "The generated starter seam re-displays the code and request context before explicit approve or deny"
    - "Generated host seam review-step UX"
    - "Host auth/session wiring around approve and deny"
  gaps_remaining: []
  regressions: []
---

# Phase 31: Host-Owned Verification UI Seam Verification Report

**Phase Goal:** The host application has the integration seams and documentation needed to build a secure user verification UI.
**Verified:** 2026-04-28T11:26:04Z
**Status:** passed
**Re-verification:** Yes - after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Host app can resolve pending device authorizations using the low-entropy user code via provided context functions/seams. | ✓ VERIFIED | `lookup_pending_device_authorization/2` canonicalizes and hashes input before store lookup in `lib/lockspire/protocol/device_verification.ex:28-39`; repo lookup by `user_code_hash` exists in `lib/lockspire/storage/ecto/repository.ex:305-314`. |
| 2 | The integration explicitly requires user action to complete the flow, mitigating remote phishing. | ✓ VERIFIED | Generated GET only prefills in `priv/templates/lockspire.install/verification_controller.ex:8-13`; lookup is POST-only at `:15-50`; approve and deny are separate POST actions in `:53-130`; the generated HEEx has explicit submit buttons in `priv/templates/lockspire.install/verification_html/index.html.heex:17-69`. |
| 3 | Documentation clearly guides the host app on implementing rate-limiting for the verification endpoints. | ✓ VERIFIED | `docs/device-flow-host-guide.md:33-90` defines the concrete `/verify` rate-limit contract; onboarding links to it in `docs/install-and-onboard.md:69-76`; supported-surface docs point to it in `docs/supported-surface.md:20,46`. |
| 4 | Host code can resolve pending device authorization state through Lockspire-owned storage callbacks without mutating browser state. | ✓ VERIFIED | Store behavior is implemented via fetch callbacks in `lib/lockspire/storage/ecto/repository.ex:305-335`; lookup stays read-only until explicit transition in protocol code at `lib/lockspire/protocol/device_verification.ex:28-39`. |
| 5 | Approval and denial can only succeed from a durable pending state guarded by Lockspire transitions. | ✓ VERIFIED | Protocol only transitions from `[:pending]` in `lib/lockspire/protocol/device_verification.ex:42-70`; repository enforces locked expected-state transitions in `lib/lockspire/storage/ecto/repository.ex:327-335`. |
| 6 | Terminal and stale requests are classified by Lockspire storage rules, not by host controllers. | ✓ VERIFIED | Repository transition guard rejects stale state via `transition_device_authorization_record/3`; protocol maps non-pending and expired outcomes in `lib/lockspire/protocol/device_verification.ex:73-85`. |
| 7 | `mix lockspire.install` generates editable host-owned `/verify` files and routes. | ✓ VERIFIED | Template inventory includes the verification controller in `lib/lockspire/generators/templates.ex:42-43`; generated route assertions live in `test/integration/install_generator_test.exs:35-43,89-108`. |
| 8 | A prefilled verification URL renders a code entry form without auto-submit or GET side effects. | ✓ VERIFIED | Template contract test `show remains prefill-only and GET-safe` checks this in `test/lockspire/web/controllers/lockspire_verification_controller_test.exs:13-23`; auto-submit markers are explicitly forbidden at `:59-69`. |
| 9 | The generated starter seam re-displays the code and request context before explicit approve or deny. | ✓ VERIFIED | The previous hollow path is closed: lookup now builds `PendingAuthorization.user_code` from canonicalized input in `lib/lockspire/protocol/device_verification.ex:31-39,88-101`; the review step renders the code, client, scopes, and explicit actions in `priv/templates/lockspire.install/verification_controller.ex:137-147` and `priv/templates/lockspire.install/verification_html/index.html.heex:29-69`; repo-backed proof exists in `test/lockspire/protocol/device_verification_test.exs:171-201`. |
| 10 | Host teams have a concrete rate-limit contract for GET `/verify` and POST `/verify`. | ✓ VERIFIED | The host guide covers both endpoints, trusted IPs, normalized-code buckets, `{normalized_user_code, ip}` failure buckets, `Retry-After`, and redacted logging in `docs/device-flow-host-guide.md:33-173`. |
| 11 | Onboarding points to the generated verification seam and the device-flow host guide during install. | ✓ VERIFIED | Onboarding lists the generated verification files and links to the host guide in `docs/install-and-onboard.md:17-27,44,69-76`; generator output also points to the guide in `lib/lockspire/generators/install.ex:102`. |
| 12 | Supported-surface docs describe the shipped Phase 31 slice without over-claiming Phase 32 polling/token support. | ✓ VERIFIED | `docs/supported-surface.md:20-23` scopes support to the host-owned seam and `:27-33,62-70` keeps polling and token issuance out of scope. |
| 13 | Host code can look up a pending device authorization from a user-entered code without mutating state. | ✓ VERIFIED | Lookup is isolated in `lib/lockspire/protocol/device_verification.ex:28-39`; approval and denial are separate later mutations in `:42-70`. |
| 14 | Approval and denial run against an opaque verification handle and persist signed-in subject binding. | ✓ VERIFIED | Protocol mutations use `verification_handle` and require `subject_id` in `lib/lockspire/protocol/device_verification.ex:42-70,114-117`; the generated controller derives that subject from host claims in `priv/templates/lockspire.install/verification_controller.ex:166-189`. |
| 15 | Device authorization responses include `verification_uri_complete` for prefill-only host flows. | ✓ VERIFIED | Controller JSON assertions confirm the field in `test/lockspire/web/controllers/device_authorization_controller_test.exs:59-67`; protocol tests cover the response contract separately. |

**Score:** 15/15 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/storage/ecto/device_authorization_record.ex` | Durable verification lifecycle fields and opaque handle storage | ✓ VERIFIED | Schema and domain mapping are substantive and include lifecycle fields plus `verification_handle`. |
| `priv/repo/migrations/20260428090000_extend_lockspire_device_authorizations_verification_state.exs` | Lifecycle-state schema extension | ✓ VERIFIED | Prior migration artifact remains present and was not regressed. |
| `lib/lockspire/storage/ecto/repository.ex` | Race-safe lookup and transition callbacks | ✓ VERIFIED | Fetch and transition callbacks remain implemented and wired. |
| `priv/templates/lockspire.install/verification_controller.ex` | Host-owned verification browser seam | ✓ VERIFIED | Substantive controller with prefill-only GET, POST lookup, and explicit approve/deny mutations. |
| `priv/templates/lockspire.install/router.ex` | Generated host-owned `/verify` routes | ✓ VERIFIED | Route comments and the four `/verify` routes remain present. |
| `test/integration/install_generator_test.exs` | Generator proof for verification seam files | ✓ VERIFIED | Install tests assert generation, idempotence, and overwrite refusal. |
| `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` | Controller-focused seam contract proof | ✓ VERIFIED | Although the plan pattern matcher expects literal `show/2`, the file substantively verifies GET safety and lack of auto-submit markers. |
| `docs/device-flow-host-guide.md` | Dedicated host guide for verification security contract | ✓ VERIFIED | Concrete anti-phishing and rate-limit guidance exists and is contract-tested. |
| `docs/install-and-onboard.md` | Install next steps for verification seam | ✓ VERIFIED | Onboarding points directly to the host-owned `/verify` seam and guide. |
| `docs/supported-surface.md` | Truthful support claim for Phase 31 slice | ✓ VERIFIED | Supported-surface wording remains narrow and accurate. |
| `test/lockspire/release_readiness_contract_test.exs` | Docs-contract coverage for host guide wiring | ✓ VERIFIED | Assertions pin onboarding and supported-surface guidance to the new host guide. |
| `lib/lockspire/protocol/device_verification.ex` | Two-step verification lookup and approve/deny API | ✓ VERIFIED | The prior hollow display-code flow is fixed by rebuilding the review code from the canonicalized lookup input. |
| `lib/lockspire/protocol/device_authorization.ex` | Success payload with `verification_uri_complete` | ✓ VERIFIED | Response field remains implemented and covered by tests. |
| `test/lockspire/protocol/device_verification_test.exs` | Protocol proof for typed lookup and actor-bound mutations | ✓ VERIFIED | Includes the new repo-backed proof for displayable code on the review step. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/lockspire/storage/ecto/repository.ex` | `lib/lockspire/storage/ecto/device_authorization_record.ex` | FOR UPDATE transition and domain mapping | ✓ WIRED | Repository fetches records and maps them through `DeviceAuthorizationRecord.to_domain/1`. |
| `lib/lockspire/storage/device_authorization_store.ex` | `lib/lockspire/storage/ecto/repository.ex` | behaviour callback implementation | ✓ WIRED | Repository still implements the device-authorization store callbacks. |
| `lib/lockspire/generators/templates.ex` | `priv/templates/lockspire.install/verification_controller.ex` | template inventory entry | ✓ WIRED | Verification controller template remains registered for install generation. |
| `priv/templates/lockspire.install/verification_controller.ex` | `lib/lockspire/protocol/device_verification.ex` | lookup and approve/deny protocol calls | ✓ WIRED | Controller calls lookup, approve, and deny protocol functions directly at `:15-19,56-60,90-94`. |
| `priv/templates/lockspire.install/verification_controller.ex` | `lib/lockspire/host/account_resolver.ex` | signed-in actor binding before approval | ✓ WIRED | `Lockspire.account_resolver!()` and claims resolution are used at `priv/templates/lockspire.install/verification_controller.ex:166-199`; the automated key-link checker false-negatives this because it only pattern-matches one side. |
| `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` | `priv/templates/lockspire.install/verification_controller.ex` | controller-first seam contract assertions | ✓ WIRED | Test file reads the generated controller template and asserts the seam contract directly. |
| `docs/install-and-onboard.md` | `docs/device-flow-host-guide.md` | host setup guidance | ✓ WIRED | Direct guide link at `docs/install-and-onboard.md:76`. |
| `docs/supported-surface.md` | `docs/device-flow-host-guide.md` | supported-slice explanation | ✓ WIRED | Direct guide link at `docs/supported-surface.md:20,46`. |
| `test/lockspire/release_readiness_contract_test.exs` | `docs/install-and-onboard.md` | release-readiness contract assertions | ✓ WIRED | Assertions lock onboarding text and link presence at `test/lockspire/release_readiness_contract_test.exs:264-274,304-319`. |
| `lib/lockspire/protocol/device_verification.ex` | `lib/lockspire/storage/device_authorization_store.ex` | lookup and transition callbacks | ✓ WIRED | Protocol depends on store callbacks through `device_authorization_store(opts)` in `lib/lockspire/protocol/device_verification.ex:34-39,45-69,123-124`. |
| `lib/lockspire/protocol/device_authorization.ex` | `test/lockspire/web/controllers/device_authorization_controller_test.exs` | `verification_uri_complete` JSON field | ✓ WIRED | HTTP response contract remains asserted in `test/lockspire/web/controllers/device_authorization_controller_test.exs:59-67`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/lockspire/protocol/device_verification.ex` | `PendingAuthorization.user_code` | Canonicalized submitted code, validated by successful repo/store lookup | Yes | ✓ FLOWING |
| `priv/templates/lockspire.install/verification_controller.ex` | `pending.user_code`, `pending.client_name`, `pending.scopes` | `DeviceVerification.lookup_pending_device_authorization/2` review payload | Yes | ✓ FLOWING |
| `priv/templates/lockspire.install/verification_html/index.html.heex` | Rendered review-step code and request context | Assigns from `render_review/3` | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/device_authorization.ex` | `verification_uri_complete` | `verification_uri` plus issued `user_code` query param | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 31 targeted proof suite remains green after the fix | `MIX_ENV=test mix test test/lockspire/protocol/device_verification_test.exs test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/web/controllers/lockspire_verification_controller_test.exs test/integration/install_generator_test.exs test/lockspire/release_readiness_contract_test.exs test/lockspire/protocol/device_authorization_test.exs test/lockspire/web/controllers/device_authorization_controller_test.exs` | `43 tests, 0 failures` | ✓ PASS |
| Repo-backed lookup returns a non-empty review-step code | `MIX_ENV=test mix test test/lockspire/protocol/device_verification_test.exs:171` | Repo-backed test asserts `pending.user_code == "WDJBMJHT"` and passes | ✓ PASS |
| Generated host seam runtime flow is covered in CI | `MIX_ENV=test mix test.integration` | `102 tests, 0 failures`; includes `Phase31GeneratedHostVerificationE2ETest` covering GET prefill-only, POST review rendering, signed-out login redirect, and signed-in approve/deny binding | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `DEV-04` | `31-01`, `31-02`, `31-04` | Expose `GET /verify` and `POST /verify` integration seams for the host app to render consent/verification UI. | ✓ SATISFIED | Generated routes, host-owned controller/template, protocol lookup/mutation seams, opaque-handle transitions, and repo-backed display-code proof are present. |
| `DEV-05` | `31-02` | Prevent auto-submit on `verification_uri_complete` to mitigate remote phishing. | ✓ SATISFIED | GET stays prefill-only in `priv/templates/lockspire.install/verification_controller.ex:8-13`; template tests explicitly reject auto-submit markers in `test/lockspire/web/controllers/lockspire_verification_controller_test.exs:59-69`. |
| `DEV-06` | `31-03` | Provide documentation on rate-limiting the `/verify` endpoint for the host app (no built-in rate limiting). | ✓ SATISFIED | Host guide, onboarding links, supported-surface links, and release-readiness contract tests all verify the documentation contract. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` | 17 | Plan artifact matcher expects literal `show/2`, while the contract test checks `def show` textually | ℹ️ Info | Causes a false-negative in `gsd-sdk query verify.artifacts`, but the test is substantive and the seam is actually verified. |
| `mix docs.verify` run | n/a | Repo-wide docs warnings outside the Phase 31 seam still fail `--warnings-as-errors` | ⚠️ Warning | Does not block the verified `/verify` seam or its documentation contract, but the broader docs gate is not fully green. |

### Gaps Summary

The prior repo-backed review-step gap is closed. The Phase 31 must-haves are now satisfied in code and runtime proof: the verification seam is generated, the anti-phishing GET/POST split is enforced, the review step receives a non-empty code plus request context, host auth/session redirects and signed-in mutations are exercised through a Phoenix browser-pipeline fixture, and the documentation contract is concrete and wired into onboarding. No human-only verification remains for this phase inside the Lockspire repo.

---

_Verified: 2026-04-28T11:26:04Z_
_Verifier: Claude (gsd-verifier)_
