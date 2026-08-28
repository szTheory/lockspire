---
phase: 133-clean-room-saas-journey
reviewed: 2026-08-27T00:00:00Z
depth: deep
files_reviewed: 45
files_reviewed_list:
  - .github/workflows/ci.yml
  - lib/lockspire/generators/install.ex
  - lib/lockspire/install/assets.ex
  - lib/lockspire/install/migrations.ex
  - mix.exs
  - priv/templates/lockspire.install/authorized_apps/index.html.heex
  - scripts/acceptance/clean_room/build_client.py
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room/package_input.py
  - scripts/acceptance/clean_room/processes.py
  - scripts/acceptance/clean_room/redaction.py
  - scripts/acceptance/clean_room_saas_journey.py
  - scripts/acceptance/run_clean_room_saas_journey.sh
  - scripts/ci/run_test_matrix.sh
  - test/clean_room/confidential_client/config/config.exs
  - test/clean_room/confidential_client/lib/clean_room_client/application.ex
  - test/clean_room/confidential_client/lib/clean_room_client/dpop.ex
  - test/clean_room/confidential_client/lib/clean_room_client/dpop_session.ex
  - test/clean_room/confidential_client/lib/clean_room_client/oauth_http.ex
  - test/clean_room/confidential_client/lib/clean_room_client/oauth_transaction.ex
  - test/clean_room/confidential_client/lib/clean_room_client/oidc_verifier.ex
  - test/clean_room/confidential_client/lib/clean_room_client/repo.ex
  - test/clean_room/confidential_client/lib/clean_room_client/transactions.ex
  - test/clean_room/confidential_client/lib/clean_room_client_web/controllers/journey_controller.ex
  - test/clean_room/confidential_client/lib/clean_room_client_web/controllers/oauth_controller.ex
  - test/clean_room/confidential_client/lib/clean_room_client_web/endpoint.ex
  - test/clean_room/confidential_client/lib/clean_room_client_web/router.ex
  - test/clean_room/confidential_client/mix.exs
  - test/clean_room/confidential_client/priv/repo/migrations/20260827000000_create_oauth_transactions.exs
  - test/clean_room/confidential_client/test/dpop_client_test.exs
  - test/clean_room/confidential_client/test/oauth_transaction_test.exs
  - test/clean_room/confidential_client/test/test_helper.exs
  - test/clean_room/provider_host/lib/clean_room_provider/accounts.ex
  - test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex
  - test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex
  - test/clean_room/provider_host/lib/clean_room_provider/lockspire/interaction_handler.ex
  - test/clean_room/provider_host/lib/clean_room_provider_web/controllers/billing_controller.ex
  - test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex
  - test/clean_room/provider_host/lib/clean_room_provider_web/operator_authorization.ex
  - test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs
  - test/clean_room/provider_host/mix.exs
  - test/integration/phase133_clean_room_saas_journey_test.exs
  - test/integration/phase133_harness_test.exs
  - test/integration/phase133_provider_install_test.exs
findings:
  critical: 5
  warning: 3
  info: 0
  total: 8
status: resolved
resolved: 2026-08-27T00:00:00Z
---

# Phase 133: Code Review Report

**Reviewed:** 2026-08-27T00:00:00Z
**Depth:** deep
**Files Reviewed:** 45
**Status:** resolved

## Summary

Phase 133 establishes useful package-provenance, OIDC, lifecycle, and DPoP acceptance pieces, but the submitted implementation does not meet its own E2E-01/E2E-06 operational contract. The actual CI path cannot authenticate to its configured PostgreSQL service, concurrent real journey runs compete for fixed ports, and TERM/INT does not execute journey teardown. There are also security defects in the reference provider login UI and acceptance endpoints. These findings block treating this as prime-time, package-clean E2E evidence.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Clean-room CI uses PostgreSQL credentials that its service does not create

**File:** `.github/workflows/ci.yml:249-266`; `scripts/acceptance/clean_room_saas_journey.py:584-587`

**Issue:** The integration service is initialized with only the `lockspire` role/password, while the actual clean-room runner hard-codes `postgres:postgres` for both child databases. It also runs `pg_isready -q` with no host, user, or database in `probe_environment`. In GitHub Actions the runner account is not the configured PostgreSQL role and the hard-coded `postgres` role/password are not supplied by this service configuration. Consequently `mix test.clean-room.e2e` fails before it can provide the required CI proof.

