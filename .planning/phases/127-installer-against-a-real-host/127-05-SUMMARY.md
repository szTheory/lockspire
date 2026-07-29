---
phase: 127-installer-against-a-real-host
plan: 05
subsystem: installer
tags: [phoenix-router, mix-generator, defmacro, csrf, deny-closed]

# Dependency graph
requires:
  - phase: 127-installer-against-a-real-host
    provides: "127-01's priv/test_fixtures/phx_new_host/ and Lockspire.HostSnapshot, and the general installer-against-a-real-host proof pattern this plan continues"
provides:
  - "priv/templates/lockspire.install/router.ex emits lockspire_routes/1 as a defmacro returning a quote block that injects a real, ordered, deny-closed route table -- the guide's first documented reading of installer step 3 (calling the helper) now works"
  - "A namespaced :lockspire_require_operator pipeline, emitted by the generated file itself, whose only plug halts every request with 403 until the host replaces it with real operator auth"
  - "An explicit browser-piped scope carrying the interaction routes and a live_session :lockspire_consent-wrapped consent LiveView route, ahead of the pipeline-less public forward, so both get session fetching and CSRF protection"
  - "test/integration/install_template_compile_test.exs -- an untagged (fast-lane) compile fence that renders the template, compiles it plus a stub host router, and reads Phoenix.Router.routes/1 back to prove injection, ordering, and the 403 halt"
  - "The regenerated, byte-compared runtime fixture at test/support/generated_host_app_web/router/lockspire.ex, and install_generator_test.exs's shape-coupled assertions realigned to the new emitted structure"
affects: [router-template-macro, install-generator-tests, install-upgrade-tests]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "defmacro returning quote for host route injection: Phoenix's scope/pipeline/pipe_through/forward/live_session/live are compile-time macros, so a quote block containing them expands correctly at the call site inside a host router -- replacing a def that returns a String, which is evaluated and discarded"
    - "Paste-safety by EEx-time literal resolution: pipeline/mount-path names are rendered as literals by the EEx template pass rather than taken as macro `opts` resolved via unquote, so the rendered quote body has zero macro-expansion-time constructs and compiles whether called or pasted verbatim"
    - "Compile-level route-table fence: Code.compile_string the rendered helper plus a stub host router declaring only :browser, then assert over the real Phoenix.Router.routes/1 output -- never over rendered source text, which passed happily on the pre-fix heredoc that injected zero routes"
    - "Source-position comparison as a byte-compare-friendly injection proof: :binary.match/2 byte offsets for the admin and public forward substrings, replacing a brittle multi-line regex tied to one exact three-line body"

key-files:
  created:
    - test/integration/install_template_compile_test.exs
  modified:
    - priv/templates/lockspire.install/router.ex
    - test/support/generated_host_app_web/router/lockspire.ex
    - test/integration/install_generator_test.exs
    - test/integration/install_upgrade_test.exs

key-decisions:
  - "Rewrote priv/templates/lockspire.install/router.ex to use fully parenthesized macro calls (get(...), post(...), pipe_through(...), forward(...)), matching Elixir's canonical formatter style, with scope/live_session block macros left paren-less exactly as mix format itself renders them. The template's rendered output used to be paren-less text inside a discarded heredoc String, invisible to mix format; now that lockspire_routes/1 is real compiled code, the byte-compared runtime fixture under test/ is subject to mix format --check-formatted, and the byte-compare fence requires the template's raw EEx output to already match that exact formatted style with no separate formatting pass possible."
  - "Kept the module-level commented BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE example block's inner six lines byte-for-byte unchanged (only repositioned from inside a heredoc string to real module-level comments, with an added one-line prose intro), because test/lockspire/release_readiness_contract_test.exs hash-compares that exact block's normalized content across four canonical sites (docs guide, adoption demo router, this template, the smoke script) and would fail on drift."
  - "Routed the interaction routes and consent LiveView to Lockspire.Web.InteractionController and Lockspire.Web.ConsentLive (the same Lockspire-owned modules Lockspire.Web.Router already forwards to), matching RESEARCH's empirically-verified probe and the adoption demo's router -- not to the separate host-owned interaction_handler.ex/consent_live.ex generated templates, which serve a different purpose (login-flow handoff, not routing)."

