defmodule Kabukura.Auth.Strategy do
  @moduledoc """
  認証ストラテジーのインターフェースを定義するモジュール。
  各データソースプロバイダーはこのインターフェースを実装する必要があります。
  """

  @doc """
  リフレッシュトークンを取得します。

  ## パラメータ
    - `credentials`: 認証情報（%{"mailaddress" => email, "password" => pass}）

  ## 戻り値
    - `{:ok, %{refresh_token: refresh_token, expired_at: expired_at}}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @callback get_refresh_token(credentials :: map()) :: {:ok, %{refresh_token: String.t(), expired_at: DateTime.t()}} | {:error, any()}

  @doc """
  IDトークンを取得します。

  ## パラメータ
    - `refresh_token`: リフレッシュトークン

  ## 戻り値
    - `{:ok, %{id_token: id_token, expired_at: expired_at}}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @callback get_id_token(refresh_token :: String.t()) :: {:ok, %{id_token: String.t(), expired_at: DateTime.t()}} | {:error, any()}

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
