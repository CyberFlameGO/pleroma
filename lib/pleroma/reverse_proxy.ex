# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.ReverseProxy do
  @range_headers ~w(range if-range)
  @keep_req_headers ~w(accept accept-encoding cache-control if-modified-since) ++
                      ~w(if-unmodified-since if-none-match) ++ @range_headers
  @resp_cache_headers ~w(etag date last-modified)
  @keep_resp_headers @resp_cache_headers ++
                       ~w(content-length content-type content-disposition content-encoding) ++
                       ~w(content-range accept-ranges vary expires)
  @default_cache_control_header "public, max-age=1209600"
  @valid_resp_codes [200, 206, 304]
  @max_read_duration :timer.seconds(30)
  @max_body_length :infinity
  @failed_request_ttl :timer.seconds(60)
  @methods ~w(GET HEAD)

  @cachex Pleroma.Config.get([:cachex, :provider], Cachex)

  def max_read_duration_default, do: @max_read_duration
  def default_cache_control_header, do: @default_cache_control_header

  @moduledoc """
  A reverse proxy.

      Pleroma.ReverseProxy.call(conn, url, options)

  It is not meant to be added into a plug pipeline, but to be called from another plug or controller.

  Supports `#{inspect(@methods)}` HTTP methods, and only allows `#{inspect(@valid_resp_codes)}` status codes.

  Responses are chunked to the client while downloading from the upstream.

  Some request / responses headers are preserved:

  * request: `#{inspect(@keep_req_headers)}`
  * response: `#{inspect(@keep_resp_headers)}`

  Options:

  * `redirect_on_failure` (default `false`). Redirects the client to the real remote URL if there's any HTTP
  errors. Any error during body processing will not be redirected as the response is chunked. This may expose
  remote URL, clients IPs, ….

  * `max_body_length` (default `#{inspect(@max_body_length)}`): limits the content length to be approximately the
  specified length. It is validated with the `content-length` header and also verified when proxying.

  * `max_read_duration` (default `#{inspect(@max_read_duration)}` ms): the total time the connection is allowed to
  read from the remote upstream.

  * `failed_request_ttl` (default `#{inspect(@failed_request_ttl)}` ms): the time the failed request is cached and cannot be retried.

  * `inline_content_types`:
    * `true` will not alter `content-disposition` (up to the upstream),
    * `false` will add `content-disposition: attachment` to any request,
    * a list of whitelisted content types

  * `req_headers`, `resp_headers` additional headers.

  """
  @inline_content_types [
    "image/gif",
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/svg+xml",
    "audio/mpeg",
    "audio/mp3",
    "video/webm",
    "video/mp4",
    "video/quicktime"
  ]

  require Logger
  import Plug.Conn

  @type option() ::
          {:max_read_duration, :timer.time() | :infinity}
          | {:max_body_length, non_neg_integer() | :infinity}
          | {:failed_request_ttl, :timer.time() | :infinity}
          | {:http, []}
          | {:req_headers, [{String.t(), String.t()}]}
          | {:resp_headers, [{String.t(), String.t()}]}
          | {:inline_content_types, boolean() | [String.t()]}
          | {:redirect_on_failure, boolean()}

  @spec call(Plug.Conn.t(), url :: String.t(), [option()]) :: Plug.Conn.t()
  def call(_conn, _url, _opts \\ [])

  def call(conn = %{method: method}, url, opts) when method in @methods do
    client_opts = Keyword.get(opts, :http, [])

    req_headers = build_req_headers(conn.req_headers, opts)

    opts =
      if filename = Pleroma.Web.MediaProxy.filename(url) do
        Keyword.put_new(opts, :attachment_name, filename)
      else
        opts
      end

    with {:ok, nil} <- @cachex.get(:failed_proxy_url_cache, url),
         {:ok, status, headers, body} <- request(method, url, req_headers, client_opts),
         :ok <-
           header_length_constraint(
             headers,
             Keyword.get(opts, :max_body_length, @max_body_length)
           ) do
      conn
      |> put_private(:proxied_url, url)
      |> response(body, status, headers, opts)
    else
      {:ok, true} ->
        conn
        |> error_or_redirect(500, "Request failed", opts)
        |> halt()

      {:ok, status, headers} ->
        conn
        |> put_private(:proxied_url, url)
        |> head_response(status, headers, opts)
        |> halt()

      {:error, {:invalid_http_response, status}} ->
        Logger.error(
          "#{__MODULE__}: request to #{inspect(url)} failed with HTTP status #{status}"
        )

        track_failed_url(url, status, opts)

        conn
        |> put_private(:proxied_url, url)
        |> error_or_redirect(
          status,
          "Request failed: " <> Plug.Conn.Status.reason_phrase(status),
          opts
        )
        |> halt()

      {:error, error} ->
        Logger.error("#{__MODULE__}: request to #{inspect(url)} failed: #{inspect(error)}")
        track_failed_url(url, error, opts)

        conn
        |> put_private(:proxied_url, url)
        |> error_or_redirect(500, "Request failed", opts)
        |> halt()
    end
  end

  def call(conn, _, _) do
    conn
    |> send_resp(400, Plug.Conn.Status.reason_phrase(400))
    |> halt()
  end

  defp request(method, url, headers, opts) do
    Logger.debug("#{__MODULE__} #{method} #{url} #{inspect(headers)}")
    method = method |> String.downcase() |> String.to_existing_atom()

    opts = opts ++ [receive_timeout: @max_read_duration]

    case Pleroma.HTTP.request(method, url, "", headers, opts) do
      {:ok, %Tesla.Env{status: status, headers: headers, body: body}}
      when status in @valid_resp_codes ->
        {:ok, status, downcase_headers(headers), body}

      {:ok, %Tesla.Env{status: status, headers: headers}} when status in @valid_resp_codes ->
        {:ok, status, downcase_headers(headers)}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, {:invalid_http_response, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp response(conn, body, status, headers, opts) do
    Logger.debug("#{__MODULE__} #{status} #{conn.private[:proxied_url]} #{inspect(headers)}")

    conn
    |> put_resp_headers(build_resp_headers(headers, opts))
    |> send_resp(status, body)
  end

  defp head_response(conn, status, headers, opts) do
    Logger.debug("#{__MODULE__} #{status} #{conn.private[:proxied_url]} #{inspect(headers)}")

    conn
    |> put_resp_headers(build_resp_headers(headers, opts))
    |> send_resp(status, "")
  end

  defp error_or_redirect(conn, status, body, opts) do
    if Keyword.get(opts, :redirect_on_failure, false) do
      conn
      |> Phoenix.Controller.redirect(external: conn.private[:proxied_url])
      |> halt()
    else
      conn
      |> send_resp(status, body)
      |> halt
    end
  end

  defp downcase_headers(headers) do
    Enum.map(headers, fn {k, v} ->
      {String.downcase(k), v}
    end)
  end

  defp get_content_type(headers) do
    {_, content_type} =
      List.keyfind(headers, "content-type", 0, {"content-type", "application/octet-stream"})

    [content_type | _] = String.split(content_type, ";")
    content_type
  end

  defp put_resp_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {k, v}, conn ->
      put_resp_header(conn, k, v)
    end)
  end

  defp build_req_headers(headers, opts) do
    headers
    |> downcase_headers()
    |> Enum.filter(fn {k, _} -> k in @keep_req_headers end)
    |> build_req_range_or_encoding_header(opts)
    |> Keyword.merge(Keyword.get(opts, :req_headers, []))
  end

  # Disable content-encoding if any @range_headers are requested (see #1823).
  defp build_req_range_or_encoding_header(headers, _opts) do
    range? = Enum.any?(headers, fn {header, _} -> Enum.member?(@range_headers, header) end)

    if range? && List.keymember?(headers, "accept-encoding", 0) do
      List.keydelete(headers, "accept-encoding", 0)
    else
      headers
    end
  end

  defp build_resp_headers(headers, opts) do
    headers
    |> Enum.filter(fn {k, _} -> k in @keep_resp_headers end)
    |> build_resp_cache_headers(opts)
    |> build_resp_content_disposition_header(opts)
    |> Keyword.merge(Keyword.get(opts, :resp_headers, []))
  end

  defp build_resp_cache_headers(headers, _opts) do
    has_cache? = Enum.any?(headers, fn {k, _} -> k in @resp_cache_headers end)

    cond do
      has_cache? ->
        # There's caching header present but no cache-control -- we need to set our own
        # as Plug defaults to "max-age=0, private, must-revalidate"
        List.keystore(
          headers,
          "cache-control",
          0,
          {"cache-control", @default_cache_control_header}
        )

      true ->
        List.keystore(
          headers,
          "cache-control",
          0,
          {"cache-control", @default_cache_control_header}
        )
    end
  end

  defp build_resp_content_disposition_header(headers, opts) do
    opt = Keyword.get(opts, :inline_content_types, @inline_content_types)

    content_type = get_content_type(headers)

    attachment? =
      cond do
        is_list(opt) && !Enum.member?(opt, content_type) -> true
        opt == false -> true
        true -> false
      end

    if attachment? do
      name =
        try do
          {{"content-disposition", content_disposition_string}, _} =
            List.keytake(headers, "content-disposition", 0)

          [name | _] =
            Regex.run(
              ~r/filename="((?:[^"\\]|\\.)*)"/u,
              content_disposition_string || "",
              capture: :all_but_first
            )

          name
        rescue
          MatchError -> Keyword.get(opts, :attachment_name, "attachment")
        end

      disposition = "attachment; filename=\"#{name}\""

      List.keystore(headers, "content-disposition", 0, {"content-disposition", disposition})
    else
      headers
    end
  end

  defp header_length_constraint(headers, limit) when is_integer(limit) and limit > 0 do
    with {_, size} <- List.keyfind(headers, "content-length", 0),
         {size, _} <- Integer.parse(size),
         true <- size <= limit do
      :ok
    else
      false ->
        {:error, :body_too_large}

      _ ->
        :ok
    end
  end

  defp header_length_constraint(_, _), do: :ok

  defp track_failed_url(url, error, opts) do
    ttl =
      unless error in [:body_too_large, 400, 204] do
        Keyword.get(opts, :failed_request_ttl, @failed_request_ttl)
      else
        nil
      end

    @cachex.put(:failed_proxy_url_cache, url, true, ttl: ttl)
  end
end
