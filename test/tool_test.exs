defmodule GenAI.ToolTest do

  use ExUnit.Case
  @moduletag feature: :tools

  describe "Tool Parsing" do
    test "tool from yaml - long" do
      {:ok, sut} = GenAI.Tool.from_yaml(
        """
        type: function
        function:
          name: get_current_weather
          description: Get the current weather in a given location
          parameters:
            type: object
            properties:
              location:
                type: string
                description: The city and state, e.g. San Francisco, CA
              unit:
                type: string
                enum:
                  - celsius
                  - fahrenheit
            required:
              - location
        """
      )
      assert sut.name == "get_current_weather"
      assert sut.description == "Get the current weather in a given location"
      assert sut.parameters.required == ["location"]
      assert sut.parameters.properties["location"].__struct__ == GenAI.Tool.Schema.String
      assert sut.parameters.properties["location"].description == "The city and state, e.g. San Francisco, CA"
      assert sut.parameters.properties["unit"].__struct__ == GenAI.Tool.Schema.Enum
      assert sut.parameters.properties["unit"].enum == ["celsius", "fahrenheit"]

    end

    test "tool from json - long" do
      {:ok, sut} = GenAI.Tool.from_json(
        """
        {
            "type": "function",
            "function": {
              "name": "get_current_weather",
              "description": "Get the current weather in a given location",
              "parameters": {
                "type": "object",
                "properties": {
                  "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                  },
                  "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"]
                  }
                },
                "required": ["location"]
              }
            }
          }
        """
      )
      assert sut.name == "get_current_weather"
      assert sut.description == "Get the current weather in a given location"
      assert sut.parameters.required == ["location"]
      assert sut.parameters.properties["location"].__struct__ == GenAI.Tool.Schema.String
      assert sut.parameters.properties["location"].description == "The city and state, e.g. San Francisco, CA"
      assert sut.parameters.properties["unit"].__struct__ == GenAI.Tool.Schema.Enum
      assert sut.parameters.properties["unit"].enum == ["celsius", "fahrenheit"]
    end

    test "Jason.encode" do
      {:ok, sut} = GenAI.Tool.from_json(
        """
        {
            "type": "function",
            "function": {
              "name": "get_current_weather",
              "description": "Get the current weather in a given location",
              "parameters": {
                "type": "object",
                "properties": {
                  "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                  },
                  "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"]
                  }
                },
                "required": ["location"]
              }
            }
          }
        """
      )
      {:ok, json} = Jason.encode(sut)
      assert json == "{\"name\":\"get_current_weather\",\"description\":\"Get the current weather in a given location\",\"parameters\":{\"type\":\"object\",\"required\":[\"location\"],\"properties\":{\"location\":{\"type\":\"string\",\"description\":\"The city and state, e.g. San Francisco, CA\"},\"unit\":{\"type\":\"string\",\"enum\":[\"celsius\",\"fahrenheit\"]}}}}"
    end

  end

end
