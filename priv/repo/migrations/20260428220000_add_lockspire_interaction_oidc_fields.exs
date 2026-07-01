defmodule Lockspire.Repo.Migrations.AddLockspireInteractionOidcFields do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_interactions) do
      add(:auth_time, :utc_datetime_usec)
      add(:max_age, :integer)
      add(:auth_time_requested, :boolean, null: false, default: false)
    end
  end
end
