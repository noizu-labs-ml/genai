ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
Mimic.copy(Finch)
Application.ensure_all_started(:gen_ai)
ExUnit.start()
