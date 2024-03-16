import Config
config :junit_formatter,
       report_file: "results.xml",
       print_report_file: true

config :genai, :mistral,
   api_key: System.get_env("MISTRAL_API_KEY")

config :genai, :gemini,
       api_key: System.get_env("GEMINI_API_KEY")

config :genai, :openai,
       api_key: System.get_env("OPENAI_API_KEY")

config :genai, :anthropic,
       api_key: System.get_env("ANTHROPIC_API_KEY")
