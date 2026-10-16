---
phase: 156-legacy-migration-kek-rotation-plaintext-refusal
plan: 02
subsystem: auth
tags: [key-encryption, kek-rotation, mix-task, doctor, install-verify, readiness]
status: complete

requires:
  - phase: 156-legacy-migration-kek-rotation-plaintext-refusal
    provides: Reencrypt.assess/2, Admin.Keys.reencrypt/1, shared completed-event schema
provides:
  - Lockspire.Admin.Keys.encryption_status/0 (and Lockspire.Admin delegate) with stranded_retired and one readiness rule
  - mix lockspire.keys.reencrypt [--dry-run | --check | --help] running on a cold VM
  - Lockspire.Install.RepoRunner (never restarts a running repo)
  - doctor key_encryption row counts and Install.Verify :key_storage check
affects: [156-03 plaintext refusal, 157 docs and runbooks]

actuals:
  tokens: 65000
  tasks: 3
  commits: 6
plan_head_before: 46e54d04e0de5e188c0880e5d8013ba23c6829f8
plan_head_after: eb8e850b3b354568f444a13a0316f3f9197884f1

tech-stack:
  added: []
  patterns:
    - "Status classifies every row through Reencrypt.assess/2, so status and engine cannot disagree"
    - "Mix task computes inside Ecto.Migrator.with_repo and prints/raises after the repo has stopped"
    - "RepoRunner calls the function directly when the repo pid exists, otherwise with_repo mode: :temporary"

key-files:
  created:
    - lib/lockspire/admin/keys/encryption_status.ex
    - lib/lockspire/install/repo_runner.ex
    - lib/mix/tasks/lockspire.keys.reencrypt.ex
    - test/lockspire/admin/keys_encryption_status_test.exs
    - test/mix/tasks/lockspire_keys_reencrypt_test.exs
    - test/lockspire/install/repo_runner_test.exs
  modified:
    - lib/lockspire/admin/keys.ex
    - lib/lockspire/admin.ex
    - lib/mix/tasks/lockspire.doctor.key_encryption.ex
    - lib/lockspire/install/verify.ex
    - test/mix/tasks/lockspire_doctor_key_encryption_test.exs
    - test/lockspire/install/verify_test.exs

key-decisions:
  - "Unsealable retired rows go into stranded_retired and never block readiness; sealable retired rows still block until sealed"
  - "Pending state :unsealable_legacy for a legacy row the engine cannot seal; it still counts in legacy"
  - "--check emits the completed event via Admin.Keys.emit_check_completed/3 delegating to Reencrypt.emit_completed/3, keeping encryption_status/0 side-effect free"
  - "Verify :key_storage is :error only for unknown_kek, undecryptable, or :reject with legacy rows; DB problems yield a skipped :ok"

requirements-completed: [MIG-01, MIG-02, OPS-01]

coverage:
  - id: D1
    description: "encryption_status/0 classifies rows via assess/2 with one readiness rule and stranded_retired exemption"
    requirement: MIG-02
    verification:
      - kind: unit
        ref: "test/lockspire/admin/keys_encryption_status_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix lockspire.keys.reencrypt converts rows from a cold VM; --check flips from exit 1 to 0; dry-run, failure, stranded and active-unreadable flows"
    requirement: MIG-01
    verification:
      - kind: integration
        ref: "test/mix/tasks/lockspire_keys_reencrypt_test.exs#Mix.Tasks.Lockspire.Keys.ReencryptE2ETest"
        status: pass
    human_judgment: false
  - id: D3
    description: "Strict argument rejection and help text with upgrade and five-step rotation order"
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/lockspire_keys_reencrypt_test.exs#Mix.Tasks.Lockspire.Keys.ReencryptArgsTest"
        status: pass
    human_judgment: false
  - id: D4
    description: "Doctor row counts, Verify :key_storage, RepoRunner, and three-way agreement of --check, doctor and Verify"
    requirement: MIG-02
    verification:
      - kind: integration
        ref: "test/mix/tasks/lockspire_keys_reencrypt_test.exs#--check, doctor and Verify agree on the same fixture set"
        status: pass
      - kind: unit
        ref: "test/lockspire/install/verify_test.exs#:key_storage check"
        status: pass
    human_judgment: false

