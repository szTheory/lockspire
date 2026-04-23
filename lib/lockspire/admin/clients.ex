defmodule Lockspire.Admin.Clients do
  @moduledoc """
  Query and command boundary for operator-managed OAuth clients.
  """

  alias Lockspire.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.Repository

  @mutable_fields ~w(name redirect_uris allowed_scopes logo_uri tos_uri policy_uri contacts metadata)a
  @immutable_fields ~w(
    client_id
    client_type
    token_endpoint_auth_method
    pkce_required
    subject_type
    allowed_grant_types
    allowed_response_types
    client_secret_hash
    active
    disabled_at
    disabled_by
    last_secret_rotated_at
  )a

  @type error_detail :: %{field: atom(), reason: atom(), detail: term()}

  @spec list_clients(keyword()) :: {:ok, [Client.t()]} | {:error, term()}
  def list_clients(opts \\ []) do
    Repository.list_clients(opts)
  end

  @spec get_client(String.t()) :: {:ok, Client.t()} | {:error, :not_found | term()}
  def get_client(client_id) when is_binary(client_id) do
    case Repository.fetch_client_by_id(client_id) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, %Client{} = client} -> {:ok, client}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec create_client(map() | keyword()) ::
          {:ok, RegistrationResult.t()} | {:error, [Clients.error_detail()]}
  def create_client(attrs) when is_list(attrs) do
    create_client(Enum.into(attrs, %{}))
  end

  def create_client(attrs) when is_map(attrs) do
    actor = actor_from_attrs(attrs)

    case transact_with_audit(
           fn -> Clients.register_client(attrs) end,
           fn %RegistrationResult{client: client} ->
             client_audit_event(:client_created, :succeeded, client, actor, %{
               client_type: client.client_type,
               token_endpoint_auth_method: client.token_endpoint_auth_method
             })
           end
         ) do
      {:ok, %RegistrationResult{client: client} = result} ->
        emit(:client_created, client, actor, %{
          client_type: client.client_type,
          token_endpoint_auth_method: client.token_endpoint_auth_method
        })

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec update_client(String.t(), map() | keyword()) ::
          {:ok, Client.t()} | {:error, [error_detail()]} | {:error, term()}
  def update_client(client_id, attrs) when is_binary(client_id) and is_list(attrs) do
    update_client(client_id, Enum.into(attrs, %{}))
  end

  def update_client(client_id, attrs) when is_binary(client_id) and is_map(attrs) do
    with {:ok, %Client{} = client} <- get_client(client_id),
         :ok <- reject_immutable_changes(attrs),
         :ok <- validate_safe_update(attrs) do
      Repository.update_client(client, normalize_update_attrs(attrs))
    else
      {:error, :not_found} = error -> error
      {:error, [_ | _] = errors} -> {:error, errors}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec rotate_client_secret(String.t(), map() | keyword()) ::
          {:ok, %{client: Client.t(), client_secret: String.t()}}
          | {:error, [error_detail()]}
          | {:error, term()}
  def rotate_client_secret(client_id, attrs \\ %{})

  def rotate_client_secret(client_id, attrs) when is_list(attrs) do
    rotate_client_secret(client_id, Enum.into(attrs, %{}))
  end

  def rotate_client_secret(client_id, attrs) when is_binary(client_id) and is_map(attrs) do
    rotated_at = Map.get(attrs, :rotated_at, DateTime.utc_now())
    actor = actor_from_attrs(attrs)

    with {:ok, %Client{} = client} <- get_client(client_id),
         :ok <- ensure_confidential_client(client) do
      {secret_hash, plaintext_secret} = Clients.rotate_secret_hash()

      case transact_with_audit(
             fn -> Repository.rotate_client_secret(client, secret_hash, rotated_at) end,
             fn %Client{} = updated_client ->
               client_audit_event(:client_secret_rotated, :succeeded, updated_client, actor, %{
                 rotated_at: rotated_at
               })
             end
           ) do
        {:ok, %Client{} = updated_client} ->
          emit(:client_secret_rotated, updated_client, actor, %{rotated_at: rotated_at})
          {:ok, %{client: updated_client, client_secret: plaintext_secret}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, [_ | _] = errors} -> {:error, errors}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec disable_client(String.t(), map() | keyword()) ::
          {:ok, Client.t()} | {:error, :not_found | term()}
  def disable_client(client_id, attrs \\ %{})

  def disable_client(client_id, attrs) when is_list(attrs) do
    disable_client(client_id, Enum.into(attrs, %{}))
  end

  def disable_client(client_id, attrs) when is_binary(client_id) and is_map(attrs) do
    actor = actor_from_attrs(attrs)
    disabled_by = normalize_string(Map.get(attrs, :disabled_by))
    disabled_at = Map.get(attrs, :disabled_at, DateTime.utc_now())

    with {:ok, %Client{} = client} <- get_client(client_id) do
      case transact_with_audit(
             fn ->
               Repository.set_client_active(client, false, %{
                 disabled_at: disabled_at,
                 disabled_by: disabled_by
               })
             end,
             fn %Client{} = updated_client ->
               client_audit_event(:client_disabled, :succeeded, updated_client, actor, %{
                 disabled_at: disabled_at,
                 disabled_by: disabled_by
               })
             end
           ) do
        {:ok, %Client{} = updated_client} ->
          emit(:client_disabled, updated_client, actor, %{disabled_at: disabled_at})
          {:ok, updated_client}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec enable_client(String.t(), map() | keyword()) ::
          {:ok, Client.t()} | {:error, :not_found | term()}
  def enable_client(client_id, attrs \\ %{})

  def enable_client(client_id, attrs) when is_list(attrs) do
    enable_client(client_id, Enum.into(attrs, %{}))
  end

  def enable_client(client_id, _attrs) when is_binary(client_id) do
    with {:ok, %Client{} = client} <- get_client(client_id) do
      Repository.set_client_active(client, true, %{disabled_at: nil, disabled_by: nil})
    end
  end

  defp validate_safe_update(attrs) do
    with :ok <- validate_redirects_if_present(attrs),
         :ok <- validate_scopes_if_present(attrs) do
      :ok
    end
  end

  defp validate_redirects_if_present(attrs) do
    if Map.has_key?(attrs, :redirect_uris) or Map.has_key?(attrs, "redirect_uris") do
      case Clients.validate_redirect_uris(
             Map.get(attrs, :redirect_uris) || Map.get(attrs, "redirect_uris")
           ) do
        :ok -> :ok
        {:error, errors} -> {:error, errors}
      end
    else
      :ok
    end
  end

  defp validate_scopes_if_present(attrs) do
    if Map.has_key?(attrs, :allowed_scopes) or Map.has_key?(attrs, "allowed_scopes") do
      case Clients.validate_allowed_scopes(
             Map.get(attrs, :allowed_scopes) || Map.get(attrs, "allowed_scopes")
           ) do
        :ok -> :ok
        {:error, errors} -> {:error, errors}
      end
    else
      :ok
    end
  end

  defp reject_immutable_changes(attrs) do
    attempted =
      attrs
      |> Map.keys()
      |> Enum.map(&normalize_field_name/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(&(&1 in @immutable_fields))

    case attempted do
      [] ->
        :ok

      fields ->
        {:error,
         Enum.map(fields, fn field ->
           %{field: field, reason: :immutable_field, detail: "cannot be changed after creation"}
         end)}
    end
  end

  defp ensure_confidential_client(%Client{client_type: :confidential}), do: :ok

  defp ensure_confidential_client(%Client{}) do
    {:error, [%{field: :client_type, reason: :client_secret_not_allowed, detail: :public}]}
  end

  defp normalize_update_attrs(attrs) do
    Enum.reduce(@mutable_fields, %{}, fn field, acc ->
      case Map.fetch(attrs, field) do
        {:ok, value} ->
          Map.put(acc, field, normalize_mutable_field(field, value))

        :error ->
          case Map.fetch(attrs, Atom.to_string(field)) do
            {:ok, value} -> Map.put(acc, field, normalize_mutable_field(field, value))
            :error -> acc
          end
      end
    end)
  end

  defp normalize_mutable_field(field, value)
       when field in [:redirect_uris, :allowed_scopes, :contacts] do
    normalize_string_list(value)
  end

  defp normalize_mutable_field(:metadata, value) when is_map(value), do: value
  defp normalize_mutable_field(:metadata, _value), do: %{}
  defp normalize_mutable_field(_field, value), do: normalize_string(value)

  defp normalize_string_list(nil), do: []

  defp normalize_string_list(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&normalize_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp normalize_string_list(value) when is_list(value) do
    value
    |> Enum.map(&normalize_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp normalize_string_list(_value), do: []

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(_value), do: nil

  defp normalize_field_name(value) when is_atom(value), do: value

  defp normalize_field_name(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> nil
    end
  end

  defp normalize_field_name(_value), do: nil

  defp transact_with_audit(fun, build_audit_event) when is_function(fun, 0) and is_function(build_audit_event, 1) do
    Repository.transact(fn ->
      case fun.() do
        {:ok, result} ->
          case Repository.append_audit_event(build_audit_event.(result)) do
            {:ok, _event} -> result
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  defp emit(event, %Client{} = client, actor, metadata) do
    Observability.emit(event, %{}, %{
      actor_type: actor[:type],
      actor_id: actor[:id],
      client_id: client.client_id,
      reason_code: event
    } |> Map.merge(metadata))
  end

  defp client_audit_event(action, outcome, %Client{} = client, actor, metadata) do
    %{
      action: action,
      outcome: outcome,
      reason_code: action,
      actor: actor,
      resource: %{type: :client, id: client.client_id},
      metadata: Map.merge(%{client_id: client.client_id}, metadata)
    }
  end

  defp actor_from_attrs(attrs) when is_map(attrs) do
    actor = Map.get(attrs, :actor) || Map.get(attrs, "actor") || %{}

    %{
      type: normalize_actor_type(Map.get(actor, :type) || Map.get(actor, "type")),
      id: normalize_string(Map.get(actor, :id) || Map.get(actor, "id")),
      display: normalize_string(Map.get(actor, :display) || Map.get(actor, "display"))
    }
  end

  defp normalize_actor_type(nil), do: :operator
  defp normalize_actor_type(value) when is_atom(value), do: value

  defp normalize_actor_type(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> :operator
      normalized -> normalized
    end
  end

  defp normalize_actor_type(_value), do: :operator
end
