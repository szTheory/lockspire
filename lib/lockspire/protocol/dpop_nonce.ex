defmodule Lockspire.Protocol.DPoPNonce do
  @moduledoc """
  Stateless nonce issuance and verification for DPoP proof validation.
  """

  alias Lockspire.Config

  @token_salt "lockspire_dpop_nonce"
  @default_max_age 300

  @type purpose :: :authorization_server | :resource_server
  @type validate_reason :: :missing_dpop_nonce | :invalid_dpop_nonce

  @spec issue(purpose(), keyword()) :: String.t()
  def issue(purpose, opts \\ []) when purpose in [:authorization_server, :resource_server] do
    payload = %{
      "purpose" => Atom.to_string(purpose),
      "nonce_id" => random_nonce_id()
    }

    Plug.Crypto.sign(secret_key_base!(opts), @token_salt, payload)
  end

  @spec validate(map(), purpose(), keyword()) :: :ok | {:error, validate_reason()}
  def validate(claims, purpose, opts \\ [])

  def validate(claims, purpose, opts)
      when is_map(claims) and purpose in [:authorization_server, :resource_server] do
    case Map.get(claims, "nonce") do
      nonce when is_binary(nonce) and nonce != "" ->
        verify_nonce(nonce, purpose, opts)

      _other ->
        {:error, :missing_dpop_nonce}
    end
  end

  def validate(_claims, _purpose, _opts), do: {:error, :missing_dpop_nonce}

  defp verify_nonce(nonce, purpose, opts) do
    case Plug.Crypto.verify(
           secret_key_base!(opts),
           @token_salt,
           nonce,
           max_age: Keyword.get(opts, :nonce_max_age, @default_max_age)
         ) do
      {:ok, %{"purpose" => encoded_purpose, "nonce_id" => nonce_id}} ->
        if encoded_purpose == Atom.to_string(purpose) and is_binary(nonce_id) and nonce_id != "" do
          :ok
        else
          {:error, :invalid_dpop_nonce}
        end

      _other ->
        {:error, :invalid_dpop_nonce}
    end
  end

  defp secret_key_base!(opts) do
    secret_key_base =
      Keyword.get(opts, :secret_key_base) ||
        Config.secret_key_base() ||
        test_secret_key_base()

    case secret_key_base do
      value when is_binary(value) and value != "" ->
        value

      _other ->
        raise ArgumentError,
              "missing Lockspire endpoint secret_key_base required for DPoP nonce signing"
    end
  end

  defp test_secret_key_base do
    if Code.ensure_loaded?(Mix) and function_exported?(Mix, :env, 0) and Mix.env() == :test do
      String.duplicate("a", 64)
    end
  end

  defp random_nonce_id do
    24
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
