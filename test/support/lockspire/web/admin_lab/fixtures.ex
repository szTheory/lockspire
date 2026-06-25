defmodule Lockspire.Web.AdminLab.Fixtures do
  @moduledoc false

  @scenario_states [
    :normal,
    :empty,
    :error,
    :disabled,
    :destructive,
    :long_value,
    :dense_data,
    :light,
    :dark,
    :system,
    :reduced_motion,
    :healthy,
    :warning,
    :incident,
    :self_registered,
    :expired,
    :revoked,
    :reuse_detected,
    :copy_once
  ]

  @fixture_keys [
    :clients,
    :tokens,
    :consents,
    :keys,
    :dcr_iat,
    :operations,
    :theme_modes,
    :motion_modes
  ]

  @forbidden_substrings [
    "real-client-secret",
    "production-secret",
    "prod-access-token",
    "prod-refresh-token",
    "customer.example.com",
    "tenant.example.com",
    "sk_live_",
    "pk_live_",
    "eyJhbGci",
    "BEGIN PRIVATE KEY"
  ]

  def all do
    %{
      clients: [
        %{
          state: :healthy,
          id: "client_acme_ledger_public",
          name: "Acme Ledger Partner With A Very Long Client Name That Wraps Safely",
          redirect_uri:
            "https://tenant-with-a-long-name.example.invalid/oauth/callbacks/production/eu-west-1/finance-ledger/reconciliation",
          secret_handle: "redacted_handle_client_secret_hash_v1"
        },
        %{
          state: :disabled,
          id: "client_legacy_disabled_reporter",
          name: "Legacy disabled reporter",
          redirect_uri: "https://disabled-reporter.example.invalid/oauth/callback",
          secret_handle: "Redacted"
        },
        %{
          state: :self_registered,
          id: "client_self_registered_portal",
          name: "Self-registered DCR portal",
          redirect_uri: "https://self-registered.example.invalid/oauth/callback",
          secret_handle: "redacted_handle_dcr_secret_hash"
        }
      ],
      tokens: [
        %{
          state: :healthy,
          account: "acct_healthy_operator",
          family: "tok_family_healthy",
          handle: "redacted_handle_refresh_active"
        },
        %{
          state: :expired,
          account: "acct_expired_operator",
          family: "tok_family_expired",
          handle: "redacted_handle_refresh_expired"
        },
        %{
          state: :revoked,
          account: "acct_revoked_operator",
          family: "tok_family_revoked",
          handle: "redacted_handle_refresh_revoked"
        },
        %{
          state: :reuse_detected,
          account: "acct_incident_operator",
          family: "tok_family_reuse_detected",
          handle: "redacted_handle_reuse_incident"
        }
      ],
      consents: [
        %{state: :healthy, subject: "acct_consent_current", scopes: ["openid", "profile"]},
        %{state: :warning, subject: "acct_consent_warning", scopes: ["openid", "offline_access"]},
        %{state: :empty, subject: "acct_consent_empty", scopes: []}
      ],
      keys: [
        %{state: :healthy, kid: "key_current_es256", algorithm: "ES256"},
        %{state: :warning, kid: "key_rotating_ps256", algorithm: "PS256"},
        %{state: :incident, kid: "key_incident_disabled", algorithm: "ES256"}
      ],
      dcr_iat: [
        %{
          state: :copy_once,
          label: "Initial access token",
          value: "redacted_handle_copy_once_iat_placeholder"
        },
        %{
          state: :revoked,
          label: "Registration access token",
          value: "redacted_handle_rat_revoked"
        }
      ],
      operations: [
        %{state: :normal, label: "Logout delivery", count: 42},
        %{state: :dense_data, label: "Device authorization attempts", count: 1248},
        %{state: :error, label: "Back-channel retry queue", count: 9},
        %{state: :destructive, label: "Token family revocation", count: 1}
      ],
      theme_modes: [:light, :dark, :system],
      motion_modes: [:default, :reduced_motion]
    }
  end

  def scenario_states, do: @scenario_states
  def fixture_keys, do: @fixture_keys
  def forbidden_substrings, do: @forbidden_substrings
end
