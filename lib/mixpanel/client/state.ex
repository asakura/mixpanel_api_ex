defmodule Mixpanel.Client.State do
  @type project_token :: String.t()
  @type base_url :: String.t()

  @type t :: %__MODULE__{
          project_token: project_token,
          base_url: base_url,
          http_adapter: module
        }

  defstruct [:project_token, :base_url, :http_adapter]

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
end
