# Phase 170 security remediation

## Scope and source

The post-plan security audit reopened five confirmed acceptance-harness/CI gaps.
The five historical plan summaries remain unchanged. Runtime repairs and their
regressions were committed in `ef9ef86030467792346d1b674c58b44d8db30d38`.
The related existing CI credential contract was corrected separately in
`debd3d28` after the broad suite exposed its stale global count. The final
completed-browser failed-receipt regression is `8f775485`; it changes tests only.

No production OAuth/OIDC behavior, package dependency, generated authorization
default, required job name, action pin, workflow trigger, or remote ref changed.
The supplied `.planning/state.json` remains byte-for-byte equal to
`/private/tmp/lockspire-phase170-original-state.json` and was never staged.

## Reproductions and controls

| Confirmed gap | Initial reproduction | Repair | Recurring evidence |
|---|---|---|---|
| T-170-03 / T-170-08: untrusted nested diagnostic keys disclosed raw data; malformed enum containers raised TypeError | Nested sentinel key appeared in `scenario_shape_issues.extra`; list/dict scenario IDs raised TypeError; new focused regression initially failed | Retain only known enum/field names; replace unknown observation keys with a count; type-check all scenario enum lookups; receipt-write diagnostics use a fixed code | Mixed-key and string-only nested hostile key/value cases; real `main` with malformed child JSON proves stdout/stderr/receipts contain no sentinel |
| T-170-14: drop timeout/error skipped raw-root deletion and failed receipt emission | Actual `main` with mocked TimeoutExpired and OSError raised from its original finally block | Guard process stop, drop, and root removal independently; bounded drop errors become false cleanup evidence; a failed cleanup forces nonzero result | Actual-main exception faults plus a completed valid-browser case retain a schema-valid failed receipt and remove the raw root on either drop error |
| T-170-04 / T-170-15: detached process groups and standalone preparation outlived interruption/deadline | Original runner and Node lacked SIGTERM/SIGINT cleanup; direct process topology placed Chrome/host outside outer wrapper group | Finite owned-session subprocess helper for package/provider preparation and Mix commands; runner signal handler unwinds through child/host cleanup; Node owns Chrome cleanup on both signals and a 175s deadline; wrapper forwards interruption and grants <=15s before escalation | Real runner SIGTERM/SIGINT/browser-timeout subprocess tests; real fake Chrome ignoring SIGTERM is killed and profile removed on both signals; wrapper external-signal/deadline child tests; no global pkill |
| T-170-15: wrapper lifecycle database was never disposed | New fake-tool regression initially found no owned-database drop on a failing test exit | EXIT cleanup invokes public `mix ecto.drop --repo Lockspire.TestRepo --force` using only the generated database name; independent finite cleanup budget; raw logs removed regardless; preserve existing failure status, fail otherwise-successful cleanup | Fake-tool success/failure/signals/deadline, drop error/timeout, and simultaneous primary/drop failures; owned child gone, exact generated DB passed to drop, private root absent |
| Floor CI clean-room credentials disagreed with PostgreSQL service | Compatibility job supplied only LOCKSPIRE_TEST_DB_* while clean-room defaults selected postgres/postgres | Explicit floor CLEAN_ROOM_DB_HOST/PORT/USER/PASSWORD match the existing lockspire service; existing host-integration contract checks both jobs | Per-job host-proof contract; existing CI matrix contract now checks fast/compatibility/integration credentials individually |

## Deadlines and ownership

Package/provider preparation commands have a 120-second default deadline.
The owned browser child has 180 seconds; Node also has its own 175-second
interruption deadline. Node waits at most 2.5 seconds for Chrome SIGTERM, then
uses SIGKILL and a one-second exit wait before removing its profile. Python
owns each child session and stops its group on timeout or interruption; host
cleanup allows two seconds before escalation. The runner's drop uses four
seconds plus a 0.5-second termination grace and one-second kill wait. Repeated
signals are ignored only while these bounded cleanup actions finish.

The wrapper allows up to 14 seconds of cooperative child cleanup plus a
one-second kill wait. Its 900-second workload budget is distinct from final
owned-database cleanup, which has a six-second command deadline, one-second
termination grace and one-second kill wait inside a ten-second cleanup budget.
An existing failure status survives cleanup failure; cleanup failure after
otherwise-successful work produces exit 1. Only per-run generated database
names and owned process groups are touched.

## Refreshed real package/browser evidence

Both canonical wrappers were rerun after the last runtime harness change:

