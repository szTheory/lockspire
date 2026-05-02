defmodule Lockspire.Protocol.Jwks do
  @moduledoc """
  Builds a public JWK set from publishable durable signing keys.
  """

  alias Lockspire.Domain.SigningKey

  @public_jwk_members ~w(alg crv e kid key_ops kty n use x x5c x5t x5t#S256 y)

  @spec public_jwk_set(keyword()) :: {:ok, map()} | {:error, term()}
  def public_jwk_set(opts \\ []) do
    key_store = Keyword.get(opts, :key_store, Lockspire.Storage.Ecto.Repository)

    security_profile =
      case Lockspire.Storage.Ecto.Repository.get_server_policy() do
        {:ok, policy} -> policy.security_profile
        _ -> :none
      end

    with {:ok, keys} <- key_store.list_publishable_keys(security_profile: security_profile) do
      {:ok, %{"keys" => Enum.map(keys, &to_public_jwk/1)}}
    end
  end

  defp to_public_jwk(%SigningKey{} = key) do
    key.public_jwk
    |> Map.take(@public_jwk_members)
    |> Map.put_new("kid", key.kid)
    |> Map.put_new("kty", Atom.to_string(key.kty))
    |> Map.put_new("alg", key.alg)
    |> Map.put_new("use", Atom.to_string(key.use))
  end
end
