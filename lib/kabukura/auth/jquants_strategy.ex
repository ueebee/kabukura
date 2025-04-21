defmodule Kabukura.Auth.JQuantsStrategy do
  @moduledoc """
  J-Quants APIの認証ストラテジーを実装するモジュール。
  """

  @behaviour Kabukura.Auth.Strategy

  alias Kabukura.DataSources.JQuants.Auth

  @doc """
  J-Quants APIのリフレッシュトークンを取得します。

  ## パラメータ
    - `credentials`: 認証情報（%{"mailaddress" => email, "password" => pass}）

  ## 戻り値
    - `{:ok, %{refresh_token: refresh_token, expired_at: expired_at}}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @impl true
  def get_refresh_token(credentials) do
    Auth.get_refresh_token_from_encrypted(credentials)
  end

  @doc """
  J-Quants APIのIDトークンを取得します。

  ## パラメータ
    - `refresh_token`: リフレッシュトークン

  ## 戻り値
    - `{:ok, %{id_token: id_token, expired_at: expired_at}}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @impl true
  def get_id_token(refresh_token) do
    Auth.get_id_token(refresh_token)
  end

  @doc """
  トークンが有効かどうかを確認します。

  ## パラメータ
    - `expired_at`: トークンの有効期限

  ## 戻り値
    - `true` - トークンが有効な場合
    - `false` - トークンが期限切れの場合
  """
  @impl true
  def is_token_valid?(nil), do: false
  def is_token_valid?(expired_at) when is_struct(expired_at, DateTime) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    DateTime.compare(now, expired_at) == :lt
  end
end
