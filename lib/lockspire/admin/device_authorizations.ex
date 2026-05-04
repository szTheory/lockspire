defmodule Lockspire.Admin.DeviceAuthorizations do
  @moduledoc """
  Query boundary for operator-managed Device Authorizations.
  """

  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Storage.Ecto.Repository

  @spec list_device_authorizations(keyword()) :: {:ok, [DeviceAuthorization.t()]} | {:error, term()}
  def list_device_authorizations(opts \\ []) do
    Repository.list_device_authorizations(opts)
  end
end
