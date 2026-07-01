defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddResourceIndicatorsState do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_interactions) do
      add(:resources_requested, {:array, :string}, default: [])
    end

    alter lockspire_table(:lockspire_pushed_authorization_requests) do
      add(:resources_requested, {:array, :string}, default: [])
    end
  end
end
