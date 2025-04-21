defmodule Kabukura.DataSources.JQuants.TokenStoreTest do
  use Kabukura.DataCase
  alias Kabukura.DataSources.JQuants.TokenStore
  alias Kabukura.DataSource
  alias Plug.Conn

  setup do
    bypass = Bypass.open()
    Application.put_env(:kabukura, :jquants_api_url, "http://localhost:#{bypass.port}")

    # 既存のデータソースを削除
    Repo.delete_all(DataSource)

    # データソースを作成
    {:ok, data_source} = %DataSource{
      name: "Test J-Quants",
      provider_type: "jquants",
      base_url: "https://api.jquants.com/v1",
      credentials: "test_credentials"
    } |> Repo.insert()

    %{data_source: data_source, bypass: bypass}
  end

  describe "get_valid_id_token/0" do
    test "returns error when no data source exists" do
      # 全てのデータソースを削除
      Repo.delete_all(DataSource)

      assert {:error, "J-Quants data source not found"} = TokenStore.get_valid_id_token()
    end

    test "returns error when credentials are invalid", %{data_source: data_source, bypass: bypass} do
      # TokenStoreの状態をリセット
      :sys.replace_state(TokenStore, fn _state ->
        %{
          id_token: nil,
          id_token_expired_at: nil,
          refresh_token: nil,
          refresh_token_expired_at: nil
        }
      end)

      # Bypassのモックレスポンスをクリア
      Bypass.up(bypass)

      # 無効な認証情報の場合はエラーを返すようにモックレスポンスを設定
      Bypass.expect(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(%{message: "Invalid credentials"}))
      end)

      # 無効な認証情報を設定
      invalid_credentials = %{
        "mailaddress" => "invalid@example.com",
        "password" => "wrong_password"
      }
      changeset = DataSource.changeset(data_source, %{credentials: invalid_credentials})
      {:ok, _} = Repo.update(changeset)

      assert {:error, _} = TokenStore.get_valid_id_token()
    end

    test "successfully retrieves and caches tokens", %{data_source: data_source, bypass: bypass} do
      # TokenStoreの状態をリセット
      :sys.replace_state(TokenStore, fn _state ->
        %{
          id_token: nil,
          id_token_expired_at: nil,
          refresh_token: nil,
          refresh_token_expired_at: nil
        }
      end)

      # モックレスポンスを設定
      Bypass.expect(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{refreshToken: "valid_refresh_token"}))
      end)

      Bypass.expect(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{idToken: "valid_id_token"}))
      end)

      # 有効な認証情報を設定
      valid_credentials = %{
        "mailaddress" => "test@example.com",
        "password" => "valid_password"
      }
      changeset = DataSource.changeset(data_source, %{credentials: valid_credentials})
      {:ok, _} = Repo.update(changeset)

      # 初回のトークン取得
      assert {:ok, id_token} = TokenStore.get_valid_id_token()
      assert is_binary(id_token)

      # 2回目の呼び出しで同じトークンが返されることを確認
      assert {:ok, ^id_token} = TokenStore.get_valid_id_token()
    end

    test "refreshes token when expired", %{data_source: data_source, bypass: bypass} do
      # 初回のモックレスポンスを設定
      Bypass.expect(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{refreshToken: "valid_refresh_token"}))
      end)

      Bypass.expect(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{idToken: "valid_id_token"}))
      end)

      # 有効な認証情報を設定
      valid_credentials = %{
        "mailaddress" => "test@example.com",
        "password" => "valid_password"
      }
      changeset = DataSource.changeset(data_source, %{credentials: valid_credentials})
      {:ok, _} = Repo.update(changeset)

      # 初回のトークン取得
      assert {:ok, first_token} = TokenStore.get_valid_id_token()

      # トークンの有効期限を過去の時間に設定
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)

      # TokenStoreの状態を完全にリセット
      :sys.replace_state(TokenStore, fn _state ->
        %{
          id_token: nil,
          id_token_expired_at: expired_at,
          refresh_token: nil,
          refresh_token_expired_at: nil
        }
      end)

      # 2回目のモックレスポンスを設定（異なるトークンを返す）
      Bypass.expect(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{refreshToken: "new_refresh_token"}))
      end)

      Bypass.expect(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{idToken: "new_id_token"}))
      end)

      # 新しいトークンが取得されることを確認
      assert {:ok, second_token} = TokenStore.get_valid_id_token()
      assert second_token != first_token
    end
  end
end
