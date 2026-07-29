# Phase 127: Installer Against A Real Host - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 14 new/modified
**Analogs found:** 12 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/integration/install_host_interaction_test.exs` | test (integration) | file-I/O + generator invocation | `test/integration/install_generator_test.exs` (structure) + `test/integration/phase31_generated_host_verification_e2e_test.exs` (tagging) | exact (composite) |
| `test/integration/install_template_compile_test.exs` | test (compile fence) | transform | `test/integration/install_generator_test.exs:236-240` (`Code.compile_string`) + `test/support/lockspire/web/admin_route_test_helpers.ex` (route-table read) | role-match |
| `priv/test_fixtures/phx_new_host/**` | fixture (committed) | file-I/O | `test/support/fixtures/generated_host_app/.keep` (only prior "fixture dir", and it is empty) | **no true analog** |
| `priv/templates/lockspire.install/router.ex` | template (generator) | transform (EEx) | itself + verified probe in RESEARCH.md § Pattern 1 | in-place rewrite |
| `priv/templates/lockspire.install/config.exs` | template (generator) | transform (EEx) | `examples/adoption_demo/config/config.exs:64-77` | exact |
| `priv/templates/lockspire.install/account_resolver.ex` | template (host-owned seam) | request-response | itself (`:75` one-line change) | in-place |
| `priv/templates/lockspire.install/authorized_apps/index.html.heex` | template (HEEx) | transform | itself (`:19` one-line change) | in-place |
| `lib/lockspire/generators/install.ex` | service (generator core) | batch file-I/O | `lib/mix/tasks/lockspire.upgrade.ex:52-140` | exact (plan-then-apply) |
| `lib/lockspire/install/manifest.ex` | service (state) | file-I/O | `lockspire.upgrade.ex:87-96` (three-way checksum compare) | role-match |
| `lib/mix/tasks/lockspire.install.ex` | mix task | request-response | `lib/mix/tasks/lockspire.upgrade.ex:15-49` (`@switches`, `dry_run: :boolean`, `help/0`) | exact |
| `lib/mix/tasks/lockspire.client.create.ex` | mix task | CRUD | `lib/lockspire/install/verify.ex:202-217` (`Ecto.Migrator.with_repo/2`) | exact |
| `lib/lockspire/install/verify.ex` | service (checks) | request-response | itself (`:197` already uses the correct `--migrations-path` form) | in-place |
| `mix.exs` (`:47` ecto_sql range) | config | — | `mix.exs:43-45` (`phoenix_live_view` range + rationale comment) | exact |
| `.planning/phases/126-.../126-DEFECT-LEDGER.md` + `scripts/maintainer/adopter_path_walk.sh` | data/contract | event-driven (set-equality gate) | `test/lockspire/maintainer/defect_ledger_contract_test.exs` | exact (contract, read-only) |

---

## Pattern Assignments

### `test/integration/install_host_interaction_test.exs` (test, integration)

**Analogs:** `test/integration/install_generator_test.exs` (setup/teardown shape — **contrast against**),
`test/integration/phase31_generated_host_verification_e2e_test.exs` (tagging).

**Tagging pattern** — copy from `phase31_generated_host_verification_e2e_test.exs:1-5`:

```elixir
defmodule Lockspire.Integration.Phase31GeneratedHostVerificationE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint
```

`async: false` is mandatory here — the installer mutates `Mix.Project` global state and `Mix.Task` reenable
state. Every install-touching test in the repo is `async: false`.

Lane behavior of the tag (`test/test_helper.exs`, read this session):

```elixir
explicit_test_target? =
  Enum.any?(System.argv(), fn arg ->
    String.ends_with?(arg, ".exs") or String.contains?(arg, "integration")
  end)
# ...
exclude = if explicit_test_target? or integration_requested?, do: [], else: [integration: true]
ExUnit.start(exclude: exclude)
```

So `@moduletag :integration` → skipped by `mix test.fast` (`mix.exs:76`), run by `mix test.integration`
(`mix.exs:77`), **and** still run when the file is named directly. This is exactly D-05's intent.

**Header / fixture-root pattern** — from `install_generator_test.exs:1-13`:

```elixir
defmodule Lockspire.InstallGeneratorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @fixture_root Path.expand("../support/fixtures/generated_host_app", __DIR__)
  @runtime_fixture_root Path.expand("../support/generated_host_app_web", __DIR__)

  setup do
    reset_fixture!()
    on_exit(&reset_fixture!/0)
    :ok
  end
```

Copy: `Path.expand(..., __DIR__)` for the fixture constant, `import ExUnit.CaptureIO`, `setup` +
`on_exit` cleanup. **Do not copy** the `reset_fixture!` idea itself (below).

**Anti-pattern to CONTRAST against — the "empty a directory" fixture** (`install_generator_test.exs:379-386`):

```elixir
defp reset_fixture! do
  File.rm_rf!(Path.join(@fixture_root, ".lockspire"))
  File.rm_rf!(Path.join(@fixture_root, "config"))
  File.rm_rf!(Path.join(@fixture_root, "lib"))
  File.rm_rf!(Path.join(@fixture_root, "test"))
  File.mkdir_p!(@fixture_root)
  File.write!(Path.join(@fixture_root, ".keep"), "")
end
```

`test/support/fixtures/generated_host_app/` contains **only `.keep`** on disk. This is the INSTALL-01 defect
verbatim. The new test must instead **copy the committed snapshot into a scratch dir** and `rm_rf!` the
scratch dir on exit — never mutate the committed snapshot (see § Shared Patterns → Scratch-dir hygiene).

**Anti-pattern to CONTRAST against — `File.cd!` + supplied module flags** (`install_generator_test.exs:363-377`):

```elixir
defp install_fixture!(extra_args \\ []) do
  File.cd!(@fixture_root, fn ->
    Mix.Task.reenable("lockspire.install")
    Mix.Tasks.Lockspire.Install.run(base_args() ++ extra_args)
  end)
end

defp base_args do
  ["--web", "GeneratedHostAppWeb", "--scope", "GeneratedHostApp.Lockspire"]
end
```

`File.cd!` changes cwd but **not** `Mix.Project.config()`, so `build_assigns/1:28-32` still answers
`:lockspire`. And `base_args/0` supplies the very values the test then asserts. The new test replaces both:

```elixir
Mix.Project.in_project(:host_app, host_scratch, fn _module ->
  Mix.Task.reenable("lockspire.install")
  Lockspire.Generators.Install.run([])   # NO --web, NO --scope
end)
```

Keep the `Mix.Task.reenable/1` call from the analog if invoking through `Mix.Tasks.Lockspire.Install.run/1`;
it is required because the suite runs the task more than once per VM.

**The derivation chain under test** (`lib/lockspire/generators/install.ex:27-51`) — this is what makes
`app_module` the single unoverridable lever:

```elixir
def build_assigns(opts) do
  root_module =
    Mix.Project.config()
    |> Keyword.fetch!(:app)
    |> to_string()
    |> Macro.camelize()

  web_module = Keyword.get(opts, :web, "#{root_module}Web")
  scope_module = Keyword.get(opts, :scope, "#{root_module}.Lockspire")
  # ...
  project_root: Keyword.get(opts, :path, File.cwd!()),
  app_path: Macro.underscore(root_module),
  router_module: "#{web_module}.Router",
```

**Assertion style to copy** (`install_generator_test.exs:38-71`) — `File.read!(Path.join(root, rel)) =~ "..."`:

```elixir
assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
         "account_resolver: GeneratedHostApp.Lockspire.AccountResolver"
```

New test asserts the same shape against `HostApp.*`, **plus the currently-unasserted `repo:` line**
(`priv/templates/lockspire.install/config.exs:8` renders `repo: <%= @app_module %>.Repo`), **plus negative
controls** (`refute config =~ "Lockspire.Repo"`).

**Manifest-load helper to copy** (`install_generator_test.exs:396-401`):

```elixir
defp load_manifest! do
  @fixture_root
  |> Path.join(".lockspire/install_manifest.json")
  |> File.read!()
  |> Jason.decode!()
end
```

**Tautology to fix, not copy** (`install_generator_test.exs:46`):

```elixir
assert manifest["version"] == to_string(Mix.Project.config()[:version])
```

Asserts the artifact against the same expression that produced it. Under `in_project` this flips to the
*host's* version. Replace with a literal expectation (RESEARCH Pitfall 1).

---

### `test/integration/install_template_compile_test.exs` (test, compile fence)

**Analog A — compile a rendered template** (`install_generator_test.exs:236-240`). This is the in-repo
precedent for compile-level fences:

```elixir
:code.purge(GeneratedHostApp.Lockspire.FapiSmokeE2ETest)
:code.delete(GeneratedHostApp.Lockspire.FapiSmokeE2ETest)

assert [{GeneratedHostApp.Lockspire.FapiSmokeE2ETest, _binary} | _rest] =
         Code.compile_string(fapi_smoke, fapi_smoke_path)
```

Copy the `:code.purge/1` + `:code.delete/1` pair before every `Code.compile_string/2` — the suite is
`async: false` and modules get redefined across runs; skipping this produces redefinition warnings that
`mix compile --warnings-as-errors` under `mix qa` will surface.

**Analog B — reading a route table** (`test/support/lockspire/web/admin_route_test_helpers.ex:1-11`):

```elixir
defmodule Lockspire.Web.AdminRouteTestHelpers do
  @moduledoc false

  def admin_routes do
    Lockspire.Web.AdminRouter
    |> Phoenix.Router.routes()
    |> Enum.map(&with_admin_mount/1)
  end
```

Also used at `test/lockspire/web/admin_router_test.exs:53,86` and
`test/lockspire/web/live/admin/design_system_contract_test.exs:1794,2862`. Route assertions in this repo go
through `Phoenix.Router.routes/1` returning maps with `:path`, `:verb`, `:plug` — assert over those, never
over rendered source strings (a regex passes happily on the heredoc that injects zero routes).

**Source of rendered content** — drive off `lib/lockspire/generators/install.ex:63-75`:

```elixir
def rendered_templates(assigns) do
  Enum.map(Templates.all(), fn template ->
    destination = destination_path(template, assigns)

    %{
      template: template,
      destination: destination,
      relative_path: template.output.(assigns),
      rendered: render_template_content(template, assigns, destination)
    }
  end)
end
```

Filter by `Path.extname(entry.destination) == ".heex"` for the HEEx fence. Note
`render_template_content/3:84-94` prepends `ownership_header/2`, so rendered line numbers are offset from
source-template line numbers:

```elixir
def render_template_content(template, assigns, destination \\ nil) do
  destination = destination || destination_path(template, assigns)

  rendered_body =
    @template_root
    |> Path.join(template.template)
    |> EEx.eval_file(assigns: assigns)

  ownership_header(template, destination) <> rendered_body
end
```

**HEEx compile call** (RESEARCH § Pattern 4, empirically verified — no in-repo analog exists):

```elixir
Phoenix.LiveView.TagEngine.compile(source,
  caller: __ENV__,
  tag_handler: Phoenix.LiveView.HTMLEngine,
  file: path,
  line: 1
)
```

Never `EEx.compile_string(engine: Phoenix.LiveView.TagEngine)` — deprecated on the resolved LV 1.2.8.

**No `build_assigns` analog outside a Mix project?** There is none needed: `Install.build_assigns/1` works
under Lockspire's own project (it only needs `Mix.Project.config()[:app]`), so this fence needs **no host and
no `in_project`** — a plain untagged test is sufficient and keeps it in `test.fast` where a template
regression is caught fastest.

---

### `priv/test_fixtures/phx_new_host/` (fixture, committed) — **NO ANALOG**

There is no committed multi-file fixture tree anywhere in this repo outside `test/`. `priv/` contains exactly
two directories (`priv/repo/`, `priv/templates/`), and the only "fixture directory" that exists,
`test/support/fixtures/generated_host_app/`, holds a single `.keep`. The planner is creating a new
convention; record it deliberately with a `README.md` beside the snapshot.

**Exclusion scopes the snapshot must avoid — verified this session:**

| Tool | Config (read this session) | Verdict for `priv/test_fixtures/` |
|------|----------------------------|-----------------------------------|
| `mix format --check-formatted` | `.formatter.exs` → `inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"]` | **Safe** — `priv/` not in inputs |
| `credo --strict` | `.credo.exs:7` → `included: ["lib/", "test/"]` | **Safe** |
| `mix test` default glob | `test/**/*_test.exs` | **Safe** |
| `elixirc_paths(:test)` (`mix.exs:70`) | `["lib", "test/support"]` | **Safe** |
| `mix hex.build` (`package_files/0`) | see below | **Safe** |

`mix.exs` `package_files/0` verbatim:

```elixir
defp package_files do
  [
    Path.wildcard("lib/**/*.ex"),
    Path.wildcard("lib/**/*.heex"),
    Path.wildcard("priv/repo/migrations/*.exs"),
    Path.wildcard("priv/templates/**/*.{ex,exs,heex}"),
    Path.wildcard("docs/**/*.md"),
    ~w(.formatter.exs mix.exs README.md CHANGELOG.md SECURITY.md LICENSE brandbook/logo/lockspire-favicon.svg)
  ]
  |> List.flatten()
  |> Enum.reject(&(&1 in @package_excluded_files))
  |> Enum.sort()
