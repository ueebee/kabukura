# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Kabukura.Repo.insert!(%Kabukura.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Kabukura.Repo
alias Kabukura.DataSource
require Logger

# Create J-Quants data source
{:ok, _} =
  %DataSource{}
  |> DataSource.changeset(%{
    name: "J-Quants API",
    description: "日本取引所グループが提供する金融データAPI",
    provider_type: "jquants",
    is_enabled: true,
    base_url: "https://api.jquants.com/v1",
    api_version: "v1",
    rate_limit_per_minute: 60,
    rate_limit_per_hour: 3600,
    rate_limit_per_day: 86400,
    credentials: %{
      email: System.get_env("SEED_JQUANTS_EMAIL") || (raise "SEED_JQUANTS_EMAIL environment variable is missing"),
      password: System.get_env("SEED_JQUANTS_PASSWORD") || (raise "SEED_JQUANTS_PASSWORD environment variable is missing")
    }
  })
  |> Repo.insert()
