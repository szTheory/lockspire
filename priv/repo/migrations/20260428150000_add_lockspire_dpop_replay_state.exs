defmodule Lockspire.TestRepo.Migrations.AddLockspireDpopReplayState do
  use Lockspire.Storage.Ecto.Migration

  def change do
    create lockspire_table(:lockspire_dpop_replay) do
      add(:replay_key, :string, null: false)
      add(:jti, :string, null: false)
      add(:htm, :string, null: false)
      add(:htu, :text, null: false)
      add(:jkt, :string, null: false)
      add(:seen_at, :utc_datetime_usec, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(lockspire_unique_index(:lockspire_dpop_replay, [:replay_key]))
    create(lockspire_index(:lockspire_dpop_replay, [:expires_at]))
  end
end
