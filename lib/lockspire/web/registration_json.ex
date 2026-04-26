defmodule Lockspire.Web.RegistrationJSON do
  @moduledoc false
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement

  def success_response(%Registration.Success{} = success) do
    %{}
  end

  def read_response(%Client{} = client) do
    %{}
  end

  def update_response(%RegistrationManagement.UpdateSuccess{} = success) do
    %{}
  end

  def error_response(%Registration.Error{} = error) do
    %{}
  end
end
