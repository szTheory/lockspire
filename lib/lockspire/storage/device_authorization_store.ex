defmodule Lockspire.Storage.DeviceAuthorizationStore do
  @moduledoc """
  Behaviour for storing and managing OAuth 2.0 Device Authorizations.
  """

  alias Lockspire.Domain.DeviceAuthorization

  @type device_poll_result ::
    :approved_ready
    | :client_mismatch
    | :consumed
    | :denied
    | :expired
          | :invalid_grant
          | :pending
          | :slow_down

  @type device_poll_outcome :: %{
          required(:result) => device_poll_result(),
          optional(:device_authorization) => DeviceAuthorization.t(),
          optional(:effective_poll_interval_seconds) => pos_integer(),
          optional(:next_poll_allowed_at) => DateTime.t()
        }

  @callback put_device_authorization(DeviceAuthorization.t()) ::
              {:ok, DeviceAuthorization.t()} | {:error, term()}

  @callback fetch_device_authorization_by_user_code_hash(String.t()) ::
              {:ok, DeviceAuthorization.t() | nil} | {:error, term()}

  @callback fetch_device_authorization_by_device_code_hash(String.t()) ::
              {:ok, DeviceAuthorization.t() | nil} | {:error, term()}

  @callback fetch_device_authorization_by_verification_handle(String.t()) ::
              {:ok, DeviceAuthorization.t() | nil} | {:error, term()}

  @callback transition_device_authorization(
              String.t(),
              [DeviceAuthorization.status()],
              map()
            ) ::
              {:ok, DeviceAuthorization.t()} | {:error, term()}

  @callback record_device_poll(String.t(), String.t(), DateTime.t()) ::
              {:ok, device_poll_outcome()} | {:error, term()}

  @callback consume_device_authorization(String.t(), String.t(), DateTime.t()) ::
              {:ok, DeviceAuthorization.t()} | {:error, :invalid_state | term()}
end
