defmodule GeneratedHostAppWeb.LockspireVerificationController do
  use Phoenix.Controller, formats: [:html]

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Protocol.DeviceVerification

  # `verification_uri_complete` is prefill-only. Do not auto-submit, auto-look-up,
  # or mutate device authorization state from GET /verify. Do not log raw query
  # strings or raw user codes from this host-owned verification surface.
  def show(conn, params) do
    render_entry(conn, user_code: params["user_code"] || "")
  end

  def lookup(conn, %{"user_code" => user_code}) do
    case Lockspire.Protocol.DeviceVerification.lookup_pending_device_authorization(
           user_code,
           protocol_opts()
         ) do
      {:ok, pending} ->
        render_review(conn, pending, current_account_subject(conn))

      {:error, :not_found} ->
        render_entry(conn,
          user_code: user_code,
          error_message: invalid_or_expired_message()
        )

      {:error, :expired} ->
        render_entry(conn,
          user_code: user_code,
          error_message: invalid_or_expired_message()
        )

      {:error, :not_active} ->
        render_entry(conn,
          user_code: user_code,
          error_message: "That request is no longer active. Restart sign-in from the device."
        )

      {:error, _reason} ->
        render_entry(conn,
          user_code: user_code,
          error_message: "We could not load that device request right now. Try again."
        )
    end
  end

  def lookup(conn, _params) do
    render_entry(conn, error_message: "Enter the code shown on your device to continue.")
  end

  def approve(conn, %{"handle" => verification_handle}) do
    case resolve_actor_context(conn, verification_handle) do
      {:ok, actor_context} ->
        case DeviceVerification.approve_device_authorization(
               verification_handle,
               actor_context,
               protocol_opts()
             ) do
          {:ok, _authorization} ->
            conn
            |> put_flash(:info, "Device access approved.")
            |> redirect(to: verification_path())

          {:error, :invalid_actor_context} ->
            conn
            |> put_flash(:error, "Sign in again before approving this device request.")
            |> redirect(to: verification_path())

          {:error, _reason} ->
            conn
            |> put_flash(:error, "We could not approve that request. Restart from the device.")
            |> redirect(to: verification_path())
        end

      {:redirect, %InteractionResult{} = result} ->
        redirect(conn, to: redirect_destination(result))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Sign in again before approving this device request.")
        |> redirect(to: verification_path())
    end
  end

  def approve(conn, _params) do
    conn
    |> put_flash(:error, "Missing verification handle.")
    |> redirect(to: verification_path())
  end

  def deny(conn, %{"handle" => verification_handle}) do
    case resolve_actor_context(conn, verification_handle) do
      {:ok, actor_context} ->
        case DeviceVerification.deny_device_authorization(
               verification_handle,
               actor_context,
               protocol_opts()
             ) do
          {:ok, _authorization} ->
            conn
            |> put_flash(:info, "Device request denied.")
            |> redirect(to: verification_path())

          {:error, :invalid_actor_context} ->
            conn
            |> put_flash(:error, "Sign in again before denying this device request.")
            |> redirect(to: verification_path())

          {:error, _reason} ->
            conn
            |> put_flash(:error, "We could not deny that request. Restart from the device.")
            |> redirect(to: verification_path())
        end

      {:redirect, %InteractionResult{} = result} ->
        redirect(conn, to: redirect_destination(result))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Sign in again before denying this device request.")
        |> redirect(to: verification_path())
    end
  end

  def deny(conn, _params) do
    conn
    |> put_flash(:error, "Missing verification handle.")
    |> redirect(to: verification_path())
  end

  defp render_entry(conn, assigns) do
    render(conn, :index, base_assigns(assigns))
  end

  defp render_review(conn, pending, account_subject) do
    render(
      conn,
      :index,
      base_assigns(
        review_step?: true,
        user_code: pending.user_code,
        verification_handle: pending.verification_handle,
        client_name: pending.client_name,
        scopes: pending.scopes,
        account_subject: account_subject
      )
    )
  end

  defp base_assigns(extra) do
    Keyword.merge(
      [
        page_title: "Verify your device",
        review_step?: false,
        user_code: "",
        verification_handle: nil,
        client_name: nil,
        scopes: [],
        account_subject: nil,
        error_message: nil
      ],
      extra
    )
  end

  defp resolve_actor_context(conn, verification_handle) do
    resolver = Lockspire.account_resolver!()

    context = %{
      return_to: verification_path(),
      verification_handle: verification_handle
    }

    case resolver.resolve_current_account(conn, context) do
      {:ok, account} ->
        case resolver.build_claims(account, context) do
          {:ok, %Claims{} = claims} ->
            {:ok, %{subject_id: claims.subject}}

          {:error, reason} ->
            {:error, reason}
        end

      {:redirect, %InteractionResult{} = result} ->
        {:redirect, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp current_account_subject(conn) do
    resolver = Lockspire.account_resolver!()
    context = %{return_to: verification_path()}

    case resolver.resolve_current_account(conn, context) do
      {:ok, account} ->
        case resolver.build_claims(account, context) do
          {:ok, %Claims{} = claims} -> claims.subject
          {:error, _reason} -> nil
        end

      _ ->
        nil
    end
  end

  # Keep invalid or expired code responses neutral so the page does not become an oracle.
  defp invalid_or_expired_message do
    "We couldn't verify that code. Check the code on your device and try again, or restart the sign-in flow to get a new code."
  end

  defp redirect_destination(%InteractionResult{} = result) do
    result.login_path
    |> append_query_param("return_to", result.return_to)
    |> append_query_params(result.params)
  end

  defp append_query_params(path, params) when is_map(params) do
    Enum.reduce(params, path, fn {key, value}, acc ->
      append_query_param(acc, key, value)
    end)
  end

  defp append_query_param(path, _key, nil), do: path
  defp append_query_param(path, _key, ""), do: path

  defp append_query_param(path, key, value) do
    separator = if String.contains?(path, "?"), do: "&", else: "?"
    path <> separator <> URI.encode_query(%{to_string(key) => value})
  end

  defp verification_path, do: "/verify"

  defp protocol_opts do
    []
  end
end
