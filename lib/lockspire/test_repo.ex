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

  # Delegated so AccessTokenSigner can fetch the active signing key when a grant
  # path passes no explicit :key_store and falls back to Config.repo!() (e.g. the
  # CIBA Push delivery worker, which issues tokens with request == %{}). The JWT
  # default (Phase 99) makes this lookup load-bearing on those worker paths.
  @spec fetch_active_signing_key(keyword()) :: {:ok, map() | nil} | {:error, term()}
  def fetch_active_signing_key(opts \\ []) do
    Repository.fetch_active_signing_key(opts)
  end
end
