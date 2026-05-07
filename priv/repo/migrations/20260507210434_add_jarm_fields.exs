defmodule Lockspire.TestRepo.Migrations.AddJarmFields do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add :authorization_signed_response_alg, :string
    end

    alter table(:lockspire_interactions) do
      add :response_mode, :string
    end
  end
end
