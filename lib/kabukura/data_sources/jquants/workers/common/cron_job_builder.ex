defmodule Kabukura.DataSources.JQuants.Workers.Common.CronJobBuilder do
  @moduledoc """
  cronジョブの作成とスケジューリングを担当する共通モジュール
  """

  require Logger

  @doc """
  cron形式でジョブを作成します。
  1回限りの実行または定期的な実行を指定できます。

  ## パラメータ
    - `worker_module`: ワーカーモジュール
    - `cron_expression`: cron式（例: "0 0 * * *" または "0 15 26 4 *"）
    - `args`: ジョブの引数
    - `opts`: オプション
      - `:is_one_time` - 1回限りの実行かどうか（デフォルト: false）

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def create_cron_job(worker_module, cron_expression, args \\ %{}, opts \\ []) do
    is_one_time = if is_list(opts), do: Keyword.get(opts, :is_one_time, false), else: Map.get(opts, "is_one_time", false)

    # cron式を解析して次の実行時間を計算
    case Crontab.CronExpression.Parser.parse(cron_expression) do
      {:ok, parsed_expression} ->
        next_execution = Crontab.Scheduler.get_next_run_date!(parsed_expression, NaiveDateTime.utc_now())
        |> DateTime.from_naive!("Etc/UTC")

        # メタデータにcron情報を追加
        # キーワードリストをマップに変換
        opts_map = if is_list(opts), do: Map.new(opts), else: opts
        job = worker_module.new(
          %{args: args},  # argsを渡す
          [
            scheduled_at: next_execution,
            meta: %{
              cron_expression: cron_expression,
              is_cron_job: true,
              is_one_time: is_one_time,
              is_recurring: !is_one_time,
              opts: opts_map  # optsをそのまま保存
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
