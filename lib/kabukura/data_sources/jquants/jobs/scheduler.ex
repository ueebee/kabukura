defmodule Kabukura.DataSources.JQuants.Jobs.Scheduler do
  @moduledoc """
  定期的なジョブ実行を管理するスケジューラー
  """
  alias Kabukura.DataSources.JQuants.Workers.ListedInfoWorker
  require Logger

  @doc """
  cron形式で上場企業情報取得ジョブをスケジュールします。
  1回限りの実行または定期的な実行を指定できます。

  ## パラメータ
    - `cron_expression`: cron式
      - 定期的な実行: "*/2 * * * *" (2分ごと)
      - 1回限りの実行: "0 15 26 4 *" (4月26日15時)
      - 遅延実行: "@/60 * * * *" (60秒後)
    - `opts`: オプション
      - `:is_one_time` - 1回限りの実行かどうか（デフォルト: false）

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def schedule_listed_info_job_cron(cron_expression, opts \\ []) do
    ListedInfoWorker.create_cron_job(cron_expression, opts)
  end
end
