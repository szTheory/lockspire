defmodule Lockspire.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :lockspire,
    adapter: Ecto.Adapters.Postgres

  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  @spec get_server_policy() :: {:ok, ServerPolicy.t()} | {:error, term()}
  def get_server_policy do
    Repository.get_server_policy()
  end

  @spec put_server_policy(ServerPolicy.t()) :: {:ok, ServerPolicy.t()} | {:error, term()}
  def put_server_policy(%ServerPolicy{} = policy) do
    Repository.put_server_policy(policy)
  end

  @spec update_server_policy((ServerPolicy.t() -> ServerPolicy.t())) ::
          {:ok, ServerPolicy.t()} | {:error, term()}
  def update_server_policy(mutator) when is_function(mutator, 1) do
    Repository.update_server_policy(mutator)
  end

  @spec record_dpop_proof(DpopReplay.t()) :: {:ok, :accepted | :replay} | {:error, term()}
  def record_dpop_proof(%DpopReplay{} = replay) do
    Repository.record_dpop_proof(replay)
  end
end
