defmodule Lockspire.Storage.CibaAuthorizationStore do
  @moduledoc """
  Behaviour for storing and managing CIBA Authorizations.
  """

  alias Lockspire.Domain.CibaAuthorization

  @type ciba_poll_result ::
          :approved_ready
          | :client_mismatch
          | :consumed
          | :denied
          | :expired
          | :invalid_grant
          | :pending
          | :slow_down

  @type ciba_poll_outcome :: %{
          required(:result) => ciba_poll_result(),
          optional(:ciba_authorization) => CibaAuthorization.t(),
          optional(:effective_poll_interval_seconds) => pos_integer(),
          optional(:next_poll_allowed_at) => DateTime.t()
        }

  @callback put_ciba_authorization(CibaAuthorization.t()) ::
              {:ok, CibaAuthorization.t()} | {:error, term()}

  @callback fetch_ciba_authorization_by_auth_req_id_hash(String.t()) ::
              {:ok, CibaAuthorization.t() | nil} | {:error, term()}

  @callback transition_ciba_authorization(
              String.t(),
              [CibaAuthorization.status()],
              map()
            ) ::
              {:ok, CibaAuthorization.t()} | {:error, term()}

  @callback record_ciba_poll(String.t(), String.t(), DateTime.t()) ::
              {:ok, ciba_poll_outcome()} | {:error, term()}
end
