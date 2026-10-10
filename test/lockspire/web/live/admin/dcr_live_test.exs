defmodule Lockspire.Web.Live.Admin.DcrLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "")

    on_exit(fn -> Application.put_env(:lockspire, :mount_path, "/lockspire") end)

    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "lockspire_salt"]
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    assert {:ok, _policy} =
             Repository.put_server_policy(%ServerPolicy{id: 1, registration_policy: :disabled})

    :ok
  end

  test "DCR hub separates issuer policy, IAT intake, and client credential jobs" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")
    text = rendered_text(html)

    assert text =~ "Registration disabled"
    assert text =~ "Prepare a partner registration"

    assert text =~
             "Dynamic Client Registration (DCR) lets a partner request client registration"

    assert text =~
             "Issuer policy determines whether a request can proceed and which requested client metadata is accepted"

    assert text =~
             "When policy requires one, an Initial Access Token authorizes the initial registration request"

    assert text =~
             "A Registration Access Token manages one registered client&#39;s configuration endpoint"

    assert text =~ "a client secret authenticates a confidential client at the token endpoint"
    assert text =~ "Changing it does not update existing clients."
    refute html =~ "operator"
    assert html =~ ~s(href="/admin/policies/dcr")
    assert html =~ ~s(href="/admin/iats/new")
    assert html =~ ~s(href="/admin/iats")
  end

  test "successful empty inventories show measured zero and the supported next actions" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")
    text = rendered_text(html)

    assert text =~ "Active 0"
    assert text =~ "0 self-registered clients"
    assert text =~ "No self-registered clients yet"
    assert text =~ "Create an Initial Access Token"
    assert length(Regex.scan(~r/href="\/admin\/iats\/new"/, html)) == 1
    refute text =~ "unavailable"
  end

  test "open registration recommends policy review instead of an unnecessary IAT" do
    assert {:ok, _policy} =
             Repository.put_server_policy(%ServerPolicy{id: 1, registration_policy: :open})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")
    text = rendered_text(html)

    assert text =~ "Next safe action"
    assert text =~ "Review DCR policy"

    assert text =~
             "Open registration does not require an Initial Access Token. Review issuer metadata allowlists before partner onboarding."

    refute text =~ "Next safe action Create an Initial Access Token"
  end

  test "populated hub links safe self-registered identities to client detail" do
    client = register_self_registered_client("partner-one", "Northstar Reports")
    _second_client = register_self_registered_client("partner-two", "Billing Console")
    _iat = save_active_iat("fixture-iat-hash-1")

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")
    text = rendered_text(html)

    assert text =~ "2 self-registered clients"
    assert text =~ "Northstar Reports"
    assert text =~ "Billing Console"
    assert text =~ "Active 1"
    assert html =~ ~s(href="/admin/clients/#{client.client_id}")
    refute html =~ "fixture-iat-hash-1"
  end

  test "failed policy read stays unavailable while client and IAT reads remain populated" do
    _client = register_self_registered_client("partner-visible", "Partner Console")
    _iat = save_active_iat("fixture-iat-hash-2")

    with_failed_source(:policy, fn ->
      assert {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")
      text = rendered_text(html)

      assert text =~ "Registration policy unavailable"
      assert text =~ "Active 1"
      assert text =~ "1 self-registered client"
      refute text =~ "Registration disabled"
      refute text =~ "Active 0"
    end)
  end

  test "failed client read preserves policy and IAT observations without a zero count" do
    _iat = save_active_iat("fixture-iat-hash-3")

    with_failed_source(:clients, fn ->
      assert {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")
      text = rendered_text(html)

      assert text =~ "Registration disabled"
      assert text =~ "Active 1"
      assert text =~ "Self-registered client inventory unavailable"
      refute text =~ "0 self-registered clients"
    end)
  end

  test "failed IAT read preserves policy and client observations without a zero count" do
    _client = register_self_registered_client("partner-visible", "Partner Console")

    with_failed_source(:iats, fn ->
      assert {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")
      text = rendered_text(html)

      assert text =~ "Registration disabled"
      assert text =~ "1 self-registered client"
      assert text =~ "Initial Access Token inventory unavailable"
      refute text =~ "Active 0"
    end)
  end

  defp register_self_registered_client(client_id, name) do
    assert {:ok, client} =
             Repository.register_client(%Client{
               client_id: client_id,
               client_secret_hash: "sha256:synthetic-secret-hash",
               client_type: :confidential,
               name: name,
               redirect_uris: ["https://partner.example/callback"],
               allowed_scopes: ["openid"],
               allowed_grant_types: ["authorization_code"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               provenance: :self_registered,
               registration_access_token_hash: "sha256:synthetic-rat-hash",
               registration_client_uri: "https://issuer.example/register/#{client_id}",
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    client
  end

  defp save_active_iat(token_hash) do
    now = DateTime.utc_now()

    assert {:ok, iat} =
             Repository.save_initial_access_token(%InitialAccessToken{
               token_hash: token_hash,
               single_use: true,
               expires_at: DateTime.add(now, 3_600, :second),
               created_by: "synthetic-operator",
               inserted_at: now,
               updated_at: now
             })

    iat
  end

  defp with_failed_source(source, fun) do
    prior_repo = Application.get_env(:lockspire, :repo)
    prior_source = Application.get_env(:lockspire, :dcr_live_test_failed_source)

    try do
      Application.put_env(:lockspire, :dcr_live_test_failed_source, source)
      Application.put_env(:lockspire, :repo, Lockspire.Web.Live.Admin.DcrLiveTest.ReadRepo)
      fun.()
    after
      Application.put_env(:lockspire, :repo, prior_repo)
      Application.put_env(:lockspire, :dcr_live_test_failed_source, prior_source)
    end
  end

  defp rendered_text(html) do
    html
    |> String.replace(~r/<style\b[^>]*>.*?<\/style>/s, " ")
    |> String.replace(~r/<script\b[^>]*>.*?<\/script>/s, " ")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp conn_for_admin, do: Phoenix.ConnTest.build_conn()
end

defmodule Lockspire.Web.Live.Admin.DcrLiveTest.ReadRepo do
  @moduledoc false

  def one(query, options \\ []) do
    maybe_fail(query)
    Lockspire.TestRepo.one(query, options)
  end

  def all(query, options \\ []) do
    maybe_fail(query)
    Lockspire.TestRepo.all(query, options)
  end

  defp maybe_fail(query) do
    source =
      query
      |> Ecto.Queryable.to_query()
      |> Map.fetch!(:from)
      |> Map.fetch!(:source)
      |> case do
        {_table, schema} -> schema
        value -> value
      end

    failed_source = Application.get_env(:lockspire, :dcr_live_test_failed_source)

    should_fail? =
      (failed_source == :policy and source == Lockspire.Storage.Ecto.ServerPolicyRecord) or
        (failed_source == :clients and source == Lockspire.Storage.Ecto.ClientRecord) or
        (failed_source == :iats and source == Lockspire.Storage.Ecto.InitialAccessTokenRecord)

    if should_fail?, do: raise("synthetic DCR read failure")
  end
end
