defmodule Kabukura.DataSources.JQuants.Workers.DailyQuotesWorkerTest do
  use Kabukura.DataCase
  import Mox
  alias Kabukura.DataSources.JQuants.Workers.DailyQuotesWorker

  # Moxの設定
  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "validate_params/1" do
    test "必須パラメータが全て存在する場合、成功を返す" do
      args = %{
        "code" => "86970",
        "from" => "2024-03-01",
        "to" => "2024-03-20"
      }
      assert {:ok, %{code: "86970", from: "2024-03-01", to: "2024-03-20"}} == DailyQuotesWorker.validate_params(args)
    end

    test "codeが存在しない場合、エラーを返す" do
      args = %{
        "from" => "2024-03-01",
        "to" => "2024-03-20"
      }
      assert {:error, "Stock code (code) is required"} == DailyQuotesWorker.validate_params(args)
    end

    test "fromが存在しない場合、エラーを返す" do
      args = %{
        "code" => "86970",
        "to" => "2024-03-20"
      }
      assert {:error, "Start date (from) is required"} == DailyQuotesWorker.validate_params(args)
    end

    test "toが存在しない場合、エラーを返す" do
      args = %{
        "code" => "86970",
        "from" => "2024-03-01"
      }
      assert {:error, "End date (to) is required"} == DailyQuotesWorker.validate_params(args)
    end

    test "argsがネストされた構造の場合、正しく処理される" do
      args = %{
        "args" => %{
          "code" => "86970",
          "from" => "2024-03-01",
          "to" => "2024-03-20"
        }
      }
      assert {:ok, %{code: "86970", from: "2024-03-01", to: "2024-03-20"}} == DailyQuotesWorker.validate_params(args)
    end
  end

  describe "normalize_opts/1" do
    test "nilを渡した場合、空のマップを返す" do
      assert %{} == DailyQuotesWorker.normalize_opts(nil)
    end

    test "空のリストを渡した場合、空のマップを返す" do
      assert %{} == DailyQuotesWorker.normalize_opts([])
    end

    test "キーワードリストを渡した場合、マップに変換して返す" do
      opts = [code: "86970", from: "2024-03-01", to: "2024-03-20"]
      expected = %{code: "86970", from: "2024-03-01", to: "2024-03-20"}
      assert expected == DailyQuotesWorker.normalize_opts(opts)
    end

    test "マップを渡した場合、そのまま返す" do
      opts = %{code: "86970", from: "2024-03-01", to: "2024-03-20"}
      assert opts == DailyQuotesWorker.normalize_opts(opts)
    end

    test "文字列キーのマップを渡した場合、そのまま返す" do
      opts = %{"code" => "86970", "from" => "2024-03-01", "to" => "2024-03-20"}
      assert opts == DailyQuotesWorker.normalize_opts(opts)
    end

    test "periodがlast_7_daysの場合、正しく変換される" do
      opts = %{"period" => "last_7_days"}
      expected = %{"period" => :last_7_days}
      assert expected == DailyQuotesWorker.normalize_opts(opts)
    end

    test "periodがlast_30_daysの場合、正しく変換される" do
      opts = %{"period" => "last_30_days"}
      expected = %{"period" => :last_30_days}
      assert expected == DailyQuotesWorker.normalize_opts(opts)
    end

    test "periodが未定義の値の場合、そのまま返す" do
      opts = %{"period" => "invalid_period"}
      assert opts == DailyQuotesWorker.normalize_opts(opts)
    end
  end
end
