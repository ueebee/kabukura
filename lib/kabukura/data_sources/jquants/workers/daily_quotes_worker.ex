defmodule Kabukura.DataSources.JQuants.Workers.DailyQuotesWorker do
  @moduledoc """
  株価データを定期的に取得するWorker
  """
  use Oban.Worker, queue: :jquants

  alias Kabukura.DataSources.JQuants.{DailyQuotes, Jobs.Scheduler}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, meta: meta, attempt: attempt, max_attempts: max_attempts} = job) do
    Logger.info("Starting DailyQuotesWorker at #{DateTime.utc_now()}")
    Logger.debug("Job details: #{inspect(job, pretty: true)}")

    with {:ok, params} <- extract_and_validate_params(args),
         {:ok, _stock_prices} <- fetch_daily_quotes(params),
         :ok <- handle_successful_fetch(meta, attempt, max_attempts) do
      :ok
    else
      {:error, reason} = error ->
        handle_error(meta, attempt, max_attempts, reason)
        error
    end
  end

  # パラメータの抽出と検証
  defp extract_and_validate_params(args) do
    Logger.debug("Args: #{inspect(args, pretty: true)}")

    # 引数からパラメータを取得
    inner_args = if Map.has_key?(args, "args"), do: Map.get(args, "args"), else: args
    Logger.debug("Inner args: #{inspect(inner_args, pretty: true)}")

    code = Map.get(inner_args, "code")
    from_date = Map.get(inner_args, "from")
    to_date = Map.get(inner_args, "to")

    Logger.debug("Extracted params: code=#{code}, from=#{from_date}, to=#{to_date}")

    validate_required_params(code, from_date, to_date)
  end

  # 株価データの取得
  defp fetch_daily_quotes(%{code: code, from: from_date, to: to_date}) do
    Logger.info("Fetching daily quotes for code=#{code}, from=#{from_date}, to=#{to_date}")
    result = DailyQuotes.get_daily_quotes(code, from_date, to_date)

    case result do
      {:ok, stock_prices} ->
        Logger.info("Successfully fetched #{length(stock_prices)} stock prices")
        {:ok, stock_prices}
      {:error, reason} ->
        Logger.error("Failed to fetch daily quotes: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # 成功時の処理
  defp handle_successful_fetch(meta, _attempt, _max_attempts) do
    if meta["is_one_time"] == false do
      schedule_next_job(meta)
    end
    :ok
  end

  # エラー時の処理
  defp handle_error(meta, attempt, max_attempts, reason) do
    Logger.error("Error occurred: #{inspect(reason)}")

    if meta["is_one_time"] == false and attempt >= max_attempts do
      schedule_next_job(meta)
    end
  end

  # 次のジョブをスケジュールする
  defp schedule_next_job(meta) do
    cron_expression = meta["cron_expression"]
    opts = normalize_opts(meta["opts"])
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)  # マップをキーワードリストに変換

    Logger.debug("Scheduling next cron job with opts: #{inspect(opts, pretty: true)}")

    case Scheduler.schedule_daily_quotes_job_cron(cron_expression, opts) do
      {:ok, _new_job} ->
        Logger.info("Cronジョブの次の実行をスケジュールしました: #{cron_expression}")
      {:error, reason} ->
        Logger.error("Cronジョブの次の実行のスケジュールに失敗しました: #{inspect(reason)}")
    end
  end

  # オプションの正規化
  defp normalize_opts(nil), do: %{}
  defp normalize_opts(opts) when is_list(opts), do: Map.new(opts)
  defp normalize_opts(opts) when is_map(opts) do
    case Map.get(opts, "period") do
      "last_7_days" -> Map.put(opts, "period", :last_7_days)
      "last_30_days" -> Map.put(opts, "period", :last_30_days)
      _ -> opts
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
    is_one_time = if is_list(opts), do: Keyword.get(opts, :is_one_time, false), else: Map.get(opts, "is_one_time", false)
    _period = if is_list(opts), do: Keyword.get(opts, :period), else: Map.get(opts, "period")

    # オプションからパラメータを抽出
    code = if is_list(opts), do: Keyword.get(opts, :code), else: Map.get(opts, "code")

    # 期間指定がある場合は日付を計算、ない場合はfrom/toを使用
    args = %{"code" => code}
    |> maybe_put_period_or_dates(opts)

    # 必須パラメータのチェック
    with {:ok, _} <- validate_required_params(code, args["from"], args["to"]) do
      # cron式を解析して次の実行時間を計算
      case Crontab.CronExpression.Parser.parse(cron_expression) do
        {:ok, parsed_expression} ->
          next_execution = Crontab.Scheduler.get_next_run_date!(parsed_expression, NaiveDateTime.utc_now())
          |> DateTime.from_naive!("Etc/UTC")

          # メタデータにcron情報を追加
          # キーワードリストをマップに変換
          opts_map = if is_list(opts), do: Map.new(opts), else: opts
          job = new(
            %{args: args},  # argsを渡す
            [
              scheduled_at: next_execution,
              meta: %{
                cron_expression: cron_expression,
                is_cron_job: true,
                is_one_time: is_one_time,
                is_recurring: !is_one_time,
                opts: opts_map
              }
            ]
          )

          # ジョブを登録
          case Oban.insert(job) do
            {:ok, inserted_job} ->
              schedule_type = if is_one_time, do: "1回限り", else: "定期的"
              Logger.info("#{schedule_type}のジョブがスケジュールされました: Cron式 #{cron_expression}, Job ID #{inserted_job.id}")
              {:ok, inserted_job}
            {:error, changeset} ->
              Logger.error("ジョブ投入エラー: #{inspect(changeset)}")
              {:error, changeset}
          end
        {:error, reason} ->
          Logger.error("Cron式のパースエラー: #{inspect(reason)}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("Missing required parameters: #{inspect(reason)}")
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
        {:error, "銘柄コード（code）は必須です"}
      is_nil(from_date) ->
        {:error, "開始日（from）は必須です"}
      is_nil(to_date) ->
        {:error, "終了日（to）は必須です"}
      true ->
        {:ok, %{code: code, from: from_date, to: to_date}}
    end
  end
end
