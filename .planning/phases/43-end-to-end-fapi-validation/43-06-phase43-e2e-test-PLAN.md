---
phase: 43-end-to-end-fapi-validation
plan: 06
type: execute
wave: 2
depends_on: [43-01-iss-emission, 43-02-discovery-keys]
files_modified:
  - test/integration/phase43_fapi_milestone_e2e_test.exs
autonomous: true
requirements: [FAPI-05, FAPI-06]
must_haves:
  truths:
    - "A new file test/integration/phase43_fapi_milestone_e2e_test.exs exists (D-10) — phase41 file is left untouched"
    - "Test (a): zero-tolerance redirect-URI rejection across /authorize, /par, /token, /end_session for trailing slash and query drift (D-11, FAPI-05)"
    - "Test (b): iss= appended on success, denial, and validation-error redirects (D-11, FAPI-06)"
    - "Test (c): discovery published correctly under both :none and :fapi_2_0_security global modes (D-11, D-08)"
    - "Test (c) asserts conditional require_pushed_authorization_requests key flips correctly (absent under :none, true under :fapi_2_0_security)"
    - "All redirect-rejection assertions pin the LITERAL error description / OAuth error code emitted by the corresponding source seam — no disjunctive substring matches that let wrong-reason rejections pass"
  artifacts:
    - path: "test/integration/phase43_fapi_milestone_e2e_test.exs"
      provides: "Phase 43 E2E proof for FAPI-05 + FAPI-06"
      contains: "Phase43FapiMilestoneE2ETest"
    - path: "test/integration/phase41_fapi_2_0_e2e_test.exs"
      provides: "PRESERVED untouched per D-10 — phase 41 evidence stays clean"
      contains: "Phase41Fapi20E2ETest"
  key_links:
    - from: "phase43_fapi_milestone_e2e_test.exs (redirect rejection tests)"
      to: "Lockspire.Web.Router via build_conn + Router.call"
      via: "exercises authorization_request.ex:236-247 + token_exchange.ex:366-378 + end_session.ex:145-170"
      pattern: "Lockspire\\.Web\\.Router\\.call"
    - from: "phase43_fapi_milestone_e2e_test.exs (iss tests)"
      to: "Plan 01 outputs in authorization_flow.ex + authorize_controller.ex"
      via: "asserts URI.decode_query of Location header contains iss key"
      pattern: "URI\\.decode_query.*iss"
    - from: "phase43_fapi_milestone_e2e_test.exs (discovery tests)"
      to: "Plan 02 outputs in discovery.ex"
      via: "calls Lockspire.Protocol.Discovery.openid_configuration/0 directly under both profile modes"
      pattern: "Discovery\\.openid_configuration"
---

<objective>
Add a NEW per-phase E2E test file `test/integration/phase43_fapi_milestone_e2e_test.exs` that
provides the executable repo-truth proof for FAPI-05 (zero-tolerance redirect URI matching) and
FAPI-06 (RFC 9207 iss emission + discovery truth). Per D-10, this is a NEW file — Phase 41's
E2E test is preserved untouched as Phase 41 evidence.

Per D-11, the test must cover:
- (a) Zero-tolerance redirect-URI rejection across `/authorize`, `/par`, `/token`, `/end_session`
  for trailing slash AND query drift
- (b) `iss=` appended on success, denial, and validation/protocol error redirects
- (c) Discovery published correctly under BOTH `:none` and `:fapi_2_0_security` global modes,
  asserting the conditional `require_pushed_authorization_requests` key flips correctly

EVERY redirect-rejection assertion pins the LITERAL error description string or OAuth error
code emitted by the corresponding source seam (verified at planning time) — NOT a disjunctive
substring match. This locks wrong-reason regressions out: a future change that rejects with a
different code (e.g., missing scope) fails the assertion.

Purpose: This is THE Phase 43 milestone evidence. Without it, the v1.10 archive has no
executable repo-truth that Lockspire actually enforces FAPI-05 and FAPI-06.

