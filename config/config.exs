# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :genai, :local_llama,
       enabled: true,
       otp_app: :genai

# Media-generation provider registry (ADR-016 / ede43647). The capability Router
# (GenAI.Media.Router) enumerates these to route a GenAI.Media.Request to a provider
# that declares its (input, output) modality. Consumers can override per-environment.
config :genai, :media_providers, [
  GenAI.Provider.OpenAI.Image,
  GenAI.Provider.Gemini.Image
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
