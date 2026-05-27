defmodule AdoptionDemoWeb.DeviceVerificationController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML
  alias Lockspire.Host.Claims
  alias Lockspire.Host.Context
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Protocol.DeviceVerification

  def show(conn, params) do
    render_entry(conn, params["user_code"] || "", nil)
  end

  def lookup(conn, %{"user_code" => user_code}) do
    case DeviceVerification.lookup_pending_device_authorization(user_code) do
      {:ok, pending} ->
        render_review(conn, pending, current_subject(conn))

      {:error, :not_found} ->
        render_entry(conn, user_code, "That code is invalid or expired.")

      {:error, :expired} ->
        render_entry(conn, user_code, "That code is invalid or expired.")

      {:error, :not_active} ->
        render_entry(conn, user_code, "That request is no longer active.")

      {:error, _reason} ->
        render_entry(conn, user_code, "We could not load that device request right now.")
    end
  end

  def lookup(conn, _params) do
    render_entry(conn, "", "Enter the code shown on your device.")
  end

  def approve(conn, %{"handle" => handle}) do
    with {:ok, actor_context} <- actor_context(conn, handle),
         {:ok, _authorization} <-
           DeviceVerification.approve_device_authorization(handle, actor_context) do
      redirect(conn, to: "/verify")
    else
      {:redirect, %InteractionResult{} = result} ->
        redirect(conn, to: redirect_destination(result))

      _other ->
        conn
        |> put_status(:bad_request)
        |> text("Could not approve device request.")
    end
  end

  def deny(conn, %{"handle" => handle}) do
    with {:ok, actor_context} <- actor_context(conn, handle),
         {:ok, _authorization} <-
           DeviceVerification.deny_device_authorization(handle, actor_context) do
      redirect(conn, to: "/verify")
    else
      {:redirect, %InteractionResult{} = result} ->
        redirect(conn, to: redirect_destination(result))

      _other ->
        conn
        |> put_status(:bad_request)
        |> text("Could not deny device request.")
    end
  end

  defp render_entry(conn, user_code, error_message) do
    body = """
    <section class="panel">
      <h1>Device verification</h1>
      <p>Enter the code from your device. This host page is side-effect free until review.</p>
      #{error_html(error_message)}
      <form action="/verify" method="post">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
        <label for="user_code">Device code</label>
        <input id="user_code" name="user_code" value="#{HTML.escape(user_code)}" />
        <button class="primary" type="submit">Review device request</button>
      </form>
    </section>
    """

    html(conn, HTML.page(conn, "Device verification", body))
  end

  defp render_review(conn, pending, subject) do
    body = """
    <section class="panel">
      <h1>Review device request</h1>
      <p>Confirm the code and approve only if it matches the requesting device.</p>
      <dl>
        <dt>Code</dt><dd><code>#{HTML.escape(pending.user_code)}</code></dd>
        <dt>Client</dt><dd><code>#{HTML.escape(pending.client_id)}</code></dd>
        <dt>Scopes</dt><dd><code>#{HTML.escape(Enum.join(pending.scopes, " "))}</code></dd>
        <dt>Signed-in subject</dt><dd><code>#{HTML.escape(subject || "anonymous")}</code></dd>
      </dl>
      <form action="/verify/#{pending.verification_handle}/approve" method="post">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
        <button class="primary" type="submit">Approve device</button>
      </form>
      <form action="/verify/#{pending.verification_handle}/deny" method="post">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
        <button type="submit">Deny request</button>
      </form>
    </section>
    """

    html(conn, HTML.page(conn, "Review device", body))
  end

  defp actor_context(conn, handle) do
    resolver = Lockspire.account_resolver!()
    context = %Context{return_to: "/verify", metadata: %{verification_handle: handle}}

    case resolver.resolve_current_account(conn, context) do
      {:ok, account} ->
        with {:ok, %Claims{} = claims} <- resolver.build_claims(account, context) do
          {:ok, %{subject_id: claims.subject}}
        end

      {:redirect, result} ->
        {:redirect, result}
    end
  end

  defp current_subject(conn) do
    case conn.assigns[:current_account] do
      nil -> nil
      account -> "user:" <> account.id
    end
  end

  defp redirect_destination(%InteractionResult{} = result) do
    result.login_path
    |> append_query("return_to", result.return_to)
    |> append_query_params(result.params)
  end

  defp append_query_params(path, params) when is_map(params) do
    Enum.reduce(params, path, fn {key, value}, acc -> append_query(acc, key, value) end)
  end

  defp append_query(path, _key, nil), do: path
  defp append_query(path, _key, ""), do: path

  defp append_query(path, key, value) do
    separator = if String.contains?(path, "?"), do: "&", else: "?"
    path <> separator <> URI.encode_query(%{to_string(key) => value})
  end

  defp error_html(nil), do: ""
  defp error_html(message), do: ~s(<p class="danger">#{HTML.escape(message)}</p>)
end
