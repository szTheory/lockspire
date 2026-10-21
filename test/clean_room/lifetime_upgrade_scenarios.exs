defmodule Lockspire.CleanRoom.LifetimeUpgradeScenarios do
  @moduledoc "Contract for the real packaged client-lifetime upgrade journey."

  @prefixes ["public", "tenant_auth"]
  @legacy_date_kinds ["nil", "creation", "past", "future"]

  def prefixes, do: @prefixes

  def legacy_date_kinds, do: @legacy_date_kinds

  def required_v0_observation do
    "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1"
  end
end
