---
quick_id: 260925-x8y
slug: treat-valid-in-progress-uat-status-as-an
status: complete
completed: 2026-09-26
description: Classify structurally valid in-progress Phase 138 UAT as active evidence without promoting pending checks
requirements-completed: [LOOSE-01]
---

# Quick Task 260925-x8y Summary

The maintained evidence classifier now recognizes a structurally valid `status: testing` UAT document as active work with a deferred recheck trigger, while preserving the pending status of its checks.

## Completed Work

- Extended the `:phase138_maintained_uat` fake-Git fixture with a realistic `testing` record: current test 100 awaits a response and tests 100 and 101 remain pending.
- Asserted the testing record produces a stable maintained REC row with `active | defer-with-trigger | direct_current`, never `resolved`.
- Added `testing` to the exact `*-UAT.md` lifecycle status mapping. Existing structural validation and fail-closed handling for missing, duplicate, malformed, and unknown status and missing headings remain in place.
- Kept the live 138-UAT artifact, canonical inventory ledger, and Phase 140 exact-SHA gate untouched. No UAT completion or human pass was asserted.

## Commits

- `e05bbcd7` — `test(260925-x8y): cover testing UAT lifecycle` (RED fixture and assertions)
- `e63235a2` — `fix(260925-x8y): classify testing UAT as active` (GREEN classifier)

## Verification

- RED: the exact focused selector failed because `testing` made the maintained inventory partial and unclassified.
- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `GSD_TOOLS=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-core/bin/gsd-tools.cjs ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 MIX_ENV=test mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_maintained_uat` — passed, 1 test, 0 failures (53 excluded).
- `git diff --check` for the three planned files — passed.

## Self-Check: PASSED

- The classifier, fake-Git fixture/assertions, and focused tagged ExUnit contract are present in the planned files.
- Both task commits are present in the current Git history.
- Verification used the exact planned fixture environment and did not modify live UAT or external acceptance evidence.
