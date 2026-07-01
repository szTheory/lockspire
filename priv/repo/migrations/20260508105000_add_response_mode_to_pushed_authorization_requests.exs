defmodule Lockspire.TestRepo.Migrations.AddResponseModeToPushedAuthorizationRequests do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_pushed_authorization_requests) do
      add(:response_mode, :string)
    end
  end
end
