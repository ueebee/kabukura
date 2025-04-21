defmodule Kabukura.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :code, :string, null: false
      add :name, :string, null: false
      add :name_en, :string
      add :sector_code_17, :string
      add :sector_name_17, :string
      add :sector_code_33, :string
      add :sector_name_33, :string
      add :scale_category, :string
      add :market_code, :string
      add :market_name, :string
      add :margin_code, :string
      add :margin_name, :string
      add :effective_date, :date, null: false

      timestamps()
    end

    # 企業コードと有効日の組み合わせでユニーク制約を設定
    create unique_index(:companies, [:code, :effective_date], name: :companies_code_effective_date_index)
  end
end
