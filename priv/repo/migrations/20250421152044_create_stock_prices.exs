defmodule Kabukura.Repo.Migrations.CreateStockPrices do
  use Ecto.Migration

  def change do
    create table(:stock_prices) do
      add :code, :string, null: false
      add :date, :date, null: false
      add :open, :decimal, precision: 10, scale: 2
      add :high, :decimal, precision: 10, scale: 2
      add :low, :decimal, precision: 10, scale: 2
      add :close, :decimal, precision: 10, scale: 2
      add :volume, :float
      add :turnover_value, :decimal, precision: 20, scale: 2
      add :adjustment_factor, :decimal, precision: 10, scale: 2
      add :adjustment_open, :decimal, precision: 10, scale: 2
      add :adjustment_high, :decimal, precision: 10, scale: 2
      add :adjustment_low, :decimal, precision: 10, scale: 2
      add :adjustment_close, :decimal, precision: 10, scale: 2
      add :adjustment_volume, :float

      timestamps()
    end

    create index(:stock_prices, [:code, :date])
  end
end
