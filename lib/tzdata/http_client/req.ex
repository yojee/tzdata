defmodule Tzdata.HTTPClient.Req do
  @moduledoc false

  @behaviour Tzdata.HTTPClient

  if Code.ensure_loaded?(Req) do
    @impl true
    def get(url, headers, options) do
      with {:ok, %Req.Response{status: status, headers: resp_headers, body: body}} <-
             Req.get(url, req_options(headers, options)) do
        {:ok, {status, normalize_headers(resp_headers), body}}
      end
    end

    @impl true
    def head(url, headers, options) do
      with {:ok, %Req.Response{status: status, headers: resp_headers}} <-
             Req.request([method: :head, url: url] ++ req_options(headers, options)) do
        {:ok, {status, normalize_headers(resp_headers)}}
      end
    end

    defp req_options(headers, options) do
      [
        headers: headers,
        # tzdata writes the body straight to disk and untars it; keep it raw.
        decode_body: false,
        retry: false,
        redirect: Keyword.get(options, :follow_redirect, false)
      ]
    end

    # Req returns headers as a map of `%{name => [values]}` with lowercased
    # names; Tzdata expects a list of `{name, value}` tuples.
    defp normalize_headers(headers) when is_map(headers) do
      Enum.flat_map(headers, fn {name, values} ->
        Enum.map(List.wrap(values), &{name, to_string(&1)})
      end)
    end

    defp normalize_headers(headers) when is_list(headers), do: headers
  else
    @message """
    missing :req dependency

    Tzdata requires a HTTP client in order to automatically update timezone
    database.

    In order to use the adapter based on the Req HTTP client, add the following
    to your mix.exs dependencies list:

        {:req, "~> 0.6"}

    See README for more information.
    """

    @impl true
    def get(_url, _headers, _options) do
      raise @message
    end

    @impl true
    def head(_url, _headers, _options) do
      raise @message
    end
  end
end
