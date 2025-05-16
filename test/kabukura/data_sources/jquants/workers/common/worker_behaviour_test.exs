defmodule Kabukura.DataSources.JQuants.Workers.Common.WorkerBehaviourTest do
  use Kabukura.DataCase

  # テスト用のモックワーカーを定義
  defmodule MockWorker do
    @behaviour Kabukura.DataSources.JQuants.Workers.Common.WorkerBehaviour

    @impl true
    def validate_params(params) do
      case params do
        %{required: _} -> {:ok, params}
        _ -> {:error, "Missing required parameter"}
      end
    end

    @impl true
    def fetch_data(_params) do
      {:ok, %{data: "test"}}
    end

    @impl true
    def normalize_opts(opts) do
      case opts do
        %{queue: _} = valid_opts -> valid_opts
        _ -> %{queue: "default"}
      end
    end

    @impl true
    def handle_result(result, meta, attempt, max_attempts) do
      cond do
        attempt >= max_attempts ->
          {:error, "Max attempts reached", meta}
        result == nil ->
          {:error, "Invalid result", meta}
        true ->
          {:ok, result, meta}
      end
    end

    @impl true
    def schedule_next_job(meta) do
      case meta do
        %{cron_expression: expression} when is_binary(expression) ->
          {:ok, meta}
        _ ->
          {:error, "Invalid cron expression"}
      end
    end
  end

  describe "validate_params/1" do
    test "returns :ok with valid params" do
      params = %{required: "value"}
      assert {:ok, ^params} = MockWorker.validate_params(params)
    end

    test "returns error with missing required parameter" do
      params = %{optional: "value"}
      assert {:error, "Missing required parameter"} = MockWorker.validate_params(params)
    end

    test "returns error with nil params" do
      assert {:error, "Missing required parameter"} = MockWorker.validate_params(nil)
    end
  end

  describe "fetch_data/1" do
    test "returns :ok with data" do
      params = %{test: "value"}
      assert {:ok, %{data: "test"}} = MockWorker.fetch_data(params)
    end

    test "handles empty params" do
      assert {:ok, %{data: "test"}} = MockWorker.fetch_data(%{})
    end
  end

  describe "normalize_opts/1" do
    test "returns normalized options" do
      opts = %{test: "value", queue: "custom"}
      assert ^opts = MockWorker.normalize_opts(opts)
    end

    test "adds default queue when missing" do
      opts = %{test: "value"}
      assert %{queue: "default"} = MockWorker.normalize_opts(opts)
    end

    test "handles nil options" do
      assert %{queue: "default"} = MockWorker.normalize_opts(nil)
    end
  end

  describe "handle_result/4" do
    test "handles successful result" do
      result = %{data: "test"}
      meta = %{attempt: 1}
      attempt = 1
      max_attempts = 3

      assert {:ok, ^result, ^meta} = MockWorker.handle_result(result, meta, attempt, max_attempts)
    end

    test "returns error when max attempts reached" do
      result = %{data: "test"}
      meta = %{attempt: 3}
      attempt = 3
      max_attempts = 3

      assert {:error, "Max attempts reached", ^meta} =
        MockWorker.handle_result(result, meta, attempt, max_attempts)
    end

    test "returns error with nil result" do
      meta = %{attempt: 1}
      attempt = 1
      max_attempts = 3

      assert {:error, "Invalid result", ^meta} =
        MockWorker.handle_result(nil, meta, attempt, max_attempts)
    end
  end

  describe "schedule_next_job/1" do
    test "schedules next job successfully" do
      meta = %{cron_expression: "0 0 * * *"}
      assert {:ok, ^meta} = MockWorker.schedule_next_job(meta)
    end

    test "returns error with invalid cron expression" do
      meta = %{cron_expression: nil}
      assert {:error, "Invalid cron expression"} = MockWorker.schedule_next_job(meta)
    end

    test "returns error with missing cron expression" do
      meta = %{other: "value"}
      assert {:error, "Invalid cron expression"} = MockWorker.schedule_next_job(meta)
    end
  end
end
