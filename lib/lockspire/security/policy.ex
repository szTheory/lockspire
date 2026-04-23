defmodule Lockspire.Security.Policy do
  @moduledoc """
  Shared security invariants for boot-time posture and protocol/runtime checks.
  """

  @supported_token_endpoint_auth_methods [:none, :client_secret_basic, :client_secret_post]
  @supported_response_types ["code"]
  @supported_signing_algs ["RS256", :RS256]

  @spec fetch_required_config!(atom(), term()) :: term()
  def fetch_required_config!(key, value) do
    case value do
      missing when missing in [nil, ""] ->
        raise ArgumentError,
              "missing required config :#{key} for :lockspire. " <>
                "Set it in config/runtime.exs or config/*.exs."

      present ->
        present
    end
  end

  @spec validate_issuer_and_mount_path!(String.t(), String.t()) :: String.t()
  def validate_issuer_and_mount_path!(issuer, mount_path)
      when is_binary(issuer) and is_binary(mount_path) do
    uri = URI.parse(issuer)
    issuer_path = uri.path || "/"

    cond do
      not absolute_uri?(uri) ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Expected an absolute URL with scheme and host."

      present?(uri.query) ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Query parameters are not allowed."

      present?(uri.fragment) ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Fragments are not allowed."

      issuer_path != mount_path ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Issuer path #{inspect(issuer_path)} must match mount_path #{inspect(mount_path)}."

      true ->
        issuer
    end
  end

  @spec ensure_supported_response_type(String.t() | nil) ::
          :ok | {:error, :unsupported_response_type}
  def ensure_supported_response_type(response_type)
      when response_type in @supported_response_types,
      do: :ok

  def ensure_supported_response_type(_response_type), do: {:error, :unsupported_response_type}

  @spec ensure_supported_token_endpoint_auth_method(atom() | nil) ::
          :ok | {:error, :unsupported_token_endpoint_auth_method}
  def ensure_supported_token_endpoint_auth_method(method)
      when method in @supported_token_endpoint_auth_methods,
      do: :ok

  def ensure_supported_token_endpoint_auth_method(_method),
    do: {:error, :unsupported_token_endpoint_auth_method}

  @spec ensure_signing_alg(String.t() | atom() | nil) :: :ok | {:error, :invalid_signing_alg}
  def ensure_signing_alg(alg) when alg in @supported_signing_algs, do: :ok
  def ensure_signing_alg(_alg), do: {:error, :invalid_signing_alg}

  @spec validate_signing_alg!(String.t() | atom() | nil) :: :ok
  def validate_signing_alg!(alg) do
    case ensure_signing_alg(alg) do
      :ok ->
        :ok

      {:error, :invalid_signing_alg} ->
        raise ArgumentError,
              "invalid :signing_alg for :lockspire. Expected RS256 and never alg=none."
    end
  end

  @spec hash_token(String.t()) :: String.t()
  def hash_token(secret) when is_binary(secret) do
    :sha256
    |> :crypto.hash(secret)
    |> Base.encode16(case: :lower)
  end

  @spec hash_client_secret(String.t()) :: String.t()
  def hash_client_secret(secret) when is_binary(secret) do
    salt = generate_token(16)
    hash = :crypto.hash(:sha256, salt <> secret) |> Base.encode64()
    "sha256:#{salt}:#{hash}"
  end

  @spec verify_client_secret(String.t(), String.t()) :: boolean()
  def verify_client_secret("sha256:" <> rest, client_secret)
      when is_binary(client_secret) do
    case String.split(rest, ":", parts: 2) do
      [salt, expected_hash] ->
        calculated_hash =
          :crypto.hash(:sha256, salt <> client_secret)
          |> Base.encode64()

        secure_compare(expected_hash, calculated_hash)

      _other ->
        false
    end
  end

  def verify_client_secret(_client_secret_hash, _client_secret), do: false

  defp generate_token(size) do
    size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp secure_compare(left, right)
       when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    Plug.Crypto.secure_compare(left, right)
  end

  defp secure_compare(_left, _right), do: false

  defp absolute_uri?(%URI{scheme: scheme, host: host})
       when is_binary(scheme) and scheme != "" and is_binary(host) and host != "",
       do: true

  defp absolute_uri?(_uri), do: false

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true
end
