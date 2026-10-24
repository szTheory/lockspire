defmodule Lockspire.CleanRoom.LifetimeUpgradeScenarios do
  @moduledoc "Contract for the real packaged client-lifetime upgrade journey."

  @prefixes ["public", "tenant_auth"]
  @legacy_date_kinds ["nil", "creation", "past", "future"]

  def prefixes, do: @prefixes

  def legacy_date_kinds, do: @legacy_date_kinds

  def required_v0_observation do
    "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1"
  end

  def required_legacy_http_observation do
    %{
      "par_http_status" => 201,
      "authorize_http_status" => 302,
      "login_http_status" => 200,
      "token_http_status" => 200,
      "lifetime_version" => 0,
      "client_secret_date_kind" => "past",
      "access_token_issued" => true
    }
  end

  def required_legacy_promotion_statuses do
    %{
      "old_secret_http_status" => 401,
      "replacement_secret_http_status" => 200,
      "management_put_http_status" => 200,
      "old_management_http_status" => 401,
      "replacement_management_http_status" => 200,
      "lifetime_version" => 1,
      "app_unlimited" => true,
      "secret_current_policy_deadline" => true,
      "management_current_policy_deadline" => true,
      "whole_row_promoted" => true,
      "unrelated_authority_preserved" => true,
      "audit_persisted" => true,
      "wire_client_expires_at" => 0
    }
  end
end
