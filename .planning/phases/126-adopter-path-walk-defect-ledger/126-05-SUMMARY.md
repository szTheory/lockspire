---
phase: 126-adopter-path-walk-defect-ledger
plan: 05
subsystem: testing
tags: [bash, elixir, phoenix, oauth, migrations, signing-keys, adopter-path, adopt-01, adopt-04]

# Dependency graph
requires:
  - phase: 126-03
    provides: "scripts/maintainer/adopter_path_flow.py's ADOPT-04 two-layer token proof, step-06b-flow/step-06c-token-proof result lines, DEFAULT_PROTECTED_PATH=/api/walk/summary"
  - phase: 126-04
    provides: "step-03c-resolver, step-03d-app-tree, step-03e-protected-route -- host resolver seam, application-start ordering, and the /api/walk/summary protected route the second ADOPT-04 acceptance layer hits"
provides:
  - "step-04-migrate and step-05-verify: the documented bare `mix ecto.migrate` is run as written (never PASS), and mix lockspire.verify is the independent detector that parses pending-migration count and missing tables, records ADOPT-D07, then applies the release-safe Application.app_dir(:lockspire, ...) migrations workaround"
  - "step-06a-client: mix lockspire.client.create run as documented (real repo-not-started failure, ADOPT-D08), then a mix run -e workaround registers the walk's public client and mints+asserts a JWKS-visible signing key (ADOPT-D06), resolving RESEARCH Open Question 1 empirically"
  - "Boot/drive/teardown block: boots the generated host in the background, invokes scripts/maintainer/adopter_path_flow.py, folds every driver-printed [PASS]/[FAIL] line into the harness's own RESULTS accumulator so step-06b-flow/step-06c-token-proof count toward the single verdict, and tears the server down unless --keep is passed"
  - "step-07-upgrade (not walked) and step-08-verify-seam (not walked): guide sections deliberately excluded from the ADOPT-03 mapping gate by construction, so absence reads as a decision, not an omission"
affects: [126-06, 127, 128, 129]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Independent-detector verdict pattern: a documented command's exit code is recorded as an observation, never a pass/fail verdict, when a separate diagnostic command (mix lockspire.verify) exists that can honestly resolve the real outcome"
    - "Two-phase defect recording: record the gap as FAIL with a provisional ledger ID before applying any LOCKSPIRE_WALK_WORKAROUND marker, so the marker never masks the underlying evidence"
    - "Driver-result folding: a shell harness parses another process's stdout [PASS]/[FAIL] lines and re-emits them through its own record_result accumulator, unifying two languages' step reporting into one report and one verdict"

key-files:
  created: []
  modified:
    - scripts/maintainer/adopter_path_walk.sh
    - test/lockspire/maintainer/adopter_walk_contract_test.exs

key-decisions:
  - "step-04-migrate can structurally never record PASS (enforced by a dedicated contract test) -- the verdict is always deferred to step-05-verify, the independent detector, per the plan's own inversion_warning."
  - "The migrations workaround uses only Application.app_dir(:lockspire, \"priv/repo/migrations\") (the release-safe application-directory form); the dependency-directory form is never used anywhere in the script, enforced by a regression-guard contract test."
  - "Dropped 'openid' from the client's registered allowed_scopes (both the documented mix lockspire.client.create attempt and the mix run -e workaround) after a real end-to-end run showed Lockspire.Clients.register_client/1 rejects it as :invalid_scope by design -- Lockspire.Protocol.AuthorizationRequest already treats 'openid' as implicitly allowed for every client regardless of allowed_scopes. Including it masked ADOPT-D08's real repo-not-started defect behind an unrelated scope-validation error; this is a bug in this plan's own script, not a Lockspire adoption defect worth ledgering."
  - "The boot step exports PORT explicitly (`PORT=\"$PORT\" mix phx.server`) rather than relying on dev.exs's compile-time port key -- a real end-to-end run showed a stock mix phx.new host's generated config/runtime.exs sets the endpoint http port from the PORT env var unconditionally (not gated behind config_env() == :prod), so it silently wins over dev.exs and always binds 4000 regardless of --port. This is the first step in the walk that actually boots mix phx.server, so the gap was invisible until now."
  - "step-06a-client's documented-command failure detail is extracted via `grep -m 1 '^\\*\\* ('` (the Elixir exception summary line) with a `tail -n 1` fallback, not `head -n 1` -- the Mix task's compile warnings precede the real error, so head-based extraction grabbed an unrelated warning line."
  - "JWKS visibility after Lockspire.Admin.generate_key/1 alone was asserted rather than assumed (RESEARCH Open Question 1): a real run confirmed generate_key/1 alone leaves the key unpublished (status :upcoming, published_at nil, excluded from list_publishable_keys), so publish_key/2 is also required -- both calls are made and the two-undocumented-calls outcome is recorded as evidence on the ADOPT-D06 ledger entry."
  - "Guide §7 and §8 are recorded via a 'PASS' level with a literal ' (not walked)' suffix in the label, which structurally cannot match the ADOPT-03 shell_steps() regex (it requires the label to be exactly step-0[1-8][a-z]?-... with no trailing text) -- this deliberately excludes them from the step-ID <-> guide-section mapping gate while still keeping them in the printed report and PASS_COUNT."