requirements-completed: [INSTALL-01, INSTALL-02]

coverage:
  - id: D1
    description: "Importing the generated router helper and calling lockspire_routes() at the host router's top level injects a real route table with the admin forward strictly before the public forward"
    requirement: "INSTALL-01"
    verification:
      - kind: unit
        ref: "test/integration/install_template_compile_test.exs#the rendered router helper injects a real, correctly ordered, deny-closed route table"
        status: pass
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install writes the host-owned integration files (admin/public forward byte-offset comparison)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A stock mix phx.new host compiles with the generated helper without defining any pipeline of its own, and the emitted operator pipeline is deny-closed (403) by default"
    requirement: "INSTALL-01"
    verification:
      - kind: unit
        ref: "test/integration/install_template_compile_test.exs#the rendered router helper injects a real, correctly ordered, deny-closed route table (stub router defines only :browser; admin request halts 403)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The interaction routes and consent LiveView are browser-piped ahead of the pipeline-less public forward, and the consent route is wrapped in a live_session with on_mount left for the host"
    requirement: "INSTALL-02"
    verification:
      - kind: unit
        ref: "test/integration/install_template_compile_test.exs#the rendered router helper injects a real, correctly ordered, deny-closed route table (consent route resolves to Phoenix.LiveView.Plug)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The rendered macro body is paste-safe (no macro-expansion-time constructs) so the guide's second documented reading (pasting the body) also compiles"
    requirement: "INSTALL-02"
    verification:
      - kind: unit
        ref: "test/integration/install_template_compile_test.exs#the rendered router helper's body is paste-safe"
        status: pass
    human_judgment: false
  - id: D5
    description: "The committed runtime fixture matches the regenerated template byte for byte and the drift fence still fires on divergence"
    requirement: "INSTALL-01"
    verification:
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install writes the host-owned integration files (byte-compare assertion)"
        status: pass
    human_judgment: false

# Metrics
duration: 35min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 05: Installer Against A Real Host Summary

**`lockspire_routes/1` is now a `defmacro` returning a `quote` block that injects a real, correctly ordered, deny-closed route table into a host router -- closing ADOPT-D01, ADOPT-D02, and ADOPT-D03 by proving injection over the real, compiled `Phoenix.Router.routes/1` table rather than rendered source text.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-07-29T12:28:26Z
- **Tasks:** 2 completed
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments

