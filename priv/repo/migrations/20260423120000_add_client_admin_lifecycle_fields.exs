defmodule Lockspire.TestRepo.Migrations.AddClientAdminLifecycleFields do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add(:active, :boolean, null: false, default: true)
      add(:disabled_at, :utc_datetime_usec)
      add(:disabled_by, :text)
      add(:last_secret_rotated_at, :utc_datetime_usec)
    end

    create(index(:lockspire_clients, [:active]))
  end
end
