---
phase: 126-adopter-path-walk-defect-ledger
plan: 03
subsystem: testing
tags: [python, http-client, pkce, oauth, csrf, adopter-path, adopt-04]

# Dependency graph
requires:
  - phase: 126-01
    provides: "LOCKSPIRE_WALK_EMAIL/LOCKSPIRE_WALK_PASSWORD cross-plan credential contract, tmp/adopter-walk workdir"
  - phase: 126-02
    provides: "ADOPT-03 step-ID <-> guide-section mapping gate scanning the union of shell record_result calls and the driver's printed result lines"
provides:
  - "scripts/maintainer/adopter_path_flow.py: stdlib-only authorization-code + PKCE flow driver emitting step-06b-flow/step-06c-token-proof result lines"
  - "ADOPT-04 two-layer token proof: userinfo bearer assertion, anonymous-401, then bearer-200 against a host-owned protected route, in fixed order"
  - "adopter_flow_driver_contract_test.exs: stdlib-only-import allowlist gate, ADOPT-04 assertion presence/ordering gate, fresh-Browser gate"
affects: [126-04, 126-05, 126-06, 127, 128]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Python stdlib-only HTTP driver (http.client, no third-party deps) adapted from scripts/demo/adoption_smoke.py, never editing that file"
    - "Literal '[PASS|FAIL] step-id: §N ...' print statements at each call site (not a shared step_id variable) so the driver source itself, not just its runtime output, is statically greppable/regex-scannable by the ADOPT-03 mapping gate"
    - "Fresh cookie-less Browser() per protected-route HTTP call so a 200 is attributable to the bearer token alone, never a surviving session"

key-files:
  created:
    - scripts/maintainer/adopter_path_flow.py
    - test/lockspire/maintainer/adopter_flow_driver_contract_test.exs
  modified: []

key-decisions:
  - "Wrote the full driver (core PKCE sequence plus the ADOPT-04 two-layer token proof) in a single pass rather than splitting Task 1's core sequence from Task 2's token-proof extension as two separate diffs -- Task 1's commit already contains step-06c-token-proof and exercise_token_proof(). Task 2's commit adds only the contract test that locks that already-written behavior in. No functional gap: both tasks' acceptance criteria pass against the commits as landed."
  - "csrf() meta-tag fallback is annotated # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D10 because Lockspire's shipped ConsentLive renders raw <form method=\"post\"> tags with zero _csrf_token input (confirmed by reading lib/lockspire/web/live/consent_live.ex:81-93) -- the fallback reads the root layout's <meta name=\"csrf-token\"> tag instead, which protect_from_forgery accepts."
  - "The driver GETs return_to itself after the login POST (# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D14) rather than passing return_to as a login parameter, because phx.gen.auth's log_in_user/3 redirects to a session key only require_authenticated_user's GET path ever writes -- a return_to query param on POST /users/log-in is inert."
  - "Redirect URI is hardcoded as {base_url}/oauth/callback (no --redirect-uri flag) matching the plan's exhaustive CLI flag list, which omits that flag deliberately."
  - "Protected-route response shape assumed to nest fields under access_token.subject / access_token.scope, mirroring the existing adoption_demo pattern (access_token.audience) and docs/protect-phoenix-api-routes.md's conn.assigns.access_token contract -- this is Claude's-discretion response-shape guessing since the actual host route does not exist until a later plan wires it."

requirements-completed: [ADOPT-01, ADOPT-04]

