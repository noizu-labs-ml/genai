import Config
config :junit_formatter,
       report_file: "results.xml",
       print_report_file: true

config :genai, :mistral,
   api_key: System.get_env("MISTRAL_API_KEY")

config :genai, :groq,
       api_key: System.get_env("GROQ_API_KEY")

config :genai, :gemini,
       api_key: System.get_env("GEMINI_API_KEY")

config :genai, :openai,
       api_key: System.get_env("OPENAI_API_KEY")

config :genai, :anthropic,
       api_key: System.get_env("ANTHROPIC_API_KEY")

config :genai, :xai,
       api_key: System.get_env("XAI_API_KEY")

config :genai, :deepseek,
       api_key: System.get_env("DEEPSEEK_API_KEY")