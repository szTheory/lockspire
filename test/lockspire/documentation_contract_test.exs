defmodule Lockspire.DocumentationContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @architecture_path Path.join(@repo_root, "docs/architecture.md")
  @walkthrough_path Path.join(@repo_root, "docs/code-walkthrough.md")
  @readme_path Path.join(@repo_root, "README.md")

  test "architecture and walkthrough are wired into ExDoc, README, and package inputs" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)
    extras = Keyword.fetch!(docs, :extras)
    guides = docs |> Keyword.fetch!(:groups_for_extras) |> Keyword.fetch!(:Guides)
    package_files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)
    readme = File.read!(@readme_path)

    expected_order = [
      "docs/oauth-oidc-for-phoenix-adopters.md",
      "docs/architecture.md",
      "docs/code-walkthrough.md",
      "docs/getting-started.md"
    ]

    assert consecutive_slice?(extras, expected_order)
    assert consecutive_slice?(guides, expected_order)

    assert_in_order(readme, [
      "[OAuth/OIDC for Phoenix adopters](docs/oauth-oidc-for-phoenix-adopters.md)",
      "[Architecture](docs/architecture.md)",
      "[Code walkthrough](docs/code-walkthrough.md)",
      "[Getting started](docs/getting-started.md)"
    ])

    assert "docs/architecture.md" in package_files
    assert "docs/code-walkthrough.md" in package_files
    assert "brandbook/logo/lockspire-favicon.svg" in package_files
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
      "lib/lockspire/generators/install.ex",
      "Enum.filter(&(&1.template.ownership == :managed))"
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
    assert Code.ensure_loaded?(Lockspire.Protocol.TokenExchange.GrantSupport)
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
    assert walkthrough =~ "Lockspire.Protocol.TokenExchange.GrantSupport"

    assert_anchor(
      walkthrough,
      "lib/lockspire/protocol/refresh_exchange.ex",
      "{:error, :reuse_detected}"
    )

    assert_anchor(
      walkthrough,
      "lib/lockspire/storage/ecto/repository.ex",
      "defp locked_refresh_token_query(token_hash)"
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

  defp consecutive_slice?(list, expected) do
    list
    |> Enum.chunk_every(length(expected), 1, :discard)
    |> Enum.any?(&(&1 == expected))
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
