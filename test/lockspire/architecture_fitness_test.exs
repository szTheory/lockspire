defmodule Lockspire.ArchitectureFitnessTest do
  use ExUnit.Case, async: true

  @repository_path Path.expand("../../lib/lockspire/storage/ecto/repository.ex", __DIR__)
  @protocol_root Path.expand("../../lib/lockspire/protocol", __DIR__)
  @token_root Path.join(@protocol_root, "token_exchange")
  @legacy_options_path Path.join(@token_root, "internal/legacy_options.ex")
  @admin_live_files [
    Path.expand("../../lib/lockspire/web/live/admin/interactions_live/index.ex", __DIR__),
    Path.expand("../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex", __DIR__),
    Path.expand("../../lib/lockspire/web/live/admin/overview_live/index.ex", __DIR__)
  ]
  @aggregate_aliases [
    :EctoAuditStore,
    :EctoCibaAuthorizationStore,
    :EctoClientStore,
    :EctoConsentStore,
    :EctoDeviceAuthorizationStore,
    :EctoInitialAccessTokenStore,
    :EctoInteractionStore,
    :EctoLogoutStore,
    :EctoPruningStore,
    :EctoPushedAuthorizationRequestStore,
    :EctoReplayStore,
    :EctoServerPolicyStore,
    :EctoSigningKeyStore,
    :EctoTokenStore,
    :EctoTransactionStore
  ]

  setup_all do
    paths = production_files(@protocol_root) ++ [@repository_path]
    {:ok, asts: Map.new(paths, &{&1, parse!(&1)})}
  end

  test "protocol core does not reach through to Ecto schemas, queries, or host repo", %{
    asts: asts
  } do
    for {path, ast} <- asts, path != @repository_path do
      refute ast_contains?(ast, &protocol_ecto_ownership?/1), "#{path} owns Ecto persistence"
      refute ast_contains?(ast, &host_repo_call?/1), "#{path} calls Lockspire.Config.repo!/0"
    end
  end

  test "LiveViews do not reach through to the Ecto adapter" do
    for path <- @admin_live_files do
      refute ast_contains?(parse!(path), fn
               {:__aliases__, _, [:Lockspire, :Storage, :Ecto, :Repository]} -> true
               _ -> false
             end),
             "#{path} references Lockspire.Storage.Ecto.Repository"
    end
  end

  test "Repository is a behavior-complete pure facade over every aggregate", %{asts: asts} do
    repository = Map.fetch!(asts, @repository_path)

    for behavior <- repository_behaviors(),
        {function, arity} <- behavior.behaviour_info(:callbacks) do
      assert function_exported?(Lockspire.Storage.Ecto.Repository, function, arity),
             "Repository must export #{inspect(behavior)} callback #{function}/#{arity}"
    end

    refute ast_contains?(repository, &repository_aggregate_ownership?/1),
           "#{@repository_path} contains an Ecto record/query/changeset/lock construct; move it to its aggregate"

    for alias_name <- @aggregate_aliases do
      assert ast_contains?(repository, &remote_call_to?(&1, [alias_name])),
             "#{@repository_path} must delegate to #{alias_name}; add the aggregate delegate rather than persistence here"
    end
  end

  test "token grants use focused collaborators and GrantSupport stays a compatibility seam", %{
    asts: asts
  } do
    assert_calls(asts, "internal/authorization_code_grant.ex", [:Dependencies, :GrantSupport])
    assert_calls(asts, "internal/device_code_grant.ex", [:Dependencies, :GrantSupport])
    assert_calls(asts, "internal/ciba_grant.ex", [:Dependencies, :GrantSupport])

    assert_calls(asts, "internal/refresh_exchange.ex", [
      :GrantPersistence,
      :GrantObservability,
      :TokenIssuer
    ])

    assert_calls(asts, "internal/rfc8693_exchange.ex", [:TokenIssuer])

    assert_calls(asts, "internal/grant_support.ex", [
      :ClientAuthentication,
      :GrantPolling,
      :ResourceSelection,
      :TokenIssuer
    ])

    for {path, ast} <- asts,
        String.contains?(path, "/token_exchange/internal/"),
        not String.ends_with?(path, "/authorization_code_grant.ex"),
        not String.ends_with?(path, "/device_code_grant.ex"),
        not String.ends_with?(path, "/ciba_grant.ex") do
      refute ast_contains?(ast, &remote_call_to?(&1, [:GrantSupport])),
             "#{path} reaches broad GrantSupport; call its focused owner instead"
    end
  end

  test "token internals construct explicit dependencies without discovery or option bags", %{
    asts: asts
  } do
    for {path, ast} <- asts,
        String.starts_with?(path, @token_root),
        path != @legacy_options_path do
      refute ast_contains?(ast, &runtime_capability_probe?/1),
             "#{path} performs runtime capability discovery; declare the dependency capability in LegacyOptions"

      refute ast_contains?(ast, &mix_environment_probe?/1),
             "#{path} branches on Mix.env/0; thread configuration through Dependencies"

      refute ast_contains?(ast, &request_option_read?/1),
             "#{path} reads request opts; LegacyOptions is the sole compatibility adapter"
    end

    assert ast_contains?(Map.fetch!(asts, @legacy_options_path), &request_option_read?/1),
           "LegacyOptions must retain the v1.x request option adapter"

    for path <- [
          "internal/authorization_code_grant.ex",
          "internal/device_code_grant.ex",
          "internal/ciba_grant.ex",
          "internal/refresh_exchange.ex",
          "internal/rfc8693_exchange.ex"
        ] do
      absolute = Path.join(@token_root, path)

      assert ast_contains?(Map.fetch!(asts, absolute), &remote_call_to?(&1, [:Dependencies])),
             "#{absolute} must receive the typed Dependencies bundle"
    end
  end

  test "AST predicates reject synthetic regressions and accept the allowed seams" do
    assert repository_aggregate_ownership?(parse_snippet!("import Ecto.Query"))

    assert repository_aggregate_ownership?(
             parse_snippet!("Lockspire.Storage.Ecto.TokenRecord.changeset(record, %{})")
           )

    assert repository_aggregate_ownership?(parse_snippet!("Ecto.Changeset.change(record)"))

    refute repository_aggregate_ownership?(
             parse_snippet!("EctoTokenStore.store_token(repo(), token)")
           )

    assert runtime_capability_probe?(parse_snippet!("function_exported?(Store, :transact, 1)"))
    assert ast_contains?(parse_snippet!("Mix.env() == :test"), &mix_environment_probe?/1)
    assert request_option_read?(parse_snippet!("Map.get(request, :opts, [])"))

    refute runtime_capability_probe?(
             parse_snippet!("Dependencies.validate(dependencies, :refresh)")
           )

    refute request_option_read?(parse_snippet!("dependencies.token_store"))

    assert remote_call_to?(
             parse_snippet!(
               "Lockspire.Protocol.TokenExchange.Internal.TokenIssuer.issue(token, client, request)"
             ),
             [:TokenIssuer]
           )
  end

  test "protocol does not depend on delivery or operator facades", %{asts: asts} do
    for {path, ast} <- asts, path != @repository_path do
      refute ast_contains?(ast, &protocol_outer_reference?/1),
             "#{path} references a delivery or operator facade"
    end
  end

  defp assert_calls(asts, suffix, aliases) do
    {path, ast} = Enum.find(asts, fn {path, _ast} -> String.ends_with?(path, suffix) end)

    for alias_name <- aliases do
      assert ast_contains?(ast, &remote_call_to?(&1, [alias_name])),
             "#{path} must call focused #{alias_name}"
    end
  end

  defp production_files(root), do: Path.wildcard(Path.join(root, "**/*.ex"))
  defp parse!(path), do: path |> File.read!() |> Code.string_to_quoted!()
  defp parse_snippet!(source), do: Code.string_to_quoted!(source)

  defp ast_contains?(ast, predicate),
    do:
      Macro.prewalk(ast, false, fn node, found? -> {node, found? or predicate.(node)} end)
      |> elem(1)

  defp protocol_ecto_ownership?(node), do: repository_aggregate_ownership?(node)

  defp repository_aggregate_ownership?({:import, _, [{:__aliases__, _, [:Ecto, :Query]} | _]}),
    do: true

  defp repository_aggregate_ownership?({:__aliases__, _, [:Lockspire, :Storage, :Ecto, module]}),
    do: String.ends_with?(Atom.to_string(module), "Record")

  defp repository_aggregate_ownership?(
         {{:., _, [{:__aliases__, _, [:Lockspire, :Storage, :Ecto, module]}, _]}, _, _}
       ),
       do: String.ends_with?(Atom.to_string(module), "Record")

  defp repository_aggregate_ownership?(
         {{:., _, [{:__aliases__, _, [:Ecto, :Changeset]}, _]}, _, _}
       ),
       do: true

  defp repository_aggregate_ownership?({:lock, _, _}), do: true
  defp repository_aggregate_ownership?(_node), do: false

  defp host_repo_call?({{:., _, [{:__aliases__, _, [:Lockspire, :Config]}, :repo!]}, _, []}),
    do: true

  defp host_repo_call?(_node), do: false
  defp protocol_outer_reference?({:__aliases__, _, [:Lockspire, :Web | _]}), do: true
  defp protocol_outer_reference?({:__aliases__, _, [:Lockspire, :Admin | _]}), do: true
  defp protocol_outer_reference?({:__aliases__, _, [:Lockspire, :DiscoveryRoutes]}), do: true
  defp protocol_outer_reference?(_node), do: false
  defp runtime_capability_probe?({:function_exported?, _, _}), do: true
  defp runtime_capability_probe?(_node), do: false

  defp mix_environment_probe?({{:., _, [{:__aliases__, _, module}, :env]}, _, _})
       when module in [[:Mix], [:"Elixir", :Mix]],
       do: true

  defp mix_environment_probe?(_node), do: false

  defp request_option_read?({{:., _, [{:__aliases__, _, [:Map]}, :get]}, _, [_, :opts | _]}),
    do: true

  defp request_option_read?(_node), do: false

  defp remote_call_to?({{:., _, [{:__aliases__, _, module}, _function]}, _, _args}, expected),
    do: List.last(module) in expected

  defp remote_call_to?(_node, _expected), do: false

  defp repository_behaviors do
    [
      Lockspire.Storage.ClientStore,
      Lockspire.Storage.InteractionStore,
      Lockspire.Storage.ConsentStore,
      Lockspire.Storage.TokenStore,
      Lockspire.Storage.KeyStore,
      Lockspire.Storage.PushedAuthorizationRequestStore,
      Lockspire.Storage.DeviceAuthorizationStore,
      Lockspire.Storage.CibaAuthorizationStore,
      Lockspire.Storage.DpopReplayStore,
      Lockspire.Storage.ServerPolicyStore,
      Lockspire.Storage.LogoutStore,
      Lockspire.Storage.UsedJtiStore,
      Lockspire.Storage.InitialAccessTokenStore,
      Lockspire.Storage.TransactionStore,
      Lockspire.Storage.AuditStore
    ]
  end
end
