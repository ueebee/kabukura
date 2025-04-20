defmodule Kabukura.Auth.JQuantsStrategy do
  @moduledoc """
  J-Quants APIの認証ストラテジーを実装するモジュール。
  """

  @behaviour Kabukura.Auth.Strategy

  alias Kabukura.DataSource
  alias Kabukura.DataSources.JQuants.Auth
  alias Kabukura.Repo

  # トークンの有効期間（秒）
  @refresh_token_expiry 7 * 24 * 60 * 60  # 1週間
  @id_token_expiry 24 * 60 * 60  # 24時間

  @doc """
  J-Quants APIのリフレッシュトークンを取得します。
  既存のトークンが有効な場合はそれを返し、無効な場合は新しいトークンを取得します。

  ## パラメータ
    - `data_source`: データソースのスキーマ

  ## 戻り値
    - `{:ok, refresh_token}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @impl true
  def get_refresh_token(data_source) do
    credentials = DataSource.decrypt_credentials(data_source)
    case Auth.get_refresh_token_from_encrypted(credentials) do
      {:ok, %{refresh_token: refresh_token, expired_at: expired_at}} ->
        case data_source
            |> DataSource.changeset(%{
              refresh_token: refresh_token,
              refresh_token_expired_at: expired_at
            })
            |> Repo.update() do
          {:ok, updated_data_source} -> {:ok, updated_data_source.refresh_token}
          {:error, changeset} -> {:error, "Failed to update data source: #{inspect(changeset.errors)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  J-Quants APIのIDトークンを取得します。
  既存のトークンが有効な場合はそれを返し、無効な場合は新しいトークンを取得します。

  ## パラメータ
    - `data_source`: データソースのスキーマ

  ## 戻り値
    - `{:ok, id_token}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  @impl true
  def get_id_token(data_source) do
    case data_source.refresh_token do
      nil ->
        {:error, "Refresh token is not set"}
      refresh_token ->
        case Auth.get_id_token(refresh_token) do
          {:ok, %{id_token: id_token, expired_at: expired_at}} ->
            case data_source
                |> DataSource.changeset(%{
                  id_token: id_token,
                  id_token_expired_at: expired_at
                })
                |> Repo.update() do
              {:ok, updated_data_source} -> {:ok, updated_data_source.id_token}
              {:error, changeset} -> {:error, "Failed to update data source: #{inspect(changeset.errors)}"}
            end

          {:error, reason} ->
            {:error, reason}
        end
    end
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
