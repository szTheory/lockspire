defmodule Lockspire.Storage.UsedJtiStore do
  @moduledoc """
  Behavior for tracking and verifying used JTIs to prevent replay attacks.
  """

  alias Lockspire.Domain.UsedJti

  @doc """
  Records a JTI as used. Returns `{:ok, :accepted}` if successfully recorded,
  or `{:ok, :replay}` if the JTI for this client_id has already been recorded.
  """
  @callback record_used_jti(UsedJti.t()) :: {:ok, :accepted | :replay} | {:error, term()}
end
