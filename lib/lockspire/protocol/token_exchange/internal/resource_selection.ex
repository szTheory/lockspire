defmodule Lockspire.Protocol.TokenExchange.Internal.ResourceSelection do
  @moduledoc false

  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenResult.Error

  @spec select(map(), Token.t()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def select(params, %Token{} = grant), do: select(params, grant, allow_unbounded?: false)

  @spec select_grant(map(), Token.t()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def select_grant(params, %Token{} = grant), do: select(params, grant, allow_unbounded?: true)

  defp select(params, %Token{audience: authorized}, options) do
    requested =
      params
      |> Map.get("resource")
      |> List.wrap()
      |> Enum.flat_map(fn
        resource when is_binary(resource) -> [resource]
        _ -> []
      end)

    cond do
      requested == [] ->
        {:ok, authorized}

      authorized == [] and options[:allow_unbounded?] ->
        {:ok, requested}

      Enum.all?(requested, &(&1 in authorized)) ->
        {:ok, requested}

      true ->
        {:error,
         %Error{
           status: 400,
           error: "invalid_target",
           error_description: "The requested resource is invalid or was not authorized",
           reason_code: :invalid_resource
         }}
    end
  end
end
