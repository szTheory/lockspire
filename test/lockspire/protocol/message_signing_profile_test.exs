defmodule Lockspire.Protocol.MessageSigningProfileTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Protocol.MessageSigningProfile
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Lockspire.TestRepo.delete_all(Lockspire.Storage.Ecto.SigningKeyRecord)
    :ok
  end

  test "readiness returns stable missing-prerequisite reason when signing posture is absent" do
    assert %{
             ready?: false,
             profile: :fapi_2_0_message_signing,
             prerequisite_reasons: [:missing_compliant_publishable_key]
           } = MessageSigningProfile.readiness()
  end

  test "readiness passes when compliant signing posture exists" do
    now = DateTime.utc_now()

    assert {:ok, _} =
             Repository.publish_key(%SigningKey{
               kid: "strict-ready",
               use: :sig,
               status: :active,
               published_at: now,
               activated_at: now,
               public_jwk: %{
                 "kty" => "EC",
                 "crv" => "P-256",
                 "kid" => "strict-ready",
                 "alg" => "ES256",
                 "use" => "sig"
               },
               private_jwk_encrypted: <<1>>,
               kty: :EC,
               alg: "ES256"
             })

    assert %{ready?: true, prerequisite_reasons: [], remediation: []} =
             MessageSigningProfile.readiness()
  end

  test "readiness remediation is reusable by admin surfaces" do
    readiness = MessageSigningProfile.readiness()

    assert is_list(readiness.remediation)
    assert Enum.all?(readiness.remediation, &is_binary/1)
    assert readiness.remediation != []
  end
end
