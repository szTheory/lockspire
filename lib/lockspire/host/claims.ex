defmodule Lockspire.Host.Claims do
  @moduledoc """
  Structured claim material returned by the host account resolver.
  """

  @protocol_claims ~w(iss aud exp iat nonce at_hash auth_time sub)

  @type claim_set :: map()

  @type t :: %__MODULE__{
          subject: String.t(),
          id_token: claim_set(),
          userinfo: claim_set()
        }

  defstruct subject: nil, id_token: %{}, userinfo: %{}

  @spec build_id_token_claims(t(), claim_set()) :: claim_set()
  def build_id_token_claims(%__MODULE__{} = claims, protocol_claims)
      when is_map(protocol_claims) do
    claims.id_token
    |> Map.drop(@protocol_claims)
    |> Map.put("sub", claims.subject)
    |> Map.merge(protocol_claims)
    |> drop_nil_claims()
  end

  @spec build_userinfo_claims(t()) :: claim_set()
  def build_userinfo_claims(%__MODULE__{} = claims) do
    claims.userinfo
    |> Map.drop(@protocol_claims)
    |> Map.put("sub", claims.subject)
    |> drop_nil_claims()
  end

  defp drop_nil_claims(claims) do
    Map.reject(claims, fn {_key, value} -> is_nil(value) end)
  end
end
