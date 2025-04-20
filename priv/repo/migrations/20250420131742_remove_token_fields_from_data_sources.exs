defmodule Kabukura.Repo.Migrations.RemoveTokenFieldsFromDataSources do
  use Ecto.Migration

  def change do
    alter table(:data_sources) do
      remove :refresh_token
      remove :refresh_token_expired_at
      remove :id_token
      remove :id_token_expired_at
    end
  end
end
