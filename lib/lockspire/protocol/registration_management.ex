defmodule Lockspire.Protocol.RegistrationManagement do
  @moduledoc """
  RFC 7592 dynamic client registration management — `Plug.Conn`-free orchestrator.

  Public entries:
    - `read/2`       — return current RFC 7591 metadata for the RAT-bound client.
    - `update/2`     — full-replace via the same validator pipeline as `Registration.register/1`;
                       on success rotates the RAT and returns the new plaintext exactly once.
    - `delete/2`     — soft-disable via the public `Lockspire.Admin.Clients.disable_client/2`.

  All three functions accept `(client_id_from_url, %Domain.Client{} ...)` where `client` is the
  row matched by `Repository.get_client_by_registration_access_token_hash/1`. URL/RAT mismatches
  ALWAYS collapse to `{:error, :invalid_token}` — the discriminator stays in telemetry only,
  defending against client-id enumeration (D-19).
  """

  alias Lockspire.Admin
  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Observability
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository
  import Ecto.Query, only: [where: 3, lock: 2]

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
    if client_id_from_url == client.client_id do
      Observability.emit(:dcr_management_read, %{count: 1}, %{
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
          {:ok, UpdateSuccess.t()} | {:error, Registration.Error.t()} | {:error, :invalid_token}
  def update(
        client_id_from_url,
        %{
          metadata: metadata,
          server_policy: %ServerPolicy{} = server_policy,
          client: %Client{} = client
        } = _request
      )
      when is_binary(client_id_from_url) and is_map(metadata) do
    if client_id_from_url != client.client_id do
      emit_unauthorized(client_id_from_url, client)
      {:error, :invalid_token}
    else
      with {:ok, resolved} <- DcrPolicy.resolve(server_policy, nil, metadata),
           :ok <- Registration.validate_intake_metadata(metadata, resolved),
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
    if client_id_from_url != client.client_id do
      emit_unauthorized(client_id_from_url, client)
      {:error, :invalid_token}
    else
      attrs = %{
        disabled_by: "dcr_self_delete",
        disabled_at: DateTime.utc_now(),
        actor: %{type: :self_registered_client, id: client.client_id}
      }

      case Admin.Clients.disable_client(client.client_id, attrs) do
        {:ok, %Client{}} ->
          Observability.emit(:dcr_management_deleted, %{count: 1}, %{
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
      Repository.transact(fn ->
        repo = Config.repo!()

        ClientRecord
        |> where([c], c.id == ^client.id)
        |> lock("FOR UPDATE")
        |> repo.one()
        |> case do
          nil ->
            repo.rollback(:not_found)

          record ->
            record
            |> Ecto.Changeset.change(
              registration_access_token_hash: new_rat_hash,
              updated_at: DateTime.utc_now()
            )
            |> repo.update()
            |> case do
              {:ok, updated_record} ->
                audit_attrs = %{
                  action: :dcr_management_rat_rotated,
                  outcome: :success,
                  actor: %{type: :operator, id: "admin-ui"},
                  resource: %{type: :client, id: client.client_id},
                  metadata: %{}
                }

                case Repository.append_audit_event(audit_attrs) do
                  {:ok, _} -> ClientRecord.to_domain(updated_record)
                  {:error, reason} -> repo.rollback(reason)
                end

              {:error, reason} ->
                repo.rollback(reason)
            end
        end
      end)

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
    updated_client = apply_metadata_to_client(client, metadata)

    Repository.transact(fn ->
      repo = Config.repo!()

      ClientRecord
      |> where([c], c.id == ^client.id)
      |> lock("FOR UPDATE")
      |> repo.one()
      |> case do
        nil ->
          repo.rollback(:not_found)

        record ->
          record
          |> ClientRecord.changeset(updated_client)
          |> Ecto.Changeset.change(
            registration_access_token_hash: new_rat_hash,
            updated_at: DateTime.utc_now()
          )
          |> repo.update()
          |> case do
            {:ok, updated_record} ->
              audit_attrs = %{
                action: :dcr_management_updated,
                outcome: :success,
                actor: %{type: :self_registered_client, id: client.client_id},
                resource: %{type: :client, id: client.client_id},
                metadata: %{}
              }

              case Repository.append_audit_event(audit_attrs) do
                {:ok, _} -> ClientRecord.to_domain(updated_record)
                {:error, reason} -> repo.rollback(reason)
              end

            {:error, reason} ->
              repo.rollback(reason)
          end
      end
    end)
  end

  defp apply_metadata_to_client(%Client{} = client, metadata) do
    auth_method =
      case Map.get(metadata, "token_endpoint_auth_method", "client_secret_basic") do
        "client_secret_post" -> :client_secret_post
        "private_key_jwt" -> :private_key_jwt
        "none" -> :none
        _ -> :client_secret_basic
      end

    client_type = if auth_method == :none, do: :public, else: :confidential

    allowed_scopes =
      case Map.get(metadata, "scope", "") do
        scope when is_binary(scope) -> String.split(scope, " ", trim: true)
        _ -> []
      end

    extension_metadata =
      metadata
      |> Map.take(["client_uri"])
      |> Map.reject(fn {_k, v} -> is_nil(v) end)

    %Client{
      client
      | client_type: client_type,
        name: Map.get(metadata, "client_name"),
        redirect_uris: Map.get(metadata, "redirect_uris", []),
        allowed_scopes: allowed_scopes,
        allowed_grant_types: Map.get(metadata, "grant_types", ["authorization_code"]),
        allowed_response_types: Map.get(metadata, "response_types", ["code"]),
        token_endpoint_auth_method: auth_method,
        logo_uri: Map.get(metadata, "logo_uri"),
        tos_uri: Map.get(metadata, "tos_uri"),
        policy_uri: Map.get(metadata, "policy_uri"),
        contacts: Map.get(metadata, "contacts", []),
        jwks: Map.get(metadata, "jwks"),
        metadata: extension_metadata
    }
  end

  defp emit_updated(%Client{} = client) do
    Observability.emit(:dcr_management_updated, %{count: 1}, %{
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id
    })
  end

  defp emit_rat_rotated(%Client{} = client) do
    Observability.emit(:dcr_registration_access_token_rotated, %{count: 1}, %{
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id
    })
  end

  defp emit_update_rejected(%Client{} = client, %Registration.Error{} = error) do
    Observability.emit(:dcr_management_updated, %{count: 1, rejected: 1}, %{
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id,
      code: error.code,
      field: error.field,
      reason: error.reason
    })
  end

  defp emit_unauthorized(client_id_from_url, %Client{} = client) do
    Observability.emit(:dcr_management_unauthorized, %{count: 1}, %{
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id_from_url: client_id_from_url,
      client_id: client.client_id
    })
  end
end
