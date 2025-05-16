ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Kabukura.Repo, :manual)
Oban.start_link(repo: Kabukura.Repo)
