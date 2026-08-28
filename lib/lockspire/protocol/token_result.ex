defmodule Lockspire.Protocol.TokenResult do
  @moduledoc false

  defmodule Success do
    @moduledoc false

    @type t :: %__MODULE__{
            access_token: String.t(),
            refresh_token: String.t() | nil,
            id_token: String.t() | nil,
            token_type: String.t(),
            issued_token_type: String.t() | nil,
            expires_in: pos_integer(),
            scope: String.t()
          }

    defstruct [
      :access_token,
      :refresh_token,
      :id_token,
      :token_type,
      :issued_token_type,
      :expires_in,
      :scope
    ]
  end

  defmodule Error do
    @moduledoc false

    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom(),
            dpop_nonce: String.t() | nil
          }

    defstruct [:status, :error, :error_description, :reason_code, :dpop_nonce]
  end
end
