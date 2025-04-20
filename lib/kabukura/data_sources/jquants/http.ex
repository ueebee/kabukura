defmodule Kabukura.DataSources.JQuants.HTTP do
  @moduledoc """
  J-Quants APIへのHTTPリクエストを担当するモジュール
  """

  @base_url "https://api.jquants.com/v1"
  @default_timeout 30_000
  @default_retries 3

  @doc """
  指定されたパスに対してGETリクエストを送信します。

  ## パラメータ
    - `path`: APIのエンドポイントパス
    - `id_token`: 認証用のIDトークン

  ## 戻り値
    - `{:ok, response_body}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def get(path, id_token) do
    url = @base_url <> path
    headers = [{"Authorization", "Bearer #{id_token}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 400, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 401, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 403, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 404, body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %{status: 500, body: %{"message" => message}}} ->
        {:error, message}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  POSTリクエストを送信します。

  ## パラメータ
    - `path`: APIパス
    - `id_token`: IDトークン
    - `body`: リクエストボディ
    - `opts`: 追加オプション（オプション）

  ## 戻り値
    - `{:ok, response}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def post(path, id_token, body, opts \\ []) do
    url = @base_url <> path
    headers = build_headers(id_token)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    retries = Keyword.get(opts, :retries, @default_retries)

    make_request(:post, url, body, headers, timeout, retries)
  end

  # プライベート関数

  defp build_url(path, params) do
    base = @base_url <> path
    if Enum.empty?(params) do
      base
    else
      query_string = URI.encode_query(params)
      base <> "?" <> query_string
    end
  end

  defp build_headers(id_token) do
    [
      {"Authorization", "Bearer #{id_token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp make_request(method, url, body, headers, timeout, retries) do
    options = [timeout: timeout]

    case Req.request(method, url, body: body, headers: headers, options: options) do
      {:ok, %{status: status, body: response_body}} when status in 200..299 ->
        case Jason.decode(response_body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, reason} -> {:error, "Failed to decode response: #{reason}"}
        end

      {:ok, %{status: 400, body: response_body}} ->
        handle_error_response(response_body, "Bad Request")

      {:ok, %{status: 401, body: response_body}} ->
        handle_error_response(response_body, "Unauthorized")

      {:ok, %{status: 403, body: response_body}} ->
        handle_error_response(response_body, "Forbidden")

      {:ok, %{status: 404, body: response_body}} ->
        handle_error_response(response_body, "Not Found")

      {:ok, %{status: 429, body: response_body}} ->
        handle_error_response(response_body, "Rate Limit Exceeded")

      {:ok, %{status: 500, body: response_body}} ->
        handle_error_response(response_body, "Internal Server Error")

      {:error, reason} ->
        if retries > 0 do
          :timer.sleep(1000)
          make_request(method, url, body, headers, timeout, retries - 1)
        else
          {:error, "HTTP request failed: #{inspect(reason)}"}
        end
    end
  end

  defp handle_error_response(response_body, default_message) do
    case Jason.decode(response_body) do
      {:ok, %{"message" => message}} -> {:error, message}
      _ -> {:error, default_message}
    end
  end
end
