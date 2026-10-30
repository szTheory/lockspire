# Plan 178-07 Root Audit and Continuation

**Status:** Private handoff blocker corrected in the preserved draft; Task 01 installed disclosure proof and all of Task 02 remain pending.
**Root RED commit:** `6bc87808`
**Starting checkpoint:** `af3533cd00fc90569d4da434a0d0244c4401e8ee`

## Confirmed private-transport defect

`_read_private_json` read the intentional one-time credential handoff, registered every string as secret material, then called `assert_safe` on that same plaintext payload. It necessarily rejected successful credential transport and misclassified allowed client IDs as secrets. This could appear as the generic outer registration-stage failure, independently of whether registration itself succeeded.

The new named regression exercised the real private reader with a generated credential and ciphertext. It failed at the intended assertion; the complete safe unittest output is in `178-07-ROOT-HANDOFF-RED.json`. GSD's checker returned `RED_EVIDENCE_OK`, `target_test_failed`, format `unittest`. This record uses actual full output rather than the unsupported condensed records retained in Plan 06.

The working runner now unlinks the mode-0600 handoff, registers values only under material-bearing field names, and returns the private payload without rendering or scanning it as diagnostic text. Subsequent child stdout/stderr still must pass the material scan. The regression confirms returned secret equality without printing it, file absence, secret/ciphertext detection in diagnostics, and allowed client-ID visibility.

Focused draft contracts: 4/4. Full Python acceptance with the documented ASDF/ERL_FLAGS environment: 122/122, zero failures. No installed disclosure receipt is implied.

## Actual owned-host countercheck

One fresh locked/delegated installed host used the current preserved disclosure fixture, the existing guarded `mix run --no-start` plus `Application.ensure_all_started(:clean_room_provider)`, and the corrected private reader. Actual seed output reduced to these safe facts:

- Two clients were registered and handed off.
- Nested `RegistrationResult` inspection was redacted.
- The private handoff file was removed.
- Child diagnostics passed the registered-material scan.
- Zero receipts were created; this is diagnosis only, with uncommitted host/harness inputs.

Therefore startup/registration is not established as a remaining blocker. The public API really returns `RegistrationResult`, and its accepted string forms are normalized; do not "fix" these valid contracts based on speculation.

The audit's exact database and `/private/tmp/lockspire178-root-audit-5wvu91j3` host directory were independently removed; the ephemeral session/key configuration file was deleted. Exact port 60633 was bindable afterward. The Python child commands exited normally. No unknown process/resource was touched. This establishes only the new audit's cleanup, not the prior checkpoint's lost process manifest.

## Source-backed capture defects to resolve before another installed retry

These remain in the preserved draft. Correct the coherent harness path before repeating expensive cells; keep actual registration/rotation/maintenance and nonempty channel proof.

| Defect | Source evidence / required direction |
|---|---|
| Intentional secret map mistaken for generic Inspect redaction | `rotate/2` inspects `%{rotated_client: client, one_time_secret: secret}` and expects the literal secret to disappear. Generic maps intentionally retain explicit handoff strings. Inspect nested stored client/domain structs; prove private one-time handoff usability separately. Preserve the public return shape. |
| Invalid apply flag | Capture calls the task with `--apply`, but the task's real flags are `--dry-run`, `--check`, `--limit`, `--after-client-id`; default mode is apply. Use the documented installed CLI. |
| Nonexistent logger synchronization call | Root runtime confirmed `function_exported?(:logger, :sync_handler, 1) == false`. Use an actual supported bounded capture/ack mechanism or establish custom handler synchrony. Do not let an undefined flush helper masquerade as a protocol failure. |
| Logger macros without `require Logger` | The fixture uses `Logger.info` without requiring the macro module. Fix the host fixture's macro use and compile it before runtime proof. |
| Deliberate sentinel leak in the control query | The draft binds a registered sentinel into ordinary `Repo` SQL with debug logging and `sensitive: true`. Direct Ecto query telemetry is not the Lockspire sensitive-repository seam. Do not send actual material into an ordinary global logger control, then expect zero leaks. Use harmless actual channel controls and separately verify the leak detector in memory, with explicit control/operation counts. Never mute the channel to obtain zero leaks. |
| Wrong sentinel set | The runner registers the safe schema prefix and the argument named `old_key`, but `_mix_env` uses that argument as the signing KEK and generates the actual verifier key separately. Register actual configured verifier key material from the environment before any child output, plus the actual secret/ciphertext handoffs. Do not classify permitted schema/client identity as secret material. Qualify encoded/decoded key representations honestly. |
| Unused listener flag | The runner sets `CLEAN_ROOM_HTTP_SERVER=false/true` but never wires that variable into the generated endpoint configuration; the base builder sets `server: true`. Before a real listener is live, the seed succeeds. Later one-off rotation/maintenance/audit VMs can collide with it. Add the ordinary host-owned endpoint flag, false for one-offs and true only for the owned listener, as proven in Plan 03. |
| Ciphertext in command arguments | Maintenance/audit expressions interpolate the expected ciphertext into `mix -e` argv. Carry material through a mode-0600 owned file or equivalent private transport; pass only the path/known identifiers. Do not put stored material in process arguments or manifests. |
| Unbounded process ownership on timeout | `_private_mix` uses `subprocess.run`, which cannot by itself establish descendant cleanup. Reuse the existing bounded owned-process helper. Persist sanitized run/resource/exit facts early enough that a timeout or nested wrapper cannot lose the identity. Never use stale failure artifacts as current evidence. |

Do not broaden this into a new framework/dependency or a changed production logging policy. No schema, protocol, crypto/age, store support or public API expansion is selected. No diagnostic raw tails are needed to fix these concrete source issues.

## TDD, scope and ownership

- Original Task-01 RED `033327e0` remains valid and unchanged.
- Root's new behavioral RED `6bc87808` is mechanically validated; working helper is GREEN in focused/full tests and the actual seed countercheck.
- The runner, host fixture and strict-validator edits remain the current uncommitted implementation draft. No Task-01 installed acceptance, source acceptance commit, Task-02 RED, SUMMARY or phase progress is claimed by this audit.
- Complete Task 01's actual both-pair success evidence and commit before observing Task 02's RED. Keep unknown-child-secret containment and all three historical incidents explicit for security review.
- Continue under the owner's explicit local implementation/test/review/commit authorization. Return a concrete exact-SHA checkpoint before remote writes; merge/publication remain separate.

## Next action

Fresh typed executor continuation should preserve the current draft and root helper fix, resolve the source-backed capture defects as one coherent path, compile/test locally, then run one bounded committed-source locked/delegated cell. Accept no empty capture or self-test substitute. Broaden to the second pair and Task 02 only after that cell's real evidence validates. Use exact stage/fact enums and retry ceilings; no raw diagnostics or historical restamping.
