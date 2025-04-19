defmodule Kabukura.Repo.Migrations.CreateDataSources do
  use Ecto.Migration

  def change do
    create table(:data_sources) do
      add :name, :string, null: false
      add :description, :string
      add :provider_type, :string, null: false
      add :is_enabled, :boolean, default: false, null: false
      add :base_url, :string, null: false
      add :api_version, :string
      add :rate_limit_per_minute, :integer, null: false
      add :rate_limit_per_hour, :integer, null: false
      add :rate_limit_per_day, :integer, null: false
      add :encrypted_credentials, :binary
      add :refresh_token, :string
      add :refresh_token_expired_at, :utc_datetime
      add :id_token, :string
      add :id_token_expired_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
