defmodule Kabukura.DataSources.Jquants.Sector33Code do
  @moduledoc """
  33業種コードを管理するモジュール
  """

  @sector33_codes %{
    "0050" => "水産・農林業",
    "1050" => "鉱業",
    "2050" => "建設業",
    "3050" => "食料品",
    "3100" => "繊維製品",
    "3150" => "パルプ・紙",
    "3200" => "化学",
    "3250" => "医薬品",
    "3300" => "石油･石炭製品",
    "3350" => "ゴム製品",
    "3400" => "ガラス･土石製品",
    "3450" => "鉄鋼",
    "3500" => "非鉄金属",
    "3550" => "金属製品",
    "3600" => "機械",
    "3650" => "電気機器",
    "3700" => "輸送用機器",
    "3750" => "精密機器",
    "3800" => "その他製品",
    "4050" => "電気･ガス業",
    "5050" => "陸運業",
    "5100" => "海運業",
    "5150" => "空運業",
    "5200" => "倉庫･運輸関連業",
    "5250" => "情報･通信業",
    "6050" => "卸売業",
    "6100" => "小売業",
    "7050" => "銀行業",
    "7100" => "証券･商品先物取引業",
    "7150" => "保険業",
    "7200" => "その他金融業",
    "8050" => "不動産業",
    "9050" => "サービス業",
    "9999" => "その他"
  }

  @doc """
  33業種コードから名称を取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.Sector33Code.get_name("0050")
      "水産・農林業"

      iex> Kabukura.DataSources.Jquants.Sector33Code.get_name("9999")
      nil

  """
  def get_name(code) when is_binary(code) do
    @sector33_codes[code]
  end

  @doc """
  33業種名称からコードを取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.Sector33Code.get_code("水産・農林業")
      "0050"

      iex> Kabukura.DataSources.Jquants.Sector33Code.get_code("存在しない業種")
      nil

  """
  def get_code(name) when is_binary(name) do
    @sector33_codes
    |> Enum.find(fn {_code, sector_name} -> sector_name == name end)
    |> case do
      {code, _name} -> code
      nil -> nil
    end
  end

  @doc """
  全ての33業種コードと名称のペアを取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.Sector33Code.all()
      %{
        "0050" => "水産・農林業",
        "1050" => "鉱業",
        ...
      }

  """
  def all do
    @sector33_codes
  end
end
