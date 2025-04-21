defmodule Kabukura.DataSources.JQuants.Auth do
  @moduledoc """
  J-Quants APIの認証処理を担当するモジュール
  """

  @auth_user_path "/token/auth_user"
  @auth_refresh_path "/token/auth_refresh"

  # トークンの有効期間（秒）
  @refresh_token_expiry 7 * 24 * 60 * 60  # 1週間
  @id_token_expiry 24 * 60 * 60  # 24時間

  defp base_url do
    Application.get_env(:kabukura, :jquants_api_url, "https://api.jquants.com/v1")
  end

  @doc """
  メールアドレスとパスワードを使用してリフレッシュトークンを取得します。

  ## パラメータ
    - `mailaddress`: J-Quantsに登録したメールアドレス
    - `password`: J-Quantsのパスワード

  ## 戻り値
    - `{:ok, %{refresh_token: refresh_token, expired_at: expired_at}}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def get_refresh_token(mailaddress, password) do
    url = base_url() <> @auth_user_path

    case Req.post(url, json: %{mailaddress: mailaddress, password: password}) do
      {:ok, %{status: 200, body: %{"refreshToken" => refresh_token}}} ->
        expired_at = DateTime.utc_now() |> DateTime.add(@refresh_token_expiry, :second) |> DateTime.truncate(:second)
        {:ok, %{refresh_token: refresh_token, expired_at: expired_at}}

      {:ok, %{status: 400, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 403, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 500, body: %{"message" => message}}} ->
        {:error, message}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  リフレッシュトークンを使用してIDトークンを取得します。

  ## パラメータ
    - `refresh_token`: リフレッシュトークン

  ## 戻り値
    - `{:ok, %{id_token: id_token, expired_at: expired_at}}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def get_id_token(refresh_token) do
    url = base_url() <> @auth_refresh_path <> "?refreshtoken=#{refresh_token}"

    case Req.post(url) do
      {:ok, %{status: 200, body: %{"idToken" => id_token}}} ->
        expired_at = DateTime.utc_now() |> DateTime.add(@id_token_expiry, :second) |> DateTime.truncate(:second)
        {:ok, %{id_token: id_token, expired_at: expired_at}}

      {:ok, %{status: 400, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 403, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 500, body: %{"message" => message}}} ->
        {:error, message}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  暗号化された認証情報を使用してリフレッシュトークンを取得します。

  ## パラメータ
    - `encrypted_credentials`: 復号化された認証情報（%{"mailaddress" => email, "password" => pass}）

  ## 戻り値
    - `{:ok, %{refresh_token: refresh_token, expired_at: expired_at}}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def get_refresh_token_from_encrypted(encrypted_credentials) when is_map(encrypted_credentials) do
    get_refresh_token(
      encrypted_credentials["mailaddress"],
      encrypted_credentials["password"]
    )
  end
  def get_refresh_token_from_encrypted(_), do: {:error, "Invalid credentials format"}

  @doc """
  トークンが有効かどうかを確認します。

  ## パラメータ
    - `expired_at`: トークンの有効期限

  ## 戻り値
    - `true` - トークンが有効な場合
    - `false` - トークンが期限切れの場合
  """
  def is_token_valid?(nil), do: false
  def is_token_valid?(expired_at) do
    now = DateTime.utc_now()
    DateTime.compare(now, expired_at) == :lt
  end
end
