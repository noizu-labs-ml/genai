defmodule GenAI.Provider.LocalLLama do
  @moduledoc """
  This module implements the GenAI provider for Local AI.
  """

  import GenAI.Provider


  @doc """
  Retrieves a list of available Local models.

  This function calls the Local API to retrieve a list of models and returns them as a list of `GenAI.Model` structs.
  """
  def models(settings \\ []) do
    # TODO scan priv/gguf-models/ to get list of models.
    models = [
    ]
    {:ok, models}
  end

  @doc """
  Sends a chat completion request to the Groq API.

  This function constructs the request body based on the provided messages, tools, and settings, sends the request to the Groq API, and returns a `GenAI.ChatCompletion` struct with the response.
  """
  def chat(messages, tools, settings) do
    messages = Enum.map(messages, &GenAI.Provider.LocalLLama.MessageProtocol.message/1)


    model = %ExLLama.Model{} =  settings[:model]
#    options = %{}
#               |> with_setting(:max_tokens, settings)
#               |> with_setting(:seed, settings)


    # todo cast completion to GenAI.ChatCompletion
    with {:ok, %{id: id, model: model, seed: seed, choices: choices, usage: usage}} <- ExLLama.chat_completion(model, messages, settings),
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
            m = %GenAI.Model{
              model: mref,
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
