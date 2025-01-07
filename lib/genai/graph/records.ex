defmodule GenAI.Session.Node.Records do
  alias GenAI.Graph.Types, as: G

  require Record
  Record.defrecord(:process_update, [node: nil, link: nil, container: nil, state: nil, runtime: nil])
  @type process_update :: record(:process_update, [node: any, link: any, container: any, state: any, runtime: any])

  Record.defrecord(:process_next, [link: nil, update: nil])
  @type process_next :: record(:process_next, [link: any, update: process_update])

  Record.defrecord(:process_end, [exit_on: nil, update: nil])
  @type process_end :: record(:process_end, [exit_on: any, update: process_update])

  Record.defrecord(:process_yield, [yield_for: nil, update: nil])
  @type process_yield :: record(:process_yield, [yield_for: any, update: process_update])

  Record.defrecord(:process_error, [error: nil, update: nil])
  @type process_error :: record(:process_error, [error: any, update: process_update])

end