coverage:
  - id: D1
    description: "Stdlib-only Python driver (Browser cookie jar, 8-hop redirect chaser, assert_status/assert_contains/assert_equal/location/json_body/code_challenge, LiveView-tolerant CSRF fallback chain, nested user[email]/user[password] login, driver-navigated return_to) drives the full authorization-code + PKCE sequence over plain HTTP with no browser and no mailbox"
    requirement: "ADOPT-01"
    verification:
      - kind: unit
        ref: "python3 -m py_compile scripts/maintainer/adopter_path_flow.py -- exits 0"
        status: pass
      - kind: other
        ref: "python3 scripts/maintainer/adopter_path_flow.py --help -- exits 0, lists all documented flags"
        status: pass
      - kind: other
        ref: "python3 scripts/maintainer/adopter_path_flow.py --base-url http://127.0.0.1:4200 with no server running -- prints [FAIL] step-06b-flow / step-06c-token-proof lines naming the readiness precondition and exits 1 with no traceback"
        status: pass
    human_judgment: false
  - id: D2
    description: "ADOPT-04 two-layer token proof: userinfo bearer assertion first, then a host-owned protected route asserted anonymous-401 before bearer-200 using a fresh cookie-less Browser each time, with step-06c-token-proof reporting FAIL naming the missing precondition if step-06b-flow yielded no token"
    requirement: "ADOPT-04"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_flow_driver_contract_test.exs (Lockspire.Maintainer.AdopterFlowDriverContractTest, 9 tests)"
        status: pass
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs ADOPT-03 mapping gate (20 tests) -- now enforces step-06b-flow/step-06c-token-proof's §6 label agreement now that the driver exists, with zero test-file changes needed"
        status: pass
    human_judgment: false

# Metrics
duration: 21min
completed: 2026-07-29
status: complete
---

# Phase 126 Plan 03: Flow Driver Core & ADOPT-04 Two-Layer Token Proof Summary

**A stdlib-only Python driver (`scripts/maintainer/adopter_path_flow.py`) completes the authorization-code + PKCE sequence over plain HTTP against a booted adopter-path host, then proves the issued access token is usable at two independent layers -- `<mount>/userinfo` and a host-owned protected route, with the anonymous-401 case asserted before the bearer-200 case -- reporting `step-06b-flow` and `step-06c-token-proof` result lines that slot directly into the shell harness's accumulator.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-07-29T00:00:00Z (approx.)
- **Completed:** 2026-07-29T00:21:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 2 (2 created, 0 modified)

## Accomplishments

- `scripts/maintainer/adopter_path_flow.py`: a new stdlib-only module (imports limited to `argparse`, `base64`, `hashlib`, `http.client`, `json`, `os`, `re`, `sys`, `time`, `http.cookies.SimpleCookie`, `urllib.parse.{parse_qs, urlencode, urljoin, urlparse}`) adapted from `scripts/demo/adoption_smoke.py:221-320`, never editing that file
- `Browser` class, `assert_status`/`assert_contains`/`assert_equal`/`location`/`json_body`/`code_challenge` copied in shape, keeping the 600-character body truncation budget
- `csrf(body, label)`: form-input-then-meta-tag fallback chain (marked `ADOPT-D10`) since Lockspire's shipped `ConsentLive` renders no `_csrf_token` form input at all
- `login(browser, email, password)`: nests parameters under `user[email]`/`user[password]` against `/users/log-in`, matching `phx.gen.auth`'s generated controller
- `wait_until_ready(base_url, mount)`: polls discovery, then requires a non-empty JWKS before the flow proceeds (surfaces RESEARCH Open Question 1 as a named readiness failure rather than an opaque signing error)
- `exercise_authorization_code(...)`: drives PKCE S256, the login handoff, and an explicit driver-navigated `GET return_to` (marked `ADOPT-D14`) since `log_in_user/3` ignores a `return_to` query parameter on POST; reports `step-06b-flow`
- `exercise_token_proof(...)`: asserts userinfo-bearer-200, then anonymous-401, then bearer-200 against the protected host route -- in that fixed order, each protected-route call using a fresh cookie-less `Browser`; reports `step-06c-token-proof`
- `main()`: readiness -> flow -> token-proof, catching `AssertionError` per step so a `step-06b-flow` failure still lets `step-06c-token-proof` report why it could not run rather than being silently skipped; never prints the access token, ID token, code, cookie, or password
- `test/lockspire/maintainer/adopter_flow_driver_contract_test.exs` (`Lockspire.Maintainer.AdopterFlowDriverContractTest`, 9 tests): py_compile gate, stdlib-import allowlist gate (with a regression guard proving an injected third-party import fails it), ADOPT-04 assertion presence + fixed-order gate (with regression guards for a deleted anonymous-401 assertion and a reordered userinfo/protected-route pair), fresh-Browser-for-protected-calls gate, and a smoke-wrapper-boundary check confirming `scripts/demo/adoption_smoke.py` still carries its own black-box proof functions

