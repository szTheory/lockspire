defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddResourceIndicatorsState do
  use Ecto.Migration

  def change do
    alter table(:lockspire_interactions) do
      add(:resources_requested, {:array, :string}, default: [])
    end

    alter table(:lockspire_pushed_authorization_requests) do
      add(:resources_requested, {:array, :string}, default: [])
    end
  end
end
