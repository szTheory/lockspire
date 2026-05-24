# Phase 43: End-to-End FAPI 2.0 Validation - Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 16 (4 new, 12 modified) — drawn verbatim from `43-CONTEXT.md` `<canonical_refs>`
**Analogs found:** 16 / 16 (every target has a strong in-repo precedent)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/authorization_flow.ex` (modify lines 376-402) | protocol/redirect-builder | request-response (302 redirect) | self — extend existing `build_redirect/2` | exact (in-place extension) |
| `lib/lockspire/web/controllers/authorize_controller.ex` (modify lines 129-145) | controller/redirect-builder | request-response (302 redirect, error path) | `lib/lockspire/protocol/authorization_flow.ex:390-402` (sibling redirect builder) | role-match (sister seam) |
| `lib/lockspire/protocol/discovery.ex` (modify lines 74-94, 168-178) | protocol/metadata-builder | request-response (JSON discovery doc) | self — same module's `maybe_put_dpop_metadata/2` (lines 168-178) is the truthful-key precedent | exact (in-place extension) |
| `lib/mix/tasks/lockspire.oidf_conformance.ex` (NEW) | mix-task | shell-out / env-validation | `lib/mix/tasks/lockspire.client.create.ex` (CLI wrapper) + `scripts/conformance/fapi2-check.sh` (shell delegate) | role-match (Mix.Task pattern) + behavior precedent in `run_phase37_suite.sh` |
| `scripts/conformance/fapi2-plan.json` (NEW) | config/data | static JSON artifact | `scripts/conformance/phase37-plan.json` | exact (mirror precedent) |
| `test/integration/phase43_fapi_milestone_e2e_test.exs` (NEW) | integration test | request-response (HTTP via `Phoenix.ConnTest` + `Lockspire.Web.Router`) | `test/integration/phase41_fapi_2_0_e2e_test.exs` | exact (per-phase E2E precedent) |
| `priv/templates/lockspire.install/<new>.exs.eex` (NEW host-test template) | template/host-test | request-response (generated test) | `priv/templates/lockspire.install/verification_controller.ex` (template shape) + `phase41_fapi_2_0_e2e_test.exs` (test shape) | role-match (template) + role-match (test body) |
| `lib/lockspire/generators/install.ex` (modify) | generator | file I/O (template render) | self — extend; new template registers in `templates.ex:8-54` | exact (extend precedent) |
| `lib/lockspire/generators/templates.ex` (modify) | template registry | data | self — append to `all/0` list (lines 8-54) | exact |
| `test/lockspire/release_readiness_contract_test.exs` (modify line 481 + new FAPI claim assertions) | contract test | file I/O (read & assert) | self — `test "phase 42 preparatory lane docs..."` block at lines 465-482 | exact (extend precedent) |
| `docs/maintainer-conformance.md` (modify line 53 + pin plan/variants) | docs | static text | self lines 88-98 (Phase 37 / FAPI 2.0 sections) | exact |
| `.github/workflows/oidf-conformance.yml` (line 66 already references task; no edits required if D-13 task name matches) | CI config | YAML | self lines 65-66 — orphan reference resolves on D-13 | exact |
| `SECURITY.md` (modify) | docs | static text | self lines 29-52 (`## Supported security surface` block) | exact |
| `README.md` (modify) | docs | static text | self lines 9-25 (What v0.1 includes / does not include) | exact |
| `docs/supported-surface.md` (modify) | docs | static text | self lines 7-46 (`## Supported in scope` / `## Explicitly out of scope`) | exact |
| `test/integration/phase41_fapi_2_0_e2e_test.exs` | preserved untouched per D-10 | — | — | n/a (hands-off) |

---

## Pattern Assignments

### `lib/lockspire/protocol/authorization_flow.ex` — Append `iss` to success + denial redirects (D-04, D-05)

**Analog (self):** `lib/lockspire/protocol/authorization_flow.ex` lines 376-402

**Existing imports already in file** (line 6):
```elixir
alias Lockspire.Config
```
`Config.issuer!/0` is already alias-resolvable — no new import needed.

