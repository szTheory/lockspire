defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddRarIntakeState do
  use Ecto.Migration

  def change do
    alter table(:lockspire_pushed_authorization_requests) do
      add(:authorization_details, {:array, :map}, default: [])
    end

    alter table(:lockspire_interactions) do
      add(:authorization_details, {:array, :map}, default: [])
    end
  end
end
