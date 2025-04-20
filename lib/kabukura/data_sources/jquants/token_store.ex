defmodule Kabukura.DataSources.JQuants.TokenStore do
  @moduledoc """
  J-Quants APIのトークン管理を担当するGenServer
  """

  use GenServer
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  有効なIDトークンを取得します。
  トークンが無効な場合は自動的に更新を試みます。
  """
  def get_valid_id_token do
    GenServer.call(__MODULE__, :get_valid_id_token)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(:get_valid_id_token, _from, state) do
    case get_data_source() do
      {:ok, data_source} ->
        case ensure_valid_token(data_source, state) do
          {:ok, new_state, id_token} ->
            {:reply, {:ok, id_token}, new_state}
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  # Private Functions

  defp get_data_source do
    case Kabukura.Repo.get_by(Kabukura.DataSource, provider_type: "jquants") do
      nil -> {:error, "J-Quants data source not found"}
      data_source -> {:ok, data_source}
    end
  end

  defp ensure_valid_token(data_source, %{id_token: id_token, id_token_expired_at: expired_at} = state)
       when not is_nil(id_token) and not is_nil(expired_at) do
    if Kabukura.Auth.JQuantsStrategy.is_token_valid?(expired_at) do
      {:ok, state, id_token}
    else
      refresh_id_token(data_source, state)
    end
  end
  defp ensure_valid_token(data_source, state), do: refresh_id_token(data_source, state)

  defp refresh_id_token(data_source, %{refresh_token: refresh_token} = state) when not is_nil(refresh_token) do
    case Kabukura.Auth.JQuantsStrategy.get_id_token(refresh_token) do
      {:ok, %{id_token: id_token, expired_at: expired_at}} ->
        new_state = %{state | id_token: id_token, id_token_expired_at: expired_at}
        {:ok, new_state, id_token}
      {:error, _} ->
        # リフレッシュトークンが無効な場合、認証情報から新しいトークンを取得
        get_new_tokens(data_source, state)
    end
  end
  defp refresh_id_token(data_source, state), do: get_new_tokens(data_source, state)

  defp get_new_tokens(data_source, state) do
    Logger.debug("Starting get_new_tokens with state: #{inspect(state)}")

    credentials = Kabukura.DataSource.decrypt_credentials(data_source)
    Logger.debug("Successfully decrypted credentials: #{inspect(credentials)}")

    case Kabukura.Auth.JQuantsStrategy.get_refresh_token(credentials) do
      {:ok, refresh_result} ->
        Logger.debug("Successfully got refresh token: #{inspect(refresh_result)}")
        %{refresh_token: refresh_token, expired_at: refresh_expired_at} = refresh_result

        case Kabukura.Auth.JQuantsStrategy.get_id_token(refresh_token) do
          {:ok, id_result} ->
            Logger.debug("Successfully got id token: #{inspect(id_result)}")
            %{id_token: id_token, expired_at: id_expired_at} = id_result

            new_state = Map.merge(state, %{
              id_token: id_token,
              id_token_expired_at: id_expired_at,
              refresh_token: refresh_token,
              refresh_token_expired_at: refresh_expired_at
            })
            Logger.debug("Updated state: #{inspect(new_state)}")
            {:ok, new_state, id_token}

          {:error, reason} ->
            Logger.error("Failed to get id token: #{inspect(reason)}")
            {:error, "Failed to get id token: #{inspect(reason)}"}

          other ->
            Logger.error("Unexpected response from get_id_token: #{inspect(other)}")
            {:error, "Unexpected response from get_id_token"}
        end

      {:error, reason} ->
        Logger.error("Failed to get refresh token: #{inspect(reason)}")
        {:error, "Failed to get refresh token: #{inspect(reason)}"}

      other ->
        Logger.error("Unexpected response from get_refresh_token: #{inspect(other)}")
        {:error, "Unexpected response from get_refresh_token"}
    end
  end
end