**Existing redirect-builder seam** (lines 376-402):
```elixir
defp approval_redirect(%Interaction{} = interaction, raw_code) do
  build_redirect(interaction.redirect_uri, %{
    "code" => raw_code,
    "state" => interaction.state
  })
end

defp denial_redirect(%Interaction{} = interaction) do
  build_redirect(interaction.redirect_uri, %{
    "error" => "access_denied",
    "state" => interaction.state
  })
end

defp build_redirect(base_uri, params) when is_binary(base_uri) and is_map(params) do
  uri = URI.parse(base_uri)
  existing = URI.decode_query(uri.query || "")

  merged =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
    |> then(&Map.merge(existing, &1))

  %{uri | query: URI.encode_query(merged)}
  |> URI.to_string()
end
```

**Pattern to copy:** Add `"iss" => Config.issuer!()` to the params map handed to `build_redirect/2` from BOTH `approval_redirect/2` and `denial_redirect/1`. Do NOT modify `build_redirect/2` itself — `iss` is just another key alongside `code`/`state`/`error`. The unconditional contract from D-04 means there is no `if fapi?` branch.

Example (apply to both helpers):
```elixir
defp approval_redirect(%Interaction{} = interaction, raw_code) do
  build_redirect(interaction.redirect_uri, %{
    "code" => raw_code,
    "state" => interaction.state,
    "iss" => Config.issuer!()
  })
end
```

---

### `lib/lockspire/web/controllers/authorize_controller.ex` — Append `iss` to error redirect (D-04, D-05)

**Analog (sibling):** `lib/lockspire/protocol/authorization_flow.ex` lines 390-402 (the redirect builder above)

**Existing imports** (lines 1-15) — `alias Lockspire.Config` is NOT yet present and must be added:
```elixir
alias Lockspire.Host.Claims
alias Lockspire.Host.InteractionResult
alias Lockspire.Protocol.AuthorizationFlow
alias Lockspire.Protocol.AuthorizationRequest
alias Lockspire.Protocol.AuthorizationRequest.Error
alias Lockspire.Protocol.AuthorizationRequest.Validated
alias Lockspire.Storage.Ecto.Repository
alias Lockspire.Web.AuthorizeHTML
```

**Existing error-redirect seam** (lines 129-145):
```elixir
defp redirect_location(%Error{} = error) do
  uri = URI.parse(error.redirect_uri)
  existing_params = URI.decode_query(uri.query || "")

  oauth_params =
    %{
      "error" => error.error,
      "error_description" => error.error_description,
      "state" => error.state
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()

  uri
  |> Map.put(:query, URI.encode_query(Map.merge(existing_params, oauth_params)))
  |> URI.to_string()
end
```

**Pattern to copy:** Add `"iss" => Config.issuer!()` to the `oauth_params` map. RFC 9207 requires `iss` on error redirects too (D-04 mirrors this). Add `alias Lockspire.Config` to the alias block. Per D-12-discretion, the planner may also factor a small shared helper if both seams gain identical injection logic.

Example:
```elixir
oauth_params =
  %{
    "error" => error.error,
    "error_description" => error.error_description,
    "state" => error.state,
    "iss" => Config.issuer!()
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Map.new()
```

---

### `lib/lockspire/protocol/discovery.ex` — Publish FAPI 2.0 keys (D-07, D-08, D-09)

**Analog (self):** `lib/lockspire/protocol/discovery.ex` lines 168-191 — `maybe_put_dpop_metadata/2` and `put_bcl_fcl_metadata/1` are the canonical "compose into the discovery doc" patterns.

**Existing builder pipeline** (lines 74-94):
```elixir
def openid_configuration do
  issuer = Config.issuer!()
  endpoint_metadata = mounted_endpoint_metadata()

  %{
    "issuer" => issuer,
    ...
    "id_token_signing_alg_values_supported" => id_token_signing_alg_values_supported()
  }
  |> Map.merge(endpoint_metadata)
  |> maybe_put_dpop_metadata(endpoint_metadata)
  |> put_bcl_fcl_metadata()
end
```

