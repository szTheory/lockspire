defmodule Lockspire.Test.Rar.PassthroughValidator do
  @moduledoc false
  @behaviour Lockspire.Host.RarTypeValidator

  @impl true
  def validate(detail, _ctx) when is_map(detail), do: {:ok, detail}
end

defmodule Lockspire.Test.Rar.NormalizingValidator do
  @moduledoc false
  @behaviour Lockspire.Host.RarTypeValidator

  @impl true
  def validate(%{"type" => type} = detail, _ctx) when is_binary(type) do
    {:ok,
     %{
       "type" => type,
       "actions" => Map.get(detail, "actions", []),
       "validated" => true
     }}
  end
end

defmodule Lockspire.Test.Rar.StringErrorValidator do
  @moduledoc false
  @behaviour Lockspire.Host.RarTypeValidator

  @impl true
  def validate(_detail, _ctx), do: {:error, "validation failed for test"}
end

defmodule Lockspire.Test.Rar.ChangesetErrorValidator do
  @moduledoc false
  @behaviour Lockspire.Host.RarTypeValidator

  import Ecto.Changeset

  @types %{type: :string, amount: :integer}

  @impl true
  def validate(detail, _ctx) when is_map(detail) do
    changeset =
      {%{}, @types}
      |> cast(detail, Map.keys(@types))
      |> validate_required([:type, :amount])
      |> validate_number(:amount, greater_than: 0)

    case apply_action(changeset, :validate) do
      {:ok, normalized} -> {:ok, normalized}
      {:error, failed_changeset} -> {:error, failed_changeset}
    end
  end
end

defmodule Lockspire.Test.Rar.RaisingValidator do
  @moduledoc false
  @behaviour Lockspire.Host.RarTypeValidator

  @impl true
  def validate(_detail, _ctx), do: raise("validator exploded")
end
