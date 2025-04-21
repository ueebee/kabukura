defmodule Kabukura.DataSources.JQuants.HTTP do
  @moduledoc """
  J-Quants APIへのHTTPリクエストを担当するモジュール
  """

  @default_timeout 30_000
  @default_retries 3

  defp base_url do
    Application.get_env(:kabukura, :jquants_api_url, "https://api.jquants.com/v1")
  end

  @doc """
  指定されたパスに対してGETリクエストを送信します。

  ## パラメータ
    - `path`: APIのエンドポイントパス
    - `opts`: 追加オプション（オプション）

  ## 戻り値
    - `{:ok, response_body}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def get(path, opts \\ []) do
    with {:ok, id_token} <- Kabukura.DataSources.JQuants.TokenStore.get_valid_id_token(),
         {:ok, response} <- make_request(:get, path, nil, id_token, opts) do
      {:ok, response}
    end
  end

  @doc """
  POSTリクエストを送信します。

  ## パラメータ
    - `path`: APIパス
    - `body`: リクエストボディ
    - `opts`: 追加オプション（オプション）

  ## 戻り値
    - `{:ok, response}` - 成功時
    - `{:error, reason}` - 失敗時
  """
  def post(path, body, opts \\ []) do
    with {:ok, id_token} <- Kabukura.DataSources.JQuants.TokenStore.get_valid_id_token(),
         {:ok, response} <- make_request(:post, path, body, id_token, opts) do
      {:ok, response}
    end
  end

  # プライベート関数

  defp make_request(method, path, body, id_token, opts) do
    url = base_url() <> path
    headers = build_headers(id_token)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    retries = Keyword.get(opts, :retries, @default_retries)

    request_opts = [
      method: method,
      url: url,
      body: body,
      headers: headers,
      receive_timeout: timeout,
      json: true
    ]

    case Req.request(request_opts) do
      {:ok, %{status: status, body: response_body}} when status in 200..299 ->
        {:ok, response_body}

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
          make_request(method, url, body, id_token, Keyword.put(opts, :retries, retries - 1))
        else
          {:error, "HTTP request failed: #{inspect(reason)}"}
        end
    end
  end

  defp build_headers(id_token) do
    [
      {"Authorization", "Bearer #{id_token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp handle_error_response(response_body, default_message) do
    case response_body do
      %{"message" => message} -> {:error, message}
      _ -> {:error, default_message}
    end
  end
end
