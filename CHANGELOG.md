Change Log
==============
# 0.0.1 - Initial Release
- Initial Text Only Generation.

# 0.0.2 - Local Model Support
- Local LLama support added for pulling in gguf models for inference.

# 0.0.3 - Vision Support and Internal Structure Update 
Warning - This update may break existing code.


- Added Vision support for OpenAI, Gemini, and Anthropic.
- Updated internal structure to allow for more advanced use cases such as prompt loops/fitness checks,
added support for how to handel local models, etc.

# 0.1.0 - Split into core and extension libraries.
To use local llama you must replace 

```
config :genai_local, :local_llama,
       enabled: true,
       otp_app: :my_app
```

with 

```
config :genai_local, :local_llama,
       otp_app: :my_app
```

and add `{:genai_local, "~> 0.1"} to your dep list.

