defmodule Kabukura.DataSources.JQuants.ListedInfo do
  @moduledoc """
  J-Quants APIから上場銘柄一覧データを取得するモジュール
  """

  alias Kabukura.DataSources.JQuants.HTTP

  @doc """
  上場銘柄一覧を取得します。

  ## パラメータ
    - `opts`: オプション（オプション）
      - `code`: 銘柄コード（オプション）
      - `date`: 基準日（オプション、形式: YYYYMMDD または YYYY-MM-DD）

  ## 戻り値
    - `{:ok, info}` - 成功時、infoには上場銘柄一覧が含まれます
    - `{:error, reason}` - 失敗時
  """
  def get_listed_info(opts \\ []) do
    path = "/listed/info"
    query_params = build_query_params(opts)
    path_with_params = path <> query_params

    case HTTP.get(path_with_params) do
      {:ok, %{"info" => info}} -> {:ok, info}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  指定された銘柄コードの上場銘柄情報を取得します。

  ## パラメータ
    - `code`: 銘柄コード（4桁または5桁）

  ## 戻り値
    - `{:ok, info}` - 成功時、infoには銘柄情報が含まれます
    - `{:error, reason}` - 失敗時
  """
  def get_listed_info_by_code(code) when is_binary(code) do
    get_listed_info(code: code)
  end

  @doc """
  指定された日付の上場銘柄一覧を取得します。

  ## パラメータ
    - `date`: 基準日（形式: YYYYMMDD または YYYY-MM-DD）

  ## 戻り値
    - `{:ok, info}` - 成功時、infoには上場銘柄一覧が含まれます
    - `{:error, reason}` - 失敗時
  """
  def get_listed_info_by_date(date) when is_binary(date) do
    get_listed_info(date: date)
  end

  # プライベート関数

  defp build_query_params(opts) do
    params = []
    params = if code = Keyword.get(opts, :code), do: params ++ [{"code", code}], else: params
    params = if date = Keyword.get(opts, :date), do: params ++ [{"date", date}], else: params

    case params do
      [] -> ""
      _ -> "?" <> URI.encode_query(params)
    end
  end
end
