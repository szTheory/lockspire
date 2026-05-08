defmodule Lockspire.Install.Verify.Check do
  @moduledoc """
  Small helpers for normalized install verification checks.
  """

  @type result :: %{
          id: atom(),
          status: :ok | :error,
          summary: String.t(),
          details: String.t(),
          fix: String.t()
        }

  @spec ok(atom(), String.t(), String.t(), String.t()) :: result()
  def ok(id, summary, details, fix) do
    %{id: id, status: :ok, summary: summary, details: details, fix: fix}
  end

  @spec error(atom(), String.t(), String.t(), String.t()) :: result()
  def error(id, summary, details, fix) do
    %{id: id, status: :error, summary: summary, details: details, fix: fix}
  end
end