**Existing unconditional-merge precedent** (lines 185-192):
```elixir
defp put_bcl_fcl_metadata(metadata) do
  Map.merge(metadata, %{
    "backchannel_logout_supported" => true,
    "backchannel_logout_session_supported" => true,
    "frontchannel_logout_supported" => true,
    "frontchannel_logout_session_supported" => true
  })
end
```

**Existing conditional-merge precedent** (lines 168-178):
```elixir
defp maybe_put_dpop_metadata(metadata, endpoint_metadata) do
  if dpop_supported_surface_mounted?(endpoint_metadata) do
    Map.put(
      metadata,
      "dpop_signing_alg_values_supported",
      DPoP.signing_alg_values_supported()
    )
  else
    metadata
  end
end
```

**Existing profile-resolution precedent inside this module** (lines 96-104):
```elixir
defp id_token_signing_alg_values_supported do
  profile =
    case Lockspire.Storage.Ecto.Repository.get_server_policy() do
      {:ok, policy} -> policy.security_profile
      _ -> :none
    end

  Lockspire.Protocol.SecurityProfile.allowed_signing_algorithms(profile)
end
```

**Pattern to copy (two new helpers, one unconditional, one profile-gated):**

1. Unconditional `iss`-parameter key (D-07) — follow `put_bcl_fcl_metadata/1` shape and chain into the `openid_configuration/0` pipeline:
```elixir
defp put_iss_parameter_metadata(metadata) do
  Map.put(metadata, "authorization_response_iss_parameter_supported", true)
end
```

2. Profile-gated PAR-required key (D-08) — follow `maybe_put_dpop_metadata/2` shape, but read the **global** `server_policy.security_profile` (not the resolved per-client value — discovery is server-wide):
```elixir
defp maybe_put_par_required_metadata(metadata) do
  if global_security_profile() == :fapi_2_0_security do
    Map.put(metadata, "require_pushed_authorization_requests", true)
  else
    metadata
  end
end

defp global_security_profile do
  case Lockspire.Storage.Ecto.Repository.get_server_policy() do
    {:ok, policy} -> policy.security_profile
    _ -> :none
  end
end
```

The `global_security_profile/0` helper deliberately mirrors lines 98-101 — extract once if the planner wants to dedupe with `id_token_signing_alg_values_supported/0`.

3. Chain both into the pipeline at lines 91-94:
```elixir
|> Map.merge(endpoint_metadata)
|> maybe_put_dpop_metadata(endpoint_metadata)
|> put_bcl_fcl_metadata()
|> put_iss_parameter_metadata()
|> maybe_put_par_required_metadata()
```

**Do NOT publish** (D-09): mTLS, JARM, `signed_metadata` keys.

---

### `lib/mix/tasks/lockspire.oidf_conformance.ex` (NEW) — Mix task wrapping `fapi2-check.sh` (D-13, D-14)

**Analog (Mix.Task shape):** `lib/mix/tasks/lockspire.client.create.ex` lines 1-42

**Pattern to copy — Mix.Task scaffold:**
```elixir
defmodule Mix.Tasks.Lockspire.OidfConformance do
  @moduledoc """
  Validate the FAPI 2.0 conformance environment and dependencies.
  """

  @shortdoc "Validates the OIDF FAPI 2.0 conformance environment"

  use Mix.Task

  @requirements ["app.config"]

  @switches [
    validate_env: :boolean,
    help: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    cond do
      Keyword.get(opts, :help, false) -> Mix.shell().info(help())
      Keyword.get(opts, :validate_env, false) -> validate_env!()
      true -> validate_env!()
    end
  end
  ...
end
```

**Analog (env/dep validation + script delegation):** `scripts/conformance/fapi2-check.sh` lines 1-18 (env-var requirement check) and `scripts/conformance/run_phase37_suite.sh` lines 66-71 (`require_command` pattern).

`run_phase37_suite.sh` lines 66-71 — the canonical "fail loud on missing dependency" pattern:
```bash
require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}
```

