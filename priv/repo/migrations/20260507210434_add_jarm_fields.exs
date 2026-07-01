defmodule Lockspire.TestRepo.Migrations.AddJarmFields do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:authorization_signed_response_alg, :string)
    end

    alter lockspire_table(:lockspire_interactions) do
      add(:response_mode, :string)
    end
  end
end
