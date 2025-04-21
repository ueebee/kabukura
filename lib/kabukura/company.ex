defmodule Kabukura.Company do
  @moduledoc """
  企業情報を管理するスキーマ
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :code, :string
    field :name, :string
    field :name_en, :string
    field :sector_code_17, :string
    field :sector_name_17, :string
    field :sector_code_33, :string
    field :sector_name_33, :string
    field :scale_category, :string
    field :market_code, :string
    field :market_name, :string
    field :margin_code, :string
    field :margin_name, :string
    field :effective_date, :date

    timestamps()
  end

  @doc """
  企業情報の変更セットを作成します。
  """
  def changeset(company, attrs) do
    company
    |> cast(attrs, [
      :code,
      :name,
      :name_en,
      :sector_code_17,
      :sector_name_17,
      :sector_code_33,
      :sector_name_33,
      :scale_category,
      :market_code,
      :market_name,
      :margin_code,
      :margin_name,
      :effective_date
    ])
    |> validate_required([
      :code,
      :name,
      :effective_date
    ])
    |> unique_constraint(:code, name: :companies_code_effective_date_index)
  end

  @doc """
  J-Quants APIから取得した企業情報をCompanyスキーマの形式に変換します。
  """
  def from_jquants(info) do
    %{
      code: info["Code"],
      name: info["CompanyName"],
      name_en: info["CompanyNameEnglish"],
      sector_code_17: info["Sector17Code"],
      sector_name_17: info["Sector17CodeName"],
      sector_code_33: info["Sector33Code"],
      sector_name_33: info["Sector33CodeName"],
      scale_category: info["ScaleCategory"],
      market_code: info["MarketCode"],
      market_name: info["MarketCodeName"],
      margin_code: info["MarginCode"],
      margin_name: info["MarginCodeName"],
      effective_date: Date.from_iso8601!(info["Date"])
    }
  end
end
