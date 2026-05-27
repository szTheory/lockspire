defmodule AdoptionDemo.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :adoption_demo,
    adapter: Ecto.Adapters.Postgres

  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  def get_server_policy do
    Repository.get_server_policy()
  end

  def put_server_policy(%ServerPolicy{} = policy) do
    Repository.put_server_policy(policy)
  end

  def update_server_policy(mutator) when is_function(mutator, 1) do
    Repository.update_server_policy(mutator)
  end

  def record_dpop_proof(%DpopReplay{} = replay) do
    Repository.record_dpop_proof(replay)
  end
end