## Task Commits

Each task was committed atomically:

1. **Task 1: Flow driver core -- cookie jar, CSRF fallback chain, login, authorize-to-token sequence** - `c7b223a` (feat)
2. **Task 2: ADOPT-04 two-layer token proof and the driver contract test** - `b3a858d` (test)

_Note: see Deviations below -- Task 1's commit already contains the ADOPT-04 token-proof implementation (`exercise_token_proof`, `step-06c-token-proof`) because the driver was authored in a single pass. Task 2's commit adds only the contract test._

## Files Created/Modified

- `scripts/maintainer/adopter_path_flow.py` - The stdlib-only PKCE flow driver and ADOPT-04 two-layer token proof
- `test/lockspire/maintainer/adopter_flow_driver_contract_test.exs` - `Lockspire.Maintainer.AdopterFlowDriverContractTest`: 9 driver-contract assertions

## Decisions Made

- Wrote the full driver (Task 1's core sequence and Task 2's token-proof extension) in one authoring pass, since both were straightforward continuations of the same module and splitting them into two separate diffs would have meant either an incomplete Task 1 commit (driver missing `step-06c-token-proof`, which the plan's own artifact list requires to exist in the finished file) or artificial code removal/re-addition between commits. Task 1's commit is functionally complete against Task 1's own acceptance criteria (verified independently -- none of Task 1's grep checks require `step-06c-token-proof` to be absent); Task 2's commit adds the test that locks the token-proof behavior in, matching the plan's task split for verification purposes even though the implementation code itself landed one commit earlier than a strict task-by-task diff would produce.
- `csrf()`'s meta-tag fallback is a marked workaround (`ADOPT-D10`), not a silent fix, per D-40/D-41 -- confirmed empirically by reading `lib/lockspire/web/live/consent_live.ex:81-93`, where both decision forms are raw `<form method="post">` tags with no `_csrf_token` input at all.
- The driver navigates `return_to` itself with an explicit `GET` after the login POST (`ADOPT-D14`), rather than trusting the login redirect, because `phx.gen.auth`'s generated `log_in_user/3` writes its redirect target to a session key that only `require_authenticated_user`'s GET path populates -- a `return_to` query parameter POSTed to `/users/log-in` is inert.
- No `--redirect-uri` CLI flag: the plan's flag list (`--base-url`, `--mount`, `--client-id`, `--email`, `--password`, `--protected-path`, `--scope`) omits it, so the redirect URI is derived as `{base_url}/oauth/callback`, matching `scripts/demo/adoption_smoke.py`'s own convention.
- The protected-route response-shape assertion (`access_token.subject`, `access_token.scope`) is a reasonable guess at the eventual host route's JSON contract, modeled on `docs/protect-phoenix-api-routes.md`'s `conn.assigns.access_token` fields and the existing adoption demo's `access_token.audience` precedent -- the actual route does not exist yet (a later plan wires it), so this is exactly the kind of assumption the `<inversion_warning>` anticipates failing on first real run.

## Deviations from Plan

### Process deviation (not a Rule 1-4 case)

**1. Task 1 and Task 2 code landed in a single authoring pass instead of two incremental diffs**

