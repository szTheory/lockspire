defmodule Lockspire.Protocol.ClientSecretLifetimePolicyTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.Registration
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.ServerPolicyRecord
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  test "supported secret duration values persist and resolve" do
    for seconds <- [nil, 0, 1, 2_147_483_647] do
      policy =
        DcrFixtures.server_policy(%{
          id: ServerPolicyRecord.singleton_id(),
          dcr_default_client_secret_lifetime_seconds: seconds
        })

      assert ServerPolicyRecord.changeset(%ServerPolicyRecord{}, policy).valid?
      assert {:ok, persisted} = Repository.put_server_policy(policy)
      assert persisted.dcr_default_client_secret_lifetime_seconds == seconds

      assert {:ok, resolved} =
               DcrPolicy.resolve(policy, nil, DcrFixtures.valid_metadata())

      assert resolved.default_client_secret_lifetime_seconds == seconds
    end
  end

  test "rejects string-valued programmatic secret duration instead of Ecto-coercing it" do
    baseline =
      DcrFixtures.server_policy(%{
        id: ServerPolicyRecord.singleton_id(),
        dcr_default_client_secret_lifetime_seconds: 17
      })

    assert {:ok, _} = Repository.put_server_policy(baseline)
    assert {:ok, before_policy} = Repository.get_server_policy()
    assert {:ok, before_clients} = Repository.list_clients()

    for seconds <- ["1", true, 1.5, %{}, [], -1, 2_147_483_648] do
      invalid = %ServerPolicy{baseline | dcr_default_client_secret_lifetime_seconds: seconds}
      changeset = ServerPolicyRecord.changeset(%ServerPolicyRecord{}, invalid)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :dcr_default_client_secret_lifetime_seconds)

      assert {:error, :server_error,
              %{field: :default_client_secret_lifetime_seconds, reason: :invalid_duration}} =
               DcrPolicy.resolve(invalid, nil, DcrFixtures.valid_metadata())

      assert {:error, %Ecto.Changeset{} = changeset} = Repository.put_server_policy(invalid)
      assert Keyword.has_key?(changeset.errors, :dcr_default_client_secret_lifetime_seconds)

      assert {:error, %Ecto.Changeset{}} =
               AdminServerPolicy.put_dcr_policy(%{
                 dcr_default_client_secret_lifetime_seconds: seconds
               })

      assert {:ok, ^before_policy} = Repository.get_server_policy()
      assert {:ok, ^before_clients} = Repository.list_clients()
    end
  end

  test "secret policy failure at registration use is a server error without writes" do
    policy =
      DcrFixtures.server_policy(%{dcr_default_client_secret_lifetime_seconds: "10"})

    assert {:ok, before_clients} = Repository.list_clients()

    assert {:error, %Registration.Error{code: :server_error}} =
             Registration.register(
               DcrFixtures.register_request(
                 server_policy: policy,
                 metadata: DcrFixtures.valid_metadata()
               )
               |> Map.put(:now, DateTime.from_unix!(100))
             )

    assert {:ok, ^before_clients} = Repository.list_clients()
  end

  test "DCR policy form casts blank and numeric secret duration text and rejects bad ranges" do
    for value <- ["", "0", "1", "2147483647"] do
      assert PolicyForm.changeset(%{
               "registration_policy" => "open",
               "dcr_default_client_secret_lifetime_seconds" => value
             }).valid?
    end

    for value <- ["-1", "2147483648", "1.5", "invalid"] do
      refute PolicyForm.changeset(%{
               "registration_policy" => "open",
               "dcr_default_client_secret_lifetime_seconds" => value
             }).valid?
    end
  end
end
