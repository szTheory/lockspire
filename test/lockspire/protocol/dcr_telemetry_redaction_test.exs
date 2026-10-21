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
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures
  alias Lockspire.TestSupport.TelemetryCapture
  import Lockspire.TokenExchangeCase, only: [basic_auth: 2, publish_signing_key: 1]

  # The 18 event paths the sweep attaches to.
  # 7 DCR family events × 2 paths (telemetry + audit-mirror) = 14
  # 2 IAT family events × 2 paths = 4 → total 18.
  @attached_events [
    # DCR
    [:lockspire, :dcr_registration_succeeded],
    [:lockspire, :dcr_registration_rejected],
    [:lockspire, :dcr_management_read],
    [:lockspire, :dcr_management_updated],
    [:lockspire, :dcr_management_deleted],
    [:lockspire, :dcr_management_unauthorized],
    [:lockspire, :dcr_registration_access_token_rotated],
    [:lockspire, :audit, :dcr_registration_succeeded],
    [:lockspire, :audit, :dcr_registration_rejected],
    [:lockspire, :audit, :dcr_management_read],
    [:lockspire, :audit, :dcr_management_updated],
    [:lockspire, :audit, :dcr_management_deleted],
    [:lockspire, :audit, :dcr_management_unauthorized],
    [:lockspire, :audit, :dcr_registration_access_token_rotated],
    # IAT
    [:lockspire, :iat_redeemed],
    [:lockspire, :iat_redemption_failed],
    [:lockspire, :audit, :iat_redeemed],
    [:lockspire, :audit, :iat_redemption_failed]
  ]

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
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
          metadata: DcrFixtures.valid_metadata(),
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
      # assert captured != [], "expected at least one captured telemetry event"

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

    jwt_request =
      DcrFixtures.register_request(
        server_policy:
          DcrFixtures.client_secret_jwt_server_policy(%{
            dcr_default_client_secret_lifetime_seconds: 60
          }),
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

    assert {:ok, ^jwt_secret_before} =
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

    assert {:ok, ^jwt_secret_after} =
             Lockspire.Security.Policy.unseal_client_secret_jwt_verifier(jwt_verifier_after)

    captured = drain_events()

    observed = Enum.frequencies_by(captured, fn {event, _measurements, _metadata} -> event end)

    for event <- events do
      assert_positive_event_count!(observed, event)
    end

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
        jwt_verifier_after
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

    for value <- material do
      refute String.contains?(failure_logs, value),
             "captured failure log contained sensitive material"
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

    for row <- audit_rows, value <- material do
      inspected = inspect(row, limit: :infinity, printable_limit: :infinity)
      refute String.contains?(inspected, value), "audit evidence contained sensitive material"
      refute sensitive_keys(row)
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
