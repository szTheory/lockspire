---
phase: 43-end-to-end-fapi-validation
plan: 04
type: execute
wave: 1
depends_on: []
files_modified:
  - priv/templates/lockspire.install/fapi_smoke_e2e_test.exs
  - lib/lockspire/generators/templates.ex
  - test/integration/install_generator_test.exs
autonomous: true
requirements: [FAPI-05, FAPI-06]
must_haves:
  truths:
    - "The install generator emits at least one host-owned FAPI-aware integration test (D-17)"
    - "The generated test renders into the host namespace via @app_module (D-17)"
    - "The generated test ACTUALLY COMPILES and runs against the public Lockspire API surface (D-17 — executable FAPI proof, no Lockspire-internal modules referenced)"
    - "The generated test exercises FAPI 2.0 enforcement (PAR signal + iss emission + redirect rejection) through the host wiring (D-17)"
    - "The template is bounded to ONE file (D-18) — no test-generator framework, no second template"
    - "The new template registers in Templates.all/0 as the 12th entry (baseline 11 + 1 new)"
  artifacts:
    - path: "priv/templates/lockspire.install/fapi_smoke_e2e_test.exs"
      provides: "EEx template producing a host-owned FAPI smoke E2E test"
      contains: "<%= @app_module %>"
    - path: "lib/lockspire/generators/templates.ex"
      provides: "Registry entry for fapi_smoke_e2e_test.exs"
      contains: "fapi_smoke_e2e_test.exs"
    - path: "test/integration/install_generator_test.exs"
      provides: "Extended assertions verifying the new template renders to the host fixture project"
      contains: "fapi_smoke_e2e_test"
  key_links:
    - from: "Lockspire.Generators.Install.run/1"
      to: "Lockspire.Generators.Templates.all/0"
      via: "iterates registry to render each template"
      pattern: "Templates\\.all\\(\\)"
    - from: "Lockspire.Generators.Templates.all/0"
      to: "priv/templates/lockspire.install/fapi_smoke_e2e_test.exs"
      via: "registry entry maps template name -> output path function"
      pattern: "fapi_smoke_e2e_test\\.exs"
---

<objective>
Extend the install generator to emit ONE host-owned FAPI-aware integration test template, so
generated host seams carry executable FAPI proof from day one (D-17, D-18). Today the install
generator emits zero test files; this plan adds exactly one — bounded scope, ACTUALLY COMPILES
in a host project, and exercises FAPI 2.0 enforcement through the public Lockspire API surface
(no Lockspire-internal modules in the rendered template).

Purpose: Give host integrators a working starting point for FAPI 2.0 verification in their own
namespace, so they ship with confidence that the embedded library actually enforces the profile
in their app's wiring (not just in Lockspire's own internal tests).

Output: One new EEx template file, one updated registry entry, extended assertions in the
existing `test/integration/install_generator_test.exs`.
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

<interfaces>
Existing templates registry (`lib/lockspire/generators/templates.ex`). VERIFIED BASELINE: the
registry currently contains exactly 11 entries (router.ex, config.exs, account_resolver.ex,
interaction_handler.ex, consent_live.ex, authorized_apps_controller.ex, authorized_apps_html.ex,
authorized_apps/index.html.heex, verification_controller.ex, verification_html.ex,
verification_html/index.html.heex). Each entry is a map
`%{template: "<filename>", output: fn assigns -> "<path>" end}`.

Available assigns from `Lockspire.Generators.Install.build_assigns/1` (verified at
`lib/lockspire/generators/install.ex:61-91`):
  - `app_module` (string, e.g., "MyApp")
  - `app_path` (string, e.g., "my_app")
  - `web_module` (string, e.g., "MyAppWeb")
  - `web_path` (string, e.g., "my_app_web")
  - `scope_module` (string, e.g., "MyApp.Lockspire")
  - `scope_path` (string, e.g., "my_app/lockspire")
  - `mount_path` (string, e.g., "/lockspire")
  - `router_module`, `resolver_module`, `interaction_handler_module`, etc.

Existing renderer (`lib/lockspire/generators/install.ex:14-58`) iterates `Templates.all()` and
writes each rendered template to disk; refuses to overwrite if the file exists with different
content.