```bash
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/phase170/remediation-locked
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/phase170/remediation-floor
```

Locked reported 145 seconds of workload with 43 shared lifecycle checks; floor
reported 144 seconds with 44 checks. These reported timings precede EXIT
cleanup; both commands then exited 0 after the independently bounded database
drop and raw-root removal. Each passed three mounts ×
16 real Chrome/CDP scenarios, for 96 passing browser scenarios total. All six
browser receipts passed independent strict validation and every cleanup flag;
all six receipt files have mode 0600. The wrapper's owned lifecycle drop also
completed before each zero exit. No owned proof process/profile/run root
remained in the post-run filesystem and process checks.

The eight refreshed receipts identify source
`ef9ef86030467792346d1b674c58b44d8db30d38`, `source_dirty: true`, Lockspire
`1.6.1`, archive SHA-256
`a4cf36af08fca6fe11b7d7c39e7cb0224129f507cb009df13879d546198a946f`, and tree
SHA-256 `fcb9ff7246b004b3dfb47d7f480a5bc41eb801e1704bc7a373bf70773e45701e`.
The unchanged package hashes are expected: acceptance tooling and CI lie outside
the published package input. Later edits affect tests and evidence only.

Observed local runtimes: Elixir 1.20.4 / OTP 29, Node 26.10.0, Chrome
155.0.8059.85 with the normal browser sandbox; Phoenix/LiveView exactly
1.8.13/1.2.10 (locked) and 1.8.5/1.1.28 (floor). Exact receipt paths and
per-mount scenario timings are in [170-ACCEPTANCE.md](170-ACCEPTANCE.md).

## Regression and broad verification

- `node --test test/browser/packaged_admin_proof_test.mjs`: 8 passed, including
  uncooperative Chrome SIGTERM/SIGINT cleanup.
- `python3 -m unittest discover -s test/clean_room -p test_admin_journey.py`:
  35 passed in 29.234 seconds, including actual schema-valid failed receipt
  retention after completed-browser drop timeout/error.
- `mix test test/lockspire/host_integration_ci_contract_test.exs test/lockspire/documentation_contract_test.exs test/lockspire/clean_room_admin_integration_test.exs test/lockspire/clean_room_release_source_contract_test.exs`: 20 passed.
- `mix test test/lockspire/ci_test_matrix_contract_test.exs test/lockspire/host_integration_ci_contract_test.exs`: 5 passed after correcting the existing credential contract.
- `mix test test/integration/install_generator_test.exs test/lockspire/ci_test_matrix_contract_test.exs --seed 106565`: 16 passed on a fresh dedicated database.
- `bash scripts/ci/lint_workflows.sh`: exit 0 with pinned actionlint 1.7.12 and
  shellcheck 0.11.0. Job env syntax was checked against the live official
  [GitHub workflow documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idenv).
- `mix format --check-formatted`, `git diff --check`, and byte comparison of
  the supplied planning state: passed.

The first broad run used its own fresh DB and Hex home and ended at
2025/2027: the stale CI credential count and a generated-host default/FAPI
smoke 500 failed. The CI assertion is repaired. The generated smoke passed
its isolated rerun at the same seed. That initial run overlapped wrapper Mix
package builds; shared generated-host compilation interference is a hypothesis,
not an established product defect. The final broad rerun uses another fresh
DB/Hex home, the original seed 106565, and no concurrent Mix wrapper/selector.
It passed all 2,027 checks (2 properties, 2,025 tests), with 6 skipped and
497 excluded, in 177.8 seconds; exit 0. Thus the original smoke failure did not
recur under either isolated or serialized full verification. Source was
`debd3d28`; later `8f775485` adds only the separately verified Python test.

```bash
HEX_HOME=/private/tmp/lockspire-phase170-final-broad-hex.ddjmB3 \
LOCKSPIRE_TEST_DB_NAME=lockspire_phase170_final_65caf16ba7d4 \
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 \
asdf exec mix test.fast --seed 106565
```

The final broad log is `/private/tmp/lockspire-phase170-remediation-final-broad.log`;
the initial failure log is `/private/tmp/lockspire-phase170-remediation-broad.log`.
These test-suite logs are separate from the deleted private provider/browser
logs. Root Mix wrapper/selector runs must remain sequential when exercising
the shared generated-host fixture. No phase-owned test remains failing.

## Limits and deviations

The only additional file beyond the initial remediation ownership list is
`test/lockspire/ci_test_matrix_contract_test.exs`, explicitly authorized after
its phase-caused stale count failed. Its per-job assertions preserve the
original credential-coverage intent and strengthen it for compatibility.

