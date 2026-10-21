defmodule Lockspire.Protocol.DcrTelemetryRedactionTest do
  use ExUnit.Case, async: false
  import Ecto.Query
  import ExUnit.CaptureLog

  alias Lockspire.Protocol.InitialAccessToken
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Admin.Clients
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures
  alias Lockspire.TestSupport.TelemetryCapture
  import Lockspire.TokenExchangeCase, only: [basic_auth: 2, publish_signing_key: 1]

  # The 18 event paths the sweep attaches to.
  # 7 DCR family events × 2 paths (telemetry + audit-mirror) = 14
  # 2 IAT family events × 2 paths = 4 → total 18.
  @attached_events [
    # DCR
    [:lockspire, :dcr, :register],
    [:lockspire, :audit, :dcr, :register],
    [:lockspire, :dcr, :read],
    [:lockspire, :audit, :dcr, :read],
    [:lockspire, :dcr, :update],
    [:lockspire, :audit, :dcr, :update],
    [:lockspire, :dcr, :delete],
    [:lockspire, :audit, :dcr, :delete],
    [:lockspire, :dcr, :unauthorized],
    [:lockspire, :audit, :dcr, :unauthorized],
    [:lockspire, :dcr, :rotate],
    [:lockspire, :audit, :dcr, :rotate],
    # IAT
    [:lockspire, :iat, :use],
    [:lockspire, :audit, :iat, :use]
  ]

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, _policy} = Repository.put_server_policy(DcrFixtures.server_policy(%{}))
    end)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    TelemetryCapture.attach_many(@attached_events, self())
    %{}
  end

  describe "DCR telemetry redaction sweep (DCR-23)" do
    test "RAT/IAT/client_secret plaintext is absent from every captured event payload, every audit row payload, and every audit row metadata column" do
      # ── 1. Exercise: register success ──────────────────────────────────────
      {iat_plaintext, _iat_record} = InitialAccessTokenFixtures.persist_with_plaintext(%{})
      {:ok, success} = Registration.register(DcrFixtures.register_request(iat: iat_plaintext))

      # Capture the three plaintext values that MUST NOT appear anywhere ↓
      plaintext_secret = success.client_secret_plaintext
      plaintext_rat = success.registration_access_token_plaintext
      plaintext_iat = iat_plaintext

      assert is_binary(plaintext_secret) and byte_size(plaintext_secret) > 0
      assert is_binary(plaintext_rat) and byte_size(plaintext_rat) > 0
      assert is_binary(plaintext_iat) and byte_size(plaintext_iat) > 0

      # ── 2. Exercise: register failure (D-14 jwks_uri axis) ─────────────────
      {:error, _} =
        Registration.register(
          DcrFixtures.register_request(metadata: DcrFixtures.invalid_redirect_uri_metadata())
        )

      # ── 3. Exercise: IAT redemption failure (already used) ──────────────────
      {:error, :invalid_token} = InitialAccessToken.redeem(iat_plaintext)

      # ── 4. Exercise: management read / update / delete + RAT rotation ──────
      server_policy = DcrFixtures.server_policy(%{})
      {:ok, _} = RegistrationManagement.read(success.client.client_id, success.client)

      # D-19 LOCKED: update/2 with bundled-request map. Do NOT call update/4.
      {:ok, update_success} =
        RegistrationManagement.update(success.client.client_id, %{
          metadata: Map.put(DcrFixtures.valid_metadata(), "client_id", success.client.client_id),
          server_policy: server_policy,
          client: success.client
        })

      new_plaintext_rat = update_success.registration_access_token_plaintext
      assert is_binary(new_plaintext_rat) and byte_size(new_plaintext_rat) > 0

      # Mismatch path
      {:error, :invalid_token} =
        RegistrationManagement.read("wrong_client_id", update_success.client)

      :ok = RegistrationManagement.delete(update_success.client.client_id, update_success.client)

      # ── 5. Drain telemetry ─────────────────────────────────────────────────
      captured = drain_events()
      observed = Enum.frequencies_by(captured, fn {event, _measurements, _metadata} -> event end)

      for event <- [
            [:lockspire, :dcr, :register],
            [:lockspire, :audit, :dcr, :register],
            [:lockspire, :dcr, :read],
            [:lockspire, :audit, :dcr, :read],
            [:lockspire, :dcr, :update],
            [:lockspire, :audit, :dcr, :update],
            [:lockspire, :dcr, :delete],
            [:lockspire, :audit, :dcr, :delete],
            [:lockspire, :dcr, :unauthorized],
            [:lockspire, :audit, :dcr, :unauthorized]
          ] do
        assert_positive_event_count!(observed, event)
      end

      # ── 6. Single-sweep refute on captured events ──────────────────────────
      plaintexts = [plaintext_secret, plaintext_rat, plaintext_iat, new_plaintext_rat]

      for {event, measurements, metadata} <- captured,
          plaintext <- plaintexts do
        inspected =
          inspect({event, measurements, metadata}, limit: :infinity, printable_limit: :infinity)

        refute String.contains?(inspected, plaintext),
               "telemetry event #{inspect(event)} carried plaintext: " <>
                 "<<plaintext redacted in error msg; first 8 chars #{binary_part(plaintext, 0, min(8, byte_size(plaintext)))}>>; " <>
                 "captured: #{inspected}"
      end

      # ── 7. Single-sweep refute on persisted audit rows ─────────────────────
      rows =
        Lockspire.TestRepo.all(
          from(audit in AuditEventRecord,
            where: like(audit.action, "dcr_%") or like(audit.action, "iat_%"),
            order_by: [desc: audit.id]
          )
        )

      for row <- rows, plaintext <- plaintexts do
        payload_str = inspect(row, limit: :infinity, printable_limit: :infinity)
        metadata_str = inspect(row.metadata, limit: :infinity, printable_limit: :infinity)

        refute String.contains?(payload_str, plaintext),
               "audit row id=#{row.id} action=#{row.action} payload carried plaintext"

        refute String.contains?(metadata_str, plaintext),
               "audit row id=#{row.id} action=#{row.action} metadata carried plaintext"
      end
    end
  end

  test "self PUT and host recovery use distinct management actors" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    policy =
      DcrFixtures.server_policy(%{
        dcr_default_registration_access_token_lifetime_seconds: 60
      })

    assert {:ok, _} = Repository.put_server_policy(policy)

    TelemetryCapture.attach_many(
      [[:lockspire, :dcr, :rotate], [:lockspire, :audit, :dcr, :rotate]],
      self()
    )

    assert {:ok, registered} =
             Registration.register(
               DcrFixtures.register_request(server_policy: policy)
               |> Map.put(:now, now)
             )

    client = registered.client

    assert {:ok, updated} =
             RegistrationManagement.update(client.client_id, %{
               metadata: Map.put(DcrFixtures.valid_metadata(), "client_id", client.client_id),
               server_policy: policy,
               client: client,
               now: DateTime.add(now, 1, :second)
             })

    assert {:ok, _recovered_plaintext, recovered} =
             RegistrationManagement.rotate_registration_access_token(
               updated.client,
               now: DateTime.add(now, 2, :second)
             )

    captured = drain_events()

    self_rotations =
      Enum.filter(captured, fn
        {[:lockspire, :dcr, :rotate], _measurements,
         %{actor_type: :self_registered_client, actor_id: id}} ->
          id == client.client_id

        _ ->
          false
      end)

    host_rotations =
      Enum.filter(captured, fn
        {[:lockspire, :dcr, :rotate], _measurements,
         %{actor_type: :operator, actor_id: "admin-ui"}} ->
          true

        _ ->
          false
      end)

    assert length(self_rotations) >= 1
    assert length(host_rotations) >= 1

    audit_rows =
      Lockspire.TestRepo.all(
        from(audit in AuditEventRecord,
          where:
            audit.resource_id == ^client.client_id and
              audit.action in ["dcr_management_updated", "dcr_management_rat_rotated"],
          order_by: [asc: audit.id]
        )
      )

    assert Enum.any?(
             audit_rows,
             &(&1.action == "dcr_management_updated" and &1.actor_type == "self_registered_client")
           )

    assert Enum.any?(
             audit_rows,
             &(&1.action == "dcr_management_rat_rotated" and &1.actor_type == "operator" and
                 &1.actor_id == "admin-ui")
           )

    assert recovered.client_id == client.client_id
  end

  test "failed host recovery audit emits no successful rotation event" do
    policy = DcrFixtures.server_policy(%{})
    assert {:ok, _} = Repository.put_server_policy(policy)

    assert {:ok, registered} =
             Registration.register(DcrFixtures.register_request(server_policy: policy))

    client = registered.client
    events = [[:lockspire, :dcr, :rotate], [:lockspire, :audit, :dcr, :rotate]]
    TelemetryCapture.attach_many(events, self())
    _ = drain_events()

    Lockspire.TestRepo.query!("""
    CREATE OR REPLACE FUNCTION lockspire_plan165_reject_management_audit() RETURNS trigger AS $$
    BEGIN
      IF NEW.action = 'dcr_management_rat_rotated' THEN
        RAISE EXCEPTION '165-06 forced management audit failure';
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """)

    Lockspire.TestRepo.query!("""
    CREATE TRIGGER lockspire_plan165_management_audit_failure
    BEFORE INSERT ON lockspire_audit_events
    FOR EACH ROW EXECUTE FUNCTION lockspire_plan165_reject_management_audit()
    """)

    try do
      assert {:error, _reason} = RegistrationManagement.rotate_registration_access_token(client)

      captured = drain_events()

      refute Enum.any?(captured, fn {event, _measurements, _metadata} -> event in events end)

      refute Lockspire.TestRepo.exists?(
               from(audit in AuditEventRecord,
                 where:
                   audit.resource_id == ^client.client_id and
                     audit.action == "dcr_management_rat_rotated"
               )
             )
    after
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lockspire_plan165_management_audit_failure ON lockspire_audit_events"
      )

      Lockspire.TestRepo.query!(
        "DROP FUNCTION IF EXISTS lockspire_plan165_reject_management_audit()"
      )
    end
  end

  test "finite secret issuance, token use, expiry rejection, and operator replacement are observed and redacted" do
    issued_at = DateTime.utc_now() |> DateTime.truncate(:second)
    deadline = DateTime.add(issued_at, 60, :second)

    events = [
      [:lockspire, :dcr, :register],
      [:lockspire, :audit, :dcr, :register],
      [:lockspire, :authorization_code, :redeemed],
      [:lockspire, :audit, :authorization_code, :redeemed],
      [:lockspire, :token, :issued],
      [:lockspire, :audit, :token, :issued],
      [:lockspire, :token_exchange, :failed],
      [:lockspire, :audit, :token_exchange, :failed],
      [:lockspire, :client, :secret_rotated],
      [:lockspire, :audit, :client, :secret_rotated]
    ]

    TelemetryCapture.attach_many(events, self())

    policy =
      DcrFixtures.server_policy(%{
        dcr_default_client_lifetime_seconds: nil,
        dcr_default_client_secret_lifetime_seconds: 60
      })

    request =
      DcrFixtures.register_request(
        server_policy: policy,
        metadata: %{
          "client_name" => "Finite secret redaction",
          "redirect_uris" => ["https://app.example.test/callback"],
          "token_endpoint_auth_method" => "client_secret_basic"
        }
      )
      |> Map.put(:now, issued_at)

    assert {:ok, success} = Registration.register(request)
    client = success.client
    secret = success.client_secret_plaintext
    hash_before = client.client_secret_hash
    assert DateTime.compare(client.client_secret_expires_at, deadline) == :eq

    code = "redaction-code-#{System.unique_integer([:positive, :monotonic])}"
    verifier = "redaction-verifier-#{System.unique_integer([:positive, :monotonic])}"

    redirect_uri = List.first(client.redirect_uris)

    assert {:ok, _authorization_code} =
             put_authorization_code(client, code, verifier, redirect_uri)

    publish_signing_key("kid-redaction-finite-secret")

    exchange_params = %{
      "grant_type" => "authorization_code",
      "code" => code,
      "code_verifier" => verifier,
      "redirect_uri" => redirect_uri
    }

    assert {:ok, issued} =
             TokenExchange.exchange_authorization_code(%{
               params: exchange_params,
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Lockspire.Storage.Ecto.Repository,
                 token_store: Lockspire.Storage.Ecto.Repository,
                 transaction_store: Lockspire.Storage.Ecto.Repository,
                 audit_store: Lockspire.Storage.Ecto.Repository,
                 interaction_store: Lockspire.Storage.Ecto.Repository,
                 key_store: Lockspire.Storage.Ecto.Repository,
                 server_policy_store: Lockspire.Storage.Ecto.Repository,
                 now: fn -> DateTime.add(issued_at, 1, :second) end,
                 access_token_generator: fn -> "redaction-access-token" end,
                 refresh_token_generator: fn -> "redaction-refresh-token" end
               ]
             })

    assert is_binary(issued.access_token)

    expired_code = "redaction-expired-code-#{System.unique_integer([:positive, :monotonic])}"

    assert {:ok, _authorization_code} =
             put_authorization_code(client, expired_code, verifier, redirect_uri)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [client_secret_expires_at: deadline]
             )

    failure_logs =
      capture_log(fn ->
        Process.put(
          :dcr_redaction_expiry_failure,
          TokenExchange.exchange_authorization_code(%{
            params: %{exchange_params | "code" => expired_code},
            authorization: basic_auth(client.client_id, secret),
            opts: [
              client_store: Lockspire.Storage.Ecto.Repository,
              token_store: Lockspire.Storage.Ecto.Repository,
              transaction_store: Lockspire.Storage.Ecto.Repository,
              audit_store: Lockspire.Storage.Ecto.Repository,
              interaction_store: Lockspire.Storage.Ecto.Repository,
              key_store: Lockspire.Storage.Ecto.Repository,
              server_policy_store: Lockspire.Storage.Ecto.Repository,
              now: fn -> deadline end
            ]
          })
        )
      end)

    failure = Process.delete(:dcr_redaction_expiry_failure)

    assert {:error, %{reason_code: :client_secret_expired} = public_error} = failure

    assert {:ok, %{client: rotated, client_secret: replacement}} =
             Clients.rotate_client_secret(client.client_id, %{
               actor: %{type: :operator, id: "ops"}
             })

    assert is_binary(replacement) and replacement != secret
    hash_after = rotated.client_secret_hash

    jwt_policy =
      DcrFixtures.client_secret_jwt_server_policy(%{
        dcr_default_client_secret_lifetime_seconds: 60,
        dcr_default_registration_access_token_lifetime_seconds: 60
      })

    assert {:ok, _} = Repository.put_server_policy(jwt_policy)

    jwt_request =
      DcrFixtures.register_request(
        server_policy: jwt_policy,
        metadata:
          DcrFixtures.client_secret_jwt_metadata()
          |> Map.put("client_name", "Finite JWT secret redaction")
      )
      |> Map.put(:now, issued_at)

    assert {:ok, jwt_success} = Registration.register(jwt_request)
    jwt_client = jwt_success.client
    jwt_secret_before = jwt_success.client_secret_plaintext

    assert {:ok, persisted_jwt_before} =
             Lockspire.Storage.Ecto.Repository.fetch_client_by_id(jwt_client.client_id)

    jwt_verifier_before = persisted_jwt_before.client_secret_jwt_verifier_encrypted
    assert is_binary(jwt_verifier_before)

    assert {:ok, jwt_verifier_plaintext_before} =
             Lockspire.Security.Policy.unseal_client_secret_jwt_verifier(jwt_verifier_before)

    assert {:ok, %{client: _rotated_jwt, client_secret: jwt_secret_after}} =
             Clients.rotate_client_secret(jwt_client.client_id, %{
               actor: %{type: :operator, id: "ops"}
             })

    assert {:ok, persisted_jwt_after} =
             Lockspire.Storage.Ecto.Repository.fetch_client_by_id(jwt_client.client_id)

    jwt_verifier_after = persisted_jwt_after.client_secret_jwt_verifier_encrypted
    assert is_binary(jwt_verifier_after)
    assert jwt_verifier_before != jwt_verifier_after

    assert {:ok, jwt_verifier_plaintext_after} =
             Lockspire.Security.Policy.unseal_client_secret_jwt_verifier(jwt_verifier_after)

    original_rat = jwt_success.registration_access_token_plaintext

    assert {:ok, _current_client} =
             RegistrationManagement.read(jwt_client.client_id, jwt_client,
               now: DateTime.add(issued_at, 1, :second)
             )

    management_failure_logs =
      capture_log(fn ->
        Process.put(
          :dcr_management_expiry_failure,
          RegistrationManagement.read(jwt_client.client_id, jwt_client,
            now: DateTime.add(issued_at, 60, :second)
          )
        )
      end)

    expired_management_result = Process.delete(:dcr_management_expiry_failure)
    assert expired_management_result == {:error, :invalid_token}

    assert {:ok, recovered_rat, recovered_client} =
             RegistrationManagement.rotate_registration_access_token(jwt_client,
               now: DateTime.add(issued_at, 61, :second)
             )

    jwt_metadata =
      DcrFixtures.client_secret_jwt_metadata()
      |> Map.put("client_id", jwt_client.client_id)
      |> Map.put("client_name", "Finite JWT management redaction updated")

    assert {:ok, management_update} =
             RegistrationManagement.update(jwt_client.client_id, %{
               metadata: jwt_metadata,
               server_policy: jwt_policy,
               client: recovered_client,
               now: DateTime.add(issued_at, 62, :second)
             })

    {:ok, final_client} = Repository.fetch_client_by_id(jwt_client.client_id)

    management_material =
      [
        original_rat,
        recovered_rat,
        management_update.registration_access_token_plaintext,
        jwt_success.client.registration_access_token_hash,
        recovered_client.registration_access_token_hash,
        final_client.registration_access_token_hash,
        jwt_secret_before,
        jwt_secret_after,
        jwt_verifier_before,
        jwt_verifier_after,
        jwt_verifier_plaintext_before,
        jwt_verifier_plaintext_after,
        jwt_verifier_plaintext_before,
        jwt_verifier_plaintext_after
      ]
      |> Enum.filter(&is_binary/1)

    captured = drain_events()

    observed = Enum.frequencies_by(captured, fn {event, _measurements, _metadata} -> event end)

    for event <- events do
      assert_positive_event_count!(observed, event)
    end

    for event <- [
          [:lockspire, :dcr, :read],
          [:lockspire, :audit, :dcr, :read],
          [:lockspire, :dcr, :unauthorized],
          [:lockspire, :audit, :dcr, :unauthorized],
          [:lockspire, :dcr, :update],
          [:lockspire, :audit, :dcr, :update],
          [:lockspire, :dcr, :rotate],
          [:lockspire, :audit, :dcr, :rotate]
        ] do
      assert_positive_event_count!(observed, event)
    end

    host_rotation_events =
      Enum.filter(captured, fn
        {[:lockspire, :dcr, :rotate], _measurements,
         %{actor_type: :operator, actor_id: "admin-ui", client_id: id}} ->
          id == jwt_client.client_id

        _ ->
          false
      end)

    self_rotation_events =
      Enum.filter(captured, fn
        {[:lockspire, :dcr, :rotate], _measurements,
         %{actor_type: :self_registered_client, actor_id: id}} ->
          id == jwt_client.client_id

        _ ->
          false
      end)

    assert length(host_rotation_events) >= 1
    assert length(self_rotation_events) >= 1

    assert_raise KeyError, fn ->
      assert_positive_event_count!(%{}, [:lockspire, :dcr, :register])
    end

    assert_raise ExUnit.AssertionError, fn ->
      assert_positive_event_count!(
        %{[:lockspire, :dcr, :register] => nil},
        [:lockspire, :dcr, :register]
      )
    end

    assert sensitive_keys(
             {:captured, %{nested: %{client_secret_jwt_verifier_encrypted: "sentinel"}}}
           )

    refute sensitive_keys({:captured, %{nested: %{ordinary: "safe"}}})

    material =
      [
        secret,
        replacement,
        hash_before,
        hash_after,
        verifier,
        jwt_secret_before,
        jwt_secret_after,
        persisted_jwt_before.client_secret_hash,
        persisted_jwt_after.client_secret_hash,
        jwt_verifier_before,
        jwt_verifier_after,
        original_rat,
        recovered_rat,
        management_update.registration_access_token_plaintext,
        jwt_success.client.registration_access_token_hash,
        recovered_client.registration_access_token_hash,
        final_client.registration_access_token_hash
      ]
      |> Enum.filter(&is_binary/1)

    for {event, measurements, metadata} <- captured,
        value <- material do
      inspected =
        inspect({event, measurements, metadata}, limit: :infinity, printable_limit: :infinity)

      refute String.contains?(inspected, value),
             "captured lifecycle output contained sensitive material"

      refute sensitive_keys({event, measurements, metadata})
    end

    for {event, measurements, metadata} <- captured,
        value <- management_material do
      inspected =
        inspect({event, measurements, metadata}, limit: :infinity, printable_limit: :infinity)

      refute String.contains?(inspected, value),
             "captured management output contained sensitive material"
    end

    for value <- material do
      refute String.contains?(failure_logs, value),
             "captured failure log contained sensitive material"
    end

    for value <- management_material do
      refute String.contains?(management_failure_logs, value),
             "captured management failure log contained sensitive material"
    end

    management_error_shape =
      inspect(expired_management_result, limit: :infinity, printable_limit: :infinity)

    for value <- management_material do
      refute String.contains?(management_error_shape, value),
             "public management error contained sensitive material"
    end

    assert public_error.error == "invalid_client"
    error_shape = inspect(public_error, limit: :infinity, printable_limit: :infinity)

    for value <- material do
      refute String.contains?(error_shape, value),
             "public auth error contained sensitive material"
    end

    refute sensitive_keys(public_error)

    audit_rows =
      Lockspire.TestRepo.all(
        from(audit in AuditEventRecord,
          where: audit.resource_id in ^[client.client_id, jwt_client.client_id],
          order_by: [desc: audit.id]
        )
      )

    assert Enum.any?(audit_rows, &(&1.action == "dcr_client_created"))
    assert Enum.any?(audit_rows, &(&1.action == "client_secret_rotated"))

    assert Enum.any?(
             audit_rows,
             &(&1.action == "dcr_management_rat_rotated" and &1.actor_type == "operator" and
                 &1.actor_id == "admin-ui")
           )

    for row <- audit_rows, value <- material do
      inspected = inspect(row, limit: :infinity, printable_limit: :infinity)
      refute String.contains?(inspected, value), "audit evidence contained sensitive material"
      refute sensitive_keys(row)
    end

    for value <- management_material, row <- audit_rows do
      inspected = inspect(row, limit: :infinity, printable_limit: :infinity)

      refute String.contains?(inspected, value),
             "management audit evidence contained sensitive material"
    end
  end

  defp drain_events(acc \\ []) do
    receive do
      {:telemetry_event, e, m, md} -> drain_events([{e, m, md} | acc])
    after
      50 -> Enum.reverse(acc)
    end
  end

  defp put_authorization_code(client, raw_code, verifier, redirect_uri) do
    interaction_id = "redaction-interaction-#{raw_code}"
    challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
    issued_at = DateTime.utc_now()

    with {:ok, _interaction} <-
           Lockspire.Storage.Ecto.Repository.put_interaction(%Interaction{
             interaction_id: interaction_id,
             client_id: client.client_id,
             account_id: "redaction-subject",
             scopes_requested: ["email"],
             redirect_uri: redirect_uri,
             return_to: "/authorize",
             state: "redaction-state",
             code_challenge: challenge,
             code_challenge_method: :S256,
             status: :completed,
             completed_at: issued_at,
             expires_at: DateTime.add(issued_at, 300, :second)
           }),
         {:ok, code} <-
           Lockspire.Storage.Ecto.Repository.store_token(%Token{
             token_hash: TokenFormatter.hash_token(raw_code),
             token_type: :authorization_code,
             client_id: client.client_id,
             account_id: "redaction-subject",
             interaction_id: interaction_id,
             redirect_uri: redirect_uri,
             scopes: ["email"],
             audience: [],
             code_challenge: challenge,
             code_challenge_method: :S256,
             issued_at: issued_at,
             expires_at: DateTime.add(issued_at, 300, :second)
           }) do
      {:ok, code}
    end
  end

  defp sensitive_keys(%_{} = struct), do: struct |> Map.from_struct() |> sensitive_keys()

  defp sensitive_keys(value) when is_map(value) do
    forbidden =
      MapSet.new(
        ~w(client_secret client_secret_hash client_secret_jwt_verifier_encrypted secret_hash verifier_secret)
      )

    Enum.any?(value, fn {key, nested} ->
      key_name = if is_atom(key), do: Atom.to_string(key), else: key
      MapSet.member?(forbidden, key_name) or sensitive_keys(nested)
    end)
  end

  defp sensitive_keys(value) when is_list(value), do: Enum.any?(value, &sensitive_keys/1)

  defp sensitive_keys(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> sensitive_keys()

  defp sensitive_keys(_value), do: false

  defp assert_positive_event_count!(observed, event) do
    count = Map.fetch!(observed, event)

    assert is_integer(count) and count > 0,
           "expected a positive integer count for #{inspect(event)}"
  end
end