Existing generator test file is `test/integration/install_generator_test.exs` (verified — Plan
extension lands here, NOT in `test/lockspire/generators/install_test.exs` which does not exist).
That file already drives the install task end-to-end via a fixture host app at
`test/support/fixtures/generated_host_app` and asserts every rendered file's content. Add new
assertions there following the existing assertion shape.

PUBLIC LOCKSPIRE API SURFACE the rendered template may reference (verified):
  - `Lockspire` module: `Lockspire.issuer/0`, `Lockspire.mount_path/0`, `Lockspire.config/0`
    (lib/lockspire.ex)
  - `Lockspire.Clients.register_client/1` — public client-registration entry, returns
    `{:ok, %Lockspire.Clients.RegistrationResult{client: ..., client_secret: ...}}` (verified
    at lib/lockspire/clients.ex:85-115)
  - `Lockspire.Web.Router` — public router for HTTP-level smokes via Phoenix.ConnTest

NOT public (MUST NOT appear in the rendered template):
  - `Lockspire.TestRepo`, `Lockspire.Storage.Ecto.Repository`, `Lockspire.Domain.Client`,
    `Lockspire.Security.Policy`, or any `Lockspire.Storage.*` / `Lockspire.Domain.*` /
    `Lockspire.Protocol.*` modules. These are Lockspire internals — the template must not
    reach into them.

