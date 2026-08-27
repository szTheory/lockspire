defmodule Lockspire.Protocol.RequestObject.Claims do
  @moduledoc false

  alias Lockspire.Domain.Client

  @type validation_reason ::
          :invalid_claims_options
          | :missing_issuer
          | :invalid_issuer
          | :missing_audience
          | :invalid_audience
          | :missing_expiration
          | :invalid_expiration
          | :expired_token
          | :expiration_too_far
          | :invalid_not_before
          | :invalid_issued_at

  @spec validate(map(), keyword()) :: :ok | {:error, validation_reason()}
  def validate(claims, opts) when is_map(claims) and is_list(opts) do
    with {:ok, expected_client_id, expected_audience, now, leeway, max_age} <- parse_opts(opts),
         :ok <- check_issuer(claims, expected_client_id),
         :ok <- check_audience(claims, expected_audience),
         :ok <- check_expiration(claims, now, leeway, max_age),
         :ok <- check_not_before(claims, now, leeway) do
      check_issued_at(claims, now, leeway)
    end
  end

  @spec project(map(), Client.t()) :: {:ok, map()}
  def project(claims, %Client{client_id: client_id}) when is_map(claims) do
    {:ok,
     claims
     |> Map.take(
       ~w(redirect_uri response_type scope prompt nonce state code_challenge code_challenge_method)
     )
     |> Map.reject(&is_nil(elem(&1, 1)))
     |> Map.put("client_id", client_id)}
  end

  defp parse_opts(opts) do
    expected_client_id = Keyword.get(opts, :expected_client_id)
    expected_audience = Keyword.get(opts, :expected_audience)
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    leeway = Keyword.get(opts, :leeway, 0)
    max_age = Keyword.get(opts, :max_age)

    with :ok <- validate_present_binary(expected_client_id),
         :ok <- validate_present_binary(expected_audience),
         :ok <- validate_now(now),
         :ok <- validate_leeway(leeway),
         :ok <- validate_max_age(max_age) do
      {:ok, expected_client_id, expected_audience, now, leeway, max_age}
    end
  end

  defp validate_present_binary(value) when is_binary(value) and value != "", do: :ok
  defp validate_present_binary(_value), do: {:error, :invalid_claims_options}
  defp validate_now(%DateTime{}), do: :ok
  defp validate_now(_value), do: {:error, :invalid_claims_options}
  defp validate_leeway(value) when is_integer(value) and value >= 0, do: :ok
  defp validate_leeway(_value), do: {:error, :invalid_claims_options}
  defp validate_max_age(nil), do: :ok
  defp validate_max_age(value) when is_integer(value) and value > 0, do: :ok
  defp validate_max_age(_value), do: {:error, :invalid_claims_options}

  defp check_issuer(claims, expected_client_id) do
    case Map.get(claims, "iss") do
      nil ->
        {:error, :missing_issuer}

      iss when is_binary(iss) ->
        if iss == expected_client_id, do: :ok, else: {:error, :invalid_issuer}

      _ ->
        {:error, :invalid_issuer}
    end
  end

  defp check_audience(claims, expected_audience) do
    case Map.get(claims, "aud") do
      nil ->
        {:error, :missing_audience}

      aud when is_binary(aud) ->
        if aud == expected_audience, do: :ok, else: {:error, :invalid_audience}

      aud when is_list(aud) ->
        validate_audience_list(aud, expected_audience)

      _ ->
        {:error, :invalid_audience}
    end
  end

  defp validate_audience_list(audiences, expected_audience) do
    cond do
      audiences == [] -> {:error, :invalid_audience}
      not Enum.all?(audiences, &is_binary/1) -> {:error, :invalid_audience}
      expected_audience in audiences -> :ok
      true -> {:error, :invalid_audience}
    end
  end

  defp check_expiration(claims, now, leeway, max_age) do
    case Map.get(claims, "exp") do
      nil -> {:error, :missing_expiration}
      exp when is_integer(exp) -> validate_expiration(exp, DateTime.to_unix(now), leeway, max_age)
      _ -> {:error, :invalid_expiration}
    end
  end

  defp validate_expiration(exp, now_unix, leeway, max_age) do
    case check_not_expired(exp, now_unix, leeway) do
      :ok -> check_max_age(exp, now_unix, leeway, max_age)
      error -> error
    end
  end

  defp check_not_expired(exp, now_unix, leeway),
    do: if(exp + leeway > now_unix, do: :ok, else: {:error, :expired_token})

  defp check_max_age(_exp, _now_unix, _leeway, nil), do: :ok

  defp check_max_age(exp, now_unix, leeway, max_age),
    do: if(exp - now_unix <= max_age + leeway, do: :ok, else: {:error, :expiration_too_far})

  defp check_not_before(claims, now, leeway),
    do: check_timestamp(claims, "nbf", now, leeway, :invalid_not_before)

  defp check_issued_at(claims, now, leeway),
    do: check_timestamp(claims, "iat", now, leeway, :invalid_issued_at)

  defp check_timestamp(claims, name, now, leeway, reason) do
    case Map.get(claims, name) do
      nil ->
        :ok

      timestamp when is_integer(timestamp) ->
        if(timestamp - leeway <= DateTime.to_unix(now), do: :ok, else: {:error, reason})

      _ ->
        {:error, reason}
    end
  end
end
