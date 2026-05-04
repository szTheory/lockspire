defmodule Lockspire.Security.DeviceCodeTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.DeviceCode

  describe "generate_user_code/0" do
    test "returns an 8-character string" do
      code = DeviceCode.generate_user_code()
      assert String.length(code) == 8
    end

    test "composed only of characters from BCDFGHJKLMNPQRSTVWXZ" do
      code = DeviceCode.generate_user_code()
      assert Regex.match?(~r/^[BCDFGHJKLMNPQRSTVWXZ]+$/, code)
    end
  end

  describe "generate_device_code/0" do
    test "returns a high entropy string" do
      code1 = DeviceCode.generate_device_code()
      code2 = DeviceCode.generate_device_code()

      assert is_binary(code1)
      # 32 bytes base64 encoded is at least 43 chars
      assert String.length(code1) >= 43
      assert code1 != code2
    end
  end
end
