defmodule Kabukura.DataSources.JQuants.Workers.DailyQuotesWorker do
  @moduledoc """
  株価データを定期的に取得するWorker
  """
  use Oban.Worker, queue: :jquants
  @behaviour Kabukura.DataSources.JQuants.Workers.Common.WorkerBehaviour

  alias Kabukura.DataSources.JQuants.{DailyQuotes, Jobs.Scheduler}
  alias Kabukura.DataSources.JQuants.Workers.Common.{CronJobBuilder, JobLogger}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, meta: meta, attempt: attempt, max_attempts: max_attempts, id: job_id} = job) do
    JobLogger.log_job_start(__MODULE__, job_id, args)
    JobLogger.log_debug(__MODULE__, "Job details", %{job: job})

    with {:ok, params} <- validate_params(args),
         {:ok, stock_prices} <- fetch_data(params),
         :ok <- handle_result({:ok, stock_prices}, meta, attempt, max_attempts) do
      JobLogger.log_job_success(__MODULE__, job_id, %{prices_count: length(stock_prices)})
      :ok
    else
      {:error, reason} = error ->
        JobLogger.log_job_error(__MODULE__, job_id, reason, attempt, max_attempts)
        handle_result(error, meta, attempt, max_attempts)
        error
    end
  end

  @impl true
  def validate_params(args) do
    JobLogger.log_debug(__MODULE__, "Validating parameters", %{args: args})

    # 引数からパラメータを取得
    inner_args = if Map.has_key?(args, "args"), do: Map.get(args, "args"), else: args
    JobLogger.log_debug(__MODULE__, "Inner args", %{inner_args: inner_args})

    code = Map.get(inner_args, "code")
    from_date = Map.get(inner_args, "from")
    to_date = Map.get(inner_args, "to")

    JobLogger.log_debug(__MODULE__, "Extracted params", %{
      code: code,
      from: from_date,
      to: to_date
    })

    validate_required_params(code, from_date, to_date)
  end

  @impl true
  def fetch_data(%{code: code, from: from_date, to: to_date}) do
    JobLogger.log_debug(__MODULE__, "Fetching daily quotes", %{
      code: code,
      from: from_date,
      to: to_date
    })

    case DailyQuotes.get_daily_quotes(code, from_date, to_date) do
      {:ok, stock_prices} ->
        {:ok, stock_prices}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def normalize_opts(opts) do
    case opts do
      nil -> %{}
      opts when is_list(opts) -> Map.new(opts)
      opts when is_map(opts) ->
        case Map.get(opts, "period") do
          "last_7_days" -> Map.put(opts, "period", :last_7_days)
          "last_30_days" -> Map.put(opts, "period", :last_30_days)
          _ -> opts
        end
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

    case Scheduler.schedule_daily_quotes_job_cron(cron_expression, opts) do
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
      - `:code` - 銘柄コード（必須）
      - `:from` - 開始日（YYYY-MM-DD形式、periodが指定されていない場合は必須）
      - `:to` - 終了日（YYYY-MM-DD形式、periodが指定されていない場合は必須）
      - `:period` - 期間指定（from/toと同時に指定した場合はperiodが優先されます）
        - `:last_7_days` - 過去7日間
        - `:last_30_days` - 過去30日間

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def create_cron_job(cron_expression, opts \\ []) do
    # オプションからパラメータを抽出
    code = if is_list(opts), do: Keyword.get(opts, :code), else: Map.get(opts, "code")

    # 期間指定がある場合は日付を計算、ない場合はfrom/toを使用
    args = %{"code" => code}
    |> maybe_put_period_or_dates(opts)

    # 必須パラメータのチェック
    with {:ok, _} <- validate_required_params(code, args["from"], args["to"]) do
      CronJobBuilder.create_cron_job(__MODULE__, cron_expression, args, opts)
    else
      {:error, reason} ->
        JobLogger.log_job_error(__MODULE__, nil, reason, 1, 1)
        {:error, reason}
    end
  end

  # プライベート関数

  # 期間指定または日付指定に基づいて引数を設定
  @spec maybe_put_period_or_dates(map(), keyword()) :: map()
  defp maybe_put_period_or_dates(args, opts) do
    period = Keyword.get(opts, :period)
    from = Keyword.get(opts, :from)
    to = Keyword.get(opts, :to)

    cond do
      period == :last_7_days ->
        {from_date, to_date} = calculate_dates_by_period(:last_7_days)
        Map.put(args, "from", from_date)
        |> Map.put("to", to_date)
      period == :last_30_days ->
        {from_date, to_date} = calculate_dates_by_period(:last_30_days)
        Map.put(args, "from", from_date)
        |> Map.put("to", to_date)
      from != nil and to != nil ->
        Map.put(args, "from", from)
        |> Map.put("to", to)
      true ->
        args
    end
  end

  # 期間に基づいて日付範囲を計算
  defp calculate_dates_by_period(period) do
    today = Date.utc_today()
    case period do
      :last_7_days ->
        {Date.add(today, -7), Date.add(today, -1)}
      :last_30_days ->
        {Date.add(today, -30), Date.add(today, -1)}
    end
  end

  # 必須パラメータの検証
  defp validate_required_params(code, from_date, to_date) do
    cond do
      is_nil(code) ->
        {:error, "Stock code (code) is required"}
      is_nil(from_date) ->
        {:error, "Start date (from) is required"}
      is_nil(to_date) ->
        {:error, "End date (to) is required"}
      true ->
        {:ok, %{code: code, from: from_date, to: to_date}}
    end
  end
end
