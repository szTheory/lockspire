defmodule Lockspire.Phase171.QualificationProbeTest do
  use Lockspire.ConfigCase, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  @callback_uri "https://client.example.com/callback"
  @client_id "phase171-qualification-public"
  @state "phase171-qualification-state"
  @nonce "phase171-qualification-nonce"
  @verifier "phase171-qualification-verifier-with-adequate-length"
  @challenge @verifier |> then(&:crypto.hash(:sha256, &1)) |> Base.url_encode64(padding: false)

  setup_all do
    previous_log_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_log_level) end)

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://issuer.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
    Application.put_env(:lockspire, :account_resolver, Lockspire.TestAccountResolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

    {:ok, client} =
      Repository.register_client(%Client{
        lifetime_version: 0,
        client_id: @client_id,
        client_secret_hash: nil,
        client_type: :public,
        name: "Phase 171 Qualification Client",
        redirect_uris: [@callback_uri],
        allowed_scopes: ["openid", "email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "A171-003 valid direct consent control then requires unsupported mode to be HTTP 400 without OAuth error parameters",
       %{client: client} do
    assert_consent_location_classification!()

    control = authorize(client.client_id, direct_params())
    control_projection = authorization_projection(control, client.client_id)

    assert_safe_control!(
      control_projection.status in [302, 303] and
        control_projection.location_kind == "host_consent" and
        control_projection.scopes == ["email", "openid"] and
        control_projection.state_matches and control_projection.nonce_matches and
        control_projection.client_matches,
      "A171-003 valid query-mode control",
      Map.take(control_projection, [
        :status,
        :location_kind,
        :scopes,
        :state_matches,
        :nonce_matches
      ])
    )

    candidate =
      authorize(client.client_id, Map.put(direct_params(), "response_mode", "binary"))
      |> unsupported_mode_projection()

    assert_projection!(
      "A171-003:http-error-disposition",
      %{status: 400, location_kind: "none", error_parameter_names: []},
      candidate
    )
  end

  test "P171-005 valid pushed-reference control requires pushed scopes to remain authoritative over front-channel scope",
       %{client: client} do
    control_reference = push_request!(client.client_id)

    control =
      authorize(client.client_id, %{
        "client_id" => client.client_id,
        "request_uri" => control_reference
      })
      |> authorization_projection(client.client_id)

    assert_safe_control!(
      control.status in [302, 303] and control.location_kind == "host_consent" and
        control.scopes == ["email", "openid"] and control.state_matches and
        control.nonce_matches and control.client_matches,
      "P171-005 reference-only control",
      Map.take(control, [
        :status,
        :location_kind,
        :scopes,
        :state_matches,
        :nonce_matches
      ])
    )

    candidate_reference = push_request!(client.client_id)

    candidate =
      authorize(client.client_id, %{
        "client_id" => client.client_id,
        "request_uri" => candidate_reference,
        "scope" => "profile"
      })
      |> authorization_projection(client.client_id)

    assert_projection!(
      "P171-005:pushed-scope-authority",
      %{
        status_class: "redirect",
        location_kind: "host_consent",
        scopes: ["email", "openid"],
        state_matches: true,
        nonce_matches: true,
        client_matches: true
      },
      candidate
    )
  end

  defp assert_consent_location_classification! do
    assert location_kind("/lockspire/consent/interaction-123") == "host_consent"

    for location <- [
          "https://attacker.example/lockspire/consent/interaction-123",
          "//attacker.example/lockspire/consent/interaction-123",
          "/lockspire/consent.evil/interaction-123",
          "/lockspire/consent/interaction-123/extra"
        ] do
      assert location_kind(location) == "other", "unexpected consent classification: #{location}"
    end
  end

  defp direct_params do
    %{
      "client_id" => @client_id,
      "response_type" => "code",
      "redirect_uri" => @callback_uri,
      "scope" => "openid email",
      "prompt" => "consent",
      "state" => @state,
      "nonce" => @nonce,
      "code_challenge" => @challenge,
      "code_challenge_method" => "S256"
    }
  end

  defp push_request!(client_id) do
    params = Map.put(direct_params(), "client_id", client_id)

    conn =
      build_conn(:post, "/par", params)
      |> put_req_header("content-type", "application/x-www-form-urlencoded")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    response = safe_par_response(conn)

    assert_safe_control!(
      conn.status == 201 and is_binary(response.request_uri) and
        String.starts_with?(response.request_uri, "urn:ietf:params:oauth:request_uri:"),
      "P171-005 PAR POST control",
      %{status: conn.status, issued_reference: is_binary(response.request_uri)}
    )

    response.request_uri
  end

  defp safe_par_response(conn) do
    case Jason.decode(conn.resp_body) do
      {:ok, %{"request_uri" => request_uri}} when is_binary(request_uri) ->
        %{request_uri: request_uri}

      _other ->
        %{request_uri: nil}
    end
  end

  defp authorize(client_id, params) do
    params = Map.put(params, "client_id", client_id)

    build_conn(:get, "/authorize", params)
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp authorization_projection(conn, client_id) do
    location = conn |> get_resp_header("location") |> List.first()
    kind = location_kind(location)

    interaction =
      if interaction_id = host_consent_interaction_id(location) do
        case Repository.fetch_interaction(interaction_id) do
          {:ok, interaction} -> interaction
          _other -> nil
        end
      end

    %{
      status: conn.status,
      status_class: if(conn.status in [302, 303], do: "redirect", else: "other"),
      location_kind: kind,
      scopes: if(interaction, do: Enum.sort(interaction.scopes_requested), else: nil),
      state_matches: interaction != nil and interaction.state == @state,
      nonce_matches: interaction != nil and interaction.nonce == @nonce,
      client_matches: interaction != nil and interaction.client_id == client_id
    }
  end

  defp unsupported_mode_projection(conn) do
    %{
      status: conn.status,
      location_kind: location_kind(conn |> get_resp_header("location") |> List.first()),
      error_parameter_names: error_parameter_names(conn)
    }
  end

  defp location_kind(nil), do: "none"

  defp location_kind(location) when is_binary(location) do
    uri = URI.parse(location)

    cond do
      uri.scheme == "https" and uri.host == "client.example.com" and
          uri.path == "/callback" ->
        "registered_callback"

      host_consent_interaction_id(location) != nil ->
        "host_consent"

      true ->
        "other"
    end
  end

  defp host_consent_interaction_id(location) when is_binary(location) do
    uri = URI.parse(location)

    if is_nil(uri.scheme) and is_nil(uri.host) and is_nil(uri.userinfo) and is_nil(uri.port) do
      case Regex.run(~r{\A/lockspire/consent/([^/?#]+)\z}, uri.path || "") do
        [_, interaction_id] -> interaction_id
        _ -> nil
      end
    end
  end

  defp host_consent_interaction_id(_), do: nil

  defp error_parameter_names(conn) do
    location = conn |> get_resp_header("location") |> List.first()

    location_names =
      case location do
        value when is_binary(value) ->
          uri = URI.parse(value)
          URI.decode_query(uri.query || "") |> Map.keys()

        _ ->
          []
      end

    structured_names =
      case {get_resp_header(conn, "content-type"), Jason.decode(conn.resp_body)} do
        {[content_type | _], {:ok, body}} when is_map(body) ->
          if String.contains?(content_type, "json"), do: Map.keys(body), else: []

        _ ->
          []
      end

    (location_names ++ structured_names)
    |> Enum.filter(&(&1 in ["error", "error_description", "error_uri", "state", "iss"]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp assert_safe_control!(true, _label, _facts), do: :ok

  defp assert_safe_control!(false, label, facts) do
    flunk("#{label} failed before the normative assertion; safe facts=#{inspect(facts)}")
  end

  defp assert_projection!(assertion_id, expected, observed) do
    assert Map.take(observed, Map.keys(expected)) == expected,
           "#{assertion_id}: normative projection mismatch; expected=#{inspect(expected)} observed=#{inspect(observed)}"
  end
end
