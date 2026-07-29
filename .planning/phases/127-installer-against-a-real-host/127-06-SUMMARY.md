---
phase: 127-installer-against-a-real-host
plan: 06
subsystem: installer
tags: [phoenix-config, oidc-scopes, heex, tag-engine, phx-gen-auth]

# Dependency graph
requires:
  - phase: 127-installer-against-a-real-host
    provides: "127-01's install_generator_test.exs config/resolver assertion baseline; 127-05's install_template_compile_test.exs fast-lane compile-fence module this plan extends"
provides:
  - "priv/templates/lockspire.install/config.exs emits a mount-path-consistent issuer, a known_scopes vocabulary (openid/email/profile), signing_alg, and a self-describing secret_key_base placeholder -- a stock import now boots instead of raising at policy validation"
  - "priv/templates/lockspire.install/account_resolver.ex redirects login to /users/log-in (the real Phoenix 1.8 phx.gen.auth --live default) with change-me comments on both the login and logout redirect clauses"
  - "priv/templates/lockspire.install/authorized_apps/index.html.heex's list-item element id uses Elixir string interpolation instead of a nested EEx tag inside a HEEx attribute expression, so the generated host compiles"
  - "test/integration/install_template_compile_test.exs gained a HEEx compile fence over every generated .heex destination via Phoenix.LiveView.TagEngine.compile/2, proven fail-first against the pre-fix authorized-apps shape"
