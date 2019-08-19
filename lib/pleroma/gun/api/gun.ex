defmodule Pleroma.Gun.API.Gun do
  @behaviour Pleroma.Gun.API

  @gun_keys [
    :connect_timeout,
    :http_opts,
    :http2_opts,
    :protocols,
    :retry,
    :retry_timeout,
    :trace,
    :transport,
    :tls_opts,
    :tcp_opts,
    :ws_opts
  ]

  @impl Pleroma.Gun.API
  def open(host, port, opts) do
    :gun.open(host, port, Map.take(opts, @gun_keys))
  end

  @impl Pleroma.Gun.API
  def info(pid), do: :gun.info(pid)

  @impl Pleroma.Gun.API
  def close(pid), do: :gun.close(pid)
end
