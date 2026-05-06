defmodule Lockspire.Host.RarTypeValidator do
  @moduledoc """
  Behaviour for validating a single Rich Authorization Request detail object
  for one specific `type` value.

  Hosts register validators via:

      config :lockspire, :rar_validators, %{
        "payment_initiation" => MyApp.RAR.PaymentInitiation,
        "account_information" => MyApp.RAR.AccountInformation
      }

  The map keys are the single source of truth for supported types.

  Each callback receives one decoded detail map and a minimal request context.
  Validators return `{:ok, normalized_map}` to admit the detail or `{:error, ...}`
  to reject it. Errors may be either an `Ecto.Changeset.t()` or a binary
  description. Changesets are formatted through `Lockspire.RAR.error_description/1`.
  """

  @callback validate(detail :: map(), ctx :: map()) ::
              {:ok, map()} | {:error, Ecto.Changeset.t() | String.t()}
end