`fapi2-check.sh` lines 14-18 — the canonical "fail loud on missing env" pattern:
```bash
if [ -z "$CLIENT_ID" ]; then
  printf '%sFAIL%s LOCKSPIRE_CLIENT_ID is required\n' "$RED" "$RESET" >&2
  printf 'Set LOCKSPIRE_CLIENT_ID to a registered client that inherits or requires FAPI 2.0.\n' >&2
  exit 1
fi
```

**Pattern to copy — `validate_env!/0` body** (D-14: env vars + deps + artifact paths, NO suite execution):
```elixir
defp validate_env! do
  required_envs = ["LOCKSPIRE_TEST_DB_HOST", "OIDF_CONFORMANCE_SERVER"]
  missing_envs = Enum.reject(required_envs, &System.get_env/1)

  required_paths = [
    "scripts/conformance/fapi2-check.sh",
    "scripts/conformance/fapi2-plan.json"
  ]
  missing_paths = Enum.reject(required_paths, &File.exists?/1)

  required_cmds = ["bash", "curl"]
  missing_cmds = Enum.reject(required_cmds, &System.find_executable/1)

  if missing_envs != [] or missing_paths != [] or missing_cmds != [] do
    Mix.raise("""
    OIDF conformance preflight failed.
      missing env: #{inspect(missing_envs)}
      missing artifacts: #{inspect(missing_paths)}
      missing commands: #{inspect(missing_cmds)}
    """)
  end

  Mix.shell().info("OIDF conformance preflight: env, artifacts, and dependencies present.")
end
```

**Critical:** the task must NOT run `docker compose` or invoke the OIDF suite. Per D-14/D-16, live suite execution stays a documented manual maintainer step.

---

### `scripts/conformance/fapi2-plan.json` (NEW) — Pinned OIDF plan + variants (D-15)

**Analog:** `scripts/conformance/phase37-plan.json` (full file, 36 lines).

**Pattern to copy — JSON shape:**
```json
{
  "description": "Lockspire Phase 43 FAPI 2.0 Security Profile final test plan",
  "artifact_dir": ".artifacts/conformance/fapi2",
  "plans": [
    {
      "name": "fapi-2-0-security-profile-final",
      "suite_plan": "fapi2-security-profile-final-test-plan",
      "variants": {
        "fapi_profile": "plain_fapi",
        "client_auth_type": "private_key_jwt",
        "sender_constrain": "dpop",
        "fapi_request_method": "unsigned",
        "fapi_response_mode": "plain_response"
      },
      "modules": []
    }
  ]
}
```

The variant set is locked verbatim by D-15. `modules: []` mirrors the precedent's "all-modules-of-plan" semantics.

---

### `test/integration/phase43_fapi_milestone_e2e_test.exs` (NEW) — Phase 43 E2E proof (D-10, D-11)

**Analog:** `test/integration/phase41_fapi_2_0_e2e_test.exs` (full file).

**Pattern to copy — module header + setup_all + setup** (lines 1-93):
```elixir
defmodule Lockspire.Integration.Phase43FapiMilestoneE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository
  # plus DPoP/Token/SigningKey/Claims/InteractionResult as needed

  defmodule GeneratedHostResolver do
    @behaviour Lockspire.Host.AccountResolver
    # copy verbatim from phase41 lines 20-55
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
    Application.put_env(:lockspire, :account_resolver, GeneratedHostResolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    # register a Client with secret/redirect_uri/scopes — copy phase41 lines 73-93
  end
end
```

**Pattern to copy — request-via-router seam** (used throughout phase41, e.g. lines 104-118):
```elixir
authorize_conn =
  build_conn(:get, "/authorize", %{
    "client_id" => client.client_id,
    "response_type" => "code",
    "redirect_uri" => "https://client.example.com/callback",
    "scope" => "openid",
    "code_challenge" => code_challenge(code_verifier),
    "code_challenge_method" => "S256"
  })
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

assert authorize_conn.status in [302, 303]
location = get_resp_header(authorize_conn, "location") |> List.first()
assert location =~ "error=invalid_request"
```

