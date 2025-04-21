defmodule Kabukura.DataSources.JQuants.DailyQuotes do
  @moduledoc """
  J-Quants APIから株価データを取得するモジュール
  """

  alias Kabukura.DataSources.JQuants.HTTP

  @doc """
  指定された銘柄コードと日付の株価データを取得します。

  ## パラメータ
    - `code`: 銘柄コード
    - `date`: 日付（YYYY-MM-DD形式）

  ## 戻り値
    - `{:ok, daily_quotes}` - 成功時、株価データ
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_daily_quotes(code, date) do
    path = "/prices/daily_quotes"
    params = %{
      "code" => code,
      "date" => date
    }

    with {:ok, response} <- HTTP.get("#{path}?#{URI.encode_query(params)}") do
      {:ok, response["daily_quotes"]}
    end
  end

  @doc """
  指定された銘柄コードと期間の株価データを取得します。

  ## パラメータ
    - `code`: 銘柄コード
    - `from`: 開始日（YYYY-MM-DD形式）
    - `to`: 終了日（YYYY-MM-DD形式）

  ## 戻り値
    - `{:ok, daily_quotes}` - 成功時、株価データのリスト
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_daily_quotes(code, from, to) do
    path = "/prices/daily_quotes"
    params = %{
      "code" => code,
      "from" => from,
      "to" => to
    }

    with {:ok, response} <- HTTP.get("#{path}?#{URI.encode_query(params)}") do
      {:ok, response["daily_quotes"]}
    end
  end
end
