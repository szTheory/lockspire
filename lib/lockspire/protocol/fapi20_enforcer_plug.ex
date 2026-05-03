defmodule Lockspire.Protocol.FAPI20EnforcerPlug do
  @moduledoc """
  Boundary fail-fast enforcer for FAPI 2.0 Security Profile.

  When the effective `security_profile` is `:fapi_2_0_security`, this Plug rejects:
  - GET /authorize requests missing `request_uri` (FAPI-02 / PAR mandate)
  - POST /token requests missing the `dpop` header (FAPI-03 / sender-constraining)
  - GET-or-POST /userinfo requests missing the `dpop` header (FAPI-03 / resource access)

  The Plug is exempt for `/par` (the PAR endpoint by definition has no `request_uri`)
  and bypasses any non-FAPI path. On unreachable ServerPolicy it fails CLOSED with 503.

  Per-route dispatch table is in 41-02-PLAN.md.

  ## Implementation Notes

  - For /userinfo, enforcement is header-shape only (DPoP header presence + Authorization
    scheme). No access token decode occurs in the Plug (see `<userinfo_strategy>` in plan).
  - Per-client opt-in under global `:none` is supported (G1 scenario). Per-client `:none`
    escape hatch under global `:fapi_2_0_security` is also supported (G2 / D-01).
  - The `policy_fn` opt in `init/1` is used in tests to simulate policy unavailability.
    In production, pass `[]` or `%{}` and the default `Repository.get_server_policy/0`
    function is used.
  """

  import Plug.Conn

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Observability
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Storage.Ecto.Repository

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    # Match on path_info first — keep the hot path fast for non-FAPI routes.
    case conn.path_info do
      ["authorize"] -> with_resolved_profile(conn, opts, &enforce_authorize/2)
      ["token"] -> with_resolved_profile(conn, opts, &enforce_token/2)
      ["userinfo"] -> with_resolved_profile(conn, opts, &enforce_userinfo/2)
      _other -> conn
    end
  end

  # ---------------------------------------------------------------------------
  # Private: profile resolution
  # ---------------------------------------------------------------------------

  defp with_resolved_profile(conn, opts, enforcement_fn) do
    policy_fn = Keyword.get(opts, :policy_fn, &Repository.get_server_policy/0)

    case policy_fn.() do
      {:ok, %ServerPolicy{} = server_policy} ->
        client = fetch_client(conn)
        resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

        if resolved.fapi_2_0_security? do
          enforcement_fn.(conn, resolved)
        else
          conn
        end

      {:error, _reason} ->
        fail_closed(conn)
    end
  end

  # ---------------------------------------------------------------------------
  # Private: per-route enforcement
  # ---------------------------------------------------------------------------

  defp enforce_authorize(conn, _resolved) do
    request_uri = Map.get(conn.params, "request_uri")

    if present?(request_uri) do
      conn
    else
      emit_fapi_failure(conn, :missing_request_uri)
      reject_authorize(conn)
    end
  end

  defp enforce_token(conn, _resolved) do
    dpop_header = get_req_header(conn, "dpop")

    if dpop_present?(dpop_header) do
      conn
    else
      emit_fapi_failure(conn, :missing_dpop_proof)
      reject_token(conn)
    end
  end

  defp enforce_userinfo(conn, _resolved) do
    dpop_header = get_req_header(conn, "dpop")
    auth_header = get_req_header(conn, "authorization") |> List.first()
    auth_scheme_is_dpop? = is_binary(auth_header) and String.starts_with?(auth_header, "DPoP ")

    if dpop_present?(dpop_header) and auth_scheme_is_dpop? do
      conn
    else
      emit_fapi_failure(conn, :missing_dpop_proof_or_auth_scheme)
      reject_userinfo(conn)
    end
  end

  defp emit_fapi_failure(conn, reason) do
    client_id = Map.get(conn.params, "client_id")

    metadata = %{
      client_id: client_id,
      reason: reason,
      path_info: conn.path_info
    }

    Observability.emit(:fapi20, :failed, %{}, metadata)
  end

  # ---------------------------------------------------------------------------
  # Private: rejection responses
  # ---------------------------------------------------------------------------

  defp reject_authorize(conn) do
    redirect_uri = Map.get(conn.params, "redirect_uri")
    state = Map.get(conn.params, "state")

    error_params = %{
      "error" => "invalid_request",
      "error_description" => "request_uri from the PAR endpoint is required"
    }

    error_params = if state, do: Map.put(error_params, "state", state), else: error_params

    if valid_redirect_uri?(redirect_uri) do
      separator = if String.contains?(redirect_uri, "?"), do: "&", else: "?"
      location = redirect_uri <> separator <> URI.encode_query(error_params)

      conn
      |> put_resp_header("location", location)
      |> send_resp(302, "")
      |> halt()
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(error_params))
      |> halt()
    end
  end

  defp reject_token(conn) do
    body = %{
      "error" => "invalid_dpop_proof",
      "error_description" => "A valid DPoP proof is required"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(body))
    |> halt()
  end

  defp reject_userinfo(conn) do
    body = %{
      "error" => "invalid_token",
      "error_description" => "DPoP-bound access token required"
    }

    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header(
      "www-authenticate",
      ~s(DPoP realm="Lockspire Userinfo", error="invalid_token", algs="ES256 PS256 EdDSA")
    )
    |> send_resp(401, Jason.encode!(body))
    |> halt()
  end

  defp fail_closed(conn) do
    body = %{
      "error" => "server_error",
      "error_description" => "Security profile unavailable"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(503, Jason.encode!(body))
    |> halt()
  end

  # ---------------------------------------------------------------------------
  # Private: helpers
  # ---------------------------------------------------------------------------

  defp fetch_client(conn) do
    case Map.get(conn.params, "client_id") do
      nil ->
        nil

      "" ->
        nil

      cid ->
        case Repository.fetch_client_by_id(cid) do
          {:ok, client} -> client
          _error -> nil
        end
    end
  end

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(str) when is_binary(str), do: true

  defp dpop_present?([]), do: false
  defp dpop_present?([""]), do: false
  defp dpop_present?([val | _]) when is_binary(val) and val != "", do: true
  defp dpop_present?(_), do: false

  defp valid_redirect_uri?(nil), do: false
  defp valid_redirect_uri?(""), do: false

  defp valid_redirect_uri?(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{scheme: scheme} when scheme in ["http", "https"] -> true
      _other -> false
    end
  end
end
