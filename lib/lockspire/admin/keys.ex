defmodule Lockspire.Admin.Keys do
  @moduledoc """
  Operator-facing query and command boundary for guided signing-key lifecycle work.
  """

  alias Lockspire.Admin.Keys.EncryptionStatus
  alias Lockspire.Admin.Keys.Reencrypt
  alias Lockspire.Config
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Observability
  alias Lockspire.Redaction
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @type lifecycle_action :: :publish | :activate | :retire

  @type reencrypt_report :: %{
          dry_run: boolean(),
          current_kek_id: String.t(),
          scanned: non_neg_integer(),
          encrypted: non_neg_integer(),
          rewrapped: non_neg_integer(),
          already_current: non_neg_integer(),
          no_private_key: non_neg_integer(),
          conflicted: non_neg_integer(),
          by_source_kek: %{optional(String.t()) => non_neg_integer()},
          failed: [
            %{
              kid: String.t() | nil,
              reason: atom(),
              kek_id: String.t() | nil,
              status: SigningKey.status() | nil
            }
          ],
          changes: [%{kid: String.t(), action: :encrypted | :rewrapped, from: String.t()}]
        }

  @type encryption_status :: %{
          configured: boolean(),
          current_kek_id: String.t() | nil,
          configured_kek_ids: [String.t()],
          legacy_plaintext: :allow | :reject,
          total: non_neg_integer(),
          no_private_key: non_neg_integer(),
          legacy: non_neg_integer(),
          by_kek_id: %{optional(String.t()) => non_neg_integer()},
          unknown_kek: %{optional(String.t()) => non_neg_integer()},
          undecryptable: non_neg_integer(),
          stranded_retired: %{count: non_neg_integer(), kids: [String.t()]},
          pending: [
            %{
              kid: String.t(),
              state: :legacy | :unsealable_legacy | :other_kek | :unknown_kek | :undecryptable
            }
          ],
          ready?: boolean()
        }

  @private_jwk_members MapSet.new(~w(d p q dp dq qi oth k))

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

  @spec generate_key(SigningKey.use_type()) ::
          {:ok, key_view()} | {:error, :key_encryption_not_configured | term()}
  def generate_key(use \\ :sig) do
    case Config.key_encryption_keyset() do
      nil -> {:error, :key_encryption_not_configured}
      keyset -> generate_sealed_key(use, keyset)
    end
  end

  defp generate_sealed_key(use, keyset) do
    with {:ok, server_policy} <- Repository.get_server_policy() do
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

      with {:ok, sealed} <- KeyEncryption.seal(keyset, kid, Jason.encode!(private_jwk_map)),
           {:ok, published_key} <-
             transact_with_audit(
               fn ->
                 Repository.publish_key(%SigningKey{
                   kid: kid,
                   kty: kty,
                   alg: alg,
                   use: use,
                   public_jwk: public_jwk_map,
                   private_jwk_encrypted: sealed,
                   status: :upcoming,
                   inserted_at: DateTime.utc_now(),
                   updated_at: DateTime.utc_now()
                 })
               end,
               fn %SigningKey{} = k ->
                 key_audit_event(:key_generated, k, actor_from_attrs(%{}), %{use: use})
               end
             ) do
        emit(:key, :generated, published_key, actor_from_attrs(%{}))
        {:ok, to_view(published_key)}
      end
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

  @doc """
  Converts stored signing-key material to the current key-encryption key.

  Legacy JSON or term-encoded rows are sealed into the encrypted envelope, and rows sealed
  under another configured key are re-wrapped under the current one. Rows already on the
  current key are opened to prove they decrypt and are left untouched. Every status and both
  key uses are covered, and no lifecycle column changes.

  Each row is converted in its own transaction, so a row that cannot be converted is listed
  under `failed` in the report while the other rows stay committed. Running it again is safe:
  rows already on the current key are counted as `already_current`.

  Options: `:dry_run` (default `false`) classifies every row and writes nothing, and `:actor`
  (a map with `:type`, `:id` and `:display`) is recorded on each audit entry. No other option
  is supported; `:page_size` and `:after_lock` are internal test seams and may change.

  The repo must already be started. On a running release node, call this through
  `bin/app rpc` instead of a separate process.
  """
  @spec reencrypt(keyword()) ::
          {:ok, reencrypt_report()}
          | {:error,
             :key_encryption_not_configured
             | :repo_not_started
             | :invalid_option
             | {:invalid_config, String.t()}}
  def reencrypt(opts \\ []) when is_list(opts) do
    with :ok <- validate_reencrypt_opts(opts),
         {:ok, keyset} <- fresh_keyset(),
         :ok <- ensure_repo_started() do
      actor = actor_from_attrs(%{actor: Keyword.get(opts, :actor)})
      {:ok, Reencrypt.run(keyset, actor, opts)}
    end
  end

  @doc """
  Reports how far stored signing keys are from the current key-encryption key.

  Every stored private key is opened with a freshly resolved key set and the plaintext is
  discarded, so a row sealed under the same id with different material counts as `undecryptable`.
  The result never contains stored bytes or key material.

  `ready?` is true when a key-encryption key is configured, no legacy row remains, every row
  sits on the current id, and no unknown or undecryptable row remains. Retired keys that cannot
  be re-encrypted are listed under `stranded_retired` and never block readiness. This function
  reads only: it takes no locks, writes nothing and emits no telemetry.
  """
  @spec encryption_status() ::
          {:ok, encryption_status()}
          | {:error, :repo_not_started | :storage_unavailable | {:invalid_config, String.t()}}
  def encryption_status do
    with {:ok, keyset} <- status_keyset(),
         :ok <- ensure_repo_started(),
         {:ok, rows} <- status_rows() do
      {:ok, EncryptionStatus.build(keyset, rows)}
    end
  end

  # Emits the completed event for a `--check` run. Kept apart from `encryption_status/0` so the
  # status itself stays free of side effects for the doctor and install verification.
  @doc false
  @spec emit_check_completed(encryption_status(), map() | nil, integer()) :: :ok
  def emit_check_completed(status, actor, duration) when is_map(status) do
    actor = actor_from_attrs(%{actor: actor})

    Reencrypt.emit_completed(
      :check,
      %{
        scanned: status.total,
        already_current: Map.get(status.by_kek_id, status.current_kek_id, 0),
        no_private_key: status.no_private_key,
        pending: length(status.pending),
        stranded_retired: status.stranded_retired.count,
        duration: duration
      },
      %{current_kek_id: status.current_kek_id, actor_type: actor[:type], actor_id: actor[:id]}
    )
  end

  defp validate_reencrypt_opts(opts) do
    case Keyword.fetch(opts, :page_size) do
      :error -> :ok
      {:ok, size} when is_integer(size) and size > 0 -> :ok
      {:ok, _invalid} -> {:error, :invalid_option}
    end
  end

  defp status_keyset do
    {:ok, Config.key_encryption!()}
  rescue
    error in ArgumentError -> {:error, {:invalid_config, Exception.message(error)}}
  end

  defp status_rows do
    case Repository.list_signing_keys(sensitive: true) do
      {:ok, rows} -> {:ok, rows}
      {:error, _exception} -> {:error, :storage_unavailable}
    end
  end

  defp fresh_keyset do
    case Config.key_encryption!() do
      nil -> {:error, :key_encryption_not_configured}
      keyset -> {:ok, keyset}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_config, Exception.message(error)}}
  end

  defp ensure_repo_started do
    if Process.whereis(Config.repo!()), do: :ok, else: {:error, :repo_not_started}
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
      publishable: publishable?(key),
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
      publishable: publishable?(key),
      next_actions: next_actions(key)
    }
  end

  defp publishable?(%SigningKey{status: status}) when status in [:active, :retiring], do: true

  defp publishable?(%SigningKey{status: :upcoming, published_at: published_at}),
    do: not is_nil(published_at)

  defp publishable?(%SigningKey{}), do: false

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
    %SigningKey{
      key
      | private_jwk_encrypted: nil,
        public_jwk: public_jwk_members(key.public_jwk)
    }
  end

  defp public_jwk_members(public_jwk) when is_map(public_jwk) do
    Map.reject(public_jwk, fn {member, _value} ->
      (is_binary(member) or is_atom(member)) and
        MapSet.member?(@private_jwk_members, to_string(member))
    end)
  end

  defp public_jwk_members(_public_jwk), do: %{}

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
