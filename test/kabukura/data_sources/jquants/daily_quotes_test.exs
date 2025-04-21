defmodule Kabukura.DataSources.JQuants.DailyQuotesTest do
  use Kabukura.DataCase
  alias Kabukura.DataSources.JQuants.DailyQuotes
  alias Kabukura.DataSources.JQuants.TokenStore
  alias Kabukura.DataSource
  alias Kabukura.StockPrice
  alias Kabukura.Repo

  setup do
    bypass = Bypass.open()
    Application.put_env(:kabukura, :jquants_api_url, "http://localhost:#{bypass.port}")

    # 既存のデータソースを削除
    Repo.delete_all(DataSource)
    Repo.delete_all(StockPrice)

    # データソースを作成
    {:ok, data_source} =
      %DataSource{}
      |> DataSource.changeset(%{
        name: "Test J-Quants",
        provider_type: "jquants",
        base_url: "https://api.jquants.com/v1",
        credentials_json: Jason.encode!(%{
          "mailaddress" => "test@example.com",
          "password" => "password"
        })
      })
      |> Repo.insert()

    # TokenStoreの状態をリセット
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    :sys.replace_state(TokenStore, fn _state ->
      %{
        id_token: "valid_id_token",
        id_token_expired_at: DateTime.add(now, 3600, :second),
        refresh_token: "valid_refresh_token",
        refresh_token_expired_at: DateTime.add(now, 7 * 24 * 3600, :second)
      }
    end)

    %{bypass: bypass, data_source: data_source}
  end

  describe "get_daily_quotes/2" do
    test "successfully retrieves and saves daily quotes by code and date", %{bypass: bypass} do
      code = "86970"
      date = "2024-04-21"

      Bypass.expect(bypass, "GET", "/prices/daily_quotes", fn conn ->
        assert conn.query_string == "code=#{code}&date=#{date}"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{
          "daily_quotes" => [
            %{
              "Date" => date,
              "Code" => code,
              "Open" => 4128.0,
              "High" => 4150.0,
              "Low" => 4100.0,
              "Close" => 4130.0,
              "Volume" => 1000000.0,
              "TurnoverValue" => 4128000000.0,
              "AdjustmentFactor" => 1.0,
              "AdjustmentOpen" => 4128.0,
              "AdjustmentHigh" => 4150.0,
              "AdjustmentLow" => 4100.0,
              "AdjustmentClose" => 4130.0,
              "AdjustmentVolume" => 1000000.0
            }
          ]
        }))
      end)

      assert {:ok, stock_prices} = DailyQuotes.get_daily_quotes(code, date)
      assert length(stock_prices) == 1
      assert stock_prices |> List.first() |> Map.get(:code) == code
      assert stock_prices |> List.first() |> Map.get(:date) |> Date.to_string() == date
      assert Decimal.eq?(stock_prices |> List.first() |> Map.get(:open), Decimal.new("4128.0"))

      # データベースに保存されていることを確認
      db_stock_prices = Repo.all(StockPrice)
      assert length(db_stock_prices) == 1
      assert db_stock_prices |> List.first() |> Map.get(:code) == code
      assert db_stock_prices |> List.first() |> Map.get(:date) |> Date.to_string() == date
      assert Decimal.eq?(db_stock_prices |> List.first() |> Map.get(:open), Decimal.new("4128.0"))
    end

    test "successfully retrieves and saves daily quotes by code and date range", %{bypass: bypass} do
      code = "86970"
      from = "2024-04-01"
      to = "2024-04-21"

      Bypass.expect(bypass, "GET", "/prices/daily_quotes", fn conn ->
        assert conn.query_string == "code=#{code}&from=#{from}&to=#{to}"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{
          "daily_quotes" => [
            %{
              "Date" => "2024-04-01",
              "Code" => code,
              "Open" => 4100.0,
              "High" => 4120.0,
              "Low" => 4080.0,
              "Close" => 4110.0,
              "Volume" => 900000.0,
              "TurnoverValue" => 3699000000.0,
              "AdjustmentFactor" => 1.0,
              "AdjustmentOpen" => 4100.0,
              "AdjustmentHigh" => 4120.0,
              "AdjustmentLow" => 4080.0,
              "AdjustmentClose" => 4110.0,
              "AdjustmentVolume" => 900000.0
            },
            %{
              "Date" => "2024-04-21",
              "Code" => code,
              "Open" => 4128.0,
              "High" => 4150.0,
              "Low" => 4100.0,
              "Close" => 4130.0,
              "Volume" => 1000000.0,
              "TurnoverValue" => 4128000000.0,
              "AdjustmentFactor" => 1.0,
              "AdjustmentOpen" => 4128.0,
              "AdjustmentHigh" => 4150.0,
              "AdjustmentLow" => 4100.0,
              "AdjustmentClose" => 4130.0,
              "AdjustmentVolume" => 1000000.0
            }
          ]
        }))
      end)

      assert {:ok, stock_prices} = DailyQuotes.get_daily_quotes(code, from, to)
      assert length(stock_prices) == 2
      assert stock_prices |> Enum.map(& &1.code) |> Enum.uniq() == [code]

      # データベースに保存されていることを確認
      db_stock_prices = Repo.all(StockPrice)
      assert length(db_stock_prices) == 2
      assert db_stock_prices |> Enum.map(& &1.code) |> Enum.uniq() == [code]
    end

    test "successfully retrieves and saves daily quotes by date", %{bypass: bypass} do
      date = "2024-04-21"

      Bypass.expect(bypass, "GET", "/prices/daily_quotes", fn conn ->
        assert conn.query_string == "date=#{date}"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{
          "daily_quotes" => [
            %{
              "Date" => date,
              "Code" => "86970",
              "Open" => 4128.0,
              "High" => 4150.0,
              "Low" => 4100.0,
              "Close" => 4130.0,
              "Volume" => 1000000.0,
              "TurnoverValue" => 4128000000.0,
              "AdjustmentFactor" => 1.0,
              "AdjustmentOpen" => 4128.0,
              "AdjustmentHigh" => 4150.0,
              "AdjustmentLow" => 4100.0,
              "AdjustmentClose" => 4130.0,
              "AdjustmentVolume" => 1000000.0
            },
            %{
              "Date" => date,
              "Code" => "9432",
              "Open" => 1500.0,
              "High" => 1510.0,
              "Low" => 1490.0,
              "Close" => 1505.0,
              "Volume" => 500000.0,
              "TurnoverValue" => 752500000.0,
              "AdjustmentFactor" => 1.0,
              "AdjustmentOpen" => 1500.0,
              "AdjustmentHigh" => 1510.0,
              "AdjustmentLow" => 1490.0,
              "AdjustmentClose" => 1505.0,
              "AdjustmentVolume" => 500000.0
            }
          ]
        }))
      end)

      assert {:ok, stock_prices} = DailyQuotes.get_daily_quotes_by_date(date)
      assert length(stock_prices) == 2
      assert stock_prices |> Enum.map(& &1.date) |> Enum.uniq() |> List.first() |> Date.to_string() == date

      # データベースに保存されていることを確認
      db_stock_prices = Repo.all(StockPrice)
      assert length(db_stock_prices) == 2
      assert db_stock_prices |> Enum.map(& &1.date) |> Enum.uniq() |> List.first() |> Date.to_string() == date
    end

    test "returns error when API returns error", %{bypass: bypass} do
      # トークンが有効であることを確認
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      :sys.replace_state(TokenStore, fn _state ->
        %{
          id_token: "valid_id_token",
          id_token_expired_at: DateTime.add(now, 3600, :second),
          refresh_token: "valid_refresh_token",
          refresh_token_expired_at: DateTime.add(now, 7 * 24 * 3600, :second)
        }
      end)

      Bypass.expect(bypass, "GET", "/prices/daily_quotes", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(%{
          "message" => "Invalid request"
        }))
      end)

      assert {:error, "Invalid request"} = DailyQuotes.get_daily_quotes("86970", "2024-04-21")
    end
  end
end
