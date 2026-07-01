defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddRarIntakeState do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_pushed_authorization_requests) do
      add(:authorization_details, {:array, :map}, default: [])
    end

    alter lockspire_table(:lockspire_interactions) do
      add(:authorization_details, {:array, :map}, default: [])
    end
  end
end
