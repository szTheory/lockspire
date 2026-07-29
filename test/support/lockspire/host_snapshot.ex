defmodule Lockspire.HostSnapshot do
  @moduledoc """
  Test-support helpers for exercising the installer against the committed
  `priv/test_fixtures/phx_new_host/` snapshot without ever writing into the
  tracked copy.

  `scripts/maintainer/repo_hygiene_check.sh` raises when `git status --porcelain`
  is non-empty, so any test that pushes the snapshot as a Mix project and runs
  the installer against it must operate on a scratch copy, never the tracked
  fixture tree.
  """

  @snapshot_root Application.app_dir(:lockspire, "priv/test_fixtures/phx_new_host")

  @doc """
  Copies the committed `phx_new_host` snapshot into a fresh, unique directory
  under `System.tmp_dir!()` and returns its path.

  Callers are responsible for cleaning up the returned path (typically via
  `on_exit/1`); this function never writes into the tracked snapshot.
  """
  @spec copy_to_scratch!() :: String.t()
  def copy_to_scratch! do
    scratch_dir =
      System.tmp_dir!()
      |> Path.join("lockspire_host_snapshot_#{System.unique_integer([:positive])}")

    File.mkdir_p!(scratch_dir)
    File.cp_r!(@snapshot_root, scratch_dir)

    scratch_dir
  end

  @doc """
  Walks `root` and returns a map of relative path to the sha256 hex digest of
  each regular file's raw bytes. Directories are excluded.

  Used both for the empty-tree/all-destinations proof in
  `install_host_interaction_test.exs` and for the zero-bytes-written proof in
  plan 127-07.
  """
  @spec tree_checksums(String.t()) :: %{optional(String.t()) => String.t()}
  def tree_checksums(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(&File.dir?/1)
    |> Map.new(fn path ->
      relative_path = Path.relative_to(path, root)
      digest = path |> File.read!() |> checksum()

      {relative_path, digest}
    end)
  end

  defp checksum(contents) do
    :sha256
    |> :crypto.hash(contents)
    |> Base.encode16(case: :lower)
  end
end
