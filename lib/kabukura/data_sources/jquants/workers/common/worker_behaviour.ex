defmodule Kabukura.DataSources.JQuants.Workers.Common.WorkerBehaviour do
  @moduledoc """
  ワーカーの共通振る舞いを定義するBehaviourモジュール。
  各ワーカーはこのBehaviourを実装する必要があります。
  """

  @doc """
  ジョブの実行に必要なパラメータを検証します。

  ## パラメータ
    - `args`: 検証対象のパラメータ（マップ形式）

  ## 戻り値
    - `{:ok, validated_params}` - 検証成功時、検証済みパラメータ
    - `{:error, reason}` - 検証失敗時、エラー理由
  """
  @callback validate_params(args :: map()) :: {:ok, map()} | {:error, String.t()}

  @doc """
  実際のデータ取得処理を実行します。

  ## パラメータ
    - `params`: 検証済みのパラメータ（マップ形式）

  ## 戻り値
    - `{:ok, data}` - 取得成功時、取得データ
    - `{:error, reason}` - 取得失敗時、エラー理由
  """
  @callback fetch_data(params :: map()) :: {:ok, any()} | {:error, any()}

  @doc """
  オプションを正規化します。

  ## パラメータ
    - `opts`: 正規化対象のオプション（マップ形式）

  ## 戻り値
    - 正規化されたオプション（マップ形式）
  """
  @callback normalize_opts(opts :: map()) :: map()

  @doc """
  ジョブの実行結果を処理します。

  ## パラメータ
    - `result`: ジョブの実行結果
    - `meta`: ジョブのメタデータ
    - `attempt`: 現在の試行回数
    - `max_attempts`: 最大試行回数

  ## 戻り値
    - `:ok` - 処理成功時
    - `{:error, reason}` - 処理失敗時、エラー理由
  """
  @callback handle_result(result :: {:ok, any()} | {:error, any()}, meta :: map(), attempt :: integer(), max_attempts :: integer()) :: :ok | {:error, any()}

  @doc """
  次のジョブをスケジュールします。

  ## パラメータ
    - `meta`: ジョブのメタデータ

  ## 戻り値
    - `:ok` - スケジューリング成功時
    - `{:error, reason}` - スケジューリング失敗時、エラー理由
  """
  @callback schedule_next_job(meta :: map()) :: :ok | {:error, any()}
end
