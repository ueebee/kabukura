defmodule Kabukura.Auth.StrategyRegistry do
  @moduledoc """
  認証ストラテジーを管理するレジストリモジュール。
  データソースプロバイダーの種類に応じて適切な認証ストラテジーを取得します。
  """

  @doc """
  データソースプロバイダーの種類に応じて適切な認証ストラテジーを取得します。

  ## パラメータ
    - `provider_type`: データソースプロバイダーの種類

  ## 戻り値
    - `{:ok, strategy_module}` - 成功時
    - `{:error, :unsupported_provider}` - サポートされていないプロバイダーの場合
  """
  def get_strategy(provider_type) do
    case provider_type do
      "jquants" -> {:ok, Kabukura.Auth.JQuantsStrategy}
      _ -> {:error, :unsupported_provider}
    end
  end
end
