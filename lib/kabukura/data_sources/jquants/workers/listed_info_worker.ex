defmodule Kabukura.DataSources.JQuants.Workers.ListedInfoWorker do
  @moduledoc """
  上場企業情報を定期的に取得するWorker
  """
  use Oban.Worker, queue: :jquants
  @behaviour Kabukura.DataSources.JQuants.Workers.Common.WorkerBehaviour

  alias Kabukura.DataSources.JQuants.{ListedInfo, Jobs.Scheduler}
  alias Kabukura.DataSources.JQuants.Workers.Common.{CronJobBuilder, JobLogger}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, meta: meta, attempt: attempt, max_attempts: max_attempts, id: job_id} = _job) do
    JobLogger.log_job_start(__MODULE__, job_id, args)

    with {:ok, companies} <- fetch_data(%{}),
         :ok <- handle_result({:ok, companies}, meta, attempt, max_attempts) do
      JobLogger.log_job_success(__MODULE__, job_id, %{companies_count: length(companies)})
      :ok
    else
      {:error, reason} = error ->
        JobLogger.log_job_error(__MODULE__, job_id, reason, attempt, max_attempts)
        handle_result(error, meta, attempt, max_attempts)
        error
    end
  end

  @impl true
  def validate_params(_args) do
    {:ok, %{}}
  end

  @impl true
  def fetch_data(_params) do
    listed_info_module().get_listed_info()
  end

  @impl true
  def normalize_opts(opts) do
    case opts do
      nil -> %{}
      opts when is_list(opts) -> Map.new(opts)
      opts when is_map(opts) -> opts
    end
  end

  @impl true
  def handle_result({:ok, _}, meta, _attempt, _max_attempts) do
    if meta["is_one_time"] == false do
      schedule_next_job(meta)
    end
    :ok
  end

  def handle_result({:error, reason}, meta, attempt, max_attempts) do
    if meta["is_one_time"] == false and attempt >= max_attempts do
      schedule_next_job(meta)
    end
    {:error, reason}
  end

  @impl true
  def schedule_next_job(meta) do
    cron_expression = meta["cron_expression"]
    opts = normalize_opts(meta["opts"])
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)  # マップをキーワードリストに変換

    JobLogger.log_debug(__MODULE__, "Scheduling next cron job", %{opts: opts})

    case Scheduler.schedule_listed_info_job_cron(cron_expression) do
      {:ok, _new_job} ->
        JobLogger.log_job_scheduled(__MODULE__, cron_expression, opts)
      {:error, reason} ->
        JobLogger.log_scheduling_error(__MODULE__, cron_expression, reason)
    end
  end

  @doc """
  cron形式でジョブを作成します。
  1回限りの実行または定期的な実行を指定できます。

  ## パラメータ
    - `cron_expression`: cron式（例: "0 0 * * *" または "0 15 26 4 *"）
    - `opts`: オプション
      - `:is_one_time` - 1回限りの実行かどうか（デフォルト: false）

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def create_cron_job(cron_expression, opts \\ []) do
    CronJobBuilder.create_cron_job(__MODULE__, cron_expression, %{}, opts)
  end

  # プライベート関数

  defp listed_info_module do
    Application.get_env(:kabukura, :listed_info_module, ListedInfo)
  end
end
