As a `new user`, I `want elelem to run locally without external servers or API keys`, so that `I can start using it immediately with zero configuration`.

# SYNOPSIS

Implement complete local inference: hardware detection, model download, local provider, and default selection.

# DESCRIPTION

This story implements the full local inference capability, consolidating the work from stories 002-005 (see ADR-0001). The spike (story 001) should be completed first to inform implementation decisions.

## 1. Hardware Detection

Detect GPU/CPU capabilities to determine what models can run locally:

- **GPU presence and type**: NVIDIA (CUDA), AMD (ROCm), or CPU-only
- **Available VRAM/RAM**: GPU memory and system RAM
- **Model recommendations**: Map hardware to appropriate model sizes
  - 8GB+ VRAM → 7B parameter model
  - 4GB VRAM → 3B model
  - CPU-only → small model (1-3B)

## 2. Model Download

Download LLM models from Hugging Face with progress indication:

- Use hardware detection to pick an appropriate default model
- Support curated list of coding models (CodeLlama, DeepSeek Coder, Qwen Coder)
- Download GGUF format from Hugging Face Hub
- Store in `~/.cache/elelem/models/`
- Show progress, handle interrupted downloads

## 3. Local Inference Provider

Create `lib/elelem/net/local.rb` provider:

- Load GGUF models using approach from spike (llama.cpp bindings or CLI)
- Support GPU acceleration (CUDA, ROCm) with CPU fallback
- Implement same interface as existing providers (streaming, conversation history)
- Keep model loaded in memory between prompts
- Configurable via `.elelem.yml`

## 4. Default Provider Selection

Make local provider the default for new users:

- When no config exists and no API keys set, use local provider
- Trigger model download if needed
- Provider priority (when no explicit config):
  1. Local provider (new default)
  2. Ollama (if running)
  3. Cloud providers (if API keys set)
- Existing users with config are not affected

# SEE ALSO

* [ ] .elelem/backlog/001-local-inference-spike.md - Complete spike first
* [ ] doc/adr/ADR-0001-consolidate-local-inference-stories.md - Decision record
* [ ] lib/elelem/net/ollama.rb - Provider interface reference
* [ ] lib/elelem/net/openai.rb - Provider interface reference
* [ ] lib/elelem/system_prompt.rb - Platform detection patterns

# Tasks

* [ ] TBD (filled in design mode, after spike completes)

# Acceptance Criteria

## Hardware Detection
* [ ] Correctly detects NVIDIA GPU presence on Linux
* [ ] Correctly detects AMD GPU presence on Linux
* [ ] Correctly detects available VRAM when GPU present
* [ ] Correctly detects available system RAM
* [ ] Works gracefully when detection tools are not installed

## Model Download
* [ ] Model downloads successfully from Hugging Face
* [ ] User sees progress indication during download
* [ ] Downloaded model is stored in consistent location
* [ ] Subsequent runs do not re-download existing model
* [ ] Graceful error handling if download fails

## Local Provider
* [ ] Provider loads model from local disk
* [ ] Provider generates streaming responses
* [ ] Provider works with GPU acceleration (CUDA and ROCm)
* [ ] Provider falls back to CPU when no GPU available
* [ ] Provider integrates with existing conversation flow
* [ ] Works fully offline once model is downloaded

## Default Selection
* [ ] New user with no config starts elelem and can chat immediately
* [ ] Local provider is used by default
* [ ] Model downloads automatically on first run if not present
* [ ] Existing users with `.elelem.yml` are not affected