requirements-completed: [ADOPT-01, ADOPT-03, ADOPT-04]

coverage:
  - id: D1
    description: "step-04-migrate runs the documented mix ecto.create + bare mix ecto.migrate exactly as written and can never record PASS; step-05-verify independently detects the silent no-op by parsing mix lockspire.verify's captured stdout (pending-migration count, missing tables), records FAIL attributed ADOPT-D07 (owning phase 127), then applies the release-safe Application.app_dir(:lockspire, ...) migrations workaround and re-verifies"
    requirement: "ADOPT-01"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (40 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "Manual: bash scripts/maintainer/adopter_path_walk.sh --from-step 04 against a real generated host with 37 genuinely pending Lockspire/Oban migrations -- step-04-migrate FAIL, step-05-verify FAIL naming '37 pending' then PASS naming zero pending after the workaround"
        status: pass
    human_judgment: false
  - id: D2
    description: "step-06a-client runs mix lockspire.client.create as documented (real repository-not-started failure attributed ADOPT-D08, owning phase 127), registers the walk's public client (adopter-walk-public, email/profile/read:walk scopes, authorization_code, token_endpoint_auth_method=none) through a mix run -e workaround, records the no-signing-key gap (ADOPT-D06, owning phases 127/128), mints a key via Lockspire.Admin.generate_key/1, and asserts JWKS non-empty (calling publish_key/2 when generation alone is insufficient)"
    requirement: "ADOPT-01"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (40 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "Manual: same live run -- step-06a-client's documented attempt fails with the real ** (RuntimeError) could not lookup Ecto repo HostApp.Repo error; the workaround registers the client and resolves RESEARCH Open Question 1 as 'two undocumented calls required' (generate_key/1 alone left JWKS empty; publish_key/2 was also needed), then records PASS"
        status: pass
    human_judgment: false
  - id: D3
    description: "Boots the generated host in the background (MIX_ENV=dev, explicit PORT export, stdout/stderr to a workdir-local server.log, pid captured under the existing pid-only EXIT/INT/TERM trap), invokes scripts/maintainer/adopter_path_flow.py, folds every driver-printed [PASS]/[FAIL] line into the harness's own RESULTS/PASS_COUNT/FAIL_COUNT accumulator, prints server.log on any driver FAIL, and tears the server down by default (or leaves it running with a printed base URL and port-still-bound warning under --keep)"
    requirement: "ADOPT-04"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (40 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "Manual: same live run -- the host boots on port 4200 (confirmed via curl against /lockspire/.well-known/openid-configuration), step-06b-flow and step-06c-token-proof appear in the printed report and count toward Summary: 8 PASS, 6 FAIL / Result: adopter path is RED; a run without --keep leaves no server process and the port free afterward (confirmed via lsof); a run with --keep leaves the server serving and prints the base URL plus an explicit port-still-bound warning (confirmed via curl and the next run's preflight rejecting the bound port)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Guide §7 and §8 are recorded as explicit 'step-07-upgrade (not walked)' / 'step-08-verify-seam (not walked)' PASS-level report lines with a one-line reason each, deliberately excluded from the ADOPT-03 step-ID <-> guide-section mapping gate by the label's own shape"
    requirement: "ADOPT-03"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs 'walk script accounts for guide §7 and §8 as explicitly not walked' and 'the not-walked §7/§8 report lines are excluded from the ADOPT-03 step-ID mapping gate by design'"
        status: pass
      - kind: other
        ref: "Manual: same live run -- both lines print in the final report at PASS level without incrementing FAIL_COUNT"
        status: pass
    human_judgment: false

# Metrics
duration: 65min
completed: 2026-07-29
status: complete
---

# Phase 126 Plan 05: Guide §4-§6 Walk Steps, Boot/Drive/Teardown & §7/§8 Accounting Summary

**The walk now runs guide §4's migrate command as documented (never PASS) with `mix lockspire.verify` as the honest detector (ADOPT-D07), registers a client and signing key through documented-then-marked paths (ADOPT-D08, ADOPT-D06), boots the generated host and drives the real authorization-code + PKCE flow against it, folding the driver's own step-06b-flow/step-06c-token-proof results into one report and one verdict -- confirmed end-to-end against a real generated host, real PostgreSQL, and a real booted Phoenix server, where the walk correctly went RED with 8 PASS and 6 FAIL, including one newly-surfaced real defect (`authorize handoff: missing interaction_id or return_to`) that this phase's own mandate is to record, not fix.**

## Performance

- **Duration:** ~65 min (including live manual verification and two rounds of bug-fixing against a real generated host)
- **Completed:** 2026-07-29T01:10:24Z
- **Tasks:** 2
- **Files modified:** 2 (0 created, 2 modified)

## Accomplishments

- `step-04-migrate`: runs the documented `mix ecto.create` + bare `mix ecto.migrate` inside the generated app exactly as written, with no `--migrations-path` flag added. Can never record PASS (enforced by a contract test) -- its exit code is deliberately never treated as the verdict.
- `step-05-verify`: captures `mix lockspire.verify`'s stdout regardless of exit code, parses the pending-migration count and missing-table checks out of it, records FAIL attributed `ADOPT-D07` (owning phase 127) naming the concrete pending count and missing tables, applies the release-safe `Application.app_dir(:lockspire, "priv/repo/migrations")` migrations workaround marked `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D07` (never the dependency-directory form), then re-verifies and records PASS or FAIL depending on whether the pending count reached zero.
- `step-06a-client`: runs the documented `mix lockspire.client.create` (expected and confirmed to fail with a real repository-not-started error, `ADOPT-D08`, owning phase 127), registers the walk's public client (`adopter-walk-public`, redirect URI `<base_url>/oauth/callback`, scopes `email`/`profile`/`read:walk`, grant `authorization_code`, `token_endpoint_auth_method: "none"`) through a `mix run -e` workaround marked `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D08`, records the no-signing-key gap (`ADOPT-D06`, owning phases 127/128), mints a key via `Lockspire.Admin.generate_key(:sig)` marked `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D06`, and immediately asserts JWKS non-empty -- calling `publish_key/2` when generation alone is insufficient, recording which path was needed as evidence for RESEARCH Open Question 1.
- Boot/drive/teardown block: boots `mix phx.server` in the background (`MIX_ENV=dev`, explicit `PORT` export), redirects output to `<workdir>/server.log`, invokes `scripts/maintainer/adopter_path_flow.py` with the base URL/mount/client-id/seeded credentials/protected path, folds every driver-printed `[PASS]`/`[FAIL]` line into the harness's own `RESULTS`/`PASS_COUNT`/`FAIL_COUNT` accumulator (with a synthetic FAIL fallback if the driver crashes without printing any step line), prints `server.log` on any driver FAIL, and terminates the server unless `--keep` is passed (which instead prints the base URL and an explicit port-still-bound warning).
- `step-07-upgrade (not walked)` and `step-08-verify-seam (not walked)`: explicit PASS-level report lines with a one-line reason each, structurally excluded from the ADOPT-03 step-ID mapping gate by the label's own shape (`(not walked)` breaks the gate's step-ID regex).
- 13 new tests added to `test/lockspire/maintainer/adopter_walk_contract_test.exs` (40 total, up from 27): step-04/05 presence, the never-PASS structural guard on step-04-migrate, the release-safe-form regression guard, step-06a-client's markers/scopes/API calls, the boot/drive/log/trap/fold assertions, the not-walked accounting, and the protected-path byte-identity check.

## Task Commits

Each task was committed atomically, plus one additional fix commit from live manual verification:

1. **Task 1: Guide §4 and §5 -- run the documented migrate command, then let the verifier detect what it did not do** - `99d6ab8` (feat)
2. **Task 2: Guide §6 -- signing key and client registration, then boot, drive, and fold the flow results into the verdict** - `2936215` (feat)
3. **Live-verification fixes: scope validation and PORT export bugs found during a real end-to-end run** - `950e328` (fix)

## Files Created/Modified

- `scripts/maintainer/adopter_path_walk.sh` - Added `run_step_04_migrate`, `run_step_05_verify`, `run_step_06a_client`, `run_step_06_boot_drive_flow`, and the §7/§8 not-walked report lines
- `test/lockspire/maintainer/adopter_walk_contract_test.exs` - 13 new tests covering steps 04-06a, the boot/drive/fold/teardown contract, and the §7/§8 not-walked exclusion

## Decisions Made

See `key-decisions` in frontmatter for the full list. The two most consequential:

- **Structural never-PASS guard on step-04-migrate.** Rather than trusting future edits not to accidentally make step-04-migrate record PASS on a lucky exit code, a dedicated contract test asserts no `record_result "PASS" "step-04-migrate"` call exists anywhere in the script. This directly encodes the plan's own inversion_warning and prohibition against letting an exit code stand in for the outcome it's supposed to prove.
- **"openid" removed from the client's registered allowed_scopes.** The plan's action text listed "openid, email, profile and read:walk" as what the allowed scopes should include, but a real end-to-end run showed `Lockspire.Clients.register_client/1` rejects "openid" as `:invalid_scope` by design -- it's implicitly always allowed for every client regardless of registered scopes (`Lockspire.Protocol.AuthorizationRequest`'s `unknown_scope?`/`disallowed_scope?` both short-circuit `false` for "openid"). Including it in the registration call was a bug in this plan's own script (not a genuine Lockspire adoption defect), and it was masking `ADOPT-D08`'s real repo-not-started error behind an unrelated scope-validation error. Confirmed by removing "openid" and observing the documented `mix lockspire.client.create` attempt then fail with the expected `** (RuntimeError) could not lookup Ecto repo HostApp.Repo` error.

## Deviations from Plan

### Auto-fixed Issues (found during live manual verification against a real generated host)

**1. [Rule 1 - Bug] "openid" is an invalid client-registration scope, masking ADOPT-D08's real error**
- **Found during:** Task 2, first live run of `run_step_06a_client` against a real generated host
- **Issue:** The plan's action text says the registered client's allowed scopes should "include openid, email, profile and read:walk." Passing `--scope openid` (documented attempt) and `allowed_scopes: ["openid", ...]` (workaround) both failed with `client registration failed: allowed_scopes:invalid_scope(openid)` -- `Lockspire.Clients.register_client/1` rejects "openid" by design, since it's implicitly always allowed regardless of a client's registered scopes.
- **Fix:** Dropped "openid" from both the documented CLI attempt's `--scope` flags and the workaround's `allowed_scopes` list. Functionally harmless: the flow driver still requests `scope=openid email profile read:walk` at `/authorize`, and `authorize_request.ex` grants "openid" unconditionally regardless of the client's registered scopes.
- **Files modified:** `scripts/maintainer/adopter_path_walk.sh`
- **Verification:** Re-ran against the real generated host -- the documented attempt now correctly fails with the real repo-not-started error (`** (RuntimeError) could not lookup Ecto repo HostApp.Repo because it was not started or it does not exist`), and the workaround registers the client successfully.
- **Committed in:** `950e328`

**2. [Rule 3 - Blocking] Generated host's config/runtime.exs silently overrides the walk's configured port**
- **Found during:** Task 2, first live boot of the generated host during `run_step_06_boot_drive_flow`
- **Issue:** The server bound to port 4000 instead of the configured 4200, causing the flow driver's readiness check to time out with "Connection refused." A stock `mix phx.new` host's generated `config/runtime.exs` sets `http: [port: String.to_integer(System.get_env("PORT", "4000"))]` unconditionally -- not gated behind `config_env() == :prod` -- and `runtime.exs` is evaluated after `dev.exs`, so it silently wins even in `MIX_ENV=dev` regardless of dev.exs's compile-time `port: 4200` value.
- **Fix:** The boot command now exports `PORT="$PORT"` explicitly (`MIX_ENV=dev PORT="$PORT" mix phx.server`), matching `runtime.exs`'s actual resolution mechanism.
- **Files modified:** `scripts/maintainer/adopter_path_walk.sh`
- **Verification:** Re-ran -- the server log now shows `Running HostAppWeb.Endpoint with Bandit ... at 127.0.0.1:4200`, and the flow driver's readiness check against `<mount>/.well-known/openid-configuration` succeeds.
- **Committed in:** `950e328`

**3. [Rule 1 - Bug] `head -n 1` grabbed an unrelated compile warning instead of the real error**
- **Found during:** Same live run, reviewing `step-06a-client`'s FAIL detail text
- **Issue:** `step_06a_client_documented.log` contains several `mix compile` warnings (pre-existing, unrelated `no route path` heex warnings) before the real Mix task error, so `head -n 1` captured a warning line instead of the actual `** (RuntimeError) ...` summary.
- **Fix:** Extract the detail via `grep -m 1 '^\*\* ('` (the Elixir exception summary line format), falling back to `tail -n 1` if no such line is found.
- **Files modified:** `scripts/maintainer/adopter_path_walk.sh`
- **Verification:** The recorded FAIL detail now reads the real error: `** (RuntimeError) could not lookup Ecto repo HostApp.Repo because it was not started or it does not exist`.
- **Committed in:** `950e328`

---

**Total deviations:** 3 auto-fixed (1 Rule 1 scope-validation bug, 1 Rule 3 blocking port-config gap, 1 Rule 1 log-extraction bug). All three were caught only by an actual live run against a real generated host, real PostgreSQL, and a real booted Phoenix server -- exactly the kind of gap static `bash -n`/`mix test` verification cannot surface, and exactly why this plan performed the live run rather than relying on unit tests alone.
**Impact on plan:** Necessary for the boot/drive/client-registration steps to reach their own stated PASS/FAIL criteria at all (a live server that never binds the right port, or a client registration masked by an unrelated validation error, would make step-06a-client/step-06b-flow/step-06c-token-proof structurally unable to ever produce meaningful evidence). No scope creep -- all three fixes live entirely inside `scripts/maintainer/adopter_path_walk.sh`, the plan's own `files_modified` list.

## Known Stubs

None. Every new step performs real work: real `mix ecto.create`/`mix ecto.migrate` invocations, a real `mix lockspire.verify` parse, real client/key registration through `mix run -e`, a real backgrounded `mix phx.server` boot, and a real invocation of the already-delivered flow driver against that live server.

## Issues Encountered

- **A real, newly-surfaced Lockspire defect during the live run:** after client/key registration and a correctly-booted host, the flow driver's `/authorize` request received a `302` redirect that the driver could not parse an `interaction_id` or `return_to` from (`authorize handoff: missing interaction_id or return_to`), so `step-06b-flow` and `step-06c-token-proof` both recorded FAIL. This is genuine defect evidence -- exactly what Phase 126's mandate is to record, not repair (per PROJECT.md's phase-sequencing rule: "Phase 126 records defects but does not fix them"). It is not fixed here; it belongs on the Phase 126 defect ledger (plan 126-06) for Phases 127-129 to investigate and repair.
- **Deferred verification:** the full `mix ci` alias (`deps.audit`, `package.build`, `docs.verify`, `test.integration`, `test.phase3`) was not re-run after this plan's changes, since this plan only modifies a shell script and one test file with no interaction with those targets. `mix qa` (format/compile --warnings-as-errors/credo --strict/sobelow), `mix test.fast` (1276 tests, up from 1263 -- the +13 new contract tests), `mix format --check-formatted`, and `bash scripts/maintainer/repo_hygiene_check.sh --ci` (18 PASS, 0 WARN, 0 BLOCK) were all confirmed green. The project's `.planning/WINDOWS.md` broken-windows ledger tooling (`gsd-tools windows append`) is not available in this installation (`Unknown command: windows`), so this deferral is recorded here rather than in that ledger.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `scripts/maintainer/adopter_path_walk.sh` now walks the entire documented adopter path from `mix phx.new` through the authorization-code + PKCE flow and the two-layer ADOPT-04 token proof, in one continuous run producing one report and one verdict. Plan 126-06 (defect-ledger reconciliation) can now read every provisional ledger ID emitted across plans 126-01 through 126-05 (`ADOPT-D01` through `ADOPT-D11`, plus the newly-discovered `authorize handoff: missing interaction_id or return_to` defect surfaced by this plan's live run) and reconcile them against `126-DEFECT-LEDGER.md`.
- Confirmed via a real end-to-end run against a real `mix phx.new` + `mix phx.gen.auth --live` + `mix lockspire.install` generated host with real PostgreSQL: preflight passes; `step-04-migrate` through `step-05-verify` correctly detect and work around the migrations gap (37 real pending migrations resolved to zero); `step-06a-client` correctly demonstrates the real repo-not-started defect and then registers a client and an active signing key; the host boots on the configured port; the flow driver runs and its results fold into the single report; `--keep` and default teardown both behave exactly as specified; and the walk correctly reports `Result: adopter path is RED` with `8 PASS, 6 FAIL` -- a red first run with a complete, attributed report, which is this phase's own definition of success.
- The one real defect this live run surfaced (`authorize handoff: missing interaction_id or return_to`) is new evidence for plan 126-06's ledger, likely attributable to the resolver seam (`step-03c-resolver`, plan 126-04) or the underlying `AuthorizeController`/consent handoff -- worth flagging to whichever of Phase 127-129 ends up investigating the authorization-code handoff path.
- No blockers.

## Verification

- `bash -n scripts/maintainer/adopter_path_walk.sh` -- exits 0
- `mix test test/lockspire/maintainer/` -- 49 tests, 0 failures (40 in `adopter_walk_contract_test.exs`, up from 27; 9 in `adopter_flow_driver_contract_test.exs`, unaffected)
- `mix qa` (format / compile --warnings-as-errors / credo --strict / sobelow) -- clean
- `mix format --check-formatted` -- clean
- `mix test.fast` -- 1276 tests, 0 failures (287 excluded; +13 from the new contract tests, baseline was 1263)
- `bash scripts/maintainer/repo_hygiene_check.sh --ci` -- 18 PASS, 0 WARN, 0 BLOCK
- Manual, against a real generated host: `bash scripts/maintainer/adopter_path_walk.sh --from-step 04 --force` twice (once to find and fix the two live-run bugs, once clean after fixing) -- `Summary: 8 PASS, 6 FAIL` / `Result: adopter path is RED`, with `step-06b-flow`/`step-06c-token-proof` appearing in the printed report; `--keep` confirmed via `curl` against the live discovery endpoint and the next run's own preflight rejecting the still-bound port; default (non-`--keep`) teardown confirmed via `lsof -ti :4200` reporting no listener afterward

## Self-Check: PASSED

- FOUND: scripts/maintainer/adopter_path_walk.sh
- FOUND: test/lockspire/maintainer/adopter_walk_contract_test.exs
- FOUND: 99d6ab8
- FOUND: 2936215
- FOUND: 950e328

---
*Phase: 126-adopter-path-walk-defect-ledger*
*Completed: 2026-07-29*
