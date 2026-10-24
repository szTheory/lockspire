---
status: resolved
resolved_by: parent_delegated_maintainer
human_confirmed: false
trigger: "Diagnose packaged journey AssertionError in PR 138; no product or test edits authorized yet."
created: 2026-10-24T18:10:00Z
updated: 2026-10-24T18:29:44Z
---

## Current Focus

goal: find_root_cause_only; parent subsequently implemented and technically verified the correction
bug_class: bohrbug (hosted and local request fail at the same first authorization boundary)
hypothesis: the clean-room host resolver reads an unfetched Plug session on the public authorization path
test: actual resolver with the exact endpoint Plug.Session state, then the same connection with only fetch_session added
expecting: unfetched callback raises ArgumentError; fetched callback returns the required host login redirect
next_action: parent continues exact-head hosted delivery checks and reconciles final debug closure under maintainer authority; this diagnose-only agent claims no human confirmation
ranked_hypotheses:
  - code/data: DCR metadata or lifetime eligibility is rejected during authorization intake; predicts OAuth validation 4xx at this request.
  - config/code: new host mount/authorization guard intercepts public authorization; predicts 403 or wrong route.
  - environment/config: packaged host policy differs from source tests; predicts request succeeds only under source fixture configuration.
  - data/transport: generated URL/query changes request semantics; predicts a bounded request-validation error.
and_gate: yes; the endpoint installs a session without fetching it, and the host resolver directly reads that unfetched session. Both must occur on the public forward to trigger this crash.
reasoning_checkpoint:
  hypothesis: The clean-room AccountResolver.get_session call raises because the current public forward supplies an unfetched cookie session.
  confirming_evidence:
    - The real package journey repeatedly returns HTTP500 at its first anonymous authorization request after successful discovery and DCR registration.
    - build_provider.write_host_runtime installs Plug.Session, while the generated public forward and Lockspire.Web.Router apply no fetch_session pipeline.
    - The actual unmodified host resolver raises ArgumentError with that exact Plug.Session state; adding only fetch_session to the same conn produces the expected login redirect in0.46seconds.
  falsification_test: A fetched same-conn callback still failing, or the public path fetching the session before this resolver, would refute this explanation.
  fix_rationale: Fetch in the host-owned resolver immediately before its own cookie lookup; this restores that seam without adding browser CSRF to token/DCR endpoints.
  blind_spots: Parent has now completed the full original packaged HTTP regressions locally; the later exact-head hosted delivery checks remain separate. Original server exception was masked by its missing error renderer.
  candidate_causes:
    - code/config: unfetched host session supplied to direct resolver get_session
    - packaging/code: missing module or wrong source package
    - environment: runtime/dependency behavior difference
    - data/transport: invalid encoded authorization metadata
  and_gate: yes; endpoint session installation without fetch and direct resolver session access jointly explain the observed crash.

## Symptoms

expected: Packaged candidate completes registration and S256 authorization-code redemption over HTTP.
actual: Hosted source integration passed, while packaged lifetime journeys fail after provider readiness.
errors: AssertionError, redacted by runner as stage saas_journey/scenario dcr_lifetime; no durable raw secret-bearing diagnostics permitted.
reproduction: test/integration/client_lifetime_packaged_journey_test.exs:9 and :102 with lifetime_package included.
started: Current cumulative PR 138 CI at head ae78be8c07e0e3df5b1dd2e156b72758df607798.

## Eliminated

- Normal OAuth request/client validation rejection: repeat returned HTTP 500, not the predicted validation 4xx.
- Simple host guard denial or wrong route: repeat returned HTTP 500, not predicted 403/404.

## Evidence

