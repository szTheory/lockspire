args = case System.argv() do ["--" | rest] -> rest; values -> values end

case args do
  [suffix] ->
    base = %{
      client_type: "confidential",
      name: "Installed verifier endpoint client",
      redirect_uris: ["https://client.example/callback"],
      allowed_scopes: ["openid", "profile"],
      allowed_grant_types: [
        "authorization_code",
        "urn:ietf:params:oauth:grant-type:device_code"
      ],
      allowed_response_types: ["code"]
    }

    register = fn method, client_id, extra ->
      attrs =
        base
        |> Map.merge(%{client_id: client_id, token_endpoint_auth_method: method})
        |> Map.merge(extra)

      case Lockspire.Clients.register_client(attrs) do
        {:ok, %{client: client, client_secret: secret}} ->
          IO.puts("CLIENT=" <> suffix <> ":" <> client.client_id <> ":" <> secret)

        {:error, errors} ->
          Mix.raise("client registration rejected: " <> Enum.map_join(errors, ",", &Atom.to_string(&1.reason)))
      end
    end

    register.("client_secret_jwt", "verifier-endpoint-jwt-" <> suffix, %{
      token_endpoint_auth_signing_alg: "HS256",
      backchannel_token_delivery_mode: :poll,
      backchannel_user_code_parameter: false
    })

    register.("client_secret_basic", "verifier-endpoint-basic-" <> suffix, %{})
    register.("client_secret_post", "verifier-endpoint-post-" <> suffix, %{})

  _ ->
    Mix.raise("expected one isolated client suffix")
end
