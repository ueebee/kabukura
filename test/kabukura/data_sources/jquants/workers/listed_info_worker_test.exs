defmodule Kabukura.DataSources.JQuants.Workers.ListedInfoWorkerTest do
  use Kabukura.DataCase
  import Mox
  alias Kabukura.DataSources.JQuants.Workers.ListedInfoWorker
  alias Kabukura.DataSources.JQuants.ListedInfoMock

  # Moxの設定
  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "validate_params/1" do
    test "空のマップを渡した場合、成功を返す" do
      assert {:ok, %{}} == ListedInfoWorker.validate_params(%{})
    end

    test "nilを渡した場合、成功を返す" do
      assert {:ok, %{}} == ListedInfoWorker.validate_params(nil)
    end

    test "任意のパラメータを渡した場合、成功を返す" do
      params = %{"some_key" => "some_value"}
      assert {:ok, %{}} == ListedInfoWorker.validate_params(params)
    end
  end

  describe "normalize_opts/1" do
    test "nilを渡した場合、空のマップを返す" do
      assert %{} == ListedInfoWorker.normalize_opts(nil)
    end

    test "空のリストを渡した場合、空のマップを返す" do
      assert %{} == ListedInfoWorker.normalize_opts([])
    end

    test "キーワードリストを渡した場合、マップに変換して返す" do
      opts = [key1: "value1", key2: "value2"]
      expected = %{key1: "value1", key2: "value2"}
      assert expected == ListedInfoWorker.normalize_opts(opts)
    end

    test "マップを渡した場合、そのまま返す" do
      opts = %{key1: "value1", key2: "value2"}
      assert opts == ListedInfoWorker.normalize_opts(opts)
    end

    test "文字列キーのマップを渡した場合、そのまま返す" do
      opts = %{"key1" => "value1", "key2" => "value2"}
      assert opts == ListedInfoWorker.normalize_opts(opts)
    end
  end

  describe "fetch_data/1" do
    test "ListedInfo.get_listed_info/0を呼び出し、その結果を返す" do
      expected_companies = [
        %{
          "Date" => "2024-03-20",
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

      ListedInfoMock
      |> expect(:get_listed_info, 1, fn -> {:ok, expected_companies} end)

      assert {:ok, ^expected_companies} = ListedInfoWorker.fetch_data(%{})
    end

    test "ListedInfo.get_listed_info/0がエラーを返した場合、エラーを返す" do
      error_reason = "API error"
      ListedInfoMock
      |> expect(:get_listed_info, 1, fn -> {:error, error_reason} end)

      assert {:error, ^error_reason} = ListedInfoWorker.fetch_data(%{})
    end
  end

  describe "perform/1" do
    # Todo:
    # test "正常系: 上場企業情報の取得に成功し、次のジョブがスケジュールされる" do
    #   expected_companies = [
    #     %{
    #       "Date" => "2024-03-20",
    #       "Code" => "86970",
    #       "CompanyName" => "日本取引所グループ"
    #     }
    #   ]

    #   job = %Oban.Job{
    #     args: %{},
    #     meta: %{"is_one_time" => false, "cron_expression" => "0 0 * * *"},
    #     attempt: 1,
    #     max_attempts: 3,
    #     id: "test-job-id"
    #   }

    #   # ListedInfoMock
    #   # |> expect(:get_listed_info, 1, fn -> {:ok, expected_companies} end)

    #   # ジョブを実行
    #   assert :ok = ListedInfoWorker.perform(job)

    #   # 次のジョブがスケジュールされたことを確認
    #   assert_receive {:log, :info, "Scheduled new " <> _worker, %{
    #     cron_expression: "0 0 * * *",
    #     opts: %{},
    #     worker: ListedInfoWorker
    #   }}
    # end

    test "異常系: 上場企業情報の取得に失敗し、エラーが返される" do
      error_reason = "API error"
      job = %Oban.Job{
        args: %{},
        meta: %{"is_one_time" => false, "cron_expression" => "0 0 * * *"},
        attempt: 1,
        max_attempts: 3,
        id: "test-job-id"
      }

      ListedInfoMock
      |> expect(:get_listed_info, 1, fn -> {:error, error_reason} end)

      assert {:error, ^error_reason} = ListedInfoWorker.perform(job)
    end

    test "1回限りのジョブの場合、次のジョブはスケジュールされない" do
      expected_companies = [
        %{
          "Date" => "2024-03-20",
          "Code" => "86970",
          "CompanyName" => "日本取引所グループ"
        }
      ]

      job = %Oban.Job{
        args: %{},
        meta: %{"is_one_time" => true, "cron_expression" => "0 0 * * *"},
        attempt: 1,
        max_attempts: 3,
        id: "test-job-id"
      }

      ListedInfoMock
      |> expect(:get_listed_info, 1, fn -> {:ok, expected_companies} end)

      assert :ok = ListedInfoWorker.perform(job)

      # 次のジョブがスケジュールされていないことを確認
      refute_receive {:log, :info, "Scheduled new " <> _worker, _}
    end

    # Todo:
    # test "最大試行回数に達した場合、次のジョブがスケジュールされる" do
    #   error_reason = "API error"
    #   job = %Oban.Job{
    #     args: %{},
    #     meta: %{"is_one_time" => false, "cron_expression" => "0 0 * * *"},
    #     attempt: 3,
    #     max_attempts: 3,
    #     id: "test-job-id"
    #   }

    #   # ジョブを実行
    #   assert {:error, ^error_reason} = ListedInfoWorker.perform(job)

    #   # 次のジョブがスケジュールされたことを確認
    #   assert_receive {:log, :info, "Scheduled new " <> _worker, %{
    #     cron_expression: "0 0 * * *",
    #     opts: %{},
    #     worker: ListedInfoWorker
    #   }}
    # end
  end
end
