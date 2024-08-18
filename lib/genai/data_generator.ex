defmodule GenAI.DataGeneratorBehaviour do
    
    @callback take(count ::integer, generator :: term, context :: term, options :: term) :: {:ok, {response :: any, generator :: any}} | {:error, any}
    
    
    def take(count, %{__struct__: m} = generator, context, options) do
        m.take(count, generator, context, options)
    end
    
end


defmodule GenAI.DataGenerator do
    @moduledoc """
    Data Batch Streamer.
    """
    
    
    defstruct [
        vsn: @vsn
    ]
    
    
    def take(count, generator, context, options)
    def take(count, generator, context, options) do
        {:ok, {Enum.random(1..count), generator}}
    end
    
    
    def new() do
        %__MODULE__{}
    end
    
end