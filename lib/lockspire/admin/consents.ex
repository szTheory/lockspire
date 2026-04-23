defmodule Lockspire.Admin.Consents do
  @moduledoc """
  Shared query and command boundary for operator and host-owned consent workflows.
  """

  alias Lockspire.Admin.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.Repository

  @type consent_view :: %{grant: ConsentGrant.t(), client: Client.t() | nil}

  @spec list_consents(keyword()) :: {:ok, [consent_view()]} | {:error, term()}
  def list_consents(opts \\ []) when is_list(opts) do
    with {:ok, grants} <- Repository.list_consents(opts) do
      {:ok, enrich_consents(grants)}
    end
  end

  @spec list_consents_for_account(String.t()) :: {:ok, [consent_view()]} | {:error, term()}
  def list_consents_for_account(account_id) when is_binary(account_id) do
    with {:ok, grants} <- Repository.list_consents_for_account(account_id) do
      {:ok, enrich_consents(grants)}
    end
  end

  @spec get_consent(integer()) :: {:ok, consent_view() | nil} | {:error, term()}
  def get_consent(grant_id) when is_integer(grant_id) do
    with {:ok, grant} <- Repository.fetch_consent_grant(grant_id) do
      {:ok, maybe_enrich_consent(grant)}
    end
  end

  @spec revoke_consent(integer(), map()) :: {:ok, consent_view()} | {:error, term()}
  def revoke_consent(grant_id, attrs \\ %{}) when is_integer(grant_id) and is_map(attrs) do
    actor = actor_from_attrs(attrs)

    attrs =
      attrs
      |> normalize_revoke_attrs()
      |> Map.put_new(:status, :revoked)
      |> Map.put_new(:revoked_at, DateTime.utc_now())

    case transact_with_audit(
           fn -> Repository.revoke_consent_grant(grant_id, attrs) end,
           fn %ConsentGrant{} = grant ->
             revoke_audit_event(grant, actor)
           end
         ) do
      {:ok, %ConsentGrant{} = grant} ->
        consent = enrich_consent(grant)
        emit(:consent_revoked, consent.grant, actor)
        {:ok, consent}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp enrich_consents(grants), do: Enum.map(grants, &enrich_consent/1)
  defp maybe_enrich_consent(nil), do: nil
  defp maybe_enrich_consent(%ConsentGrant{} = grant), do: enrich_consent(grant)

  defp enrich_consent(%ConsentGrant{} = grant) do
    %{grant: grant, client: fetch_client(grant.client_id)}
  end

  defp fetch_client(client_id) do
    case Clients.get_client(client_id) do
      {:ok, %Client{} = client} -> client
      _other -> nil
    end
  end

  defp normalize_revoke_attrs(attrs) do
    attrs
    |> Map.new(fn {key, value} -> {normalize_key(key), value} end)
    |> Map.take([:revoked_at, :revoked_by, :revoked_reason, :status])
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    case key do
      "revoked_at" -> :revoked_at
      "revoked_by" -> :revoked_by
      "revoked_reason" -> :revoked_reason
      "status" -> :status
      _other -> key
    end
  end

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

  defp emit(event, %ConsentGrant{} = grant, actor) do
    Observability.emit(event, %{}, %{
      actor_type: actor[:type],
      actor_id: actor[:id],
      grant_id: grant.id,
      client_id: grant.client_id,
      account_id: grant.account_id,
      reason_code: grant.revoked_reason || event
    })
  end

  defp revoke_audit_event(%ConsentGrant{} = grant, actor) do
    %{
      action: :consent_revoked,
      outcome: :succeeded,
      reason_code: grant.revoked_reason || :consent_revoked,
      actor: actor,
      resource: %{type: :consent_grant, id: grant.id},
      metadata: %{
        grant_id: grant.id,
        client_id: grant.client_id,
        account_id: grant.account_id,
        status: grant.status,
        revoked_by: grant.revoked_by
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
    value
    |> String.trim()
    |> case do
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
