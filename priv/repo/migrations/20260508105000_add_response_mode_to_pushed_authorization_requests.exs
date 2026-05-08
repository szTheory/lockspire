defmodule Lockspire.TestRepo.Migrations.AddResponseModeToPushedAuthorizationRequests do
  use Ecto.Migration

  def change do
    alter table(:lockspire_pushed_authorization_requests) do
      add :response_mode, :string
    end
  end
end
