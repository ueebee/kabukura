defmodule Kabukura.DataSourceTest do
  use Kabukura.DataCase

  alias Kabukura.DataSource

  describe "data_source" do
    @valid_attrs %{
      name: "Test API",
      description: "Test Description",
      provider_type: "test",
      is_enabled: true,
      base_url: "https://api.test.com/v1",
      api_version: "v1",
      rate_limit_per_minute: 30,
      rate_limit_per_hour: 1000,
      rate_limit_per_day: 10000
    }

    @invalid_attrs %{
      name: nil,
      description: nil,
      provider_type: nil,
      is_enabled: nil,
      base_url: nil,
      api_version: nil,
      rate_limit_per_minute: nil,
      rate_limit_per_hour: nil,
      rate_limit_per_day: nil
    }

    test "changeset with valid attributes" do
      changeset = DataSource.changeset(%DataSource{}, @valid_attrs)
      assert changeset.valid?

      assert get_field(changeset, :name) == "Test API"
      assert get_field(changeset, :description) == "Test Description"
      assert get_field(changeset, :provider_type) == "test"
      assert get_field(changeset, :is_enabled) == true
      assert get_field(changeset, :base_url) == "https://api.test.com/v1"
      assert get_field(changeset, :api_version) == "v1"
      assert get_field(changeset, :rate_limit_per_minute) == 30
      assert get_field(changeset, :rate_limit_per_hour) == 1000
      assert get_field(changeset, :rate_limit_per_day) == 10000
    end

    test "changeset with invalid attributes" do
      changeset = DataSource.changeset(%DataSource{}, @invalid_attrs)
      refute changeset.valid?

      assert errors_on(changeset) |> Map.keys() |> length() == 7
    end

    test "schema default values" do
      data_source = %DataSource{}
      assert data_source.is_enabled == true
    end

    test "changeset with optional description" do
      attrs = Map.drop(@valid_attrs, [:description])
      changeset = DataSource.changeset(%DataSource{}, attrs)
      assert changeset.valid?
    end

    test "changeset with optional api_version" do
      attrs = Map.drop(@valid_attrs, [:api_version])
      changeset = DataSource.changeset(%DataSource{}, attrs)
      assert changeset.valid?
    end
  end

  describe "credentials handling" do
    @credentials %{"email" => "test@example.com", "password" => "secret_password"}

    test "handles nil credentials" do
      attrs = Map.put(@valid_attrs, :credentials, nil)
      changeset = DataSource.changeset(%DataSource{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :encrypted_credentials) == nil
    end

    test "decrypts credentials correctly" do
      # まず暗号化されたデータソースを作成
      attrs = Map.put(@valid_attrs, :credentials, @credentials)
      {:ok, data_source} =
        %DataSource{}
        |> DataSource.changeset(attrs)
        |> Repo.insert()

      # 復号化して元の認証情報と一致することを確認
      decrypted_credentials = DataSource.decrypt_credentials(data_source)
      assert decrypted_credentials == @credentials
    end

    test "returns nil for nil encrypted_credentials" do
      data_source = %DataSource{encrypted_credentials: nil}
      assert DataSource.decrypt_credentials(data_source) == nil
    end
  end
end
