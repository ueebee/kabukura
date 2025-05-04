defmodule Kabukura.DataSources.JQuants.Workers.ListedInfoWorker do
  @moduledoc """
  上場企業情報を定期的に取得するWorker
  """
  use Oban.Worker, queue: :jquants

  alias Kabukura.DataSources.JQuants.{ListedInfo, Jobs.Scheduler}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args, meta: meta, attempt: attempt, max_attempts: max_attempts} = _job) do
    Logger.info("Starting ListedInfoWorker at #{DateTime.utc_now()}")

    case ListedInfo.get_listed_info() do
      {:ok, companies} ->
        Logger.info("Successfully fetched #{length(companies)} companies")
        # 成功時はis_one_timeがfalseなら次のジョブをスケジュール
        if meta["is_one_time"] == false do
          cron_expression = meta["cron_expression"]
          case Scheduler.schedule_listed_info_job_cron(cron_expression) do
            {:ok, _new_job} ->
              Logger.info("Cronジョブの次の実行をスケジュールしました: #{cron_expression}")
            {:error, reason} ->
              Logger.error("Cronジョブの次の実行のスケジュールに失敗しました: #{inspect(reason)}")
          end
        end
        :ok
      {:error, reason} ->
        Logger.error("Failed to fetch listed info: #{inspect(reason)}")
        # 失敗時、is_one_timeがfalseかつリトライ上限到達時のみ次回スケジュール
        if meta["is_one_time"] == false and attempt >= max_attempts do
          cron_expression = meta["cron_expression"]
          case Scheduler.schedule_listed_info_job_cron(cron_expression) do
            {:ok, _new_job} ->
              Logger.info("Cronジョブの次の実行をスケジュールしました: #{cron_expression}")
            {:error, reason} ->
              Logger.error("Cronジョブの次の実行のスケジュールに失敗しました: #{inspect(reason)}")
          end
        end
        {:error, reason}
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
    is_one_time = Keyword.get(opts, :is_one_time, false)

    # cron式を解析して次の実行時間を計算
    case Crontab.CronExpression.Parser.parse(cron_expression) do
      {:ok, parsed_expression} ->
        next_execution = Crontab.Scheduler.get_next_run_date!(parsed_expression, NaiveDateTime.utc_now())
        |> DateTime.from_naive!("Etc/UTC")

        # メタデータにcron情報を追加
        job = new(
          %{},  # 空のマップをargsとして渡す
          [
            scheduled_at: next_execution,
            meta: %{
              cron_expression: cron_expression,
              is_cron_job: true,
              is_one_time: is_one_time,
              is_recurring: !is_one_time
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
  end
end
