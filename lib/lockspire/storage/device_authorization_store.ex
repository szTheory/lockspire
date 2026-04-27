defmodule Lockspire.Storage.DeviceAuthorizationStore do
  @moduledoc """
  Behaviour for storing and managing OAuth 2.0 Device Authorizations.
  """

  alias Lockspire.Domain.DeviceAuthorization

  @callback put_device_authorization(DeviceAuthorization.t()) ::
              {:ok, DeviceAuthorization.t()} | {:error, term()}
end
