defmodule GenAI.Session.Report do
    defstruct [
      session: nil,
      effective_settings: nil,
      completion: nil,
      thread: nil, # broken into execution steps , e.g. input + output of inference
    ]

end