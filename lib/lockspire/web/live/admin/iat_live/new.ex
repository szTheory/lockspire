defmodule Lockspire.Web.Live.Admin.IatLive.New do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin.InitialAccessTokens

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Mint Initial Access Token",
       current_section: :iats,
       iat_secret: nil,
       form: to_form(%{"single_use" => "true", "expires_in_days" => "30"})
     )}
  end

  @impl true
  def handle_event("mint", %{"single_use" => single_use, "expires_in_days" => days}, socket) do
    attrs = %{
      single_use: single_use == "true",
      expires_at: days_from_now(days),
      created_by: "operator"
    }

    case InitialAccessTokens.mint_iat(attrs) do
      {:ok, _iat, plaintext_secret} ->
        {:noreply,
         socket
         |> put_flash(:info, "IAT minted successfully.")
         |> assign(iat_secret: plaintext_secret)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to mint IAT.")}
    end
  end

  @impl true
  def handle_event("acknowledge_copy", _params, socket) do
    {:noreply, assign(socket, iat_secret: nil)}
  end

  defp days_from_now(days_str) do
    case Integer.parse(days_str) do
      {days, ""} when days > 0 -> DateTime.add(DateTime.utc_now(), days, :day)
      _ -> nil
    end
  end

  def iat_index_path, do: Lockspire.mount_path() <> "/admin/iats"
end
