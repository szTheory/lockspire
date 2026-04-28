# credo:disable-for-this-file
defmodule Lockspire.Protocol.DPoP do
  @moduledoc """
  DPoP proof decoding, verification, and proof-key thumbprint helpers.

  This module owns the protocol-sensitive JOSE work for DPoP proofs so later
  token and protected-resource flows can depend on one validator.
  """

  defstruct [:claims, :header, :public_jwk, :jkt]

  @type t :: %__MODULE__{
          claims: map(),
          header: map(),
          public_jwk: JOSE.JWK.t() | nil,
          jkt: String.t() | nil
        }

  @type validate_reason ::
          :invalid_jwt
          | :invalid_signature
          | :invalid_typ
          | :missing_jwk
          | :invalid_jwk

  @allowed_algorithms ~w(RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 EdDSA)
  @required_typ "dpop+jwt"

  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_jwt}
  def decode(jwt) when is_binary(jwt) do
    try do
      payload_struct = JOSE.JWT.peek_payload(jwt)
      protected_struct = JOSE.JWT.peek_protected(jwt)
      {_modules, claims} = JOSE.JWT.to_map(payload_struct)
      {_modules, header} = JOSE.JWS.to_map(protected_struct)

      {:ok, %__MODULE__{claims: claims, header: header}}
    rescue
      _ -> {:error, :invalid_jwt}
    catch
      _, _ -> {:error, :invalid_jwt}
    end
  end

  def decode(_), do: {:error, :invalid_jwt}

  @spec validate_proof(String.t(), keyword()) :: {:ok, t()} | {:error, validate_reason()}
  def validate_proof(jwt, opts \\ [])
  def validate_proof(jwt, _opts) when is_binary(jwt) do
    with {:ok, %__MODULE__{} = decoded} <- decode(jwt),
         :ok <- check_typ(decoded.header),
         {:ok, public_jwk} <- header_public_jwk(decoded.header),
         {:ok, %__MODULE__{} = verified} <- verify_signature(jwt, public_jwk) do
      {:ok,
       %__MODULE__{
         verified
         | public_jwk: public_jwk,
           jkt: public_jwk |> thumbprint!()
       }}
    end
  end

  def validate_proof(_jwt, _opts), do: {:error, :invalid_jwt}

  @spec thumbprint(JOSE.JWK.t() | map()) :: {:ok, String.t()} | {:error, :invalid_jwk}
  def thumbprint(%JOSE.JWK{} = jwk) do
    {:ok, thumbprint!(JOSE.JWK.to_public(jwk))}
  rescue
    _ -> {:error, :invalid_jwk}
  catch
    _, _ -> {:error, :invalid_jwk}
  end

  def thumbprint(jwk_map) when is_map(jwk_map) do
    with {:ok, public_jwk} <- parse_header_jwk(jwk_map) do
      thumbprint(public_jwk)
    end
  end

  def thumbprint(_), do: {:error, :invalid_jwk}

  defp verify_signature(jwt, public_jwk) do
    try do
      case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, jwt) do
        {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
          {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
          {_modules, header} = JOSE.JWS.to_map(jws_struct)

          case check_typ(header) do
            :ok -> {:ok, %__MODULE__{claims: claims, header: header}}
            {:error, _} = error -> error
          end

        {false, _jwt_struct, _jws_struct} ->
          {:error, :invalid_signature}
      end
    rescue
      _ -> {:error, :invalid_signature}
    catch
      _, _ -> {:error, :invalid_signature}
    end
  end

  defp check_typ(%{"typ" => @required_typ}), do: :ok
  defp check_typ(_header), do: {:error, :invalid_typ}

  defp header_public_jwk(%{"jwk" => jwk_map}) when is_map(jwk_map), do: parse_header_jwk(jwk_map)
  defp header_public_jwk(_header), do: {:error, :missing_jwk}

  defp parse_header_jwk(%{"kty" => "oct"}), do: {:error, :invalid_jwk}

  defp parse_header_jwk(jwk_map) when is_map(jwk_map) do
    try do
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
  end

  defp parse_header_jwk(_), do: {:error, :invalid_jwk}

  defp thumbprint!(%JOSE.JWK{} = jwk) do
    jwk
    |> JOSE.JWK.thumbprint()
    |> IO.iodata_to_binary()
  end
end
