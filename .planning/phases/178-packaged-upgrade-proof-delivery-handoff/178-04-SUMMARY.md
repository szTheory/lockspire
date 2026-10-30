---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "04"
subsystem: testing
tags: [elixir, phoenix, oauth, client-secret-jwt, release-rpc, packaged-upgrade]
requires:
  - phase: 178-02
    provides: shared clean-room builder, installed candidate binding, receipt schema, and group dispatch
provides:
  - Installed mounted-HTTP JWT endpoint evidence for locked and floor dependency pairs
  - Revocation lifecycle, PAR rejection, both FAPI exclusions, and Basic/post controls
  - Actual assembled locked release maintenance RPC evidence with loaded beam identity
affects: [phase-178, packaged-upgrade-proof, verifier-custody]
actuals:
  tokens: 15233
  tasks: 2
  commits: 11
tech-stack:
  added: []
  patterns:
    - Explicit evidence group dispatch independent of dependency matrix width
    - Owned foreground release process with readiness polling and process-group cleanup
    - Case-specific strict receipt fields for lifecycle and FAPI policy evidence
key-files:
  created:
    - scripts/acceptance/clean_room/verifier_endpoints.py
    - test/clean_room/provider_host/verifier_endpoints.exs
    - test/acceptance/client_verifier_endpoints_test.py
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-04-01-red-evidence.json
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-04-02-red-evidence.json
  modified:
    - scripts/acceptance/clean_room/verifier_receipts.py
    - scripts/acceptance/clean_room_verifier_upgrade.py
    - test/clean_room/provider_host/mix.exs
    - lib/lockspire/oban.ex
key-decisions:
  - "Use the configured issuer string as assertion audience on all five endpoints and retain configured, discovery, and used audience URIs in receipts."
  - "Run the assembled release's foreground start command as an owned process group; run bounded RPC commands against that live process."
  - "Keep VPROOF-02 pending until the remaining Phase 178 proof groups complete their assigned coverage."
patterns-established:
  - "Host-owned setup may prepare state through public admin APIs; all authentication outcomes are asserted through mounted HTTP."
  - "Release receipts bind task-local and immutable startup contexts separately and bind the loaded module path and digest to the release."
requirements-completed: []
coverage:
  - id: D1
    description: "Installed JWT endpoint breadth and preserved authentication exclusions across locked and floor dependency pairs"
    verification:
      - kind: integration
        ref: ".artifacts/phase178/endpoints-final-v2/{locked-builtin,floor-builtin}/receipt.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "Running locked release maintenance dry-run and fresh check with task-local versus startup custody contexts"
    verification:
      - kind: integration
        ref: ".artifacts/phase178/release-rpc-final/locked-builtin/receipt.json"
        status: pass
    human_judgment: false
duration: ">=44m27s"
completed: 2026-10-26
status: complete
plan_head_before: ba83e45fb6c2068abdfcbcb2c6579cd0b0a28b7a
plan_head_after: e05464c4a4588c7aaf758d3b54be7074d589a94f
---

# Phase 178 Plan 04: Packaged Upgrade Proof & Delivery Handoff Summary

**Installed HTTP proofs cover all five existing JWT endpoints, lifecycle and policy exclusions across both dependency pairs; one live assembled release completed the documented maintenance RPCs.**

## Performance

- **Duration:** At least 44m27s from the earliest recorded task RED commit through final verification; exact initial dispatch time was not captured.
- **Started:** Earliest recorded RED commit, `2026-10-26T16:21:48-04:00`.
- **Completed:** `2026-10-26T17:06:15-04:00`.
- **Tasks:** 2/2.
- **Files changed before this summary:** 9.
- **Measured plan commits:** 11 from the persisted plan ledger. Actuals use 60,935 characters of realized diff divided by four (15,233 tokens).

## Accomplishments

- Executed nine installed mounted-HTTP cases for each required pair: `locked/builtin` and `floor/builtin`. Each pair passed JWT token, introspection, revocation, device-code and CIBA endpoints; PAR rejection; JWT algorithm, issuer, audience, expiry and replay negatives; and Basic/post controls.
- Used the configured issuer URI as the JWT audience on every endpoint. Both receipts preserve configured issuer, discovery issuer, actual assertion audience, and a distinct rejected-audience URI. Locked and floor receipts also show the revoked access token becomes inactive after revocation and both FAPI security profiles reject the method.
- Assembled and booted the locked host release with the installed candidate included. The actual release process handled RPC `dry_run` and `check`; the receipt distinguishes bare Mix `task_local` custody from the release's `startup` snapshot and binds the loaded maintenance beam path and SHA-256 to the assembled release.
- Kept the endpoint group fixed to explicit group dispatch, separate from pair/store width. The release group accepts only locked/builtin. Strict receipt validation rejects omitted routes, incomplete lifecycle/FAPI fields, and release module identities outside the assembled candidate.
- Preserved `VPROOF-02` as pending for the remaining Phase 178 proof groups.

