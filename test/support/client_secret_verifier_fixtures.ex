defmodule Lockspire.TestSupport.ClientSecretVerifierFixtures do
  @moduledoc false

  alias Lockspire.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @salt "lockspire client_secret_jwt verifier"
  @default_max_age 86_400

  def legacy_verifier(secret, opts \\ []) when is_binary(secret) do
    signed_at = Keyword.get(opts, :signed_at, System.os_time(:second))
    max_age = Keyword.get(opts, :max_age, @default_max_age)

    case Keyword.get(opts, :legacy_shape, :tuple3) do
      :tuple3 ->
        Plug.Crypto.encrypt(secret_key_base(), @salt, secret,
          signed_at: signed_at,
          max_age: max_age
        )

      :tuple2 ->
        encrypt_raw_term({secret, signed_at * 1000})

      :map ->
        encrypt_raw_term(%{data: secret, signed: signed_at * 1000})
    end
  end

  def persisted_client(opts \\ []) do
    {hash, secret} = Clients.rotate_secret_hash()
    signed_at = Keyword.get(opts, :signed_at, System.os_time(:second))
    max_age = Keyword.get(opts, :max_age, @default_max_age)

    generated_verifier =
      legacy_verifier(secret,
        signed_at: signed_at,
        max_age: max_age,
        legacy_shape: Keyword.get(opts, :legacy_shape, :tuple3)
      )

    verifier = Keyword.get(opts, :verifier, generated_verifier)

    client = %Client{
      client_id: unique_id(),
      client_secret_hash: Keyword.get(opts, :hash, hash),
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: "Phase 175 legacy verifier qualification",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: Keyword.get(opts, :active, true),
      provenance: :operator,
      lifetime_version: Keyword.get(opts, :lifetime_version, 0),
      client_expires_at: Keyword.get(opts, :client_expires_at),
      client_secret_expires_at: Keyword.get(opts, :client_secret_expires_at)
    }

    {:ok, persisted} = Repository.register_client(client)
    {:ok, stored} = Repository.fetch_client_by_id(persisted.client_id)
    %{client: stored, plaintext_secret: secret, verifier: verifier}
  end

  def assertion(%Client{} = client, secret, opts \\ []) do
    now = Keyword.get(opts, :issued_at, DateTime.utc_now() |> DateTime.truncate(:second))
    jti = unique_id()

    claims = %{
      "iss" => client.client_id,
      "sub" => client.client_id,
      "aud" => Lockspire.Config.issuer!(),
      "jti" => jti,
      "iat" => DateTime.to_unix(now),
      "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
    }

    jwt =
      JOSE.JWK.from_oct(secret)
      |> JOSE.JWT.sign(%{"alg" => "HS256"}, claims)
      |> JOSE.JWS.compact()
      |> elem(1)

    {jwt_params(jwt), jti, now}
  end

  def authenticate(%Client{} = client, secret, opts \\ []) do
    {params, jti, issued_at} = assertion(client, secret, opts)

    result =
      ClientAuth.authenticate(params, nil,
        client_store: Repository,
        jti_store: Repository,
        server_policy_store: Repository,
        supported_jwt_auth_methods: [:client_secret_jwt],
        now: Keyword.get(opts, :now, fn -> DateTime.utc_now() end)
      )

    {result, jti, issued_at}
  end

  def encrypt_payload(payload) when is_binary(payload) do
    key = Plug.Crypto.KeyGenerator.generate(secret_key_base(), @salt)
    Plug.Crypto.MessageEncryptor.encrypt(payload, key, "")
  end

  def encrypt_raw_term(term) do
    term
    |> :erlang.term_to_binary()
    |> encrypt_payload()
  end

  def authenticated_metadata(encrypted) when is_binary(encrypted) do
    key = Plug.Crypto.KeyGenerator.generate(secret_key_base(), @salt)

    with {:ok, payload} <- Plug.Crypto.MessageEncryptor.decrypt(encrypted, key, ""),
         term when not is_nil(term) <- safe_decode(payload),
         {:ok, metadata} <- normalize_metadata(term) do
      {:ok, metadata}
    else
      _ -> {:error, :unsupported_or_invalid_legacy_verifier}
    end
  rescue
    _ -> {:error, :unsupported_or_invalid_legacy_verifier}
  end

  def metadata_deadline(%{signed_at_ms: signed_at_ms, max_age_seconds: :infinity})
      when is_integer(signed_at_ms),
      do: :infinity

  def metadata_deadline(%{signed_at_ms: signed_at_ms, max_age_seconds: max_age})
      when is_integer(signed_at_ms) and is_number(max_age) and max_age > 0 do
    signed_at_ms + trunc(max_age * 1000)
  end

  def metadata_deadline(_), do: {:error, :unsupported_age}

  def migration_readiness(
        %{data: data, signed_at_ms: signed_at_ms} = metadata,
        now_ms
      )
      when is_binary(data) and byte_size(data) > 0 and is_integer(signed_at_ms) and
             is_integer(now_ms) do
    if signed_at_ms > now_ms,
      do: {:error, :future_timestamp},
      else: readiness_at_deadline(metadata, now_ms)
  end

  def migration_readiness(_metadata, _now_ms), do: {:error, :unsupported_age}

  defp readiness_at_deadline(metadata, now_ms) do
    case metadata_deadline(metadata) do
      deadline when is_integer(deadline) ->
        if deadline >= now_ms, do: :ready, else: {:error, :expired}

      _unsupported ->
        {:error, :unsupported_age}
    end
  end

  def expired_at?(metadata, now_ms) when is_integer(now_ms) do
    case metadata_deadline(metadata) do
      :infinity -> false
      deadline when is_integer(deadline) -> deadline < now_ms
      _ -> {:error, :unsupported_age}
    end
  end

  def jti_count(client_id) do
    import Ecto.Query

    Lockspire.TestRepo.aggregate(
      from(jti in Lockspire.Storage.Ecto.UsedJtiRecord, where: jti.client_id == ^client_id),
      :count
    )
  end

  def effects_snapshot(client_id) do
    import Ecto.Query

    %{
      used_jtis: jti_count(client_id),
      tokens:
        Lockspire.TestRepo.aggregate(
          from(token in Lockspire.Storage.Ecto.TokenRecord,
            where: token.client_id == ^client_id
          ),
          :count
        ),
      grants:
        Lockspire.TestRepo.aggregate(
          from(grant in Lockspire.Storage.Ecto.ConsentGrantRecord,
            where: grant.client_id == ^client_id
          ),
          :count
        ),
      audits:
        Lockspire.TestRepo.aggregate(
          from(event in Lockspire.Storage.Ecto.AuditEventRecord,
            where: event.resource_id == ^client_id
          ),
          :count
        )
    }
  end

  def secret_hash_matches?(hash, secret), do: Policy.verify_client_secret(hash, secret)

  defp normalize_metadata({data, signed_at_ms, max_age})
       when is_binary(data) and is_integer(signed_at_ms) and
              (is_number(max_age) or max_age == :infinity) do
    {:ok, %{data: data, signed_at_ms: signed_at_ms, max_age_seconds: max_age, shape: :tuple3}}
  end

  defp normalize_metadata({data, signed_at_ms})
       when is_binary(data) and is_integer(signed_at_ms) do
    {:ok,
     %{data: data, signed_at_ms: signed_at_ms, max_age_seconds: @default_max_age, shape: :tuple2}}
  end

  defp normalize_metadata(%{data: data, signed: signed_at_ms})
       when is_binary(data) and is_integer(signed_at_ms) do
    {:ok,
     %{data: data, signed_at_ms: signed_at_ms, max_age_seconds: @default_max_age, shape: :map}}
  end

  defp normalize_metadata(_), do: {:error, :unsupported_shape}

  defp safe_decode(payload) do
    Plug.Crypto.non_executable_binary_to_term(payload, [:safe])
  rescue
    ArgumentError -> nil
  end

  defp secret_key_base do
    Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)[:secret_key_base]
  end

  defp unique_id do
    "phase175-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
  end

  defp jwt_params(assertion) do
    %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }
  end
end
