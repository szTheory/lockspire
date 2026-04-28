defmodule Lockspire.Admin.ServerPolicy do
  @moduledoc """
  Query and command boundary for Lockspire server policy.
  """

  require Logger

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  @type error_detail :: %{field: atom(), reason: atom(), detail: term()}

  @registration_policy_atoms [:disabled, :initial_access_token, :open]
  @registration_policy_strings ["disabled", "initial_access_token", "open"]

  @dcr_field_keys [
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
  ]

  @spec get_server_policy() :: {:ok, ServerPolicy.t()} | {:error, term()}
  def get_server_policy do
    Repository.get_server_policy()
  end

  @spec put_server_policy(atom() | String.t()) ::
          {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
  def put_server_policy(mode) do
    with {:ok, normalized_mode} <- normalize_par_policy(mode) do
      Repository.update_server_policy(fn %ServerPolicy{} = current ->
        %ServerPolicy{current | par_policy: normalized_mode}
      end)
    end
  end

  @spec put_dpop_policy(atom() | String.t()) ::
          {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
  def put_dpop_policy(mode) do
    with {:ok, normalized_mode} <- normalize_dpop_policy(mode) do
      Repository.update_server_policy(fn %ServerPolicy{} = current ->
        %ServerPolicy{current | dpop_policy: normalized_mode}
      end)
    end
  end

  @doc """
  Returns the current DCR policy view as a `%Domain.ServerPolicy{}` (the same struct
  used by `get_server_policy/0` — DCR fields land on the singleton row per D-04).

  Phase 28 admin LiveView consumes this; Phase 26 intake validator and
  `Lockspire.Protocol.DcrPolicy.resolve/3` consume the same struct.
  """
  @spec get_dcr_policy() :: {:ok, ServerPolicy.t()} | {:error, term()}
  def get_dcr_policy do
    Repository.get_server_policy()
  end

  @doc """
  Persists the DCR-shaped fields onto the server-policy singleton row, preserving any
  non-DCR fields (notably `par_policy`) on the same row.

  Accepts a map keyed by atoms or strings. Unknown keys are ignored. Validates the
  `:registration_policy` value is `:disabled | :initial_access_token | :open`.

  Returns `{:ok, %Domain.ServerPolicy{}}` on success or a list-shaped error per the
  `error_detail` typespec.
  """
  @spec put_dcr_policy(map()) ::
          {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
  def put_dcr_policy(attrs) when is_map(attrs) do
    with {:ok, normalized_attrs} <- normalize_dcr_attrs(attrs) do
      Repository.update_server_policy(fn %ServerPolicy{} = current ->
        Map.merge(current, normalized_attrs)
      end)
    end
  end

  defp normalize_par_policy(:optional), do: {:ok, :optional}
  defp normalize_par_policy(:required), do: {:ok, :required}

  defp normalize_par_policy(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "optional" -> {:ok, :optional}
      "required" -> {:ok, :required}
      _other -> invalid_par_policy(value)
    end
  end

  defp normalize_par_policy(value), do: invalid_par_policy(value)

  defp invalid_par_policy(value) do
    {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: value}]}
  end

  defp normalize_dpop_policy(:bearer), do: {:ok, :bearer}
  defp normalize_dpop_policy(:dpop), do: {:ok, :dpop}

  defp normalize_dpop_policy(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "bearer" -> {:ok, :bearer}
      "dpop" -> {:ok, :dpop}
      _other -> invalid_dpop_policy(value)
    end
  end

  defp normalize_dpop_policy(value), do: invalid_dpop_policy(value)

  defp invalid_dpop_policy(value) do
    {:error, [%{field: :dpop_policy, reason: :invalid_dpop_policy, detail: value}]}
  end

  defp normalize_dcr_attrs(attrs) do
    {atomized, unknown_keys} =
      Enum.reduce(attrs, {%{}, []}, fn
        {key, value}, {acc, unknown} when is_atom(key) ->
          if key in @dcr_field_keys do
            {Map.put(acc, key, value), unknown}
          else
            {acc, [key | unknown]}
          end

        {key, value}, {acc, unknown} when is_binary(key) ->
          case atomize_dcr_key(key) do
            nil -> {acc, [key | unknown]}
            atom_key -> {Map.put(acc, atom_key, value), unknown}
          end

        _other, acc ->
          acc
      end)

    if unknown_keys != [] do
      # Phase 28 admin LiveView: silent drops of typo'd field names is a known operator-UX
      # hazard. Logging here gives operators a breadcrumb when an admin form sends an
      # unexpected key (e.g., :dcr_allowed_scope vs :dcr_allowed_scopes); a future iteration
      # may upgrade this to a structured `{:error, [%{field: :unknown, ...}]}` return once
      # the LiveView surface lands and can render the validation error.
      Logger.warning(
        "Lockspire.Admin.ServerPolicy.put_dcr_policy/1 dropped unknown keys: " <>
          inspect(Enum.reverse(unknown_keys))
      )
    end

    case Map.fetch(atomized, :registration_policy) do
      {:ok, value} ->
        case normalize_registration_policy(value) do
          {:ok, normalized} -> {:ok, Map.put(atomized, :registration_policy, normalized)}
          {:error, _} = err -> err
        end

      :error ->
        {:ok, atomized}
    end
  end

  defp atomize_dcr_key(key) when is_binary(key) do
    Enum.find(@dcr_field_keys, fn atom -> Atom.to_string(atom) == key end)
  end

  defp normalize_registration_policy(value) when value in @registration_policy_atoms,
    do: {:ok, value}

  defp normalize_registration_policy(value) when value in @registration_policy_strings,
    do: {:ok, String.to_existing_atom(value)}

  defp normalize_registration_policy(value) do
    {:error,
     [%{field: :registration_policy, reason: :invalid_registration_policy, detail: value}]}
  end
end