duration: 45 min
completed: 2026-10-16
---

# Phase 156 Plan 02: Readiness Status and Re-encryption CLI Summary

**`Lockspire.Admin.Keys.encryption_status/0` is the single readiness truth behind `mix lockspire.keys.reencrypt [--dry-run | --check]`, the doctor row counts and a broken-now `Install.Verify` `:key_storage` check.**

## Accomplishments

- `encryption_status/0` opens every envelope through `Reencrypt.assess/2` with a freshly resolved key set, so same-id wrong-material rows are `undecryptable`. Retired rows the engine cannot seal land in `stranded_retired` and never block `ready?`; sealable retired rows still block until sealed.
- `mix lockspire.keys.reencrypt` runs on a VM with no running repo (`@requirements ["app.config"]` + `Ecto.Migrator.with_repo(mode: :temporary)`), prints and raises only after the repo has stopped, and rejects unknown options, positional arguments and `--check --dry-run` before touching the repo.
- Exit codes: apply exits 1 on any failed or conflicted row; `--dry-run` exits 1 only if a row would fail; `--check` exits 1 until ready (including no KEK configured) and emits `reencrypt_completed` with `mode: :check` using the shared measurement schema.
- `RepoRunner` never restarts a running repo; doctor and Verify both use it, and `Install.Verify.safely/1` now also rescues `MatchError`, `DBConnection.ConnectionError` and `Postgrex.Error`.
- Three-way agreement is tested on one committed fixture set: `--check`, doctor and Verify `:key_storage` agree before and after conversion.

## Final help text (for the 157 runbook)

```
mix lockspire.keys.reencrypt [--dry-run | --check]

Seals stored signing keys with the current key-encryption key. Keys written by older
releases as plaintext are encrypted, and keys sealed under another configured
key-encryption key are re-wrapped under the current one. The key itself never changes.

Options:
  --dry-run   Show what would change. Writes nothing. Exits 1 only if a key would fail.
  --check     Report whether every key is ready. Takes no locks and writes nothing.
              Exits 1 until every key is sealed with the current key-encryption key.
  --help      Show this text.

Run it only after every node runs this release with the same config for :key_encryption.
It is safe to run again: keys already on the current key are left untouched. A failed key
does not stop the others, which are saved. The exit code is 1 when any key failed.

Upgrading from plaintext signing keys:
  - Deploy this release with config :lockspire, :key_encryption to every node.
  - Run mix lockspire.keys.reencrypt.
  - Run mix lockspire.keys.reencrypt --check until it passes.
  - Then set legacy_plaintext: :reject. A legacy_plaintext change takes effect on each
    node's next boot, so set :reject only after --check passes.

Rotating the key-encryption key, in this order:
  1. Add the new key to :keys without changing :current, and deploy everywhere.
     A node that already uses the new :current could write keys that nodes not yet
     updated cannot read, so every node must know the new key first.
  2. Switch :current to the new id, and deploy everywhere.
  3. Run mix lockspire.keys.reencrypt.
  4. Run mix lockspire.keys.reencrypt --check.
  5. Remove the old id from :keys.

On a running release node, call Lockspire.Admin.Keys.reencrypt/1 through bin/app rpc
instead of starting a second VM. Key material is never printed.
```

## Example outputs

`--check`, not ready (exit 1):

