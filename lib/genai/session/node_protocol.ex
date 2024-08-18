#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================
defprotocol GenAI.Session.NodeProtocol do
    @doc """
    Process node and proceed to next step.
    
  """
    #TODO add specs
    
    @doc """
    Return the type of node. Used for validating input requsts and orchestrating state manipulation by providers.
    """
    def node_type(graph_node)
    
    @doc """
    Apply node, update state if expired, run inference/logic for special nodes, etc. if cached value expired. Apply directives, etc.
    """
    def process_node(graph_node, scope, context, options)
#
#    @doc """
#    Gather input values to be consumed inside of process_node method.
#    """
#    def update_state_input(graph_node, scope, context, options)
#
#
#    @doc """
#    Update state for node and link.
#    Use directives if artifacts have been modified.
#    This will raise if fingerprint unchanged for data security.
#    """
#    def update_state(graph_node, scope, context, options)
#
#
#    @doc """
#    Return directive(s) for setting tools/messages/settings/artifacts for node.
#    Only executed by default handler if fingerprint change indicates values will result in new values.
#    Directives with unchanged fingerprint will not be updated.
#    """
#    def directives(graph_node, input, finger_print_key, scope, context, options)
#
#    @doc """
#    Prepare finger_print_key digest message as a (map) used to generate your finger_print digest. For static nodes with no input we simply reference node id.
#
#    If a node is dependent on a data generator and contents of a dynamic system prompt the digest map, and ttl value then you
#    should include the data generator value finger_print, the system_prompt message finger_print (which in indicates if it has changed.)
#    and ttl element.
#    e.g
#    ```elixir
#    %{
#      id: self.id,
#      data_record: data_record.finder_print,
#      system_prompt: message_by_handle!(:dynamic_system_prompt).finger_print,
#      ttl: div(System.time(:second), 3600)
#    }
#    ```
#
#    You will generally want to override this method for dynamic nodes,
#    for convenience you can generally just specify pass options to derive to control values used.
#    and input values will be automatically injected into the fingerprint map unless wrapped in request with ignore_finger_print modifier.
#    manually setting input values with out this specifier (even if initially set on request) will result in the ignore flag being cleared.
#
#    ```elixir
#        @derive GenAI.Session.NodeProtocol [
#            provider: GenAI.Session.NodeProtocol.DefaultProvider,
#            # Inject values from state into input arguments with out need to manually fetch.
#            # Values are passed to directives by default process_node method.
#            input: %{
#                data_set_foo: data_set(name: :foo, count: 5), # grab from generator
#                data_set_bar: data_set(name: :bar, count: 3), # grab from generator
#                memories: memory_injector(),
#                user_local: no_finger_print(stack(:user_local)), # request an input but don't automatically add to fingerprint list.
#            },
#            finger_print: %{
#                data_set_foo: input(:data_set_foo), # this would be auto injected as it's in input list.
#                data_set_bar: input(:data_set_bar), # a passed in input map value (values from input field plut modifiers are made available here.
#                system_prompt: message_by_handle(:dynamic_system_prompt),
#                memories: input(:memories),
#                temperature: setting(:temperature), # used if for example in a grid loop.
#                ttl: ttl(3600),
#                user_name: stack(:user_name),
#                dynamic: dynamic_key(), # always generate new fingerprint regardless of any other changes.
#            }
#        ]
#    ```
#    """
#    def finger_print_key(graph_node, input, default_key, scope, context, options)
#
#
#
#    @doc """
#    Calculate Cache Finger print for node. Used to determine if node has changed and needs to be reprocessed.
#    The default implementation should be fine for most cases but you can override if needed.
#    """
#    def finger_print(graph_node, finger_print_key, scope, context, options)
#
#    #==================================
#    # Meta Data Feed
#    #==================================
#    def graph_node_protocol_options(graph_node, context, options)
#    def __derive_graph_node_protocol_options__(graph_node)
#
end

defimpl GenAI.Session.NodeProtocol, for: Any do
    defmacro __deriving__(module, _struct, options) do
        options = Macro.escape(options)
        quote do
            defimpl GenAI.Session.NodeProtocol, for: unquote(module) do
                
                @provider unquote(options[:provider]) || GenAI.Session.NodeProtocol.DefaultProvider
                @input_directives unquote(options)[:input] || %{}
                @finger_print unquote(options)[:finger_print] || %{}
                @graph_node_protocol_options %{
                    provider: @provider,
                    input: @input_directives,
                    finger_print: @finger_print
                }
                
                defdelegate node_type(graph_node), to: @provider
                defdelegate process_node(graph_node, scope, context, options), to: @provider
#                defdelegate update_state(graph_node, scope, context, options), to: @provider
#                defdelegate graph_node_protocol_options(graph_node, context, options), to: @provider
#                def __derive_graph_node_protocol_options__(graph_node) do
#                    @graph_node_protocol_options
#                end
#                defdelegate update_state_input(graph_node, scope, context, options), to: @provider
#                defdelegate finger_print(graph_node, finger_print_key, scope, context, options), to: @provider
#                defdelegate finger_print_key(graph_node, input, default_key, scope, context, options), to: @provider
#                defdelegate directives(graph_node, input, finger_print_key, scope, context, options), to: @provider
#
            end
        end
    end
end


