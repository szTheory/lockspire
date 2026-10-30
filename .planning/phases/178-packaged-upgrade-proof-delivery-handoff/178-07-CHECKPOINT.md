# Phase 178 Plan 07 Execution Checkpoint

Status: blocked during task 178-07-01 installed disclosure success proof. This is a durable execution handoff, not a Plan 07 summary or completion claim. No accepted Plan 07 receipt exists; VPROOF-02 remains pending.

## Repository state

- Project root: `/Users/jon/projects/lockspire`
- Branch: `milestone/v1.48-client-auth-key-isolation`
- Initial Plan 07 HEAD: `5a006080b6ded022d15be5f327ab022f6a2f9b09`
- Current HEAD at checkpoint: `033327e0` (`test(178-07): add failing test for installed disclosure fixture`)
- Only Plan 07 commit: `033327e0`, the task-01 RED test and its preserved evidence.
- Working tree contains uncommitted Plan 07 implementation draft in the three owned paths plus `scripts/acceptance/clean_room/verifier_receipts.py`; no source acceptance commit was made.
- Branch and worktree were not changed. No push, PR, merge, or publication occurred.

## TDD and focused checks

- Task-01 RED was observed before the source fixture existed: the focused test failed on the missing generated-host disclosure fixture. Exact evidence is preserved in `178-07-01-red-evidence.json`; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Focused command after the current draft changes: `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s test/acceptance -p 'client_verifier_disclosure_test.py'` — 3 tests passed.
- The focused tests cover module dispatch/fixture presence, pair-specific success receipt case IDs, and a fixed private startup failure marker that does not interpolate exception data.
- The host fixture compiled and passed the installed-provider source boundary audit in earlier locked-pair attempts. The attempted `Lockspire.Storage.Ecto.Repository` reference was removed in favor of public `Lockspire.Admin.Clients.get_client`.

## Installed attempts and limits

The required installed success matrix has not passed. Earlier bounded locked/delegated runs reached the generated host registration stage, but failed before a valid private registration handoff was accepted. Their raw child stdout, stderr, exception maps, stacks, and tails were never inspected or forwarded. Safe failure artifacts recorded `stage=registration`, `reason=stage_failed`; one artifact recorded database `lockspire_clean_room_verifier_disclosure_f4ede7e9b7ff41fd993becfe4676572f` absent after cleanup. Other specifically recorded database names were `lockspire_clean_room_verifier_disclosure_907352905123417091b7ae` and `lockspire_clean_room_verifier_disclosure_b2f256ebec424e5083819079f3cfd86f`; the first was manually checked for no active connections and dropped, and later exact-prefix absence checks returned no disclosure databases.

A final bounded diagnostic changed the seed invocation to `mix run --no-start` with explicit guarded `Application.ensure_all_started(:clean_room_provider)` and a fixed `host_setup` marker. Its tool output contained only `provider provenance verified` and `provider dependency provenance verified`; the ignored failure artifact remained unchanged (mtime `2026-10-26 20:41:05` local, still names run DB `lockspire_clean_room_verifier_disclosure_f4ede7e9b7ff41fd993becfe4676572f`), so this attempt's exact child exit/stage is not established. The exec wrapper did not retain the nested command's process/session identifier or return code. Do not infer success or a more specific failure from that output. A read-only PostgreSQL query for `lockspire_clean_room_verifier_disclosure_%` databases returned no rows. No current process or listener global-absence claim is made; this run did not durably emit its in-memory PID/port resource manifest.

The task-01 three-attempt auto-fix ceiling has been reached. Stop installed retries here. The registration/startup failure needs a separately routed diagnostic owner to inspect the generated host control flow and add a safe, fixed stage witness. Keep child output contained even when it contains an unregistered generated secret.

## Security incident history

These earlier harness incidents remain part of the final security record even though the affected harness paths were later scrubbed or contained:

- Plan 03 retained a raw process log tail containing JWT/code/PKCE material in an owned artifact, which was later scrubbed.
- Plan 04 exposed a generated fixture secret in failed tool output.
- Plan 06 exposed a generated one-time secret in failed tool output.

No sensitive values are reproduced here. Future containment fixes do not erase these incidents. Host custom instrumentation and PostgreSQL server logging remain host-owned and are not certified or globally changed by this plan.

## Remaining work

- Task 178-07-01 is incomplete. Neither locked nor floor accepted installed registration/rotation/maintenance evidence exists.
- Task 178-07-02 RED has not been started; no failure-path implementation is claimed.
- Required valid HTTP success and exact `invalid_client` 401 probes, the actual crypto/storage forced failures, one-time secret handoff, nested inspection, non-empty owned Logger/query telemetry, audit projection, and both pair-specific receipt validations remain unproven.
- The required source integration owner command and full Python acceptance suite have not been run for Plan 07.
- No Plan 07 SUMMARY, STATE/ROADMAP progress update, requirements completion, or completion metadata commit was created.

## Preserved draft source locations

- Runner stage and private child launch: `scripts/acceptance/clean_room/verifier_disclosure.py:110-118` and `:362-385`.
- Generated-host seed and fixed in-memory channel observers: `test/clean_room/provider_host/lib/clean_room_provider/verifier_disclosure.ex:13-51` and subsequent capture callbacks.
- Success-only receipt case/field validator: `scripts/acceptance/clean_room/verifier_receipts.py:126-130` and its disclosure validation branches.
- Focused contracts: `test/acceptance/client_verifier_disclosure_test.py:19-52`.
- Terminal checkpoint: `178-07-CHECKPOINT.md` (this file); it is currently uncommitted with the source draft.

## Resume guidance

Resume only with a bounded diagnostic that identifies the generated host startup/registration substage using fixed allowlisted enums. Do not expose raw child diagnostics or repeat the full matrix blindly. After task 01's actual installed success proof commits, add and observe task 02 RED before implementing crypto/storage failure proofs. Preserve the three historical incidents in the eventual Plan 07 security summary.

Unproved diagnostic lead from prior plans: public `Lockspire.Clients` credential creation may require a valid immutable verifier startup context. `mix run --no-start` with only Repo startup may therefore be insufficient (Plan 05 mechanism); normal application startup can collide with an HTTP listener when that listener is already owned (Plan 03 mechanism). This lead is not established as the cause of the Plan 07 failure. If a separately routed owner tests it, keep one-off server startup disabled and start only the explicitly owned listener at its assigned port. Do not apply a fix or launch another installed attempt from this checkpoint.