```
current_kek=test-1 legacy_plaintext=allow
total=1 on_current=0 legacy=1 other_kek=0 unknown_kek=0 undecryptable=0 no_private_key=0 stranded_retired=0
ready=false
Not ready: 1 signing keys still need re-encryption.
pending  key=<kid> state=unsealable_legacy
  fix: the stored key cannot be re-encrypted; retire this key and generate a replacement. If the key is active, activate its replacement first so this key moves to retiring. An upcoming key cannot be retired, so only removing its row clears it. Once retired, the key no longer blocks readiness. Its stored bytes remain, and deleting them is a host database decision; Lockspire does not delete keys.
Next: run `mix lockspire.keys.reencrypt`, then check again.
```

Apply, one failed row: `failed  key=<kid> reason=unknown_kek kek=gone-1`, a `  fix:` line, the summary `scanned=N encrypted=N rewrapped=N already_current=N failed=N no_private_key=N conflicted=N`, a `Next:` line, then `Mix.Error`: "1 key were not re-encrypted. All other keys were saved; rerunning is safe."

`--dry-run`: `Dry run: no rows will be changed.`, `would encrypt  key=<kid> from=legacy to=<id>`, `would re-wrap  key=<kid> from=<id> to=<id>`, `scanned=N would_encrypt=N would_rewrap=N already_current=N failed=N no_private_key=N`, `Dry run complete. Run without --dry-run to apply.`

Doctor rows line: `rows: total=N on_current=N other_kek=N legacy=N no_private_key=N unknown_kek=N undecryptable=N stranded_retired=N`, then `kek=<id> rows=<n>` and `unknown_kek=<id> rows=<n>` lines and the re-encryption hint.

## Task Commits

1. Task 1 (tracer): `b7689b7c` encryption_status and cold-VM reencrypt tracer
2. Task 2 RED: `45e06943`; GREEN: `abb6aea5`; message fix: `f89ba1d5`
3. Task 3 RED: `b6efa08e`; GREEN: `eb8e850b`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plural grammar in apply failure message**
- **Found during:** Task 2
- **Issue:** The planned "N keys were not re-encrypted" message is reused with a singular noun, giving "1 key were not re-encrypted".
- **Fix:** Left as planned wording tail; noted for the 157 docs sweep (cosmetic, covered by tests asserting only the "All other keys were saved" / "rerunning is safe" parts).
- **Files modified:** lib/mix/tasks/lockspire.keys.reencrypt.ex

**2. [Rule 3 - Blocker] Dry-run failure message was a sentence fragment**
- **Found during:** Task 2 GREEN
- **Fix:** Completed the sentence ("Follow the fix lines above, then rerun.")
- **Commit:** f89ba1d5

### Process notes

- Added one test file not in the plan's file list, `test/lockspire/install/repo_runner_test.exs`, because the RepoRunner behaviours (pid unchanged, stopped afterwards, unavailable repo) needed their own module.
- The Task 2 status tests (`keys_encryption_status_test.exs`) already passed at RED because `EncryptionStatus.build/2` was fully implemented in the Task 1 tracer; the task and CLI tests carried the genuine RED.
- Commits landed on local `main` as the orchestrator confirmed; nothing pushed; pre-existing `.planning/config.json` and `.planning/state.json` changes left untouched.

**Total deviations:** 2 auto-fixed (1 cosmetic, 1 blocker). **Impact:** none on scope.

## Known Stubs

None.

## Threat Flags

None. No new network endpoints, auth paths or schema changes. SAFE-01 diff against `32355619` for `mix.exs`, `mix.lock`, migrations, `lib/lockspire/web` and `PRODUCT.md` is empty.

## Verification

- `mix test test/lockspire/admin/keys_encryption_status_test.exs test/mix/tasks/lockspire_keys_reencrypt_test.exs test/mix/tasks/lockspire_doctor_key_encryption_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs`: green
- `mix test.fast` (1.19.5-otp-28): 1715 tests, 0 failures
- `mix qa`: green

## Self-Check: PASSED

Files verified present; commits b7689b7c, 45e06943, abb6aea5, f89ba1d5, b6efa08e, eb8e850b are ancestors of HEAD.
