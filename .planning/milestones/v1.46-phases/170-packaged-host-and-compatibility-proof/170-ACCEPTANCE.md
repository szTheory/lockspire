# Phase 170 — Final Acceptance Evidence

## Current evidence after receipt-directory review repair (2026-10-24)

CR-01 reopened the wrapper's lexical receipt-path guard: traversal and symlink
components could redirect stale-file deletion outside `.artifacts`. The repair
in `0d646e36`, refined in `7a845ba3e142f3ff1e717d85ebc017d02becfae2`, validates a strict canonical
repo-local artifact descendant before any mkdir/delete/staging, rejects every
existing symlink component and parent traversal, and rejects line breaks that
could change the path through Bash command substitution. Invalid paths return
exit 64 and one fixed diagnostic; external sentinel files remain unchanged.
The independent reviewer owns closure of CR-01; these are repair/runtime results.

Both canonical wrappers were refreshed after the final runtime edit. Every
current receipt identifies source `7a845ba3e142f3ff1e717d85ebc017d02becfae2`,
`source_dirty: true`, Lockspire `1.6.1`, archive SHA-256 `a4cf36af08fca6fe11b7d7c39e7cb0224129f507cb009df13879d546198a946f`, and
expanded-tree SHA-256 `fcb9ff7246b004b3dfb47d7f480a5bc41eb801e1704bc7a373bf70773e45701e`. The supplied `.planning/state.json` is still
preserved byte-for-byte and unstaged. Runtime source did not change during
these sequential pair runs.

| Cell | Phoenix / LiveView | Mount | Result | Sum of scenario durations | Receipt |
|---|---|---|---|---:|---|
| locked-lockspire | 1.8.13 / 1.2.10 | `/lockspire` | 16/16; cleanup passed | 2.246 s | `.artifacts/phase170/final-containment-locked/locked-lockspire.json` |
| locked-nested | 1.8.13 / 1.2.10 | `/teams/ops/identity` | 16/16; cleanup passed | 2.952 s | `.artifacts/phase170/final-containment-locked/locked-nested.json` |
| locked-root | 1.8.13 / 1.2.10 | `/` | 16/16; cleanup passed | 2.192 s | `.artifacts/phase170/final-containment-locked/locked-root.json` |
| floor-lockspire | 1.8.5 / 1.1.28 | `/lockspire` | 16/16; cleanup passed | 2.272 s | `.artifacts/phase170/final-containment-floor-retry/floor-lockspire.json` |
| floor-nested | 1.8.5 / 1.1.28 | `/teams/ops/identity` | 16/16; cleanup passed | 2.264 s | `.artifacts/phase170/final-containment-floor-retry/floor-nested.json` |
| floor-root | 1.8.5 / 1.1.28 | `/` | 16/16; cleanup passed | 2.691 s | `.artifacts/phase170/final-containment-floor-retry/floor-root.json` |

| Pair | Reported workload duration | Lifecycle checks | Lifecycle receipt |
|---|---:|---:|---|
| locked | 562 s | 43 | `.artifacts/phase170/final-containment-locked/lifecycle.json` |
| floor | 156 s | 44 | `.artifacts/phase170/final-containment-floor-retry/lifecycle.json` |

Timings are the wrapper's report before independently bounded EXIT cleanup;
both commands then exited zero after owned lifecycle-database disposal and raw
root removal. Every browser receipt reports all four cleanup flags true. Both
reported workloads fit the 900-second deadline; the locked run left 338 seconds.
Actual local runtimes remain Elixir 1.20.4 / OTP 29, Node 26.10.0 and Chrome
155.0.8059.85, using the normal browser sandbox. CI's minimum BEAM remains an
expectation, with no hosted run dispatched or observed.

```bash
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/phase170/final-containment-locked
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/phase170/final-containment-floor-retry
```

Both inherited fresh `HEX_HOME=/private/tmp/lockspire-phase170-final-containment-hex.NJIhZ1`
and generated fresh owned lifecycle/admin databases. Current Python regressions
pass 36 tests; Node passes 8; affected CI/docs contracts pass 14. Workflow/shell
lint, formatting, diff and preserved-state checks pass. The prior 2,027-check
broad pass remains historical evidence at its recorded source; no new broad
pass is claimed for this wrapper-only path change. Detailed red/green evidence
and the superseded intermediate run are in [170-REMEDIATION.md](170-REMEDIATION.md).


## Historical first security-remediation evidence (2026-10-24)

The audit reproduced nested diagnostic-key disclosure and incomplete interruption,
exception, and database cleanup in the original harness. Those paths were repaired
in `ef9ef86030467792346d1b674c58b44d8db30d38`; the original Plan 05
results below remain historical. [170-REMEDIATION.md](170-REMEDIATION.md) records
fault reproductions, controls, regression evidence, and limits.

