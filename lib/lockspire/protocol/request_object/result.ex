defmodule Lockspire.Protocol.RequestObject.Result do
  @moduledoc false

  @type disposition :: :browser_error | :redirect_error

  @type t :: %__MODULE__{
          disposition: disposition(),
          error: String.t(),
          error_description: String.t(),
          reason_code: atom(),
          state: String.t() | nil,
          redirect_uri: String.t() | nil
        }

  defstruct [
    :error,
    :error_description,
    :reason_code,
    :state,
    :redirect_uri,
    disposition: :browser_error
  ]

  @spec browser_error(String.t() | atom(), String.t(), atom()) :: t()
  def browser_error(error, description, reason_code) do
    %__MODULE__{
      error: to_string(error),
      error_description: description,
      reason_code: reason_code,
      state: nil,
      redirect_uri: nil,
      disposition: :browser_error
    }
  end
end
