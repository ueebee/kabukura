defmodule Kabukura.DataSources.JQuants.DailyQuotes do
  @moduledoc """
  J-Quants APIから株価データを取得するモジュール
  """

  alias Kabukura.DataSources.JQuants.HTTP
  alias Kabukura.StockPrice
  alias Kabukura.Repo

  @doc """
  指定された銘柄コードと日付の株価データを取得し、データベースに保存します。

  ## パラメータ
    - `code`: 銘柄コード
    - `date`: 日付（YYYY-MM-DD形式）

  ## 戻り値
    - `{:ok, stock_prices}` - 成功時、保存された株価データ
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_daily_quotes(code, date) do
    path = "/prices/daily_quotes"
    params = %{
      "code" => code,
      "date" => date
    }

    with {:ok, response} <- HTTP.get("#{path}?#{URI.encode_query(params)}"),
         {:ok, stock_prices} <- save_stock_prices(response["daily_quotes"]) do
      {:ok, stock_prices}
    end
  end

  @doc """
  指定された銘柄コードと期間の株価データを取得し、データベースに保存します。

  ## パラメータ
    - `code`: 銘柄コード
    - `from`: 開始日（YYYY-MM-DD形式）
    - `to`: 終了日（YYYY-MM-DD形式）

  ## 戻り値
    - `{:ok, stock_prices}` - 成功時、保存された株価データのリスト
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_daily_quotes(code, from, to) do
    path = "/prices/daily_quotes"
    params = %{
      "code" => code,
      "from" => from,
      "to" => to
    }

    with {:ok, response} <- HTTP.get("#{path}?#{URI.encode_query(params)}"),
         {:ok, stock_prices} <- save_stock_prices(response["daily_quotes"]) do
      {:ok, stock_prices}
    end
  end

  @doc """
  指定された日付の全銘柄の株価データを取得し、データベースに保存します。

  ## パラメータ
    - `date`: 日付（YYYY-MM-DD形式）

  ## 戻り値
    - `{:ok, stock_prices}` - 成功時、保存された株価データのリスト
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_daily_quotes_by_date(date) do
    path = "/prices/daily_quotes"
    params = %{"date" => date}

    with {:ok, response} <- HTTP.get("#{path}?#{URI.encode_query(params)}"),
         {:ok, stock_prices} <- save_stock_prices(response["daily_quotes"]) do
      {:ok, stock_prices}
    end
  end

  # プライベート関数

  defp save_stock_prices(quotes) do
    # トランザクション内で株価データを保存
    Repo.transaction(fn ->
      Enum.map(quotes, fn quote ->
        stock_price_attrs = StockPrice.from_jquants(quote)

        # 既存の株価データを検索
        existing_stock_price =
          Repo.get_by(StockPrice,
            code: stock_price_attrs.code,
            date: stock_price_attrs.date
          )

        # 株価データを保存または更新
        case existing_stock_price do
          nil ->
            %StockPrice{}
            |> StockPrice.changeset(stock_price_attrs)
            |> Repo.insert!()

          stock_price ->
            stock_price
            |> StockPrice.changeset(stock_price_attrs)
            |> Repo.update!()
        end
      end)
    end)
  end
end
