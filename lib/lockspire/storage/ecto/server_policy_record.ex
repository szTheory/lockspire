defmodule Lockspire.Storage.Ecto.ServerPolicyRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.ServerPolicy

  @singleton_id 1
  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_server_policies" do
    field(:par_policy, Ecto.Enum, values: [:optional, :required], default: :optional)

    # D-05: tri-state Ecto.Enum cast against the text column from Plan 02 migration.
    # Pitfall 4: every text-enum column MUST have a matching Ecto.Enum field, or code
    # pattern-matching on :disabled silently fails because the value is "disabled".
    field(:registration_policy, Ecto.Enum,
      values: [:disabled, :initial_access_token, :open],
      default: :disabled
    )

    # D-06: 6 array allowlists. Ecto array of :string maps to {:array, :text} on disk.
    field(:dcr_allowed_scopes, {:array, :string}, default: [])
    field(:dcr_allowed_grant_types, {:array, :string}, default: [])
    field(:dcr_allowed_response_types, {:array, :string}, default: [])
    field(:dcr_allowed_redirect_uri_schemes, {:array, :string}, default: [])
    field(:dcr_allowed_redirect_uri_hosts, {:array, :string}, default: [])
    field(:dcr_allowed_token_endpoint_auth_methods, {:array, :string}, default: [])

    # D-06: 3 nullable lifetime integers (Phase 26 falls back to global defaults when nil).
    field(:dcr_default_client_lifetime_seconds, :integer)
    field(:dcr_default_client_secret_lifetime_seconds, :integer)
    field(:dcr_default_registration_access_token_lifetime_seconds, :integer)

    timestamps()
  end

  def singleton_id, do: @singleton_id

  def changeset(record, %ServerPolicy{} = policy) do
    record
    |> cast(Map.from_struct(policy), [
      :id,
      :par_policy,
      :registration_policy,
      :dcr_allowed_scopes,
      :dcr_allowed_grant_types,
      :dcr_allowed_response_types,
      :dcr_allowed_redirect_uri_schemes,
      :dcr_allowed_redirect_uri_hosts,
      :dcr_allowed_token_endpoint_auth_methods,
      :dcr_default_client_lifetime_seconds,
      :dcr_default_client_secret_lifetime_seconds,
      :dcr_default_registration_access_token_lifetime_seconds
    ])
    |> validate_required([:id, :par_policy, :registration_policy])
  end

  def to_domain(%__MODULE__{} = record) do
    %ServerPolicy{
      id: record.id,
      par_policy: record.par_policy,
      registration_policy: record.registration_policy,
      dcr_allowed_scopes: record.dcr_allowed_scopes,
      dcr_allowed_grant_types: record.dcr_allowed_grant_types,
      dcr_allowed_response_types: record.dcr_allowed_response_types,
      dcr_allowed_redirect_uri_schemes: record.dcr_allowed_redirect_uri_schemes,
      dcr_allowed_redirect_uri_hosts: record.dcr_allowed_redirect_uri_hosts,
      dcr_allowed_token_endpoint_auth_methods: record.dcr_allowed_token_endpoint_auth_methods,
      dcr_default_client_lifetime_seconds: record.dcr_default_client_lifetime_seconds,
      dcr_default_client_secret_lifetime_seconds:
        record.dcr_default_client_secret_lifetime_seconds,
      dcr_default_registration_access_token_lifetime_seconds:
        record.dcr_default_registration_access_token_lifetime_seconds,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
