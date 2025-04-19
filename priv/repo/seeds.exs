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

# Create J-Quants data source
{:ok, _} =
  Repo.insert(%DataSource{
    name: "J-Quants API",
    description: "日本取引所グループが提供する金融データAPI",
    provider_type: "jquants",
    is_enabled: true,
    base_url: "https://api.jquants.com/v1",
    api_version: "v1",
    rate_limit_per_minute: 30,
    rate_limit_per_hour: 1000,
    rate_limit_per_day: 10000
  })