Output: One new test file; ~400-500 lines mirroring the Phase 41 E2E shape but scoped to
Phase 43 obligations only.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md
@.planning/phases/43-end-to-end-fapi-validation/43-RESEARCH.md
@.planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md
@.planning/phases/43-end-to-end-fapi-validation/43-01-iss-emission-PLAN.md
@.planning/phases/43-end-to-end-fapi-validation/43-02-discovery-keys-PLAN.md

<interfaces>
Reference shape: `test/integration/phase41_fapi_2_0_e2e_test.exs` (584 lines).

Key seams the test exercises:
- `Lockspire.Web.Router.call/2` with `build_conn(...)` for HTTP-style assertions
- `Lockspire.Protocol.Discovery.openid_configuration/0` for direct discovery doc inspection
- `Lockspire.Storage.Ecto.Repository.{get_server_policy/0, put_server_policy/1}` for profile flipping
- `Lockspire.Storage.Ecto.Repository.register_client/1` for fixture client setup

VERIFIED literal error descriptions and OAuth error codes (pinned at planning time — DO NOT
change to substring matches; a future regression must fail the test loudly):

- `/authorize` trailing-slash or extra-query redirect_uri:
  - Source: `lib/lockspire/protocol/authorization_request.ex:236-247`
  - OAuth error: `:invalid_request` (atom)
  - Description literal: `"redirect_uri must match a registered URI"`
  - Internal error code: `:invalid_redirect_uri`
  - Behavior: This is `{:browser_error, ...}` (the URI cannot be safely redirected to). The
    response is rendered via `render_browser_error/3` (status 400, content-type text/html, body
    contains the description literal).

- `/par` trailing-slash or extra-query redirect_uri:
  - Same `validate_redirect_uri/2` path as /authorize (with `pushed?: true`).
  - PAR returns a JSON error response. The OAuth error string in the JSON body is
    `"invalid_request"`. The PAR controller serializes the same Error struct as JSON.

- `/token` trailing-slash redirect_uri (during code exchange):
  - Source: `lib/lockspire/protocol/token_exchange.ex:366-378`
  - OAuth error: `"invalid_grant"` (the JSON `error` field)
  - Description literal: `"redirect_uri does not match the issued authorization code"`
  - Internal error code: `:redirect_uri_mismatch`

- `/end_session` trailing-slash or extra-query post_logout_redirect_uri (after String.trim):
  - Source: `lib/lockspire/protocol/end_session.ex:145-163`
  - OAuth error: `:invalid_request` (atom from `invalid_request/2` helper)
  - Description literal: `"post_logout_redirect_uri not registered"`
  - Internal error code: `:unregistered_post_logout_redirect_uri`