**Fix:** Build both child URLs from explicit clean-room DB environment variables and pass those variables in the integration job, for example `CLEAN_ROOM_DB_USER=lockspire`, `CLEAN_ROOM_DB_PASSWORD=lockspire`, `CLEAN_ROOM_DB_HOST=127.0.0.1`, and `CLEAN_ROOM_DB_PORT=5432`. Make `probe_environment` call `pg_isready` with the same explicit connection inputs. Keep local defaults only where they match the documented local service.

### CR-02: The real journey violates the required concurrent-origin isolation

**File:** `scripts/acceptance/clean_room_saas_journey.py:44-45,164-175,584-605`; `test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex:4-7`; `test/clean_room/confidential_client/lib/clean_room_client_web/controllers/journey_controller.ex:7`

**Issue:** The real provider/client journey is hard-wired to ports 4100 and 4101 in its origins, child environment, client configuration, registered redirect URIs, resources, and protected resource URL. A second invocation cannot boot while one is live; it either collides with a listener or accidentally speaks to the other run. The separate probe supervisor allocates ports, but the full runner never uses it. This directly contradicts D-01 and makes the claimed clean-room evidence unsafe under parallel CI or local test execution.

**Fix:** Allocate the two ports once per run before provisioning, derive provider/client origins from those values, and pass them through all provider bootstrap, client config, registered redirect/resource metadata, browser helpers, and DPoP `htu` construction. Add an integration test that runs two actual journey processes concurrently (not the probe-only supervisor) and asserts both complete and clean up.

### CR-03: Signal interruption leaks live processes, databases, and run roots

**File:** `scripts/acceptance/clean_room_saas_journey.py:576-630`; `mix.exs:89-91`

**Issue:** The maintained command invoked by CI is the Python runner directly. It has a `finally` for ordinary exceptions but no SIGTERM/SIGINT handlers. Python's default SIGTERM action terminates the process without unwinding the `try/finally`, leaving provider/client BEAM processes and generated databases behind. The shell wrapper has traps, but is only used for the probe harness and does not supervise the real Phoenix journey. This fails the explicit cleanup-on-signal requirement in E2E-01/D-04 and can contaminate later CI work.

**Fix:** Install signal handlers that convert TERM/INT into a controlled exception or termination flag and always run `stop_process` plus database teardown; alternatively make the maintained alias invoke a trap-owning wrapper that starts the Python runner in a managed process group and explicitly reaps all descendants. Test TERM against an in-flight full journey and verify both PIDs, databases, and temporary root are gone.

### CR-04: Provider login reflects attacker-controlled query values into HTML without escaping

**File:** `test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex:6-14`

**Issue:** `return_to` and `interaction_id` are read directly from query params and string-interpolated into HTML attribute values. A request such as `/login?return_to=\"%3E<script>...</script>` is reflected in the response and executes in the provider origin. This fixture is the reference package-clean host used to demonstrate operator/provider behavior, so it must not normalize an XSS-prone host seam.

**Fix:** Render an HEEx template/component and pass assigns so Phoenix escapes values, or escape every attribute value with the framework's HTML escaping function. Better, do not trust `return_to` from the browser at all: resolve the interaction server-side and allow only the known interaction route.

### CR-05: Provider login has a protocol-relative open redirect

**File:** `test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex:23-27`

**Issue:** `resume/1` accepts every string beginning with `/`; that includes `//attacker.example`. Phoenix will emit that as a protocol-relative `Location`, sending a successfully authenticated provider user to an attacker-controlled origin. An attacker can obtain a valid CSRF token through the reflected login form and submit the hostile `return_to`, so the check does not make this safe.

**Fix:** Never redirect from arbitrary request `return_to`. Prefer the server-side interaction ID mapping. If a fallback path is truly necessary, parse it and require a single leading slash, no authority/scheme, and a route allowlist; explicitly reject strings beginning with `//` or containing a scheme.

## Warnings

### WR-01: Acceptance endpoints permit cross-site state changes without CSRF protection

**File:** `test/clean_room/confidential_client/lib/clean_room_client_web/router.ex:5-34`; `test/clean_room/confidential_client/lib/clean_room_client_web/endpoint.ex:5-12`

