defmodule Lockspire.Storage.ClientVerifierMaintenanceTest do
  use ExUnit.Case, async: false

  alias Lockspire.Storage.ClientVerifierMaintenance
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Ecto.Adapters.SQL.Sandbox

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    unless Process.whereis(Lockspire.TestRepo) do
      start_supervised!(Lockspire.TestRepo)
    end

    Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Sandbox.checkout(Lockspire.TestRepo)

    Application.put_env(
      :lockspire,
      :client_store,
      Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    )

    Application.put_env(
      :lockspire,
      :transaction_store,
      Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    )

    on_exit(fn ->
      Application.delete_env(:lockspire, :client_store)
      Application.delete_env(:lockspire, :transaction_store)
      Application.delete_env(:lockspire, :maintenance_declaration_mode)
    end)

    :ok
  end

  test "preserves the adapter's explicit unsupported capability result" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :unsupported)

    assert {:error, :client_secret_verifier_maintenance_unsupported} =
             ClientVerifierMaintenance.configured()

    assert_received :maintenance_declaration_called
    refute_received {:client_fetch, _}
    refute_received {:inventory_page, _}
  end

  test "rejects a mismatched maintenance declaration before inventory or client access" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :mismatch)

    assert {:error, :client_secret_verifier_maintenance_authority_mismatch} =
             ClientVerifierMaintenance.configured()

    assert_received :maintenance_declaration_called
    refute_received {:client_fetch, _}
    refute_received {:inventory_page, _}
  end

  test "rejects declaration participants that disagree with the selected composition" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :participant_mismatch)

    assert {:error, :client_secret_verifier_maintenance_authority_mismatch} =
             ClientVerifierMaintenance.configured()

    refute_received {:client_fetch, _}
    refute_received {:inventory_page, _}
  end

  test "accepts the declared shared PostgreSQL delegation" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :valid)

    assert {:ok, config} = ClientVerifierMaintenance.configured()
    assert config.client_store == Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    assert config.transaction_store == Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    assert config.audit_store == Repository
  end

  @tag :integration
  @tag :inventory_paging
  test "inventory pages traverse all persisted IDs in exclusive UTF-8 byte order" do
    prefix = "zzzzzzzzzz-verifier-page-#{System.unique_integer([:positive])}-"

    ids = [
      prefix <> "A",
      prefix <> "a",
      prefix <> ".",
      prefix <> "e\u0301",
      prefix <> "é",
      prefix <> "z"
    ]

    Enum.each(ids, fn id ->
      assert {:ok, %Client{}} = Repository.register_client(client(id))
    end)

    expected = Enum.sort_by(ids, &:binary.bin_to_list/1)
    start_cursor = prefix <> " "
    assert {:ok, first} = Repository.verifier_inventory_page(start_cursor, 1)
    assert first.clients |> Enum.map(& &1.client_id) == [hd(expected)]
    assert first.next_cursor == hd(expected)
    refute first.complete?

    pages = [first | collect_pages(first.next_cursor, 1)]
    traversed = Enum.flat_map(pages, &Enum.map(&1.clients, fn client -> client.client_id end))
    assert Enum.filter(traversed, &String.starts_with?(&1, prefix)) == expected
    assert Enum.uniq(traversed) == traversed
    assert List.last(pages).next_cursor == nil
    assert List.last(pages).complete?
    assert utf8_encoding?()

    assert {:ok, %{clients: [], next_cursor: nil, complete?: true}} =
             Repository.verifier_inventory_page("\u{10FFFF}", 1)
  end

  @tag :integration
  test "inventory accepts default and maximum page sizes and includes unfiltered rows" do
    prefix = "zzzzzzzzzz-verifier-page-size-#{System.unique_integer([:positive])}-"
    ids = for n <- 1..501, do: prefix <> String.pad_leading(Integer.to_string(n), 3, "0")

    Enum.each(ids, fn id ->
      attrs =
        cond do
          String.ends_with?(id, "499") ->
            [
              client_type: :confidential,
              token_endpoint_auth_method: :client_secret_jwt,
              client_expires_at: DateTime.add(DateTime.utc_now(), -1, :second)
            ]

          String.ends_with?(id, "500") ->
            [
              client_type: :confidential,
              token_endpoint_auth_method: :client_secret_jwt,
              client_secret_jwt_verifier_encrypted: nil
            ]

          String.ends_with?(id, "501") ->
            [active: false]

          true ->
            []
        end

      assert {:ok, %Client{}} = Repository.register_client(client(id, attrs))
    end)

    start_cursor = prefix <> " "
    assert {:ok, first} = Repository.verifier_inventory_page(start_cursor, 500)
    assert Enum.count(first.clients, &String.starts_with?(&1.client_id, prefix)) == 500
    refute first.complete?
    assert first.next_cursor == List.last(first.clients).client_id

    assert {:ok, second} = Repository.verifier_inventory_page(first.next_cursor, 500)
    assert Enum.count(second.clients, &String.starts_with?(&1.client_id, prefix)) == 1
    assert second.complete?
    assert second.next_cursor == nil
    assert List.first(second.clients).active == false

    all_ids = collect_all(start_cursor, 500, [])
    assert Enum.count(all_ids, &String.starts_with?(&1, prefix)) == 501
    assert Enum.any?(all_ids, &(&1 == List.last(ids)))

    default_ids = collect_all(start_cursor, 100, [])
    assert Enum.count(default_ids, &String.starts_with?(&1, prefix)) == 501
  end

  @tag :integration
  test "inventory validates limits and cursors before querying" do
    for limit <- [0, 501, "1"] do
      assert {:error, :client_secret_verifier_inventory_invalid_limit} =
               Repository.verifier_inventory_page(nil, limit)
    end

    for cursor <- ["", <<255>>, 12, %{}] do
      assert {:error, :client_secret_verifier_inventory_invalid_cursor} =
               Repository.verifier_inventory_page(cursor, 1)
    end
  end

  defp collect_pages(cursor, limit) do
    {:ok, page} = Repository.verifier_inventory_page(cursor, limit)
    if page.complete?, do: [page], else: [page | collect_pages(page.next_cursor, limit)]
  end

  defp collect_all(cursor, limit, acc) do
    {:ok, page} = Repository.verifier_inventory_page(cursor, limit)
    ids = acc ++ Enum.map(page.clients, & &1.client_id)
    if page.complete?, do: ids, else: collect_all(page.next_cursor, limit, ids)
  end

  defp client(id, attrs \\ []) do
    %Client{
      lifetime_version: 0,
      client_id: id,
      client_secret_hash: "test-hash",
      client_secret_jwt_verifier_encrypted: "test-verifier",
      client_type: :public,
      name: "Inventory fixture",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :none,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }
    |> then(fn value -> struct(value, attrs) end)
  end

  defp utf8_encoding? do
    {:ok, %{rows: [[encoding]]}} =
      Ecto.Adapters.SQL.query(Lockspire.TestRepo, "SELECT current_setting('server_encoding')", [],
        log: false,
        telemetry_event: nil
      )

    encoding == "UTF8"
  end
end
