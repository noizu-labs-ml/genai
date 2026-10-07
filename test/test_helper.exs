ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
Mimic.copy(Finch)
Application.ensure_all_started(:gen_ai)
# :live tests hit real provider APIs; run them with GENAI_LIVE_TESTS=1
live_excludes = if System.get_env("GENAI_LIVE_TESTS") in ["1", "true"], do: [], else: [:live]
ExUnit.start(exclude: live_excludes)
