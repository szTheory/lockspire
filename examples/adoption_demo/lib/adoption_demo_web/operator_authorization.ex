defmodule AdoptionDemoWeb.OperatorAuthorization do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias AdoptionDemo.Accounts
  alias AdoptionDemoWeb.Plugs.RequireOperator

  def on_mount(:default, _params, session, socket) do
    case current_operator(session) do
      nil ->
        {:halt, Phoenix.LiveView.redirect(socket, to: login_path())}

      account ->
        socket =
          socket
          |> assign(:current_account, account)
          |> Phoenix.LiveView.attach_hook(
            :adoption_demo_operator_authorization,
            :handle_params,
            fn params, uri, socket -> authorize_params(session, params, uri, socket) end
          )

        {:cont, socket}
    end
  end

  defp authorize_params(session, _params, _uri, socket) do
    case current_operator(session) do
      nil -> {:halt, Phoenix.LiveView.redirect(socket, to: login_path())}
      account -> {:cont, assign(socket, :current_account, account)}
    end
  end

  defp current_operator(%{"demo_login" => login}) when is_binary(login) do
    case Accounts.get(login) do
      account when is_map(account) ->
        if RequireOperator.operator_account?(account), do: account

      _other ->
        nil
    end
  end

  defp current_operator(_session), do: nil

  defp login_path do
    "/login?" <> URI.encode_query(%{"return_to" => "/lockspire/admin"})
  end
end
