defmodule Mixpanel.Client.State do
  @moduledoc false

  @type project_token :: String.t()
  @type base_url :: String.t()
  @type http_adapter :: module()
  @type name :: atom

  @type option ::
          {:project_token, project_token}
          | {:base_url, base_url}
          | {:http_adapter, http_adapter}
          | {:name, name}

  @type t :: %__MODULE__{
          project_token: project_token,
          base_url: base_url,
          http_adapter: http_adapter,
          name: name,
          span: nil | Mixpanel.Telemetry.t()
        }

  @enforce_keys [:project_token, :base_url, :http_adapter, :name]
  defstruct @enforce_keys ++ [:span]

  @spec new([option, ...]) :: t()
  def new(opts) do
    project_token = Keyword.fetch!(opts, :project_token)
    base_url = Keyword.fetch!(opts, :base_url)
    http_adapter = Keyword.fetch!(opts, :http_adapter)
    name = Keyword.fetch!(opts, :name)

    %__MODULE__{
      project_token: project_token,
      base_url: base_url,
      http_adapter: http_adapter,
      name: name
    }
  end

  @spec attach_span(t(), Mixpanel.Telemetry.t()) :: t()
  def attach_span(state, span) do
    %__MODULE__{state | span: span}
  end
end
