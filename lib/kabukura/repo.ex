defmodule Kabukura.Repo do
  use Ecto.Repo,
    otp_app: :kabukura,
    adapter: Ecto.Adapters.Postgres
end
