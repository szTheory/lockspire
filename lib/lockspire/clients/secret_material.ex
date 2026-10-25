defmodule Lockspire.Clients.SecretMaterial do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  @secret_bytes 32
  @safe_reasons [
    :client_secret_verifier_configuration_invalid,
    :client_secret_verifier_identity_missing,
    :client_secret_verifier_key_missing,
    :client_secret_verifier_unavailable,
    :legacy_secret_key_base_missing
  ]

  @spec generate(term(), keyword()) :: {:ok, map()} | {:error, atom()}
  def generate(client_id, opts) when is_list(opts) do
    secret = generate_token(@secret_bytes)
    context = Config.client_secret_verifier_context(opts)

    case seal(context, client_id, secret, opts) do
      {:ok, verifier} ->
        {:ok,
         %{
           client_secret: secret,
           client_secret_hash: Policy.hash_client_secret(secret),
           client_secret_jwt_verifier_encrypted: verifier
         }}

      {:error, reason} when reason in @safe_reasons ->
        {:error, reason}

      {:error, _reason} ->
        {:error, :client_secret_verifier_unavailable}

      _other ->
        {:error, :client_secret_verifier_unavailable}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  def generate(_client_id, _opts),
    do: {:error, :client_secret_verifier_configuration_invalid}

  defp seal(%Context{state: :absent}, _client_id, secret, opts) do
    {:ok, Policy.seal_client_secret_jwt_verifier(secret, opts)}
  rescue
    ArgumentError -> {:error, :legacy_secret_key_base_missing}
  end

  defp seal(%Context{state: :valid, write_mode: :legacy}, _client_id, secret, opts) do
    {:ok, Policy.seal_client_secret_jwt_verifier(secret, opts)}
  rescue
    ArgumentError -> {:error, :legacy_secret_key_base_missing}
  end

  defp seal(%Context{state: :valid, write_mode: :dedicated} = context, client_id, secret, _opts) do
    ClientSecretVerifier.seal(context, client_id, secret)
  end

  defp seal(%Context{}, _client_id, _secret, _opts),
    do: {:error, :client_secret_verifier_configuration_invalid}

  defp seal(_context, _client_id, _secret, _opts),
    do: {:error, :client_secret_verifier_configuration_invalid}

  defp generate_token(size) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
