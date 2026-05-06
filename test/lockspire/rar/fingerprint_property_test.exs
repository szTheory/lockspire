defmodule Lockspire.RAR.FingerprintPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "is invariant under map key ordering" do
    check all(
            type <- StreamData.string(:alphanumeric, min_length: 1),
            action_a <- StreamData.string(:alphanumeric, min_length: 1),
            action_b <- StreamData.string(:alphanumeric, min_length: 1)
          ) do
      left = [
        %{
          "type" => type,
          "actions" => [action_a, action_b],
          "instructedAmount" => %{"currency" => "EUR", "amount" => "12.99"}
        }
      ]

      right = [
        %{
          "instructedAmount" => %{"amount" => "12.99", "currency" => "EUR"},
          "actions" => [action_a, action_b],
          "type" => type
        }
      ]

      assert Lockspire.RAR.Fingerprint.compute(left) == Lockspire.RAR.Fingerprint.compute(right)
    end
  end
end
