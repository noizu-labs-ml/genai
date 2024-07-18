defmodule GenAI.Tool.Function do
  @vsn 1.0
  defstruct [
    name: nil,
    description: nil,
    parameters: %{},
    vsn: @vsn
  ]

  def from_json(json_string) when is_bitstring(json_string) do
    with {:ok, json} <- Jason.decode(json_string) do
      do_from_json(json)
    end
  end

  def from_yaml(yaml_string) when is_bitstring(yaml_string) do
    with {:ok, json} <- YamlElixir.read_from_string(yaml_string) do
      do_from_json(json)
    end
  end

  defp do_from_json(%{"type" => "function", "function" => json}) do
    do_from_json(json)
  end
  defp do_from_json(%{"name" => _} = json) do
    # parameters is json a standard object json schema entry so use it to build a map of parameters one implemented.
      parameters = with {:ok, x} <- json["parameters"] && GenAI.Tool.Schema.Type.from_json(json["parameters"]) do
        x
      end
    {:ok,
      %GenAI.Tool.Function{
        name: json["name"],
        description: json["description"],
        parameters: parameters
      }
    }
  end
end



defmodule GenAI.Tool.Schema.Type do
  def from_json(json) do
    cond do
      GenAI.Tool.Schema.Object.is_type(json) ->
        GenAI.Tool.Schema.Object.from_json(json)
      GenAI.Tool.Schema.Enum.is_type(json) ->
        GenAI.Tool.Schema.Enum.from_json(json)
      GenAI.Tool.Schema.String.is_type(json) ->
        GenAI.Tool.Schema.String.from_json(json)
      GenAI.Tool.Schema.Number.is_type(json) ->
        GenAI.Tool.Schema.Number.from_json(json)
      GenAI.Tool.Schema.Integer.is_type(json) ->
        GenAI.Tool.Schema.Integer.from_json(json)
      GenAI.Tool.Schema.Null.is_type(json) ->
        GenAI.Tool.Schema.Null.from_json(json)
      GenAI.Tool.Schema.Bool.is_type(json) ->
        GenAI.Tool.Schema.Bool.from_json(json)
      :else -> {:error, :pending}
    end
  end
end

defmodule GenAI.Tool.Schema.TypeBehaviour do
  @callback is_type(map()) :: boolean
  @callback from_json(map()) :: {:ok, term} | {:error, term}
end

defmodule GenAI.Tool.Schema.Bool do
  @moduledoc """
  Represents a schema for boolean types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct [
    description: nil
  ]

  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "boolean"}), do: true
  def is_type(_), do: false

  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "boolean"} = json) do
    {:ok, %__MODULE__{description: json["description"]}}
  end
  def from_json(_), do: {:error, :unrecognized_type}
end

defmodule GenAI.Tool.Schema.Number do
  @moduledoc """
  Represents a schema for number types, including integers and floating-point numbers.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct [
    type: "number",
    description: nil,
    minimum: nil,
    maximum: nil,
    multiple_of: nil,
    exclusive_minimum: nil,
    exclusive_maximum: nil
  ]

  @type t :: %__MODULE__{
               type: String.t(),
               description: String.t() | nil,
               minimum: float() | nil,
               maximum: float() | nil,
               multiple_of: float() | nil,
               exclusive_minimum: boolean() | nil,
               exclusive_maximum: boolean() | nil
             }

  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "number"}), do: true
  def is_type(_), do: false

  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "number"} = json) do
    {:ok,
      %__MODULE__{
        description: json["description"],
        minimum: json["minimum"],
        maximum: json["maximum"],
        multiple_of: json["multipleOf"],
        exclusive_minimum: json["exclusiveMinimum"],
        exclusive_maximum: json["exclusiveMaximum"]
      }}
  end
  def from_json(_), do: {:error, :unrecognized_type}
end

defmodule GenAI.Tool.Schema.Integer do
  @moduledoc """
  Represents a schema for integer types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct [
    type: "integer",
    description: nil,
    minimum: nil,
    maximum: nil,
    multiple_of: nil,
    exclusive_minimum: nil,
    exclusive_maximum: nil
  ]

  @type t :: %__MODULE__{
               type: String.t(),
               description: String.t() | nil,
               minimum: integer() | nil,
               maximum: integer() | nil,
               multiple_of: integer() | nil,
               exclusive_minimum: boolean() | nil,
               exclusive_maximum: boolean() | nil
             }

  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "integer"}), do: true
  def is_type(_), do: false

  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "integer"} = json) do
    {:ok,
      %__MODULE__{
        type: "integer",
        description: json["description"],
        minimum: json["minimum"],
        maximum: json["maximum"],
        multiple_of: json["multipleOf"],
        exclusive_minimum: json["exclusiveMinimum"],
        exclusive_maximum: json["exclusiveMaximum"]
      }}
  end
  def from_json(_), do: {:error, :unrecognized_type}
end

defmodule GenAI.Tool.Schema.Null do
  @moduledoc """
  Represents a schema for null types.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct [
    type: "null",
    description: nil
  ]

  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "null"}), do: true
  def is_type(_), do: false

  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "null"} = json) do
    {:ok, %__MODULE__{
      type: "null",
      description: json["description"]}
    }
  end
  def from_json(_), do: {:error, :unrecognized_type}
end




