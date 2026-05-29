defmodule Mix.Tasks.Lockspire.Doctor.TokenFormatTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Mix.Task.reenable("lockspire.doctor")
    Mix.Task.reenable("lockspire.doctor.token_format")

    {:ok, _nil_client} = register_client("doctor-token-format-nil", nil)
    {:ok, _opaque_client} = register_client("doctor-token-format-opaque", :opaque)

    :ok
  end

  test "reports the nil-format client as effective :jwt and flags it changed" do
    output =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["token_format"])
      end)

    assert output =~ "doctor-token-format-nil: jwt"
    assert output =~ "CHANGED"
  end

  test "reports the explicit-:opaque client as :opaque and does not flag it" do
    output =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["token_format"])
      end)

    assert output =~ "doctor-token-format-opaque: opaque"

    opaque_line =
      output
      |> String.split("\n")
      |> Enum.find("", &(&1 =~ "doctor-token-format-opaque"))

    refute opaque_line =~ "CHANGED"
  end

  test "does not raise on flagged clients (read-only, diagnostic-only)" do
    # The capture returning normally is the proof the run did not raise.
    output =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["token_format"])
      end)

    assert is_binary(output)
  end

  test "precedence parity: nil client tracks the server default like the signer" do
    output_default =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["token_format"])
      end)

    nil_line_default =
      output_default
      |> String.split("\n")
      |> Enum.find("", &(&1 =~ "doctor-token-format-nil"))

    assert nil_line_default =~ "doctor-token-format-nil: jwt"

    {:ok, _policy} = ServerPolicy.put_access_token_format(:opaque)

    Mix.Task.reenable("lockspire.doctor")
    Mix.Task.reenable("lockspire.doctor.token_format")

    output_opaque =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["token_format"])
      end)

    nil_line_opaque =
      output_opaque
      |> String.split("\n")
      |> Enum.find("", &(&1 =~ "doctor-token-format-nil"))

    assert nil_line_opaque =~ "doctor-token-format-nil: opaque"
  end

  test "--help output documents the dispatcher command spelling" do
    help =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["token_format", "--help"])
      end)

    assert help =~ "mix lockspire.doctor token_format"
  end

  defp register_client(client_id, access_token_format) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: "sha256:#{client_id}:hash",
      client_type: :confidential,
      name: "Token Format Test #{client_id}",
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      access_token_format: access_token_format,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end
end
