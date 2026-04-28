defmodule Lockspire.Storage.DeviceAuthorizationStore do
  @moduledoc """
  Behaviour for storing and managing OAuth 2.0 Device Authorizations.
  """

  alias Lockspire.Domain.DeviceAuthorization

  @callback put_device_authorization(DeviceAuthorization.t()) ::
              {:ok, DeviceAuthorization.t()} | {:error, term()}

  @callback fetch_device_authorization_by_user_code_hash(String.t()) ::
              {:ok, DeviceAuthorization.t() | nil} | {:error, term()}

  @callback fetch_device_authorization_by_verification_handle(String.t()) ::
              {:ok, DeviceAuthorization.t() | nil} | {:error, term()}

  @callback transition_device_authorization(
              String.t(),
              [DeviceAuthorization.status()],
              map()
            ) ::
              {:ok, DeviceAuthorization.t()} | {:error, term()}
end
