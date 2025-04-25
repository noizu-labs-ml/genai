defmodule GenAI.Test.Support.Common do
  def random_fact_tool() do
    {:ok, tool} = GenAI.Tool.from_yaml(
      """
      name: random_fact
      description: Get a random fact
      parameters:
        type: object
        properties:
          subject:
            type: string
            description: The subject to generate a random fact for. e.g Cats
        required:
          - category
      """
    )
    tool
  end

end