Both canonical wrappers were rerun after the final runtime harness changes.
All eight refreshed receipts bind source
`ef9ef86030467792346d1b674c58b44d8db30d38`, `source_dirty: true`, Lockspire
`1.6.1`, archive SHA-256
`a4cf36af08fca6fe11b7d7c39e7cb0224129f507cb009df13879d546198a946f`, and
expanded-tree SHA-256
`fcb9ff7246b004b3dfb47d7f480a5bc41eb801e1704bc7a373bf70773e45701e`.
The source remains marked dirty because the supplied `.planning/state.json` was
preserved byte-for-byte. The later `debd3d28` change updates only the existing
CI credential test; `8f775485` adds a receipt regression only. Neither changes
the runtime harness or package bytes.

Every browser receipt reports `processes_stopped`, `database_removed`,
`profile_removed`, and `run_root_removed` as true. The wrapper independently
drops its generated lifecycle database before a successful exit. Raw process
logs and profiles are removed; validated receipts retain only schema-bound
identity, runtime, booleans, counts, and known scenario IDs.

| Cell | Phoenix / LiveView | Mount | Result | Sum of scenario durations | Receipt |
|---|---|---|---|---:|---|
| locked-lockspire | 1.8.13 / 1.2.10 | `/lockspire` | 16/16; cleanup passed | 2.378 s | `.artifacts/phase170/remediation-locked/locked-lockspire.json` |
| locked-nested | 1.8.13 / 1.2.10 | `/teams/ops/identity` | 16/16; cleanup passed | 2.257 s | `.artifacts/phase170/remediation-locked/locked-nested.json` |
| locked-root | 1.8.13 / 1.2.10 | `/` | 16/16; cleanup passed | 2.355 s | `.artifacts/phase170/remediation-locked/locked-root.json` |
| floor-lockspire | 1.8.5 / 1.1.28 | `/lockspire` | 16/16; cleanup passed | 2.274 s | `.artifacts/phase170/remediation-floor/floor-lockspire.json` |
| floor-nested | 1.8.5 / 1.1.28 | `/teams/ops/identity` | 16/16; cleanup passed | 2.316 s | `.artifacts/phase170/remediation-floor/floor-nested.json` |
| floor-root | 1.8.5 / 1.1.28 | `/` | 16/16; cleanup passed | 2.236 s | `.artifacts/phase170/remediation-floor/floor-root.json` |

Actual local runtimes in every refreshed browser receipt: Elixir `1.20.4`,
OTP `29`, Node `26.10.0`, and Chrome `155.0.8059.85`, with normal browser
sandboxing. These are local runtime observations, separate from CI expectations.

| Pair | Reported workload duration | Lifecycle tests | Lifecycle receipt |
|---|---:|---:|---|
| locked | 145 s | 43 | `.artifacts/phase170/remediation-locked/lifecycle.json` |
| floor | 144 s | 44 | `.artifacts/phase170/remediation-floor/lifecycle.json` |

The pair workload deadline is 900 seconds; owned child termination allows at
most 15 seconds for cooperative cleanup and escalation. The wrapper's owned
lifecycle database cleanup has its own finite budget after that deadline.
The reported 145/144 seconds precede the EXIT cleanup. Both runs then exited
zero after successful bounded final cleanup and remained inside 900 seconds.
No hosted CI run, remote required-check configuration, or minimum CI BEAM
execution was observed or changed.

```bash
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/phase170/remediation-locked
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/phase170/remediation-floor
```

## Historical Plan 05 evidence (before the security remediation)

The following original results are retained for provenance. They do not prove
the repaired fault paths and are superseded by the refreshed evidence above.

## Evidence boundary

The pair wrapper installs the actual Lockspire 1.6.1 candidate archive into a
disposable Phoenix host, runs the existing shared server lifecycle selector on
the selected dependency pair, and executes the full 16-case matrix in real
Chrome/CDP at each supported mount. Lifecycle JSON and browser receipts remain
separate evidence kinds. Each browser receipt was validated against the
wrapper's run ID, source revision, pair, mount, archive/tree hashes, version,
and full-case set. All reported cleanup flags are true. No raw page HTML,
frames, browser profile, cookie/header values, credentials, or process logs are
retained in these receipt directories.

## Candidate identity and source revisions

| Pair command | Source revision | `source_dirty` | Lockspire version | Archive SHA-256 | Tree SHA-256 | Wrapper time |
|---|---|---:|---|---|---|---:|
| `locked` | `2bf1fdc2375cee6b3853ee24677a82b6f557388d` | true | `1.6.1` | `a4cf36af08fca6fe11b7d7c39e7cb0224129f507cb009df13879d546198a946f` | `fcb9ff7246b004b3dfb47d7f480a5bc41eb801e1704bc7a373bf70773e45701e` | 137 s |
| `floor` | `c7fcdb377a49763cf8c07e3213e44bc1a200ac69` | true | `1.6.1` | `a4cf36af08fca6fe11b7d7c39e7cb0224129f507cb009df13879d546198a946f` | `fcb9ff7246b004b3dfb47d7f480a5bc41eb801e1704bc7a373bf70773e45701e` | 138 s |

