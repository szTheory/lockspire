---
phase: 168-host-owned-liveview-authorization
source_revision: 93b555804a1a11ba08116cd44f8dc020abbd4ea9
status: independent-audit-recheck-pending
---

# Phase 168 Security Audit Remediation Evidence

This addendum records targeted evidence added after an independent audit identified two gaps in the original Plan 03 coverage. It is evidence for the auditor's recheck, not a final audit verdict. The changes are test-only; production code and dependencies are unchanged.

## T-168-07 — Cached-Response Rejoin Record Preservation

The threat register requires a refused cached join to return no protected view/output or action and leave a domain record unchanged. The earlier denial tests asserted redirects, host-hook observations and protected-callback sentinels but did not snapshot a domain record around the rejoin itself.

Commit `93b555804a1a11ba08116cd44f8dc020abbd4ea9` adds a representative client-record snapshot and read-after-denial comparison to:

- The cached probe denial after the original response and first connected view succeed.
- The default-mount cached-response policy-withdrawal join after stopping the previously authorized process.
- Each invalid session, removed binding, deleted identity and withdrawn-policy denial in the default, nested and root mount matrix.

Each case retains the actual sign-in redirect and current connected-denial observation. The applicable rejoin paths retain original response/session checks, distinct-process evidence, no additional HTTP/session callback evidence and protected-callback sentinels. The record comparison covers the seeded client record; it is not a claim that every persistence side effect is impossible.

## T-168-14 — Withdrawn-Policy Policy and Rotation Patches

The original Plan 03 evidence exercised allowed edit, authorization-policy and secret-rotation patches but only withdrew authority for the edit and query-filter patches. The earlier summary wording therefore overstated withdrawn-policy patch coverage for policy and rotation.

The same commit starts a fresh, currently authorized client view for each `Edit authorization request rules` and `Rotate client secret` link, withdraws staff permission, clicks the actual LiveView patch link, and asserts:

- The exact host sign-in redirect and a denied `handle_params` observation.
- No additional allowed params observation after withdrawal.
- The stored client record remains equal to its pre-patch snapshot.

Existing allowed controls for edit, policy, rotation and query filtering remain in the test. This proves the patch boundary and representative record preservation; event authorization and other host business actions remain host responsibilities.

## CI Selector Evidence

The workflow at `.github/workflows/ci.yml` invokes `bash scripts/ci/run_test_matrix.sh --fast ...`. The script's `--fast` branch calls `MIX_ENV=test mix do test.setup + test`. That CI command is distinct from the local `mix test.fast` verification. The added tests are untagged and remain selected by the script's `mix test` invocation. No duplicate CI job was added and no remote CI run is claimed.

## Verification

All commands used Elixir `1.20.4-otp-29`, Erlang/OTP `29.1.1`, isolated database `lockspire_phase168_20261022`, and `HEX_HOME=/tmp/lockspire-phase168-hex` where Mix invokes Hex.

- Targeted test selection for cached probe denial, default cached rejoin, all-mount rejoin matrix, and native client patches: **6 passed**.
- Focused Phase 168 route/LiveView union: **44 passed**.
- `mix format --check-formatted`: passed.
- `mix test.fast`: **1,976 passed** (2 properties and 1,974 tests), 6 skipped, 497 excluded.
- `git diff --check` and phase-base `git diff --check 66fa5c7aa5ee873ecfb2746f52190d03fda97f5f`: passed after phase-document whitespace cleanup.

Locked Phoenix/LiveView versions remain `1.8.13` / `1.2.10`; this evidence does not establish browser transport, package adoption, or exact supported-floor behavior.

## Auditor Recheck

Both findings are ready for independent re-evaluation against the tests and this evidence. Their final status remains with the security auditor.
