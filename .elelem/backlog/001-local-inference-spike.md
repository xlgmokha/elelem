As a `developer`, I `want to research local LLM inference options`, so that `we can choose the best approach for running models without external servers`.

# SYNOPSIS

Research spike to evaluate llama.cpp, Hugging Face CLI, and other options for local inference.

# DESCRIPTION

Before building the local provider, we need to understand:

1. **Inference engines**: Evaluate options like llama.cpp (via Ruby bindings or CLI), Hugging Face transformers, or other local inference tools
2. **Ruby integration**: Determine if we should use Ruby bindings (e.g., `llama_cpp.rb` gem) or shell out to a CLI tool
3. **Hugging Face integration**: Understand how to download GGUF/GGML models, whether to use `huggingface-cli` or direct API calls
4. **GPU support**: Verify CUDA and ROCm acceleration works on Linux
5. **Model format**: Determine which quantized model formats to support (GGUF recommended for llama.cpp)

Deliverable: A written recommendation document with:
- Recommended approach
- Required dependencies
- Example code showing basic inference working
- Known limitations

# SEE ALSO

* [ ] https://github.com/ggerganov/llama.cpp
* [ ] https://github.com/yoshoku/llama_cpp.rb
* [ ] https://huggingface.co/docs/huggingface_hub/guides/cli
* [ ] lib/elelem/net/ (existing provider implementations)

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Document exists with clear recommendation
* [ ] Proof-of-concept code demonstrates loading a model and generating a response
* [ ] GPU acceleration tested on at least one platform (CUDA or ROCm)
* [ ] Decision made: Ruby bindings vs CLI wrapper
* [ ] Decision made: Model download strategy (HF CLI vs direct download)
