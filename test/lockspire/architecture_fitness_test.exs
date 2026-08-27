defmodule Lockspire.ArchitectureFitnessTest do
  use ExUnit.Case, async: true

  @protocol_root Path.expand("../../lib/lockspire/protocol", __DIR__)
  @admin_live_files [
    Path.expand("../../lib/lockspire/web/live/admin/interactions_live/index.ex", __DIR__),
    Path.expand("../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex", __DIR__),
    Path.expand("../../lib/lockspire/web/live/admin/overview_live/index.ex", __DIR__)
  ]

  test "protocol core does not reach through to Ecto schemas, queries, or host repo" do
    Enum.each(production_files(@protocol_root), fn path ->
      ast = parse!(path)

      refute ast_contains?(ast, fn
               {:import, _, [{:__aliases__, _, [:Ecto, :Query]} | _]} -> true
               _ -> false
             end),
             "#{path} imports Ecto.Query"

      refute ast_contains?(ast, fn
               {:__aliases__, _, [:Lockspire, :Storage, :Ecto, module]} ->
                 String.ends_with?(Atom.to_string(module), "Record")

               _ ->
                 false
             end),
             "#{path} references an Ecto record"

      refute ast_contains?(ast, &host_repo_call?/1), "#{path} calls Lockspire.Config.repo!/0"
    end)
  end

  test "LiveViews do not reach through to the Ecto adapter" do
    Enum.each(@admin_live_files, fn path ->
      refute ast_contains?(parse!(path), fn
               {:__aliases__, _, [:Lockspire, :Storage, :Ecto, :Repository]} -> true
               _ -> false
             end),
             "#{path} references Lockspire.Storage.Ecto.Repository"
    end)
  end

  test "Repository implements the explicit persistence ports and TestRepo stays ordinary" do
    assert function_exported?(Lockspire.Storage.Ecto.Repository, :replace_client_registration, 4)
    assert function_exported?(Lockspire.Storage.Ecto.Repository, :redeem_initial_access_token, 2)

    assert function_exported?(
             Lockspire.Storage.Ecto.Repository,
             :mark_logout_delivery_enqueued,
             2
           )

    assert function_exported?(Lockspire.Storage.Ecto.Repository, :transact, 1)
    assert function_exported?(Lockspire.Storage.Ecto.Repository, :append_audit_event, 1)

    refute function_exported?(Lockspire.TestRepo, :fetch_active_signing_key, 1)
    refute function_exported?(Lockspire.TestRepo, :get_server_policy, 0)
    refute function_exported?(Lockspire.TestRepo, :record_dpop_proof, 1)
  end

  test "Repository delegates every signing-key storage behavior to its aggregate" do
    ast = parse!(Path.expand("../../lib/lockspire/storage/ecto/repository.ex", __DIR__))

    for {function, arity} <- Lockspire.Storage.KeyStore.behaviour_info(:callbacks) do
      assert function_exported?(Lockspire.Storage.Ecto.Repository, function, arity)

      assert ast_contains?(ast, &signing_key_store_call?(&1, function)),
             "Repository must delegate #{function}/#{arity} to SigningKeyStore"
    end

    refute ast_contains?(ast, fn
             {:__aliases__, _, [:Lockspire, :Storage, :Ecto, :SigningKeyRecord]} -> true
             _ -> false
           end),
           "Repository must not own signing-key record queries or lifecycle transitions"
  end

  test "protocol does not depend on delivery or operator facades" do
    Enum.each(production_files(@protocol_root), fn path ->
      refute ast_contains?(parse!(path), &protocol_outer_reference?/1),
             "#{path} references a delivery or operator facade"
    end)
  end

  test "registration facades delegate writes inward and do not own audit transactions" do
    facade_paths = [
      Path.expand("../../lib/lockspire/clients.ex", __DIR__),
      Path.expand("../../lib/lockspire/admin/clients.ex", __DIR__),
      Path.expand("../../lib/lockspire/protocol/registration.ex", __DIR__),
      Path.expand("../../lib/lockspire/protocol/registration_management.ex", __DIR__)
    ]

    Enum.each(facade_paths, fn path ->
      ast = parse!(path)

      assert ast_contains?(ast, &lifecycle_call?/1),
             "#{path} must call Lockspire.ClientLifecycle rather than own writes"

      refute ast_contains?(ast, &facade_lifecycle_bypass?/1),
             "#{path} must not bypass ClientLifecycle for persistence or audit ownership"
    end)

    for path <- Enum.take(facade_paths, 3) do
      assert ast_contains?(parse!(path), &metadata_call?/1),
             "#{path} must delegate shared metadata operations to Lockspire.ClientMetadata"
    end
  end

  test "AST predicates reject indirect delivery and ownership violations" do
    assert ast_contains?(
             parse_snippet!("Lockspire.DiscoveryRoutes.paths()"),
             &protocol_outer_reference?/1
           )

    assert ast_contains?(
             parse_snippet!("Lockspire.Web.Router.__info__(:functions)"),
             &protocol_outer_reference?/1
           )

    refute ast_contains?(
             parse_snippet!("Lockspire.Protocol.Discovery.openid_configuration([])"),
             &protocol_outer_reference?/1
           )

    assert lifecycle_call?(parse_snippet!("Lockspire.ClientLifecycle.persist_direct(client)"))
    refute lifecycle_call?(parse_snippet!("Lockspire.ClientMetadata.validate_direct(attrs)"))
    assert metadata_call?(parse_snippet!("Lockspire.ClientMetadata.validate_direct(attrs)"))
    refute metadata_call?(parse_snippet!("Lockspire.ClientLifecycle.persist_direct(client)"))

    assert facade_lifecycle_bypass?(
             parse_snippet!("Lockspire.Storage.Ecto.Repository.transact(fn -> :ok end)")
           )

    assert facade_lifecycle_bypass?(
             parse_snippet!("Lockspire.Storage.Ecto.Repository.append_audit_event(event)")
           )

    assert facade_lifecycle_bypass?(
             parse_snippet!(
               "Lockspire.Storage.Ecto.Repository.rotate_client_secret(client, hash, verifier, now)"
             )
           )

    assert facade_lifecycle_bypass?(
             parse_snippet!(
               "Lockspire.Storage.Ecto.Repository.rotate_registration_access_token(client, hash, event)"
             )
           )

    refute facade_lifecycle_bypass?(
             parse_snippet!("Lockspire.ClientLifecycle.transact_with_audit(fun, audit)")
           )
  end

  defp production_files(root), do: Path.wildcard(Path.join(root, "**/*.ex"))

  defp parse!(path), do: path |> File.read!() |> Code.string_to_quoted!()
  defp parse_snippet!(source), do: Code.string_to_quoted!(source)

  defp ast_contains?(ast, predicate) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn node, found? -> {node, found? or predicate.(node)} end)

    found?
  end

  defp host_repo_call?({{:., _, [{:__aliases__, _, [:Lockspire, :Config]}, :repo!]}, _, []}),
    do: true

  defp host_repo_call?(_node), do: false

  defp protocol_outer_reference?({:__aliases__, _, [:Lockspire, :Web | _]}), do: true
  defp protocol_outer_reference?({:__aliases__, _, [:Lockspire, :Admin | _]}), do: true
  defp protocol_outer_reference?({:__aliases__, _, [:Lockspire, :DiscoveryRoutes]}), do: true
  defp protocol_outer_reference?(_node), do: false

  defp lifecycle_call?(node),
    do:
      remote_call_to?(node, [:Lockspire, :ClientLifecycle]) or
        remote_call_to?(node, [:ClientLifecycle])

  defp metadata_call?(node),
    do:
      remote_call_to?(node, [:Lockspire, :ClientMetadata]) or
        remote_call_to?(node, [:ClientMetadata])

  defp facade_lifecycle_bypass?(node) do
    Enum.any?(
      [
        :register_client,
        :update_client,
        :set_client_active,
        :rotate_client_secret,
        :rotate_registration_access_token,
        :replace_client_registration,
        :transact,
        :transact_with_audit,
        :append_audit_event
      ],
      &repository_call?(node, &1)
    )
  end

  defp repository_call?(node, function),
    do:
      remote_call_to?(node, [:Lockspire, :Storage, :Ecto, :Repository], function) or
        remote_call_to?(node, [:Repository], function)

  defp signing_key_store_call?(node, function),
    do:
      remote_call_to?(
        node,
        [:EctoSigningKeyStore],
        function
      ) or
        remote_call_to?(
          node,
          [:Lockspire, :Storage, :Ecto, :Repository, :SigningKeyStore],
          function
        )

  defp remote_call_to?(
         {{:., _, [{:__aliases__, _, module}, function]}, _, _args},
         module,
         expected
       )
       when function == expected,
       do: true

  defp remote_call_to?(_node, _module, _function), do: false

  defp remote_call_to?({{:., _, [{:__aliases__, _, module}, _function]}, _, _args}, module),
    do: true

  defp remote_call_to?(_node, _module), do: false
end
