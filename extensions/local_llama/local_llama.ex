defmodule GenAI.Provider.LocalLLama do
  @moduledoc """
  This module implements the GenAI provider for Local AI.
  """
  @behaviour GenAI.ProviderBehaviour


  #------------------
  # chat/5
  #------------------
  @doc """
  Low level inference, pass in model, messages, tools, and various settings to prepare final provider specific API requires.
  """
  @impl GenAI.ProviderBehaviour
  def chat(model, messages, tools, hyper_parameters, provider_settings \\ [])
  def chat(_model, _messages, _tools, _hyper_parameters, _provider_settings) do
    throw "NYI"
  end

  @doc """
  Retrieves a list of available Local models.

  This function calls the Local API to retrieve a list of models and returns them as a list of `GenAI.Model` structs.
  """
  def models(settings \\ [])
  def models(settings) do
    GenAI.Provider.LocalLLamaManager.models(settings)
  end



  @impl GenAI.ProviderBehaviour
  def format_tool(tool, state)
  def format_tool(tool, state) do
    {:ok, GenAI.Provider.LocalLLama.ToolProtocol.tool(tool), state}
  end

  @impl GenAI.ProviderBehaviour
  def format_message(message, state)
  def format_message(message, state) do
    {:ok, GenAI.Provider.LocalLLama.MessageProtocol.message(message), state}
  end

  @impl GenAI.ProviderBehaviour
  def run(state) do
    provider = __MODULE__
    with {:ok, _provider_settings, state} <- GenAI.Thread.StateProtocol.provider_settings(state, provider),
         {:ok, settings, state} <- GenAI.Thread.StateProtocol.settings(state),
         {:ok, _model = %{external: runner = %ExLLama.Model{}}, state} <- GenAI.Thread.StateProtocol.model(state),
         {:ok, _tools, state} <- GenAI.Thread.StateProtocol.tools(state, provider),
         {:ok, messages, state} <- GenAI.Thread.StateProtocol.messages(state, provider) do
      with {:ok, %{id: id, model: model, seed: _seed, choices: choices, usage: usage}} <- ExLLama.chat_completion(runner, messages, settings),
           %{prompt_tokens: _, total_tokens: _, completion_tokens: _} <- usage do

        usage = %GenAI.ChatCompletion.Usage{
          prompt_tokens: usage.prompt_tokens,
          total_tokens: usage.total_tokens,
          completion_tokens: usage.completion_tokens
        }

        choices = Enum.map(choices, fn choice ->
          %GenAI.ChatCompletion.Choice{
            index: choice.index,
            message: %GenAI.Message{role: :assistant, content: choice.message},
            finish_reason: choice.finish_reason
          }
        end)

        completion = %GenAI.ChatCompletion{
          id: id,
          provider: __MODULE__,
          model: model,
          usage: usage,
          choices: choices
        }
        {:ok, completion, state}
      end
    else
      error = {:error, _} -> error
      error -> {:error, error}
    end
  end



  @doc """
  Sends a chat completion request to the LocalLlama

  This function constructs the request body based on the provided messages, tools, and settings, sends the request to the ExLLama instanceI, and returns a `GenAI.ChatCompletion` struct with the response.
  """
  def chat(messages, _tools, settings) do
    # 1. extend model to track instructions on how to pack/unpack.

    messages = Enum.map(messages, &GenAI.Provider.LocalLLama.MessageProtocol.message/1)


    model = %ExLLama.Model{} =  settings[:model]
#    options = %{}
#               |> with_setting(:max_tokens, settings)
#               |> with_setting(:seed, settings)


    # todo cast completion to GenAI.ChatCompletion
    with {:ok, %{id: id, model: model, seed: _seed, choices: choices, usage: usage}} <- ExLLama.chat_completion(model, messages, settings),
         %{prompt_tokens: _, total_tokens: _, completion_tokens: _} <- usage do

      usage = %GenAI.ChatCompletion.Usage{
        prompt_tokens: usage.prompt_tokens,
        total_tokens: usage.total_tokens,
        completion_tokens: usage.completion_tokens
      }

      choices = Enum.map(choices, fn choice ->
        %GenAI.ChatCompletion.Choice{
          index: choice.index,
          message: %GenAI.Message{role: :assistant, content: choice.message},
          finish_reason: choice.finish_reason
        }
      end)

      completion = %GenAI.ChatCompletion{
        id: id,
        provider: __MODULE__,
        model: model,
        usage: usage,
        choices: choices
      }
      {:ok, completion}
    end
  end

  defmodule Models do
    def priv(path, options \\ nil) do
      priv_dir = cond do
        x = options[:priv_dir] -> {:ok, x}
        otp_app = options[:otp_app] ->
          case :code.priv_dir(otp_app) do
            x = {:error, _} -> x
            x -> {:ok, List.to_string(x)}
          end
        :else ->
          otp_app = Application.get_env(:genai, :local_llama)[:otp_app]
          case :code.priv_dir(otp_app) do
            x = {:error, _} -> x
            x -> {:ok, List.to_string(x)}
          end
      end
      with {:ok, pd} <- priv_dir do
        p = pd <> "/" <> path
        if File.exists?(p) do

          with {:ok, mref} <- ExLLama.load_model(p) do
            %GenAI.ExternalModel{
              handle: UUID.uuid4(),
              manager: GenAI.Provider.LocalLLamaManager,
              external: mref,
              provider: GenAI.Provider.LocalLLama,
              details: %{}, # encoding details, formatter, etc.
            }
            # TODO extend nif to allow for a preload/not yet loaded wrapper
            # That can be populated at runtime using the model_name field.
          end

        else
          {:error, "Model not found"}
        end
      end
    end
  end


end
