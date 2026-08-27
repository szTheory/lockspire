defmodule Lockspire.Protocol.TokenExchange.GrantSupport do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Internal.GrantSupport, as: Internal
  alias Lockspire.Protocol.TokenResult

  def handle_code_exchange(client, code, code_hash, params, context, request),
    do:
      Internal.handle_code_exchange(client, code, code_hash, params, context, request)
      |> to_public_result()

  def authenticate_client(params, authorization, request),
    do: Internal.authenticate_client(params, authorization, request) |> to_public_result()

  def fetch_authorization_code(params, request),
    do: Internal.fetch_authorization_code(params, request) |> to_public_result()

  def fetch_device_authorization_for_exchange(params, %Client{} = client, request),
    do:
      Internal.fetch_device_authorization_for_exchange(params, client, request)
      |> to_public_result()

  def fetch_ciba_authorization_for_exchange(params, %Client{} = client, request),
    do:
      Internal.fetch_ciba_authorization_for_exchange(params, client, request)
      |> to_public_result()

  def validate_grant_resources_for_test(params, %Token{} = grant),
    do: Internal.validate_grant_resources_for_test(params, grant) |> to_public_result()

  def redeem_device_authorization(
        %Client{} = client,
        %DeviceAuthorization{} = authorization,
        context,
        request
      ),
      do:
        Internal.redeem_device_authorization(client, authorization, context, request)
        |> to_public_result()

  def redeem_ciba_authorization(
        %Client{} = client,
        %CibaAuthorization{} = authorization,
        context,
        request
      ),
      do:
        Internal.redeem_ciba_authorization(client, authorization, context, request)
        |> to_public_result()

  def emit_failure(%Error{} = error, params, request),
    do: Internal.emit_failure(Compatibility.to_neutral(error), params, request)

  defp to_public_result({:ok, %TokenResult.Success{} = success}),
    do: {:ok, Compatibility.to_public(success)}

  defp to_public_result({:error, %TokenResult.Error{} = error}),
    do: {:error, Compatibility.to_public(error)}

  defp to_public_result({:error, %TokenResult.Error{} = error, first, second}),
    do: {:error, Compatibility.to_public(error), first, second}

  defp to_public_result(other), do: other
end
