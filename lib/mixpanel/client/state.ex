defmodule Mixpanel.Client.State do
  @moduledoc false

  @type project_token :: String.t()
  @type base_url :: String.t()

  @type t :: %__MODULE__{
          project_token: project_token,
          base_url: base_url,
          http_adapter: module
        }

  @enforce_keys [:project_token, :base_url, :http_adapter]
  defstruct [:project_token, :base_url, :http_adapter, :span]

  def new(opts) do
    project_token = Keyword.fetch!(opts, :project_token)
    base_url = Keyword.fetch!(opts, :base_url)
    http_adapter = Keyword.fetch!(opts, :http_adapter)

    %__MODULE__{
      project_token: project_token,
      base_url: base_url,
      http_adapter: http_adapter
    }
  end

  @spec attach_span(t(), Mixpanel.Telemetry.t()) :: t()
  def attach_span(state, span) do
    %__MODULE__{state | span: span}
  end

  @spec base_url(t()) :: base_url
  def base_url(state), do: state.base_url

  @spec http_adapter(t()) :: module
  def http_adapter(state), do: state.http_adapter

  @spec span(t()) :: Mixpanel.Telemetry.t()
  def span(state), do: state.span
end
