defmodule Lockspire.RARTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset

  test "error_description/1 formats changeset errors" do
    changeset =
      {%{}, %{type: :string, amount: :integer}}
      |> cast(%{"type" => "", "amount" => 0}, [:type, :amount])
      |> validate_required([:type, :amount])
      |> validate_length(:type, min: 1)
      |> validate_number(:amount, greater_than: 0)

    description = Lockspire.RAR.error_description(changeset)

    assert description =~ "type:"
    assert description =~ "amount:"
  end

  test "error_description/1 passes string errors through" do
    assert Lockspire.RAR.error_description("plain error") == "plain error"
  end
end
