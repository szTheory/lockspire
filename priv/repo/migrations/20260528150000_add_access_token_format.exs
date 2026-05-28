defmodule Lockspire.TestRepo.Migrations.AddAccessTokenFormat do
  use Ecto.Migration

  def change do
    # D-06: per-client override is NULLABLE with no default — nil = inherit the
    # server-wide default. Pitfall 6: the :text column pairs with the Ecto.Enum
    # field added on ClientRecord so :jwt/:opaque persist/load as "jwt"/"opaque".
    alter table(:lockspire_clients) do
      add :access_token_format, :text
    end

    # D-04: server-wide default flips to JWT. null: false + default: "jwt" backfills
    # the existing @singleton_id 1 row to "jwt" via the column default (no row rewrite).
    alter table(:lockspire_server_policies) do
      add :access_token_format, :text, null: false, default: "jwt"
    end
  end
end
