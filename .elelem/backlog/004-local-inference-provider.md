As a `user`, I `want to run LLM inference locally without external servers`, so that `I can use elelem without API keys, Ollama, or network connectivity`.

# SYNOPSIS

Implement a local inference provider that loads and runs models directly in-process.

# DESCRIPTION

Create a new provider in `lib/elelem/net/` that:

1. **Loads models locally**:
   - Use the approach determined by Story 001 (llama.cpp bindings or CLI)
   - Load GGUF model files from `~/.cache/elelem/models/`
   - Support GPU acceleration (CUDA, ROCm) when available
   - Fall back to CPU inference when no GPU present

2. **Implements the provider interface**:
   - Match the interface of existing providers (ollama.rb, openai.rb, claude.rb)
   - Support streaming responses
   - Handle the conversation history format

3. **Performance considerations**:
   - Model loading may take a few seconds - show appropriate feedback
   - Keep model loaded in memory for subsequent prompts (don't reload per-request)
   - Handle memory limits gracefully

4. **Configuration**:
   - Configurable via `.elelem.yml` similar to other providers
   - Support specifying custom model path
   - Support model selection override

# SEE ALSO

* [ ] Story 001 (determines implementation approach)
* [ ] Story 003 (provides downloaded models)
* [ ] lib/elelem/net/ollama.rb (provider interface reference)
* [ ] lib/elelem/net/openai.rb (provider interface reference)
* [ ] lib/elelem/net/claude.rb (provider interface reference)

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Provider loads model from local disk
* [ ] Provider generates streaming responses
* [ ] Provider works with GPU acceleration on CUDA
* [ ] Provider works with GPU acceleration on ROCm
* [ ] Provider falls back to CPU when no GPU available
* [ ] Provider integrates with existing elelem conversation flow
* [ ] Tool calling works with local models (if model supports it)
* [ ] Works fully offline once model is downloaded