**Issue:** The client browser pipeline only fetches the session. Every POST acceptance endpoint is reachable with the victim's cookie and no CSRF check. A third-party origin can trigger resource nonce storage, consume the recorded replay proof, or replace a pending transaction nonce, yielding a user-visible denial of the in-flight OAuth/DPoP journey. Although endpoints are fixture-scoped, this is executable host code and weakens the security claim it is intended to prove.

**Fix:** Add `plug :protect_from_forgery` to the browser pipeline and have the runner obtain/send the CSRF token, or isolate these deliberately test-only mutation hooks behind a strict ephemeral capability unavailable to cross-site requests.

### WR-02: Redaction checks synthetic strings, not the secrets generated by the journey

**File:** `scripts/acceptance/clean_room/redaction.py:14-96`; `scripts/acceptance/clean_room_saas_journey.py:190-213,350,407`

**Issue:** The redactor only recognizes random synthetic sentinel values. The actual client secrets, authorization codes, tokens, PKCE verifiers, cookies, DPoP proofs, and private keys are never registered with it. `scan_evidence` therefore detects only raw Authorization/Cookie labels and synthetic sentinel leakage; a real token in a URL, body, exception, or retained log passes the scan. The ExUnit assertions repeat the same synthetic-sentinel check, so they cannot prove D-17's real evidence-redaction guarantee.

**Fix:** Register every dynamically generated sensitive value with the per-run redactor at creation/handoff (or maintain strict structural allowlists that never retain bodies/query strings). Scan all retained evidence and console-rendered diagnostics against those real values, and add an induced failure whose generated secret would be exposed unless redacted.

### WR-03: The integration lane executes the expensive clean-room proof twice

**File:** `scripts/ci/run_test_matrix.sh:57-60`; `test/integration/phase133_clean_room_saas_journey_test.exs:9-90`

**Issue:** `mix test.integration` includes all `@moduletag :integration` Phase 133 tests; each of the five tests invokes the clean-room Python runner. The matrix then invokes `mix test.clean-room.e2e`, which runs all groups again. This contradicts the plan's single named CI invocation, increases failure/flakiness surface, and masks the intended alias as the authoritative full journey.

**Fix:** Make the regular integration suite exercise small, cheap harness/unit contracts only and exclude the full journey tests from `test.integration`, or remove the post-suite alias and have a single explicitly tagged test/command execute it. Preserve one clearly authoritative full clean-room invocation in CI.

---

## Resolution Evidence

All five blockers and three warnings were addressed without weakening the
package-clean acceptance boundary:

- **CR-01:** the runner and preflight now use `CLEAN_ROOM_DB_*` consistently;
  the integration workflow supplies the `lockspire` service role (`63246c5`).
- **CR-02:** each real journey allocates its own provider/client ports and
  threads those origins through issuer, registrations, resources, and DPoP;
  the skipped-on-default stress test exercises two full journeys concurrently
  (`df8370b`).
- **CR-03:** SIGINT/SIGTERM raise a controlled interruption, child process
  groups are reaped, and the runner's signal probe verifies teardown (`df8370b`).
- **CR-04 / CR-05:** provider login escapes all rendered values, no longer
  trusts `return_to`, and URI-encodes the server-side interaction route
  (`bb91670`).
- **WR-01:** browser mutation routes use Phoenix CSRF protection; the runner
  proves an un-tokened mutation is rejected before using a session-bound token
  (`26d5e0c`).
- **WR-02:** dynamically generated client secrets, callback codes, PKCE
  verifiers, cookies, and token payload values are registered before evidence
  is retained; logs are redacted in place and an induced real-secret check is
  part of the run (`df8370b`, `d807c36`).
- **WR-03:** the expensive ExUnit wrapper is skipped from normal/`integration`
  partitions, leaving `mix test.clean-room.e2e` as the single CI proof
  (`832de94`, `a93e42a`).

Targeted verification: Python AST checks passed for the runner/redactor and
package preflight; `mix format --check-formatted` passed for all touched Elixir
fixtures; `python3 scripts/acceptance/clean_room/redaction.py --self-test`
passed; a real dynamic-origin happy-path run reached all receipt milestones and
cleanup after the retained-evidence correction.

_Reviewed: 2026-08-27T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
