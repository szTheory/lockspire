defmodule CleanRoomClient.OAuthHttp do
  @moduledoc false

  def token_exchange(endpoint, transaction, profile, options \\ %{}) do
    headers = [
      {"authorization",
       basic(Map.fetch!(profile, :client_id), Map.fetch!(profile, :client_secret))}
    ]

    headers =
      if profile.mode == :dpop,
        do: [{"dpop", Map.fetch!(options, :proof)} | headers],
        else: headers

    form =
      URI.encode_query(%{
        "grant_type" => "authorization_code",
        "code" => Map.fetch!(options, :code),
        "redirect_uri" => transaction.callback_uri,
        "code_verifier" => transaction.verifier,
        "resource" => Map.fetch!(options, :resource)
      })

    request(:post, endpoint, headers, form)
  end

  def userinfo(endpoint, token, proof) do
    request(:get, endpoint, [{"authorization", "DPoP " <> token}, {"dpop", proof}], "")
  end

  def bearer_get(endpoint, token),
    do: request(:get, endpoint, [{"authorization", "Bearer " <> token}], "")

  def get_json(endpoint), do: request(:get, endpoint, [], "")

  def request(method, url, headers, body) do
    request_headers =
      Enum.map(headers, fn {key, value} ->
        {String.to_charlist(key), String.to_charlist(value)}
      end)

    request = {String.to_charlist(url), request_headers}

    result =
      if method == :post do
        {url, headers} = request

        :httpc.request(
          :post,
          {url, headers, ~c"application/x-www-form-urlencoded", String.to_charlist(body)},
          [],
          []
        )
      else
        :httpc.request(:get, request, [], [])
      end

    case result do
      {:ok, {{_version, status, _reason}, response_headers, response_body}} ->
        {:ok, status, headers_to_map(response_headers), IO.iodata_to_binary(response_body)}

      {:error, _reason} ->
        {:error, :provider_unavailable}
    end
  end

  defp basic(id, secret), do: "Basic " <> Base.encode64(id <> ":" <> secret)

  defp headers_to_map(headers),
    do:
      Map.new(headers, fn {key, value} -> {String.downcase(to_string(key)), to_string(value)} end)
end
