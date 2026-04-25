defmodule Lockspire.Domain.ServerPolicy do
  @moduledoc """
  Durable server-wide operator policy owned by Lockspire.
  """

  @type par_policy :: :optional | :required

  @type t :: %__MODULE__{
          id: integer() | nil,
          par_policy: par_policy(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            par_policy: :optional,
            inserted_at: nil,
            updated_at: nil
end
