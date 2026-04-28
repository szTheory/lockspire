defmodule Lockspire.Storage.DpopReplayStore do
  @moduledoc """
  Domain-level persistence contract for DPoP replay detection state.
  """

  alias Lockspire.Domain.DpopReplay

  @type record_result :: :accepted | :replay
  @type store_error :: term()

  @callback record_dpop_proof(DpopReplay.t()) ::
              {:ok, record_result()} | {:error, store_error()}
end
