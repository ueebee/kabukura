defmodule Kabukura.Auth.Strategy do
  @moduledoc """
  認証ストラテジーのインターフェースを定義するモジュール。
  各データソースプロバイダーはこのインターフェースを実装する必要があります。
  """

  @doc """
  リフレッシュトークンを取得します。

  ## パラメータ
    - `data_source`: データソースのスキーマ

  ## 戻り値
    - `{:ok, refresh_token}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @callback get_refresh_token(data_source :: struct()) :: {:ok, String.t()} | {:error, any()}

  @doc """
  IDトークンを取得します。

  ## パラメータ
    - `data_source`: データソースのスキーマ

  ## 戻り値
    - `{:ok, id_token}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @callback get_id_token(data_source :: struct()) :: {:ok, String.t()} | {:error, any()}

  @doc """
  トークンが有効かどうかを確認します。

  ## パラメータ
    - `expired_at`: トークンの有効期限

  ## 戻り値
    - `true` - トークンが有効な場合
    - `false` - トークンが期限切れの場合
  """
  @callback is_token_valid?(expired_at :: DateTime.t() | nil) :: boolean()
end
