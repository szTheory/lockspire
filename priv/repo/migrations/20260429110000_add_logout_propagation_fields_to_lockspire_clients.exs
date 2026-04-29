defmodule Lockspire.TestRepo.Migrations.AddLogoutPropagationFieldsToLockspireClientsCompat do
  use Ecto.Migration

  # Phase 39-02 already shipped the client logout columns under
  # 20260429193000_add_logout_propagation_fields_to_lockspire_clients.exs.
  # Keep this earlier plan-owned migration version as a compatibility no-op so
  # already-migrated and fresh databases both converge without duplicate-column
  # failures.
  def up, do: :ok

  def down, do: :ok
end
