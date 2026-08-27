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

  test "protocol does not depend on delivery or operator facades" do
    Enum.each(production_files(@protocol_root), fn path ->
      refute ast_contains?(parse!(path), &protocol_outer_reference?/1),
             "#{path} references Lockspire.Web or Lockspire.Admin"
    end)
  end

  test "registration facades delegate through neutral lifecycle seams" do
    for path <- [
          Path.expand("../../lib/lockspire/clients.ex", __DIR__),
          Path.expand("../../lib/lockspire/admin/clients.ex", __DIR__),
          Path.expand("../../lib/lockspire/protocol/registration.ex", __DIR__),
          Path.expand("../../lib/lockspire/protocol/registration_management.ex", __DIR__)
        ] do
      assert File.read!(path) =~ "ClientLifecycle", "#{path} must delegate lifecycle writes"
    end
  end

  defp production_files(root), do: Path.wildcard(Path.join(root, "**/*.ex"))

  defp parse!(path), do: path |> File.read!() |> Code.string_to_quoted!()

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
  defp protocol_outer_reference?(_node), do: false
end
