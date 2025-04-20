defmodule Kabukura.DataSource do
  use Ecto.Schema
  import Ecto.Changeset
  alias Kabukura.Encryption
  alias Kabukura.Auth.StrategyRegistry
  require Logger

  schema "data_sources" do
    field :name, :string
    field :description, :string
    field :provider_type, :string
    field :is_enabled, :boolean, default: true
    field :base_url, :string
    field :api_version, :string
    field :rate_limit_per_minute, :integer, default: 60
    field :rate_limit_per_hour, :integer, default: 3600
    field :rate_limit_per_day, :integer, default: 86400
    field :encrypted_credentials, :binary
    field :refresh_token, :string
    field :refresh_token_expired_at, :utc_datetime
    field :id_token, :string
    field :id_token_expired_at, :utc_datetime

    # Virtual fields for credentials
    field :credentials, :map, virtual: true
    field :credentials_json, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(data_source, attrs) do
    Logger.debug("Creating changeset with attrs: #{inspect(attrs)}")
    data_source
    |> cast(attrs, [:name, :description, :provider_type, :is_enabled, :base_url, :api_version, :rate_limit_per_minute, :rate_limit_per_hour, :rate_limit_per_day, :encrypted_credentials, :refresh_token, :refresh_token_expired_at, :id_token, :id_token_expired_at, :credentials, :credentials_json])
    |> validate_required([:name, :provider_type, :is_enabled, :base_url, :rate_limit_per_minute, :rate_limit_per_hour, :rate_limit_per_day])
    |> handle_credentials()
  end

  defp handle_credentials(changeset) do
    Logger.debug("Handling credentials in changeset")
    case get_change(changeset, :credentials) do
      nil ->
        Logger.debug("No credentials change found in changeset")
        changeset
      credentials ->
        Logger.debug("Found credentials to encrypt: #{inspect(credentials)}")
        json = Jason.encode!(credentials)
        Logger.debug("Encoded JSON: #{json}")
        {encrypted, _iv} = Encryption.encrypt(json)
        Logger.debug("Encrypted data length: #{byte_size(encrypted)}")
        put_change(changeset, :encrypted_credentials, encrypted)
    end
  end

  @doc """
  Decrypts the credentials stored in the data source.
  """
  def decrypt_credentials(%__MODULE__{encrypted_credentials: nil}), do: nil
  def decrypt_credentials(%__MODULE__{encrypted_credentials: encrypted_data}) do
    Logger.debug("Attempting to decrypt credentials. Data length: #{byte_size(encrypted_data)}")
    <<iv::binary-12, _tag::binary-16, _ciphertext::binary>> = encrypted_data
    Logger.debug("Extracted IV: #{inspect(iv)}")
    decrypted = Encryption.decrypt(encrypted_data)
    Logger.debug("Decrypted data: #{inspect(decrypted)}")
    Jason.decode!(decrypted)
  end

  @doc """
  リフレッシュトークンを取得します。
  データソースプロバイダーの種類に応じて適切な認証ストラテジーを使用します。

  ## パラメータ
    - `data_source`: データソースのスキーマ

  ## 戻り値
    - `{:ok, refresh_token}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def get_refresh_token(%__MODULE__{} = data_source) do
    with {:ok, strategy} <- StrategyRegistry.get_strategy(data_source.provider_type) do
      strategy.get_refresh_token(data_source)
    else
      {:error, :unsupported_provider} -> {:error, "Unsupported provider type: #{data_source.provider_type}"}
    end
  end

  @doc """
  IDトークンを取得します。
  データソースプロバイダーの種類に応じて適切な認証ストラテジーを使用します。

  ## パラメータ
    - `data_source`: データソースのスキーマ

  ## 戻り値
    - `{:ok, id_token}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def get_id_token(%__MODULE__{} = data_source) do
    with {:ok, strategy} <- StrategyRegistry.get_strategy(data_source.provider_type) do
      strategy.get_id_token(data_source)
    else
      {:error, :unsupported_provider} -> {:error, "Unsupported provider type: #{data_source.provider_type}"}
    end
  end
end
