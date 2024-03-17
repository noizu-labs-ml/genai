GenAI Library
====
GenAI Elixir Library: A Framework for Interacting with Generative AI

**Version:** 0.0.1

This repository contains an Elixir library for interacting with various generative AI providers and models through a common interface. The library is designed to be flexible, extensible, and easy to use.

### Features

* **Protocol-based design:** Allows for easy integration of new providers and message types.
* **Modular structure:** Well-organized code for improved maintainability and clarity.
* **Support for multiple providers:** Currently supports OpenAI, Anthropic, Mistral, and Gemini.
* **Tool integration:** Enables extending the capabilities of the framework by integrating external tools, even with models that don't have native tool support, through system prompts and custom parsing.
* **Dynamic chat chain support:** Allows for building complex conversational AI systems with multiple steps and dynamic model selection.

### Getting Started

1. Add the `gen_ai` dependency to your `mix.exs` file:

```elixir
def deps do
  [
    {:gen_ai, "~> 0.0.1"}
  ]
end
```

2. Configure your API keys and other settings in your application environment.

```

config :genai, :mistral,
   api_key: System.get_env("MISTRAL_API_KEY")

config :genai, :gemini,
       api_key: System.get_env("GEMINI_API_KEY")

config :genai, :openai,
       api_key: System.get_env("OPENAI_API_KEY")
       api_org: System.get_env("OPTIONAL_OPENAI_API_ORG")

config :genai, :anthropic,
       api_key: System.get_env("ANTHROPIC_API_KEY")

```

3. Start interacting with generative AI models using the provided functions and protocols.

### Example Usage

```elixir
# Create a chat context
chat = GenAI.chat()

# Set the model and API key
chat = chat
  |> GenAI.with_model(GenAI.Provider.OpenAI.Models.gpt_3_5_turbo())
  |> GenAI.with_api_key(GenAI.Provider.OpenAI, "YOUR_API_KEY")

# Add a message to the conversation
chat = GenAI.with_message(chat, %GenAI.Message{role: :user, content: "Hello!"})

# Run inference and get the response
{:ok, response} = GenAI.run(chat)

# Print the response message
IO.puts response.choices[0].message.content
```

### Extending the Library with Additional Model Providers

The GenAI library is designed to be easily extensible with new model providers. Here's how to add support for a new provider:

1. **Create a new provider module:** Create a new module under the `GenAI.Provider` namespace, for example, `GenAI.Provider.NewProvider`.
2. **Implement the `GenAIProtocol`:** Implement the following functions defined in the `GenAIProtocol` for your new provider module:
    * `chat(messages, tools, settings)`
    * `models(settings)`
3. **Handle provider-specific details:** Implement any provider-specific logic, such as handling authentication, constructing API requests, and parsing responses.
4. **(Optional) Implement tool protocols:** If the provider supports tool integration, implement the following protocols:
    * `GenAI.Provider.NewProvider.ToolProtocol`
    * `GenAI.Provider.NewProvider.MessageProtocol`
5. **Add tests:** Write unit and integration tests for your new provider module to ensure it works as expected.

Once you have implemented the provider module and protocols, you can use it with the GenAI library just like any other supported provider.

### Future Features

* **Response tree execution:** Implement a dedicated `GenAI.ResponseTree` module to define and execute complex response plan trees with conditional branching and different actions at each node.
* **Streaming support:** Implement the `stream` function for real-time interaction with models that offer this feature.
* **Enhanced model selection:** Improve the model selection logic to consider factors like cost, performance, and context size.
* **Improved error handling:** Provide more specific and informative error messages.
* **Comprehensive tests:** Expand the test suite to cover more functionalities and edge cases.
* **Detailed documentation:** Add comprehensive documentation for all modules and functions.
* **Support for more providers:** Explore the possibility of adding support for other generative AI providers and models.
* **Caching mechanism:** Implement a caching system to improve performance and reduce costs.
* **Logging and analysis:** Develop a mechanism for logging and analyzing interactions with generative AI models.

### Contributing

Contributions are welcome! Please see the `CONTRIBUTING.md` file for guidelines.

### License

This library is released under the MIT License.
