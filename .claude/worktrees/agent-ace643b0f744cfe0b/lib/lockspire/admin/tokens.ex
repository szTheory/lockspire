defmodule Lockspire.Admin.Tokens do
  @moduledoc """
  Shared query and command boundary for operator token support workflows.
  """

  alias Lockspire.Admin.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Redaction
  alias Lockspire.Storage.Ecto.Repository

  @type token_status :: :active | :revoked | :expired | :reuse_detected

  @type token_view :: %{
          token: Token.t(),
          client: Client.t() | nil,
          status: token_status()
        }

  @type token_detail :: %{
          token: map(),
          client: Client.t() | nil,
          status: token_status(),
          family_tokens: [map()],
          family_status: token_status(),
          family_revoked_count: non_neg_integer(),
          family_active_count: non_neg_integer(),
          family_reuse_detected_at: DateTime.t() | nil
        }

  @spec list_tokens(keyword()) :: {:ok, [token_view()]} | {:error, term()}
  def list_tokens(opts \\ []) when is_list(opts) do
    with {:ok, tokens} <- Repository.list_lifecycle_tokens(opts) do
      {:ok, Enum.map(tokens, &enrich_token/1)}
    end
  end

  @spec get_token(integer()) :: {:ok, token_detail() | nil} | {:error, term()}
  def get_token(token_id) when is_integer(token_id) do
    with {:ok, token} <- Repository.fetch_lifecycle_token_by_id(token_id) do
      {:ok, build_detail(token)}
    end
  end

  @spec revoke_token(integer(), map()) :: {:ok, token_detail()} | {:error, term()}
  def revoke_token(token_id, attrs \\ %{}) when is_integer(token_id) and is_map(attrs) do
    actor = actor_from_attrs(attrs)
    attrs = normalize_revoke_attrs(attrs)
    revoked_at = Map.get(attrs, :revoked_at, DateTime.utc_now())
    revoked_reason = Map.get(attrs, :revoked_reason)

    with {:ok, %Token{} = token} <- fetch_existing_token(token_id),
         {:ok, {_revoked_token, detail}} <-
           transact_with_audit(
             fn -> revoke_token_detail(token, token_id, revoked_at) end,
             fn {revoked_token, _detail} ->
               revoke_audit_event(revoked_token, actor, revoked_reason)
             end
           ) do
      emit(:token_revoked, token, actor, %{
        token_id: token.id,
        reason_code: revoked_reason || :token_revoked
      })

      {:ok, detail}
    end
  end

  @spec revoke_token_family(integer(), map()) ::
          {:ok, %{count: non_neg_integer(), token: token_detail()}} | {:error, term()}
  def revoke_token_family(token_id, attrs \\ %{}) when is_integer(token_id) and is_map(attrs) do
    actor = actor_from_attrs(attrs)
    attrs = normalize_revoke_attrs(attrs)
    revoked_reason = Map.get(attrs, :revoked_reason)

    with {:ok, %Token{} = token} <- fetch_existing_token(token_id),
         family_id when is_binary(family_id) <- token.family_id || {:error, :no_family},
         {:ok, {count, detail}} <-
           transact_with_audit(
             fn -> revoke_token_family_detail(family_id, token_id) end,
             fn {count, _detail} ->
               revoke_family_audit_event(token, actor, count, revoked_reason)
             end
           ) do
      emit(:token_family_revoked, token, actor, %{
        family_id: family_id,
        revoked_count: count,
        reason_code: revoked_reason || :token_family_revoked
      })

      {:ok, %{count: count, token: detail}}
    else
      {:error, _reason} = error -> error
    end
  end

  defp fetch_existing_token(token_id) do
    case Repository.fetch_lifecycle_token_by_id(token_id) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, %Token{} = token} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end

  defp revoke_token_detail(%Token{} = token, token_id, revoked_at) do
    with {:ok, revoked_token} <-
           Repository.revoke_lifecycle_token(token.token_hash, token.client_id, revoked_at),
         {:ok, detail} <- get_token(token_id) do
      {:ok, {revoked_token || token, detail}}
    end
  end

  defp revoke_token_family_detail(family_id, token_id) do
    with {:ok, count} <- Repository.revoke_token_family(family_id),
         {:ok, detail} <- get_token(token_id) do
      {:ok, {count, detail}}
    end
  end

  defp build_detail(nil), do: nil

  defp build_detail(%Token{} = token) do
    client = fetch_client(token.client_id)
    family_tokens = load_family_tokens(token)

    %{
      token: token_detail_view(token, client),
      client: client,
      status: token_status(token),
      family_tokens: family_tokens,
      family_status: family_status(family_tokens),
      family_revoked_count: Enum.count(family_tokens, &(&1.status == :revoked)),
      family_active_count: Enum.count(family_tokens, &(&1.status == :active)),
      family_reuse_detected_at:
        family_tokens
        |> Enum.map(& &1.token.reuse_detected_at)
        |> Enum.reject(&is_nil/1)
        |> Enum.max_by(&DateTime.to_unix/1, fn -> nil end)
    }
  end

  defp enrich_token(%Token{} = token) do
    %{
      token: token,
      client: fetch_client(token.client_id),
      status: token_status(token)
    }
  end

  defp token_detail_view(%Token{} = token, client) do
    %{
      id: token.id,
      handle: token_handle(token),
      client_display: client_display(client, token.client_id),
      client_handle: Redaction.handle(:client, token.client_id),
      account_handle: optional_handle(:account, token.account_id),
      token_type: token.token_type,
      generation: token.generation,
      expires_at: token.expires_at,
      revoked_at: token.revoked_at,
      reuse_detected_at: token.reuse_detected_at,
      family_id: token.family_id,
      family_handle: optional_handle(:family, token.family_id),
      parent_handle: parent_handle(token.parent_token_id),
      scopes: token.scopes
    }
  end

  defp token_family_entry(%Token{} = token, current_token_id) do
    %{
      token: %{
        handle: token_handle(token),
        token_type: token.token_type,
        generation: token.generation,
        reuse_detected_at: token.reuse_detected_at
      },
      status: token_status(token),
      current?: token.id == current_token_id
    }
  end

  defp fetch_client(client_id) do
    case Clients.get_client(client_id) do
      {:ok, %Client{} = client} -> client
      _other -> nil
    end
  end

  defp token_status(%Token{reuse_detected_at: %DateTime{}}), do: :reuse_detected
  defp token_status(%Token{revoked_at: %DateTime{}}), do: :revoked

  defp token_status(%Token{expires_at: %DateTime{} = expires_at}) do
    if DateTime.compare(expires_at, DateTime.utc_now()) == :gt, do: :active, else: :expired
  end

  defp family_status(tokens) do
    cond do
      Enum.any?(tokens, &(&1.status == :reuse_detected)) -> :reuse_detected
      Enum.any?(tokens, &(&1.status == :active)) -> :active
      Enum.any?(tokens, &(&1.status == :expired)) -> :expired
      true -> :revoked
    end
  end

  defp token_handle(%Token{} = token) do
    source =
      cond do
        is_integer(token.id) -> token.id
        is_binary(token.family_id) -> "#{token.family_id}:#{token.generation}"
        true -> token.token_hash
      end

    Redaction.handle(:token, source)
  end

  defp client_display(%Client{name: name}, _client_id) when is_binary(name) and name != "",
    do: name

  defp client_display(_client, client_id), do: Redaction.handle(:client, client_id)

  defp optional_handle(_type, nil), do: nil
  defp optional_handle(type, value), do: Redaction.handle(type, value)

  defp parent_handle(nil), do: nil
  defp parent_handle(value), do: Redaction.handle(:token, value)

  defp normalize_revoke_attrs(attrs) do
    attrs
    |> Map.new(fn {key, value} -> {normalize_key(key), value} end)
    |> Map.take([:actor, :revoked_at, :revoked_by, :revoked_reason, :status])
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    case key do
      "actor" -> :actor
      "revoked_at" -> :revoked_at
      "revoked_by" -> :revoked_by
      "revoked_reason" -> :revoked_reason
      "status" -> :status
      _other -> key
    end
  end

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

  defp load_family_tokens(%Token{family_id: family_id} = token) when is_binary(family_id) do
    case Repository.list_token_family(family_id) do
      {:ok, tokens} -> Enum.map(tokens, &token_family_entry(&1, token.id))
      {:error, _reason} -> [token_family_entry(token, token.id)]
    end
  end

  defp load_family_tokens(%Token{} = token), do: [token_family_entry(token, token.id)]

  defp append_audit_event(build_audit_event, result) do
    case Repository.append_audit_event(build_audit_event.(result)) do
      {:ok, _event} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp emit(event, %Token{} = token, actor, metadata) do
    raw_metadata =
      %{
        actor_type: actor[:type],
        actor_id: actor[:id],
        client_id: token.client_id
      }
      |> Map.merge(metadata)

    final_metadata =
      raw_metadata
      |> Observability.redact()
      |> restore_unredacted_ids(raw_metadata)

    :telemetry.execute([:lockspire, :audit, event], %{count: 1}, final_metadata)
    :telemetry.execute([:lockspire, event], %{count: 1}, final_metadata)
  end

  defp restore_unredacted_ids(metadata, raw_metadata) do
    metadata
    |> maybe_restore_raw_id(:family_id, raw_metadata)
    |> maybe_restore_raw_id(:token_id, raw_metadata)
  end

  defp maybe_restore_raw_id(metadata, key, raw_metadata) do
    case Map.fetch(raw_metadata, key) do
      {:ok, value} -> Map.put(metadata, key, value)
      :error -> metadata
    end
  end

  defp revoke_audit_event(%Token{} = token, actor, revoked_reason) do
    %{
      action: :token_revoked,
      outcome: :succeeded,
      reason_code: revoked_reason || :token_revoked,
      actor: actor,
      resource: %{type: token.token_type, id: token.id || token.token_hash},
      metadata: %{
        token_id: token.id,
        client_id: token.client_id,
        account_id: token.account_id,
        family_id: token.family_id
      }
    }
  end

  defp revoke_family_audit_event(%Token{} = token, actor, count, revoked_reason) do
    %{
      action: :token_family_revoked,
      outcome: :succeeded,
      reason_code: revoked_reason || :token_family_revoked,
      actor: actor,
      resource: %{type: :token_family, id: token.family_id},
      metadata: %{
        token_id: token.id,
        client_id: token.client_id,
        account_id: token.account_id,
        revoked_count: count
      }
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
    case String.trim(value) do
      "" -> :operator
      normalized -> normalized
    end
  end

  defp normalize_actor_type(_value), do: :operator

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(_value), do: nil
end
