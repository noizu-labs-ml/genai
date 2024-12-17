Todo
=====

- [ ] Overhaul how state is tracked.

Walk across flow graph generating message nodes as we go rather than walking across entire graph before running inference.

Track metadata if requested. If we reach a node that needs to run inference before proceeding verify we have model settings set already.

On inference output nodes (messages) append meta data - effective model, settings, etc. at time of generation. 

On loop nodes and tagged nodes store state values (sans message thread) - i.e. effective values. 

We need to segment out state from message thread. Once reaching final node run inference with effective thread at that point. 

Internally output loop nodes need to track all paths through (if in report mode execute) plus the final effective messages added to thread. 


<style>
.mermaid  {
  display: flex;
  justify-content: center;
}

.mermaid svg {
  border: 2px solid darkgray;
  background: #FFFFBB50; 
  padding: 25px;
  box-shadow: #888888 0px 2px 5px;
}
</style>

```mermaid
---
config:
    theme: forest
    layout: elk
    elk: 
      mergeEdges: true
      nodePlacementStrategy: LINEAR_SEGMENTS
    flowchart:
      diagramPadding: 25
      nodeSpacing: 25
      rankSpacing: 35
      titleTopMargin: 100
      htmlLAbels: true
title: "Flow with Loop"

---
flowchart TD 
  classDef noteNode fill:#F6F6F6,stroke:#CCC,stroke-width:1px;
  Start[System] --> N1[User]
  N1 --> N2[Assistant] --> N5[Loop]
  N5 --> L1["EnterLoop"] --> L2["DataSet"] --> L3["Inner Nodes"] --> L4[/"LoopEnd"/]
  L4 --> L5{"Break?"}
  L5 -- "break" --> S["EFFECTIVE MESSAGE UPDATE"] --> N6[User] --> N7[End]
  L5 -- "continue" --> L1
  
  
  S -. "note" .-> NOTE1[["`
Only final selected loop messages
are added to output. What these are
depends on the loop type.
A appending loop or iterator loop.
`"]]:::noteNode
```


---------------------

# Model Details
- [ ] Overhaul how model details are loaded to incorporate a model database to fill in model internal details.
  - [ ] Context Limits
  - [ ] Function Call Support
  - [ ] Image Support
  - [ ] Audio Support
  - [ ] Video Support

# Providers
- [ ] Add support for HuggingFace
- [ ] Add support for OpenVllm
- [ ] Update API Call logic for Anthropic to use updated api format.
- [ ] Vision Support for Groq models that support it.
- [ ] Tool use via api for Groq models that support it.

# Local Llama
- [ ] Move LocalLama to extension/add-on module