## Final Installed Evidence

| Scope | Receipt | Runner and candidate source | Artifact digest |
| --- | --- | --- | --- |
| endpoints, locked/builtin, 9 cases | `.artifacts/phase178/endpoints-final-v2/locked-builtin/receipt.json` | `e05464c4a4588c7aaf758d3b54be7074d589a94f` | `1eb9fbc3c9bb3aaf8d2c02e07097f9264115f1db5b3c8ef4bab08004176aa125` |
| endpoints, floor/builtin, 9 cases | `.artifacts/phase178/endpoints-final-v2/floor-builtin/receipt.json` | `e05464c4a4588c7aaf758d3b54be7074d589a94f` | `15760b862ca0931375431c76a1aa74600e69c442fc1b44ad52db9062991ab5af` |
| release-rpc, locked/builtin, 1 case | `.artifacts/phase178/release-rpc-final/locked-builtin/receipt.json` | `e05464c4a4588c7aaf758d3b54be7074d589a94f` | `74fc621d879bae725e04bbb2dd9ac6a45da1b1f24d448eae8c97a3b315f6bf18` |

All three receipts bind candidate source revision `e05464c4a4588c7aaf758d3b54be7074d589a94f`, candidate tree `2af2082226f0be0e47b1f761cb4e98dd526effc0f93800fbacacce1f3a46b243`, and source archive `8be113c5d8cd630ee9fefba3494aac2c236350589a5cd9e7c98600a11a8d1e91`. The compiled host candidate digests are distinct by pair and release: locked endpoint `71dedcf5ce5dc01c971e7fe8f9b0b6ffd954393e83635afc601a7c7e38f0a26d`, floor endpoint `d501178abbb6a45aa5be99befe0f0d87c17d13f11cd8e2104571577aac728b4c`, and locked release host `3ce2d82336b9881355ecb517f3d401804247203d27a3d6fbbc21e4bf5b78bddd`. The release-loaded beam is `lib/lockspire-1.6.1/ebin/Elixir.Lockspire.Admin.ClientVerifierMaintenance.beam`, SHA-256 `4b6fb4e95f96b66032eca2fe735bcf21b6e831adf0005e90c8c879caf21f42d0`.

## Task Commits

All 11 commits measured from the plan ledger:

1. Task 1 RED: `4f7fe46d` — failing endpoint and release dispatch contracts.
2. Task 1 implementation: `8240f041` — installed endpoint breadth.
3. Task 2 RED: `2ae39532` — missing running-release RPC contract.
4. Task 2 implementation: `d9303e82` — assembled release maintenance RPC.
5. Release startup fix: `b0b95f82` — bounded startup output handling.
6. Release diagnostics fix: `78a63753` — safe startup diagnostics.
7. Lifecycle RED: `b80b5c9f` — foreground release start behavior.
8. Owned-process RED: `1ecb970c` — process-group ownership contract.
9. Lifecycle implementation: `8e7c682b` — tracked live foreground release process.
10. Endpoint lifecycle/FAPI RED: `7750565e` — required lifecycle and FAPI receipt fields.
11. Endpoint lifecycle/FAPI implementation: `e05464c4`.

## Verification

- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check tdd-red-evidence .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-04-01-red-evidence.json` — `RED_EVIDENCE_OK`; initial endpoint/dispatch contract failed as designed.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check tdd-red-evidence .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-04-02-red-evidence.json` — `RED_EVIDENCE_OK`; initial release executor contract failed as designed.
- `python3 -m unittest discover -s test/acceptance -p 'client_verifier_endpoints_test.py'` — 8 focused harness tests passed.
- `PYTHONDONTWRITEBYTECODE=1 node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 1800 -- python3 -m unittest discover -s test/acceptance -p '*_test.py'` — all 100 acceptance tests passed.
- Installed endpoints: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair all --store builtin --group endpoints --receipt-dir .artifacts/phase178/endpoints-final-v2` — exit 0, executed count 2; each receipt validates independently for its pair.
- Running release: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group release-rpc --receipt-dir .artifacts/phase178/release-rpc-final` — exit 0, executed count 1; strict receipt validation passed.
- `python3 -m py_compile scripts/acceptance/clean_room/verifier_endpoints.py scripts/acceptance/clean_room/verifier_receipts.py` and `git diff --check` — passed.

