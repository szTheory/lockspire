defmodule Lockspire.Host.RarTypeValidatorTest do
  use ExUnit.Case, async: true

  test "behaviour module declares validate/2 callback" do
    callbacks = Lockspire.Host.RarTypeValidator.behaviour_info(:callbacks)
    assert {:validate, 2} in callbacks
  end

  test "moduledoc documents configuration and error helper" do
    {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} =
      Code.fetch_docs(Lockspire.Host.RarTypeValidator)

    assert moduledoc =~ ":rar_validators"
    assert moduledoc =~ "Lockspire.RAR.error_description/1"
  end
end
