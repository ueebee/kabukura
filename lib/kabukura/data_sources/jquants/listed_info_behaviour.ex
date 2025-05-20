defmodule Kabukura.DataSources.JQuants.ListedInfoBehaviour do
  @moduledoc """
  J-Quants APIから上場企業情報を取得するためのbehaviour
  """

  @callback get_listed_info() :: {:ok, list(map())} | {:error, term()}
  @callback get_listed_info_by_code(String.t()) :: {:ok, list(map())} | {:error, term()}
  @callback get_listed_info_by_date(String.t()) :: {:ok, list(map())} | {:error, term()}
end
