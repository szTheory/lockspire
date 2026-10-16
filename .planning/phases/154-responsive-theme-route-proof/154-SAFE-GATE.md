# Phase 154 SAFE-01 Regression Gate

These commands ran from `/Users/jon/projects/lockspire` on 2026-10-16 against source `3e31d4010276b98bfcad8b05e9e0fa8fea0d1bed` (last source commit `3e31d401`), the frozen post-review source the final captures came from. Mix commands used `HEX_HOME=/private/tmp/lockspire-hex MIX_ENV=test ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1`. Plan 07 edited no source, and every command passed on its first run.

**History:** the first gate ran on 2026-10-15 against `dc4257f2` (last source commit `d3b2fec2`): 518 passed in (a), 1554 passed and 6 skipped in (b), 15 node tests in (f). The code-review and UI-review fixes since then added tests, so this re-run reports higher counts. Logs: `tmp/safe-gate/a.log`, `tmp/safe-gate/b.log`, `tmp/compile-final.log`.

## Command outcomes

| Step | Command | Exit | Summary |
|---|---|---|---|
| (a) | `mix test test/lockspire/web/live/admin test/lockspire/web/admin_router_test.exs test/lockspire/redaction test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/clients_test.exs test/lockspire/admin test/lockspire/architecture_fitness_test.exs test/lockspire/adoption_demo_docker_contract_test.exs test/lockspire/web/revocation_controller_test.exs test/lockspire/web/token_controller_test.exs test/lockspire/ci_workflow_evidence_contract_test.exs` | 0 | `Result: 537 passed` (0 failures) |
| (b) | `mix test.fast` | 0 | `Result: 1573 passed, 6 skipped, 286 excluded` (matches the post-review baseline of 1573 passed, 6 skipped) |
| (c) | `mix format --check-formatted` | 0 | clean |
| (d) | `git diff --check ef6043ec` | 0 | clean (the first gate's trailing-blank-line fix in `dc4257f2` still holds) |
| (e) | `mix compile --force` (output saved to `tmp/compile-final.log`) | 0 | 317 files. 0 warnings name a file under `lib/lockspire/web/`; the observations are listed below. |
| (f) | `node --test test/browser/admin_multi_value_test.mjs test/browser/admin_route_proof_test.mjs` | 0 | `# tests 27`, `# pass 27`, `# fail 0` |
| (g) | v1.42 allowlist: `git diff --numstat e67a4898 -- lib/lockspire/protocol lib/lockspire/storage lib/lockspire/security lib/lockspire/domain mix.exs mix.lock` plus line checks on `git diff -U0` | 0 | exactly `1 1 message_signing_profile.ex`, `0 1 mix.exs`, `0 2 mix.lock`; removed and added lines match g1-g3 below |
| (h) | phase-local: `git diff --stat ef6043ec -- lib/lockspire/protocol lib/lockspire/storage lib/lockspire/security lib/lockspire/domain mix.exs mix.lock` | 0 | empty |
| (i) | `! rg -n "BEGIN [A-Z ]*PRIVATE KEY" .planning/phases/154-responsive-theme-route-proof/ tmp/admin-ui-polish/v1.42/final/ --glob '!*.png' --glob '!*-PLAN.md' --glob '!*-RESEARCH.md'` | 0 | no matches in the evidence docs, the sweep doc, the matrix logs, or the observation and capture JSON |
| (j) | `grep -n "test/browser/" .github/workflows/ci.yml`; `grep -cE 'agent-browser\|admin_route_proof' .github/workflows/ci.yml` | 0 | exactly one line (161: `node --test test/browser/admin_multi_value_test.mjs`). 0 references to the capture harness, its test, or the browser CLI (D-05). |

## Known v1.42 deltas (allowlist for step g)

| ID | File | Change | Commit | SAFE-01 justification |
|---|---|---|---|---|
| g1 | `mix.exs` | removes only `{:bandit, "~> 1.11"},` | `d44b95dd` (PR #123) | Lockspire stops shipping Bandit as a runtime dependency. This clears EEF-CVE-2026-105659; the library never starts an HTTP server. It removes a dependency rather than adding one. |
| g2 | `mix.lock` | removes only the `"bandit"` and `"thousand_island"` entries | `d44b95dd` (PR #123) | Lockfile consequence of g1. |
| g3 | `lib/lockspire/protocol/message_signing_profile.ex` | one remediation string: "ES256 or PS256 issuer signing key" becomes "ES256 or PS256 Lockspire signing key" | `d44b95dd` (PR #123) | Copy only. No protocol behavior changes. |

Nothing else under protocol, storage, security, domain, `mix.exs`, or `mix.lock` changed since `e67a4898`. Nothing changed there since the phase-154 planning commit `ef6043ec`.

## Compile observations (D-04: not fixed here)

All are outside `lib/lockspire/web/` and predate this phase:

- `lib/lockspire/admin/clients.ex:671`: unused clause of `profile_detail/1`
- `lib/lockspire/protocol/authorization_request.ex:688`: unused clause of `ensure_authorization_details_shape/2`
- `lib/lockspire/protocol/authorization_request.ex:727`: redundant `nil ->` clause in `normalize_authorization_detail/4` (type warning)
- `lib/lockspire/protocol/client_auth.ex:187`: clause `{:error, :unsupported_token_endpoint_auth_method}` never matches (type warning)
- `lib/lockspire/redaction.ex:269-270`: redundant `normalize_scalar/1` clauses

## Invariant to assertion map

| Invariant | Asserted by |
|---|---|
| PKCE S256, exact redirect match, no implicit flow, no `alg=none` | `test/lockspire/protocol/authorization_request_test.exs`, `token_controller_test.exs` (a), plus the empty protocol diff (h) |
| Refresh rotation with family-wide revocation on reuse | `test/lockspire/protocol/refresh_exchange_test.exs` (a) |
| Revocation scope (token, consent grant, setup token) | `test/lockspire/protocol/revocation_test.exs`, `web/revocation_controller_test.exs`, admin LiveView tests (a) |
| Client secrets hashed at rest; copy-once secret display | `test/lockspire/clients_test.exs`, admin LiveView rotate tests (a) |
| Redaction in logs and operator surfaces | `test/lockspire/redaction`, admin LiveView redaction tests (a); harness denylist plus `BrowserEvidence.parse!/1` on 928 rows; (i) |
| Read-only support queues (interactions, device authorizations, sign-out notices) | admin LiveView tests (a) |
| Host ownership and module boundaries | `architecture_fitness_test.exs`, `adoption_demo_docker_contract_test.exs` (a) |
| No new dependencies | (g) and (h) |
| Browser capture stays out of CI | `ci_workflow_evidence_contract_test.exs` (a) and (j) |
| No private key material in evidence | (i); key pages show public metadata only (eye review in `154-FINAL-CAPTURES.md`) |
