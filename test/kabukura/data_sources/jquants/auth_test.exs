defmodule Kabukura.DataSources.JQuants.AuthTest do
  use Kabukura.DataCase
  use ExUnit.Case, async: true

  alias Kabukura.DataSources.JQuants.Auth

  setup do
    bypass = Bypass.open()
    Application.put_env(:kabukura, :jquants_api_url, "http://localhost:#{bypass.port}")
    {:ok, bypass: bypass}
  end

  describe "get_refresh_token/2" do
    test "successfully gets refresh token with valid credentials", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{refreshToken: "valid_refresh_token"}))
      end)

      assert {:ok, %{refresh_token: "valid_refresh_token", expired_at: expired_at}} =
               Auth.get_refresh_token("test@example.com", "password")

      # 有効期限が1週間後であることを確認
      expected_expiry = DateTime.utc_now() |> DateTime.add(7 * 24 * 60 * 60, :second) |> DateTime.truncate(:second)
      assert DateTime.compare(expired_at, expected_expiry) in [:eq, :gt]
    end

    test "returns error with invalid credentials", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(%{message: "Invalid credentials"}))
      end)

      assert {:error, "Invalid credentials"} = Auth.get_refresh_token("invalid@example.com", "wrong_password")
    end
  end

  describe "get_id_token/1" do
    test "successfully gets id token with valid refresh token", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{idToken: "valid_id_token"}))
      end)

      assert {:ok, %{id_token: "valid_id_token", expired_at: expired_at}} =
               Auth.get_id_token("valid_refresh_token")

      # 有効期限が24時間後であることを確認
      expected_expiry = DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second) |> DateTime.truncate(:second)
      assert DateTime.compare(expired_at, expected_expiry) in [:eq, :gt]
    end

    test "returns error with invalid refresh token", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/token/auth_refresh", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(%{message: "Invalid refresh token"}))
      end)

      assert {:error, "Invalid refresh token"} = Auth.get_id_token("invalid_refresh_token")
    end
  end

  describe "get_refresh_token_from_encrypted/1" do
    test "successfully gets refresh token with valid encrypted credentials", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/token/auth_user", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{refreshToken: "valid_refresh_token"}))
      end)

      encrypted_credentials = %{
        "mailaddress" => "test@example.com",
        "password" => "password"
      }

      assert {:ok, %{refresh_token: "valid_refresh_token", expired_at: _expired_at}} =
               Auth.get_refresh_token_from_encrypted(encrypted_credentials)
    end

    test "returns error with invalid encrypted credentials", %{bypass: _bypass} do
      assert {:error, "Invalid credentials format"} = Auth.get_refresh_token_from_encrypted("invalid")
    end
  end

  describe "is_token_valid?/1" do
    test "returns true for valid token expiry" do
      expired_at = DateTime.utc_now() |> DateTime.add(1, :hour)
      assert Auth.is_token_valid?(expired_at)
    end

    test "returns false for expired token" do
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour)
      refute Auth.is_token_valid?(expired_at)
    end

    test "returns false for nil expiry" do
      refute Auth.is_token_valid?(nil)
    end
  end
end
