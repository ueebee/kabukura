defmodule Kabukura.DataSource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_sources" do
    field :name, :string
    field :description, :string
    field :provider_type, :string
    field :is_enabled, :boolean, default: false
    field :base_url, :string
    field :api_version, :string
    field :rate_limit_per_minute, :integer
    field :rate_limit_per_hour, :integer
    field :rate_limit_per_day, :integer
    field :encrypted_credentials, :binary
    field :refresh_token, :string
    field :refresh_token_expired_at, :utc_datetime
    field :id_token, :string
    field :id_token_expired_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(data_source, attrs) do
    data_source
    |> cast(attrs, [:name, :description, :provider_type, :is_enabled, :base_url, :api_version, :rate_limit_per_minute, :rate_limit_per_hour, :rate_limit_per_day, :encrypted_credentials, :refresh_token, :refresh_token_expired_at, :id_token, :id_token_expired_at])
    |> validate_required([:name, :provider_type, :is_enabled, :base_url, :rate_limit_per_minute, :rate_limit_per_hour, :rate_limit_per_day])
  end
end
