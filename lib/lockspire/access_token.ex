defmodule Lockspire.AccessToken do
  @moduledoc """
  Encapsulates the state of an access token throughout the validation plug pipeline.
  """

  defstruct [
    :token,
    :claims,
    :client_id,
    :authorization_scheme,
    :binding_type,
    :binding_requirements,
    :error
  ]

  @type t :: %__MODULE__{
          token: String.t() | nil,
          claims: map() | nil,
          client_id: String.t() | nil,
          authorization_scheme: String.t() | nil,
          binding_type: String.t() | nil,
          binding_requirements: %{
            optional(:dpop_jkt) => String.t(),
            optional(:mtls_x5t_s256) => String.t()
          } | nil,
          error: term()
        }
end
