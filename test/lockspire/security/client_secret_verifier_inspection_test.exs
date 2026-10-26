defmodule Lockspire.Security.ClientSecretVerifierInspectionTest do
  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.ClientRecord

  test "stored credentials are hidden throughout supported nested inspections" do
    hash = marker("client-hash")
    verifier = marker("jwt-verifier")
    management_hash = marker("registration-hash")
    secret = marker("one-time-secret")

    client = %Client{
      client_id: "inspection-client",
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      registration_access_token_hash: management_hash
    }

    record = %ClientRecord{
      client_id: client.client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      registration_access_token_hash: management_hash
    }

    outputs = [
      inspect(record),
      inspect(Changeset.change(record)),
      inspect(client),
      inspect([client]),
      inspect({:client, client}),
      inspect(%{result: {:ok, client}}),
      inspect(%RegistrationResult{client: client, client_secret: secret}),
      inspect(%{client: client, client_secret: secret}.client)
    ]

    for output <- outputs do
      refute_marker(output, hash)
      refute_marker(output, verifier)
      refute_marker(output, management_hash)
    end

    # The explicit one-time handoff remains available through the existing public shape.
    handoff = %{client: client, client_secret: secret}
    assert Map.keys(handoff) |> Enum.sort() == [:client, :client_secret]
    assert handoff.client.client_id == "inspection-client"
    assert handoff.client_secret == secret

    assert Map.keys(%RegistrationResult{client: client, client_secret: secret}) |> Enum.sort() ==
             [:client, :client_secret]

    assert %RegistrationResult{client: ^client, client_secret: ^secret} =
             %RegistrationResult{client: client, client_secret: secret}

    assert Map.keys(%{
             client_secret: secret,
             client_secret_hash: hash,
             client_secret_jwt_verifier_encrypted: verifier
           })
           |> Enum.sort() ==
             [:client_secret, :client_secret_hash, :client_secret_jwt_verifier_encrypted]
  end

  defp marker(kind), do: "inspect-sentinel-" <> kind

  defp refute_marker(output, marker) do
    unless not String.contains?(output, marker) do
      flunk("stored credential sentinel leaked through inspection")
    end
  end
end