- **Found during:** Task 1 implementation
- **What happened:** The full driver, including `exercise_token_proof` and `step-06c-token-proof` (Task 2's scope), was written together with Task 1's core sequence in one `Write` call, since both were part of the same natural continuation of the module.
- **Impact:** None functionally -- both tasks' acceptance criteria were independently verified to pass against the commits as landed (Task 1's commit satisfies every one of Task 1's own `grep`/behavior checks; Task 2's commit adds the test suite that locks in the already-present token-proof behavior). No code was written and then discarded or re-added.
- **Files affected:** `scripts/maintainer/adopter_path_flow.py` (all content in Task 1's commit `c7b223a`)
- **Committed in:** `c7b223a` (Task 1), `b3a858d` (Task 2, test-only)

No `<must_haves>` truth or prohibition was violated, and no scope crept beyond what the plan specified for the file's final content.

## Known Stubs

None. Every function is a real implementation, not a placeholder -- the driver is expected by the plan's own `<inversion_warning>` to fail against a real generated host on first run (the consent POST, resolver claims, and protected route are downstream of unfixed defects this phase records but does not repair), which is a runtime/environment gap, not a stub in this plan's own deliverables.

## Issues Encountered

- Initial contract-test helper (`extract_imported_modules`) pattern-matched `Regex.scan`'s per-match capture list assuming a fixed 2-capture-group shape (`[_, mod, ""]` / `[_, "", mod]`); Erlang's `re` only emits participating capture groups, so a bare `import X` line produced a 1-element capture list and raised `FunctionClauseError`. Fixed by switching to `capture: :all_but_first` and rejecting empty strings before taking the first non-empty capture, verified by re-running the test suite (9/9 passing).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `scripts/maintainer/adopter_path_flow.py` is ready for plan 126-04/126-05 to invoke from the shell harness once the generated host is booted and a client is registered; its CLI flags (`--base-url`, `--mount`, `--client-id`, `--email`, `--password`, `--protected-path`, `--scope`) and `LOCKSPIRE_WALK_BASE_URL` env fallback are the integration surface those plans consume.
- `step-06b-flow` and `step-06c-token-proof` are already validated against the ADOPT-03 mapping gate from plan 126-02 (`test/lockspire/maintainer/adopter_walk_contract_test.exs`, 20 tests, 0 failures) -- the gate's union-scan of shell + driver sources now finds and correctly attributes both driver steps to guide §6 with zero further test-file changes, exactly as 126-02's summary anticipated.
- The driver has **not** been run against a real booted host in this plan (that requires plans 126-04/126-05 to generate, wire, and boot the app first); its own `<verify>` gate (`py_compile` + `mix test`) and the manual no-server-running behavior check (confirmed: `[FAIL]` lines naming the readiness precondition, exit 1, no traceback) are fully satisfied here. Per the plan's `<inversion_warning>`, the driver is expected to surface real defects (consent CSRF, resolver claims, protected-route wiring) once it runs against a real host in a later plan -- that is this phase's purpose, not a gap in this plan.
- No blockers.

## Verification

- `python3 -m py_compile scripts/maintainer/adopter_path_flow.py` -- exits 0
- `mix test test/lockspire/maintainer/adopter_flow_driver_contract_test.exs` -- 9 tests, 0 failures
- `mix test test/lockspire/maintainer/adopter_walk_contract_test.exs` -- 20 tests, 0 failures (ADOPT-03 mapping gate now covers the driver)
- `git diff --exit-code -- scripts/demo/adoption_smoke.py` -- no change
- `bash scripts/maintainer/repo_hygiene_check.sh --ci` -- 18 PASS, 0 WARN, 0 BLOCK
- `mix qa` (format / compile --warnings-as-errors / credo --strict / sobelow) -- clean
- `mix test.fast` -- 1256 tests, 0 failures (287 excluded) -- confirms no regression to the broader suite (prior baseline was 1247; +9 from the new contract test file)
- Manual: `timeout 60 python3 scripts/maintainer/adopter_path_flow.py --base-url http://127.0.0.1:4200` with no server running -- printed `[FAIL] step-06b-flow: ...` and `[FAIL] step-06c-token-proof: ...` lines naming the readiness precondition, exited 1, no traceback

## Self-Check: PASSED

- FOUND: scripts/maintainer/adopter_path_flow.py
- FOUND: test/lockspire/maintainer/adopter_flow_driver_contract_test.exs
- FOUND: c7b223a
- FOUND: b3a858d

---
*Phase: 126-adopter-path-walk-defect-ledger*
*Completed: 2026-07-29*