- Closed ADOPT-D01: replaced `def lockspire_routes do """...""" end` (a heredoc `String`, evaluated and discarded when called) with `defmacro lockspire_routes(_opts \\ [])` returning a `quote do ... end` block. Calling `lockspire_routes()` at a host router's top level now injects a real, non-empty route table -- proven by compiling the rendered helper plus a stub host router and reading `Phoenix.Router.routes/1` back.
- Closed ADOPT-D02: the macro emits its own namespaced `:lockspire_require_operator` pipeline whose only plug halts every request with a 403 until the host replaces it with real operator auth. A stub host router declaring only the standard `:browser` pipeline compiles and correctly denies an admin request (403, halted) with zero operator-pipeline code of its own.
- Closed ADOPT-D03: the interaction routes and the consent LiveView now sit in an explicit browser-piped scope, wrapped for the consent route in a `live_session :lockspire_consent` (with `on_mount:` deliberately left for the host, per Phase 128's scope), emitted ahead of the pipeline-less public forward -- so they get session fetching and CSRF protection instead of riding the bare `forward` to `Lockspire.Web.Router`.
- Ordered the admin forward to `Lockspire.Web.AdminRouter` strictly before the public forward to `Lockspire.Web.Router`, matching `verify.ex:128-134`'s independent shadowing check; removed the duplicated commented admin-scope example; tidied the optional protected-API pipeline comment to read as documentation rather than dead code, while keeping its exact byte content so the four-site canonical-pipeline hash comparison in `release_readiness_contract_test.exs` still passes.
- Kept the emitted body paste-safe (RESEARCH Pitfall 12, Option 2): pipeline and mount-path names are rendered as EEx-time literals, not macro `opts` resolved via `unquote`, so the guide's second documented reading (pasting the rendered body directly into a router) also compiles.
- Added `test/integration/install_template_compile_test.exs`, an untagged fast-lane compile fence driven off `Lockspire.Generators.Install.rendered_templates/1` with a non-existent `project_root` (writes nothing to disk): it compiles the rendered helper and a stub host router, asserts the real route table via `Phoenix.Router.routes/1` (both forwards present, admin index < public index, consent route resolves to `Phoenix.LiveView.Plug`, all `/verify` and authorized-apps routes present), that the stub defines no operator pipeline of its own, that an admin request halts 403, and that the rendered body contains no `unquote(`.
- Regenerated `test/support/generated_host_app_web/router/lockspire.ex` from the rewritten template (installer run into the existing fixture with `base_args/0`'s `--web`/`--scope` values, output copied byte for byte) so the byte-compare drift fence keeps comparing against the new shape.
- Realigned the two structurally-coupled router assertions in `install_generator_test.exs` (recorded as a deliberate departure from CONTEXT D-06's "extend, not rewrite" -- see Deviations): the stand-in `pipe_through [:browser, :require_operator]` substring became `pipe_through([:browser, :lockspire_require_operator])`, and the brittle multi-line regex requiring the admin scope's exact old three-line body became a `pipeline :lockspire_require_operator` presence assertion plus a source-position (`:binary.match/2` byte offset) comparison of the admin and public forwards -- the same property `install_template_compile_test.exs` proves over the real, compiled route table.

## Task Commits

1. **Task 1: Make the generated helper inject a real, correctly ordered, deny-closed route table** - `131d977` (feat)
2. **Task 2: Regenerate the byte-compared runtime fixture and realign the shape-coupled assertions** - `c993252` (fix)

## Files Created/Modified

- `priv/templates/lockspire.install/router.ex` - rewritten as a `defmacro` returning a `quote` block; deny-closed operator pipeline, ordered admin/public forwards, browser-piped interaction+consent scope, paste-safe body, tidied protected-pipeline example, duplicate admin scope removed
- `test/integration/install_template_compile_test.exs` - new fast-lane compile fence proving real route injection, ordering, deny-closed default, and paste-safety over compiled output
- `test/support/generated_host_app_web/router/lockspire.ex` - regenerated runtime fixture, byte-identical to the rewritten template's rendered output
- `test/integration/install_generator_test.exs` - two shape-coupled router assertions realigned to the new pipeline name and forward ordering proof; router/authorized-apps/verify substring assertions updated for the new parenthesized macro-call style
- `test/integration/install_upgrade_test.exs` - one router content assertion updated for the new parenthesized macro-call style (out of this plan's stated files; see Deviations)

## Decisions Made

- Rewrote the template to fully parenthesized macro calls (see key-decisions above) so the byte-compared runtime fixture satisfies `mix format --check-formatted` without a separate formatting pass on generated output.
- Preserved the canonical `BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` example block's inner content byte-for-byte (only repositioned and given a one-line prose intro) to keep the four-site hash-comparison contract test green.
- Routed interaction/consent traffic to the existing `Lockspire.Web.InteractionController`/`Lockspire.Web.ConsentLive` modules (matching RESEARCH's verified probe and the adoption demo), not the separately-generated host-owned `interaction_handler.ex`/`consent_live.ex` templates, which serve login-flow handoff rather than routing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `mix format --check-formatted` failure on the regenerated runtime fixture**
- **Found during:** Task 2, after regenerating and copying the runtime fixture
- **Issue:** The rewritten template's paren-less macro-call style (`get "/verify", ...`, `pipe_through [:browser]`, `forward "/", ...`) was previously invisible to `mix format` because it lived inside a discarded heredoc `String`. Once it became real compiled code inside a `defmacro`/`quote`, the byte-compared runtime fixture at `test/support/generated_host_app_web/router/lockspire.ex` -- itself under `.formatter.exs`'s `test/**` scope -- failed `mix format --check-formatted`. Since the byte-compare fence requires the template's raw EEx output to be byte-identical to this fixture, the template itself had to already render in canonically-formatted style; a post-hoc `mix format` pass on only the fixture would have broken the byte-compare.
- **Fix:** Rewrote `priv/templates/lockspire.install/router.ex` to use fully parenthesized macro calls matching Elixir's default formatter output (confirmed by running `mix format` on a copy of the rendered output and diffing byte-for-byte against the hand-written template's own render), while leaving `scope`/`live_session` block macros paren-less exactly as the formatter itself renders them.
- **Files modified:** `priv/templates/lockspire.install/router.ex`, `test/support/generated_host_app_web/router/lockspire.ex`
- **Verification:** `mix format --check-formatted`, `mix qa`, `mix test.fast`
- **Committed in:** `c993252`

**2. [Rule 1 - Bug] Paren-less router assertion broke in an out-of-scope test file**
- **Found during:** Task 2, `mix test.fast` full-suite run
- **Issue:** `test/integration/install_upgrade_test.exs` (not named in this plan's `<files>`) asserts `~s(forward "/oauth", Lockspire.Web.Router)` against the regenerated router content, which now renders as `forward("/oauth", Lockspire.Web.Router)` -- a direct regression from the parenthesization fix above, not a pre-existing failure.
- **Fix:** Updated the assertion to the parenthesized form (`~s<forward("/oauth", Lockspire.Web.Router)>`).
- **Files modified:** `test/integration/install_upgrade_test.exs`
- **Verification:** `mix test test/integration/install_upgrade_test.exs`, `mix test.fast`
- **Committed in:** `c993252`

### Departures from Explicit Plan Instructions

**3. [CONTEXT D-06 departure, disclosed per Task 2's own instruction] Two `install_generator_test.exs` router assertions rewritten, not extended**
- **What changed:** `pipe_through [:browser, :require_operator]` -> `pipe_through([:browser, :lockspire_require_operator])`, and the multi-line regex `~r/scope "\/lockspire\/admin" do\s+pipe_through \[:browser, :require_operator\]\s+forward "\/", Lockspire.Web.AdminRouter\s+end/` -> a `pipeline :lockspire_require_operator` presence assertion plus a `:binary.match/2` byte-offset comparison of the admin and public forwards.
- **Why this departs from D-06's "extend, not rewrite":** both assertions encoded the *defective* pre-fix shape (the stand-in, non-namespaced `:require_operator` pipeline name, and one exact three-line admin-scope body) this plan exists to replace. Neither can be true of any correct output, so extending them was not possible. Task 2's own plan text explicitly named and required this exception, scoped to exactly these two assertions and no others in the shape-coupled range.
- **Not extended to:** any other assertion in `install_generator_test.exs:83-113` (the admin scope path, both forwards' presence, the operator-ownership comment, the four `/verify` routes, the authorized-apps route, the prefill-only note, and the device-flow guide reference were all preserved, only re-parenthesized where their literal text changed).

---

**Total deviations:** 2 auto-fixed (Rule 1 bugs, both direct consequences of the paren-style shape change), 1 disclosed plan departure (explicitly instructed by the plan itself).
**Impact on plan:** No scope creep. The out-of-scope `install_upgrade_test.exs` touch is a one-line assertion fix required to keep `mix test.fast` green after this plan's own shape change; the router content, ordering, deny-closed default, and paste-safety guarantees are exactly what the plan specified.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ADOPT-D01, ADOPT-D02, and ADOPT-D03 are closed. Both documented readings of the guide's router step (calling `lockspire_routes()`, and pasting its rendered body) now compile and produce a real, deny-closed, correctly-ordered route table.
- `test/integration/install_template_compile_test.exs` is a new fast-lane compile fence future router-template changes must keep green; it is the canonical place to extend route-table proof for this template going forward.
- The remaining `127-0N` plans (config template, plan-then-apply conflict semantics, and the point fixes from the Phase 126 ledger) are untouched by this plan.
- No blockers. `mix test.fast` (1296 tests, 0 failures), `mix qa` (format, Credo `--strict`, `compile --warnings-as-errors`, Sobelow), and the plan's full `<verification>` command set are all green with a clean `git status --porcelain`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 5 created/modified files confirmed present on disk; both task commits (`131d977`, `c993252`) confirmed in `git log --oneline --all`.
