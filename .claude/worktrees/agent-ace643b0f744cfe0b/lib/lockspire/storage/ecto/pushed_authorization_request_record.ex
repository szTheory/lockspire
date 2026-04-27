defmodule Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.PushedAuthorizationRequest

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_pushed_authorization_requests" do
    field(:request_uri_hash, :string)
    field(:client_id, :string)
    field(:redirect_uri, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:prompt, {:array, :string}, default: [])
    field(:nonce, :string)
    field(:state, :string)
    field(:code_challenge, :string)
    field(:code_challenge_method, Ecto.Enum, values: [:S256])
    field(:expires_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(record, %PushedAuthorizationRequest{} = request) do
    attrs =
      request
      |> Map.from_struct()
      |> Map.put(:prompt, normalize_prompt(request.prompt))

    record
    |> cast(attrs, [
      :request_uri_hash,
      :client_id,
      :redirect_uri,
      :scopes,
      :prompt,
      :nonce,
      :state,
      :code_challenge,
      :code_challenge_method,
      :expires_at
    ])
    |> validate_required([
      :request_uri_hash,
      :client_id,
      :redirect_uri,
      :code_challenge,
      :code_challenge_method,
      :expires_at
    ])
    |> unique_constraint(:request_uri_hash)
  end

  def to_domain(%__MODULE__{} = record, opts \\ []) do
    %PushedAuthorizationRequest{
      id: record.id,
      request_uri: Keyword.get(opts, :request_uri),
      request_uri_hash: record.request_uri_hash,
      client_id: record.client_id,
      redirect_uri: record.redirect_uri,
      scopes: record.scopes,
      prompt: record.prompt,
      nonce: record.nonce,
      state: record.state,
      code_challenge: record.code_challenge,
      code_challenge_method: record.code_challenge_method,
      expires_at: record.expires_at,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end

  defp normalize_prompt(nil), do: []
  defp normalize_prompt(prompt) when is_binary(prompt), do: [prompt]
  defp normalize_prompt(prompt) when is_list(prompt), do: prompt
end
