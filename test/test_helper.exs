ExUnit.start()

Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

{:ok, _pid} = Lockspire.TestRepo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
