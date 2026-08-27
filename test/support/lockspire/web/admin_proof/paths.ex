defmodule Lockspire.Web.AdminProof.Paths do
  @moduledoc false

  @root Path.expand("../../../../../", __DIR__)

  def root, do: @root
  def admin_live_glob, do: Path.join(@root, "lib/lockspire/web/live/admin/**/*.{ex,heex}")
  def admin_css, do: Path.join(@root, "lib/lockspire/web/admin_css.ex")
  def admin_components, do: Path.join(@root, "lib/lockspire/web/components/admin_components.ex")
  def admin_layout, do: Path.join(@root, "lib/lockspire/web/live/admin_layout_live.ex")
  def admin_router, do: Path.join(@root, "lib/lockspire/web/admin_router.ex")
  def operator_admin_doc, do: Path.join(@root, "docs/operator-admin.md")
  def supported_surface_doc, do: Path.join(@root, "docs/supported-surface.md")
  def mix_file, do: Path.join(@root, "mix.exs")
  def brandbook_tokens, do: Path.join(@root, "brandbook/tokens/tokens.json")

  def admin_live_sources do
    admin_live_glob()
    |> Path.wildcard()
    |> Enum.map(&File.read!/1)
  end
end
