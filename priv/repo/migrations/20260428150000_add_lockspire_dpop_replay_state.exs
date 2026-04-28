defmodule Lockspire.TestRepo.Migrations.AddLockspireDpopReplayState do
  use Ecto.Migration

  def change do
    create table(:lockspire_dpop_replay) do
      add :replay_key, :string, null: false
      add :jti, :string, null: false
      add :htm, :string, null: false
      add :htu, :text, null: false
      add :jkt, :string, null: false
      add :seen_at, :utc_datetime_usec, null: false
      add :expires_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_dpop_replay, [:replay_key])
    create index(:lockspire_dpop_replay, [:expires_at])
  end
end