- The named reproduction `mix test --include lifetime_package test/integration/client_lifetime_packaged_journey_test.exs:9` ran in 32.5 seconds: 1 test, 1 failure, 1 excluded. It used the task-owned cache and database with exception-location-only instrumentation.
- The temporary trace identified `require_status` line 141, `run_dcr_lifetime` line 514, `main` line 1506. Line 514 expects HTTP 302 for the authorization request. Discovery HTTP 200 and DCR registration HTTP 201 assertions preceding it succeeded.
- First repro completed; its provider/database/run-root cleanup terminated before further probes. No production/test files changed.
- SBFL skipped: no per-test server/Python coverage spectrum is available for this external process seam. Exception localization provides the precise failing boundary.
- Existing knowledge-base entries concern finalizer/proof labels and do not match this HTTP assertion. No matching prior resolution assumed.
- Repeated exact test completed in 27.6 seconds with 1 test/1 failure. Numeric-only probe observed expected_http=302 actual_http=500 at the same request. All owned resources terminated; parent notified.
- Candidate causes now branch across code/config (host seam exception), packaging/code (missing runtime module), and environment (runtime/dependency behavior); no root cause collapsed yet.
- Third exact run again failed HTTP500. Structural-only provider-log extraction found ArgumentError in Phoenix.Template.render_with_fallback/4, render_to_iodata/4, Controller.render_and_send/4 and Endpoint.RenderErrors: the error renderer masks the original server exception. No raw message, arguments, headers or response body was retained by the diagnostic hook.
- Minimal command: `LOCKSPIRE_TEST_DB_NAME=lockspire_171_delivery_20261024a ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix run /tmp/lockspire-171-package-debug-session.exs`. Exit0 in0.46seconds printed only `unfetched_exception=ArgumentError` and `fetched_outcome=login_redirect`. The throwaway script compiles the actual host Accounts/AccountResolver sources and uses Plug.Session's real cookie store.
- The maintained demo resolver reads current-account assigns rather than calling get_session; the clean-room fixture uniquely performs this direct unfetched read. The generated public forward has no host browser pipeline; routing all protocol endpoints through browser CSRF would be an incorrect repair.
- All three real repro subprocesses terminated, including their owned provider/database/run-root cleanup. Parent notified that source changes may resume. Debug hooks remain only in owned /tmp paths and were never added to production/test source.
- Parent implemented commit `4fcb74864339006e87946f463cec5bd1a508ee30` (`fix(proof): preserve host session and legacy admin seams`). The host resolver fetches its endpoint session before reading it. The host router overlay also restores its legacy `require_operator` pipeline using the existing deny-all Plug, addressing the independently diagnosed old-package compilation failure.
- Parent's new real-resolver regression first failed with `session not fetched`, then passed with the fixture correction: two clean-room integration tests, zero failures. The oracle follows Plug's session contract and the host resolver's existing guest/authenticated outcomes; it does not choose a new protocol or security policy.
- The actual old-package router-template/current-overlay compilation now passes with marker `OLD_PROVIDER_ROUTER_COMPILES`. Strict Credo reports zero issues.
- Parent reran the original complete package-path regressions at frozen commit `4fcb7486`: `CLEAN_ROOM_CACHE_ROOT=/tmp/lockspire-171-package-debug-cache LOCKSPIRE_TEST_DB_NAME=lockspire_171_delivery_20261024a ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test --include lifetime_package test/integration/client_lifetime_packaged_journey_test.exs test/integration/app_lifetime_packaged_upgrade_test.exs`. Exit zero in244.7seconds: three tests, zero failures. This includes fresh, custom-adapter and legacy upgrade package journeys.
- Parent confirms those original regression wrappers completed owned process/database/root cleanup. No raw diagnostic material or temporary debug hook was added to repository source. This update records parent-provided execution evidence and runs no further tests or code changes.

## Resolution

root_cause: The clean-room host AccountResolver calls Plug.Conn.get_session on a connection whose endpoint only installed Plug.Session; the current public protocol forward never fetched it. Plug raises ArgumentError before account resolution. A missing host error view masks that original exception as an error-renderer HTTP500.
fix: Implemented by parent in4fcb7486 — fetch the session in the host-owned resolver immediately before get_session; restore the old package's host-owned require_operator pipeline using the existing deny-all Plug. Token/DCR routes gain no browser CSRF, and library runtime/generator behavior is unchanged.
oracle_type: derived (Plug session contract and existing host callback outcomes)
verification: Original named RED runs failed in32.5s/27.6s; minimal callback RED/GREEN counterfactual completed in0.46s. Parent's real-resolver regression went RED then GREEN (two tests, zero failures); old-package router compile passed; strict Credo passed; full original packaged regressions at4fcb7486 passed in244.7seconds (three tests, zero failures).
technical_verdict: verified_by_parent
human_confirmation: not requested or claimed by this diagnose-only agent; debugger role requires that confirmation before formal resolved/archive transition
files_changed:
  - test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex
  - test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs
  - test/lockspire/clean_room_admin_integration_test.exs

## Parent closure decision

The maintainer explicitly delegated unblocking and following the synthesized
recommendations to this run. The parent closes the technical bug under that
authority after the actual callback RED/GREEN proof and all three original
packaged regressions passed at source `4fcb7486` (244.7 seconds, zero failures).
The debugger's prior `awaiting_human_verify` handoff is retained here as history.
No human confirmation was performed or inferred; this is automated technical
verification and delegated maintainer closure, not a subjective UI approval.
Fresh exact-head PR checks and exact-main acceptance remain separate gates.
