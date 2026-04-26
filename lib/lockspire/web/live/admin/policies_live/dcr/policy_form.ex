defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm do
  @moduledoc """
  Embedded schema and changeset for validating DCR policy form submissions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open]
    field :dcr_allowed_scopes, {:array, :string}, default: []
    field :dcr_allowed_grant_types, {:array, :string}, default: []
    field :dcr_allowed_response_types, {:array, :string}, default: []
    field :dcr_allowed_redirect_uri_schemes, {:array, :string}, default: []
    field :dcr_allowed_redirect_uri_hosts, {:array, :string}, default: []
    field :dcr_allowed_token_endpoint_auth_methods, {:array, :string}, default: []
    field :dcr_default_client_lifetime_seconds, :integer
    field :dcr_default_client_secret_lifetime_seconds, :integer
    field :dcr_default_registration_access_token_lifetime_seconds, :integer
  end

  @doc """
  Casts and validates form parameters into the embedded schema.
  """
  def changeset(policy \\ %__MODULE__{}, attrs) do
    policy
    |> cast(attrs, [
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
    |> validate_required([:registration_policy])
    |> validate_number(:dcr_default_client_lifetime_seconds, greater_than_or_equal_to: 0)
    |> validate_number(:dcr_default_client_secret_lifetime_seconds, greater_than_or_equal_to: 0)
    |> validate_number(:dcr_default_registration_access_token_lifetime_seconds, greater_than_or_equal_to: 0)
  end
end
