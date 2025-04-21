defmodule Kabukura.DataSources.Jquants.MarketCode do
  @moduledoc """
  市場区分コードを管理するモジュール
  """

  @market_codes %{
    "0101" => "東証一部",
    "0102" => "東証二部",
    "0104" => "マザーズ",
    "0105" => "TOKYO PRO MARKET",
    "0106" => "JASDAQ スタンダード",
    "0107" => "JASDAQ グロース",
    "0109" => "その他",
    "0111" => "プライム",
    "0112" => "スタンダード",
    "0113" => "グロース"
  }

  @doc """
  市場区分コードから名称を取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.MarketCode.get_name("0101")
      "東証一部"

      iex> Kabukura.DataSources.Jquants.MarketCode.get_name("9999")
      nil

  """
  def get_name(code) when is_binary(code) do
    @market_codes[code]
  end

  @doc """
  市場区分名称からコードを取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.MarketCode.get_code("東証一部")
      "0101"

      iex> Kabukura.DataSources.Jquants.MarketCode.get_code("存在しない市場")
      nil

  """
  def get_code(name) when is_binary(name) do
    @market_codes
    |> Enum.find(fn {_code, market_name} -> market_name == name end)
    |> case do
      {code, _name} -> code
      nil -> nil
    end
  end

  @doc """
  全ての市場区分コードと名称のペアを取得する

  ## Examples

      iex> Kabukura.DataSources.Jquants.MarketCode.all()
      %{
        "0101" => "東証一部",
        "0102" => "東証二部",
        ...
      }

  """
  def all do
    @market_codes
  end
end
