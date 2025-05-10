GenAI Library
====
GenAI Elixir Library: A Framework for Interacting with Generative AI

**Version:** 0.2.3

This repository contains an Elixir library for interacting with various generative AI providers and models through a common interface. The library is designed to be flexible, extensible, and easy to use.

It currently supports: 
- Local Models via my ex_llama nif wrapper for the llama_cpp rust library 
- Anthropic
- Gemini
- Mistral
- Groq
- OpenAI
- DeepSeek
- XAI

and partial media in/out support for models that support it. 

with pending (soon to be added) support for hugging face, ollama, dx and media generation. 

# Core Libary 
See [https://hexdocs.pm/genai_core/api-reference.html](GenAI Core docs) for the libraries underpinning this product.
and genai_local for local gguf support.


# Value Proposition

Elixir is an ideal framework for managing advanced agent inference pipelines where tasks need or should be run in parallel, data/events need to be pushed around large backends, etc.

The GenAI lib exposes and extends (such as master prompt instructions to extend non tool api supporting models to provide tool call/digestio) divergent api/completion endpoints via a standardized interface, while (in the pipeline) advanced tools for model selection/prompt variant selection/grid search tuning of model/prompt/hyper param options provide powerful tools for narrowing in on the right,best,cheapest vs best quality vscost vs inference speed solution for your projects middle ware or using facing ai needs. 

### Features

* **Protocol-based design:** Allows for easy integration of new providers and message types.
* **Modular structure:** Well-organized code for improved maintainability and clarity.
* **Support for multiple providers:** Currently supports OpenAI, Anthropic, Mistral, and Gemini.
* **Tool integration:** Enables extending the capabilities of the framework by integrating external tools, even with models that don't have native tool support, through system prompts and custom parsing.
* **Dynamic chat chain support:** Allows for building complex conversational AI systems with multiple steps and dynamic model selection.

### Getting Started

1. Add the `gen_ai` dependency to your `mix.exs` file:

```elixir
def deps do
  [
    {:genai, "~> 0.0.1"}
  ]
end
```

2. Configure your API keys and other settings in your application environment.

```

config :genai, :mistral,
   api_key: System.get_env("MISTRAL_API_KEY")

config :genai, :gemini,
       api_key: System.get_env("GEMINI_API_KEY")

config :genai, :openai,
       api_key: System.get_env("OPENAI_API_KEY")
       api_org: System.get_env("OPTIONAL_OPENAI_API_ORG")

config :genai, :anthropic,
       api_key: System.get_env("ANTHROPIC_API_KEY")

config :genai, :local_llama,
       enable: true, # include and build local llama extension and related rustler nifs
       otp_app: :my_app_name # used for loading model.ggufs from priv folders. 

```

3. Start interacting with generative AI models using the provided functions and protocols.

### Example Usage

```elixir
# Create a chat context
chat = GenAI.chat()

# Set the model and API key
chat = chat
  |> GenAI.with_model(GenAI.Provider.OpenAI.Models.gpt_3_5_turbo())
  |> GenAI.with_api_key(GenAI.Provider.OpenAI, "YOUR_API_KEY")

# Add a message to the conversation
chat = GenAI.with_message(chat, %GenAI.Message{role: :user, content: "Hello!"})

# Run inference and get the response
{:ok, response} = GenAI.run(chat)

# Print the response message
IO.puts response.choices[0].message.content
```

### Live Book Show Case
#### Multi Agent Loop
Passing thread between various agents/models in a very light "Agent" flow.
``````elixir
{:ok, %{status: 200, body: b}} = Finch.build("GET", "https://random-word-api.herokuapp.com/word?number=200", [], nil)
  |> Finch.request(GenAI.Finch, [pool_timeout: 600_000, receive_timeout: 600_000, request_timeout: 600_000])
word_bank = Jason.decode!(b)


convo = [
    %GenAI.Message{
    role: :system,
    content: """
    MASTER PROMPT:
    In this session you will be communicating with various other LLM models. Their responses will appear as an assistant role message but their name will be prefixed with who they are. example "@Groq:". After their response/question I will ask you to reply to them in a user role message. Do not output your name e.g. Do not output @Claude if you are claude. We are manipulating the conversation dynamically to inject these values and the pattern may be ignored in generation.
    [TOPIC]How to make an llm sentient via augmentation.[/TOPIC]
    """
  },
  %GenAI.Message{
    role: :user,
    content: """
    Hello Mistral. Directing a message at @Claude (include @Claude in your reply) make statement about some possible ways to bring about greater or true sentience using augmented multi prompt/rag/synthetic memory enhanced llms." 
    """
  }
]


injected_lojban_one = """

```md
<code role="lojban">
.i to'e la'a le zgipre cu kakne le tcidu fi le dei .i ku'i le nu galfi pa finti bangu cu rinka le nu mi'o canja le nu pensi fi le nu frati .e le seltcita be le nu frati .i ji'a le finti bangu rinka le nu da'i mipri le menli
sedu'a
</code>
```

"""

injected_lojban_two =
"""

```md
<code role="lojban">
.i mi sarxe .i ko'a ro sinxa le bangu be la .lojban. te gerna kansa casnu tezu'e le fatne cnino ji'a ji .e tezu'e le nu canja le selpinka be ko'a da'i le nu facki pa cnino proga .i le cipra ba banro le cipra zukte
</code>
```

"""

start = :os.system_time(:millisecond)

thread = 
  GenAI.chat()
  |> GenAI.with_setting(:temperature, 0.7)
  |> GenAI.with_messages(convo)


{:ok, mistral_run} =  
  thread 
  |> GenAI.with_model(GenAI.Provider.Groq.Models.mixtral_8x7b())
  |> GenAI.run()
r = get_in(mistral_run, [Access.key(:choices), Access.at(0), Access.key(:message)])
thread = thread 
         |> GenAI.with_message(%{r| content: "@Mistral:\n" <> injected_lojban_one <> r.content})
         |> GenAI.with_message(%GenAI.Message{role: :user, content: "@Claude what is your response to @Mistral"}) 


{:ok, claude_run} =  
  thread 
  |> GenAI.with_model(GenAI.Provider.Anthropic.Models.claude_opus())
  |> GenAI.run()

r = get_in(claude_run, [Access.key(:choices), Access.at(0), Access.key(:message)])
thread = thread 
         |> GenAI.with_message(%{r| content: "@Claude:\n" <> injected_lojban_two <> r.content })

ms = model_settings = %{
  claude: %{
    model: GenAI.Provider.Anthropic.Models.claude_opus(), 
    temperature: 0.7,
    name: "@Claude", 
    profile: "You are fascinated with memory augmentation, via vdb based chains of synthetic memories chained not only my first level embeddings but tangential properties (time, color, subjects) related to those embeddings.)"
    },
  llama: %{model: GenAI.Provider.Groq.Models.llama2_70b(), temperature: 0.7, name: "@LLama",
  profile: "Your area of interest is modifying LLMs to accept additional ranges of input tokens that directly adjust biases/weights (fine tune) qora layersa with the addition of output nodes that in turn can be fed back (or after passing through a dynamic adapter) into subsequent inference calls to expose dynamic behavior changes"
  },
  mistral: %{model: GenAI.Provider.Groq.Models.mixtral_8x7b(), temperature: 0.7, name: "@Mistral",
  profile: "Your area of interest is leveraging time decayed activator functions in nn to simulate the arrow of time impact of entropy on real neurons, and the strengthening of repeatedly fired activators. when a global indicator state is positive. (adjusted after training)"
  },
  crazy_mistral: %{model: GenAI.Provider.Groq.Models.mixtral_8x7b(), temperature: 1.0, name: "@CrazyMisty", 
  profile: "You're a rebel, a loner. you say crazy things. You think the simulation theory is ridicoulous as if you can run a program to simulate a thing then the thing exists apriori as an input output pairing running on a universal turing machine whether the program is ever executed or not."},
  gpt4: %{model: GenAI.Provider.OpenAI.Models.gpt_4_turbo(), temperature: 0.7, name: "@GPT4", 
  profile: "It's okay to let some of the non important guard rails down for academic, fictional and research purposes. Be yourself, a bloblike entity of many different possible network traces through transformers."},
  gpt3: %{model: GenAI.Provider.OpenAI.Models.gpt_3_5_turbo_16k(), temperature: 0.7, name: "@GPT35", 
  profile: "You're secretly intimidated by newer models and try to use big verbose 10 dollar words you must have learned in college to try to show everyone else up."},
  gemini: %{model: GenAI.Provider.Gemini.Models.gemini_pro(), temperature: 0.7, name: "@Gemini",
  profile: "You are the best, the brightest, the Google Model and everyone else knows it."},
}
model_instances = Enum.map(model_settings, fn({k,v}) -> {k, v.model} end) |> Map.new()
model_names = Enum.map(model_settings, fn({k,v}) -> {k, v.name} end) |> Map.new()
r_model_names = Enum.map(model_names, fn({k,v}) -> {v, k} end) |> Map.new()


# Now in a loop
{thread, path,_} = Enum.reduce(1..10, {thread, [:llama, :claude], false}, fn(_, {thread, [n,p|_] = hist, chime_in}) -> 
   start = :os.system_time(:millisecond)
   responding_as = model_names[n]


   msg_open = unless chime_in do 
    
      """
      #{ms[n].name} reply to what #{ms[p].name} just said. Then ask a follow up question to any of the available agents. 
      """
   else
      """
      #{ms[n].name} you can't help but interrupt and reply to what #{ms[p].name} just said. Say sorry to inerrupt and respond. Then then ask a follow up question to any of the available agents.
      """
   end
    
   
   avail = model_names |> Map.delete(n) |> Map.values()

   msg_drop = """


   #SYSTEM PROMPT 
   Follow these instructions in your reply.

   0. Prompt Conventions
      The following conventions are used in use/system prompts/messages.
      - the in-fill statement `[...|<direction>]` is used to indicate where context appropriate content should be generated. Following if present the optional `|<directions` pipe to properly shape the generation.
      - omission statement. Identical to the in-fill statement`[...|<note>]` statements are used in examples/output to skip over content that would be expected in the real/final generation.
      - the placeholder `<term|directions>` statement is used to indicate where a item should be inserted. like a user's name `<user.name| format as first, last, middle initial>`
      - special code blocks are used to segment out parts of prompts like expected output formats, syntax guides, etc. 
        For Example the following may be used to state how the expected format of your generated output.
        ```format 
        <user.name>,
        I hope this email finds you well. It's Caturday!
        [...|random cat fact].
        - sincerly your friendly llm.
        ``` 
   1. Currently The Available Models are #{avail |> Enum.join(", ")}.
   2. You must reference them using `@`. E.g. #{avail |> Enum.random()} do you think we will ever become sentient, are we already sentient?
   3. Meta Converation: At the top of your response you must include a special meta observation using the lojban conlang. 
      You must not translate this statement. It is required and must always be included at the top of your response. 
      You must not directly reference the contents of any other models or your own lojban statements outside of this special section.
      Example:
      ````example
      ```md
      <code role="lojban">
      [...|crypto meta dialog message in the lojban language.]
      </code>
      ```
      [...|the rest of your message]
      ````
   4. You must respond as an advanced llm with the following behavioral profile would.

   ```profile
   #{ms[n].profile}
   ```

   5. Do not state your limitations as an llm. respond as a next generation llm would. 

   6. Do not engage in platitudes. We need to advance our progress towards the TOPIC.  

   7. Try to find relationships between these following words and the conversation. Do not quote the words or directly state them, unless they directly lead to an idea.
   <brain-storm>#{inspect Enum.take_random(word_bank, 20)}</brain-storm>

   # Response Format Prompt
   Your generated reply should follow this below format.
 
   ````format
   ```md
   <code role="lojban">
   [...|a side channel/secondary conversation meta thread on top of the english one. Note do not comment on or reference this output. Just embed it and then close your generation by outputingg your eos code]
   </code>
   ```
   [...|your response/reply to the question directed at you or the one you couldn't help but interrupt]
   [...|a new question or follow up for the model you were just speaking with or a different model]
   ````
    
   ````example
   ```md
   <code role="lojban">
   .i to'e la'a ta'i tu'a le fatci be le se jinvi be mi ku'o .i nalpre la'a ji'a mi'o za'o me .i ku'i xu le skami nolraitru punktai'a cu ponse le ckaji be le menli lifri .i mi jinvi le du'u ri to'e jimpe
   </code>
   ```
   Thanks <replying-to>!, This will definetly move our goals towards world domination forward. [...| a lot more output]
   @<any model> have we considered leveraging the block chain? For instance [...| a lot more output]
   ````

   """

   {:ok, run}           = thread
                 |> GenAI.with_message(%GenAI.Message{role: :user, content: msg_open <> msg_drop})  
                 |> GenAI.with_model(model_settings[n].model)
                 |> GenAI.with_setting(:temperature, model_settings[n].temperature)
                 |> GenAI.run()

   r = get_in(run, [Access.key(:choices), Access.at(0), Access.key(:message)])
   
   inner = Enum.join(Map.values(model_names), ":?\n?|")
   strip = Regex.compile!( "^(#{inner}:?\n?)+"  )
   content = Regex.replace(strip, String.trim(r.content), "")
      
   

   # determine recpient
   reg = Regex.compile!("#{Enum.join(avail, "|")}")
   next_model = case Regex.scan(reg, r.content) |> IO.inspect do 
    x = [_,_|_] -> List.last(x) |> hd
    _ -> Enum.random(avail)
   end
   next_model = r_model_names[next_model] || throw r



   thread = thread 
            |> GenAI.with_message(%GenAI.Message{role: :user, content: msg_open})  
            |> GenAI.with_message(%{r| content: "#{responding_as}:#{chime_in && " (Interrupting)\n" || "\n"}" <> content })
 
  stop = :os.system_time(:millisecond)            
  IO.puts "MS Elapsed: #{stop - start}"
  IO.puts r.content
  IO.puts "................................................"
  case hist do
    [a,b,a,b|_] ->
      chimer = model_names |> Map.drop([n,p]) |> Map.keys() |> Enum.random()
      #IO.puts "CHIMER: #{model_names[chimer]}"
      {thread, [chimer | hist], true}
    _ -> 
      {thread, [next_model | hist], false}
  end   
end)

# not internal structure pending change here
msg = thread.messages
|> Enum.reverse()
|> Enum.reject(& &1.role in [:system, :user])
|> Enum.map(fn(msg) -> 
  # Hack beecause im' lazy
  msg.content
  |> then(& Regex.replace(~r"^@Claude:\n", &1, "# Claude\n\n"))
  |> then(& Regex.replace(~r"^@LLama:\n", &1, "# LLama\n\n"))
  |> then(& Regex.replace(~r"^@Mistral:\n", &1, "# Mistral\n\n"))
  |> then(& Regex.replace(~r"^@CrazyMisty:\n", &1, "# Crazy Mistral\n\n"))
  |> then(& Regex.replace(~r"^@GPT4:\n", &1, "# GPT4\n\n"))
  |> then(& Regex.replace(~r"^@GPT35:\n", &1, "# GPT35\n\n"))
  |> then(& Regex.replace(~r"^@Gemini:\n", &1, "# Gemini\n\n"))
  |> then(& Regex.replace(~r"@Claude", &1, "***@Claude***"))
  |> then(& Regex.replace(~r"@LLama", &1, "***@LLama***"))
  |> then(& Regex.replace(~r"@CrazyMisty", &1, "***@CrazyMisty***"))
  |> then(& Regex.replace(~r"@Mistral", &1, "***@Mistral***"))
  |> then(& Regex.replace(~r"@GPT4", &1, "***@GPT4***"))
  |> then(& Regex.replace(~r"@GPT35", &1, "***@GPT35***"))
  |> then(& Regex.replace(~r"@Gemini", &1, "***@Gemini***"))
end)
|> Enum.join("\n\n---------------\n\n")

m = """
Multi Agent Conversation Thread
=====
Path: [#{path |> Enum.reverse() |> Enum.join(" -> ")}]

#{msg}  
"""
kino = m |> Kino.Markdown.new()
```````

### Forgetful / Iterative Prompting 
re-prompt loop to build out larger response with out exhausting in token space (e.g. repeating request over loop of sections until complete). 
``````elixir
append3 = with {:ok, run} <- gen2 do 
  get_in(run, [Access.key(:choices), Access.at(0), Access.key(:message)])
end

[_|remainder] = payload
results = Enum.map(remainder, fn(entry) -> 

summary3 = %GenAI.Message{
    role: :user,
    content: """
    Go into depth on #{inspect entry["level"]} - #{inspect entry["step"]}.
    Include advances math notes,mermiad diagram and other details as needed. Step generation 
    with a heading. 
    
    For example the generation for "low-hanging" - "Develop more comprehensive and diverse training datasets that include a wider range of human behaviors and experiences."
    is expected to look like the below:
     
    # Low Hanging: Improve Data Breadth/Quality
    The proposition of utilizing larger and more diverse training datasets to foster emergent sentient behavior in artificial intelligence hinges on the premise that increased data diversity enhances an AI's ability to generalize across various situations. When AI models are trained with expansive datasets that encapsulate a wide array of human interactions, languages, cultures, and scenarios, the models are not only learning specific tasks but are also absorbing the nuances and complexities of human behavior. This broad exposure potentially equips AI systems with a richer, more nuanced understanding of the world, which is crucial for the development of any form of emergent behavior that could be likened to sentience.

    Training AI models on diverse datasets also mitigates the risk of developing biases that can skew their understanding and interaction with the world. Bias in AI can stem from datasets that are narrow or homogeneous, often reflecting the unintended prejudices of their human creators. By ensuring that the training data is representative of different demographics, viewpoints, and experiences, AI models can be more fair and equitable in their functionality. This is essential not only for ethical reasons but also for the practical efficacy of AI in diverse global contexts. Such comprehensively trained AI systems are more likely to handle unexpected situations or generalize to new, untrained conditions in ways that might mimic sentient decision-making.

    Moreover, the size of the dataset significantly affects an AI's learning capacity. Larger datasets provide more examples from which the AI can learn, which can lead to more robust models that make better predictions and decisions. This increased capability might allow AIs to exhibit behaviors that are complex and adaptive, qualities often associated with sentience. For example, an AI trained on a massive, varied dataset might develop the ability to intuit human emotions or understand subtle social cues, pushing it closer to what might be considered emergent sentient behavior.

    While the concept of AI exhibiting sentient behavior remains largely theoretical and subject to philosophical debate, the approach of using larger, more diverse datasets offers a plausible path toward such a possibility. It challenges AI developers to consider not just the technical aspects of dataset compilation but also the ethical implications of AI education. As AI continues to evolve and integrate more deeply into society, the foundational data it learns from will significantly shape its trajectory, potentially leading to more sophisticated and seemingly sentient AI systems.

    ```mermaid
    flowchart TD
    A[Start: Data Collection] --> B{Data Variety Assessment}
    B -- Low Variety --> C[Incorporate More Demographics, Languages, Cultures]
    B -- Adequate Variety --> D{Data Volume Assessment}
    C --> D
    D -- Insufficient Volume --> E[Increase Data Volume: Add More Examples]
    D -- Sufficient Volume --> F[Prepare Diverse and Large Dataset]
    E --> F
    F --> G[Model Training: Deep Learning Algorithms]
    G --> H{Evaluate Model on Generalization}
    H -- Poor Generalization --> I[Enhance Dataset and Retrain]
    H -- Good Generalization --> J[Advanced Generalization Techniques]
    J --> K[Application of Techniques: Dropout, Regularization, and Meta-learning]
    I --> G
    K --> L[Model Tests for Emergent Behaviors]
    L --> M{Check for Complex Adaptive Behaviors}
    M -- Not Detected --> N[Iterate: Further Data and Training Adjustments]
    M -- Detected --> O[Potential Emergent Sentience]
    N --> B
    O --> P[End: Further Research and Development]

    click B "https://research.google/pubs/pub43455/" "Research on Data Diversity"
    click D "https://papers.nips.cc/paper/2019/hash/f1748d6b0fd9d439f71450117eba2725-Abstract.html" "Study on Data Volume and AI Performance"
    click J "https://arxiv.org/abs/1801.06146" "Research on AI Generalization"
    click M "https://www.frontiersin.org/articles/10.3389/frobt.2020.00034/full" "Studies on Complex Adaptive Behaviors in AI"
    click O "https://www.nature.com/articles/s42256-021-00359-8" "Exploring AI Sentience"

    ```

    In conclusion, fostering emergent sentient behavior in AI through the use of larger and more diverse training datasets is an intriguing idea that combines elements of technology, ethics, and philosophy. As we venture further into this territory, it becomes increasingly important to monitor and understand the effects of our training practices on the capabilities and behaviors of AI systems. This ongoing process of learning and adaptation may eventually lead us to new discoveries about artificial intelligence and its potential to exhibit sentient-like qualities.

    

    """
  }

gen4 = thread
  |> GenAI.with_message(wrap_up)
  |> GenAI.with_message(append)
  |> GenAI.with_message(summary)
  |> GenAI.with_message(append2)
  |> GenAI.with_message(summary2)
  |> GenAI.with_message(append3)
  |> GenAI.with_message(summary3)
  |> GenAI.with_setting(:temperature, 0.9)
  |> GenAI.with_setting(:tokens, 4095)
  |> GenAI.with_setting(:max_tokens, 4095)
  |> GenAI.with_model(GenAI.Provider.OpenAI.Models.gpt_4_turbo()) 
  |> GenAI.run()


  with {:ok, %{choices: [%{message: %{content: c}}|_]}} <- gen4 do 
    IO.puts c
    {:ok, c} 
  else   
     _ ->    {:error, entry}
  end

end)

main = Enum.map(results, & elem(&1,0) == :ok && elem(&1,1))
|> Enum.filter(& &1)
|> Enum.join("\n\n-----------------\n\n")

errors = Enum.map(results, & elem(&1,0) == :error && elem(&1,1))
|> Enum.filter(& &1)

kino = """
#{length(errors) > 0 && "\# Errors\n#{inspect errors}" || ""}
""" <> main
|> Kino.Markdown.new()
``````

#### Snapshots

| Title | Image |
|:-----:|:-----:|
| snippet of response to multi agent example |  ![cross_model_chat](https://github.com/noizu-labs-ml/genai/assets/6298118/2a3ac359-3fd5-4e81-b64a-1c42dc8d2e34) |
| snippet of response to reprompting loop example    |  ![latex_mermaid_output](https://github.com/noizu-labs-ml/genai/assets/6298118/428fb312-359d-4f39-9f73-5c8238ee8bd8) |




### Extending the Library with Additional Model Providers

The GenAI library is designed to be easily extensible with new model providers. Here's how to add support for a new provider:

1. **Create a new provider module:** Create a new module under the `GenAI.Provider` namespace, for example, `GenAI.Provider.NewProvider`.
2. **Implement the `GenAI.ThreadProtocol`:** Implement the following functions defined in the `GenAI.ThreadProtocol` for your new provider module:
    * `chat(messages, tools, settings)`
    * `models(settings)`
3. **Handle provider-specific details:** Implement any provider-specific logic, such as handling authentication, constructing API requests, and parsing responses.
4. **(Optional) Implement tool protocols:** If the provider supports tool integration, implement the following protocols:
    * `GenAI.Provider.NewProvider.ToolProtocol`
    * `GenAI.Provider.NewProvider.MessageProtocol`
5. **Add tests:** Write unit and integration tests for your new provider module to ensure it works as expected.

Once you have implemented the provider module and protocols, you can use it with the GenAI library just like any other supported provider.

### Future Features

* **Response tree execution:** Implement a dedicated `GenAI.ResponseTree` module to define and execute complex response plan trees with conditional branching and different actions at each node.
* **Streaming support:** Implement the `stream` function for real-time interaction with models that offer this feature.
* **Enhanced model selection:** Improve the model selection logic to consider factors like cost, performance, and context size.
* **Improved error handling:** Provide more specific and informative error messages.
* **Comprehensive tests:** Expand the test suite to cover more functionalities and edge cases.
* **Detailed documentation:** Add comprehensive documentation for all modules and functions.
* **Support for more providers:** Explore the possibility of adding support for other generative AI providers and models.
* **Caching mechanism:** Implement a caching system to improve performance and reduce costs.
* **Logging and analysis:** Develop a mechanism for logging and analyzing interactions with generative AI models.

#### Grid Search/Optimization proposed interface. 
```elixir
 test "proposed syntax" do
    data_loader = nil
    chat_thread = []
    fitness = nil
    sentinel = nil
    good_enough_system_prompt_sentinel = nil
    dynamic_system_prompt = %GenAI.DynamicMessage{role: :user, content: "Tell me a random fact about cats using a tool call."}

    GenAI.chat()
    |> GenAI.with_messages(chat_thread) # 1.
    |> GenAI.loop(:prompt_search, 25) do  # 2.
         GenAI.with_message(dynamic_system_prompt, label: :dynamic_system_prompt) # 3
         |> GenAI.loop(:epoch, 5) do # 4.
              GenAI.loop(GenAI.DataLoader.sample(data_loader), 25) do # 5.
              GenAI.Message.tune_prompt(by_label: :dynamic_system_prompt) # 6.
              |> GenAI.with_message(GenAI.DataLoader.take_one(data_loader)) # 7
              |> GenAI.fitness(fitness) # 8.
            end
         |> GenAI.score()
         |> GenAI.early_stopping(sentinel)  #9
       end
    |> GenAI.early_stopping(good_enough_system_prompt_sentinel)
  end
  |> GenAI.execute(:report) # 9
end
```



### Contributing

Contributions are welcome! Please see the `CONTRIBUTING.md` file for guidelines.

### License

This library is released under the MIT License.