Both receipts identify a dirty local checkout. The pre-existing `.planning/state.json`
change was preserved from `/private/tmp/lockspire-phase170-original-state.json`;
later edits after these runs were limited to test-only guardrail fixes and
planning evidence. The exact package archive and expanded tree hashes match
between pairs. Test-only files are outside the published package input.

## Six-cell dependency and mount matrix

| Cell | Phoenix / LiveView | Actual local BEAM / OTP | Node / Chrome | Mount | Result | Cases / browser time | Receipt |
|---|---|---|---|---|---|---|---|
| locked-default | 1.8.13 / 1.2.10 | Elixir 1.20.4 / OTP 29 | Node 26.10.0 / Chrome 155.0.8059.85 | `/lockspire` | passed; cleanup passed | 16/16; 2.248 s | `.artifacts/phase170/final-locked/locked-lockspire.json` |
| locked-nested | 1.8.13 / 1.2.10 | Elixir 1.20.4 / OTP 29 | Node 26.10.0 / Chrome 155.0.8059.85 | `/teams/ops/identity` | passed; cleanup passed | 16/16; 2.258 s | `.artifacts/phase170/final-locked/locked-nested.json` |
| locked-root | 1.8.13 / 1.2.10 | Elixir 1.20.4 / OTP 29 | Node 26.10.0 / Chrome 155.0.8059.85 | `/` | passed; cleanup passed | 16/16; 2.222 s | `.artifacts/phase170/final-locked/locked-root.json` |
| floor-default | 1.8.5 / 1.1.28 | Elixir 1.20.4 / OTP 29 | Node 26.10.0 / Chrome 155.0.8059.85 | `/lockspire` | passed; cleanup passed | 16/16; 2.275 s | `.artifacts/phase170/final-floor/floor-lockspire.json` |
| floor-nested | 1.8.5 / 1.1.28 | Elixir 1.20.4 / OTP 29 | Node 26.10.0 / Chrome 155.0.8059.85 | `/teams/ops/identity` | passed; cleanup passed | 16/16; 2.235 s | `.artifacts/phase170/final-floor/floor-nested.json` |
| floor-root | 1.8.5 / 1.1.28 | Elixir 1.20.4 / OTP 29 | Node 26.10.0 / Chrome 155.0.8059.85 | `/` | passed; cleanup passed | 16/16; 2.288 s | `.artifacts/phase170/final-floor/floor-root.json` |

Each browser receipt includes exactly these scenarios: `allowed_entry`,
`assets`, `live_navigation`, `params_patch`, `detail_task`,
`allowed_reconnect`, `anonymous_http_denied`, `nonstaff_http_denied`,
`cached_join_denied`, `reconnect_denied`, `params_denied`,
`public_session_denied`, `consent_session_denied`, `public_discovery`,
`public_jwks`, and `public_protocol_error`.

## Shared lifecycle evidence

| Pair | Selector | Existing tests passed | Receipt |
|---|---|---:|---|
| locked | `locked_admin_routes_lifecycle`; compile, inventory, separation, and connected admin integration test files | 43 | `.artifacts/phase170/final-locked/lifecycle.json` |
| floor | `floor_admin_host_runtime`; same four original test files loaded by the floor fixture | 44 | `.artifacts/phase170/final-floor/lifecycle.json` |

The lifecycle receipts independently report the actual Phoenix/LiveView
versions. The packaged child host does not import repository test support.
These process-based server checks do not substitute for browser transport.

## CI expectations, budget, and remote status

| CI job | Pair | Expected CI Elixir / OTP | PostgreSQL service | Existing job cap |
|---|---|---|---|---:|
| Integration Checks | locked | 1.19.5 / 28 | pinned PostgreSQL 16 image | 30 min |
| Minimum Supported Elixir/OTP | floor | 1.18.4 / 27 | pinned PostgreSQL 14 image | 30 min |

The wrapper's per-pair deadline is 900 seconds. Local runs used 137 seconds
(`locked`) and 138 seconds (`floor`), leaving 763 and 762 seconds respectively
inside that wrapper budget. Full hosted job headroom was not measured locally;
the existing 30-minute CI job limits remain unchanged. No remote workflow run
was dispatched or observed, so there is no remote run URL, SHA result, or green
status to report.

## Commands and prerequisites

The exact commands, database variables, Node/Chrome discovery, fresh receipt
directory rules, and safe-output interpretation are documented in
[`docs/maintainer-release.md`](../../../docs/maintainer-release.md#packaged-host-compatibility-proof).
The local commands used were:

```bash
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/phase170/final-locked
ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 bash scripts/ci/run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/phase170/final-floor
```
