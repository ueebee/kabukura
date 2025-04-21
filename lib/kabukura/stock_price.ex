defmodule Kabukura.StockPrice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stock_prices" do
    field :code, :string
    field :date, :date
    field :open, :decimal
    field :high, :decimal
    field :low, :decimal
    field :close, :decimal
    field :volume, :float
    field :turnover_value, :decimal
    field :adjustment_factor, :decimal
    field :adjustment_open, :decimal
    field :adjustment_high, :decimal
    field :adjustment_low, :decimal
    field :adjustment_close, :decimal
    field :adjustment_volume, :float

    timestamps()
  end

  @doc false
  def changeset(stock_price, attrs) do
    stock_price
    |> cast(attrs, [:code, :date, :open, :high, :low, :close, :volume, :turnover_value,
                    :adjustment_factor, :adjustment_open, :adjustment_high, :adjustment_low,
                    :adjustment_close, :adjustment_volume])
    |> validate_required([:code, :date])
  end

  @doc """
  J-Quants APIのレスポンスから株価データの属性を生成します。
  """
  def from_jquants(quote) do
    %{
      code: quote["Code"],
      date: Date.from_iso8601!(quote["Date"]),
      open: Decimal.new(to_string(quote["Open"])),
      high: Decimal.new(to_string(quote["High"])),
      low: Decimal.new(to_string(quote["Low"])),
      close: Decimal.new(to_string(quote["Close"])),
      volume: quote["Volume"],
      turnover_value: Decimal.new(to_string(quote["TurnoverValue"])),
      adjustment_factor: Decimal.new(to_string(quote["AdjustmentFactor"])),
      adjustment_open: Decimal.new(to_string(quote["AdjustmentOpen"])),
      adjustment_high: Decimal.new(to_string(quote["AdjustmentHigh"])),
      adjustment_low: Decimal.new(to_string(quote["AdjustmentLow"])),
      adjustment_close: Decimal.new(to_string(quote["AdjustmentClose"])),
      adjustment_volume: quote["AdjustmentVolume"]
    }
  end
end