**Pattern to copy — security-profile setter** (phase41 lines 438-441):
```elixir
defp put_security_profile!(profile) do
  {:ok, policy} = Repository.get_server_policy()
  Repository.put_server_policy(%{policy | security_profile: profile})
end
```

**D-11 test obligations (organize as discrete `test ... do` blocks):**

1. **Zero-tolerance redirect-URI rejection** across `/authorize`, `/par`, `/token`, `/end_session` for trailing slash and query drift. Use `build_conn` + `Lockspire.Web.Router.call/2` with redirect URIs that differ from the registered `https://client.example.com/callback` only by a trailing slash or extra query param. Assert each surface returns the `:invalid_redirect_uri` / `:redirect_uri_mismatch` / `:unregistered_post_logout_redirect_uri` error, not a 200/302 success.
2. **`iss=` appended on success, denial, and error redirects.** Walk a full PAR + auth + approve flow (mirror phase41 lines 138-173) and assert `URI.decode_query` of the callback location contains `"iss" => "https://example.test/lockspire"`. Also exercise denial (`{"decision" => "deny"}`) and a validation error redirect path through `AuthorizeController` to confirm both seams emit `iss`.
3. **Discovery published correctly under both modes.** Toggle via `put_security_profile!/1`, then call `Lockspire.Protocol.Discovery.openid_configuration/0` directly. Assert:
   - Always: `"authorization_response_iss_parameter_supported" => true`
   - Under `:fapi_2_0_security`: `"require_pushed_authorization_requests" => true`
   - Under `:none`: key `"require_pushed_authorization_requests"` is absent (not `false`)

---

### `priv/templates/lockspire.install/<host_fapi_test>.exs.eex` (NEW) — Host-owned FAPI test template (D-17, D-18)

**Analog (template shape — EEx file with `<%= @assigns %>`):** `priv/templates/lockspire.install/config.exs`:
```eex
import Config

config :lockspire,
  repo: <%= @app_module %>.Repo,
  account_resolver: <%= @resolver_module %>,
  issuer: "https://example.com",
  mount_path: "<%= @mount_path %>"
```

