defmodule Kabukura.DataSources.JQuants.ListedInfoTest do
  use Kabukura.DataCase
  alias Kabukura.DataSources.JQuants.ListedInfo
  alias Kabukura.DataSources.JQuants.TokenStore
  alias Kabukura.DataSource

  setup do
    bypass = Bypass.open()
    Application.put_env(:kabukura, :jquants_api_url, "http://localhost:#{bypass.port}")

    # 既存のデータソースを削除
    Repo.delete_all(DataSource)

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

  describe "get_listed_info/1" do
    test "successfully retrieves all listed info", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/listed/info", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{
          "info" => [
            %{
              "Date" => "2022-11-11",
              "Code" => "86970",
              "CompanyName" => "日本取引所グループ",
              "CompanyNameEnglish" => "Japan Exchange Group,Inc.",
              "Sector17Code" => "16",
              "Sector17CodeName" => "金融（除く銀行）",
              "Sector33Code" => "7200",
              "Sector33CodeName" => "その他金融業",
              "ScaleCategory" => "TOPIX Large70",
              "MarketCode" => "0111",
              "MarketCodeName" => "プライム",
              "MarginCode" => "1",
              "MarginCodeName" => "信用"
            }
          ]
        }))
      end)

      assert {:ok, [info]} = ListedInfo.get_listed_info()
      assert info["Code"] == "86970"
      assert info["CompanyName"] == "日本取引所グループ"
    end

    test "successfully retrieves info by code", %{bypass: bypass} do
      code = "86970"

      Bypass.expect(bypass, "GET", "/listed/info", fn conn ->
        assert conn.query_string == "code=#{code}"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{
          "info" => [
            %{
              "Date" => "2022-11-11",
              "Code" => code,
              "CompanyName" => "日本取引所グループ"
            }
          ]
        }))
      end)

      assert {:ok, [info]} = ListedInfo.get_listed_info_by_code(code)
      assert info["Code"] == code
    end

    test "successfully retrieves info by date", %{bypass: bypass} do
      date = "2022-11-11"

      Bypass.expect(bypass, "GET", "/listed/info", fn conn ->
        assert conn.query_string == "date=#{date}"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{
          "info" => [
            %{
              "Date" => date,
              "Code" => "86970",
              "CompanyName" => "日本取引所グループ"
            }
          ]
        }))
      end)

      assert {:ok, [info]} = ListedInfo.get_listed_info_by_date(date)
      assert info["Date"] == date
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

      Bypass.expect(bypass, "GET", "/listed/info", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(%{
          "message" => "Invalid request"
        }))
      end)

      assert {:error, "Invalid request"} = ListedInfo.get_listed_info()
    end
  end
end
