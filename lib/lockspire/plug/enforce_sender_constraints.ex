defmodule Lockspire.Plug.EnforceSenderConstraints do
  @moduledoc """
  Soft sender-constraint enforcement for DPoP- and MTLS-bound access tokens.
  """

  @behaviour Plug

  import Plug.Conn

  alias Lockspire.AccessToken
  alias Lockspire.Protocol.MTLSTokenBinding
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
    mtls_extractor: [
      type: :any,
      required: false
    ],
    now: [
      type: :any,
      required: false
    ]
  ]

  @impl Plug
  def init(opts) do
    opts = NimbleOptions.validate!(opts, @options_schema)

    case Keyword.get(opts, :mtls_extractor) do
      nil ->
        opts

      {module, extractor_opts} when is_atom(module) and is_list(extractor_opts) ->
        opts

      other ->
        raise ArgumentError,
              "expected :mtls_extractor to be {module, opts}, got: #{inspect(other)}"
    end
  end

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
        maybe_validate_mtls(conn, access_token, opts)

      :skip ->
        maybe_validate_mtls(conn, access_token, opts)

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

  defp maybe_validate_mtls(
         conn,
         %AccessToken{binding_requirements: %{mtls_x5t_s256: expected_thumbprint}} = access_token,
         opts
       ) do
    with {:ok, cert} <- fetch_mtls_cert(conn, opts),
         true <- MTLSTokenBinding.confirmation_matches?(expected_thumbprint, cert) do
      conn
    else
      {:error, _reason} ->
        assign(conn, :access_token, %AccessToken{access_token | error: mtls_error()})

      false ->
        assign(conn, :access_token, %AccessToken{access_token | error: mtls_error()})
    end
  end

  defp maybe_validate_mtls(conn, _access_token, _opts), do: conn

  defp sender_error(challenge, error) do
    %{
      category: :sender_constraint,
      challenge: challenge,
      reason_code: error.reason_code,
      error: error.error,
      error_description: error.error_description,
      dpop_nonce: Map.get(error, :dpop_nonce)
    }
  end

  defp mtls_error do
    %{
      category: :sender_constraint,
      challenge: :bearer,
      reason_code: :invalid_client_certificate,
      error: "invalid_token",
      error_description: "Client certificate missing or thumbprint mismatch"
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

  defp fetch_mtls_cert(conn, opts) do
    case conn.private[:lockspire_mtls_cert] do
      cert when is_binary(cert) ->
        {:ok, cert}

      _other ->
        case Keyword.get(opts, :mtls_extractor) do
          {module, extractor_opts} -> module.extract(conn, extractor_opts)
          nil -> {:error, :missing_client_certificate}
        end
    end
  end
end
