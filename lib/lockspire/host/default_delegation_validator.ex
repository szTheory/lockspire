defmodule Lockspire.Host.DefaultDelegationValidator do
  @moduledoc """
  A default implementation of `Lockspire.Host.TokenExchangeValidator` that properly structures
  the `act` (actor) claim when delegating tokens according to RFC 8693.
  """

  @behaviour Lockspire.Host.TokenExchangeValidator

  alias Lockspire.Host.TokenExchangeContext

  @impl true
  def validate(%TokenExchangeContext{actor_token: nil}), do: :ok

  def validate(%TokenExchangeContext{actor_token: actor_token}) when is_map(actor_token) do
    act = build_act_claim(actor_token)

    if act == %{} do
      :ok
    else
      {:ok, %{claims: %{"act" => act}}}
    end
  end

  def validate(_), do: :ok

  defp build_act_claim(actor_token) do
    act = %{}

    act =
      if sub = Map.get(actor_token, "sub") do
        Map.put(act, "sub", sub)
      else
        act
      end

    act =
      if client_id = Map.get(actor_token, "client_id") do
        Map.put(act, "client_id", client_id)
      else
        act
      end

    act =
      if nested_act = Map.get(actor_token, "act") do
        Map.put(act, "act", nested_act)
      else
        act
      end

    act
  end
end
