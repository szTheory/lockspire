defmodule Lockspire.Storage.Ecto.InteractionRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.Interaction

  @timestamps_opts [type: :utc_datetime_usec]
  @active_statuses [:pending_login, :pending_consent]
  @statuses @active_statuses ++ [:completed, :denied, :expired]

  schema "lockspire_interactions" do
    field(:interaction_id, :string)
    field(:sid, :string)
    field(:client_id, :string)
    field(:account_id, :string)
    field(:scopes_requested, {:array, :string}, default: [])
    field(:prompt, {:array, :string}, default: [])
    field(:nonce, :string)
    field(:auth_time, :utc_datetime_usec)
    field(:max_age, :integer)
    field(:auth_time_requested, :boolean, default: false)
    field(:redirect_uri, :string)
    field(:return_to, :string)
    field(:state, :string)
    field(:code_challenge, :string)
    field(:code_challenge_method, Ecto.Enum, values: [:S256])
    field(:status, Ecto.Enum, values: @statuses)
    field(:login_required_at, :utc_datetime_usec)
    field(:consent_requested_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:denied_at, :utc_datetime_usec)
    field(:expired_at, :utc_datetime_usec)
    field(:denial_reason, :string)
    field(:expires_at, :utc_datetime_usec)
    field(:tenant_id, :string)

    timestamps()
  end

  def changeset(record, %Interaction{} = interaction) do
    prompt = normalize_prompt(interaction.prompt)

    attrs =
      interaction
      |> Map.from_struct()
      |> Map.put(:prompt, prompt)

    record
    |> cast(attrs, [
      :interaction_id,
      :sid,
      :client_id,
      :account_id,
      :scopes_requested,
      :prompt,
      :nonce,
      :auth_time,
      :max_age,
      :auth_time_requested,
      :redirect_uri,
      :return_to,
      :state,
      :code_challenge,
      :code_challenge_method,
      :status,
      :login_required_at,
      :consent_requested_at,
      :completed_at,
      :denied_at,
      :expired_at,
      :denial_reason,
      :expires_at,
      :tenant_id
    ])
    |> validate_required([:interaction_id, :client_id, :return_to, :expires_at, :status])
    |> unique_constraint(:interaction_id)
  end

  def update_changeset(record, attrs) when is_map(attrs) do
    record
    |> cast(attrs, [
      :account_id,
      :status,
      :auth_time,
      :login_required_at,
      :consent_requested_at,
      :completed_at,
      :denied_at,
      :expired_at,
      :denial_reason,
      :updated_at
    ])
    |> validate_required([:status])
  end

  def to_domain(%__MODULE__{} = record) do
    %Interaction{
      id: record.id,
      interaction_id: record.interaction_id,
      sid: record.sid,
      client_id: record.client_id,
      account_id: record.account_id,
      scopes_requested: record.scopes_requested,
      prompt: record.prompt,
      nonce: record.nonce,
      auth_time: record.auth_time,
      max_age: record.max_age,
      auth_time_requested: record.auth_time_requested,
      redirect_uri: record.redirect_uri,
      return_to: record.return_to,
      state: record.state,
      code_challenge: record.code_challenge,
      code_challenge_method: record.code_challenge_method,
      status: record.status,
      login_required_at: record.login_required_at,
      consent_requested_at: record.consent_requested_at,
      completed_at: record.completed_at,
      denied_at: record.denied_at,
      expired_at: record.expired_at,
      denial_reason: record.denial_reason,
      expires_at: record.expires_at,
      tenant_id: record.tenant_id,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end

  def active_statuses, do: @active_statuses

  defp normalize_prompt(nil), do: []
  defp normalize_prompt(prompt) when is_binary(prompt), do: [prompt]
  defp normalize_prompt(prompt) when is_list(prompt), do: prompt
end
