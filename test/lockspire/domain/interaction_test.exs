defmodule Lockspire.Domain.InteractionTest do
  use ExUnit.Case, async: true
  alias Lockspire.Domain.Interaction

  test "Interaction struct supports response_mode" do
    interaction = %Interaction{response_mode: "query.jwt"}
    assert interaction.response_mode == "query.jwt"
  end
end
