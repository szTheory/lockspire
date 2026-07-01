defmodule Lockspire.TestRepo.Migrations.AddMtlsAttributesToClients do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:tls_client_auth_subject_dn, :string)
      add(:tls_client_auth_san_dns, :string)
      add(:tls_client_auth_san_uri, :string)
      add(:tls_client_auth_san_ip, :string)
      add(:tls_client_auth_san_email, :string)
    end
  end
end