end
```

**Disqualified locations: `lib/**` and `priv/templates/**`** — both are wildcarded and would ship the
snapshot to Hex. `priv/test_fixtures/` clears every one of the five scopes. Note the wildcards are evaluated
at `mix.exs` load time, so a snapshot's `mix.exs` at `priv/test_fixtures/phx_new_host/mix.exs` is **not**
matched by the `~w(... mix.exs ...)` literal (that is the repo-root path), but verify with `mix hex.build`.

---

### `priv/templates/lockspire.install/router.ex` (template, generator)

**Current shape to replace** (`:9-10, :53-62`) — a `def` returning a heredoc `String`:

```elixir
  def lockspire_routes do
    """
    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
    ...
    scope "<%= @mount_path %>/admin" do
      pipe_through [:browser, :require_operator]
      forward "/", Lockspire.Web.AdminRouter
    end

    scope "/" do
      forward "<%= @mount_path %>", Lockspire.Web.Router
    end
    """
  end
```

Note `:40-56`: the admin scope is rendered **twice** — once commented under `# Example:` (`:43-48`) and once
live (`:53-56`). D-12 removes the duplicate.

**EEx assign vocabulary available in this template** (from `build_assigns/1:40-60`):
`@project_root @app_module @app_path @web_module @web_path @scope_module @scope_path @mount_path
@storage_prefix @oban_prefix @router_module @resolver_module @interaction_handler_module
@consent_live_module @authorized_apps_controller_module @authorized_apps_html_module
@verification_controller_module @verification_html_module @sigra_host`.

**Escaping rule** — templates are rendered with `EEx.eval_file/2`, so literal EEx that must survive into the
generated file is written `<%%= ... %>`. See `priv/templates/lockspire.install/authorized_apps/index.html.heex:16-24`:

```heex
  <%% else %>
    <ul>
      <%%= for consent <- @consents do %>
        <li id={"authorized-app-<%%= consent.grant.id %>"}>
```

Line 19 is ADOPT-D16: a nested EEx tag inside a HEEx `{...}` attribute. D-24 makes it
`<li id={"authorized-app-#{consent.grant.id}"}>` — but that `#{}` must **also** survive EEx rendering, so
check whether the template's own EEx pass would interpolate it (it will not — `#{}` is Elixir, not EEx —
but the surrounding `<%%=` escaping convention still applies to the sibling lines).

**Downstream contract the rewrite must not break** — `lib/lockspire/install/verify.ex:120-134` hard-errors
when the admin mount is absent or shadowed by the public forward. And
`test/integration/install_generator_test.exs:88-95` asserts the exact current shape:

```elixir
assert router =~ ~s(scope "/lockspire/admin")
assert router =~ "pipe_through [:browser, :require_operator]"
assert router =~ ~s(forward "/", Lockspire.Web.AdminRouter)
assert router =~ "Do not rely on Lockspire to authenticate your operators"
assert router =~ ~s(forward "/lockspire", Lockspire.Web.Router)

assert router =~
         ~r/scope "\/lockspire\/admin" do\s+pipe_through \[:browser, :require_operator\]\s+forward "\/", Lockspire.Web.AdminRouter\s+end/
```

That regex at `:94-95` **will fail** after the rewrite and must be updated in the same commit (D-06 says
extend, not rewrite — but this specific assertion is shape-coupled and must move).

**Byte-compare fence to regenerate** (`install_generator_test.exs:209-210`):

```elixir
assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) ==
         File.read!(Path.join(@runtime_fixture_root, "router/lockspire.ex"))
```

`@runtime_fixture_root` = `test/support/generated_host_app_web/`. RESEARCH verified this fixture is
**inert** (nothing imports `GeneratedHostAppWeb.Router.Lockspire`), so blast radius is zero — but it is
compiled by `elixirc_paths(:test)` and must be regenerated byte-for-byte.

---

### `priv/templates/lockspire.install/config.exs` (template, generator)

**Current file, complete** (13 lines):

```elixir
import Config

# Import this file from your main config entrypoint:
#   import_config "lockspire.exs"
#
# Keep the Lockspire runtime contract explicit and host-owned here.
config :lockspire,
  repo: <%= @app_module %>.Repo,
  account_resolver: <%= @resolver_module %>,
  issuer: "https://example.com",
  mount_path: "<%= @mount_path %>",
  storage_prefix: "<%= @storage_prefix %>",
  oban_prefix: "<%= @oban_prefix %>"
```

`:10`'s bare issuer raises at `lib/lockspire/security/policy.ex:104-106` against `mount_path` (note: RESEARCH
Pitfall 4 corrects CONTEXT D-13's path — it is `lib/lockspire/security/policy.ex`, not `lib/lockspire/policy.ex`).

**Reference shape** — `examples/adoption_demo/config/config.exs:64-77` is the only working `config :lockspire`
block in the repo; read it for key ordering and the issuer-includes-mount-path form. Do **not** edit it
(Phase 129 owns the demo).

**Comment style to copy:** `#`-prefixed prose above the `config` call, imperative voice, naming the host's
responsibility. Every new key (`known_scopes`, `signing_alg`, `secret_key_base`) gets a `# CHANGE ME`-style
line in the same voice. `secret_key_base` is a placeholder, never a literal (D-14).

**Assertions coupled to this file** (`install_generator_test.exs:38-71`) — extend, do not rewrite.

---

### `lib/lockspire/generators/install.ex` (service, batch file-I/O) — plan-then-apply

**Current shape to replace** (`:11-24` and `:106-128`):

```elixir
  def run(opts \\ []) do
    assigns = build_assigns(opts)
    rendered_templates = rendered_templates(assigns)

    Enum.each(rendered_templates, fn rendered ->
      ensure_file!(rendered.destination, rendered.rendered)
    end)

    write_manifest!(assigns, rendered_templates)
    Mix.shell().info(instructions(assigns))

    :ok
  end
```

```elixir
  defp ensure_file!(destination, rendered) do
    File.mkdir_p!(Path.dirname(destination))

    case File.read(destination) do
      {:ok, ^rendered} ->
        Mix.shell().info("* unchanged #{Path.relative_to_cwd(destination)}")

      {:ok, _existing} ->
        Mix.raise("""
        Refusing to overwrite modified file: #{Path.relative_to_cwd(destination)}
        ...
        """)

      {:error, :enoent} ->
        File.write!(destination, rendered)
        Mix.shell().info("* created #{Path.relative_to_cwd(destination)}")

      {:error, reason} ->
        Mix.raise("Could not read #{Path.relative_to_cwd(destination)}: #{inspect(reason)}")
    end
  end
```

Note `File.mkdir_p!` at `:107` is a **write** — the plan pass must not call it. Move directory creation into
the apply pass.

**Analog — `lib/mix/tasks/lockspire.upgrade.ex:74-140`. Copy this shape verbatim (D-17):**

```elixir
    {updates, drifts} =
      manifest["managed_files"]
      |> List.wrap()
      |> Enum.reduce({[], []}, fn entry, {updates, drifts} ->
        path = entry["path"]
        expected_checksum = entry["checksum"]
        rendered = Map.fetch!(rendered_by_path, path)

        case File.read(rendered.destination) do
          {:ok, contents} ->
            current_checksum = Manifest.checksum(contents)
            next_checksum = Manifest.checksum(rendered.rendered)

            cond do
              current_checksum != expected_checksum ->
                {updates, [{path, "checksum drift detected"} | drifts]}

              current_checksum == next_checksum ->
                {updates, drifts}

              true ->
                {[rendered | updates], drifts}
            end

          {:error, :enoent} ->
            {updates, [{path, "managed file is missing"} | drifts]}

          {:error, reason} ->
            {updates, [{path, inspect(reason)} | drifts]}
        end
      end)

    if drifts != [] do
      Enum.each(Enum.reverse(drifts), fn {path, reason} ->
        Mix.shell().info("REFUSE #{path} (#{reason})")

        Mix.shell().info(
          "  fix: reconcile the managed file manually, then rerun `mix lockspire.upgrade`."
        )
      end)

      Mix.raise("Lockspire upgrade refused because managed scaffolding drifted.")
    end
```

Points to copy exactly:
- `Enum.reduce/3` accumulating `{keep, refuse}` tuples of `{path, reason}` — **no writes in the pass**
- accumulate by prepending, emit with `Enum.reverse/1` to preserve `Templates.all/0` order
- `REFUSE #{path} (#{reason})` one line per entry, then a **second** indented `  fix: ...` line
- exactly one `Mix.raise/1` after the whole list is printed
- the three-way checksum compare distinguishes *"you edited this"* from *"Lockspire changed this"* — reuse it
  so `install`'s refusal message can say `run mix lockspire.upgrade`

**`--dry-run` label swap** (`lockspire.upgrade.ex:122-136`):

```elixir
      Enum.each(Enum.reverse(updates), fn rendered ->
        Mix.shell().info(
          "#{if(dry_run?, do: "DRY-RUN", else: "UPDATE")} #{rendered.relative_path}"
        )

        unless dry_run? do
          File.write!(rendered.destination, rendered.rendered)
        end
      end)

      unless dry_run? do
        assigns
        |> Manifest.build(Map.values(rendered_by_path))
        |> then(&Manifest.write(assigns.project_root, &1))
      end
```

`install`'s equivalent labels are `* created` / `* unchanged` (existing, asserted at
`install_generator_test.exs:313-318` — **keep these strings**), plus a new dry-run variant.

**`instructions/1` to extend** (`install.ex:130-142`) — a plain heredoc numbered list; `:140` carries the
wrong `mix ecto.migrate`:

```elixir
  defp instructions(assigns) do
    """

    Lockspire canonical onboarding next steps:
      1. Import `config/lockspire.exs` from your main config files.
      2. Import `#{assigns.web_module}.Router.Lockspire` in `lib/#{assigns.web_path}/router.ex`.
      3. Call `lockspire_routes()` where your host wants the authorized-apps surface.
      4. Implement `#{assigns.resolver_module}` with real account lookup and claims.
      5. Point your login flow back through `#{assigns.interaction_handler_module}`.
      6. Review `docs/device-flow-host-guide.md` before shipping the generated `/verify` seam. ...
      7. Run `mix ecto.migrate`, create a client, and verify discovery, JWKS, and an auth-code + PKCE flow.
    """
  end
```

Style to preserve when adding D-26 (app-tree wiring) and D-27 (key lifecycle) steps: numbered, one line per
step, `#{assigns.*}` interpolation for host-shaped names, backticked paths and module names. Output is
asserted with `=~` at `install_generator_test.exs:242-245`, so additions are non-breaking.

**Ownership header to leave alone** (`install.ex:144-186`) — `ownership_header/2` branches on
`%{ownership: :managed}` vs `:host_owned` and on `.heex` extension (`<%!-- --%>` vs `#`). Any new template or
line-number-reporting fence must account for the 3-4 prepended lines.

---

### `lib/mix/tasks/lockspire.install.ex` (mix task) — `--dry-run` parity

**Analog:** `lib/mix/tasks/lockspire.upgrade.ex:1-49`:

```elixir
  @shortdoc "Upgrades Lockspire-managed generated scaffolding"

  use Mix.Task

  @requirements ["app.config"]

  @switches [
    web: :string,
    scope: :string,
    path: :string,
    mount_path: :string,
    storage_prefix: :string,
    oban_prefix: :string,
    dry_run: :boolean,
    help: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      do_run(opts)
    end
  end

  def help do
    """
    mix lockspire.upgrade [--web MyAppWeb] [--scope MyApp.Lockspire] [--path PATH] ... [--dry-run]
    ...
    """
  end
```

Copy: `OptionParser.parse(args, strict: @switches)`, the `invalid != []` guard with that exact message shape,
the `--help` branch, the public `help/0` returning a usage heredoc, and `dry_run: :boolean` in `@switches`.
Note `@requirements ["app.config"]` — **not** `["app.start"]` (see below).

---

### `lib/mix/tasks/lockspire.client.create.ex` (mix task, CRUD)

**Analog:** `lib/lockspire/install/verify.ex:202-217` — the `Ecto.Migrator.with_repo/2` wrapper that lets an
`["app.config"]` task reach a started repo without booting the host endpoint. Read that range and wrap
`Clients.register_client/1` (currently `lockspire.client.create.ex:39`) identically:

```elixir
Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _repo ->
  # repo work here
end)
```

`lib/mix/tasks/lockspire.verify.ex:10` declares `@requirements ["app.config"]` and works *only* because of
this wrapper. Do not "fix" `client.create` by declaring `app.start`.

---

### `mix.exs` — `ecto_sql` version range

**Analog: `mix.exs:41-48`, the `phoenix_live_view` entry three lines above the one being changed:**

```elixir
  defp deps do
    [
      {:phoenix, "~> 1.8.5"},
      # Range, not a pin: Lockspire mounts inside a host Phoenix app, so a hard
      # `~> 1.2.x` requirement would force every adopter to upgrade LiveView in
      # lockstep with Lockspire. Hosts on 1.1.x stay supported; CI resolves 1.2.x.
      {:phoenix_live_view, ">= 1.1.28 and < 2.0.0"},
      {:ecto_sql, "~> 3.13.5"},
```

Copy exactly: a three-line `#` rationale comment immediately above the dep, explaining *why a range and not a
pin* in adopter terms, then `">= X.Y.Z and < N.0.0"`. This is the house style D-23 names.

---

### Ledger / marker reconciliation touchpoint (read-only contract)

**File:** `test/lockspire/maintainer/defect_ledger_contract_test.exs` — no analog needed; this is the gate any
fix must satisfy. Shape the planner needs:

Markers are harvested from **every non-directory file** under `scripts/maintainer/` (`:86-99`):

```elixir
  defp marker_ids do
    @maintainer_scripts_dir
    |> File.ls!()
    |> Enum.reject(&File.dir?(Path.join(@maintainer_scripts_dir, &1)))
    |> Enum.flat_map(fn filename ->
      path = Path.join(@maintainer_scripts_dir, filename)
      source = File.read!(path)

      ~r/LOCKSPIRE_WALK_WORKAROUND:\s*(ADOPT-D\d+)/
      |> Regex.scan(source)
      |> Enum.map(fn [_full, id] -> id end)
    end)
    |> MapSet.new()
  end
```

Ledger claims come from the `Workaround:` field only (`:63-70`, `:103-112`):

```elixir
  @field_labels %{
    walk_step: ~r/-\s*\*\*Walk step:\*\*\s*(.+)/,
    # ...
    workaround: ~r/-\s*\*\*Workaround:\*\*\s*(.+)/
  }
```

```elixir
  defp ledger_workaround_ids(entries) do
    entries
    |> Enum.flat_map(fn {_id, fields} ->
      case fields[:workaround] do
        nil -> []
        value -> Regex.scan(~r/ADOPT-D\d+/, value) |> List.flatten()
      end
    end)
    |> MapSet.new()
  end
```

**Critical parsing trap:** `(.+)` with no `s` modifier captures **only the first line** of the field. So an
`ADOPT-Dnn` token written on the *first* line of a `Workaround:` field creates a claim; one on a continuation
line does not. A closing note like `**Workaround:** removed in Phase 127 — ADOPT-D15's marker deleted`
re-creates the phantom claim it is trying to retire.

**Two-way set equality** (`:187-211`) — both directions fail loudly:

```elixir
    unmatched = MapSet.difference(markers, ledgered)
    assert MapSet.size(unmatched) == 0,
           "The following harness markers have no matching ledger workaround entry ..."
```
```elixir
    unmatched = MapSet.difference(ledgered, markers)
    assert MapSet.size(unmatched) == 0,
           "The following ledger workaround IDs have no matching harness marker ..."
```

Other invariants enforced on every ledger entry the phase edits: all six fields non-blank (`:126-141`),
`Source:` tokens from `@allowed_sources` (`:24-31`, split on `and`/`,`), `Owning phase:` mentioning one of
`~w(127 128 129 130 future)` (`:32`), no seeded password (`:217-219`), no bearer-shaped string (`:221-223`).

**Entry heading format the parser requires** (`:57-58`): `### ADOPT-Dnn` followed by `- **Field:** value`
bullets, up to the next `### ADOPT-Dnn` or EOF.

**Planner action:** every commit that deletes a `LOCKSPIRE_WALK_WORKAROUND` marker must edit that entry's
`Workaround:` field in the same commit, and run
`mix test test/lockspire/maintainer/defect_ledger_contract_test.exs` after **each** ledger edit.

---

## Shared Patterns

### Scratch-dir hygiene (applies to the new host-interaction test)

**Source:** none in-repo — `grep -rn "System.tmp_dir" test/ scripts/ lib/` returns **zero hits**. The repo has
no scratch-dir convention; the closest is `install_generator_test.exs`'s destructive `reset_fixture!`, which
mutates a tracked directory.

**Constraint:** `scripts/maintainer/repo_hygiene_check.sh:402` raises `BLOCK` on non-empty
`git status --porcelain`. A test that installs into the committed snapshot dirties the tree every run.

**Pattern to establish:**

```elixir
setup do
  scratch = Path.join(System.tmp_dir!(), "lockspire-host-#{System.unique_integer([:positive])}")
  File.mkdir_p!(scratch)
  File.cp_r!(@snapshot, scratch)
  on_exit(fn -> File.rm_rf!(scratch) end)
  {:ok, host: scratch}
end
```

`on_exit` cleanup is the one part with an in-repo precedent (`install_generator_test.exs:11`,
`:18-24`). On macOS compare paths with `Path.expand/1` on both sides — `System.tmp_dir!()` resolves through
the `/tmp → /private/tmp` symlink.

### Capture-IO around generator invocation
**Source:** `test/integration/install_generator_test.exs:4, 28-31, 249-251`
**Apply to:** every test that calls `Install.run/1` or the Mix task
```elixir
import ExUnit.CaptureIO

output =
  capture_io(fn ->
    install_fixture!()
  end)
```
Under `Mix.Project.in_project/4` Mix additionally prints its `==> host_app` banner into this capture — assert
with `=~`, never equality.

### Refuse-on-drift, never overwrite, never prompt
**Source:** `lib/lockspire/generators/install.ex:113-119`, `lib/mix/tasks/lockspire.upgrade.ex:106-116`
**Apply to:** `install.ex`, `manifest.ex`, `lockspire.install.ex`
Both existing writers refuse rather than clobber. `Manifest.write/2` (`manifest.ex:35-38`) is the lone
exception and D-19 brings it into line. No `--force`, no `Mix.Generator.create_file/3` prompt (D-20) — CI and
the walk harness are non-interactive.

### Migrations path
**Source:** `lib/mix/tasks/lockspire.test.setup.ex:34`, `lib/lockspire/install/verify.ex:197`
**Apply to:** `verify.ex:241`, `verify.ex:270`, `install.ex:140` (three sites, not two — RESEARCH Pitfall 10)
```
Application.app_dir(:lockspire, "priv/repo/migrations")
```
Never a source-tree-relative path; it does not exist inside a compiled release.

### Async discipline
**Source:** `install_generator_test.exs:2`, `install_upgrade_test.exs`, `phase31_*:2`
**Apply to:** both new integration tests
`use ExUnit.Case, async: false`. `Mix.Project`, `Mix.Task` enable-state and `Application.put_env` are global.
The `@moduletag :integration` tests in this repo are uniformly `async: false`; the maintainer contract tests
(`defect_ledger_contract_test.exs:2`) are `async: true` because they only read files.

### Environment save/restore around `Application.put_env`
**Source:** `install_generator_test.exs:16-26`
```elixir
original_mount_path = Application.get_env(:lockspire, :mount_path)

on_exit(fn ->
  if is_nil(original_mount_path) do
    Application.delete_env(:lockspire, :mount_path)
  else
    Application.put_env(:lockspire, :mount_path, original_mount_path)
  end
end)

Application.delete_env(:lockspire, :mount_path)
```
Apply wherever the new tests need `:lockspire` app env deviations.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `priv/test_fixtures/phx_new_host/**` | fixture | file-I/O | No committed multi-file fixture tree exists outside `test/`. `priv/` holds only `repo/` and `templates/`; `test/support/fixtures/generated_host_app/` holds only `.keep`. New convention — needs a `README.md` documenting capture provenance (`phx_new 1.8.9`, Elixir 1.19.5 / OTP 28, sourced from the Phase 126 walk's `tmp/adopter-walk/host_app/`) and refresh procedure. |
| HEEx compile fence body | test | transform | `Phoenix.LiveView.TagEngine.compile/2` has zero in-repo callers. Use RESEARCH § Pattern 4 verbatim; the nearest in-repo precedent is only conceptual (`Code.compile_string` at `install_generator_test.exs:236-240`). |

Partial-analog note: `Mix.Project.in_project/4` also has zero in-repo callers
(`grep` confirms). RESEARCH § Pattern 2 carries the empirically verified invocation; treat it as the analog.

## Metadata

**Analog search scope:** `test/integration/`, `test/support/`, `test/lockspire/maintainer/`,
`lib/lockspire/generators/`, `lib/lockspire/install/`, `lib/mix/tasks/`, `priv/templates/lockspire.install/`,
`mix.exs`, `.formatter.exs`, `.credo.exs`, `test/test_helper.exs`
**Files read in full:** 6 (`install_generator_test.exs`, `install.ex`, `lockspire.upgrade.ex`,
`defect_ledger_contract_test.exs`, `router.ex` template, `config.exs` template)
**Files read in part:** 8
**Pattern extraction date:** 2026-07-28
