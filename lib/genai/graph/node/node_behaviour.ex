#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================
defmodule GenAI.Graph.NodeBehaviour do
    @moduledoc """
    Behaviour Graph Node Elements must adhere to.
    """
    alias GenAI.Types, as: T
    alias GenAI.Graph.Types, as: G

    #==================================
    # Support Macros
    #==================================
    defmacro defnodetype(types) do
        types = Macro.expand_once(types, __CALLER__)
        members = quote do
            [
                {:id, T.node_id},
                {:handle, T.node_handle},
                {:name, T.name},
                {:description, T.description},
                unquote_splicing(types),
                {:inbound_links, T.link_map},
                {:outbound_links, T.link_map},
                {:meta, nil | map() | keyword()},
                {:vsn, float}
            ]
        end
        
        quote do
            @type t :: %__MODULE__{
                         unquote_splicing(members)
                       }
        end
    end
    
    defmacro defnodestruct(values) do
        quote do
            @vsn Module.get_attribute(__MODULE__, :vsn, 1.0)
            Kernel.defstruct [
                                 id: nil,
                                 handle: nil,
                                 name: nil,
                                 description: nil,
                             ] ++
                             (unquote(values) || []) ++
                             [
                                 outbound_links: %{}, # edge ids grouped by outlet
                                 inbound_links: %{}, # edge ids grouped by outlet
                                 vsn: @vsn,
                                 meta: nil,
                             ]
        end # end of quote
    end
    
    #==================================
    # Using Macro
    #==================================
    defmacro __using__(opts \\ nil) do
        quote do
            @provider (unquote(opts[:provider]) || GenAI.Graph.NodeProtocol.DefaultProvider)
            require GenAI.Graph.NodeBehaviour
            import GenAI.Graph.NodeBehaviour, only: [defnodestruct: 1, defnodetype: 1]
            import GenAI.Graph.NodeProtocol.DefaultProvider
            
            
            defdelegate id(graph), to: @provider, as: :do_id
            defdelegate handle(graph), to: @provider, as: :do_handle
            defdelegate handle(graph, default), to: @provider, as: :do_handle
            defdelegate name(graph), to: @provider, as: :do_name
            defdelegate name(graph, default), to: @provider, as: :do_name
            defdelegate description(graph), to: @provider, as: :do_description
            defdelegate description(graph, default), to: @provider, as: :do_description
            
        end
    end


end