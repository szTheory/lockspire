defmodule Lockspire.Web.Live.Admin.DesignSystem.ThemeSyncTest do
  use ExUnit.Case, async: true

  @layout_path Path.expand(
                 "../../../../../../lib/lockspire/web/live/admin_layout_live.ex",
                 __DIR__
               )

  test "replaced theme selects track the single saved preference" do
    source = File.read!(@layout_path)

    assert source =~ ~s|const storageKey = "lockspire-admin-theme"|
    assert source =~ "const syncThemeSelects = () =>"
    assert source =~ ~s|select.value = savedTheme|
    assert source =~ "new MutationObserver(syncThemeSelects)"
    assert source =~ "themeSelectObserver.observe(root"
    assert source =~ "savedTheme = nextTheme"
  end
end
