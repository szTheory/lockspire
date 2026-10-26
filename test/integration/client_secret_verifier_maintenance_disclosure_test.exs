defmodule Lockspire.Integration.ClientSecretVerifierMaintenanceDisclosureTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.TestRepo

  setup_all do
    repo_config = Application.fetch_env!(:lockspire, TestRepo)
    Application.put_env(:lockspire, TestRepo, Keyword.put(repo_config, :log, :debug))
    start_supervised!(TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)

    on_exit(fn -> Application.put_env(:lockspire, TestRepo, repo_config) end)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    :ok
  end

  @tag :red_disclosure
  test "existing client SQL operations hide credentials from Logger and query telemetry" do
    markers = markers()
    client_id = unique_id()
    client = client(client_id, markers)

    capture_log([level: :debug], fn ->
      assert {:ok, _persisted} = Repository.register_client(client)
    end)

    handler_id = {__MODULE__, System.unique_integer([:positive, :monotonic])}

    assert :ok =
             :telemetry.attach(
               handler_id,
               [:lockspire, :test_repo, :query],
               &__MODULE__.capture_query/4,
               self()
             )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    capture_log([level: :debug], fn ->
      assert {:ok, persisted} = Repository.fetch_client_by_id(client_id)
      send(self(), {:persisted_disclosure_client, persisted})
    end)

    assert_receive {:persisted_disclosure_client, persisted}

    control_log =
      capture_log([level: :debug], fn ->
        Ecto.Adapters.SQL.query!(TestRepo, "SELECT $1::text", [markers.verifier], log: :debug)
      end)

    control_events = drain_query_events([])

    require_marker(
      control_log,
      markers.verifier,
      "Logger positive control did not capture SQL result"
    )

    unless Enum.any?(control_events, fn {_event, _measurements, metadata} ->
             includes_marker?(inspect(metadata), markers.verifier)
           end) do
      flunk("query telemetry positive control did not capture stored verifier material")
    end

    sensitive_log =
      capture_log([level: :debug], fn ->
        register_markers = Map.put(markers, :management_hash, marker("second-registration-hash"))
        register_client(client(client_id <> "-register", register_markers))
        fetch_client(client_id)
        list_clients(client_id)
        lock_client(persisted)
        find_by_registration_hash(markers.management_hash)
        update_client(persisted)
        manage_registration(persisted)
        rotate_secret(persisted)
      end)

    sensitive_events = drain_query_events([])

    for marker <- Map.values(markers) do
      refute_marker(sensitive_log, marker, "sensitive client query reached Logger")

      unless Enum.all?(sensitive_events, fn {_event, _measurements, metadata} ->
               not includes_marker?(inspect(metadata), marker)
             end) do
        flunk("sensitive client query material reached query telemetry")
      end
    end
  end

  test "database exceptions are mapped before returning from client-store updates" do
    marker = marker("hostile-database-error")
    client_id = unique_id()

    suffix = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    function = "lockspire_disclosure_failure_" <> suffix
    trigger = "lockspire_disclosure_failure_trigger_" <> suffix

    capture_log([level: :debug], fn ->
      assert {:ok, persisted} = Repository.register_client(client(client_id, markers()))

      Ecto.Adapters.SQL.query!(
        TestRepo,
        "CREATE FUNCTION #{function}() RETURNS trigger LANGUAGE plpgsql AS $fn$ BEGIN RAISE EXCEPTION USING MESSAGE = '#{marker}'; END; $fn$",
        []
      )

      Ecto.Adapters.SQL.query!(
        TestRepo,
        "CREATE TRIGGER #{trigger} BEFORE UPDATE ON lockspire_clients FOR EACH ROW EXECUTE FUNCTION #{function}()",
        []
      )

      send(
        self(),
        {:database_update_result,
         Repository.update_client(persisted, %{name: "triggered update"})}
      )
    end)

    assert_receive {:database_update_result, result}

    unless result == {:error, :storage_error} do
      flunk("client-store update returned an unsafe database error")
    end

    refute_marker(inspect(result), marker, "database error marker escaped the client store")
  end

  def capture_query(event, measurements, metadata, owner) do
    send(owner, {:client_query_event, event, measurements, metadata})
  end

  defp register_client(client), do: assert_ok(Repository.register_client(client))

  defp fetch_client(client_id), do: assert_ok(Repository.fetch_client_by_id(client_id))

  defp list_clients(client_id), do: assert_ok(Repository.list_clients(search: client_id))

  defp lock_client(%Client{client_id: client_id}) do
    assert_ok(Repository.transact(fn -> Repository.lock_clients([client_id]) end))
  end

  defp find_by_registration_hash(hash),
    do: assert_ok(Repository.get_client_by_registration_access_token_hash(hash))

  defp update_client(%Client{} = client) do
    assert_ok(Repository.update_client(client, %{name: "updated client"}))
  end

  defp manage_registration(%Client{} = client) do
    audit = audit_attrs(client.client_id)
    new_hash = marker("replacement-registration-hash")

    assert {:ok, _rotated} = Repository.rotate_registration_access_token(client, new_hash, audit)
    assert {:ok, current} = Repository.fetch_client_by_id(client.client_id)
    replacement = %{current | name: "replaced registration"}

    assert {:ok, _replaced} =
             Repository.replace_client_registration(
               current,
               replacement,
               marker("next-registration-hash"),
               audit
             )

    :ok
  end

  defp rotate_secret(%Client{} = client) do
    assert {:ok, current} = Repository.fetch_client_by_id(client.client_id)

    assert {:ok, _rotated} =
             Repository.rotate_client_secret(
               current,
               marker("rotated-client-hash"),
               marker("rotated-verifier"),
               DateTime.utc_now()
             )

    :ok
  end

  defp audit_attrs(client_id) do
    %{
      action: :client_secret_verifier_rewrapped,
      outcome: :succeeded,
      actor: %{type: :system},
      resource: %{type: :client, id: client_id},
      metadata: %{maintenance_at: DateTime.utc_now()}
    }
  end

  defp client(client_id, markers) do
    %Client{
      client_id: client_id,
      client_secret_hash: markers.hash,
      client_secret_jwt_verifier_encrypted: markers.verifier,
      registration_access_token_hash: markers.management_hash,
      client_type: :confidential,
      name: "Disclosure test client",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }
  end

  defp markers do
    %{
      hash: marker("client-hash"),
      verifier: marker("jwt-verifier"),
      management_hash: marker("registration-hash")
    }
  end

  defp marker(kind), do: "stored-secret-sentinel-" <> kind

  defp unique_id,
    do: "disclosure-" <> Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)

  defp drain_query_events(events) do
    receive do
      {:client_query_event, event, measurements, metadata} ->
        drain_query_events([{event, measurements, metadata} | events])
    after
      0 -> Enum.reverse(events)
    end
  end

  defp includes_marker?(value, marker), do: String.contains?(value, marker)

  defp require_marker(value, marker, message) do
    unless includes_marker?(value, marker), do: flunk(message)
  end

  defp refute_marker(value, marker, message) do
    if includes_marker?(value, marker), do: flunk(message)
  end

  defp assert_ok({:ok, _result}), do: :ok

  defp assert_ok({:error, reason}) when is_atom(reason),
    do: flunk("client operation error: #{reason}")

  defp assert_ok({:error, %{__struct__: module}}),
    do: flunk("client operation returned an error struct: #{inspect(module)}")

  defp assert_ok(_result), do: flunk("client repository operation did not succeed")
end
