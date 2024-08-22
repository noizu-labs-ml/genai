defmodule GenAI.Provider do
  def api_call(type, url, headers, body \\ nil, _options \\ []) do
    if body do
      with {:ok, serialized_body} <- Jason.encode(body) do
        Finch.build(type, url, headers, serialized_body)
        |> Finch.request(GenAI.Finch, [pool_timeout: 600_000, receive_timeout: 600_000, request_timeout: 600_000])
      end
    else
      Finch.build(type, url, headers, body)
      |> Finch.request(GenAI.Finch, [pool_timeout: 600_000, receive_timeout: 600_000, request_timeout: 600_000])
    end
  end


  def with_required_setting(body, setting, settings) do
    case settings[setting] do
      nil ->
        raise GenAI.RequestError, "Missing required setting: #{setting}"
      v -> Map.put(body, setting, v)
    end
  end

  def optional_field(body, _, nil), do: body
  def optional_field(body, field, value) do
    Map.put(body, field, value)
  end



  def with_dynamic_setting(body, setting, model, settings, default \\ nil) do
    # TODO - dynamic model setting configuration details.
    # TEMP - for now, dummy check
    with {:ok, model_name} <- GenAI.ModelProtocol.model(model) do
      if model_name in ["o1-preview", "o1-mini"] do
        case setting do
          :temperature -> body # not supported
          x -> with_setting(body, setting, settings, default)
        end
      else
        with_setting(body, setting, settings, default)
      end

    else
      _ ->
        with_setting(body, setting, settings, default)
    end
  end


  def with_dynamic_setting_as(body, as_setting, setting,  model, settings, default \\ nil) do
    # TODO - dynamic model setting configuration details.
    # TEMP - for now, dummy check
    with {:ok, model_name} <- GenAI.ModelProtocol.model(model) do
      if model_name in ["o1-preview", "o1-mini"] do
        case setting do
          :completion_choices -> body # not supported by preview
          :temperature -> body # not supported
          :top_n -> body # not supported
          :presence_penalty -> body # not supported
          :fequency_penalty -> body # not supported
          x -> with_setting_as(body, as_setting, setting, settings, default)
        end
      else
        with_setting_as(body, as_setting, setting, settings, default)
      end
    else
      _ ->
        with_setting_as(body, as_setting, setting, settings, default)
    end
  end


  def with_setting(body, setting, settings, default \\ nil) do
    case settings[setting] do
      nil ->
        unless default == nil do
          Map.put(body, setting, default)
        else
          body
        end
      v -> Map.put(body, setting, v)
    end
  end

  def with_setting_as(body, as_setting, setting, settings, default \\ nil) do
    case settings[setting] do
      nil ->
        unless default == nil do
          Map.put(body, as_setting, default)
        else
          body
        end
      v -> Map.put(body, as_setting, v)
    end
  end

end
