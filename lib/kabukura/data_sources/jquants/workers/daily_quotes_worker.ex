defmodule Kabukura.DataSources.JQuants.Workers.DailyQuotesWorker do
  @moduledoc """
  株価データを定期的に取得するWorker
  """
  use Oban.Worker, queue: :jquants

  alias Kabukura.DataSources.JQuants.{DailyQuotes, Jobs.Scheduler}
  require Logger
  import Crontab.CronExpression

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, meta: meta, attempt: attempt, max_attempts: max_attempts} = job) do
    Logger.info("Starting DailyQuotesWorker at #{DateTime.utc_now()}")
    Logger.debug("Job details: #{inspect(job, pretty: true)}")
    Logger.debug("Args: #{inspect(args, pretty: true)}")
    Logger.debug("Meta: #{inspect(meta, pretty: true)}")

    # 引数からパラメータを取得
    # argsが二重ネストされている可能性があるため、対応
    inner_args = if Map.has_key?(args, "args"), do: Map.get(args, "args"), else: args
    Logger.debug("Inner args: #{inspect(inner_args, pretty: true)}")

    code = Map.get(inner_args, "code")
    from_date = Map.get(inner_args, "from")
    to_date = Map.get(inner_args, "to")

    Logger.debug("Extracted params: code=#{code}, from=#{from_date}, to=#{to_date}")

    # 必須パラメータのチェック
    with {:ok, _} <- validate_required_params(code, from_date, to_date) do
      # 株価データの取得
      Logger.info("Fetching daily quotes for code=#{code}, from=#{from_date}, to=#{to_date}")
      result = DailyQuotes.get_daily_quotes(code, from_date, to_date)

      case result do
        {:ok, stock_prices} ->
          Logger.info("Successfully fetched #{length(stock_prices)} stock prices")
          # 成功時はis_one_timeがfalseなら次のジョブをスケジュール
          if meta["is_one_time"] == false do
            schedule_next_job(meta)
          end
          :ok
        {:error, reason} ->
          Logger.error("Failed to fetch daily quotes: #{inspect(reason)}")
          # 失敗時、is_one_timeがfalseかつリトライ上限到達時のみ次回スケジュール
          if meta["is_one_time"] == false and attempt >= max_attempts do
            schedule_next_job(meta)
          end
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("Missing required parameters: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # 次のジョブをスケジュールする
  defp schedule_next_job(meta) do
    cron_expression = meta["cron_expression"]
    # キーワードリストをマップに変換
    opts = case meta["opts"] do
      nil -> %{}
      opts when is_list(opts) -> Map.new(opts)
      opts when is_map(opts) ->
        # periodが文字列の場合はアトムに変換
        case Map.get(opts, "period") do
          "last_7_days" -> Map.put(opts, "period", :last_7_days)
          "last_30_days" -> Map.put(opts, "period", :last_30_days)
          _ -> opts
        end
    end
    Logger.debug("Scheduling next cron job with opts: #{inspect(opts, pretty: true)}")
    case Scheduler.schedule_daily_quotes_job_cron(cron_expression, opts) do
      {:ok, _new_job} ->
        Logger.info("Cronジョブの次の実行をスケジュールしました: #{cron_expression}")
      {:error, reason} ->
        Logger.error("Cronジョブの次の実行のスケジュールに失敗しました: #{inspect(reason)}")
    end
  end

  @impl Oban.Worker
  def new(opts \\ []) do
    Oban.Job.new(%{worker: __MODULE__}, opts)
  end

  @doc """
  ジョブを作成します。
  """
  def create_job do
    new() |> Oban.insert()
  end

  @doc """
  指定された時間後にジョブを作成します。

  ## パラメータ
    - `seconds`: 実行までの秒数
    - `opts`: オプション
      - `:code` - 銘柄コード（指定しない場合は全銘柄）
      - `:from` - 開始日（YYYY-MM-DD形式、指定しない場合は当日）
      - `:to` - 終了日（YYYY-MM-DD形式、指定しない場合は当日）
      - `:period` - 期間指定（from/toと同時に指定した場合はperiodが優先されます）
        - `:last_7_days` - 過去7日間
        - `:last_30_days` - 過去30日間

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def create_job_after(seconds, opts \\ []) do
    # オプションからパラメータを抽出
    args = %{}
    |> maybe_put_code(opts)
    |> maybe_put_period_or_dates(opts)

    # ジョブを作成
    new(%{args: args}, [scheduled_in: seconds])
    |> Oban.insert()
  end

  @doc """
  指定された時刻にジョブを作成します。

  ## パラメータ
    - `datetime`: 実行時刻（DateTime形式）
    - `opts`: オプション
      - `:code` - 銘柄コード（指定しない場合は全銘柄）
      - `:from` - 開始日（YYYY-MM-DD形式、指定しない場合は当日）
      - `:to` - 終了日（YYYY-MM-DD形式、指定しない場合は当日）

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def create_job_at(datetime, opts \\ []) do
    # オプションからパラメータを抽出
    args = %{}
    |> maybe_put_code(opts)
    |> maybe_put_from(opts)
    |> maybe_put_to(opts)

    # ジョブを作成
    new(%{args: args}, [scheduled_at: datetime])
    |> Oban.insert()
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
    period = if is_list(opts), do: Keyword.get(opts, :period), else: Map.get(opts, "period")

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
  defp maybe_put_period_or_dates(args, opts) when is_list(opts) do
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

  defp maybe_put_period_or_dates(args, opts) when is_map(opts) do
    period = Map.get(opts, "period") || Map.get(opts, :period)
    from = Map.get(opts, "from") || Map.get(opts, :from)
    to = Map.get(opts, "to") || Map.get(opts, :to)

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

  # オプションから銘柄コードを取得して引数に追加
  defp maybe_put_code(args, opts) do
    case Map.get(opts, "code") do
      nil -> args
      code -> Map.put(args, "code", code)
    end
  end

  # オプションから開始日を取得して引数に追加
  defp maybe_put_from(args, opts) do
    case Map.get(opts, "from") do
      nil -> args
      from -> Map.put(args, "from", from)
    end
  end

  # オプションから終了日を取得して引数に追加
  defp maybe_put_to(args, opts) do
    case Map.get(opts, "to") do
      nil -> args
      to -> Map.put(args, "to", to)
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
      _ ->
        # 未知の期間が指定された場合は当日のみ
        {today, today}
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
