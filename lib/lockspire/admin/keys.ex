defmodule Lockspire.Admin.Keys do
  @moduledoc """
  Operator-facing query and command boundary for guided signing-key lifecycle work.
  """

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Observability
  alias Lockspire.Redaction
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @type lifecycle_action :: :publish | :activate | :retire

  @type key_view :: %{
          key: SigningKey.t() | map(),
          published: boolean(),
          publishable: boolean(),
          next_actions: [lifecycle_action()]
        }

  @spec list_keys(keyword()) :: {:ok, [key_view()]} | {:error, term()}
  def list_keys(opts \\ []) when is_list(opts) do
    with {:ok, keys} <- Repository.list_signing_keys(opts) do
      {:ok, keys |> Enum.map(&to_view/1) |> Enum.sort_by(&sort_key/1)}
    end
  end

  @spec get_key(integer()) :: {:ok, key_view() | nil} | {:error, term()}
  def get_key(key_id) when is_integer(key_id) do
    with {:ok, key} <- Repository.fetch_signing_key_by_id(key_id) do
      {:ok, maybe_detail_view(key)}
    end
  end

  @spec generate_key(SigningKey.use_type()) :: {:ok, key_view()} | {:error, term()}
  def generate_key(use \\ :sig) do
    {:ok, server_policy} = Repository.get_server_policy()

    {jwk, kty, alg} =
      signing_key_defaults(server_policy.security_profile, use)

    {_, public_jwk_map} = JOSE.JWK.to_map(JOSE.JWK.to_public(jwk))
    {_, private_jwk_map} = JOSE.JWK.to_map(jwk)

    kid = Base.encode16(:crypto.strong_rand_bytes(8))

    public_jwk_map =
      public_jwk_map
      |> Map.put("use", Atom.to_string(use))
      |> Map.put("kid", kid)
      |> Map.put("alg", alg)

    private_jwk_map = Map.put(private_jwk_map, "kid", kid)

    key = %SigningKey{
      kid: kid,
      kty: kty,
      alg: alg,
      use: use,
      public_jwk: public_jwk_map,
      private_jwk_encrypted: Jason.encode!(private_jwk_map),
      status: :upcoming,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    with {:ok, published_key} <-
           transact_with_audit(
             fn -> Repository.publish_key(key) end,
             fn %SigningKey{} = k ->
               key_audit_event(:key_generated, k, actor_from_attrs(%{}), %{use: use})
             end
           ) do
      emit(:key, :generated, published_key, actor_from_attrs(%{}))
      {:ok, to_view(published_key)}
    end
  end

  @spec publish_key(integer(), map() | keyword()) :: {:ok, key_view()} | {:error, term()}
  def publish_key(key_id, attrs \\ %{})

  def publish_key(key_id, attrs) when is_list(attrs) do
    publish_key(key_id, Enum.into(attrs, %{}))
  end

  def publish_key(key_id, attrs) when is_integer(key_id) and is_map(attrs) do
    published_at = Map.get(attrs, :published_at, DateTime.utc_now())
    actor = actor_from_attrs(attrs)

    with {:ok, %SigningKey{} = key} <-
           transact_with_audit(
             fn -> Repository.publish_signing_key(key_id, published_at) end,
             fn %SigningKey{} = published_key ->
               key_audit_event(:key_published, published_key, actor, %{published_at: published_at})
             end
           ) do
      emit(:key, :published, key, actor)
      {:ok, to_detail_view(key)}
    end
  end

  @spec activate_key(integer(), map() | keyword()) :: {:ok, key_view()} | {:error, term()}
  def activate_key(key_id, attrs \\ %{})

  def activate_key(key_id, attrs) when is_list(attrs) do
    activate_key(key_id, Enum.into(attrs, %{}))
  end

  def activate_key(key_id, attrs) when is_integer(key_id) and is_map(attrs) do
    activated_at = Map.get(attrs, :activated_at, DateTime.utc_now())
    actor = actor_from_attrs(attrs)

    with {:ok, server_policy} <- Repository.get_server_policy(),
         {:ok, %SigningKey{} = key_to_activate} <- Repository.fetch_signing_key_by_id(key_id),
         :ok <- validate_activation_compliance(key_to_activate, server_policy.security_profile),
         {:ok, %{activated_key: key}} <-
           transact_with_audit(
             fn -> Repository.activate_signing_key(key_id, activated_at) end,
             fn %{activated_key: %SigningKey{} = activated_key, retiring_key: retiring_key} ->
               key_audit_event(:key_activated, activated_key, actor, %{
                 activated_at: activated_at,
                 retired_key_id: retiring_key && retiring_key.id
               })
             end
           ) do
      emit(:key, :activated, key, actor)
      {:ok, to_detail_view(key)}
    end
  end

  @spec retire_key(integer(), map() | keyword()) :: {:ok, key_view()} | {:error, term()}
  def retire_key(key_id, attrs \\ %{})

  def retire_key(key_id, attrs) when is_list(attrs) do
    retire_key(key_id, Enum.into(attrs, %{}))
  end

  def retire_key(key_id, attrs) when is_integer(key_id) and is_map(attrs) do
    retired_at = Map.get(attrs, :retired_at, DateTime.utc_now())
    actor = actor_from_attrs(attrs)

    with {:ok, %SigningKey{} = key} <-
           transact_with_audit(
             fn -> Repository.retire_signing_key(key_id, retired_at) end,
             fn %SigningKey{} = retired_key ->
               key_audit_event(:key_retired, retired_key, actor, %{retired_at: retired_at})
             end
           ) do
      emit(:key, :retired, key, actor)
      {:ok, to_detail_view(key)}
    end
  end

  defp maybe_detail_view(nil), do: nil
  defp maybe_detail_view(%SigningKey{} = key), do: to_detail_view(key)

  defp signing_key_defaults(:fapi_2_0_security, :sig),
    do: {JOSE.JWK.generate_key({:ec, "P-256"}), :EC, "ES256"}

  defp signing_key_defaults(_profile, :enc),
    do: {JOSE.JWK.generate_key({:rsa, 2048}), :RSA, "RS256"}

  defp signing_key_defaults(_profile, _use),
    do: {JOSE.JWK.generate_key({:ec, "P-256"}), :EC, "ES256"}

  defp validate_activation_compliance(%SigningKey{} = key, security_profile) do
    case Policy.validate_key_compliance(key, security_profile) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error,
         {:non_compliant_signing_key, reason,
          "Generate and publish an ES256 or PS256 signing key before activating FAPI mode."}}
    end
  end

  defp to_view(%SigningKey{} = key) do
    %{
      key: strip_private_key_material(key),
      published: not is_nil(key.published_at),
      publishable: key.status in [:active, :retiring] or not is_nil(key.published_at),
      next_actions: next_actions(key)
    }
  end

  defp to_detail_view(%SigningKey{} = key) do
    public_jwk = key.public_jwk || %{}

    %{
      key: %{
        handle: key_handle(key),
        database_handle: database_handle(key),
        status: key.status,
        alg: key.alg,
        kty: key.kty,
        use: key.use,
        published_at: key.published_at,
        activated_at: key.activated_at,
        retiring_at: key.retiring_at,
        retired_at: key.retired_at,
        public_jwk: %{
          "kid" => key_handle(key),
          "alg" => Map.get(public_jwk, "alg") || key.alg,
          "kty" => Map.get(public_jwk, "kty") || key.kty,
          "use" => Map.get(public_jwk, "use") || key.use
        }
      },
      published: not is_nil(key.published_at),
      publishable: key.status in [:active, :retiring] or not is_nil(key.published_at),
      next_actions: next_actions(key)
    }
  end

  defp next_actions(%SigningKey{status: :upcoming, published_at: nil}), do: [:publish]
  defp next_actions(%SigningKey{status: :upcoming}), do: [:activate]
  defp next_actions(%SigningKey{status: :retiring}), do: [:retire]
  defp next_actions(%SigningKey{}), do: []

  defp sort_key(%{key: %SigningKey{status: status, inserted_at: inserted_at}}) do
    {status_order(status), descending_unix(inserted_at)}
  end

  defp status_order(:active), do: 0
  defp status_order(:upcoming), do: 1
  defp status_order(:retiring), do: 2
  defp status_order(:retired), do: 3
  defp status_order(_other), do: 4

  defp descending_unix(%DateTime{} = value), do: -DateTime.to_unix(value, :microsecond)
  defp descending_unix(_value), do: 0

  defp strip_private_key_material(%SigningKey{} = key) do
    %SigningKey{key | private_jwk_encrypted: nil}
  end

  defp key_handle(%SigningKey{} = key), do: Redaction.handle(:kid, key.kid)

  defp database_handle(%SigningKey{id: id}) when is_integer(id), do: Redaction.handle(:key, id)
  defp database_handle(%SigningKey{} = key), do: key_handle(key)

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

  defp append_audit_event(build_audit_event, result) do
    case Repository.append_audit_event(build_audit_event.(result)) do
      {:ok, _event} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp emit(entity, action, %SigningKey{} = key, actor) do
    Observability.emit(entity, action, %{}, %{
      actor_type: actor[:type],
      actor_id: actor[:id],
      key_id: key.id,
      kid: key.kid,
      status: key.status
    })
  end

  defp key_audit_event(action, %SigningKey{} = key, actor, metadata) do
    %{
      action: action,
      outcome: :succeeded,
      reason_code: action,
      actor: actor,
      resource: %{type: :signing_key, id: key.id || key.kid},
      metadata: Map.merge(%{key_id: key.id, kid: key.kid, status: key.status}, metadata)
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