Reference test body shape — `test/integration/phase41_fapi_2_0_e2e_test.exs` (584 lines total).
The new template renders a TRIMMED, public-API-only version — bounded to ~200 lines per D-18,
covering FAPI 2.0 enforcement signals (PAR rejection at /authorize, iss appended on every
authorization redirect, exact-match redirect rejection at /authorize). Per-client overrides
and userinfo defense-in-depth permutations stay in Lockspire's own internal proof.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create the FAPI smoke E2E test EEx template (D-17, D-18)</name>
  <files>priv/templates/lockspire.install/fapi_smoke_e2e_test.exs</files>
  <read_first>
    - test/integration/phase41_fapi_2_0_e2e_test.exs (entire file — source for the trimmed test body)
    - priv/templates/lockspire.install/config.exs (entire file — EEx assignment pattern)
    - priv/templates/lockspire.install/verification_controller.ex (entire file — module-name-from-assigns pattern)
    - lib/lockspire.ex (entire file — confirm public surface available to host: Lockspire.issuer/0, Lockspire.mount_path/0)
    - lib/lockspire/clients.ex (lines 85-150 — confirm register_client/1 signature and RegistrationResult shape)
    - lib/lockspire/generators/install.ex (entire file — confirm available assigns from build_assigns/1)
    - lib/lockspire/protocol/authorization_request.ex (lines 236-247 — pin error code for redirect_uri rejection)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-17 single FAPI smoke, D-18 cap at ~200 lines)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Host-owned FAPI test template" section)
  </read_first>
  <action>
    Create `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` as an EEx template. The
    rendered output MUST land in the host namespace, MUST COMPILE in a host project that has
    run `mix lockspire.install`, and MUST exercise FAPI 2.0 enforcement through Lockspire's
    PUBLIC API surface only. Cap total file length at ~200 lines (D-18).

    Design contract (per D-17 "executable FAPI proof"):

      - The rendered template uses `use ExUnit.Case, async: false` (NO Ecto sandbox dependency,
        NO `use DataCase`).
      - It uses `Phoenix.ConnTest` for HTTP helpers.
      - It reads the issuer at runtime via `Lockspire.issuer/0` (NOT via
        `Application.compile_env/3`), so the assertion compares against the issuer Lockspire
        ACTUALLY emits at runtime — not the host's compile-time fallback. This guarantees the
        iss-equality assertion holds even when the host configures a different issuer at runtime.
      - It registers a fixture client via the PUBLIC `Lockspire.Clients.register_client/1` —
        NOT by constructing `Lockspire.Domain.Client` structs or calling `Lockspire.TestRepo`
        / `Lockspire.Storage.Ecto.Repository.*` / `Lockspire.Security.Policy.*`. None of those
        modules appear in the rendered file.
      - The FAPI 2.0 enforcement signal exercised is the PAR-required rejection at /authorize
        when the host has the global `:fapi_2_0_security` profile configured. Toggling the
        profile is OUT of scope for the host template — instead, the template documents in
        the moduledoc that it expects the host to set the profile in config and asserts the
        rejection only when the host has done so. (See moduledoc instructions below.)
      - Two redirect-rejection tests (FAPI-05) exercise the public unauthenticated rejection
        paths at /authorize: trailing-slash and extra-query variants. These DO NOT require the
        FAPI profile to be active — exact-match is enforced unconditionally.
      - One iss-emission test (FAPI-06, RFC 9207) asserts that even an error redirect from
        /authorize carries `iss=` matching `Lockspire.issuer()` — the unconditional D-04 contract.

    Required template content (literal EEx — note the `<%= ... %>` interpolations):

    ```eex
    defmodule <%= @app_module %>.Lockspire.FapiSmokeE2ETest do
      @moduledoc """
      FAPI 2.0 smoke E2E generated by `mix lockspire.install`.

      This test exercises Lockspire's FAPI 2.0 enforcement through the host's
      router wiring against the PUBLIC Lockspire API surface (`Lockspire`,
      `Lockspire.Clients`, `Lockspire.Web.Router`). It uses no Lockspire-internal
      modules and does not require an Ecto sandbox.

      Coverage:
        * RFC 9207 `iss` parameter present on /authorize error redirect (always-on)
        * Exact-match redirect URI rejection at /authorize (trailing slash)
        * Exact-match redirect URI rejection at /authorize (extra query param)

      Notes for host operators:
        * The test registers a throwaway client via `Lockspire.Clients.register_client/1`
          on each run. Lockspire's storage layer must be migrated and reachable from the
          test environment for the registration to persist.
        * To extend coverage to PAR-required enforcement, configure the global
          `security_profile: :fapi_2_0_security` in your test environment and add an
          assertion that GET /authorize without `request_uri` returns an
          `error=invalid_request` redirect. See Lockspire's own
          `phase43_fapi_milestone_e2e_test.exs` for the full pattern.

      Edit freely or delete after you have your own host-side FAPI proof.
      """

      use ExUnit.Case, async: false
      @moduletag :integration

      import Phoenix.ConnTest
      import Plug.Conn

      @endpoint Lockspire.Web.Router

      @registered_redirect_uri "https://client.example.com/callback"

      setup do
        client_attrs = %{
          name: "FAPI Smoke (host-generated test)",
          client_type: :confidential,
          redirect_uris: [@registered_redirect_uri],
          allowed_scopes: ["openid", "email", "profile"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          metadata: %{"created_by" => "fapi_smoke_e2e_test"}
        }

        case Lockspire.Clients.register_client(client_attrs) do
          {:ok, %{client: client}} -> %{client: client}
          {:error, reason} -> flunk("Could not register fixture client: " <> inspect(reason))
        end
      end

      test "iss is appended to the /authorize error redirect (RFC 9207, D-04)", %{client: client} do
        # Trigger a redirect-with-error by sending an unsupported response_type.
        # The redirect URI is registered, so Lockspire MUST redirect (not browser-error)
        # and MUST include `iss=` per RFC 9207.
        conn =
          build_conn(:get, "/authorize", %{
            "client_id" => client.client_id,
            "response_type" => "id_token",
            "redirect_uri" => @registered_redirect_uri,
            "scope" => "openid",
            "code_challenge" => code_challenge("fapi-smoke-iss"),
            "code_challenge_method" => "S256",
            "state" => "fapi-smoke-state"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        assert conn.status in [302, 303]
        location = conn |> get_resp_header("location") |> List.first()
        assert is_binary(location), "expected redirect with Location header, got: " <> inspect(conn)

        query = location |> URI.parse() |> Map.get(:query) |> Kernel.||("") |> URI.decode_query()
        assert query["iss"] == Lockspire.issuer()
        assert query["error"] == "unsupported_response_type"
      end

      test "trailing-slash redirect_uri is rejected at /authorize (FAPI-05)", %{client: client} do
        conn =
          build_conn(:get, "/authorize", %{
            "client_id" => client.client_id,
            "response_type" => "code",
            "redirect_uri" => @registered_redirect_uri <> "/",
            "scope" => "openid",
            "code_challenge" => code_challenge("fapi-smoke-trailing"),
            "code_challenge_method" => "S256"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        # An unregistered redirect_uri MUST NOT be redirected to. Lockspire renders a
        # browser-error response with the literal description from
        # authorization_request.ex:236-247 ("redirect_uri must match a registered URI").
        evidence = (conn |> get_resp_header("location") |> List.first()) || conn.resp_body || ""
        assert evidence =~ "redirect_uri must match a registered URI"
      end

      test "extra-query redirect_uri is rejected at /authorize (FAPI-05)", %{client: client} do
        conn =
          build_conn(:get, "/authorize", %{
            "client_id" => client.client_id,
            "response_type" => "code",
            "redirect_uri" => @registered_redirect_uri <> "?extra=1",
            "scope" => "openid",
            "code_challenge" => code_challenge("fapi-smoke-querydrift"),
            "code_challenge_method" => "S256"
          })
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        evidence = (conn |> get_resp_header("location") |> List.first()) || conn.resp_body || ""
        assert evidence =~ "redirect_uri must match a registered URI"
      end

      defp code_challenge(verifier) do
        :crypto.hash(:sha256, verifier)
        |> Base.url_encode64(padding: false)
      end
    end
    ```

    Notes for the executor:

    1. The template references ONLY public modules: `Lockspire`, `Lockspire.Clients`,
       `Lockspire.Web.Router`. NO `Lockspire.TestRepo`, NO `Lockspire.Storage.*`, NO
       `Lockspire.Domain.*`, NO `Lockspire.Security.*`, NO `Lockspire.Protocol.*`.
    2. The issuer is read at RUNTIME via `Lockspire.issuer()`, not at compile time. This is
       the explicit fix for the prior version which used `Application.compile_env/3` and would
       fail when host runtime issuer differs from the template's compile-time fallback.
    3. The PAR-required enforcement assertion is NOT in the template body — it requires the
       host to flip the global `security_profile`, which is host-environment-specific. The
       moduledoc documents this clearly so the host can extend if they wish.
    4. The redirect-rejection assertions assert the LITERAL error description string emitted
       by `lib/lockspire/protocol/authorization_request.ex:236-247`
       (`"redirect_uri must match a registered URI"`) — NOT a disjunctive substring match.
       This locks the wrong-reason rejection out: a future regression that rejects with a
       different code (e.g., missing scope) would fail the assertion.
    5. The iss-emission test uses `unsupported_response_type` because that takes a redirectable
       error path — `redirect_uri` is registered, so Lockspire redirects with `error=` rather
       than rendering a browser-error page. The assertion pins both `query["iss"]` (RFC 9207)
       and `query["error"] == "unsupported_response_type"` (the exact OAuth error string from
       `validate_response_type/1` at `authorization_request.ex:402-415`).
    6. Total file size MUST stay under ~200 rendered lines (D-18). The template above is ~120
       lines including moduledoc.
  </action>
  <verify>
    <automated>test -f priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; grep -q "&lt;%= @app_module %&gt;.Lockspire.FapiSmokeE2ETest" priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; grep -q "FAPI 2.0" priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; grep -q "Lockspire.Web.Router" priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; grep -q "Lockspire.Clients.register_client" priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; grep -q "Lockspire.issuer()" priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; grep -q "redirect_uri must match a registered URI" priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; ! grep -q "Lockspire.TestRepo\|Lockspire.Storage\|Lockspire.Domain\|Lockspire.Security\|Application.compile_env" priv/templates/lockspire.install/fapi_smoke_e2e_test.exs &amp;&amp; [ "$(wc -l &lt; priv/templates/lockspire.install/fapi_smoke_e2e_test.exs)" -le 200 ]</automated>
  </verify>
  <acceptance_criteria>
    - File `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` exists
    - File contains literal EEx tag `<%= @app_module %>.Lockspire.FapiSmokeE2ETest`
    - File contains the string `FAPI 2.0` in module documentation
    - File references `Lockspire.Web.Router`
    - File registers a client via `Lockspire.Clients.register_client/1` (public API per D-17)
    - File reads issuer via `Lockspire.issuer()` at runtime (NOT `Application.compile_env`)
    - File contains the literal pinned error description `redirect_uri must match a registered URI` (sourced from authorization_request.ex:236-247) — no disjunctive substring matches
    - File contains an iss-emission test asserting `query["iss"] == Lockspire.issuer()`
    - File contains a test for trailing-slash redirect_uri rejection
    - File contains a test for extra-query redirect_uri rejection
    - File line count is <= 200 (D-18 ~200-line cap)
    - File does NOT contain ANY of: `Lockspire.TestRepo`, `Lockspire.Storage`, `Lockspire.Domain`, `Lockspire.Security`, `Application.compile_env` (D-17 — public API surface only)
    - File does NOT contain `userinfo defense-in-depth` or per-client `:none` override permutations (trimmed scope per D-18)
  </acceptance_criteria>
  <done>
    Host FAPI smoke template committed; uses ONLY Lockspire's public API surface; reads issuer at runtime; pins literal error descriptions for redirect rejection; bounded scope.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Register the template in Templates.all/0 and prove rendering (D-17)</name>
  <files>lib/lockspire/generators/templates.ex, test/integration/install_generator_test.exs</files>
  <read_first>
    - lib/lockspire/generators/templates.ex (entire file — VERIFIED baseline is 11 entries; new entry will be the 12th)
    - lib/lockspire/generators/install.ex (entire file — confirm render_template/2 + assigns shape)
    - test/integration/install_generator_test.exs (entire file — VERIFIED this is the existing generator test; lines 1-160 show the assertion shape used for every other rendered file)
    - priv/templates/lockspire.install/fapi_smoke_e2e_test.exs (created by Task 1 — confirm it exists)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Generator wiring" section)
  </read_first>
  <behavior>
    - `Lockspire.Generators.Templates.all/0` returns a list including a map for `fapi_smoke_e2e_test.exs`
    - The map's `output` function returns a host-namespaced test path (`test/<app_path>/lockspire_fapi_smoke_e2e_test.exs`)
    - When `mix lockspire.install` runs against the existing fixture host (`test/support/fixtures/generated_host_app`), the rendered file lands at `test/generated_host_app/lockspire_fapi_smoke_e2e_test.exs` inside the fixture
    - The rendered file contains the host's `app_module` interpolated (`GeneratedHostApp.Lockspire.FapiSmokeE2ETest`)
    - The rendered file contains `Lockspire.Web.Router`, `FAPI 2.0`, and `Lockspire.Clients.register_client`
    - The total entry count returned by `Templates.all/0` equals BASELINE_AT_WRITE_TIME + 1, where BASELINE_AT_WRITE_TIME == 11 (verified at write time on `lib/lockspire/generators/templates.ex` — see comment in test). The assertion is expressed as "the new entry appears AND the count equals 12 at this writing" so a future plan adding another template can update only the count constant without rewriting the whole assertion.
  </behavior>
  <action>
    1. Edit `lib/lockspire/generators/templates.ex`. Append a new entry to the list returned by `all/0` as the FINAL entry (after the existing `verification_html/index.html.heex` entry, before the closing `]`):

       ```elixir
       %{
         template: "fapi_smoke_e2e_test.exs",
         output: &"test/#{&1.app_path}/lockspire_fapi_smoke_e2e_test.exs"
       }
       ```

       Place it as the FINAL list entry. Preserve all 11 existing entries verbatim. Do NOT
       reorder existing entries.

    2. Extend `test/integration/install_generator_test.exs` (the EXISTING generator test). Add new
       assertions inside the existing first test (`"mix lockspire.install writes the host-owned
       integration files"`) following the same assertion shape every other template uses
       (lines 21-148 in that file). The fixture host's `app_module` is `GeneratedHostApp` and
       its `app_path` is `generated_host_app`, so the rendered file lands at
       `test/generated_host_app/lockspire_fapi_smoke_e2e_test.exs` inside `@fixture_root`.

       Add this block after the existing assertions (immediately before the
       `assert output =~ "Lockspire canonical onboarding next steps"` line at ~line 150):

       ```elixir
       fapi_smoke_path =
         Path.join(@fixture_root, "test/generated_host_app/lockspire_fapi_smoke_e2e_test.exs")

       assert File.exists?(fapi_smoke_path),
              "Expected FAPI smoke E2E test to be rendered to host fixture"

       fapi_smoke = File.read!(fapi_smoke_path)

       assert fapi_smoke =~ "defmodule GeneratedHostApp.Lockspire.FapiSmokeE2ETest"
       assert fapi_smoke =~ "Lockspire.Web.Router"
       assert fapi_smoke =~ "Lockspire.Clients.register_client"
       assert fapi_smoke =~ "Lockspire.issuer()"
       assert fapi_smoke =~ "FAPI 2.0"
       assert fapi_smoke =~ "redirect_uri must match a registered URI"

       refute fapi_smoke =~ "Lockspire.TestRepo"
       refute fapi_smoke =~ "Lockspire.Storage"
       refute fapi_smoke =~ "Lockspire.Domain"
       refute fapi_smoke =~ "Lockspire.Security"
       refute fapi_smoke =~ "Application.compile_env"
       ```

       Also extend the idempotency test (`"mix lockspire.install is idempotent..."`) and the
       refusal test (`"mix lockspire.install refuses to overwrite host edits"`) IF they iterate
       over rendered files programmatically — read those tests first and only edit if they
       maintain a list of rendered paths that needs the new path appended. If they only assert
       on the install task's stdout/exit, no edit is needed.

       NOTE: If the existing test's `reset_fixture!/0` helper relies on a hard-coded list of
       paths to delete between runs, append the new fixture path to that list. Read the helper
       definition before editing to confirm whether this is necessary.

    3. In a comment at the new templates.ex entry (or above the assertion in install_generator_test.exs), record the baseline-at-write-time:

       ```elixir
       # Plan 43-04: this brings Templates.all/0 to 12 entries (baseline 11 at the time
       # this template was added). If a future plan adds another template, increment this
       # comment and the corresponding length assertion in install_generator_test.exs.
       ```

       Then add this length assertion to the install_generator_test.exs test:

       ```elixir
       # Sanity check: total templates rendered. Update this constant if a future plan
       # adds or removes a template. Baseline at Plan 43-04 write time was 11; the FAPI
       # smoke template makes it 12.
       assert length(Lockspire.Generators.Templates.all()) == 12
       ```

    4. Do NOT remove or reorder existing template entries. Do NOT change the assigns shape produced by `Install.build_assigns/1`.
  </action>
  <verify>
    <automated>mix test test/integration/install_generator_test.exs --color &amp;&amp; grep -q '"fapi_smoke_e2e_test.exs"' lib/lockspire/generators/templates.ex &amp;&amp; grep -q "lockspire_fapi_smoke_e2e_test.exs" lib/lockspire/generators/templates.ex</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "fapi_smoke_e2e_test.exs" lib/lockspire/generators/templates.ex` returns >= 2 (template name + output path)
    - `grep -c "lockspire_fapi_smoke_e2e_test.exs" lib/lockspire/generators/templates.ex` returns 1 (output path only)
    - `mix test test/integration/install_generator_test.exs` exits 0
    - `test/integration/install_generator_test.exs` contains assertions verifying the rendered fixture file contains `Lockspire.Web.Router`, `Lockspire.Clients.register_client`, `Lockspire.issuer()`, `FAPI 2.0`, and the literal `redirect_uri must match a registered URI`
    - `test/integration/install_generator_test.exs` contains refute assertions for `Lockspire.TestRepo`, `Lockspire.Storage`, `Lockspire.Domain`, `Lockspire.Security`, `Application.compile_env`
    - `test/integration/install_generator_test.exs` contains an assertion `length(Lockspire.Generators.Templates.all()) == 12` (baseline 11 + new entry)
    - `mix compile --warnings-as-errors` exits 0
    - The list returned by `Lockspire.Generators.Templates.all/0` has exactly 12 entries (11 baseline + 1 new) — verify with `mix run -e 'IO.puts(length(Lockspire.Generators.Templates.all()))'` outputs `12`
  </acceptance_criteria>
  <done>
    Template registered as the 12th entry (baseline 11 + 1); existing install_generator_test extended with assertions on rendered fixture content and refute checks for internal modules; rendered file contains the host's app_module.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host project repo -> generated FAPI test file | Host owns the file after generation; Lockspire only ships the initial scaffold |
| Generated test -> Lockspire.Web.Router | Test exercises FAPI enforcement through the host's wired router (the actual integration boundary) |
| Generated test -> Lockspire public API surface | Template MUST NOT couple host tests to Lockspire internals — only `Lockspire`, `Lockspire.Clients`, `Lockspire.Web.Router` are crossable |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-43-17 | Spoofing (false sense of FAPI proof in host) | Generated test asserts only happy paths and skips negative-redirect rejection | mitigate | Template includes BOTH iss-emission assertion AND trailing-slash + extra-query redirect rejection assertions, all using PINNED literal error descriptions (not disjunctive substring matches that would let wrong-reason rejections pass). Severity: HIGH — the whole point of the host template is to give the host real FAPI signal. |
| T-43-18 | Tampering (template overwrites host edits) | Re-running `mix lockspire.install` clobbers a host's customized FAPI test | mitigate | The existing `Install.ensure_file!/2` (lines 40-58) already refuses to overwrite modified files. New template inherits this behavior — no change required. Severity: MEDIUM — addressed by reusing existing renderer behavior. |
| T-43-19 | Information Disclosure (template leaks Lockspire-internal state) | Template references Lockspire-internal modules (`TestRepo`, `Storage.Ecto.Repository`, `Domain.Client`, `Security.Policy`) that won't exist or aren't part of the host's contract | mitigate | Template now uses ONLY public modules: `Lockspire`, `Lockspire.Clients`, `Lockspire.Web.Router`. Acceptance criteria + install_generator_test refute assertions lock this. Severity: HIGH — was a previous blocker; now structurally prevented. |
| T-43-20 | Repudiation (FAPI claim with no host-side proof) | Lockspire claims FAPI 2.0 readiness but generated host has no test | mitigate | Template ships exactly one host-side smoke; install_generator_test proves it renders into the fixture. Plan 07 contract test asserts the template exists in the registry. Severity: HIGH — addressed structurally by D-17 + Plan 07. |
| T-43-21 | Denial of Service (template scope bloat slows host install) | Template grows beyond ~200 lines | mitigate | Acceptance criteria caps file at 200 lines; D-18 codifies the limit. Severity: LOW. |
| T-43-22 | Tampering (issuer drift between host config and assertion) | Template hardcodes issuer at compile time and silently mismatches host runtime config | mitigate | Template reads `Lockspire.issuer()` at runtime (NOT `Application.compile_env/3`). Acceptance criteria explicitly forbids `Application.compile_env` and require `Lockspire.issuer()`. Severity: HIGH — was a previous blocker; now structurally prevented. |
| T-43-23 | Spoofing (wrong-reason rejection passes redirect-URI test) | Template asserts redirect-URI rejection via disjunctive substring (`evidence =~ "x" or evidence =~ "y"`) so a future regression rejecting with the wrong reason still passes | mitigate | Template asserts the LITERAL error description string `"redirect_uri must match a registered URI"` sourced verbatim from `authorization_request.ex:236-247`. No `or` clauses in the assertion. Severity: HIGH — was a previous warning; now pinned. |
</threat_model>

<verification>
- `mix test test/integration/install_generator_test.exs` exits 0
- `mix compile --warnings-as-errors` exits 0
- File `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` exists with EEx interpolation, `FAPI 2.0` mention, and redirect-rejection tests using PINNED literal error description
- File contains NO Lockspire-internal module references and NO `Application.compile_env`
- `lib/lockspire/generators/templates.ex` registers the template as the 12th entry (baseline 11 + 1)
- All grep assertions in Task 1 and Task 2 acceptance_criteria pass
</verification>

<success_criteria>
- One new template emits a host-namespaced FAPI 2.0 smoke E2E test on `mix lockspire.install`
- Template uses ONLY Lockspire's public API surface (`Lockspire`, `Lockspire.Clients`, `Lockspire.Web.Router`) — actually compiles in a host project
- Template reads issuer at runtime via `Lockspire.issuer()` so the iss-equality assertion holds against the host's runtime config (not a compile-time fallback)
- Template covers iss emission and exact-match redirect rejection (trailing slash + extra query) with PINNED literal error descriptions (no disjunctive substring matches)
- Existing install_generator_test extended to prove the file renders to the fixture path with expected interpolations and absence of internal-module references
- Plan 07 will reassert the template's existence in the truth-in-docs contract test
</success_criteria>

<output>
After completion, create `.planning/phases/43-end-to-end-fapi-validation/43-04-SUMMARY.md`
</output>