These are local packaged-host, exact dependency-pair, and harness-fault checks.
They do not establish a hosted workflow result, remote required-check settings,
or execution on CI's expected Elixir 1.19.5/OTP 28 and 1.18.4/OTP 27. No remote
workflow, publication, push, or required-check update was dispatched. Historical
plan summaries retain their original audit limits; the refreshed ledgers
supersede the earlier zero-gap claim without rewriting that history.

## Code-review reopening: CR-01 receipt-directory containment

The later independent code review found that lexical `.artifacts/*` matching
allowed traversal and symlink escapes before stale receipt deletion. This
sixth confirmed gap was reopened without rewriting the five earlier findings
or historical summaries. Runtime repair `0d646e36` validates the path before
all mkdir/delete/staging actions: preserve the relative `.artifacts/` CLI,
reject `..`, reject every existing symlink component including `.artifacts`
root/intermediate/final directories, reject non-directory components, and
require a strict canonical descendant of the canonical repo-local artifact
root. Invalid input prints only `receipt directory must be below .artifacts`
and exits 64. Existing directory components are checked under a single-user
invocation boundary; no hostile concurrent same-user replacement guarantee is
claimed.

Test-first real-wrapper calls initially deleted all four external sentinel
receipts for traversal/final-symlink inputs, and created forbidden directories
for root/intermediate symlinks and contained traversal. Five subcases then
passed. Final review identified a Bash command-substitution round-trip bypass:
`.artifacts/link` plus a trailing newline validated as a different nonexistent
path, then became the existing escaping symlink after Bash stripped the newline.
A sixth subcase reproduced deletion again. Final runtime commit `7a845ba3e142f3ff1e717d85ebc017d02becfae2`
rejects CR/LF before canonicalization. All six hostile subcases now preserve
external contents exactly and return the fixed diagnostic/64. The normal
success test creates a previously nonexistent nested receipt directory and
stages all three validated fake-tool receipts successfully.

Final verification after that runtime edit:

- Python full harness suite: 36 passed in 30.031 seconds, including all six
  real-wrapper hostile path subcases and ordinary nested output success.
- Node browser suite: 8 passed in 5.197 seconds.
- Affected host integration/CI matrix/docs contracts: 14 passed.
- Workflow/shell lint, whole-project formatter, remediation-scoped baseline diff check and original
  state byte comparison: passed.
- Final locked wrapper: source `7a845ba3e142f3ff1e717d85ebc017d02becfae2`, 43 lifecycle checks,
  3 mounts × 16 browser scenarios, reported workload 562 seconds; exit 0 after
  owned lifecycle-database/raw-root cleanup.
- Final floor wrapper: same source, 44 lifecycle checks, 3 × 16 scenarios,
  reported workload 156 seconds; exit 0 after cleanup.

The locked workload was slower than the superseded 138-second intermediate
pass; its measured 562 seconds is retained, leaving 338 seconds inside the
900-second workload cap. Both final runs used fresh
`HEX_HOME=/private/tmp/lockspire-phase170-final-containment-hex.NJIhZ1`, fresh
owned databases, normal Chrome sandboxing, and sequential Mix work. Exact
candidate hashes, versions, runtime observations, per-mount timings and receipt
paths are in [170-ACCEPTANCE.md](170-ACCEPTANCE.md). All six final browser
receipts validate with all cleanup flags true. The `0d646e36` receipts at
`.artifacts/phase170/containment-locked` are historical and superseded.

The previous broad 2,027-check pass remains valid evidence for its recorded
source; no fresh broad pass is claimed after this bounded wrapper-only change.
The first final-source floor attempt reached the 900-second workload deadline
after its 44 lifecycle checks, before browser_0. It returned 124 after the bounded
cleanup trap, and its private raw root was removed;
its lifecycle-only output at `.artifacts/phase170/final-containment-floor` is
failed historical evidence, not a successful matrix. The unchanged-source retry
is recorded separately at `.artifacts/phase170/final-containment-floor-retry`.
Safe stage timing metadata is `/private/tmp/phase170-floor-retry-stage-timings.json`;
raw child logs remain deleted. No budget or scenario was weakened for the retry.
Independent CR-01 closure belongs to the reviewer; this report
records repairs and evidence only. No remote workflow, push, publication or
required-check update occurred. REVIEW/SECURITY/VERIFICATION and phase state/
roadmap/requirements were not modified by this repair.
