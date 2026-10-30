# Phase 178 Plan 06 Execution Checkpoint

Status: blocked at installed recovery task 178-06-01. This is a durable handoff, not a plan summary or completion claim. Plan 06 remains incomplete; VPROOF-02 remains pending.

## Repository state

- Project root: `/Users/jon/projects/lockspire`
- Branch: `milestone/v1.48-client-auth-key-isolation`
- Checkpoint HEAD: `c145aafb546e32256fe3fc270887de864977ab1f`
- Working tree: clean at checkpoint creation.
- Plan base: `8e9f49f8f2217f89c53d53ec7192cd846098a2e0`
- Commits made during this execution, oldest first:
  - `6359f252` test(178-06): add recovery runner dispatch contract
  - `3859eb67` feat(178-06): add recovery and issuance proof runner
  - `ba3f5803` fix(178-06): keep recovery failure diagnostics allowlisted
  - `b2b51e08` fix(178-06): scope recovery failures to safe stages
  - `1dd71c3d` fix(178-06): enable legacy custody inspection in recovery host
  - `af5a5ae9` fix(178-06): withhold failed child diagnostics
  - `e8de49ec` fix(178-06): exercise expired migrated custody
  - `9fe5c7d7` fix(178-06): report only safe child failure stages
  - `1c44f05d` fix(178-06): start host HTTP client for expiry proof
  - `c145aafb` fix(178-06): classify token probe transport failures
- `1dd71c3d` temporarily changed only generated recovery-host legacy-read configuration. `e8de49ec` removed that override; the current fixture leaves `legacy_read: :reject` and uses authenticated migrated custody.

## Checks completed

- Valid RED for dispatch: the focused recovery acceptance test failed because the issuance module mapping did not point to the shared recovery runner. RED evidence is stored at `178-06-01-red-evidence.json`; GSD check returned `RED_EVIDENCE_OK`.
- Boundary regression RED: the new child-output test observed the prior failed-Mix error include child output. After the fix, the focused acceptance suite passed 3 tests, including random unregistered material emitted to stdout and stderr and included in a nested exception map; no child bytes were included in the parent error or owned output directory.
- Focused command passed: `python3 -m unittest discover -s test/acceptance -p 'client_verifier_recovery_test.py'` — 3 tests, 0 failures.
- Required source integration command passed: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/security/client_secret_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs test/integration/client_secret_jwt_legacy_age_test.exs` — 25 tests, 0 failures.
- Host verifier recovery module compiled using `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' mix run --no-start -e 'Code.compile_file("test/clean_room/provider_host/lib/clean_room_provider/verifier_recovery.ex")'`. Expected warnings reported the generated host Repo and fixture adapter are unavailable in the package checkout context.
- Python syntax checks passed for the touched runner, child runner and acceptance test.

## Installed recovery failures

After changing the fixture from expired legacy Plug ciphertext to a finite expired `LSCV1` migrated envelope, the same probe was attempted three times, stopping at the plan executor's retry ceiling:

`ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/acceptance/clean_room_verifier_upgrade.py --pair locked --store builtin --group recovery --receipt-dir .artifacts/phase178/recovery-probe`

Each run verified package/dependency provenance, applied host overlays, passed the provider boundary audit and compiled the installed host. The child diagnostic boundary returned only `installed verifier host scenario failed at expired_http; child diagnostics withheld`. It never returned the required recovery observations, and no receipt was written.

Confirmed from the last committed fixture control flow:

- Recovery apply completed far enough to advance beyond `:expired_apply`; the earlier apply failure was caused by using an expired legacy fixture that could not be migrated, and the fixture is now a directly sealed authenticated migrated envelope.
- The process stage is marked `:expired_http` before authorization-code seeding. The HTTP helper replaces that marker with a specific fixed stage if `:httpc` reports connect, timeout or transport errors. The observed stage stayed `:expired_http`.
- The runtime config is unchanged between rewrap and authorization probes and continues to reject legacy reads.
- Child stdout/stderr and exception contents were withheld. No raw error tail, credential, client map, ciphertext or key material is retained here.

Unconfirmed inference: the latest failure likely occurred in authorization-code fixture seeding or assertion setup before a transport failure marker could be set. This has not been established; the current stage does not distinguish those substeps. Do not claim the HTTP rejection, deadline-preservation observation, or successful recovery receipt.

The three explicit `expired_http` failures above are the bounded retry history for the corrected fixture. Earlier attempts before that correction included safe `expired_apply` failures. One earlier, pre-boundary-fix failed run exposed a generated one-time secret through a host exception; the incident was reported to the orchestrator and is not repeated or retained in this artifact. The child boundary correction was committed before subsequent installed runs.

## Remaining proof

- Task 178-06-01 is incomplete. Four recovery cells did not pass; the probe did not produce any receipt. The preservation/retry/restore/rotation and expired-migrated installed evidence must remain pending.
- Task 178-06-02 has not been executed or verified. Both delegated issuance pair cells and actual HTTP stale-identity evidence remain pending.
- The required full recovery command, required issuance command and required issuance source integration command remain unrun.
- No Plan 06 SUMMARY, state/tracking update or completion commit was created.

## Owned-resource custody

Each installed probe used a runner-created private `TemporaryDirectory`, a generated isolated recovery database URL, a generated local port and a synchronous child Mix process. The runner's `finally` block invoked `ecto.drop`; the temporary run root is removed on return. The child processes exited. No daemon server was started by this probe. A filesystem check found no receipt under `.artifacts/phase178/recovery-probe`; no proof artifact should be treated as accepted. Database drop is invoked by the runner but was not independently confirmed after each failed run.

## Next diagnostic

Use a separate bounded diagnostic owner to split the `:expired_http` window into fixed allowlisted stages for code seeding and assertion construction, then identify the failing step without surfacing subprocess output. Preserve the finite signed/deadline metadata and `legacy_read: :reject`. Any further installed attempt requires orchestrator routing after this checkpoint; do not continue this retry loop here. Keep the exact source integration command and focused acceptance command green, then pursue all four recovery cells before beginning or claiming issuance cells.

Execution timing: original start recorded as `2026-10-26T21:47:13Z`; this checkpoint was written at `2026-10-26T22:25:50Z` (38m 37s elapsed, including continuations).
