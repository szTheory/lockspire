defmodule Lockspire.Web.Live.Admin.IatLive.New do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin.InitialAccessTokens

  @invalid_expiry_error "Enter a whole number of days greater than zero."
  @mint_failure_error "Initial access token could not be minted. Check the expiry and try again."

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Mint Initial Access Token",
       current_section: :dcr,
       iat_secret: nil,
       iat_acknowledged?: false,
       form: to_form(default_form_params()),
       form_errors: [],
       expiry_error: nil
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     assign(socket,
       iat_secret: nil,
       iat_acknowledged?: false,
       form: to_form(default_form_params()),
       form_errors: [],
       expiry_error: nil
     )}
  end

  @impl true
  def handle_event("mint", _params, %{assigns: %{iat_secret: secret}} = socket)
      when is_binary(secret) and byte_size(secret) > 0 do
    {:noreply, socket}
  end

  def handle_event("mint", params, socket) when is_map(params) do
    safe_params = safe_form_params(params)

    case expiry_at(Map.get(safe_params, "expires_in_days")) do
      {:ok, expires_at} ->
        attrs = %{
          single_use: true,
          expires_at: expires_at,
          created_by: "operator"
        }

        case safely_mint_iat(attrs) do
          {:ok, _iat, plaintext_secret} ->
            {:noreply,
             assign(socket,
               iat_secret: plaintext_secret,
               iat_acknowledged?: false,
               form_errors: [],
               expiry_error: nil
             )}

          {:error, _reason} ->
            {:noreply,
             assign(socket,
               iat_secret: nil,
               iat_acknowledged?: false,
               form: to_form(safe_params),
               form_errors: [%{message: @mint_failure_error}],
               expiry_error: nil
             )}
        end

      :error ->
        {:noreply,
         assign(socket,
           iat_secret: nil,
           iat_acknowledged?: false,
           form: to_form(safe_params),
           form_errors: [%{message: @invalid_expiry_error}],
           expiry_error: @invalid_expiry_error
         )}
    end
  end

  def handle_event("mint", _params, socket) do
    {:noreply,
     assign(socket,
       iat_secret: nil,
       form: to_form(default_form_params()),
       form_errors: [%{message: @invalid_expiry_error}],
       expiry_error: @invalid_expiry_error
     )}
  end

  @impl true
  def handle_event("acknowledge_copy", _params, socket) do
    {:noreply, assign(socket, iat_secret: nil, iat_acknowledged?: true)}
  end

  defp expiry_at(days_str) when is_binary(days_str) do
    case Integer.parse(days_str) do
      {days, ""} when days > 0 ->
        {:ok, DateTime.add(DateTime.utc_now(), days, :day)}

      _ ->
        :error
    end
  rescue
    ArgumentError -> :error
  end

  defp expiry_at(_days_str), do: :error

  defp safely_mint_iat(attrs) do
    InitialAccessTokens.mint_iat(attrs)
  rescue
    _exception -> {:error, :unavailable}
  catch
    _kind, _reason -> {:error, :unavailable}
  end

  defp safe_form_params(params) do
    expires_in_days = Map.get(params, "expires_in_days")

    %{"expires_in_days" => if(is_binary(expires_in_days), do: expires_in_days, else: "")}
  end

  defp default_form_params do
    %{"expires_in_days" => "30"}
  end

  defp expiry_describedby(nil), do: "iat_expires_in_days-help"

  defp expiry_describedby(_error),
    do: "iat_expires_in_days-help iat_expires_in_days-error"

  def iat_index_path, do: Lockspire.mount_path() <> "/admin/iats"
end
