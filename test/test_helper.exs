ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Kabukura.Repo, :manual)
Oban.start_link(repo: Kabukura.Repo)

# Moxの設定
Mox.defmock(Kabukura.DataSources.JQuants.ListedInfoMock, for: Kabukura.DataSources.JQuants.ListedInfoBehaviour)