**Analog (test body — what the rendered file should look like):** `test/integration/phase41_fapi_2_0_e2e_test.exs` (whole file, scoped to a single E2E pathway under the host's namespace).

**Pattern to copy — template header:** Render the module name from `@app_module` so it lands in the host namespace, e.g.:
```eex
defmodule <%= @app_module %>.Lockspire.FapiSmokeE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn
  ...
end
```

**Pattern to copy — keep scope ≤ ~200 lines (D-18):** The default delivery is ONE cohesive smoke covering PAR + DPoP + `iss` + redirect rejection. Mirror phase41's PAR+DPoP success path (lines 95-237) but trim the per-client override variants (those are repo-internal proof, not host-template proof). Cap at one file unless growth forces a split into two (auth-code+PKCE smoke + FAPI 2.0 smoke).

**Generator wiring — append to `Lockspire.Generators.Templates.all/0`** (lines 8-54 in `templates.ex`):
```elixir
%{
  template: "fapi_smoke_e2e_test.exs",
  output: &"test/lockspire/#{&1.app_path}_fapi_smoke_e2e_test.exs"
}
```

**Generator behavior** is unchanged — `Install.run/1` (lines 11-21) iterates `Templates.all()` and the existing `render_template/2` (lines 23-35) handles EEx + path expansion. No new generator framework required.

---

### `test/lockspire/release_readiness_contract_test.exs` — Truth-in-docs assertions (D-12, D-19, D-20)

**Analog (self):** `test "phase 42 preparatory lane docs stay truthful..."` block (lines 465-482).

**Existing precedent:**
```elixir
test "phase 42 preparatory lane docs stay truthful about certification and feature support" do
  maintainer_conformance = File.read!(@maintainer_conformance_path)
  workflow = File.read!(@oidf_conformance_workflow_path)

  assert maintainer_conformance =~ "preparatory OIDF lane"
  assert maintainer_conformance =~ "Phase 42 wires the lane for Phase 43 consumption"
  assert maintainer_conformance =~ "does not claim pass-ready certification"
  assert maintainer_conformance =~ "does not imply support for mTLS or `private_key_jwt`"

  refute maintainer_conformance =~ "fully certified"
  refute maintainer_conformance =~ "Phase 43 completion"

  assert workflow =~ "uses: actions/upload-artifact@v4"
  assert workflow =~ "mix lockspire.oidf_conformance"
end
```

**Pattern to copy — Phase 43 truth-in-docs block:**
```elixir
test "phase 43 FAPI 2.0 milestone claims stay truthful and bounded" do
  security = File.read!(@security_policy_path)
  readme = File.read!(@readme_path)
  supported_surface = File.read!(@supported_surface_path)
  maintainer_conformance = File.read!(@maintainer_conformance_path)

  # Positive claims (D-19): describe what is enforced
  for doc <- [security, readme, supported_surface] do
    assert doc =~ "FAPI 2.0"
    assert doc =~ "PAR"
    assert doc =~ "DPoP"
    # plus: ES256/PS256, exact redirect match, iss on auth responses,
    # FAPI 2.0 keys in discovery — exact wording chosen at planning time per
    # CONTEXT "Claude's Discretion"
  end

  # Negative claims: do NOT claim certification, do NOT claim mTLS
  for doc <- [security, readme, supported_surface] do
    refute doc =~ "certified"
    refute doc =~ "mTLS"
  end

  # Pin OIDF plan ID + variants
  assert maintainer_conformance =~ "fapi2-security-profile-final-test-plan"
  assert maintainer_conformance =~ "private_key_jwt"
  assert maintainer_conformance =~ "dpop"
end
```

**Existing line 481 reference** (`assert workflow =~ "mix lockspire.oidf_conformance"`) requires no edit — it resolves once the Mix task lands (D-13).

**Add new path module attribute** at top of file (after lines 22-36):
```elixir
@fapi2_conformance_plan_path Path.expand("../../scripts/conformance/fapi2-plan.json", __DIR__)
```

---

### `docs/maintainer-conformance.md` — Pin OIDF plan + variants (D-15)

**Analog (self):** existing file, lines 88-98 (Phase 37 + FAPI 2.0 sections).

**Existing line 53 pattern (no edit required if Mix task name matches):**
```markdown
You can also run the `mix lockspire.oidf_conformance` task to perform this check. It expects `LOCKSPIRE_TEST_DB_HOST` and `OIDF_CONFORMANCE_SERVER` to be set if not in dry-run.
```

**Pattern to add — pin canonical plan + variants verbatim** (mirror phase37-plan.json variant block):
```markdown
## FAPI 2.0 OIDF plan (Phase 43)

Use the `fapi2-security-profile-final-test-plan` plan in the OIDF UI, with these variants:

- `fapi_profile`: `plain_fapi`
- `client_auth_type`: `private_key_jwt`
- `sender_constrain`: `dpop`
- `fapi_request_method`: `unsigned`
- `fapi_response_mode`: `plain_response`

The same plan and variants are pinned in `scripts/conformance/fapi2-plan.json`.
The live Docker run remains a manual maintainer step; CI does not gate on it.
```

---

### `SECURITY.md` / `README.md` / `docs/supported-surface.md` — Add positive FAPI 2.0 claim language (D-19)

**Analog (each file is its own analog — extend in place):**

`SECURITY.md` lines 29-62 (`## Supported security surface` + `## Secure defaults`) — extend these blocks. Existing pattern uses `-` bullet lists.

`README.md` lines 9-25 (`## What v0.1 includes` / `## What v0.1 does not include`) — extend both blocks. Existing pattern uses `-` bullet lists.

`docs/supported-surface.md` lines 7-46 (`## Supported in scope` / `## Explicitly out of scope`) — extend both blocks. Existing pattern uses `-` bullet lists.

**Pattern to copy — additive bullets only (no rewrites):**

Positive claims (add to "supported"/"includes"/"in scope" lists):
- "FAPI 2.0 Security Profile enforcement: PAR-required, DPoP sender-constrained access tokens, ES256/PS256 signing, exact-match redirect URIs"
- "RFC 9207 `iss` parameter on every authorization response"
- "Truthful FAPI 2.0 keys in `.well-known/openid-configuration` (`authorization_response_iss_parameter_supported`, conditional `require_pushed_authorization_requests`)"

Negative claims (add to "out of scope"/"does not include" lists):
- "External OIDF conformance suite certification (the harness is wired and pinned but not pass-gated in CI)"
- "mTLS client authentication and mTLS-bound access tokens"

**Critical:** `release_readiness_contract_test.exs` is the locked validator — the exact assertion strings added there (D-20) MUST appear verbatim in the doc files.

---

## Shared Patterns

### Truthful metadata sourced from runtime enforcement (Phase 42 D-11)

**Source:** `lib/lockspire/protocol/discovery.ex` lines 168-178 (the `maybe_put_dpop_metadata/2` precedent — only publish what's enforced).

**Apply to:** All new discovery keys. The unconditional `iss` emission contract (D-04) and the unconditional discovery key (D-07) are aligned by this rule. The conditional PAR discovery key (D-08) reflects the actual server-wide enforcement.

```elixir
# Truth pattern — read what the runtime actually enforces, then publish it.
defp maybe_put_<feature>_metadata(metadata) do
  if <feature_actually_enforced?>(...) do
    Map.put(metadata, "<discovery_key>", <truth_value>)
  else
    metadata
  end
end
```

### Per-phase E2E test naming (`phase{N}_*_e2e_test.exs`)

**Source:** `test/integration/` directory listing — every prior milestone has its own `phase{N}_*_e2e_test.exs`. Phase 41 is preserved untouched (D-10); Phase 43 gets a new file.

**Apply to:** `test/integration/phase43_fapi_milestone_e2e_test.exs` only. Do NOT modify `phase41_fapi_2_0_e2e_test.exs`.

### Mix.Task scaffold

**Source:** `lib/mix/tasks/lockspire.client.create.ex` lines 1-42 (canonical `use Mix.Task` + `@requirements ["app.config"]` + `OptionParser.parse` + `--help` switch + `Mix.raise/1` on bad input).

**Apply to:** `lib/mix/tasks/lockspire.oidf_conformance.ex`.

### EEx template + registry

**Source:** `lib/lockspire/generators/install.ex` lines 11-58 (renderer) + `lib/lockspire/generators/templates.ex` lines 8-54 (registry).

**Apply to:** New host-FAPI test template. Register one entry in `templates.ex`; add the EEx file under `priv/templates/lockspire.install/`. The renderer handles file collision detection (lines 40-58: existing identical = unchanged, existing different = refuse-to-overwrite, missing = create).

### Truth-in-docs contract test

**Source:** `test/lockspire/release_readiness_contract_test.exs` lines 465-482 (Phase 42 precedent block — `assert doc =~` for positive claims, `refute doc =~` for negative claims, paired against module-attribute file paths declared at lines 22-36).

**Apply to:** Phase 43 FAPI 2.0 claim assertions (D-12, D-19, D-20).

---

## No Analog Found

None — every new and modified file in this phase has a strong in-repo precedent. The phase is, by design, a closure phase: it consumes harnesses landed in Phase 42 and aligns documentation with already-shipped enforcement. No greenfield architectural shapes are introduced.

---

## Metadata

**Analog search scope:**
- `lib/lockspire/protocol/`
- `lib/lockspire/web/controllers/`
- `lib/lockspire/generators/`
- `lib/mix/tasks/`
- `priv/templates/lockspire.install/`
- `scripts/conformance/`
- `test/integration/`
- `test/lockspire/release_readiness_contract_test.exs`
- `docs/maintainer-conformance.md`, `SECURITY.md`, `README.md`, `docs/supported-surface.md`
- `.github/workflows/oidf-conformance.yml`

**Files scanned:** 16 target files + 8 analog files (all read in full or by targeted offset/limit; no re-reads).

**Pattern extraction date:** 2026-05-02
