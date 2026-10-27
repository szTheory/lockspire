# Source test target guard qualification

Status: guarded source disclosure check passed; Plan 07 remains incomplete pending executor reconciliation. This does not clear the two wrong-target incidents or certify development data unchanged.

## Implementation and offline checks

- `aa3524ba135884ce5cbc7ab4a459015881166ec5` adds the dependency-free maintainer runner and 15 offline tests, with the read-only incident assessment.
- It generates its own unique local database name, normalizes inherited connection selectors, forces `MIX_ENV=test` for every child, validates `Lockspire.TestRepo.config()` without starting the application, and requires a prior-absence check, exact Ecto new-creation witness, catalog OID and connected database/server identity before migrations/tests/cleanup. Existing or uncertain storage is never automatically dropped.
- Each child owns a bounded process group. The private mode-0600 manifest in a mode-0700 directory records intent before mutation, process outcomes, exact source SHA and initial checkout cleanliness, raw-output byte counts/digests and nonzero ExUnit counts. Raw stdout/stderr/config credentials never become durable logs or tool output. Catalog/identity commands enforce read-only mode.
- Explicit local test files and a fixed `--ci` mode are supported. The latter runs the unchanged canonical `mix ci` alias in the same guarded environment. No runtime dependency or public library behavior changes.

## First live attempt retained

At clean `aa3524ba`, the runner witnessed fresh creation but refused the connected identity because PostgreSQL serializes its `oid` type as a JSON string. No migration/test command ran; cleanup was refused because ownership was not fully bound. Root read-only inspection confirmed the generated database `lockspire_owned_91f84c721a2f456a94078bdb8cb819f9`, OID `39074428`, and zero public tables. The exact generated name had been absent before creation and the manifest had the exact successful new-storage witness.

Root explicitly cleaned only that run-owned database after confirming its exact name/OID. The catalog-driven DROP was conditional on both, used no force/connection termination, and an independent read-only catalog check confirmed absence. Its manifest retains the original failed identity outcome plus the root cleanup basis. No development/shared database cleanup occurred.

`dfe87c9fe747f6a925472b9396677ac9d4375d7a` casts OID to bigint inside SQL so JSON returns the required numeric type. A read-only SQL check confirmed the numeric JSON type. This is a guard qualification fix, not a claim about the earlier unexplained disclosure failure.

## Successful live source check

Command from repository root:

```sh
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/ci/run_owned_source_tests.py --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs
```

- Tested source: clean `dfe87c9fe747f6a925472b9396677ac9d4375d7a`.
- Result: exit 0; 9 tests, 0 failures, 0 properties. All owned child groups confirmed stopped.
- Exact created database: `lockspire_owned_09bd3a10698c450b9beee80cf9748756`, OID `39074433`; creation witnessed, effective test Repo checked throughout, final cleanup independently absent.
- Test stdout: 1,502 bytes, SHA256 `c09f73e5eeace0b24c4573fdce02b9bd863dd0e2854d5c85c0240edf6e9ec229`; raw content withheld.
- Private manifest copy: `.artifacts/phase178/owned-source-guard/source-pass-manifest.json`, SHA256 `bca4eee39f4489ea623986eeab6806e6fd56c4bd1a47bc3f9d498ac540283e96`. The first failed manifest is retained beside it as `first-refused-manifest.json` with its separate cleanup provenance. No evidence is restamped.

## Broader Python verification

A bare-environment Python acceptance run produced 144 tests / 1 failure: the host OTP runtime probe exited 126. It is preserved as an unsuccessful verification attempt, not interpreted as a product regression. The full command with the selected runtime passed freshly:

```sh
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 -m unittest discover -s test/acceptance -p '*_test.py'
```

Result: 144 tests, 0 failures, exit 0. The 15 new guard tests are included. `git diff --check` also passed. Future source database verification must use this runner. Full `--ci` qualification and installed final proof remain later-plan owners; this focused check does not substitute for them.
