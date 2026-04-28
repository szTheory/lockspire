defmodule Lockspire.Protocol.DeviceVerification do
  @moduledoc """
  Narrow lookup and approval seam for host-owned device verification UX.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Storage.Ecto.Repository

  defmodule PendingAuthorization do
    @moduledoc "Pending device authorization context exposed to the host verification seam."

    @enforce_keys [:verification_handle, :user_code, :client_id, :client_name, :scopes]
    defstruct [:verification_handle, :user_code, :client_id, :client_name, :scopes]

    @type t :: %__MODULE__{
            verification_handle: String.t(),
            user_code: String.t(),
            client_id: String.t(),
            client_name: String.t(),
            scopes: [String.t()]
          }
  end

  @type lookup_result :: {:ok, PendingAuthorization.t()} | {:error, :not_found | :expired | :not_active | term()}
  @type transition_result :: {:ok, DeviceAuthorization.t()} | {:error, :invalid_actor_context | term()}

  @spec lookup_pending_device_authorization(String.t(), keyword()) :: lookup_result()
  def lookup_pending_device_authorization(user_code, opts \\ [])
      when is_binary(user_code) and is_list(opts) do
    normalized_user_code = DeviceAuthorization.canonicalize_user_code(user_code)
    user_code_hash = DeviceAuthorization.hash_user_code(normalized_user_code)

    with {:ok, authorization} <- device_authorization_store(opts).fetch_device_authorization_by_user_code_hash(user_code_hash) do
      classify_lookup_result(authorization, normalized_user_code, opts)
    end
  end

  @spec approve_device_authorization(String.t(), map(), keyword()) :: transition_result()
  def approve_device_authorization(verification_handle, actor_context, opts \\ [])
      when is_binary(verification_handle) and is_map(actor_context) and is_list(opts) do
    with {:ok, subject_id} <- actor_subject_id(actor_context) do
      device_authorization_store(opts).transition_device_authorization(
        verification_handle,
        [:pending],
        %{
          status: :approved,
          subject_id: subject_id,
          approved_at: now(opts)
        }
      )
    end
  end

  @spec deny_device_authorization(String.t(), map(), keyword()) :: transition_result()
  def deny_device_authorization(verification_handle, actor_context, opts \\ [])
      when is_binary(verification_handle) and is_map(actor_context) and is_list(opts) do
    with {:ok, _subject_id} <- actor_subject_id(actor_context) do
      device_authorization_store(opts).transition_device_authorization(
        verification_handle,
        [:pending],
        %{
          status: :denied,
          denied_at: now(opts)
        }
      )
    end
  end

  defp classify_lookup_result(nil, _normalized_user_code, _opts), do: {:error, :not_found}

  defp classify_lookup_result(%DeviceAuthorization{} = authorization, _normalized_user_code, opts) do
    cond do
      authorization.status != :pending ->
        {:error, :not_active}

      expired?(authorization, opts) ->
        {:error, :expired}

      true ->
        build_pending_authorization(authorization, opts)
    end
  end

  defp build_pending_authorization(%DeviceAuthorization{} = authorization, opts) do
    with {:ok, client_name} <- client_name(authorization.client_id, opts) do
      {:ok,
       %PendingAuthorization{
         verification_handle: authorization.verification_handle,
         user_code: user_code_for_display(authorization),
         client_id: authorization.client_id,
         client_name: client_name,
         scopes: List.wrap(authorization.scopes)
       }}
    end
  end

  defp client_name(client_id, opts) do
    case client_store(opts).fetch_client_by_id(client_id) do
      {:ok, %Client{name: name}} when is_binary(name) and name != "" -> {:ok, name}
      {:ok, %Client{client_id: client_id}} -> {:ok, client_id}
      {:ok, nil} -> {:ok, client_id}
      {:error, reason} -> {:error, reason}
    end
  end

  defp actor_subject_id(%{subject_id: subject_id}) when is_binary(subject_id) and subject_id != "",
    do: {:ok, subject_id}

  defp actor_subject_id(_actor_context), do: {:error, :invalid_actor_context}

  defp user_code_for_display(%DeviceAuthorization{user_code: user_code})
       when is_binary(user_code) and user_code != "" do
    DeviceAuthorization.canonicalize_user_code(user_code)
  end

  defp user_code_for_display(%DeviceAuthorization{user_code_hash: _hash} = authorization) do
    authorization
    |> Map.get(:user_code)
    |> to_string()
    |> DeviceAuthorization.canonicalize_user_code()
  end

  defp expired?(%DeviceAuthorization{expires_at: expires_at}, opts) do
    DateTime.compare(expires_at, now(opts)) != :gt
  end

  defp device_authorization_store(opts),
    do: Keyword.get(opts, :device_authorization_store, Repository)

  defp client_store(opts),
    do: Keyword.get(opts, :client_store, Repository)

  defp now(opts),
    do: Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
end
