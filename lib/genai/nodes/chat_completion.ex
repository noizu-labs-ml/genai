
defmodule GenAI.ChatCompletion do
  @vsn 1.0
  defstruct [
    id: nil,
    model: nil,
    provider: nil,
    seed: nil,
    choices: nil,
    usage: nil,
    details: nil,
    vsn: @vsn
  ]

  defmodule Choice do
    defstruct [
      index: nil,
      message: nil,
      finish_reason: nil,
    ]
  end

  defmodule Usage do
    defstruct [
      prompt_tokens: nil,
      total_tokens: nil,
      completion_tokens: nil,
    ]
  end
end