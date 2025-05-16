defmodule Kabukura.DataSources.JQuants.Workers.Common.CronJobBuilderTest do
  use Kabukura.DataCase
  alias Kabukura.DataSources.JQuants.Workers.Common.CronJobBuilder

  # テスト用のモックワーカーを定義
  defmodule MockWorker do
    use Oban.Worker, queue: :test

    @impl Oban.Worker
    def perform(_job) do
      :ok
    end
  end

  describe "create_cron_job/4" do
    test "creates a cron job with valid parameters" do
      cron_expression = "0 0 * * *"
      args = %{"test" => "value"}
      opts = [is_one_time: false]

      assert {:ok, job} = CronJobBuilder.create_cron_job(MockWorker, cron_expression, args, opts)
      assert job.worker == "Kabukura.DataSources.JQuants.Workers.Common.CronJobBuilderTest.MockWorker"
      assert job.args == %{"args" => args}
      assert job.meta["cron_expression"] == cron_expression
      assert job.meta["is_cron_job"] == true
      assert job.meta["is_one_time"] == false
      assert job.meta["is_recurring"] == true
    end

    test "creates a one-time job" do
      cron_expression = "0 15 26 4 *"
      args = %{"test" => "value"}
      opts = [is_one_time: true]

      assert {:ok, job} = CronJobBuilder.create_cron_job(MockWorker, cron_expression, args, opts)
      assert job.meta["is_one_time"] == true
      assert job.meta["is_recurring"] == false
    end

    test "handles empty args and opts" do
      cron_expression = "0 0 * * *"

      assert {:ok, job} = CronJobBuilder.create_cron_job(MockWorker, cron_expression)
      assert job.args == %{"args" => %{}}
      assert job.meta["is_one_time"] == false
      assert job.meta["is_recurring"] == true
    end

    test "returns error with invalid cron expression" do
      cron_expression = "invalid"
      args = %{"test" => "value"}
      opts = [is_one_time: false]

      assert {:error, _reason} = CronJobBuilder.create_cron_job(MockWorker, cron_expression, args, opts)
    end

    test "handles map opts instead of keyword list" do
      cron_expression = "0 0 * * *"
      args = %{"test" => "value"}
      opts = %{"is_one_time" => true}

      assert {:ok, job} = CronJobBuilder.create_cron_job(MockWorker, cron_expression, args, opts)
      assert job.meta["is_one_time"] == true
      assert job.meta["is_recurring"] == false
    end
  end
end
