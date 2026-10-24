# Phase 170 — Final Acceptance Evidence

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
