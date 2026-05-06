defmodule Lockspire.Host.BackchannelNotification do
  @moduledoc """
  Behaviour for triggering out-of-band notifications to users during CIBA flows.
  """

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Host.Context

  @type context :: Context.t()

  @doc """
  Invoked after a backchannel authentication request is successfully initiated.

  The host application should use this callback to trigger an out-of-band
  notification (e.g., push notification, SMS, email) to the user associated
  with the `subject_id` in the `ciba_authorization`.

  The `binding_message` from the authorization should be displayed to the
  user if provided.
  """
  @callback notify_authentication(ciba_authorization :: CibaAuthorization.t(), context()) ::
              :ok | {:error, term()}
end
