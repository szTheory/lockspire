# Phase 178 Plan 03 Recovery Checkpoint

**Date:** 2026-10-26
**Status:** Standard blocking attempt-limit checkpoint; automatic-mode diagnostic recovery selected. No task or rollout acceptance is complete.

## Observed State

The executor returned `human-verify`, `Gate: blocking`, at its three-auto-fix-attempt limit. It did not return `blocking-human`. Configured automatic mode therefore permits continuation approval; this is workflow approval, not fabricated human verification or permission to merge/publish.

- Current source: `791e7973520d08041d5911f9e2102ad7707b6e0c`.
- Partial Plan 03 commits: `6dff93df`, `5c4bcb9a`, `77e762bd`, `f07581aa`, `2c9202e8`, `a7a02a79`, `8871aa02`, `791e7973`.
- Focused rollout contracts: four tests passed.
- Accepted predecessor `173059a166e9ade0f5f57c9980b7b2400a98538c` was exported/built with package files compared against that source. This is builder evidence only.
- The required four-cell installed rollout command failed. Latest observed failure was `installed client registration failed` with provider listener `:eaddrinuse` after old/candidate hosts were live and registration booted another host.
- Earlier path-resolution and isolated Mix-home/cache failures were corrected in committed code, but no rollout receipt passed. No receipt exists under `.artifacts/phase178/rollout`.
- The executor reports temporary directories removed and cleanup attempted for child processes/run-owned DBs; no matching rollout/`mix run --no-halt` process remained at its observation. This does not assert fleet or unknown-resource cleanup.
- Failed output exists in the command-session transcript but was not saved at a durable log path. Do not invent a raw log or exit code beyond the reported failed command.
- Task 2 RED contract/evidence was committed in `791e7973` before the stop instruction; its implementation/public-control execution was not started. Preserve that history rather than reconstructing RED.

## Recovery Route

Use a fresh diagnostic context to identify exact listener/configuration ownership and recommend a bounded correction. Then dispatch a fresh executor continuation with the checkpoint state and automatic approval. Do not silently reset the original attempt history or treat new fixes as proof. Require actual installed reruns on committed source, retained failures, cleanup and truthful receipts before closing either task.

## Fresh Diagnostic Result

A separate typed debugger returned `ROOTCAUSE_FOUND` without editing source. It identified the exact extra-VM boot path: rollout starts real old/new listeners, then `_capture_secret` uses app-starting `mix run -e` with the same `PORT`; generated host configuration unconditionally enables its endpoint listener. `_actual_runtime` and the public-control path repeat this collision. Setting `PHX_SERVER=false` cannot override explicit `server: true`.

A bounded temporary Phoenix/Bandit counterfactual probe reproduced the occupied-port failure with listener enabled (exit 1, expression not reached), then reached the same expression with listener disabled (exit 0). It used existing local dependencies, no PostgreSQL, and closed its owned socket/subprocesses. Logs/reproducer remain under `/private/tmp/lockspire-rollout-listener-diag-mcai0w2j/` (`baseline.log`, `runtime-server-true.log`, `runtime-server-false.log`). This is diagnostic evidence, not installed rollout acceptance.

The recommended narrow correction is a rollout-host-owned runtime endpoint listener flag, default disabled for one-off app commands; `_start_server` uses a copied environment explicitly enabling its real listener. This keeps ports/issuers and installed artifacts unchanged and avoids broad shared-helper refactoring. Other concrete findings must be addressed coherently before expensive reruns:

- Fixture uppercase `ROW_FORMAT/HASH_DIGEST/DEADLINE` disagrees with the projection parser's lowercase keys.
- The old-code probe misclassifies the actual `installed token HTTP returned status 401` failure; expected rejection must retain actual status/cause controls rather than accepting arbitrary authentication failures.
- Candidate configuration currently selects dedicated writes before observed old-process drain. Stage legacy writes during overlap, then stop/reconfigure/restart for explicit activation after observed drain.
- If `_start_server` readiness raises before returning process ownership, it must clean its child and log handle.
- Public archive checksum, commit existence and record existence alone do not link public bytes to their claimed source. Complete the already-required retained release-evidence linkage without substituting runner SHA.

Automatic mode approves a fresh executor continuation for these bounded harness corrections and the remaining planned proof. The earlier attempt limit and failed observations stay intact; no human verification, merged source or passing rollout outcome is invented.