- `/authorize` unsupported response_type (used in Task 2 for iss-on-error-redirect proof):
  - Source: `lib/lockspire/protocol/authorization_request.ex:402-415`
  - This takes a `{:redirect_error, ...}` path (redirect_uri is registered), so Lockspire
    302-redirects to the registered URI with `error=` in the query string.
  - OAuth error string in `query["error"]`: `"unsupported_response_type"`
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Create Phase 43 E2E test scaffolding + redirect-URI rejection coverage (D-11a, FAPI-05)</name>
  <files>test/integration/phase43_fapi_milestone_e2e_test.exs</files>
  <read_first>
    - test/integration/phase41_fapi_2_0_e2e_test.exs (entire file — copy module/setup/setup_all/helpers shape; cap reading at first 250 lines if context-tight, then targeted reads for helper definitions)
    - lib/lockspire/protocol/authorization_request.ex (lines 236-247 — pin literal error description for redirect_uri rejection)
    - lib/lockspire/protocol/token_exchange.ex (lines 366-378 — pin literal error description for code-bound redirect mismatch)
    - lib/lockspire/protocol/end_session.ex (lines 145-170 — pin literal error description for post_logout_redirect_uri rejection)
    - lib/lockspire/web/controllers/authorize_controller.ex (lines 129-145 — confirm error.error is the OAuth string passed through unchanged)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-01, D-03, D-10, D-11)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Phase 43 E2E proof" section)
  </read_first>
  <behavior>
    - The new test module is named `Lockspire.Integration.Phase43FapiMilestoneE2ETest` and uses `:integration` moduletag
    - setup_all establishes Application env (issuer, mount_path, repo, account_resolver) — copy phase41 lines 56-67
    - setup checks out a sandbox connection AND registers a fixture client with redirect_uris and post_logout_redirect_uris suitable for negative-path testing
    - Test groupings under D-11(a), each pinning the LITERAL error description from the corresponding source seam:
      1. /authorize trailing-slash redirect_uri -> body contains literal `"redirect_uri must match a registered URI"` (browser_error, status 400)
      2. /authorize extra-query redirect_uri -> same literal
      3. /par trailing-slash redirect_uri -> JSON body has `"error" == "invalid_request"` AND `error_description` contains literal `"redirect_uri must match a registered URI"` (status 400)
      4. /token trailing-slash redirect_uri (during code exchange) -> JSON body has `"error" == "invalid_grant"` AND `"error_description"` contains literal `"redirect_uri does not match the issued authorization code"` (status 400)
      5. /end_session trailing-slash post_logout_redirect_uri (after String.trim) -> body / location contains literal `"post_logout_redirect_uri not registered"`
      6. /end_session post_logout_redirect_uri with extra query param -> same literal
    - For /end_session: also include a positive control test that surrounding whitespace IS tolerated (D-03), to lock the documented behavior. The positive control asserts the response does NOT contain the literal `"post_logout_redirect_uri not registered"`.
  </behavior>
  <action>
    Create `test/integration/phase43_fapi_milestone_e2e_test.exs`. Copy the module-header,
    `GeneratedHostResolver`, `setup_all`, and `setup` blocks from
    `test/integration/phase41_fapi_2_0_e2e_test.exs` (lines 1-93), renaming the module to
    `Lockspire.Integration.Phase43FapiMilestoneE2ETest` and changing the client_id to
    `"phase43-fapi-client"`. Register the client with:
    ```elixir
    redirect_uris: ["https://client.example.com/callback"],
    post_logout_redirect_uris: ["https://client.example.com/post-logout"],
    ```
    Use `secret = "phase43-client-secret"` and the same `pkce_required: true` shape as phase41.

    Then add this test block (Task 1 owns these tests). Note every assertion pins the LITERAL
    error description sourced VERBATIM from the corresponding lib/lockspire/protocol/* file —
    no `or` clauses, no disjunctive substring matches.

    ```elixir
    describe "FAPI-05: zero-tolerance exact-match redirect URIs (D-01, D-03, D-11a)" do
      # Literal pinned from lib/lockspire/protocol/authorization_request.ex:236-247
      @authorize_redirect_mismatch_literal "redirect_uri must match a registered URI"
      # Literal pinned from lib/lockspire/protocol/token_exchange.ex:366-378
      @token_redirect_mismatch_literal "redirect_uri does not match the issued authorization code"
      # Literal pinned from lib/lockspire/protocol/end_session.ex:145-163
      @end_session_unregistered_literal "post_logout_redirect_uri not registered"

      test "/authorize rejects trailing-slash redirect_uri (browser-error, exact literal)", %{client: client} do
        conn =
          build_conn(:get, "/authorize", %{
            "client_id" => client.client_id,
            "response_type" => "code",
            "redirect_uri" => "https://client.example.com/callback/",
            "scope" => "openid",
            "code_challenge" => code_challenge("v1"),
            "code_challenge_method" => "S256"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        # The URI itself can't be safely redirected to -> browser_error path -> status 400 + html body.
        assert conn.status == 400
        assert conn.resp_body =~ @authorize_redirect_mismatch_literal
      end

      test "/authorize rejects redirect_uri with extra query param (browser-error, exact literal)", %{client: client} do
        conn =
          build_conn(:get, "/authorize", %{
            "client_id" => client.client_id,
            "response_type" => "code",
            "redirect_uri" => "https://client.example.com/callback?extra=1",
            "scope" => "openid",
            "code_challenge" => code_challenge("v2"),
            "code_challenge_method" => "S256"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        assert conn.status == 400
        assert conn.resp_body =~ @authorize_redirect_mismatch_literal
      end

      test "/par rejects trailing-slash redirect_uri (JSON error, pinned OAuth code + literal description)", %{client: client, secret: secret} do
        conn =
          build_conn(:post, "/par", %{
            "client_id" => client.client_id,
            "response_type" => "code",
            "redirect_uri" => "https://client.example.com/callback/",
            "scope" => "openid",
            "code_challenge" => code_challenge("v3"),
            "code_challenge_method" => "S256"
          })
          |> put_req_header("authorization", basic_auth(client.client_id, secret))
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        assert conn.status == 400
        body = Jason.decode!(conn.resp_body)
        # PAR serializes the same Error struct as JSON. OAuth error code is "invalid_request"
        # (from `:invalid_request` atom in the browser_error helper); description carries the
        # literal pinned from authorization_request.ex:236-247.
        assert body["error"] == "invalid_request"
        assert body["error_description"] =~ @authorize_redirect_mismatch_literal
      end

      test "/token rejects trailing-slash redirect_uri during code exchange (pinned literal)", %{client: client, secret: secret} do
        code_verifier = "phase43-token-verifier"
        raw_code = "phase43-token-code"

        # Helper from phase41 — copy its create_completed_authorization_code/4 verbatim.
        {:ok, _code} =
          create_completed_authorization_code(client, raw_code, code_verifier,
            account_id: "phase43-fapi-user",
            scopes: ["openid"]
          )

        conn =
          build_conn(:post, "/token", %{
            "grant_type" => "authorization_code",
            "code" => raw_code,
            "redirect_uri" => "https://client.example.com/callback/",
            "code_verifier" => code_verifier
          })
          |> put_req_header("authorization", basic_auth(client.client_id, secret))
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        assert conn.status == 400
        body = Jason.decode!(conn.resp_body)
        # Pinned from token_exchange.ex:366-378 — both OAuth code and description.
        assert body["error"] == "invalid_grant"
        assert body["error_description"] =~ @token_redirect_mismatch_literal
      end

      test "/end_session rejects trailing-slash post_logout_redirect_uri (after String.trim, pinned literal)", %{client: client} do
        conn =
          build_conn(:get, "/end_session", %{
            "client_id" => client.client_id,
            "post_logout_redirect_uri" => "https://client.example.com/post-logout/"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        # end_session may render a browser-error page (no safe redirect target) — assert on
        # the literal description from end_session.ex:159 in whichever surface carries it.
        evidence = (conn |> get_resp_header("location") |> List.first()) || conn.resp_body || ""
        assert evidence =~ @end_session_unregistered_literal
      end

      test "/end_session rejects post_logout_redirect_uri with extra query param (pinned literal)", %{client: client} do
        conn =
          build_conn(:get, "/end_session", %{
            "client_id" => client.client_id,
            "post_logout_redirect_uri" => "https://client.example.com/post-logout?leak=1"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        evidence = (conn |> get_resp_header("location") |> List.first()) || conn.resp_body || ""
        assert evidence =~ @end_session_unregistered_literal
      end

      test "/end_session POSITIVE: surrounding whitespace IS tolerated for post_logout_redirect_uri (D-03)", %{client: client} do
        # D-03: String.trim/1 at end_session.ex:147 is documented behavior. Lock it.
        conn =
          build_conn(:get, "/end_session", %{
            "client_id" => client.client_id,
            "post_logout_redirect_uri" => "  https://client.example.com/post-logout  "
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        # Whitespace-trimmed match should NOT produce the unregistered error literal
        evidence = (conn |> get_resp_header("location") |> List.first()) || conn.resp_body || ""
        refute evidence =~ @end_session_unregistered_literal
      end
    end
    ```

    Copy `code_challenge/1`, `basic_auth/2`, `create_completed_authorization_code/4`, and
    `put_security_profile!/1` helper definitions VERBATIM from phase41 — they are stable utilities.

    Do NOT modify `test/integration/phase41_fapi_2_0_e2e_test.exs` (D-10).

    Note for the executor: if during implementation you discover that one of the literal strings
    above no longer matches the source (e.g., an in-flight refactor renamed a description), DO NOT
    relax the assertion to a substring match. Re-read the source seam, update the literal at the
    top of the describe block, and re-run. Disjunctive matches are explicitly forbidden in this
    test file.
  </action>
  <verify>
    <automated>mix test test/integration/phase43_fapi_milestone_e2e_test.exs --only integration --color</automated>
  </verify>
  <acceptance_criteria>
    - File `test/integration/phase43_fapi_milestone_e2e_test.exs` exists
    - `grep -c "defmodule Lockspire.Integration.Phase43FapiMilestoneE2ETest" test/integration/phase43_fapi_milestone_e2e_test.exs` returns 1
    - `grep -c '@moduletag :integration' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 1
    - `grep -c 'describe "FAPI-05' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 1
    - File contains tests for /authorize, /par, /token, AND /end_session redirect rejection (grep for each path appears at least once with trailing-slash assertion)
    - File contains the positive control test for D-03 (surrounding whitespace IS tolerated for post_logout_redirect_uri)
    - File pins the literal `redirect_uri must match a registered URI` (sourced from authorization_request.ex:236-247) — `grep -c "redirect_uri must match a registered URI" test/integration/phase43_fapi_milestone_e2e_test.exs` returns >= 1
    - File pins the literal `redirect_uri does not match the issued authorization code` (sourced from token_exchange.ex:366-378) — grep returns >= 1
    - File pins the literal `post_logout_redirect_uri not registered` (sourced from end_session.ex:145-163) — grep returns >= 1
    - File contains NO disjunctive `=~` assertions for redirect-rejection evidence — `grep -E ' =~ ".+" or .+ =~ ".+"' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 0 matches inside the FAPI-05 describe block (re-confirm by visual inspection if any other `or` shows up legitimately for non-rejection logic)
    - `mix test test/integration/phase43_fapi_milestone_e2e_test.exs --only integration` exits 0
    - `test/integration/phase41_fapi_2_0_e2e_test.exs` is byte-identical to its pre-edit state (verify with `git diff test/integration/phase41_fapi_2_0_e2e_test.exs` showing empty)
  </acceptance_criteria>
  <done>
    Phase 43 E2E test exists with FAPI-05 redirect-rejection coverage; every assertion pins the literal error description from the corresponding source seam; no disjunctive substring matches; phase41 file untouched; tests pass.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add iss-emission + discovery-mode E2E coverage (D-11b, D-11c, FAPI-06)</name>
  <files>test/integration/phase43_fapi_milestone_e2e_test.exs</files>
  <read_first>
    - test/integration/phase43_fapi_milestone_e2e_test.exs (re-read after Task 1 — confirm helpers exist, append into the same module)
    - test/integration/phase41_fapi_2_0_e2e_test.exs (lines 95-237 — full PAR + DPoP + auth + approve flow shape for the success-redirect iss assertion)
    - lib/lockspire/protocol/discovery.ex (re-read after Plan 02 lands — confirm openid_configuration/0 returns the new keys)
    - lib/lockspire/protocol/authorization_request.ex (lines 402-415 — confirm the OAuth error literal `unsupported_response_type` for the iss-on-error-redirect test)
    - lib/lockspire/web/controllers/authorize_controller.ex (lines 129-145 — confirm error.error is passed through unchanged into the redirect query string)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-04, D-05, D-07, D-08, D-11b, D-11c)
    - .planning/phases/43-end-to-end-fapi-validation/43-01-iss-emission-PLAN.md (Plan 01 outputs — iss in both seams)
    - .planning/phases/43-end-to-end-fapi-validation/43-02-discovery-keys-PLAN.md (Plan 02 outputs — discovery keys + helpers)
  </read_first>
  <behavior>
    - One test walks an approval/success flow (mirror phase41's full PAR+approve sequence) and asserts `URI.decode_query(URI.parse(callback_location).query)["iss"]` equals the configured issuer
    - One test walks a denial flow and asserts the same iss key on the denial redirect AND `query["error"] == "access_denied"` (pinned OAuth literal)
    - One test triggers a validation-error redirect via AuthorizeController and asserts iss appears on the error redirect AND `query["error"] == "unsupported_response_type"` (pinned OAuth literal — NOT `is_binary(query["error"])` which would let any error string pass)
    - One test asserts: under `:none` global profile, `Discovery.openid_configuration()["authorization_response_iss_parameter_supported"]` is `true` AND `"require_pushed_authorization_requests"` key is ABSENT (use `Map.has_key?/2` and refute)
    - One test asserts: under `:fapi_2_0_security` global profile, both keys are present and true
    - One test asserts: per-client `:fapi_2_0_security` override on a client does NOT add `require_pushed_authorization_requests` to discovery (server-wide gating)
  </behavior>
  <action>
    Append two new `describe` blocks to the SAME test file from Task 1
    (`test/integration/phase43_fapi_milestone_e2e_test.exs`):

    ```elixir
    describe "FAPI-06: RFC 9207 iss on every authorization-response redirect (D-04, D-05, D-11b)" do
      test "iss is appended to successful authorization redirect", %{client: client, secret: secret} do
        # Exercise the full happy-path: PAR push -> /authorize -> consent approval -> callback redirect.
        # Mirror phase41 lines 95-180 for the PAR+DPoP+approve sequence; assert the FINAL callback
        # location query contains "iss" => Lockspire.Config.issuer!()
        success_location = drive_par_authorize_approve_to_callback!(client, secret)
        query = success_location |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
        assert query["iss"] == "https://example.test/lockspire"
        assert is_binary(query["code"])
        assert query["state"] == "phase43-state"
      end

      test "iss is appended to access_denied redirect (with pinned OAuth error literal)", %{client: client, secret: secret} do
        deny_location = drive_par_authorize_deny_to_callback!(client, secret)
        query = deny_location |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
        assert query["iss"] == "https://example.test/lockspire"
        # OAuth error literal pinned: this is the only acceptable error string for a user denial.
        assert query["error"] == "access_denied"
      end

      test "iss is appended to validation-error redirect from AuthorizeController (with pinned OAuth error literal)", %{client: client} do
        # Trigger a redirectable validation error: response_type=id_token is unsupported, but
        # redirect_uri is registered, so Lockspire 302-redirects with `error=` rather than
        # rendering a browser-error page. The error path through
        # AuthorizeController.redirect_location/1 (lines 129-145) must include iss.
        # Pinned literal: `"unsupported_response_type"` from
        # authorization_request.ex:402-415 (validate_response_type/1).
        conn =
          build_conn(:get, "/authorize", %{
            "client_id" => client.client_id,
            "response_type" => "id_token",
            "redirect_uri" => "https://client.example.com/callback",
            "scope" => "openid",
            "code_challenge" => code_challenge("v-iss-error"),
            "code_challenge_method" => "S256",
            "state" => "phase43-error-state"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        assert conn.status in [302, 303]
        location = conn |> get_resp_header("location") |> List.first()
        query = location |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
        assert query["iss"] == "https://example.test/lockspire"
        # Tighter than `is_binary(query["error"])` — pin the exact OAuth error literal.
        assert query["error"] == "unsupported_response_type"
        assert query["state"] == "phase43-error-state"
      end
    end

    describe "FAPI-06: discovery published correctly under both modes (D-07, D-08, D-11c)" do
      test "under :none global profile, iss-parameter key is true and PAR-required key is ABSENT", %{client: _client} do
        put_security_profile!(:none)
        metadata = Lockspire.Protocol.Discovery.openid_configuration()
        assert metadata["authorization_response_iss_parameter_supported"] == true
        refute Map.has_key?(metadata, "require_pushed_authorization_requests")
      end

      test "under :fapi_2_0_security global profile, both keys are true", %{client: _client} do
        put_security_profile!(:fapi_2_0_security)
        metadata = Lockspire.Protocol.Discovery.openid_configuration()
        assert metadata["authorization_response_iss_parameter_supported"] == true
        assert metadata["require_pushed_authorization_requests"] == true
      end

      test "per-client :fapi_2_0_security override does NOT add PAR-required to discovery", %{client: client} do
        # Discovery is server-wide. A per-client opt-in must not flip the global discovery shape.
        put_security_profile!(:none)
        {:ok, _client} = Repository.update_client(client, %{security_profile: :fapi_2_0_security})

        metadata = Lockspire.Protocol.Discovery.openid_configuration()
        refute Map.has_key?(metadata, "require_pushed_authorization_requests")
      end

      test "discovery does NOT publish mTLS, JARM, or signed_metadata keys (D-09)", %{client: _client} do
        put_security_profile!(:fapi_2_0_security)
        metadata = Lockspire.Protocol.Discovery.openid_configuration()
        refute Map.has_key?(metadata, "tls_client_certificate_bound_access_tokens")
        refute Map.has_key?(metadata, "authorization_signing_alg_values_supported")
        refute Map.has_key?(metadata, "signed_metadata")
      end
    end
    ```

    Add two private helpers at the bottom of the module:

    - `drive_par_authorize_approve_to_callback!/2` — encapsulates the PAR push + /authorize +
      consent approval sequence (copy from phase41 lines 95-180), returning the final callback
      Location header value.
    - `drive_par_authorize_deny_to_callback!/2` — same sequence but with `{"decision" => "deny"}`
      at the consent step, returning the denial redirect Location.

    These helpers may use the existing test helper module Lockspire's TestSupport patterns or be
    inlined in this file. Keep them in this file to avoid leaking phase43 helpers into shared scope.

    Do NOT modify `test/integration/phase41_fapi_2_0_e2e_test.exs` (D-10).
  </action>
  <verify>
    <automated>mix test test/integration/phase43_fapi_milestone_e2e_test.exs --only integration --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'describe "FAPI-06: RFC 9207' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 1
    - `grep -c 'describe "FAPI-06: discovery' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 1
    - File contains assertions for `query["iss"]` on success, denial, AND validation-error redirects (grep for `query\["iss"\]` returns >= 3)
    - File asserts the literal `query["error"] == "access_denied"` for denial (pinned OAuth literal) — `grep -c 'query\["error"\] == "access_denied"' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 1
    - File asserts the literal `query["error"] == "unsupported_response_type"` for validation error (pinned OAuth literal) — `grep -c 'query\["error"\] == "unsupported_response_type"' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 1
    - File does NOT use `is_binary(query["error"])` as the only assertion on error code — `grep -c 'is_binary(query\["error"\])' test/integration/phase43_fapi_milestone_e2e_test.exs` returns 0 (the prior loose assertion is replaced by literal pinning)
    - File contains assertions toggling profile via `put_security_profile!(:none)` AND `put_security_profile!(:fapi_2_0_security)` and asserting discovery keys behave per D-07/D-08
    - File contains a per-client override test asserting discovery is unchanged
    - File contains a refute test for D-09 negative keys (mTLS, JARM, signed_metadata)
    - `mix test test/integration/phase43_fapi_milestone_e2e_test.exs --only integration` exits 0 (all tests from Task 1 + Task 2 pass)
    - Total file line count is between 350 and 700 (proportional to phase41 shape)
    - `git diff test/integration/phase41_fapi_2_0_e2e_test.exs` is empty (D-10 — phase41 untouched)
    - `mix compile --warnings-as-errors` exits 0
  </acceptance_criteria>
  <done>
    Phase 43 E2E covers iss emission across all 3 redirect kinds with PINNED OAuth error literals AND discovery mode-toggling AND per-client-vs-global gating; phase41 untouched; all tests pass.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Lockspire runtime enforcement -> Phase 43 E2E test | The test IS the executable proof that runtime matches policy claims; without it, FAPI-05/06 are unverified |
| Phase 43 E2E test -> v1.10 milestone archive | Test pass is the gate condition for archive |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-43-27 | Spoofing (silent regression) | Future change drops iss from one of the three redirect seams | mitigate | E2E test asserts iss on success, denial, AND error redirects independently. Failure on any one seam fails CI. Severity: HIGH — this is the canonical RFC 9207 mix-up mitigation. |
| T-43-28 | Tampering (silent redirect-URI relaxation) | Future change introduces URI parser tolerance for trailing slash | mitigate | E2E test asserts rejection at /authorize, /par, /token, /end_session for both trailing-slash and query-drift variants. Each assertion pins the LITERAL error description from the corresponding source seam — wrong-reason rejections do NOT pass. Severity: HIGH — exact-match is the FAPI 2.0 contract per FAPI-05. |
| T-43-29 | Spoofing (per-client override leakage into discovery) | Future change makes discovery per-client-aware, breaking RP discovery contract | mitigate | E2E test "per-client override does NOT flip discovery PAR key" actually registers a per-client override and pins server-wide gating. Severity: HIGH. |
| T-43-30 | Spoofing (D-03 silently changed) | Future change removes String.trim from end_session, breaking documented operator-tolerated whitespace handling | mitigate | E2E test includes positive control for surrounding-whitespace tolerance (locks D-03) using the literal `post_logout_redirect_uri not registered` as the negative-presence assertion. Severity: MEDIUM — interop regression risk. |
| T-43-31 | Information Disclosure (test fixture client/secret leaked) | Test fixtures use a real-looking secret value | accept | Fixtures use `phase43-client-secret` literal — clearly test-only string; no production credential reuse. Severity: LOW. |
| T-43-32 | Repudiation (CI cannot prove milestone evidence ran) | E2E test exists but is skipped or untagged | mitigate | `@moduletag :integration` matches the existing test-suite invocation pattern; phase41 evidence used the same tag and ran in CI. Severity: MEDIUM. |
| T-43-33 | Tampering (phase41 evidence rewritten as part of this work) | Executor edits phase41 file thinking it's phase43 | mitigate | Acceptance criteria includes `git diff test/integration/phase41_fapi_2_0_e2e_test.exs` empty check. Severity: HIGH — D-10 violation would corrupt prior milestone evidence. |
| T-43-34 | Spoofing (wrong-reason rejection passes test via disjunctive `=~ "x" or =~ "y"`) | Future regression rejects with a different error code (e.g., scope mismatch instead of redirect mismatch) and the disjunctive substring match silently passes | mitigate | Every redirect-rejection assertion pins the LITERAL error description string sourced verbatim from the corresponding lib/lockspire/protocol/* source seam. No `or` clauses on substring matches in the FAPI-05 describe block. Acceptance criteria contains an explicit grep gate forbidding the pattern. Severity: HIGH — was a previous warning; now structurally locked. |
</threat_model>

<verification>
- `mix test test/integration/phase43_fapi_milestone_e2e_test.exs --only integration` exits 0
- `mix compile --warnings-as-errors` exits 0
- `git diff test/integration/phase41_fapi_2_0_e2e_test.exs` is empty (D-10)
- All grep assertions in Task 1 and Task 2 acceptance_criteria pass
- File covers all D-11(a/b/c) obligations across two `describe` blocks per task
- Every redirect-rejection assertion pins the literal error description sourced from the corresponding lib/lockspire/protocol/* file (verified at planning time)
</verification>

<success_criteria>
- Phase 43 E2E test exists in NEW file (D-10)
- All FAPI-05 redirect-rejection variants exercised across all four endpoints (D-11a) with PINNED literal error descriptions — no disjunctive substring matches
- iss emission proven on success, denial, AND error redirects (D-11b) with PINNED OAuth error literals (`access_denied`, `unsupported_response_type`)
- Discovery toggling proven under both profile modes with per-client override safety (D-11c)
- Phase 41 evidence preserved untouched
- Plan 07 (truth-in-docs contract test) can run in parallel; this plan provides the runtime proof, Plan 07 provides the docs proof
</success_criteria>

<output>
After completion, create `.planning/phases/43-end-to-end-fapi-validation/43-06-SUMMARY.md`
</output>
