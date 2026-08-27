defmodule CleanRoomClient.DPoP do
  @moduledoc false
  alias Plug.Crypto.{KeyGenerator, MessageEncryptor}

  @aad "clean-room-dpop-v1"

  def new_key do
    key = JOSE.JWK.generate_key({:ec, "P-256"})
    {_fields, private_jwk} = JOSE.JWK.to_map(key)
    public_jwk = Map.take(private_jwk, ["crv", "kty", "x", "y"])
    %{private_jwk: private_jwk, public_jwk: public_jwk, jkt: JOSE.JWK.thumbprint(key)}
  end

  def encrypt(value) when is_binary(value) do
    MessageEncryptor.encrypt(value, @aad, encryption_key(), "")
  end

  def decrypt(ciphertext) when is_binary(ciphertext) do
    MessageEncryptor.decrypt(ciphertext, @aad, encryption_key(), "")
  end

  def proof(private_jwk, method, url, options \\ %{}) do
    key = JOSE.JWK.from(private_jwk)
    {_fields, full_jwk} = JOSE.JWK.to_map(key)
    public_jwk = Map.take(full_jwk, ["crv", "kty", "x", "y"])

    claims =
      %{
        "htu" => url,
        "htm" => method |> to_string() |> String.upcase(),
        "iat" => System.system_time(:second),
        "jti" => :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
      }
      |> maybe_put("nonce", Map.get(options, :nonce))
      |> maybe_put("ath", Map.get(options, :ath))

    JOSE.JWT.sign(key, %{"alg" => "ES256", "typ" => "dpop+jwt", "jwk" => public_jwk}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  def resource_proof(session, method, url, nonce) do
    with {:ok, private_jwk} <- decrypt(session.encrypted_key),
         {:ok, token} <- decrypt(session.encrypted_access_token) do
      {:ok,
       proof(Jason.decode!(private_jwk), method, url, %{
         nonce: nonce,
         ath: access_token_hash(token)
       })}
    end
  end

  def access_token_hash(token),
    do: :crypto.hash(:sha256, token) |> Base.url_encode64(padding: false)

  defp encryption_key do
    secret = Application.fetch_env!(:clean_room_confidential_client, :transaction_cipher_secret)
    KeyGenerator.generate(secret, "clean-room-dpop-key", length: 32)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
