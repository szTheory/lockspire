defmodule Lockspire.Protocol.ManagementTokenLifetimePolicyTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.Registration
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.ServerPolicyRecord
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "openid"])
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  defp dispatch(conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  @tag :management_policy_bounds_red
  test "management duration changeset rejects invalid typed values" do
    baseline = DcrFixtures.server_policy(%{id: ServerPolicyRecord.singleton_id()})

    for seconds <- ["1", true, 1.5, [], %{}, -1, 2_147_483_648] do
      invalid = %ServerPolicy{
        baseline
        | dcr_default_registration_access_token_lifetime_seconds: seconds
      }

      changeset = ServerPolicyRecord.changeset(%ServerPolicyRecord{}, invalid)
      refute changeset.valid?

      assert Keyword.has_key?(
               changeset.errors,
               :dcr_default_registration_access_token_lifetime_seconds
             )
    end
  end

  test "supported management duration values persist and resolve without casting" do
    now = DateTime.from_unix!(100)
    client = %Client{provenance: :self_registered}

    assert {:ok, nil} =
             Client.management_deadline(%Client{provenance: :operator}, now, 20)

    assert {:error, :invalid_lifetime_state} =
             Client.management_deadline(%Client{provenance: :unclassified}, now, 20)

    assert {:error, :invalid_lifetime_state} =
             Client.management_deadline(client, :invalid_time, 20)

    for seconds <- [nil, 0, 1, 2_147_483_647] do
      policy =
        DcrFixtures.server_policy(%{
          id: ServerPolicyRecord.singleton_id(),
          dcr_default_registration_access_token_lifetime_seconds: seconds
        })

      assert ServerPolicyRecord.changeset(%ServerPolicyRecord{}, policy).valid?
      assert {:ok, _persisted} = Repository.put_server_policy(policy)
      assert {:ok, reloaded} = Repository.get_server_policy()
      assert reloaded.dcr_default_registration_access_token_lifetime_seconds == seconds

      assert {:ok, resolved} = DcrPolicy.resolve(reloaded, nil, DcrFixtures.valid_metadata())

      assert resolved.default_registration_access_token_lifetime_seconds == seconds

      expected = if is_integer(seconds) and seconds > 0, do: DateTime.add(now, seconds, :second)
      assert Client.management_deadline(client, now, seconds) == {:ok, expected}
    end
  end

  test "malformed typed duration fails write and use boundaries without durable changes" do
    baseline =
      DcrFixtures.server_policy(%{
        id: ServerPolicyRecord.singleton_id(),
        dcr_default_registration_access_token_lifetime_seconds: 17
      })

    assert {:ok, _} = Repository.put_server_policy(baseline)
    assert {:ok, before_policy} = Repository.get_server_policy()
    assert {:ok, before_clients} = Repository.list_clients()
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    for seconds <- ["1", true, 1.5, [], %{}, -1, 2_147_483_648] do
      invalid = %ServerPolicy{
        baseline
        | dcr_default_registration_access_token_lifetime_seconds: seconds
      }

      changeset = ServerPolicyRecord.changeset(%ServerPolicyRecord{}, invalid)
      refute changeset.valid?

      assert Keyword.has_key?(
               changeset.errors,
               :dcr_default_registration_access_token_lifetime_seconds
             )

      assert {:error, :server_error,
              %{
                field: :default_registration_access_token_lifetime_seconds,
                reason: :invalid_duration
              }} =
               DcrPolicy.resolve(invalid, nil, DcrFixtures.valid_metadata())

      assert Client.management_deadline(
               %Client{provenance: :self_registered},
               DateTime.from_unix!(100),
               seconds
             ) ==
               {:error, :invalid_management_lifetime_policy}

      assert {:error, %Ecto.Changeset{} = stored_changeset} =
               Repository.put_server_policy(invalid)

      assert Keyword.has_key?(
               stored_changeset.errors,
               :dcr_default_registration_access_token_lifetime_seconds
             )

      assert {:error, %Ecto.Changeset{} = admin_changeset} =
               AdminServerPolicy.put_dcr_policy(%{
                 dcr_default_registration_access_token_lifetime_seconds: seconds
               })

      assert Keyword.has_key?(
               admin_changeset.errors,
               :dcr_default_registration_access_token_lifetime_seconds
             )

      assert {:ok, ^before_policy} = Repository.get_server_policy()
      assert {:ok, ^before_clients} = Repository.list_clients()
      assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
    end
  end

  test "malformed policy form values fail while blank and numeric values persist as nil or integers" do
    baseline = DcrFixtures.server_policy(%{id: ServerPolicyRecord.singleton_id()})
    assert {:ok, _} = Repository.put_server_policy(baseline)

    for {text, expected} <- [{"", nil}, {"0", 0}, {"1", 1}, {"2147483647", 2_147_483_647}] do
      changeset =
        PolicyForm.changeset(%{
          "registration_policy" => "open",
          "dcr_default_registration_access_token_lifetime_seconds" => text
        })

      assert changeset.valid?

      value =
        Ecto.Changeset.apply_changes(changeset).dcr_default_registration_access_token_lifetime_seconds

      assert value == expected

      assert {:ok, _} =
               AdminServerPolicy.put_dcr_policy(%{
                 dcr_default_registration_access_token_lifetime_seconds: value
               })

      assert {:ok, reloaded} = Repository.get_server_policy()
      assert reloaded.dcr_default_registration_access_token_lifetime_seconds == expected
    end

    for text <- ["-1", "2147483648", "1.5", "invalid"] do
      refute PolicyForm.changeset(%{
               "registration_policy" => "open",
               "dcr_default_registration_access_token_lifetime_seconds" => text
             }).valid?
    end
  end

  test "invalid in-memory policy rejects registration without client or success-audit writes" do
    policy =
      DcrFixtures.server_policy(%{
        dcr_default_registration_access_token_lifetime_seconds: "20"
      })

    assert {:ok, before_clients} = Repository.list_clients()
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, %Registration.Error{code: :server_error}} =
             Registration.register(
               DcrFixtures.register_request(server_policy: policy)
               |> Map.put(:now, DateTime.from_unix!(100))
             )

    assert {:ok, ^before_clients} = Repository.list_clients()
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "router rejects a corrupt persisted management policy as a redacted server error" do
    assert {:ok, _} =
             Repository.put_server_policy(
               DcrFixtures.server_policy(%{registration_policy: :open})
             )

    Ecto.Adapters.SQL.query!(
      Lockspire.TestRepo,
      "UPDATE lockspire_server_policies SET dcr_default_registration_access_token_lifetime_seconds = -1 WHERE id = 1",
      []
    )

    assert {:ok, clients_before} = Repository.list_clients()
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    conn =
      build_conn(:post, "/register", DcrFixtures.valid_metadata())
      |> dispatch()

    body = Jason.decode!(conn.resp_body)
    assert conn.status == 500
    assert body["error"] == "server_error"

    refute get_resp_header(conn, "www-authenticate")
           |> Enum.any?(&String.contains?(&1, "invalid_token"))

    refute Map.has_key?(body, "registration_access_token")
    refute Map.has_key?(body, "client_secret")
    assert {:ok, ^clients_before} = Repository.list_clients()
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end
end
