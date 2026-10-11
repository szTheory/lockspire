defmodule Lockspire.Web.Live.Admin.DesignSystem.ThemeSyncTest do
  use ExUnit.Case, async: true

  @layout_path Path.expand(
                 "../../../../../../lib/lockspire/web/live/admin_layout_live.ex",
                 __DIR__
               )

  test "replaced theme selects track the single saved preference" do
    source = File.read!(@layout_path)

    assert source =~ ~s|const storageKey = "lockspire-admin-theme"|
    assert source =~ "const syncShellThemeState = () =>"
    assert source =~ ~s|select.value = currentPageTheme|
    assert source =~ "new MutationObserver((mutations) =>"
    assert source =~ "shellObserver.observe(root"
    assert source =~ "requestAnimationFrame(() =>"
    assert source =~ "if (focusTarget.isConnected) focusTarget.focus()"
    assert source =~ "savedTheme = nextTheme"
  end

  test "storage failures keep page appearance truthful and announce the outcome" do
    source = File.read!(@layout_path)

    assert source =~ "let currentPageTheme = \"system\""
    assert source =~ "data-lockspire-theme-status role=\"status\" aria-live=\"polite\""
    assert source =~ "Your saved theme preference could not be read."

    assert source =~
             "Your theme is applied for this page, but the saved preference was not updated."

    assert source =~
             "Your theme is applied for this page, but the saved preference was not cleared."

    refute source =~ "${_error.message}"
  end
end
