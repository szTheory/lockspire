defmodule Lockspire.Domain.LogoutEvent do
  @moduledoc """
  Durable protocol-owned logout event state.
  """

  @type initiated_by :: :rp_initiated_logout

  @type t :: %__MODULE__{
          id: integer() | nil,
          event_id: String.t() | nil,
          sid: String.t() | nil,
          account_id: String.t() | nil,
          subject: String.t() | nil,
          initiated_by: initiated_by(),
          post_logout_redirect_uri: String.t() | nil,
          frontchannel_continue_to: String.t() | nil,
          completed_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :event_id,
    :sid,
    :account_id,
    :subject,
    :post_logout_redirect_uri,
    :frontchannel_continue_to,
    :completed_at,
    :inserted_at,
    :updated_at,
    initiated_by: :rp_initiated_logout
  ]
end