affects: [router-template-macro, install-instructions, plan-then-apply-conflict-semantics]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phoenix.LiveView.TagEngine.compile/2 (not EEx.compile_string(engine: TagEngine), which is deprecated on LV 1.2.8 and would trip mix qa's warnings-as-errors) as the fast-lane, no-host regression fence for every generated .heex destination -- filtered from Install.rendered_templates/1 by Path.extname"
    - "Self-describing placeholder tokens (containing REPLACE or GENERATE) as the escape hatch from a length-only secret-literal fence: grep -Eo '[A-Za-z0-9+/=_-]{32,}' | grep -Ev 'REPLACE|GENERATE' catches any unlabeled 32+ character run without a second entropy heuristic"

key-files:
  created: []
  modified:
    - priv/templates/lockspire.install/config.exs
    - priv/templates/lockspire.install/account_resolver.ex
    - priv/templates/lockspire.install/authorized_apps/index.html.heex
    - test/integration/install_generator_test.exs
    - test/integration/install_template_compile_test.exs

key-decisions:
  - "Wrote the login change-me comment as a single line rather than wrapped across two comment lines, so a single =~ substring assertion could prove both the phx.gen.auth attribution and the change-me instruction without needing a multi-line regex."
  - "Chose 'REPLACE_ME_WITH_A_MIX_PHX_GEN_SECRET_VALUE' as the secret_key_base placeholder -- self-describing, names the exact remedy (mix phx.gen.secret), and its single 32+ character run contains REPLACE so it passes the length-only secret-literal fence by design rather than by accident."
  - "Added known_scopes: [\"openid\", \"email\", \"profile\"] (including openid, matching the adoption demo's own precedent) rather than only the two non-implicit scopes, since AuthorizationRequest.unknown_scope?/1 already special-cases openid as always-known regardless of the vocabulary -- listing it explicitly costs nothing and matches the one working reference config in the repo."
  - "Added a new test asserting issuer consistency under a custom --mount-path value (not just the default /lockspire), since the plan's behavior spec explicitly named both the default and a custom mount path as in-scope."

requirements-completed: [INSTALL-01]

coverage:
  - id: D1
    description: "The generated config's issuer includes the mount path (default and custom), so an adopter who imports it does not hit a path-mismatch boot failure"
    requirement: "INSTALL-01"
    verification:
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install writes the host-owned integration files (issuer/mount-path assertions)"
        status: pass
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install renders a mount-path-consistent issuer for a custom mount path"
        status: pass
    human_judgment: false
  - id: D2
    description: "The generated config declares known_scopes, signing_alg, and a self-describing secret_key_base placeholder, with a security fence proving no secret literal ships"
    requirement: "INSTALL-01"
    verification:
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install writes the host-owned integration files (known_scopes/signing_alg/secret_key_base assertions)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The generated resolver's login redirect matches a real phx.gen.auth --live host route and both redirect clauses carry change-me instructions"
    requirement: "INSTALL-01"
    verification:
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install writes the host-owned integration files (login_path assertions)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every generated HEEx template compiles under the LiveView tag engine, proven fail-first against the known-bad nested-EEx-in-attribute shape"
    requirement: "INSTALL-01"
    verification:
      - kind: unit
        ref: "test/integration/install_template_compile_test.exs#every generated .heex template compiles under the LiveView tag engine"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 06: Installer Against A Real Host Summary

**Closed ADOPT-D04, ADOPT-D09, and ADOPT-D16: the generated config now boots (mount-path-consistent issuer, scope vocabulary, signing algorithm, self-describing secret placeholder), the resolver redirects to a route a real `phx.gen.auth --live` host actually has, and a fast-lane compile fence proves every generated `.heex` compiles under the LiveView tag engine.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-29T16:37:12Z
- **Tasks:** 3 completed
- **Files modified:** 5 (0 created, 5 modified)

## Accomplishments

- Closed ADOPT-D04: the config template's `issuer` used to be a bare `"https://example.com"`, which fails Lockspire's own issuer/mount-path consistency check in `lib/lockspire/security/policy.ex:104-106` -- a stock import raised at boot before an adopter ever reached a real misconfiguration. The issuer now interpolates `<%= @mount_path %>`, proven for both the default `/lockspire` mount path and a custom one supplied via `--mount-path`.
- Added the three keys the config template was silently missing: `known_scopes: ["openid", "email", "profile"]` (without it `AuthorizationRequest` rejected every scope except `openid`), `signing_alg: "RS256"`, and `secret_key_base` as an obvious, self-describing placeholder (`REPLACE_ME_WITH_A_MIX_PHX_GEN_SECRET_VALUE`) that the library cannot infer on its own since `Config.inferred_secret_key_base/0` only scans the `:lockspire` app env.
- Enforced the secret-literal fence as a real test assertion, not just a grep in acceptance criteria: `install_generator_test.exs` now scans the rendered config for any run of 32+ hex/base64url characters and asserts every such run names its own replacement (`REPLACE`/`GENERATE`), so a future accidental literal fails the suite.
- Closed ADOPT-D09: the generated resolver's login redirect now points at `/users/log-in`, Phoenix 1.8's real `phx.gen.auth --live` default, with an explicit change-me comment. Extended the same treatment to the sibling logout clause's hardcoded path in the same edit, since leaving one documented and the other silent would be inconsistent.
- Closed ADOPT-D16 at the source: the authorized-apps HEEx list item nested an EEx tag inside a HEEx attribute expression (`id={"authorized-app-<%%= consent.grant.id %>"}`), which the resolved LiveView tokenizer rejects outright -- a generated host failed to compile immediately after install, before any router/config/resolver wiring was ever exercised. Replaced with Elixir string interpolation inside the attribute's braces (`id={"authorized-app-#{consent.grant.id}"}`), which passes through the render pass unchanged and preserves the sibling lines' doubled-percent escaping convention.
- Closed ADOPT-D16 as a class, not a one-off: added a HEEx compile fence to `install_template_compile_test.exs` that drives `Install.rendered_templates/1`, filters to `.heex` destinations, and compiles each rendered body with `Phoenix.LiveView.TagEngine.compile/2` (not the deprecated `EEx.compile_string(engine: TagEngine)` route, which would trip `mix qa`'s warnings-as-errors). Asserted the filtered set is non-empty first so the fence cannot silently pass over zero templates. Ran the fence fail-first: reverted the authorized-apps fix via `Edit` (not git), reran the test, confirmed it reproduced the real `Phoenix.LiveView.TagEngine.Tokenizer.ParseError` at the exact known-bad line, then restored the fix and reconfirmed green.

## Task Commits

1. **Task 1: Make the generated config boot** (TDD) - `5441652` (feat)
2. **Task 2: Fix the resolver login path and the HEEx attribute interpolation** (TDD) - `9dd6d51` (feat)
3. **Task 3: Fence every generated HEEx template through the LiveView tag engine** (TDD) - `13b8a30` (feat)

_Note: all three tasks carried `tdd="true"`, but each was a single-commit red/green cycle run and verified locally rather than split into separate `test`/`feat` commits -- for Tasks 1 and 2 the RED state was proven by running the relevant assertions against the pre-fix template and confirming failure before implementing, and for Task 3 the RED state was proven via the fail-first revert-and-rerun documented above. No separate `test(...)` commit was created; the finished, verified state landed as a single `feat(...)` commit per task, consistent with how 127-01 and 127-05 handled equivalent single-pass TDD tasks._

## Files Created/Modified

- `priv/templates/lockspire.install/config.exs` - mount-path-consistent issuer, `known_scopes`, `signing_alg`, self-describing `secret_key_base` placeholder, change-me comments on each new key
- `priv/templates/lockspire.install/account_resolver.ex` - login redirect changed to `/users/log-in`, change-me comments on both login and logout redirect clauses
- `priv/templates/lockspire.install/authorized_apps/index.html.heex` - list-item element id uses Elixir string interpolation instead of a nested EEx tag in a HEEx attribute expression
- `test/integration/install_generator_test.exs` - extended config assertions (issuer, known_scopes, signing_alg, secret placeholder, secret-literal negative fence), a new custom-mount-path issuer test, and extended resolver assertions (login path, both change-me comments)
- `test/integration/install_template_compile_test.exs` - new HEEx compile fence over every generated `.heex` destination via `Phoenix.LiveView.TagEngine.compile/2`, proven fail-first

## Decisions Made

- Kept the login change-me comment on a single line so a substring assertion could prove both the `phx.gen.auth` attribution and the change-me instruction without a multi-line regex (see key-decisions above).
- Chose a `secret_key_base` placeholder that deliberately trips the length-only secret-literal fence by design (contains `REPLACE`) rather than by luck, and named the exact remedy (`mix phx.gen.secret`) in the accompanying comment.
- Included `openid` explicitly in `known_scopes` even though `AuthorizationRequest.unknown_scope?/1` treats it as always-known regardless of vocabulary, matching the one working `config :lockspire` reference in the repo (`examples/adoption_demo/config/config.exs`).
- Added a dedicated test proving issuer/mount-path consistency under a custom `--mount-path` value, since the plan's behavior spec named both the default and a custom mount path as in-scope and no existing test exercised that combination for the config template.

## Deviations from Plan

None - plan executed exactly as written. All three tasks' acceptance criteria pass as specified; no Rule 1-4 auto-fixes or architectural questions arose during execution.

## Issues Encountered

None beyond the expected TDD iteration: the first version of the login change-me comment (wrapped across two lines) failed a substring assertion that spanned the wrap point; rewritten as a single line and reconfirmed green before proceeding.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ADOPT-D04, ADOPT-D09, and ADOPT-D16 are closed. A stock generated config boots, the resolver's login default matches a real `phx.gen.auth --live` host, and every generated `.heex` is proven to compile fail-first.
- `test/integration/install_template_compile_test.exs` now covers both the router macro (127-05) and every generated `.heex` (this plan) in the fast lane -- the canonical place to extend template-regression proof for any future template change.
- The remaining `127-0N` plans (plan-then-apply conflict semantics, and the point fixes from the Phase 126 ledger not yet addressed) are untouched by this plan.
- No blockers. `mix test test/integration/install_generator_test.exs` (9 tests), `mix test test/integration/install_template_compile_test.exs` (3 tests), `mix test.fast` (1298 tests, 0 failures), and `mix qa` (format, Credo `--strict`, Sobelow, compile) are all green with a clean `git status --porcelain`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 5 created/modified files confirmed present on disk; all 3 task commits (`5441652`, `9dd6d51`, `13b8a30`) confirmed in `git log --oneline --all`.
