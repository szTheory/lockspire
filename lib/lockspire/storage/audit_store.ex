defmodule Lockspire.Storage.AuditStore do
  @moduledoc """
  Narrow audit append capability for transactional domain operations.
  """

  alias Lockspire.Audit.Event

  @type store_error :: term()

  @callback append_audit_event(Event.t() | map()) :: {:ok, Event.t()} | {:error, store_error()}
  @callback transact_with_audit(Event.t() | map(), (-> term())) ::
              {:ok, term()} | {:error, store_error()}
end
