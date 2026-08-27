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
    :copy_once,
    :one_item,
    :many_items,
    :high_count,
    :zero_count,
    :missing_optional,
    :stale_read_only,
    :focus,
    :mobile_width,
    :orient,
    :configure,
    :support,
    :operate,
    :internal_lab,
    :waiting,
    :completed,
    :provenance
  ]

  @fixture_keys [
    :clients,
    :tokens,
    :consents,
    :keys,
    :dcr_iat,
    :operations,
    :structural_rows,
    :status_matrix,
    :proof_matrix,
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
      structural_rows: [
        %{
          state: :pending,
          title: "Dense queue row with generated identifier",
          subtitle: "device_queue_01",
          identifier:
            "device_authorization_work_item_01JZ2Z6GZ8T3D8QPMTZZZZZZZZ_extremely_long_safe_identifier",
          actor: "redacted_actor_support_01",
          consequence: "Operator can inspect retry posture without token plaintext."
        },
        %{
          state: :reuse_detected,
          title: "Token family incident",
          subtitle: "family_reuse_detected",
          identifier: "redacted_handle_refresh_family_reuse_detected_01JZ2Z6GZ8T3D8QPMT",
          actor: "redacted_actor_security_02",
          consequence: "Reuse detection requires family-wide revocation proof."
        }
      ],
      status_matrix: [
        %{domain: :configure, status: :active},
        %{domain: :configure, status: :open},
        %{domain: :configure, status: :approved},
        %{domain: :device_authorization, status: :approved},
        %{domain: :support, status: :pending},
        %{domain: :support, status: :pending_login},
        %{domain: :support, status: :pending_consent},
        %{domain: :operate, status: :enqueued},
        %{domain: :operate, status: :attempted},
        %{domain: :operate, status: :retiring},
        %{domain: :operate, status: :retryable},
        %{domain: :support, status: :denied},
        %{domain: :support, status: :reuse_detected},
        %{domain: :operate, status: :discarded},
        %{domain: :configure, status: :disabled},
        %{domain: :configure, status: :retired},
        %{domain: :support, status: :completed},
        %{domain: :support, status: :consumed},
        %{domain: :support, status: :used},
        %{domain: :operate, status: :succeeded},
        %{domain: :operate, status: :rendered},
        %{domain: :operate, status: :skipped},
        %{domain: :configure, status: :operator},
        %{domain: :configure, status: :self_registered},
        %{domain: :configure, status: :self_registered_client},
        %{domain: :operate, status: :system},
        %{domain: :configure, status: :host_app},
        %{domain: :configure, status: :dcr},
        %{domain: :configure, status: :one_time},
        %{domain: :configure, status: :remembered},
        %{domain: :configure, status: :initial_access_token},
        %{domain: :configure, status: :upcoming},
        %{domain: :support, status: :revoked},
        %{domain: :support, status: :expired},
        %{domain: :support, status: :unknown_lab_only}
      ],
      proof_matrix: [
        %{
          class: :cardinality_layout,
          state: :empty,
          label: "Empty support result",
          count: 0,
          journey: :support,
          display_value: "No matching support records"
        },
        %{
          class: :cardinality_layout,
          state: :one_item,
          label: "One client pending review",
          count: 1,
          journey: :configure
        },
        %{
          class: :cardinality_layout,
          state: :many_items,
          label: "Many device authorization records",
          count: 24,
          journey: :operate
        },
        %{
          class: :cardinality_layout,
          state: :dense_data,
          label: "Dense queue count",
          count: 1248,
          journey: :operate
        },
        %{
          class: :cardinality_layout,
          state: :high_count,
          label: "High count support queue",
          count: 4096,
          journey: :support
        },
        %{
          class: :cardinality_layout,
          state: :zero_count,
          label: "Zero expired keys",
          count: 0,
          journey: :configure,
          display_value: "0"
        },
        %{
          class: :string_pressure,
          state: :long_value,
          label: "Long safe values",
          long_name:
            "Partner Configuration With Long Legal Entity Name For Responsive Wrapping Proof",
          long_id: "redacted_handle_admin_lab_long_identifier_01JZ2Z6GZ8T3D8QPMTZZZZZZZZ",
          long_url:
            "https://admin-lab-long-fixture.example.invalid/oauth/callbacks/configure/support/operate/internal-lab-proof"
        },
        %{
          class: :optionality,
          state: :missing_optional,
          label: "Missing optional support note",
          optional_value: nil,
          display_value: "Not recorded",
          journey: :support
        },
        %{
          class: :lifecycle_security,
          state: :warning,
          label: "Warning posture",
          consequence: "Operator should inspect policy posture before changing configuration."
        },
        %{
          class: :lifecycle_security,
          state: :incident,
          label: "Incident pressure",
          consequence: "Security review should stay focused on redacted handles."
        },
        %{
          class: :lifecycle_security,
          state: :disabled,
          label: "Disabled client",
          consequence: "Disabled clients stay visible for support correlation."
        },
        %{
          class: :lifecycle_security,
          state: :expired,
          label: "Expired authorization",
          consequence: "Expired records are read-only support truth."
        },
        %{
          class: :lifecycle_security,
          state: :revoked,
          label: "Revoked consent",
          consequence: "Already revoked records must not imply another mutation."
        },
        %{
          class: :lifecycle_security,
          state: :reuse_detected,
          label: "Reuse-detected family",
          consequence: "Family-wide revocation proof uses redacted family handles."
        },
        %{
          class: :lifecycle_security,
          state: :copy_once,
          label: "Copy-once credential handoff",
          value: "redacted_handle_copy_once_admin_lab"
        },
        %{
          class: :lifecycle_security,
          state: :stale_read_only,
          label: "Stale read-only evidence",
          consequence: "Evidence can be reviewed but not used as a command surface."
        },
        %{
          class: :visual_accessibility,
          state: :light,
          label: "Light theme",
          theme: :light
        },
        %{
          class: :visual_accessibility,
          state: :dark,
          label: "Dark theme",
          theme: :dark
        },
        %{
          class: :visual_accessibility,
          state: :system,
          label: "System theme",
          theme: :system
        },
        %{
          class: :visual_accessibility,
          state: :reduced_motion,
          label: "Reduced motion",
          motion: :reduced_motion
        },
        %{
          class: :visual_accessibility,
          state: :focus,
          label: "Keyboard focus",
          focus_path: "nav -> filter input -> primary safe action"
        },
        %{
          class: :visual_accessibility,
          state: :mobile_width,
          label: "Mobile width",
          viewport_width: 320
        },
        %{
          class: :journey_boundary,
          state: :orient,
          label: "Orient journey",
          route: "/admin"
        },
        %{
          class: :journey_boundary,
          state: :configure,
          label: "Configure journey",
          route: "/admin/clients"
        },
        %{
          class: :journey_boundary,
          state: :support,
          label: "Support journey",
          route: "/admin/tokens"
        },
        %{
          class: :journey_boundary,
          state: :operate,
          label: "Operate journey",
          route: "/admin/logouts"
        },
        %{
          class: :journey_boundary,
          state: :internal_lab,
          label: "Internal lab boundary",
          route: "Lockspire.Web.AdminLab.StressSurface",
          support_surface: "test/support only"
        }
      ],
      theme_modes: [:light, :dark, :system],
      motion_modes: [:default, :reduced_motion]
    }
  end

  def scenario_states, do: @scenario_states
  def fixture_keys, do: @fixture_keys
  def forbidden_substrings, do: @forbidden_substrings
end
