defmodule Lockspire.RedactionTest do
  use ExUnit.Case, async: true

  describe "for_telemetry/1 — Phase 26 DCR drop list extension" do
    test "drops :registration_access_token (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{registration_access_token: "secret_rat", a: 1}) == %{a: 1}
    end

    test ~s|drops "registration_access_token" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{"registration_access_token" => "secret_rat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :initial_access_token (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{initial_access_token: "secret_iat", a: 1}) == %{a: 1}
    end

    test ~s|drops "initial_access_token" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{"initial_access_token" => "secret_iat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :rat (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{rat: "secret_rat", a: 1}) == %{a: 1}
    end

    test ~s|drops "rat" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{"rat" => "secret_rat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :iat (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{iat: "secret_iat", a: 1}) == %{a: 1}
    end

    test ~s|drops "iat" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{"iat" => "secret_iat", "a" => 1}) == %{"a" => 1}
    end
  end

  describe "for_audit/1 — Phase 26 DCR drop list extension" do
    test "drops :registration_access_token (atom)" do
      assert Lockspire.Redaction.for_audit(%{registration_access_token: "secret_rat", a: 1}) == %{a: 1}
    end

    test ~s|drops "registration_access_token" (string)| do
      assert Lockspire.Redaction.for_audit(%{"registration_access_token" => "secret_rat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :initial_access_token (atom)" do
      assert Lockspire.Redaction.for_audit(%{initial_access_token: "secret_iat", a: 1}) == %{a: 1}
    end

    test ~s|drops "initial_access_token" (string)| do
      assert Lockspire.Redaction.for_audit(%{"initial_access_token" => "secret_iat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :rat (atom)" do
      assert Lockspire.Redaction.for_audit(%{rat: "secret_rat", a: 1}) == %{a: 1}
    end

    test ~s|drops "rat" (string)| do
      assert Lockspire.Redaction.for_audit(%{"rat" => "secret_rat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :iat (atom)" do
      assert Lockspire.Redaction.for_audit(%{iat: "secret_iat", a: 1}) == %{a: 1}
    end

    test ~s|drops "iat" (string)| do
      assert Lockspire.Redaction.for_audit(%{"iat" => "secret_iat", "a" => 1}) == %{"a" => 1}
    end
  end
end
