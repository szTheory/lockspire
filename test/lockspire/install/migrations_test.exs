defmodule Lockspire.Install.MigrationsTest do
  use ExUnit.Case, async: true

  alias Lockspire.Install.Migrations

  setup do
    root =
      Path.join(System.tmp_dir!(), "lockspire-migrations-#{System.unique_integer([:positive])}")

    source_root = Path.join(root, "package/priv/repo/migrations")
    project_root = Path.join(root, "host")

    File.mkdir_p!(source_root)

    on_exit(fn -> File.rm_rf!(root) end)

    {:ok, source_root: source_root, project_root: project_root}
  end

  test "plans missing packaged migrations as copies", %{
    source_root: source_root,
    project_root: project_root
  } do
    write_migration!(source_root, "20260826000100_create_widgets.exs", "create widgets")

    assert {:ok, %{operations: [operation]}} =
             Migrations.plan(source_root: source_root, project_root: project_root)

    assert operation.status == :copy
    assert operation.version == "20260826000100"
    assert operation.name == "create_widgets"
    assert operation.relative_path == "priv/repo/migrations/20260826000100_create_widgets.exs"
    assert operation.checksum == Lockspire.Install.Manifest.checksum("create widgets")
    refute File.exists?(Path.join(project_root, "priv/repo/migrations"))
  end

  test "plans byte-identical installed migrations as unchanged without mutation", %{
    source_root: source_root,
    project_root: project_root
  } do
    filename = "20260826000100_create_widgets.exs"
    contents = "create widgets"
    write_migration!(source_root, filename, contents)
    destination = write_host_migration!(project_root, filename, contents)
    before = File.stat!(destination).mtime

    assert {:ok, %{operations: [%{status: :unchanged}]}} =
             Migrations.plan(source_root: source_root, project_root: project_root)

    assert File.read!(destination) == contents
    assert File.stat!(destination).mtime == before
  end

  test "rejects an exact destination with different contents", %{
    source_root: source_root,
    project_root: project_root
  } do
    filename = "20260826000100_create_widgets.exs"
    write_migration!(source_root, filename, "package bytes")
    destination = write_host_migration!(project_root, filename, "host bytes")

    assert {:error, [%{type: :content_collision, source: source, destination: ^destination}]} =
             Migrations.plan(source_root: source_root, project_root: project_root)

    assert source == Path.join(source_root, filename)
    assert File.read!(destination) == "host bytes"
  end

  test "rejects a host migration with the same version under another name", %{
    source_root: source_root,
    project_root: project_root
  } do
    write_migration!(source_root, "20260826000100_create_widgets.exs", "package bytes")

    collision =
      write_host_migration!(project_root, "20260826000100_create_other_widgets.exs", "host bytes")

    assert {:error, [%{type: :version_collision, host: ^collision, version: "20260826000100"}]} =
             Migrations.plan(source_root: source_root, project_root: project_root)
  end

  test "rejects a host migration with the same name under another version", %{
    source_root: source_root,
    project_root: project_root
  } do
    write_migration!(source_root, "20260826000100_create_widgets.exs", "package bytes")

    collision =
      write_host_migration!(project_root, "20260826000200_create_widgets.exs", "host bytes")

    assert {:error, [%{type: :name_collision, host: ^collision, name: "create_widgets"}]} =
             Migrations.plan(source_root: source_root, project_root: project_root)
  end

  test "rejects invalid packaged migration filenames before creating a host directory", %{
    source_root: source_root,
    project_root: project_root
  } do
    invalid_source = Path.join(source_root, "not_a_migration.exs")
    File.write!(invalid_source, "package bytes")

    assert {:error, [%{type: :invalid_package_migration, source: ^invalid_source}]} =
             Migrations.plan(source_root: source_root, project_root: project_root)

    refute File.exists?(Path.join(project_root, "priv/repo/migrations"))
  end

  test "a late collision leaves earlier missing destinations absent", %{
    source_root: source_root,
    project_root: project_root
  } do
    first = "20260826000100_create_widgets.exs"
    second = "20260826000200_create_gadgets.exs"
    write_migration!(source_root, first, "first package bytes")
    write_migration!(source_root, second, "second package bytes")
    write_host_migration!(project_root, second, "conflicting host bytes")

    assert {:error, [%{type: :content_collision}]} =
             Migrations.plan(source_root: source_root, project_root: project_root)

    refute File.exists?(Path.join(project_root, "priv/repo/migrations/#{first}"))
  end

  test "applies an approved plan byte-for-byte and returns stable complete inventory", %{
    source_root: source_root,
    project_root: project_root
  } do
    first = "20260826000100_create_widgets.exs"
    second = "20260826000200_create_gadgets.exs"
    write_migration!(source_root, second, "second package bytes")
    write_migration!(source_root, first, "first package bytes")

    assert {:ok, plan} = Migrations.plan(source_root: source_root, project_root: project_root)
    assert {:ok, result} = Migrations.apply(plan)

    assert Enum.map(result.operations, & &1.status) == [:copied, :copied]

    assert Enum.map(result.migrations, & &1.relative_path) == [
             "priv/repo/migrations/#{first}",
             "priv/repo/migrations/#{second}"
           ]

    assert File.read!(Path.join(project_root, "priv/repo/migrations/#{first}")) ==
             "first package bytes"

    assert File.read!(Path.join(project_root, "priv/repo/migrations/#{second}")) ==
             "second package bytes"
  end

  test "reapplying unchanged migrations preserves their mtimes and copies only additive source growth",
       %{
         source_root: source_root,
         project_root: project_root
       } do
    first = "20260826000100_create_widgets.exs"
    second = "20260826000200_create_gadgets.exs"
    write_migration!(source_root, first, "first package bytes")

    assert {:ok, first_plan} =
             Migrations.plan(source_root: source_root, project_root: project_root)

    assert {:ok, _first_result} = Migrations.apply(first_plan)
    first_destination = Path.join(project_root, "priv/repo/migrations/#{first}")
    before = File.stat!(first_destination).mtime

    write_migration!(source_root, second, "second package bytes")

    assert {:ok, additive_plan} =
             Migrations.plan(source_root: source_root, project_root: project_root)

    assert {:ok, result} = Migrations.apply(additive_plan)

    assert Enum.map(result.operations, & &1.status) == [:unchanged, :copied]
    assert File.stat!(first_destination).mtime == before

    assert File.read!(Path.join(project_root, "priv/repo/migrations/#{second}")) ==
             "second package bytes"
  end

  test "refuses an approved plan when its packaged bytes change before apply", %{
    source_root: source_root,
    project_root: project_root
  } do
    filename = "20260826000100_create_widgets.exs"
    source = write_migration!(source_root, filename, "original package bytes")

    assert {:ok, plan} = Migrations.plan(source_root: source_root, project_root: project_root)
    File.write!(source, "changed package bytes")

    assert {:error, [%{type: :approved_plan_changed, path: ^source}]} = Migrations.apply(plan)
    refute File.exists?(Path.join(project_root, "priv/repo/migrations"))
  end

  test "refuses an approved plan when a host migration appears before apply", %{
    source_root: source_root,
    project_root: project_root
  } do
    filename = "20260826000100_create_widgets.exs"
    write_migration!(source_root, filename, "package bytes")

    assert {:ok, plan} = Migrations.plan(source_root: source_root, project_root: project_root)
    destination = write_host_migration!(project_root, filename, "host bytes")

    assert {:error, [%{type: :approved_plan_changed, path: ^destination}]} =
             Migrations.apply(plan)

    assert File.read!(destination) == "host bytes"
  end

  defp write_migration!(source_root, filename, contents) do
    path = Path.join(source_root, filename)
    File.write!(path, contents)
    path
  end

  defp write_host_migration!(project_root, filename, contents) do
    path = Path.join(project_root, "priv/repo/migrations/#{filename}")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
    path
  end
end
