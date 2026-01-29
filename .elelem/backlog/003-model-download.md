As a `new user`, I `want elelem to automatically download the recommended model`, so that `I can start using it immediately without manual setup`.

# SYNOPSIS

Download LLM models from Hugging Face with progress indication.

# DESCRIPTION

When the local provider is used and the required model is not present locally:

1. **Model selection**:
   - Use hardware detection (Story 002) to pick an appropriate default model
   - Support a curated list of known-good coding models (e.g., CodeLlama, DeepSeek Coder, Qwen Coder)

2. **Download process**:
   - Download from Hugging Face Hub (GGUF format preferred for llama.cpp)
   - Show download progress (stream CLI output or use Terminal#waiting)
   - Store in `~/.cache/elelem/models/` or similar standard location

3. **Model management**:
   - Check if model already exists before downloading
   - Handle interrupted downloads gracefully (resume or restart)

The approach (HF CLI vs direct download) will be determined by Story 001 spike.

# SEE ALSO

* [ ] Story 001 (determines download approach)
* [ ] Story 002 (provides hardware info for model selection)
* [ ] lib/elelem/terminal.rb (progress indication)
* [ ] ~/.cache/elelem/models/ (storage location)

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Model downloads successfully from Hugging Face
* [ ] User sees progress indication during download
* [ ] Downloaded model is stored in consistent location
* [ ] Subsequent runs do not re-download existing model
* [ ] Graceful error handling if download fails (network error, disk full, etc.)
* [ ] At least one good default coding model is identified and tested
