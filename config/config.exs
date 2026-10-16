# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :genai, :jev,
  api_key: System.get_env("JEV_API_KEY") || System.get_env("TYPESAFE_API_KEY"),
  base_url: System.get_env("JEV_BASE_URL") || "https://api.typesafe.ai/v1"

# The workspace-specific URL is intentionally not a published default.
config :genai, :qwen,
  api_key: System.get_env("QWEN_API_KEY") || System.get_env("DASHSCOPE_API_KEY"),
  token_api_key: System.get_env("QWEN_TOKEN_KEY"),
  decision_base_url: System.get_env("QWEN_DECISION_BASE_URL"),
  native_base_url: System.get_env("QWEN_NATIVE_BASE_URL")

config :genai, :local_llama,
  enabled: true,
  otp_app: :genai

# Media-generation provider registry (ADR-016 / ede43647). The capability Router
# (GenAI.Media.Router) enumerates these to route a GenAI.Media.Request to a provider
# that declares its (input, output) modality. Specific providers come before the LiteLLM
# proxy so they win for modalities both can serve. Consumers can override per-environment.
config :genai, :media_providers, [
  GenAI.Provider.OpenAI.Image,
  GenAI.Provider.Gemini.Image,
  GenAI.Provider.Qwen.Image,
  GenAI.Provider.OpenAI.Audio,
  GenAI.Provider.OpenAI.Speech,
  GenAI.Provider.Qwen.Speech,
  GenAI.Provider.OpenAI.Transcription,
  GenAI.Provider.Qwen.Video,
  GenAI.Provider.Suno,
  GenAI.Provider.ElevenLabs,
  GenAI.Provider.LiteLLM.Media
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Optional developer overrides live outside published defaults and are gitignored.
# Load after the environment configuration so local endpoints take effect in dev/test.
if config_env() in [:dev, :test] and File.exists?(Path.join(__DIR__, "local.exs")) do
  import_config "local.exs"
end
