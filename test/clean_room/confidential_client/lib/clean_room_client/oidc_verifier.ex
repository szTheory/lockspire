defmodule CleanRoomClient.OIDCVerifier do
  @moduledoc false
  @clock_skew_seconds 60

  def validate_metadata(metadata, expected_issuer) do
    with ^expected_issuer <- metadata["issuer"],
         jwks_uri when is_binary(jwks_uri) and jwks_uri != "" <- metadata["jwks_uri"],
         algorithms when is_list(algorithms) <- metadata["id_token_signing_alg_values_supported"],
         true <- Enum.all?(algorithms, &(&1 != "none")) do
      {:ok, %{issuer: expected_issuer, jwks_uri: jwks_uri, algorithms: algorithms}}
    else
      _ -> {:error, :invalid_discovery}
    end
  end

  def validate_claims(claims, transaction, metadata) do
    now = System.system_time(:second)

    with issuer <- metadata.issuer,
         ^issuer <- claims["iss"],
         true <- audience?(claims["aud"], transaction.client_id),
         exp when is_integer(exp) and exp + @clock_skew_seconds >= now <- claims["exp"],
         nonce <- transaction.nonce,
         ^nonce <- claims["nonce"],
         sub when is_binary(sub) and sub != "" <- claims["sub"] do
      {:ok, Map.put(claims, "sub", sub)}
    else
      _ -> {:error, :invalid_id_token_claims}
    end
  end

  def same_subject?(%{"sub" => subject}, %{"sub" => subject}) when is_binary(subject), do: true
  def same_subject?(_, _), do: false

  defp audience?(audience, client_id) when is_binary(audience), do: audience == client_id
  defp audience?(audience, client_id) when is_list(audience), do: client_id in audience
  defp audience?(_, _), do: false
end