defmodule GenAI.Tool.Schema.Enum do
  @moduledoc """
  Represents a schema for enum types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct [
    type: "string",
    description: nil,
    enum: nil
  ]

  @type t :: %__MODULE__{
               type: String.t(),
               description: String.t() | nil,
               enum: [String.t()]
             }

  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "string", "enum" => _}), do: true
  def is_type(_), do: false

  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(%{"type" => "string", "enum" => _} = json) do
    %__MODULE__{
      type: "string",
      description: json["description"],
      enum: json["enum"]
    }
  end
  def from_json(_), do: {:error, :pending}
end

defmodule GenAI.Tool.Schema.String do
  @moduledoc """
  Represents a schema for string types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct [
    type: "string",
    description: nil,
    min_length: nil,
    max_length: nil,
    pattern: nil,
    format: nil,
  ]

  @type t :: %__MODULE__{
               type: String.t(),
               description: String.t() | nil,
               min_length: integer() | nil,
               max_length: integer() | nil,
               pattern: String.t() | nil,
               format: String.t() | nil,
             }

  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "string"}), do: true
  def is_type(_), do: false

  @doc """
  Converts a JSON map to a `GenAI.Tool.Schema.String` struct, handling naming conventions.
  """
  @spec from_json(map()) :: t()
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(attributes = %{"type" => "string"}) do
    a = attributes
        |> Enum.map(
             fn
               {"maxLength", value} -> {:max_length, value}
               {"minLength", value} -> {:min_length, value}
               {"pattern", value} -> {:pattern, value}
               {"description", value} -> {:description, value}
               {"format", value} -> {:format, value}
               {"type", value} -> {:type, value}
             end)
        |> Enum.reject(&is_nil(&1))
    {:ok, struct(__MODULE__, a)}
  end
  def from_json(_), do: {:error, :pending}
end

defmodule GenAI.Tool.Schema.Object do
  @moduledoc """
  Represents a schema for object types, converting JSON schema attributes to Elixir struct fields.
  """
  @behaviour GenAI.Tool.Schema.TypeBehaviour

  defstruct [
    type: "object",
    description: nil,
    properties: nil,
    min_properties: nil,
    max_properties: nil,
    property_names: nil,
    pattern_properties: nil,
    required: nil,
    additional_properties: nil,
  ]

  @type t :: %__MODULE__{
               type: String.t(),
               description: String.t() | nil,
               properties: map() | nil,
               min_properties: integer() | nil,
               max_properties: integer() | nil,
               property_names: map() | nil,
               pattern_properties: map() | nil,
               required: [String.t()] | nil,
               additional_properties: boolean() | map() | nil,
             }

  @impl GenAI.Tool.Schema.TypeBehaviour
  def is_type(%{"type" => "object"}), do: true
  def is_type(_), do: false

  @doc """
  Converts a JSON map to a `GenAI.Tool.Schema.String` struct, handling naming conventions.
  """
  @spec from_json(map()) :: t()
  @impl GenAI.Tool.Schema.TypeBehaviour
  def from_json(attributes = %{"type" => "object"}) do
    a = attributes
        |> Enum.map(
             fn
               {"type", value} -> {:type, value}
               {"properties", nil} -> nil
               {"properties", value} ->
                 x = Enum.map(value,
                       fn {k,v} ->
                         with {:ok, x} <- GenAI.Tool.Schema.Type.from_json(v) do
                           {k, x}
                         else
                           error -> {k, error}
                         end
                       end)
                     |> Map.new()
                 {:properties, x}
               {"minProperties", value} -> {:min_properties, value}
               {"maxProperties", value} -> {:max_properties, value}
               {"propertyNames", value} -> {:property_names, value}
               {"patternProperties", nil} -> nil
               {"patternProperties", value} ->
                 x = Enum.map(value,
                       fn {k,v} ->
                         with {:ok, x} <- GenAI.Tool.Schema.Type.from_json(v) do
                           {k, x}
                         else
                           error -> {k, error}
                         end
                       end)
                     |> Map.new()
                 {:pattern_properties, x}
               {"required", nil} -> nil
               {"required", []} -> nil
               {"required", value} -> {:required, value}
               {"additionalProperties", nil} -> nil
               {"additionalProperties", true} -> {:additional_properties, true}
               {"additionalProperties", false} -> {:additional_properties, false}
               {"additionalProperties", value} ->
                 x = with {:ok, x} <- GenAI.Tool.Schema.Type.from_json(value) do
                   x
                 end
                 {:additional_properties, x}
               {"description", value} -> {:description, value}
             end
           )
        |> Enum.reject(&is_nil(&1))
    {:ok, struct(__MODULE__, a)}
  end
  def from_json(_), do: {:error, :pending}
end


defimpl Jason.Encoder, for: [
                         GenAI.Tool.Function,
                         GenAI.Tool.Schema.Bool,
                         GenAI.Tool.Schema.Enum,
                         GenAI.Tool.Schema.Integer,
                         GenAI.Tool.Schema.Null,
                         GenAI.Tool.Schema.Number,
                         GenAI.Tool.Schema.Object,
                         GenAI.Tool.Schema.String,
] do
  def encode(s, opts) do
    s
    |> Map.from_struct()
    |> Enum.reject(fn {k, v} -> k == :vsn or is_nil(v) end)
    |> Map.new()
    |> Jason.Encode.map(opts)
  end


end
