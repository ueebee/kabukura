defmodule Kabukura.DataSources.JQuants.Workers.Common.JobLoggerTest do
  use Kabukura.DataCase
  alias Kabukura.DataSources.JQuants.Workers.Common.JobLogger
  import ExUnit.CaptureLog
  require Logger

  setup do
    # テスト中はログレベルをすべて出力するように設定
    Logger.configure(level: :debug)
    :ok
  end

  # テスト用のモックワーカーを定義
  defmodule MockWorker do
    use Oban.Worker, queue: :test

    @impl Oban.Worker
    def perform(_job) do
      :ok
    end
  end

  describe "log_job_start/3" do
    test "logs job start information" do
      log = capture_log(fn ->
        JobLogger.log_job_start(MockWorker, "test_job_id", %{"test" => "value"})
      end)

      assert log =~ "[info]"
      assert log =~ "Starting"
      assert log =~ inspect(MockWorker)
      assert log =~ "job execution"
    end
  end

  describe "log_job_success/3" do
    test "logs job success information" do
      log = capture_log(fn ->
        JobLogger.log_job_success(MockWorker, "test_job_id", %{count: 10})
      end)

      assert log =~ "[info]"
      assert log =~ "Successfully completed"
      assert log =~ inspect(MockWorker)
      assert log =~ "job"
    end
  end

  describe "log_job_error/5" do
    test "logs job error information" do
      log = capture_log(fn ->
        JobLogger.log_job_error(MockWorker, "test_job_id", "test error", 1, 3)
      end)

      assert log =~ "[error]"
      assert log =~ "Error in"
      assert log =~ inspect(MockWorker)
      assert log =~ "job execution"
    end
  end

  describe "log_job_scheduled/3" do
    test "logs job scheduling information" do
      log = capture_log(fn ->
        JobLogger.log_job_scheduled(MockWorker, "0 0 * * *", [is_one_time: true])
      end)

      assert log =~ "[info]"
      assert log =~ "Scheduled new"
      assert log =~ inspect(MockWorker)
      assert log =~ "job"
    end
  end

  describe "log_scheduling_error/3" do
    test "logs scheduling error information" do
      log = capture_log(fn ->
        JobLogger.log_scheduling_error(MockWorker, "invalid", "Invalid cron expression")
      end)

      assert log =~ "[error]"
      assert log =~ "Failed to schedule"
      assert log =~ inspect(MockWorker)
      assert log =~ "job"
    end
  end

  describe "log_debug/3" do
    test "logs debug information" do
      log = capture_log(fn ->
        JobLogger.log_debug(MockWorker, "Debug message", %{key: "value"})
      end)

      assert log =~ "[debug]"
      assert log =~ inspect(MockWorker)
      assert log =~ "Debug message"
    end
  end
end
