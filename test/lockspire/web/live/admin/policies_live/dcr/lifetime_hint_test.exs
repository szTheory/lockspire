defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr.LifetimeHintTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr.LifetimeHint

  @client :dcr_default_client_lifetime_seconds
  @secret :dcr_default_client_secret_lifetime_seconds
  @management_token :dcr_default_registration_access_token_lifetime_seconds

  test "exact durations use the largest whole unit" do
    assert LifetimeHint.describe(@client, "45") == "45 seconds"
    assert LifetimeHint.describe(@client, "60") == "1 minute"
    assert LifetimeHint.describe(@client, "3600") == "1 hour"
    assert LifetimeHint.describe(@client, "7200") == "2 hours"
    assert LifetimeHint.describe(@client, 86_400) == "1 day"
    assert LifetimeHint.describe(@client, "2592000") == "30 days"
  end

  test "inexact durations round to one decimal of the largest unit" do
    assert LifetimeHint.describe(@client, "180000") == "≈ 2.1 days"
    assert LifetimeHint.describe(@client, "5400") == "≈ 1.5 hours"
    assert LifetimeHint.describe(@client, "86401") == "≈ 1 day"
  end

  test "durations of a year or more add an approximate year count" do
    assert LifetimeHint.describe(@client, "31536000") == "365 days (1 year)"

    assert LifetimeHint.describe(@client, "2147483647") ==
             "≈ 24,855.1 days (≈ 68.1 years)"
  end

  test "blank and zero explain that app secrets do not expire automatically" do
    assert LifetimeHint.describe(@client, "") == nil
    assert LifetimeHint.describe(@client, nil) == nil
    assert LifetimeHint.describe(@client, "0") == "0 seconds"

    for value <- [" ", "0"] do
      assert LifetimeHint.describe(@secret, value) == "No automatic expiry"
    end
  end

  test "blank and zero explain that management tokens do not expire automatically" do
    for value <- ["", nil, "0"] do
      assert LifetimeHint.describe(@management_token, value) == "No automatic expiry"
    end
  end

  test "a positive secret duration remains a readable duration" do
    assert LifetimeHint.describe(@secret, "60") == "1 minute"
  end

  test "invalid input shows no duration and leaves the error to validation" do
    for value <- ["-1", "1.5", "1,000", "abc", -5] do
      assert LifetimeHint.describe(@client, value) == nil
    end
  end
end
