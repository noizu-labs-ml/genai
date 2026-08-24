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

config :genai, :openrouter,
  api_key: System.get_env("OPENROUTER_API_KEY"),
  http_referer:
    System.get_env("OPENROUTER_HTTP_REFERER") || "https://github.com/noizu-labs-ml/genai",
  app_title: System.get_env("OPENROUTER_APP_TITLE") || "Noizu GenAI"

config :genai, :qwen,
  api_key: System.get_env("QWEN_API_KEY") || System.get_env("DASHSCOPE_API_KEY"),
  token_api_key: System.get_env("QWEN_TOKEN_KEY"),
  token_plan: false,
  base_url:
    System.get_env("QWEN_BASE_URL") || "https://dashscope-intl.aliyuncs.com/compatible-mode/v1",
  token_plan_base_url:
    System.get_env("QWEN_TOKEN_BASE_URL") ||
      "https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1"

config :genai, :litellm,
  api_key: System.get_env("LITELLM_API_KEY"),
  base_url: System.get_env("LITELLM_BASE_URL") || "http://localhost:4000"

config :genai, :suno,
  api_key: System.get_env("SUNO_API_KEY"),
  base_url: System.get_env("SUNO_BASE_URL") || "https://api.sunoapi.org"
