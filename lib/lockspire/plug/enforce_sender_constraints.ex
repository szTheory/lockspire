defmodule Lockspire.Plug.EnforceSenderConstraints do
  @moduledoc """
  Soft sender-constraint enforcement for DPoP- and MTLS-bound access tokens.
  """

  @behaviour Plug

  import Plug.Conn

  alias Lockspire.AccessToken
  alias Lockspire.Protocol.ProtectedResourceDPoP

  @options_schema [
    dpop_replay_store: [
      type: {:or, [:atom, :map]},
      required: false,
      doc: "Replay store implementing record_dpop_proof/1."
    ],
    dpop_max_age: [
      type: :non_neg_integer,
      required: false
    ],
    dpop_clock_skew: [
      type: :non_neg_integer,
      required: false
    ],
    now: [
      type: :any,
      required: false
    ]
  ]

  @impl Plug
  def init(opts), do: NimbleOptions.validate!(opts, @options_schema)

  @impl Plug
  def call(conn, opts) do
    case conn.assigns[:access_token] do
      %AccessToken{error: nil, binding_requirements: requirements} = access_token
      when is_map(requirements) ->
        enforce_constraints(conn, access_token, opts)

      _other ->
        conn
    end
  end

  defp enforce_constraints(conn, %AccessToken{} = access_token, opts) do
    case maybe_validate_dpop(access_token, conn, opts) do
      {:ok, _proof} ->
        conn

      :skip ->
        conn

      {:error, sender_error} ->
        assign(conn, :access_token, %AccessToken{access_token | error: sender_error})
    end
  end

  defp maybe_validate_dpop(%AccessToken{binding_requirements: %{dpop_jkt: _jkt}} = access_token, conn, opts) do
    request = %{
      authorization_scheme: access_token.authorization_scheme,
      access_token: access_token.token,
      dpop: header_value(conn, "dpop"),
      method: conn.method,
      target_uri: request_target_uri(conn),
      opts: [
        dpop_replay_store: Keyword.get(opts, :dpop_replay_store),
        dpop_max_age: Keyword.get(opts, :dpop_max_age, 300),
        dpop_clock_skew: Keyword.get(opts, :dpop_clock_skew, 30),
        now: Keyword.get(opts, :now, &DateTime.utc_now/0)
      ]
    }

    case ProtectedResourceDPoP.validate_access(access_token, request) do
      {:ok, proof} ->
        {:ok, proof}

      {:error, error} ->
        {:error, sender_error(:dpop, error)}
    end
  end

  defp maybe_validate_dpop(_access_token, _conn, _opts), do: :skip

  defp sender_error(challenge, error) do
    %{
      category: :sender_constraint,
      challenge: challenge,
      reason_code: error.reason_code,
      error: error.error,
      error_description: error.error_description
    }
  end

  defp header_value(conn, header_name) do
    conn
    |> get_req_header(header_name)
    |> List.first()
    |> case do
      value when is_binary(value) and value != "" -> value
      _other -> nil
    end
  end

  defp request_target_uri(conn) do
    path =
      case conn.query_string do
        "" -> conn.request_path
        query -> conn.request_path <> "?" <> query
      end

    URI.to_string(%URI{
      scheme: Atom.to_string(conn.scheme || :http),
      host: conn.host || "www.example.com",
      port: conn.port,
      path: path
    })
  end
end
