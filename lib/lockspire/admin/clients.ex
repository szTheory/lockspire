defmodule Lockspire.Admin.Clients do
  @moduledoc """
  Query and command boundary for operator-managed OAuth clients.
  """

  alias Lockspire.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.Repository

  @mutable_fields ~w(
    name
    redirect_uris
    post_logout_redirect_uris
    backchannel_logout_uri
    backchannel_logout_session_required
    frontchannel_logout_uri
    frontchannel_logout_session_required
    allowed_scopes
    logo_uri
    tos_uri
    policy_uri
    contacts
    par_policy
    dpop_policy
    security_profile
    metadata
    max_delegation_depth
  )a
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
        emit(:client, :created, client, actor, %{
          client_type: client.client_type,
          token_endpoint_auth_method: client.token_endpoint_auth_method
        })

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec create_dcr_client(%{required(:client) => Client.t(), required(:actor) => map()}) ::
          {:ok, Client.t()} | {:error, term()}
  def create_dcr_client(%{client: %Client{} = client} = attrs) when is_map(attrs) do
    actor = actor_from_attrs(attrs)

    audit_event =
      client_audit_event(:dcr_client_created, :succeeded, client, actor, %{
        client_id: client.client_id,
        provenance: client.provenance
      })

    case Repository.transact_with_audit(audit_event, fn -> Repository.register_client(client) end) do
      {:ok, %Client{} = persisted} ->
        Observability.emit(:dcr, :client_created, %{}, %{
          actor_type: actor[:type],
          actor_id: actor[:id],
          client_id: persisted.client_id,
          provenance: persisted.provenance
        })

        {:ok, persisted}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}

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
         :ok <- validate_safe_update(client, attrs) do
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

      case rotate_client_secret_with_audit(client, secret_hash, rotated_at, actor) do
        {:ok, %Client{} = updated_client} ->
          emit(:client, :secret_rotated, updated_client, actor, %{rotated_at: rotated_at})
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
      case disable_client_with_audit(client, disabled_at, disabled_by, actor) do
        {:ok, %Client{} = updated_client} ->
          emit(:client, :disabled, updated_client, actor, %{disabled_at: disabled_at})
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

  defp validate_safe_update(%Client{} = client, attrs) do
    errors =
      []
      |> maybe_append_errors(validate_redirects_if_present(attrs))
      |> maybe_append_errors(validate_post_logout_redirects_if_present(attrs))
      |> maybe_append_errors(
        validate_logout_propagation(attrs, effective_redirect_uris(client, attrs))
      )
      |> maybe_append_errors(validate_scopes_if_present(attrs))
      |> maybe_append_errors(validate_par_policy_if_present(attrs))
      |> maybe_append_errors(validate_dpop_policy_if_present(attrs))
      |> maybe_append_errors(validate_security_profile_if_present(client, attrs))

    case errors do
      [] -> :ok
      _errors -> {:error, errors}
    end
  end

  defp validate_redirects_if_present(attrs) do
    case fetch_attr(attrs, :redirect_uris) do
      nil ->
        :ok

      redirect_uris ->
        Clients.validate_redirect_uris(redirect_uris)
    end
  end

  defp validate_scopes_if_present(attrs) do
    case fetch_attr(attrs, :allowed_scopes) do
      nil ->
        :ok

      allowed_scopes ->
        Clients.validate_allowed_scopes(allowed_scopes)
    end
  end

  defp validate_post_logout_redirects_if_present(attrs) do
    case fetch_attr(attrs, :post_logout_redirect_uris) do
      nil ->
        :ok

      post_logout_redirect_uris ->
        case Clients.validate_redirect_uris(post_logout_redirect_uris) do
          :ok ->
            :ok

          {:error, errors} ->
            {:error, Enum.map(errors, &Map.put(&1, :field, :post_logout_redirect_uris))}
        end
    end
  end

  defp validate_logout_propagation(attrs, redirect_uris) do
    []
    |> maybe_add_logout_uri_error(attrs, :backchannel_logout_uri)
    |> maybe_add_logout_uri_error(attrs, :frontchannel_logout_uri)
    |> maybe_add_session_required_error(
      attrs,
      :backchannel_logout_uri,
      :backchannel_logout_session_required
    )
    |> maybe_add_session_required_error(
      attrs,
      :frontchannel_logout_uri,
      :frontchannel_logout_session_required
    )
    |> maybe_add_frontchannel_origin_error(attrs, redirect_uris)
    |> Enum.reverse()
  end

  defp validate_par_policy_if_present(attrs) do
    case fetch_mutable_attr(attrs, :par_policy) do
      :error ->
        :ok

      {:ok, value} ->
        case normalize_par_policy(value) do
          {:ok, _policy} ->
            :ok

          :error ->
            {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: value}]}
        end
    end
  end

  defp validate_dpop_policy_if_present(attrs) do
    case fetch_mutable_attr(attrs, :dpop_policy) do
      :error ->
        :ok

      {:ok, value} ->
        case normalize_dpop_policy(value) do
          {:ok, _policy} ->
            :ok

          :error ->
            {:error, [%{field: :dpop_policy, reason: :invalid_dpop_policy, detail: value}]}
        end
    end
  end

  defp validate_security_profile_if_present(client, attrs) do
    case fetch_mutable_attr(attrs, :security_profile) do
      :error ->
        :ok

      {:ok, value} ->
        with {:ok, profile} <- normalize_security_profile(value),
             :ok <- check_fapi_signing_readiness(client.security_profile, profile) do
          :ok
        else
          :error ->
            {:error,
             [%{field: :security_profile, reason: :invalid_security_profile, detail: value}]}

          {:error, reason}
          when reason in [:missing_compliant_active_key, :missing_compliant_publishable_key] ->
            {:error, [%{field: :security_profile, reason: reason, detail: :fapi_2_0_security}]}
        end
    end
  end

  @doc false
  def check_fapi_signing_readiness(:fapi_2_0_security, :fapi_2_0_security), do: :ok

  def check_fapi_signing_readiness(_old_profile, :fapi_2_0_security) do
    Repository.validate_fapi_signing_readiness()
  end

  def check_fapi_signing_readiness(_old_profile, _new_profile), do: :ok

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
      case fetch_mutable_attr(attrs, field) do
        {:ok, value} ->
          normalized = normalize_mutable_field(field, value)
          acc = Map.put(acc, field, normalized)
          maybe_reset_logout_session_required(acc, field, normalized)

        :error ->
          acc
      end
    end)
  end

  defp normalize_mutable_field(field, value)
       when field in [:redirect_uris, :post_logout_redirect_uris, :allowed_scopes, :contacts] do
    normalize_string_list(value)
  end

  defp normalize_mutable_field(:par_policy, value) do
    case normalize_par_policy(value) do
      {:ok, policy} -> policy
      :error -> value
    end
  end

  defp normalize_mutable_field(:dpop_policy, value) do
    case normalize_dpop_policy(value) do
      {:ok, policy} -> policy
      :error -> value
    end
  end

  defp normalize_mutable_field(:security_profile, value) do
    case normalize_security_profile(value) do
      {:ok, profile} -> profile
      :error -> value
    end
  end

  defp normalize_mutable_field(:metadata, value) when is_map(value), do: value
  defp normalize_mutable_field(:metadata, _value), do: %{}

  defp normalize_mutable_field(field, value)
       when field in [:backchannel_logout_session_required, :frontchannel_logout_session_required] do
    normalize_boolean(value)
  end

  defp normalize_mutable_field(:max_delegation_depth, value) when is_integer(value), do: value
  defp normalize_mutable_field(:max_delegation_depth, value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end
  defp normalize_mutable_field(:max_delegation_depth, _value), do: nil

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

  defp normalize_boolean(value) when value in [true, "true", 1, "1"], do: true
  defp normalize_boolean(value) when value in [false, "false", 0, "0", nil, ""], do: false
  defp normalize_boolean(_value), do: false

  defp normalize_par_policy(:inherit), do: {:ok, :inherit}
  defp normalize_par_policy(:required), do: {:ok, :required}
  defp normalize_par_policy(:optional), do: {:ok, :optional}

  defp normalize_par_policy(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "inherit" -> {:ok, :inherit}
      "required" -> {:ok, :required}
      "optional" -> {:ok, :optional}
      _other -> :error
    end
  end

  defp normalize_par_policy(_value), do: :error

  defp normalize_dpop_policy(:inherit), do: {:ok, :inherit}
  defp normalize_dpop_policy(:bearer), do: {:ok, :bearer}
  defp normalize_dpop_policy(:dpop), do: {:ok, :dpop}

  defp normalize_dpop_policy(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "inherit" -> {:ok, :inherit}
      "bearer" -> {:ok, :bearer}
      "dpop" -> {:ok, :dpop}
      _other -> :error
    end
  end

  defp normalize_dpop_policy(_value), do: :error

  defp normalize_security_profile(:inherit), do: {:ok, :inherit}
  defp normalize_security_profile(:fapi_2_0_security), do: {:ok, :fapi_2_0_security}
  defp normalize_security_profile(:none), do: {:ok, :none}

  defp normalize_security_profile(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "inherit" -> {:ok, :inherit}
      "fapi_2_0_security" -> {:ok, :fapi_2_0_security}
      "none" -> {:ok, :none}
      _other -> :error
    end
  end

  defp normalize_security_profile(_value), do: :error

  defp normalize_field_name(value) when is_atom(value), do: value

  defp normalize_field_name(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end

  defp normalize_field_name(_value), do: nil

  defp transact_with_audit(fun, build_audit_event)
       when is_function(fun, 0) and is_function(build_audit_event, 1) do
    Repository.transact(fn ->
      case fun.() do
        {:ok, result} ->
          append_audit_event(build_audit_event, result)

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  defp fetch_attr(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} ->
        value

      :error ->
        case Map.fetch(attrs, Atom.to_string(key)) do
          {:ok, value} -> value
          :error -> nil
        end
    end
  end

  defp fetch_mutable_attr(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} -> {:ok, value}
      :error -> Map.fetch(attrs, Atom.to_string(field))
    end
  end

  defp maybe_append_errors(errors, :ok), do: errors
  defp maybe_append_errors(errors, []), do: errors
  defp maybe_append_errors(errors, {:error, new_errors}), do: errors ++ new_errors
  defp maybe_append_errors(errors, new_errors) when is_list(new_errors), do: errors ++ new_errors

  defp maybe_add_logout_uri_error(errors, attrs, field) do
    case fetch_attr(attrs, field) do
      nil ->
        errors

      uri ->
        case Clients.validate_logout_uri(uri) do
          :ok ->
            errors

          {:error, error} ->
            [Map.put(error, :field, field) | errors]
        end
    end
  end

  defp maybe_add_session_required_error(errors, attrs, uri_field, session_field) do
    session_required = normalize_boolean(fetch_attr(attrs, session_field))
    uri = normalize_string(fetch_attr(attrs, uri_field))

    if session_required and is_nil(uri) do
      [%{field: session_field, reason: :logout_uri_required, detail: uri_field} | errors]
    else
      errors
    end
  end

  defp maybe_add_frontchannel_origin_error(errors, attrs, redirect_uris) do
    case normalize_string(fetch_attr(attrs, :frontchannel_logout_uri)) do
      nil ->
        errors

      uri ->
        if Clients.frontchannel_logout_origin_matches_redirect_uri?(uri, redirect_uris) do
          errors
        else
          [
            %{
              field: :frontchannel_logout_uri,
              reason: :frontchannel_logout_origin_mismatch,
              detail: uri
            }
            | errors
          ]
        end
    end
  end

  defp effective_redirect_uris(%Client{} = client, attrs) do
    case fetch_attr(attrs, :redirect_uris) do
      nil -> client.redirect_uris
      redirect_uris -> normalize_string_list(redirect_uris)
    end
  end

  defp maybe_reset_logout_session_required(attrs, :backchannel_logout_uri, nil),
    do: Map.put(attrs, :backchannel_logout_session_required, false)

  defp maybe_reset_logout_session_required(attrs, :frontchannel_logout_uri, nil),
    do: Map.put(attrs, :frontchannel_logout_session_required, false)

  defp maybe_reset_logout_session_required(attrs, _field, _value), do: attrs

  defp rotate_client_secret_with_audit(client, secret_hash, rotated_at, actor) do
    transact_with_audit(
      fn -> Repository.rotate_client_secret(client, secret_hash, rotated_at) end,
      fn %Client{} = updated_client ->
        client_audit_event(:client_secret_rotated, :succeeded, updated_client, actor, %{
          rotated_at: rotated_at
        })
      end
    )
  end

  defp disable_client_with_audit(client, disabled_at, disabled_by, actor) do
    transact_with_audit(
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
    )
  end

  defp append_audit_event(build_audit_event, result) do
    case Repository.append_audit_event(build_audit_event.(result)) do
      {:ok, _event} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp emit(entity, action, %Client{} = client, actor, metadata) do
    Observability.emit(
      entity,
      action,
      %{},
      %{
        actor_type: actor[:type],
        actor_id: actor[:id],
        client_id: client.client_id,
        reason_code: action
      }
      |> Map.merge(metadata)
    )
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

  defp normalize_actor_type(nil) do
    raise ArgumentError,
          "actor.type is required; pass attrs[:actor][:type] explicitly. " <>
            "Allowed: :operator | :system | :host_app | :dcr | :self_registered_client"
  end

  defp normalize_actor_type(value) when is_atom(value), do: value

  defp normalize_actor_type(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> raise ArgumentError, "actor.type cannot be blank"
      normalized -> normalized
    end
  end

  defp normalize_actor_type(other) do
    raise ArgumentError,
          "actor.type must be an atom or non-blank string, got: " <> inspect(other)
  end
end
