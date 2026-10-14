defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr.PolicyForm do
  @moduledoc """
  Embedded schema and changeset for validating DCR policy form submissions.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @lifetime_fields [
    :dcr_default_client_lifetime_seconds,
    :dcr_default_client_secret_lifetime_seconds,
    :dcr_default_registration_access_token_lifetime_seconds
  ]
  # These values are persisted in PostgreSQL integer columns.
  @maximum_lifetime_seconds 2_147_483_647

  def maximum_lifetime_seconds, do: @maximum_lifetime_seconds

  @primary_key false
  embedded_schema do
    field(:registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open])
    field(:dcr_allowed_scopes, {:array, :string}, default: [])
    field(:dcr_allowed_grant_types, {:array, :string}, default: [])
    field(:dcr_allowed_response_types, {:array, :string}, default: [])
    field(:dcr_allowed_redirect_uri_schemes, {:array, :string}, default: [])
    field(:dcr_allowed_redirect_uri_hosts, {:array, :string}, default: [])
    field(:dcr_allowed_token_endpoint_auth_methods, {:array, :string}, default: [])
    field(:dcr_default_client_lifetime_seconds, :integer)
    field(:dcr_default_client_secret_lifetime_seconds, :integer)
    field(:dcr_default_registration_access_token_lifetime_seconds, :integer)
  end

  @doc """
  Casts and validates form parameters into the embedded schema.
  """
  def changeset(policy \\ %__MODULE__{}, attrs) do
    attrs = prepare_array_fields(attrs)

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
    |> validate_lifetimes()
  end

  defp validate_lifetimes(changeset) do
    Enum.reduce(@lifetime_fields, changeset, fn field, acc ->
      acc
      |> validate_number(field,
        greater_than_or_equal_to: 0,
        message: "must be zero or greater"
      )
      |> validate_number(field,
        less_than_or_equal_to: @maximum_lifetime_seconds,
        message: "must be 2,147,483,647 seconds or less"
      )
    end)
  end

  defp prepare_array_fields(attrs) do
    array_fields = [
      "dcr_allowed_scopes",
      "dcr_allowed_grant_types",
      "dcr_allowed_response_types",
      "dcr_allowed_redirect_uri_schemes",
      "dcr_allowed_redirect_uri_hosts",
      "dcr_allowed_token_endpoint_auth_methods",
      :dcr_allowed_scopes,
      :dcr_allowed_grant_types,
      :dcr_allowed_response_types,
      :dcr_allowed_redirect_uri_schemes,
      :dcr_allowed_redirect_uri_hosts,
      :dcr_allowed_token_endpoint_auth_methods
    ]

    Enum.reduce(array_fields, attrs, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, [val]} when is_binary(val) ->
          # Split comma-separated string from a single HTML input with name="[]"
          list = val |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
          Map.put(acc, field, list)

        {:ok, val} when is_binary(val) ->
          # Split comma-separated string from a single HTML input without name="[]"
          list = val |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
          Map.put(acc, field, list)

        _ ->
          acc
      end
    end)
  end
end