## Decisions Made

- Every direct JWT assertion uses the configured issuer as audience. The device route does not derive a different audience from its path.
- The five positive JWT endpoint calls use fresh assertions/JTIs. Negative assertions cover wrong algorithm, audience, issuer, configured expiry, and JTI replay. PAR and both FAPI profiles remain outside the supported method surface.
- Host policy setup uses `Lockspire.Admin.put_security_profile/1` through an isolated host Mix command with the HTTP listener disabled; authentication is still evaluated by actual mounted requests.
- The release's foreground `start` command remains alive by design. Its process is owned via `Popen(start_new_session=True)`, HTTP readiness is polled, and cleanup terminates only that process group.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Made the production release boot without runtime Mix access**
- **Found during:** Task 2.
- **Issue:** The assembled production release crashed in `Lockspire.Oban` because a runtime call to `Mix.env/0` is unavailable in a release.
- **Fix:** Moved test-mode selection to a compile-time branch in `lib/lockspire/oban.ex`; production release code no longer calls Mix at runtime.
- **Verification:** The final assembled release booted, served discovery, and completed both documented RPC operations.
- **Committed in:** `d9303e82`.

**2. [Rule 1 - Bug] Bound actual release identity and lifecycle to a tracked running node**
- **Found during:** Task 2.
- **Issue:** A foreground release `start` command was mistakenly treated as a finite command; it correctly remained attached while the server ran, and a detached `daemon` alternative would have weakened exact process ownership.
- **Fix:** Start the release with an owned foreground process group, poll HTTP readiness, use bounded separate RPC commands, and stop only that owned process group. Run-owned logs use private permissions and raw startup tails are not copied into receipts.
- **Verification:** Final live release RPC receipt records readiness, process identity, RPC results, startup/task-local contexts, and loaded module digest.
- **Committed in:** `8e7c682b`.

**3. [Rule 2 - Missing Critical] Added lifecycle and FAPI evidence to endpoint receipts**
- **Found during:** Task 1 contract audit.
- **Issue:** The first endpoint receipt proved revocation HTTP success but did not prove the token became inactive afterward, and it did not explicitly observe either FAPI exclusion.
- **Fix:** Added post-revocation introspection and actual mounted introspection requests with each FAPI profile selected through the public host policy API. The strict receipt validator requires these case-specific observations.
- **Verification:** Locked and floor endpoint runs passed all nine cases and both receipts validated.
- **Committed in:** `e05464c4`.

**4. [Rule 2 - Missing Critical] Captured child fixture output before validation**
- **Found during:** Task 1 setup.
- **Issue:** A failed initial client-registration command briefly forwarded a generated test client secret to executor output.
- **Fix:** The host fixture now captures command output and applies redaction before any failure text is emitted. The secret was not written to a receipt or retained artifact.
- **Verification:** Final receipt content is schema-allowlisted and contains no client secret, assertion, token, or raw log data.
- **Committed in:** `8240f041`.

**Total deviations:** 4 auto-fixed correctness/security issues. All were necessary to run the planned installed checks; no protocol support or production API was expanded.

## Failed Attempts and Limits

- Earlier endpoint setup attempts failed on an invalid grant request, app crypto not started in a `--no-start` command, the wrong auth method on Basic/post controls, a wrong CIBA path, and a path-derived device audience. These were corrected before the final pair runs. A generated fixture secret was briefly shown in an earlier failed tool output as noted above; it was not persisted. The final evidence uses a source commit, strict redaction, and safe projection only.
- Release attempt at source `78a637538a1df20177a11b428fe95b676a67c0f6` timed out waiting for the foreground `start` command to return. Its startup log showed the owned endpoint was healthy; the failure was the harness treating a server process as a finite command. The run produced no receipt; its temporary release and DB cleanup ran in the attempt's `finally` path. The raw host log was discarded; this summary retains only the bounded redacted failure description and source identity.
- No failed endpoint result or earlier release attempt was restamped as final evidence. Final receipts are immutable files bound to source `e05464c4`; `.artifacts/phase178` is local ignored evidence storage.

## Next Phase Readiness

Plan 178-04 is complete. The remaining Phase 178 proof groups and final handoff remain open; this plan does not complete VPROOF-02 or authorize integration, merge, or publication.

## Self-Check: PASSED

- Summary file exists and all 11 measured plan commits are ancestors of the current HEAD.
- All three final receipt files exist; each passed strict pair-specific receipt validation.
- The 100-test acceptance suite and both task RED evidence records passed their required checks.
- Stub scan found no placeholder/TODO/FIXME patterns in files changed by this plan.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-26*
