import Config

config :junit_formatter,
  report_file: "results.xml",
  print_report_file: true

config :genai, :mistral, api_key: System.get_env("MISTRAL_API_KEY")

config :genai, :groq, api_key: System.get_env("GROQ_API_KEY")

config :genai, :gemini, api_key: System.get_env("GEMINI_API_KEY")

config :genai, :openai, api_key: System.get_env("OPENAI_API_KEY")

config :genai, :anthropic, api_key: System.get_env("ANTHROPIC_API_KEY")

config :genai, :xai, api_key: System.get_env("XAI_API_KEY")

config :genai, :deepseek, api_key: System.get_env("DEEPSEEK_API_KEY")

config :genai, :zai, api_key: System.get_env("ZAI_API_KEY")

config :genai, :cerebras, api_key: System.get_env("CEREBRAS_API_KEY")

config :genai, :qwen,
  api_key: System.get_env("QWEN_API_KEY") || System.get_env("DASHSCOPE_API_KEY"),
  base_url:
    System.get_env("QWEN_BASE_URL") || "https://dashscope-intl.aliyuncs.com/compatible-mode/v1"

config :genai, :litellm,
  api_key: System.get_env("LITELLM_API_KEY"),
  base_url: System.get_env("LITELLM_BASE_URL") || "http://localhost:4000"

config :genai, :suno,
  api_key: System.get_env("SUNO_API_KEY"),
  base_url: System.get_env("SUNO_BASE_URL") || "https://api.sunoapi.org"
