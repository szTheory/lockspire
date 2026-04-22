defmodule Lockspire.Storage.Ecto.InteractionRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.Interaction

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_interactions" do
    field :interaction_id, :string
    field :client_id, :string
    field :account_id, :string
    field :scopes_requested, {:array, :string}, default: []
    field :prompt, {:array, :string}, default: []
    field :nonce, :string
    field :redirect_uri, :string
    field :return_to, :string
    field :state, :string
    field :code_challenge, :string
    field :code_challenge_method, Ecto.Enum, values: [:S256]
    field :expires_at, :utc_datetime_usec
    field :tenant_id, :string

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
      :client_id,
      :account_id,
      :scopes_requested,
      :prompt,
      :nonce,
      :redirect_uri,
      :return_to,
      :state,
      :code_challenge,
      :code_challenge_method,
      :expires_at,
      :tenant_id
    ])
    |> validate_required([:interaction_id, :client_id, :return_to, :expires_at])
    |> unique_constraint(:interaction_id)
  end

  def to_domain(%__MODULE__{} = record) do
    %Interaction{
      id: record.id,
      interaction_id: record.interaction_id,
      client_id: record.client_id,
      account_id: record.account_id,
      scopes_requested: record.scopes_requested,
      prompt: record.prompt,
      nonce: record.nonce,
      redirect_uri: record.redirect_uri,
      return_to: record.return_to,
      state: record.state,
      code_challenge: record.code_challenge,
      code_challenge_method: record.code_challenge_method,
      expires_at: record.expires_at,
      tenant_id: record.tenant_id,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end

  defp normalize_prompt(nil), do: []
  defp normalize_prompt(prompt) when is_binary(prompt), do: [prompt]
  defp normalize_prompt(prompt) when is_list(prompt), do: prompt
end
