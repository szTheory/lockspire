defmodule Lockspire.Protocol.DPoP do
  @moduledoc """
  DPoP proof decoding, verification, and proof-key thumbprint helpers.

  This public coordinator keeps the protocol contract stable while focused
  parser and verifier modules handle the security-sensitive JOSE details.
  """

  alias Lockspire.Protocol.DPoP.ProofParser
  alias Lockspire.Protocol.DPoP.ProofVerifier
  alias Lockspire.Protocol.SecurityProfile

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
          | :invalid_claims_options
          | :missing_htm
          | :invalid_htm
          | :missing_htu
          | :invalid_htu
          | :missing_iat
          | :invalid_iat
          | :stale_iat
          | :future_iat
          | :missing_jti
          | :unsupported_signing_algorithm
          | :missing_dpop_nonce
          | :invalid_dpop_nonce

  @spec signing_alg_values_supported() :: [String.t()]
  def signing_alg_values_supported, do: SecurityProfile.allowed_signing_algorithms(:none)

  @spec signing_alg_values_supported(struct() | :fapi_2_0_security | :none) :: [String.t()]
  def signing_alg_values_supported(%SecurityProfile.Resolved{effective_profile: profile}),
    do: SecurityProfile.allowed_signing_algorithms(profile)

  def signing_alg_values_supported(profile) when is_atom(profile),
    do: SecurityProfile.allowed_signing_algorithms(profile)

  @spec access_token_ath(String.t()) :: String.t()
  def access_token_ath(access_token) when is_binary(access_token) do
    access_token
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_jwt}
  def decode(jwt) do
    with {:ok, %{claims: claims, header: header}} <- ProofParser.decode(jwt) do
      {:ok, %__MODULE__{claims: claims, header: header}}
    end
  end

  @spec validate_proof(String.t(), keyword()) :: {:ok, t()} | {:error, validate_reason()}
  def validate_proof(jwt, opts \\ [])

  def validate_proof(jwt, opts) when is_binary(jwt) do
    security_profile = Keyword.get(opts, :security_profile, %SecurityProfile.Resolved{})

    with {:ok, %{header: header}} <- ProofParser.decode(jwt),
         :ok <- ProofVerifier.check_typ(header),
         {:ok, public_jwk} <- ProofParser.header_public_jwk(header),
         {:ok, verified} <- ProofVerifier.verify_signature(jwt, public_jwk, security_profile),
         :ok <- ProofVerifier.validate_claims(verified.claims, opts) do
      {:ok,
       %__MODULE__{
         claims: verified.claims,
         header: verified.header,
         public_jwk: public_jwk,
         jkt: ProofParser.thumbprint!(public_jwk)
       }}
    end
  end

  def validate_proof(_jwt, _opts), do: {:error, :invalid_jwt}

  @spec thumbprint(JOSE.JWK.t() | map()) :: {:ok, String.t()} | {:error, :invalid_jwk}
  defdelegate thumbprint(jwk), to: ProofParser
end
