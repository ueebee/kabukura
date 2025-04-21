defmodule Kabukura.DataSources.JQuants.ListedInfo do
  @moduledoc """
  J-Quants APIから上場企業情報を取得し、データベースに保存するモジュール
  """

  alias Kabukura.DataSources.JQuants.HTTP
  alias Kabukura.Company
  alias Kabukura.Repo

  @doc """
  すべての上場企業情報を取得します。

  ## 戻り値
    - `{:ok, companies}` - 成功時、企業情報のリスト
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_listed_info do
    with {:ok, response} <- HTTP.get("/listed/info"),
         {:ok, companies} <- save_companies(response["info"]) do
      {:ok, companies}
    end
  end

  @doc """
  指定された企業コードの上場企業情報を取得します。

  ## パラメータ
    - `code`: 企業コード

  ## 戻り値
    - `{:ok, companies}` - 成功時、企業情報のリスト
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_listed_info_by_code(code) do
    with {:ok, response} <- HTTP.get("/listed/info?code=#{code}"),
         {:ok, companies} <- save_companies(response["info"]) do
      {:ok, companies}
    end
  end

  @doc """
  指定された日付の上場企業情報を取得します。

  ## パラメータ
    - `date`: 日付（YYYY-MM-DD形式）

  ## 戻り値
    - `{:ok, companies}` - 成功時、企業情報のリスト
    - `{:error, reason}` - 失敗時、エラー理由
  """
  def get_listed_info_by_date(date) do
    with {:ok, response} <- HTTP.get("/listed/info?date=#{date}"),
         {:ok, companies} <- save_companies(response["info"]) do
      {:ok, companies}
    end
  end

  # プライベート関数

  defp save_companies(companies) do
    # トランザクション内で企業情報を保存
    Repo.transaction(fn ->
      Enum.map(companies, fn company_info ->
        company_attrs = Company.from_jquants(company_info)

        # 既存の企業情報を検索
        existing_company =
          Repo.get_by(Company,
            code: company_attrs.code,
            effective_date: company_attrs.effective_date
          )

        # 企業情報を保存または更新
        case existing_company do
          nil ->
            %Company{}
            |> Company.changeset(company_attrs)
            |> Repo.insert!()

          company ->
            company
            |> Company.changeset(company_attrs)
            |> Repo.update!()
        end
      end)
    end)
  end
end
