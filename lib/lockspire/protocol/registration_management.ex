defmodule Lockspire.Protocol.RegistrationManagement do
  @moduledoc """
  RFC 7592 dynamic client registration management — `Plug.Conn`-free orchestrator.

  Public entries:
    - `read/2`       — return current RFC 7591 metadata for the RAT-bound client.
    - `update/2`     — full-replace via the same validator pipeline as `Registration.register/1`;
                       on success rotates the RAT and returns the new plaintext exactly once.
    - `delete/2`     — soft-disable through the neutral client lifecycle.

  All three functions accept `(client_id_from_url, %Domain.Client{} ...)` where `client` is the
  row matched by `Repository.get_client_by_registration_access_token_hash/1`. URL/RAT mismatches
  ALWAYS collapse to `{:error, :invalid_token}` — the discriminator stays in telemetry only,
  defending against client-ID enumeration.
  """

  alias Lockspire.ClientLifecycle
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Observability
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Storage.Ecto.Repository

  defmodule UpdateSuccess do
    @moduledoc false
    @type t :: %__MODULE__{
            client: Client.t(),
            registration_access_token_plaintext: String.t()
          }
    defstruct [:client, :registration_access_token_plaintext]
  end

  @type update_request :: %{
          required(:metadata) => map(),
          required(:server_policy) => ServerPolicy.t(),
          required(:client) => Client.t()
        }

  @spec read(String.t(), Client.t()) :: {:ok, Client.t()} | {:error, :invalid_token}
  def read(client_id_from_url, %Client{} = client) when is_binary(client_id_from_url) do
    if client_id_from_url == client.client_id and client.active do
      Observability.emit(:dcr, :read, %{count: 1}, %{
        status: :success,
        actor_type: :self_registered_client,
        actor_id: client.client_id,
        client_id: client.client_id
      })

      {:ok, client}
    else
      emit_unauthorized(client_id_from_url, client)
      {:error, :invalid_token}
    end
  end

  @spec update(String.t(), update_request()) ::
          {:ok, struct()} | {:error, struct()} | {:error, :invalid_token}
  def update(
        client_id_from_url,
        %{
          metadata: metadata,
          server_policy: %ServerPolicy{} = server_policy,
          client: %Client{} = client
        } = _request
      )
      when is_binary(client_id_from_url) and is_map(metadata) do
    if client_id_from_url != client.client_id or not client.active do
      emit_unauthorized(client_id_from_url, client)
      {:error, :invalid_token}
    else
      with {:ok, resolved} <- DcrPolicy.resolve(server_policy, nil, metadata),
           :ok <- Registration.validate_intake_metadata(metadata, resolved, server_policy, client),
           {new_rat_plaintext, new_rat_hash} <- RegistrationAccessToken.generate(),
           {:ok, updated_client} <- persist_update(client, metadata, new_rat_hash) do
        emit_updated(updated_client)
        emit_rat_rotated(updated_client)

        {:ok,
         %UpdateSuccess{
           client: updated_client,
           registration_access_token_plaintext: new_rat_plaintext
         }}
      else
        {:error, :invalid_client_metadata, info} ->
          error = %Registration.Error{
            code: :invalid_client_metadata,
            field: info.field,
            reason: info.reason,
            allowed: info[:allowed]
          }

          emit_update_rejected(client, error)
          {:error, error}

        {:error, %Registration.Error{} = error} ->
          emit_update_rejected(client, error)
          {:error, error}

        {:error, reason} ->
          error = %Registration.Error{code: :persistence_error, reason: reason}
          emit_update_rejected(client, error)
          {:error, error}
      end
    end
  end

  @spec delete(String.t(), Client.t()) :: :ok | {:error, :invalid_token | term()}
  def delete(client_id_from_url, %Client{} = client) when is_binary(client_id_from_url) do
    if client_id_from_url != client.client_id or not client.active do
      emit_unauthorized(client_id_from_url, client)
      {:error, :invalid_token}
    else
      case ClientLifecycle.disable_dcr(client) do
        {:ok, %Client{}} ->
          Observability.emit(:dcr, :delete, %{count: 1}, %{
            status: :success,
            actor_type: :self_registered_client,
            actor_id: client.client_id,
            client_id: client.client_id
          })

          :ok

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec rotate_registration_access_token(Client.t()) ::
          {:ok, String.t(), Client.t()} | {:error, term()}
  def rotate_registration_access_token(%Client{} = client) do
    {new_rat_plaintext, new_rat_hash} = RegistrationAccessToken.generate()

    result =
      Repository.rotate_registration_access_token(client, new_rat_hash, %{
        action: :dcr_management_rat_rotated,
        outcome: :success,
        actor: %{type: :operator, id: "admin-ui"},
        resource: %{type: :client, id: client.client_id},
        metadata: %{}
      })

    case result do
      {:ok, updated_client} ->
        emit_rat_rotated(updated_client)
        {:ok, new_rat_plaintext, updated_client}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private Helpers

  defp persist_update(%Client{} = client, metadata, new_rat_hash) do
    ClientLifecycle.replace_dcr(client, metadata, new_rat_hash)
  end

  defp emit_updated(%Client{} = client) do
    Observability.emit(:dcr, :update, %{count: 1}, %{
      status: :success,
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id
    })
  end

  defp emit_rat_rotated(%Client{} = client) do
    Observability.emit(:dcr, :rotate, %{count: 1}, %{
      status: :success,
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id
    })
  end

  defp emit_update_rejected(%Client{} = client, %Registration.Error{} = error) do
    Observability.emit(:dcr, :update, %{count: 1, rejected: 1}, %{
      status: :failure,
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id,
      code: error.code,
      field: error.field,
      reason: error.reason
    })
  end

  defp emit_unauthorized(client_id_from_url, %Client{} = client) do
    Observability.emit(:dcr, :unauthorized, %{count: 1}, %{
      status: :failure,
      reason_code: :unauthorized,
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id_from_url: client_id_from_url,
      client_id: client.client_id
    })
  end
end
