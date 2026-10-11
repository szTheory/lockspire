defmodule Lockspire.DocumentationContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @architecture_path Path.join(@repo_root, "docs/architecture.md")
  @walkthrough_path Path.join(@repo_root, "docs/code-walkthrough.md")
  @readme_path Path.join(@repo_root, "README.md")
  @getting_started_path Path.join(@repo_root, "docs/getting-started.md")
  @install_path Path.join(@repo_root, "docs/install-and-onboard.md")

  test "every maintained guide appears once in a reader-task ExDoc group and package" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)
    extras = Keyword.fetch!(docs, :extras)
    groups = Keyword.fetch!(docs, :groups_for_extras)
    package_files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)
    grouped_extras = groups |> Keyword.values() |> List.flatten()
    expected_extras = Enum.reject(extras, &(&1 == "README.md"))

    assert Enum.sort(grouped_extras) == Enum.sort(expected_extras)
    assert length(grouped_extras) == length(Enum.uniq(grouped_extras))
    assert Enum.all?(extras, &(&1 in package_files))

    assert "brandbook/logo/lockspire-favicon.svg" in package_files
    refute "CONTRIBUTING.md" in extras
    refute "CONTRIBUTING.md" in package_files

    for extra <- expected_extras do
      assert File.exists?(Path.join(@repo_root, extra)), "missing ExDoc extra: #{extra}"
    end

    evaluate = Keyword.fetch!(groups, :"Evaluate and install")
    integrate = Keyword.fetch!(groups, :Integrate)
    understand = Keyword.fetch!(groups, :"Understand Lockspire")
    upgrade = Keyword.fetch!(groups, :Upgrade)
    maintain = Keyword.fetch!(groups, :Maintain)

    assert_in_order(Enum.join(extras, "\n"), [
      "docs/install-and-onboard.md",
      "docs/saas-adoption-recipe.md",
      "docs/adoption-demo.md"
    ])

    assert "docs/supported-surface.md" in evaluate
    assert "docs/operator-admin.md" in integrate
    assert "docs/sigra-companion-host.md" in integrate
    assert "docs/architecture.md" in understand
    assert "docs/code-walkthrough.md" in understand
    assert "docs/maintainer-conformance.md" in maintain
    assert "docs/maintainer-release.md" in maintain
    assert "docs/upgrading/v1.27.md" in upgrade
  end

  test "README and getting-started route readers to canonical sources and task guides" do
    readme = File.read!(@readme_path)
    getting_started = File.read!(@getting_started_path)
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)
    extras = Keyword.fetch!(docs, :extras)
    package_files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)

    required_routes = [
      "docs/supported-surface.md",
      "docs/install-and-onboard.md",
      "docs/saas-adoption-recipe.md",
      "docs/device-flow-host-guide.md",
      "docs/operator-admin.md",
      "docs/maintainer-release.md",
      "CONTRIBUTING.md"
    ]

    for route <- required_routes do
      assert readme =~ route
    end

    assert readme =~ "https://github.com/szTheory/lockspire/blob/main/CONTRIBUTING.md"
    assert "CONTRIBUTING.md" not in extras
    assert "CONTRIBUTING.md" not in package_files

    assert getting_started =~ "[canonical install and onboarding guide](install-and-onboard.md)"

    for relative_path <- [
          "docs/supported-surface.md",
          "docs/install-and-onboard.md",
          "docs/saas-adoption-recipe.md",
          "docs/device-flow-host-guide.md",
          "docs/operator-admin.md",
          "docs/maintainer-release.md",
          "CONTRIBUTING.md"
        ] do
      assert File.exists?(Path.join(@repo_root, relative_path))
    end
  end

  test "canonical install keeps current command anchors and explains verifier limits" do
    install = File.read!(@install_path)
    install_task = File.read!(Path.join(@repo_root, "lib/mix/tasks/lockspire.install.ex"))
    verify_task = File.read!(Path.join(@repo_root, "lib/mix/tasks/lockspire.verify.ex"))
    commands = install |> fenced_blocks("bash") |> Enum.join("\n")

    assert_in_order(commands, [
      "mix lockspire.install",
      "mix ecto.migrate",
      "mix lockspire.verify"
    ])

    assert install_task =~ "defmodule Mix.Tasks.Lockspire.Install"
    assert verify_task =~ "defmodule Mix.Tasks.Lockspire.Verify"
    assert install =~ "supported-surface.md"
    assert install =~ "does not prove"
    assert install =~ "staff access policy"
    assert install =~ "host app"
    assert install =~ "host request tests"
    assert Code.ensure_loaded?(Mix.Tasks.Ecto.Migrate)
  end

  test "HTML docs use the Lockspire favicon and pinned theme-aware Mermaid hook" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)
    head_hook = Keyword.fetch!(docs, :before_closing_head_tag)
    body_hook = Keyword.fetch!(docs, :before_closing_body_tag)
    html_head = head_hook.(:html)
    html_body = body_hook.(:html)

    assert Keyword.fetch!(docs, :favicon) == "brandbook/logo/lockspire-favicon.svg"
    assert html_head =~ ".lockspire-mermaid"
    assert html_body =~ "mermaid@11.16.0/dist/mermaid.min.js"
    assert html_body =~ ~s(securityLevel: "strict")
    assert html_body =~ ~s(startOnLoad: false)
    assert html_body =~ "exdoc:loaded"
    assert html_body =~ "lockspire:mermaid-ready"
    assert html_body =~ "MutationObserver"
    assert html_body =~ "captureSources"
    assert html_body =~ "lockspireMermaidSource"
    assert html_body =~ "state.generation"
    assert html_body =~ "fallback.hidden = false"
    assert html_body =~ "themeVariables"

    assert head_hook.(:epub) == ""
    assert body_hook.(:epub) == ""
    assert body_hook.(:markdown) == ""
  end

  test "architecture guide keeps the required journey and ownership order" do
    architecture = File.read!(@architecture_path)

    assert architecture =~
             "Lockspire owns protocol truth; the Phoenix host owns people and product"

    assert_in_order(architecture, [
      "## Lockspire in one picture",
      "## Vocabulary for the trip",
      "## Journey 1: an authorization request becomes tokens",
      "## Journey 2: refresh rotation contains compromise",
      "## Installation draws the ownership line",
      "## Security is the architecture",
      "## The data model carries protocol state",
      "## Cross-cutting mechanics",
      "## Advanced protocols orbit the core",
      "## Module atlas",
      "## Code-reading routes",
      "## Changing Lockspire safely",
      "## Where to go next"
    ])

    diagrams = fenced_blocks(architecture, "mermaid")

    assert length(diagrams) == 4

    for diagram <- diagrams do
      assert diagram =~ "accTitle:"
      assert diagram =~ "accDescr:"
    end

    assert architecture =~ "[code walkthrough](code-walkthrough.md)"
    assert architecture =~ "[supported surface](supported-surface.md)"
  end

  test "walkthrough Elixir excerpts parse and carry stable architectural anchors" do
    architecture = File.read!(@architecture_path)
    walkthrough = File.read!(@walkthrough_path)
    elixir_blocks = fenced_blocks(architecture <> "\n" <> walkthrough, "elixir")
    walkthrough_blocks = fenced_blocks(walkthrough, "elixir")

    assert length(walkthrough_blocks) in 12..18

    for block <- elixir_blocks do
      assert {:ok, _quoted} = Code.string_to_quoted(block)
    end

    assert walkthrough =~ "Internal modules and private functions are shown"
    assert walkthrough =~ "[architecture guide](architecture.md)"
    assert walkthrough =~ "[supported surface](supported-surface.md)"

    assert_anchor(
      walkthrough,
      "lib/lockspire/install/operation_plan.ex",
      "with {:ok, migration_plan} <- Migrations.plan(project_root: assigns.project_root)"
    )

    assert_anchor(
      walkthrough,
      "lib/lockspire/protocol/authorization_request.ex",
      "redirect_uri in client.redirect_uris"
    )

    assert_anchor(
      walkthrough,
      "lib/lockspire/protocol/authorization_flow.ex",
      "token_hash = Policy.hash_token(raw_code)"
    )

    assert Code.ensure_loaded?(Lockspire.Protocol.TokenExchange)
    assert function_exported?(Lockspire.Protocol.TokenExchange, :exchange, 1)
    assert function_exported?(Lockspire.Protocol.TokenExchange, :issue_ciba_tokens, 4)

    assert Map.keys(struct(Lockspire.Protocol.TokenExchange.Success)) |> Enum.sort() ==
             [
               :__struct__,
               :access_token,
               :expires_in,
               :id_token,
               :issued_token_type,
               :refresh_token,
               :scope,
               :token_type
             ]

    assert walkthrough =~ "Token endpoint: stable facade, focused coordinators"
    assert walkthrough =~ "internal grant-support coordinator"

    assert_anchor(
      walkthrough,
      "lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex",
      "{:error, :reuse_detected}"
    )

    assert_anchor(
      walkthrough,
      "lib/lockspire/storage/ecto/repository/token_store.ex",
      "|> lock(\"FOR UPDATE\")"
    )
  end

  test "guides avoid local handoffs and brittle source-reading links" do
    for path <- [@architecture_path, @walkthrough_path] do
      guide = File.read!(path)

      refute guide =~ "ARCHITECTURE-CODE-WALKTHROUGH-DNA"
      refute guide =~ ".planning/"
      refute guide =~ "/Users/"
      refute guide =~ "file://"
      refute guide =~ ~r{https://github\.com/[^\s)]+/blob/}
      refute guide =~ ~r{\]\((?:\.\./)*(?:lib|test)/}
      refute guide =~ ~r{#[Ll]\d+(?:-[Ll]\d+)?}
    end
  end

  defp fenced_blocks(markdown, language) do
    ~r/^```#{Regex.escape(language)}\s*\n(.*?)^```\s*$/ms
    |> Regex.scan(markdown, capture: :all_but_first)
    |> List.flatten()
  end

  defp assert_in_order(text, needles) do
    indexes = Enum.map(needles, &index_of!(text, &1))
    assert indexes == Enum.sort(indexes)
  end

  defp index_of!(text, needle) do
    case :binary.match(text, needle) do
      {index, _length} -> index
      :nomatch -> flunk("expected to find #{inspect(needle)}")
    end
  end

  defp assert_anchor(walkthrough, relative_source_path, anchor) do
    source = @repo_root |> Path.join(relative_source_path) |> File.read!()

    assert source =~ anchor
    assert walkthrough =~ anchor
  end
end
