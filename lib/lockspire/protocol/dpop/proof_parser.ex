defmodule Lockspire.Protocol.DPoP.ProofParser do
  @moduledoc false

  @type decoded_proof :: %{claims: map(), header: map()}

  @spec decode(String.t()) :: {:ok, decoded_proof()} | {:error, :invalid_jwt}
  def decode(jwt) when is_binary(jwt) do
    payload_struct = JOSE.JWT.peek_payload(jwt)
    protected_struct = JOSE.JWT.peek_protected(jwt)
    {_modules, claims} = JOSE.JWT.to_map(payload_struct)
    {_modules, header} = JOSE.JWS.to_map(protected_struct)

    {:ok, %{claims: claims, header: header}}
  rescue
    _ -> {:error, :invalid_jwt}
  catch
    _, _ -> {:error, :invalid_jwt}
  end

  def decode(_), do: {:error, :invalid_jwt}

  @spec header_public_jwk(map()) :: {:ok, JOSE.JWK.t()} | {:error, :missing_jwk | :invalid_jwk}
  def header_public_jwk(%{"jwk" => jwk_map}) when is_map(jwk_map), do: parse_public_jwk(jwk_map)
  def header_public_jwk(_header), do: {:error, :missing_jwk}

  @spec parse_public_jwk(map()) :: {:ok, JOSE.JWK.t()} | {:error, :invalid_jwk}
  def parse_public_jwk(%{"kty" => "oct"}), do: {:error, :invalid_jwk}

  def parse_public_jwk(jwk_map) when is_map(jwk_map) do
    jwk = JOSE.JWK.from_map(jwk_map)
    public_jwk = JOSE.JWK.to_public(jwk)
    {_modules, public_map} = JOSE.JWK.to_public_map(jwk)

    if Map.equal?(public_map, jwk_map) do
      {:ok, public_jwk}
    else
      {:error, :invalid_jwk}
    end
  rescue
    _ -> {:error, :invalid_jwk}
  catch
    _, _ -> {:error, :invalid_jwk}
  end

  @spec thumbprint(JOSE.JWK.t() | map()) :: {:ok, String.t()} | {:error, :invalid_jwk}
  def thumbprint(%JOSE.JWK{} = jwk) do
    {:ok, thumbprint!(JOSE.JWK.to_public(jwk))}
  rescue
    _ -> {:error, :invalid_jwk}
  catch
    _, _ -> {:error, :invalid_jwk}
  end

  def thumbprint(jwk_map) when is_map(jwk_map) do
    with {:ok, public_jwk} <- parse_public_jwk(jwk_map) do
      thumbprint(public_jwk)
    end
  end

  def thumbprint(_), do: {:error, :invalid_jwk}

  @spec thumbprint!(JOSE.JWK.t()) :: String.t()
  def thumbprint!(%JOSE.JWK{} = jwk) do
    jwk
    |> JOSE.JWK.thumbprint()
    |> IO.iodata_to_binary()
  end
end
