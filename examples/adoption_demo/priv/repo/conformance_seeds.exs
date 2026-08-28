alias Lockspire.Domain.Client
alias Lockspire.Domain.ServerPolicy
alias Lockspire.Storage.Ecto.Repository

profile = System.fetch_env!("LOCKSPIRE_OIDF_PROFILE")
config_path = System.fetch_env!("LOCKSPIRE_OIDF_CONFIG_PATH")
base_url = Application.fetch_env!(:adoption_demo, :demo_base_url)
discovery_url = base_url <> "/lockspire/.well-known/openid-configuration"
callback_url = "https://nginx:8443/test/a/lockspire-fapi2/callback"
now = DateTime.utc_now()

unless profile in ["phase37", "fapi2"] do
  raise ArgumentError, "unsupported ephemeral conformance profile"
end

unless Path.type(config_path) == :absolute do
  raise ArgumentError, "LOCKSPIRE_OIDF_CONFIG_PATH must be absolute"
end

browser = [
  %{
    "match" => base_url <> "/lockspire/authorize*",
    "tasks" => [
      %{
        "task" => "Login",
        "optional" => true,
        "match" => base_url <> "/login*",
        "commands" => [["click", "css", "button.primary"]]
      },
      %{
        "task" => "Consent",
        "optional" => true,
        "match" => base_url <> "/lockspire/consent/*",
        "commands" => [["click", "css", "button.primary"]]
      },
      %{
        "task" => "Verify Complete",
        "match" => "*/test/*/callback*",
        "commands" => [["wait", "id", "submission_complete", 10]]
      }
    ]
  }
]

unsafe_redirect_browser = [
  %{
    "match" => base_url <> "/lockspire/authorize*",
    "tasks" => [
      %{
        "task" => "Expect the host-safe authorization error",
        "match" => base_url <> "/lockspire/authorize*",
        "commands" => [
          [
            "wait",
            "xpath",
            "//*",
            10,
            "Authorization request rejected",
            "update-image-placeholder"
          ]
        ]
      }
    ]
  }
]

register_fapi_client = fn client_id ->
  private_key = JOSE.JWK.generate_key({:rsa, 2048})
  {_private_fields, private_jwk} = JOSE.JWK.to_map(private_key)

  public_jwk =
    private_jwk
    |> Map.take(["kty", "n", "e"])
    |> Map.merge(%{"kid" => client_id, "alg" => "PS256", "use" => "sig"})

  {:ok, client} =
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: nil,
      client_type: :confidential,
      name: "Ephemeral OIDF FAPI Client",
      redirect_uris: [callback_url],
      allowed_scopes: ["openid", "email", "profile", "read:billing"],
      allowed_grant_types: ["authorization_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :private_key_jwt,
      token_endpoint_auth_signing_alg: :PS256,
      pkce_required: true,
      par_policy: :required,
      dpop_policy: :dpop,
      security_profile: :fapi_2_0_security,
      subject_type: :public,
      jwks: %{"keys" => [public_jwk]},
      created_by: "ephemeral-conformance",
      created_at: now,
      metadata: %{"ephemeral" => true}
    })

  private_jwk =
    Map.merge(private_jwk, %{
      "alg" => "PS256",
      "kid" => client_id,
      "use" => "sig"
    })

  %{client_id: client.client_id, private_jwk: private_jwk}
end

provider_client = fn %{client_id: client_id, private_jwk: private_jwk} ->
  %{
    "client_id" => client_id,
    "scope" => "openid email profile read:billing",
    "jwks" => %{"keys" => [private_jwk]},
    "dpop_signing_alg" => "ES256"
  }
end

config =
  case profile do
    "phase37" ->
      {:ok, _policy} =
        Repository.put_server_policy(%ServerPolicy{
          par_policy: :optional,
          dpop_policy: :bearer,
          security_profile: :none,
          registration_policy: :open,
          dcr_allowed_scopes: ["openid", "email", "profile"],
          dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
          dcr_allowed_response_types: ["code"],
          dcr_allowed_redirect_uri_schemes: ["https"],
          dcr_allowed_redirect_uri_hosts: ["nginx"],
          dcr_allowed_token_endpoint_auth_methods: ["none"]
        })

      %{
        "description" => "Throwaway Lockspire OIDC provider",
        "server" => %{"discoveryUrl" => discovery_url},
        "client" => %{"client_name" => "lockspire-oidf-phase37"},
        "client2" => %{"client_name" => "lockspire-oidf-phase37-second"},
        "browser" => browser,
        "override" => %{
          "oidcc-ensure-registered-redirect-uri" => %{"browser" => unsafe_redirect_browser},
          "oidcc-redirect-uri-query-mismatch" => %{"browser" => unsafe_redirect_browser}
        }
      }

    "fapi2" ->
      {:ok, _policy} =
        Repository.put_server_policy(%ServerPolicy{
          par_policy: :required,
          dpop_policy: :dpop,
          security_profile: :fapi_2_0_security,
          registration_policy: :disabled
        })

      client = register_fapi_client.("lockspire-fapi2-client")
      client2 = register_fapi_client.("lockspire-fapi2-client-2")

      %{
        "alias" => "lockspire-fapi2",
        "description" => "Throwaway Lockspire FAPI 2.0 provider",
        "server" => %{"discoveryUrl" => discovery_url},
        "client" => provider_client.(client),
        "client2" => provider_client.(client2),
        "resource" => %{
          "resourceUrl" => base_url <> "/api/billing/summary",
          "resourceMethod" => "GET",
          "resourceMediaType" => "application/json"
        },
        "browser" => browser
      }
  end

File.write!(config_path, Jason.encode!(config))
File.chmod!(config_path, 0o600)
