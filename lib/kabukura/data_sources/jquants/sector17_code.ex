defmodule Kabukura.DataSources.Jquants.Sector17Code do
  @moduledoc """
  17業種コードを管理するモジュール
  """

  @sector17_codes %{
    "1" => "食品",
    "2" => "エネルギー資源",
    "3" => "建設・資材",
    "4" => "素材・化学",
    "5" => "医薬品",
    "6" => "自動車・輸送機",
    "7" => "鉄鋼・非鉄",
    "8" => "機械",
    "9" => "電機・精密",
    "10" => "情報通信・サービスその他",
    "11" => "電気・ガス",
    "12" => "運輸・物流",
    "13" => "商社・卸売",
    "14" => "小売",
    "15" => "銀行",
    "16" => "金融（除く銀行）",
    "17" => "不動産",
    "99" => "その他"
  }

  @doc """
  17業種コードから名称を取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.Sector17Code.get_name("1")
      "食品"

      iex> Kabukura.DataSources.Jquants.Sector17Code.get_name("999")
      nil

  """
  def get_name(code) when is_binary(code) do
    @sector17_codes[code]
  end

  @doc """
  17業種名称からコードを取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.Sector17Code.get_code("食品")
      "1"

      iex> Kabukura.DataSources.Jquants.Sector17Code.get_code("存在しない業種")
      nil

  """
  def get_code(name) when is_binary(name) do
    @sector17_codes
    |> Enum.find(fn {_code, sector_name} -> sector_name == name end)
    |> case do
      {code, _name} -> code
      nil -> nil
    end
  end

  @doc """
  全ての17業種コードと名称のペアを取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.Sector17Code.all()
      %{
        "1" => "食品",
        "2" => "エネルギー資源",
        ...
      }

  """
  def all do
    @sector17_codes
  end
end
