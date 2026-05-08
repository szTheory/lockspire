defmodule Lockspire.Protocol.SecurityProfileTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Protocol.SecurityProfile.Resolved

  describe "resolve_effective_profile/2" do
    test "global :none and client :inherit returns effective :none with fapi_2_0_security? false" do
      server_policy = %ServerPolicy{security_profile: :none}
      client = %Client{security_profile: :inherit}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :none
      assert resolved.client_profile == :inherit
      assert resolved.effective_profile == :none
      assert resolved.fapi_2_0_security? == false
    end

    test "global :fapi_2_0_security and client :inherit returns effective :fapi_2_0_security with fapi_2_0_security? true" do
      server_policy = %ServerPolicy{security_profile: :fapi_2_0_security}
      client = %Client{security_profile: :inherit}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :fapi_2_0_security
      assert resolved.client_profile == :inherit
      assert resolved.effective_profile == :fapi_2_0_security
      assert resolved.fapi_2_0_security? == true
      assert resolved.fapi_2_0_message_signing? == false
    end

    test "global :fapi_2_0_message_signing and client :inherit returns effective strict mode" do
      server_policy = %ServerPolicy{security_profile: :fapi_2_0_message_signing}
      client = %Client{security_profile: :inherit}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :fapi_2_0_message_signing
      assert resolved.client_profile == :inherit
      assert resolved.effective_profile == :fapi_2_0_message_signing
      assert resolved.fapi_2_0_security? == true
      assert resolved.fapi_2_0_message_signing? == true
    end

    test "global :none and client :fapi_2_0_security returns effective :fapi_2_0_security (client opt-in)" do
      server_policy = %ServerPolicy{security_profile: :none}
      client = %Client{security_profile: :fapi_2_0_security}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :none
      assert resolved.client_profile == :fapi_2_0_security
      assert resolved.effective_profile == :fapi_2_0_security
      assert resolved.fapi_2_0_security? == true
      assert resolved.fapi_2_0_message_signing? == false
    end

    test "global :none and client :fapi_2_0_message_signing returns effective strict mode" do
      server_policy = %ServerPolicy{security_profile: :none}
      client = %Client{security_profile: :fapi_2_0_message_signing}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :none
      assert resolved.client_profile == :fapi_2_0_message_signing
      assert resolved.effective_profile == :fapi_2_0_message_signing
      assert resolved.fapi_2_0_security? == true
      assert resolved.fapi_2_0_message_signing? == true
    end

    test "global :fapi_2_0_security and client :none returns effective :none (mixed-mode escape hatch per D-01)" do
      server_policy = %ServerPolicy{security_profile: :fapi_2_0_security}
      client = %Client{security_profile: :none}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :fapi_2_0_security
      assert resolved.client_profile == :none
      assert resolved.effective_profile == :none
      assert resolved.fapi_2_0_security? == false
      assert resolved.fapi_2_0_message_signing? == false
    end

    test "global :fapi_2_0_message_signing and client :none returns effective :none" do
      server_policy = %ServerPolicy{security_profile: :fapi_2_0_message_signing}
      client = %Client{security_profile: :none}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :fapi_2_0_message_signing
      assert resolved.client_profile == :none
      assert resolved.effective_profile == :none
      assert resolved.fapi_2_0_security? == false
      assert resolved.fapi_2_0_message_signing? == false
    end

    test "client = nil (unauthenticated request) treats client_profile as :inherit" do
      server_policy = %ServerPolicy{security_profile: :fapi_2_0_security}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, nil)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :fapi_2_0_security
      assert resolved.client_profile == :inherit
      assert resolved.effective_profile == :fapi_2_0_security
      assert resolved.fapi_2_0_security? == true
    end

    test "plain map client with :fapi_2_0_security behaves like struct override" do
      server_policy = %ServerPolicy{security_profile: :none}
      client = %{security_profile: :fapi_2_0_security}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :none
      assert resolved.client_profile == :fapi_2_0_security
      assert resolved.effective_profile == :fapi_2_0_security
      assert resolved.fapi_2_0_security? == true
    end

    test "plain map client with :fapi_2_0_message_signing behaves like struct override" do
      server_policy = %ServerPolicy{security_profile: :none}
      client = %{security_profile: :fapi_2_0_message_signing}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert %Resolved{} = resolved
      assert resolved.global_profile == :none
      assert resolved.client_profile == :fapi_2_0_message_signing
      assert resolved.effective_profile == :fapi_2_0_message_signing
      assert resolved.fapi_2_0_security? == true
      assert resolved.fapi_2_0_message_signing? == true
    end

    test "plain map client with unknown key defaults client_profile to :inherit" do
      server_policy = %ServerPolicy{security_profile: :fapi_2_0_security}
      client = %{some_other_field: :value}

      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

      assert resolved.client_profile == :inherit
      assert resolved.effective_profile == :fapi_2_0_security
    end
  end

  describe "allowed_signing_algorithms/1" do
    test "allowed_signing_algorithms(:fapi_2_0_message_signing) returns restricted FAPI 2.0 algorithms" do
      algorithms = SecurityProfile.allowed_signing_algorithms(:fapi_2_0_message_signing)

      assert algorithms == ["ES256", "PS256"]
    end

    test "allowed_signing_algorithms(:fapi_2_0_security) returns restricted FAPI 2.0 algorithms" do
      algorithms = SecurityProfile.allowed_signing_algorithms(:fapi_2_0_security)

      assert algorithms == ["ES256", "PS256"]
    end

    test "allowed_signing_algorithms(:none) returns full algorithm set" do
      algorithms = SecurityProfile.allowed_signing_algorithms(:none)

      assert algorithms == ["RS256", "ES256", "PS256", "EdDSA"]
    end
  end
end
