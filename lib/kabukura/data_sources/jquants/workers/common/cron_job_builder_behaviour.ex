defmodule Kabukura.DataSources.JQuants.Workers.Common.CronJobBuilderBehaviour do
  @moduledoc """
  cronジョブの作成とスケジューリングの振る舞いを定義するBehaviour
  """

  @doc """
  cron形式でジョブを作成します。

  ## パラメータ
    - `worker_module`: ワーカーモジュール
    - `cron_expression`: cron式
    - `args`: ジョブの引数
    - `opts`: オプション

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  @callback create_cron_job(worker_module :: module(), cron_expression :: String.t(), args :: map(), opts :: keyword() | map()) ::
              {:ok, Oban.Job.t()} | {:error, any()}

  @doc """
  次のジョブをスケジュールします。

  ## パラメータ
    - `worker_module`: ワーカーモジュール
    - `cron_expression`: cron式
    - `opts`: オプション

  ## 戻り値
    - `{:ok, job}` - 成功時、ジョブ情報
    - `{:error, reason}` - 失敗時、エラー理由
  """
  @callback schedule_next_job(worker_module :: module(), cron_expression :: String.t(), opts :: keyword() | map()) ::
              {:ok, Oban.Job.t()} | {:error, any()}
end
